#!/bin/bash
#
# 	slave_setup.sh
#
# 	This program will install SNAP onto a fresh EC2 instance.
# 	It assumes that the EBS reference volume is attached at /dev/xvdf1
# 	This script runs on the EC2 instance
# 	Chiu Laboratory
# 	University of California, San Francisco
# 	January, 2014
#
# Copyright (C) 2014 Scot Federman - All Rights Reserved
# Permission to copy and modify is granted under the BSD license
# Last revised 5/15/2014

# create mount point if necessary
if [ ! -d /reference ]
then
	sudo mkdir /reference
fi

#try 5x to mount EBS disk containing SNAP db
for i in {1..5}
do
	if [ -e /dev/xvdf ]
	then
		break
	fi
	sleep $i
done

#create working directory
if [ ! -d /mnt/SURPI_data ]
then
	sudo mkdir /mnt/SURPI_data
fi
sudo chown ubuntu:ubuntu /mnt/SURPI_data

#create tmp directory
if [ ! -d /mnt/tmp ]
then
	sudo mkdir /mnt/tmp
fi
sudo chown ubuntu:ubuntu /mnt/tmp


if [ -e /dev/xvdf ]
then
	sudo mount /dev/xvdf /reference
	echo "successfully mounted EBS drive on instance $(ec2metadata --instance-id)."
else
	echo "EBS drive was not attached to instance $(ec2metadata --instance-id)."
fi

# Start dummy SNAP run in order to precache SNAP database
database=$(ls -d /reference/snap*)
/usr/local/bin/snap single $database test.fastq -o test.sam -t 32 -x -f -h 250 -d 12 -n 25 > snap.log