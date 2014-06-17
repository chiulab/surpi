#!/bin/bash
#
#	start_slaves_setup_custom_AMI.sh
#
#	This script runs on a local machine with the EC2 command line tools, and sets up the SNAP-NT
#	slave nodes. There is 1 node for each nt division
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# Copyright (C) 2014 Scot Federman - All Rights Reserved
# Permission to copy and modify is granted under the BSD license
# Last revised 5/15/2014

START1=$(date +%s)

expected_args=7

if [ $# -lt $expected_args ]
then
	echo "Usage: start_slaves_setup.sh <ami> <number_of_slaves> <instance_type> <keypair> <security_group> <availability_zone> <file_with_slave_list> <placement_group>"
	exit 65
fi

###
ami_id=$1
number_of_instances=$2
instance_type=$3
keypair=$4
security_group=$5
availability_zone=$6
file_with_slave_ips=$7
placement_group=$8
###
scriptname=${0##*/}

#This is the time (in seconds) this script waits after starting up the AWS machines. 
#It allows the instances time to start up. In practice, 120s appears to be sufficient.
WAIT_TIME=120

#folder where slave scripts are located
slave_folder="/usr/local/bin/surpi/slave"
#script located on slave to run
slave_script="slave_setup.sh"	

#this parameter is currently tied to the $keypair used during slave_setup.sh. should be cleaned up prior to release
pemkey="/home/ubuntu/.ssh/surpi.pem"

#These are the ids of the EBS drives containing SNAP reference data
# this can be derived via the API. Implement this before release.
#something like this:
#ec2-describe-volumes -F tag:Name=SNAP*
snap00="vol-0145b148"
snap01="vol-5b45b112"
snap02="vol-5645b11f"
snap03="vol-4645b10f"
snap04="vol-4f45b106"
snap05="vol-14e7105d"
snap06="vol-84e710cd"
snap07="vol-bce710f5"
snap08="vol-a3e710ea"
snap09="vol-53e6111a"
snap10="vol-a22addeb"
snap11="vol-3929de70"
snap12="vol-1229de5b"
snap13="vol-eb29dea2"
snap14="vol-9f29ded6"
snap15="vol-cb29de82"
snap16="vol-9329deda"
snap17="vol-ed29dea4"
snap18="vol-a429deed"
snap19="vol-ec29dea5"
snap20="vol-7c1deb35"
snap21="vol-ee29dea7"
snap22="vol-e129dea8"
snap23="vol-bb29def2"
snap24="vol-b729defe"
snap25="vol-5e28df17"
snap26="vol-4e28df07"
snap27="vol-b229defb"
snap28="vol-8629decf"

ebs_volumes=($snap00 $snap01 $snap02 $snap03 $snap04 $snap05 $snap06 $snap07 $snap08 $snap09 $snap10 $snap11 $snap12 $snap13 $snap14 $snap15 $snap16 $snap17 $snap18 $snap19 $snap20 $snap21 $snap22 $snap23 $snap24 $snap25 $snap26 $snap27 $snap28)

#Create EC2 slave instances
result=$(	ec2-run-instances $ami_id \
				--instance-count $number_of_instances \
				--instance-type $instance_type \
				--key $keypair \
				--group $security_group \
				--availability-zone $availability_zone \
				--placement-group $placement_group \
				-b /dev/xvdb=ephemeral0 -b /dev/xvdc=ephemeral1 \
				| egrep ^INSTANCE | cut -f2 )

echo -e "$(date)\t$scriptname\t---------------------------"
echo -e "$(date)\t$scriptname\tInstance ids"
echo -e "$(date)\t$scriptname\t$result"
echo -e "$(date)\t$scriptname\t---------------------------"
#give AWS some time to start up the slaves
echo -e "$(date)\t$scriptname\tWaiting $WAIT_TIME seconds for slaves to start up..."
# sleep $WAIT_TIME
for i in $(seq 1 $WAIT_TIME)
do
	sleep 1
	printf "\r $i"
done
# instance_id_list=( $result )
# instance_id_size=${#instance_id_list[@]}
# 
# if [ "$instance_id_size" != "$number_of_instances" ]; then
# 	echo "ERROR: could not create $number_of_instances instances"
# 	echo "$number_of_instances instances were created."
# 	exit
# else
# 	echo "Launched with instanceid=$instance_id"
# fi

COUNTER=0
for instance_id in $result
do
	touch slave.$COUNTER.log
	echo -e "$(date)\t$scriptname\t---------------------------" >> slave.$COUNTER.log 2>&1
	echo -e "$(date)\t$scriptname\tinstance $COUNTER: $instance_id" >> slave.$COUNTER.log 2>&1
	echo -e "$(date)\t$scriptname\t---------------------------" >> slave.$COUNTER.log 2>&1

	# wait for the instance to be fully operational
	echo -n -e "$(date)\t$scriptname\tWaiting for instance to start running..." >> slave.$COUNTER.log 2>&1
	while host=$(ec2-describe-instances "$instance_id" | egrep ^INSTANCE | cut -f4) && test -z $host; do echo -n . >> slave.$COUNTER.log 2>&1; sleep 1; done
# 	echo >> slave.$COUNTER.log 2>&1
	while true; do
		printf "." >> slave.$COUNTER.log 2>&1
		# get private dns
		SLAVE_HOST=`ec2-describe-instances $instance_id | grep running | awk '{print $5}'`
		if [ ! -z $SLAVE_HOST ]; then
			echo -e "$(date)\t$scriptname\tStarted as $SLAVE_HOST" >> slave.$COUNTER.log 2>&1
			break;
		fi
		sleep 1
	done

	#remove this line before release.
	echo -e "$(date)\t$scriptname\tssh -l ubuntu -i $pemkey $host" >> slave.$COUNTER.log 2>&1

	echo -e "$(date)\t$scriptname\tRunning with host=$host" >> slave.$COUNTER.log 2>&1
	echo -n -e "$(date)\t$scriptname\tVerifying ssh connection to $host..." >> slave.$COUNTER.log 2>&1
	while ssh -o StrictHostKeyChecking=no -q -i $pemkey ubuntu@$host true && test; do echo -n . >> slave.$COUNTER.log 2>&1; sleep 1; done
	echo >> slave.$COUNTER.log 2>&1
	echo -e "$(date)\t$scriptname\tAttaching EBS ${ebs_volumes[$COUNTER]} to $instance_id" >> slave.$COUNTER.log 2>&1
	attached=$(ec2-attach-volume -d /dev/sdf -i $instance_id ${ebs_volumes[$COUNTER]})

	echo -e "$(date)\t$scriptname\t$attached" >> slave.$COUNTER.log 2>&1
	#verify $attached here to verify that EBS was attached
	
	echo -e "$(date)\t$scriptname\tconnecting and running $slave_script script..." >> slave.$COUNTER.log 2>&1
	ssh -o StrictHostKeyChecking=no -i $pemkey ubuntu@$host "/home/ubuntu/$slave_script" >> slave.$COUNTER.log 2>&1 &
	let COUNTER=COUNTER+1
done

for job in `jobs -p`
do
	wait $job
done

> $file_with_slave_ips # this ensures that the file is created and blank
files=$(ls slave.[0-9]*.log | sort -n)
for f in $files
do
	head -5 $f | grep -o ip-.*.ec2.internal >> $file_with_slave_ips
done
