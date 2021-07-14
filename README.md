# Snap xCompile
Tool to cross-compile ROS snaps for x86_64 and arm64 machines using AWS

Roboticists often develop software on one platform (say, a laptop) and run their apps on another (say, a robot SBC). A lot of times, these platforms have different chip architectures, making cross-compiling a necessity.

[Snapcraft](https://snapcraft.io/), although a nifty and simple tool for building snaps, does not currently support cross-compiling. Running it on docker images of the target architecture fails because snapcraft depends on _systemd_, which is usually disabled in docker containers to enhance security and isolation. Although it is possible to configure a docker container to run systemd, I found that snap tools stopped working when the host and container architectures were different. Snapcraft does offer the capability to do [remote builds](https://snapcraft.io/docs/remote-build) for different architectures, but this uploads your code to [Launchpad](https://launchpad.net/) and makes it publicly available. Pretty much a deal breaker if you want to keep your code private.

Snap xCompile takes the idea of remote builds and uses a variety of AWS services to build snaps without exposing your source code. The tools spins up an EC2 instance with the the target architecture, uploads your code to a (private and ephemeral) S3 bucket, builds the snap and fetches it to your host workstation. The result is a seamless one-command method to build snaps when host and target architectures differ.

Currently, Snap xCompile supports snapping for **x86_64** and **arm64** targets.


## Notes
* You should have AWS CLI tools [installed](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) and [configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html) on your workstation
* This repository uses a [ROS Hello World](https://github.com/adi3/rospy_hello_world) project as an example
* When snapping your own software, the _src/_ directory will contain the code you want snapped
* Some steps in the script take several minutes to finish; patience you must have
* Check status of the CloudFormation stack created by the script to track progress
* Access EC2 instance log under _/var/log/cloud-init-output.log_ for further execution details


# Example Usage

1. Download the project to your local system.

```
git clone https://github.com/aws-samples/snap-xcompile.git
```

2. Give execution permission to the shell script.

```
cd snap-xcompile/

chmod +x src/snap_xcompile.sh
```

3. Snap [example ROS project](https://github.com/aws-samples/snap-xcompile/tree/main/examples/ros_hello_world) for the desired target architecture (*arm64* or *x86_64*).

```
./src/snap_xcompile.sh --source examples/ros_hello_world/ --arch arm64
```

4. The desired snap will be located in your working directory once the script finishes execution.
```
ls .
```
[SCREENSHOT HERE]


## Test Deployment

1. Transfer snap to your target system.

2. Install snap. Replace **filename** with name of the snap produced by Snap xCompile.
  ```
  sudo snap install --devmode filename.snap
  ```
  
3. Confirm snap installation.
  ```
  snap list
  ```
  
4. Invoke _echo_ from the ROS snap.
  ```
  hello-world.echo
  ```


## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.


## License

This library is licensed under the MIT-0 License. See the LICENSE file.
