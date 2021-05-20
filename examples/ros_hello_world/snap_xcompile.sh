#!/bin/bash

set -Eeuf -o pipefail

base_name='snap-xcompile'
cfn_template='snap_xcompile.yaml'

# Starting year for Ubuntu versions to list
START_YEAR=16

LTS_YEARS=(16 18 20)
ARCHITECTURES=("x86_64" "arm64")
# x86_64 and ARM instances
# Need Nitro hypervisor to get console logs
TYPES=("t3.micro" "t4g.micro")


ami_names=()
ami_ids=()
ami_chosen=-1
type_chosen=-1

log_num=-1
log_start=-1
log_end=-1
log_delay=0.02
log_file='.log'


# Delete s3 bucket and cfn stack
function cleanup {
	echo "- Cleaning up resources"
	rm -f $log_file
	aws s3 rb s3://$name --force &> /dev/null
	echo -e "\t- Deleted S3 bucket"
	aws ec2 delete-key-pair --key-name $name &> /dev/null
	echo -e "\t- Deleted EC2 keypair"
	aws cloudformation delete-stack --stack-name $name &> /dev/null
	echo -e '\t- Deleted Snap xCompile resources'
}


# Custom response to sigint/sigterm
function handle_sig {
	cleanup
	trap - SIGINT SIGTERM # clear the trap
    kill -- -$$ # Sends SIGTERM to child/sub processes
}


trap cleanup SIGINT SIGTERM ERR


# Fetch status tag of an ec2 instance
function get_status {
	echo $(aws ec2 describe-tags \
			--filters Name=resource-id,Values=$1 \
				  	  Name=key,Values=Status \
			--query "Tags[0].Value" --output text)
}


# Fetch the latest AMI for the given release and architecture
function get_ami {
	ami=$(aws ec2 describe-images \
    --owners 099720109477 \
    --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu*$1*" \
    					"Name=state,Values=available" \
    					"Name=architecture,Values=$2" \
    --query "reverse(sort_by(Images, &Name))[:1].[Description,Architecture,ImageId]"
  )

  if [[ $ami != "[]" ]]; then
	  echo -e "\t- Ubuntu $1 LTS ($2)"
	
	  # Ex: Canonical, Ubuntu, 18.04 LTS, amd64 bionic image build on 2021-05-04 ami-0a1e248de68099571 x86_64
	  ami=$(echo $ami | sed 's/"//g; s/,//g; s/\[//g; s/\]//g')
	
	  params=()
	  for param in $ami; do
	  	params+=($param)
	  done
	
	  if [[ "${params[3]}" == "LTS" ]]; then
	  	params[2]="${params[2]} LTS"
	  	params[4]=${params[5]}
	  	params[9]=${params[10]}
	  	params[10]=${params[11]}
	  fi
	  
	  ami_names+=("${params[1]} ${params[2]} (${params[4]}) - ${params[9]}")
	  ami_ids+=("${params[10]}")
  fi
}


# Fetch all Ubuntu AMIs from start year to today
function get_amis {
	for year in "${LTS_YEARS[@]}"; do
		version="$year.04"

		for arch in "${ARCHITECTURES[@]}"; do
			get_ami $version $arch
		done
	done
}


function get_type {
	arch=$(echo ${ami_names[$ami_chosen]} | awk '{print $NF}')

	case $arch in
	  "x86_64")
	    echo -n 0
	    ;;
	  "arm64")
	    echo -n 1
	    ;;
	  *)
	    echo -n -1
	    ;;
	esac
}


# ----------------------------------------------------
# xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# ----------------------------------------------------


# Check for snapcraft file
if [[ ! -f $(pwd)/snap/snapcraft.yaml ]]; then
    echo "[ERROR] Snapcraft config file not found!"
    exit -1
fi

# Get info on latest AMIs
echo "Fetching latest buildfarm options..."
get_amis
echo

