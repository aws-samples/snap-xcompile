# Snap XCompile
Tool to cross-compile ROS snaps for arm64 machines using AWS

...the scripts use this hello world (https://github.com/adi3/rospy_hello_world) project as an example..
... for use in your own ROS projects, simple edit the snapcraft.yaml file...

..set up aws cli... give link here...

...tool will look for your src/ and snap/ folders in your catkin workspace and use them to build the snap...
replace content of snap/ and src/ folders with your own snapcraft and source code files respectively

- cd ~/catkin_ws
- wget -P xcompile -N https://raw.githubusercontent.com/adi3/snap_xcompile/main/arm64_cfn.yaml
- wget -P xcompile -N https://raw.githubusercontent.com/adi3/snap_xcompile/main/arm64_compile.sh
- chmod +x xcompile/arm64_compile.sh
- ./xcompile/arm64_compile.sh

...prepared snap will be present in ~/catkin_ws once script finishes..

## Notes
* Some steps in the script take several minutes to finish; patience you must have
* Check status of the CloudFormation stack created by the script to track progress
* Access EC2 instance log under _/var/log/cloud-init-output.log_ for further execution details
