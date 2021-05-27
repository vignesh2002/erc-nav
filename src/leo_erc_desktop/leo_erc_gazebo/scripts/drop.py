#!/usr/bin/env python

import rospy
from geometry_msgs.msg import Twist
from std_msgs.msg import Empty
import math

def drop_probe():
        
	pub = rospy.Publisher('/cmd_vel',Twist, queue_size = 10)
	pub1 = rospy.Publisher('/probe_deployment_unit/drop',Empty, queue_size = 10)
	data = Empty()
	speed = Twist()
	d = 1
	speed.linear.x=5
	while not rospy.is_shutdown():
		pub.publish(speed)
		print 1
		if d % 50000 == 0:
			pub1.publish(data)
	 	d = d + 1

if __name__ == "__main__":
	rospy.init_node('map_maker', anonymous = True)
	drop_probe()
	
