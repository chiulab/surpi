#!/bin/bash
#
#	SNAP_setup.sh
#
#	This program will install SNAP onto a fresh EC2 instance.
#	It assumes that the EBS reference volume is attached at /dev/xvdf1
#	This script runs on the EC2 instance
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# Copyright (C) 2014 Scot Federman - All Rights Reserved
# Permission to copy and modify is granted under the BSD license
# Last revised 5/14/2014

export DEBIAN_FRONTEND=noninteractive

install_folder="/usr/local"
bin_folder="$install_folder/bin"

if [ ! -d $bin_folder ]
then
	mkdir $bin_folder
fi
	
CWD=$(pwd)

# set timezone
echo "America/Los_Angeles" | sudo tee /etc/timezone
sudo dpkg-reconfigure --frontend noninteractive tzdata

### install & update Ubuntu packages
sudo -E apt-get update -y
# sudo -E apt-get upgrade -y
sudo -E apt-get install -y pigz unzip htop

# format SSD instance drives (1x800GB)
# echo "formatting /dev/xvdb..."
# sudo mkfs.ext4 /dev/xvdb

#setup instance drive
# sudo mkdir /ssd
# sudo mount /dev/xvdb /ssd
sudo mkdir /mnt/SURPI_data
sudo chown ubuntu:ubuntu /mnt/SURPI_data

# install SNAP
curl -O "http://snap.cs.berkeley.edu/downloads/snap-0.15.4-linux.tar.gz"
tar xvfz snap-0.15.4-linux.tar.gz
sudo cp snap-0.15.4-linux/snap "$bin_folder/"

#
##
### install EC2 CLI tools
##
#

sudo -E apt-get install -y openjdk-7-jre
wget http://s3.amazonaws.com/ec2-downloads/ec2-api-tools.zip
sudo mkdir /usr/local/ec2
sudo unzip ec2-api-tools.zip -d /usr/local/ec2

echo "export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/jre" >> /home/ubuntu/.bashrc
echo "export EC2_HOME=/usr/local/ec2/ec2-api-tools-1.6.13.0/" >> /home/ubuntu/.bashrc
echo "PATH=\$PATH:\$EC2_HOME/bin" >> /home/ubuntu/.bashrc

# mount EBS disk containing SNAP db
if [ ! -d /reference ]
then
	sudo mkdir /reference
fi

for i in {1..5}
	if [ -e /dev/xvdf ]
	then
		break
	fi
	sleep $i
done

if [ -e /dev/xvdf ]; then
	sudo mount /dev/xvdf /reference
else
	echo "EBS drive was not attached to instance $(ec2metadata --instance-id)."
fi

# Start dummy SNAP run in order to precache SNAP database
database=$(ls -d /reference/snap*)
/usr/local/bin/snap single $database test.fastq -o test.sam -t 32 -x -f -h 250 -d 12 -n 25 > snap.log
