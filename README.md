# Snap XCompile
Tool to cross-compile ROS snaps for arm64 machines using AWS

...the scripts use this hello world (https://github.com/adi3/rospy_hello_world) project as an example..
... for use in your own ROS projects, simple edit the snapcraft.yaml file...

..set up aws cli... give link here...

...tool will look for your src/ and snap/ folders in your catkin workspace and use them to build the snap...

- cd ~/catkin_ws
- mkdir xcompile && cd xcompile
- wget -O https://raw.githubusercontent.com/adi3/snap_xcompile/main/xcompile/arm64_cfn.yaml
- wget -O https://raw.githubusercontent.com/adi3/snap_xcompile/main/xcompile/arm64_compile.sh
- chmod +x xcompile/arm64_compile.sh
- ./xcompile/arm64_compile.sh

...prepared snap will be present in ~/catkin_ws once script finishes..

..if script fails to execute sucessfully, check userdata logs the ec2 instance created by the cfn stack under /var/log/cloud-init-output.log
