#!/bin/bash

apt update
apt install -y awscli
apt remove lxd-client -y
snap install lxd
lxd init --auto
snap install snapcraft --classic

mkdir -p /tmp/robomaker_snap
cd tmp/robomaker_snap
aws s3 cp s3://S3_BUCKET/src src/ --recursive
aws s3 cp s3://S3_BUCKET/snap snap/ --recursive

snapcraft --use-lxd
ls .
aws s3 cp hello-world_0.1_arm64.snap s3://S3_BUCKET/

..just create temp bucket..download snap at end... delete bucket...