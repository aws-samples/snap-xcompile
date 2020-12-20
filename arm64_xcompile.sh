#!/bin/bash


function get_status {
	echo $(aws ec2 describe-tags \
			--filters Name=resource-id,Values=$1 \
				  	  Name=key,Values=Status \
			--query "Tags[0].Value" --output text)
}

# Create s3 bucket
uuid=$(head -c 16 /proc/sys/kernel/random/uuid)
name=arm64-snap-$uuid
echo "- Creating S3 bucket"
aws s3 mb s3://$name

# Upload code files to bucket
echo "- Uploading source code to bucket"
aws s3 cp src/ s3://$name/src --recursive
aws s3 cp snap/ s3://$name/snap --recursive

# Initiate cfn stack
echo "- Setting up xcompile resources"
stack_arn=$(aws cloudformation create-stack \
	--stack-name $name \
	--template-body file://arm64_cfn.yaml \
	--parameters ParameterKey=S3BucketName,ParameterValue=$name \
	--capabilities CAPABILITY_IAM \
	--query "StackId" --output text)

echo -e "\t- Stack Name: $name"
echo -e "\t- Stack ARN: $stack_arn"

# Wait for ec2 instance to launch
echo -e "- Spinning up EC2 instance\c"
ec2_id='None'

while [ $ec2_id == 'None' ]; do
	sleep 1
	echo -e '.\c'
	ec2_id=$(aws cloudformation describe-stacks \
		--stack-name $stack_arn \
		--query "Stacks[0].Outputs[?OutputKey=='InstanceId'].OutputValue" \
		--output text)
done

echo -e "\n\t- Instance ID: $ec2_id"
echo -e "- Installing AWS tools\c"

# Check ec2 status tag
#status=$(get_status $ec2_id)

while [ $(get_status $ec2_id) == 'None' ]; do
	sleep 1
	echo -e '.\c'

#	status=$(get_status $ec2_id)
#	status=$(aws ec2 describe-tags \
#		--filters Name=resource-id,Values=$ec2_id Name=key,Values=Status \
#		--query "Tags[0].Value" --output text)

#	echo "A-"$status
done

# Install snap tools on ec2
echo -e "\n- Configuring machine\c"
while [ $(get_status $ec2_id) == "CONFIGURING" ]; do
	echo -e '.\c'
	sleep 1

#	status=$(get_status $ec2_id)
#	status=$(aws ec2 describe-tags \
#		--filters Name=resource-id,Values=$ec2_id Name=key,Values=Status \
#		--query "Tags[0].Value" --output text)

#	echo "B-"$status
done

echo -e "\nThe next step will take several minutes to complete. \c"
echo -e "Perfect opportunity for a stretch break!"

# Snap source code
echo -e "- Building snap\c"
while [ status=$(get_status $ec2_id) == "SNAPPING" ]; do
	echo -e '.\c'
	sleep 1

#	status=$(get_status $ec2_id)
#	status=$(aws ec2 describe-tags \
#		--filters Name=resource-id,Values=$ec2_id Name=key,Values=Status \
#		--query "Tags[0].Value" --output text)

#	echo "C-"$status
done

# ...check for complete tag...
echo -e '\ncomplete!'

# download snap from s3
aws s3 cp s3://$name/*.snap .

# delete cfn stack
# aws cloudformation delete-stack --stack-name myteststack

# delete s3 bucket
# aws s3 rb s3://$name --force

#--query "Stacks[0].Outputs[?OutputKey=='DbUrl'].OutputValue" --output text