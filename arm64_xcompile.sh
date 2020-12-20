#!/bin/bash

# Create s3 bucket
uuid=$(head -c 16 /proc/sys/kernel/random/uuid)
#echo $uuid
bucket=arm64-snap-$uuid
echo "Creating S3 bucket..."
aws s3 mb s3://$bucket

# Upload code files to bucket
aws s3 cp src/ s3://$bucket/src --recursive
aws s3 cp snap/ s3://$bucket/snap --recursive

# Replace bucket name in cfn stack 
#sed -e "s/S3_BUCKET/${bucket}/g" arm64_cfn.yaml > arm64_cfn_$uuid.yaml
#sed -e "/USER_DATA/{r arm64_snapcraft.sh" -e "d}" arm64_cfn.yaml


# initiate cfn stack
aws cloudformation create-stack \
	--stack-name myteststack \
	--template-body file://arm64_cfn.yaml \
	--parameters ParameterKey=S3BucketName,ParameterValue=$bucket \
	--capabilities CAPABILITY_IAM

# delete cfn tmp file

# while loop fetching and printing user data output
# complete when user data finished

# download snap from s3

# delete cfn stack

# delete s3 bucket
