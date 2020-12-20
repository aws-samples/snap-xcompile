#!/bin/bash

# Create s3 bucket
uuid=$(head -c 16 /proc/sys/kernel/random/uuid)
#echo $uuid
bucket=arm64-snap-$uuid
echo "Creating S3 bucket..."
#aws s3 mb s3://$bucket

# Upload code files to bucket
#aws s3 cp src/ s3://$bucket/src --recursive
#aws s3 cp snap/ s3://$bucket/snap --recursive

# initiate cfn stack
stack_arn=$(aws cloudformation create-stack \
	--stack-name myteststack \
	--template-body file://arm64_cfn.yaml \
	--parameters ParameterKey=S3BucketName,ParameterValue=$bucket \
	--capabilities CAPABILITY_IAM \
	--query "StackId" --output text)

echo $stack_arn

# while loop checking for stack outputs -> ec2 ID
ec2_id=''

while [ -z $ec2_id ]; do
	echo "hii"
	sleep 1
	ec2_id=$(aws cloudformation describe-stacks \
		--stack-name $stack_arn \
		--query "Stacks[0].Outputs[?OutputKey=='InstanceId'].OutputValue" \
		--output text)
	echo $ec2_id
done

echo "fuck"

# while loop fetching and printing user data output
# complete when user data finished

# download snap from s3

# delete cfn stack
# aws cloudformation delete-stack --stack-name myteststack

# delete s3 bucket

#--query "Stacks[0].Outputs[?OutputKey=='DbUrl'].OutputValue" --output text