cmake_minimum_required(VERSION 3.0.2)
project(hello_world)

find_package(catkin REQUIRED COMPONENTS
  rospy
  std_msgs
)

catkin_package()

include_directories(
  ${catkin_INCLUDE_DIRS}
)

catkin_install_python(PROGRAMS nodes/broadcast.py
  DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
)

install(FILES launch/broadcast.launch
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}
)