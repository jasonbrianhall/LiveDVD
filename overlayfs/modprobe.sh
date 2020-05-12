#!/bin/bash

#Loads Modules
DATA=$(ls -RL /lib/modules | grep -i ko | sort | awk -F\. '{print $1}')
for module in $DATA
do 
	modprobe $module 2> /dev/null
done
