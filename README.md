# Snap XCompile
Tool to cross-compile snaps for arm64 machines using AWS

...you need to have src/ and snap/ folders in your workspace with your code and config files...

- cd ~/catkin_ws
- mkdir xcompile && cd xcompile
- wget -O https://raw.githubusercontent.com/adi3/snap_xcompile/main/xcompile/arm64_cfn.yaml
- wget -O https://raw.githubusercontent.com/adi3/snap_xcompile/main/xcompile/arm64_compile.sh
- chmod +x xcompile/arm64_compile.sh
- ./xcompile/arm64_compile.sh

...prepared snap will be present in ~/catkin_ws once script finishes..

..if script fails to execute sucessfully, check userdata logs the ec2 instance created by the cfn stack under /var/log/cloud-init-output.log