# Allow user to select preferred AMI
PS3="Select desired build machine: "
select ami in "${ami_names[@]}"; do
		ami_chosen=$REPLY-1
		type_chosen=$(get_type)
    echo -e "\tImage selected: ${ami_names[$ami_chosen]}"
    break
done


# Create s3 bucket
# Create unique id for AWS resources
uuid=$(uuidgen | awk -F- '{print tolower($1)}')
name="$base_name-$uuid"
echo "- Creating S3 bucket"
aws s3 mb s3://$name


# Upload code files to bucket
echo "- Uploading source code to bucket"
aws s3 cp $(pwd)/src/ s3://$name/src --recursive
aws s3 cp $(pwd)/snap/ s3://$name/snap --recursive


# Create EC2 keypair
echo "- Creating keypair for EC2 access"
aws ec2 create-key-pair --key-name $name &> /dev/null

# Initiate cfn stack
echo "- Setting up Snap xCompile resources"
stack_arn=$(aws cloudformation create-stack \
	--stack-name $name \
	--template-body file://$(pwd)/$cfn_template \
	--parameters ParameterKey=UniqueName,ParameterValue=$name \
							 ParameterKey=BuildType,ParameterValue=${TYPES[$type_chosen]} \
							 ParameterKey=BuildImage,ParameterValue=${ami_ids[$ami_chosen]} \
	--capabilities CAPABILITY_IAM \
	--query "StackId" --output text || cleanup)

echo -e "\t- Stack Name: $name"
# echo -e "\t- Stack ARN: $stack_arn"


# Wait for ec2 instance to launch
echo -e "- Spinning up EC2 instance\c"
echo -e "\n\t- Type: ${TYPES[$type_chosen]}\c"
echo -e "\n\t- Image: ${ami_names[$ami_chosen]}"
ec2_id='None'

while [ $ec2_id == 'None' ]; do
	sleep 1
	echo -e '.\c'
	ec2_id=$(aws cloudformation describe-stacks \
		--stack-name $name \
		--query "Stacks[0].Outputs[?OutputKey=='InstanceId'].OutputValue" \
		--output text)
done

echo -e "\n- Configuring machine\c"
echo -e "\n\t- Instance ID: $ec2_id"


# Stream console output from ec2 instance
while [ $(get_status $ec2_id) == 'None' ]; do

	aws ec2 get-console-output \
	    --instance-id $ec2_id \
	    --latest \
	    --query "Output" \
	    --output text > $log_file

	num=$(wc -l $log_file | awk '{ print $1 }')

	if [[ $num -le 1 ]]; then
		echo -n "."
	else
		tss=$(grep -Eo '\[\s*([0-9]+\.[0-9]+)\]' $log_file | sed 's/[][]//g' | xargs)
		start=$(echo $tss | cut -d' ' -f1)
		end=$(echo $tss | rev | cut -d' ' -f1 | rev)

		if [[ $log_num == $num ]]; then
			echo -n "."
			continue
		elif [[ $start > $log_end ]]; then
			log_start=$start
		else
			log_start=$log_end
		fi

		log_end=$end
		log_num=$num

		# Print log output if timestamp is within bounds
		while IFS= read -r line; do
			ts=$(echo $line | grep -Eo '\[\s*([0-9]+\.[0-9]+)\]' | sed 's/[][]//g' | xargs || true)
			
			if [[ ( -z $ts ) || ( $log_start < $ts && $ts < $log_end ) ]]; then
				echo $line
				sleep $log_delay
			fi
		done < $log_file
	fi
	sleep 1
done


# Download snap from bucket
if [ $(get_status $ec2_id) == "COMPLETED" ]; then
	echo -e "\n- Retrieving snap"
	aws s3 cp s3://$name/$(aws s3 ls s3://$name/ | awk '{print $4}' | grep -i .snap) .
else
	echo "[ERROR] Something went wrong! Try choosing a different build machine."
	cleanup
	exit -2
fi


cleanup
echo -e "- Finished successfully!"
echo -e "\t- Snap retrieved to your working directory"
