#!/usr/bin/env python

## Simple hello world demo that publishes a message to
## the 'broadcaster' topic

import rospy
from std_msgs.msg import String

topic='broadcaster'
message='Hello from AWS'

def talker():
    pub = rospy.Publisher(topic, String, queue_size=10)
    rospy.init_node('talker', anonymous=True)
    rate = rospy.Rate(10) # 10hz
    while not rospy.is_shutdown():
        rospy.loginfo(message)
        pub.publish(message)
        rate.sleep()

if __name__ == '__main__':
    try:
        talker()
    except rospy.ROSInterruptException:
        pass
