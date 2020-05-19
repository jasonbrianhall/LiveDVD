#!/bin/bash

#Loads Modules
DATA=$(ls -RL /lib/modules | grep -i ko | sort | awk -F\. '{print $1}')
for module in $DATA
do 
	modprobe $module 2> /dev/null
done

#LIST="ata_generic ahci sd_mod sr_mod virtio_blk loop ext4 isofs squashfs"
#for module in $LIST
#do
	#modprobe $module
#done

