#!/bin/bash

# Create s3 bucket
uuid=$(head -c 16 /proc/sys/kernel/random/uuid)
#echo $uuid
bucket-name="arm64-snap-$uuid"
echo "Creating S3 bucket..."
aws s3 mb s3://$bucket-name

# Upload code files to bucket
aws s3 cp src/ s3://$bucket-name/src --recursive
aws s3 cp snap/ s3://$bucket-name/snap --recursive

# Replace bucket name in cfn stack 
sed -i '' 's/S3_BUCKET/$bucket-name/g' arm64_cfn.yaml
#sed -e "/USER_DATA/{r arm64_snapcraft.sh" -e "d}" arm64_cfn.yaml


# initiate cfn stack

# while loop fetching and printing user data output
# complete when user data finished

# download snap from s3

# delete cfn stack

# delete s3 bucket
