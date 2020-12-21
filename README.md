# Snap xCompile
Tool to cross-compile ROS snaps for arm64 machines using AWS

Roboticists often develop software on one platform (say, a laptop) and run their apps on another (say, a robot SBC). A lot of times, these platforms have different chip architectures, making cross-compiling of apps necessary.

[Snapcraft](https://snapcraft.io/), although a nifty and simple tool for building snaps, does not currently support cross-compiling. Running it on docker images of the target architecture fails because snapcraft depends on _systemd_, which is usually disabled in docker containers to enhance security and isolation. Although it is possible to configure a docker container to run systemd, I found that snap tools stopped working when the host and container architectures were different. Snapcraft does offer the capability to do [remote builds](https://snapcraft.io/docs/remote-build) for different architectures, but this uploads your code to [Launchpad](https://launchpad.net/) and makes it publicly available. Pretty much a deal breaker if you want to keep your code private.

Snap xCompile takes the idea of remote builds and uses a variety of AWS services to build snaps without exposing your source code. The tools spins up an EC2 instance with the the target architecture, uploads your code to a (private and ephemeral) S3 bucket, builds the snap and fetches it to your host workstation. The result is a seamless one-command method to build snaps when host and target architectures differ.

Currently, Snap xCompile supports snapping for *arm64* targets.

## Notes
* You should have AWS CLI tools [installed](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) and [configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html) on your workstation
* This repository uses a [ROS Hello World](https://github.com/adi3/rospy_hello_world) project as an example
* When snapping your own software, the _snap/_ and _src/_ directories should contain the code you want snapped
* Some steps in the script take several minutes to finish; patience you must have
* Check status of the CloudFormation stack created by the script to track progress
* Access EC2 instance log under _/var/log/cloud-init-output.log_ for further execution details

# Usage

1. Download scripts to your workspace
  ```
  cd ~/catkin_ws
  wget -P xcompile -N https://raw.githubusercontent.com/adi3/snap_xcompile/main/arm64_cfn.yaml
  wget -P xcompile -N https://raw.githubusercontent.com/adi3/snap_xcompile/main/arm64_compile.sh
  ```
  
2. Give execution permissions
  ```
  chmod +x xcompile/arm64_compile.sh
  ```
  
3. Initiate snapping
  ```
  ./xcompile/arm64_compile.sh
  ```

The finished snap will be downloaded to your workspace by the script

4. Transfer snap to your target system

5. Install snap
  ```
  sudo snap install --devmode <snap_name>
  ```
