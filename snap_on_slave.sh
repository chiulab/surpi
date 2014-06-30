#!/bin/bash
#
#	snap_on_slave.sh
#
#	This script runs on a local machine with the EC2 command line tools. It does the following tasks:
#
#	• compress the file to be transferred (using pigz)
#	• transfer compressed file to the slave machines (each receives the same compressed FASTQ file).
#
# 	On each slave, execute run_SNAP.sh:
#		• start SNAP on each slave
#		• send results back to the master machine
#
#	• wait until all slaves have returned results to master
#	• merge the returned data to form a single SAM file
#
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# Copyright (C) 2014 Scot Federman - All Rights Reserved
# Permission to copy and modify is granted under the BSD license
# Last revised 6/30/2014


expected_args=6

if [ $# -lt $expected_args ]
then
	echo "Usage: snap_on_slave.sh <file_to_transfer> <pemkey> <file_with_slave_list> <incoming_directory_for_results> <output_filename> <SNAP d-value cutoff>"
	exit 65
fi

###
file_to_transfer=$1
pemkey=$2
file_with_slave_ips=$3
incoming_dir_for_results=$4
output_file=$5
SNAP_d_cutoff=$6
###
scriptname=${0##*/}

#remove this hardcode before release
working_directory_on_slave="/mnt/SURPI_data"

master_IP=$(wget -qO- http://instance-data/latest/meta-data/local-ipv4)

#compress file to send to slaves
START1=$(date +%s)
pigz $file_to_transfer
END1=$(date +%s)
diff1=$(( END1 - START1 ))
echo -e "$(date)\t$scriptname\tdone compressing file to transfer to slaves in $diff1 seconds"

#send file to slaves
START2=$(date +%s)
COUNTER=0
while read line; do
	rsync -azv -e "ssh -o StrictHostKeyChecking=no -i $pemkey" "$file_to_transfer.gz" ubuntu@$line:$working_directory_on_slave >> slave.$COUNTER.log 2>&1 &
	let COUNTER=COUNTER+1
done < $file_with_slave_ips

for job in `jobs -p`
do
	wait $job
done
END2=$(date +%s)
diff2=$(( END2 - START2 ))

echo -e "$(date)\t$scriptname\tdone transferring data to slaves in $diff2 seconds"

#run SNAP on slaves
START3=$(date +%s)
echo -e "$(date)\t$scriptname\trunning SNAP on slaves..."
COUNTER=0
while read line; do
	ssh -o StrictHostKeyChecking=no -i $pemkey ubuntu@$line "cd $working_directory_on_slave; /usr/local/bin/run_SNAP.sh $file_to_transfer.gz $master_IP $incoming_dir_for_results" "$SNAP_d_cutoff" >> slave.$COUNTER.log 2>&1 &
	let COUNTER=COUNTER+1
done < $file_with_slave_ips

for job in `jobs -p`
do
	wait $job
done
END3=$(date +%s)
diff3=$(( END3 - START3 ))
echo -e "$(date)\t$scriptname\tdone running SNAP on slaves and transferring data from slaves to master in $diff3 seconds"

#after receiving results from slaves, decompress on master
START4=$(date +%s)

# this will run pigz, no more than 4 simultaneous (specified by -j)
parallel --gnu -j 4 "echo pigz {}; pigz -d {}; echo done {};" ::: $incoming_dir_for_results/*.gz

END4=$(date +%s)
diff4=$(( END4 - START4 ))
echo -e "$(date)\t$scriptname\tdone decompressing SAM files on master in $diff4 seconds"

#merge SAM files on master
START5=$(date +%s)
echo -e "$(date)\t$scriptname\tmerging SAM files on master machine: "
list_of_incoming_sam_files=$(ls $incoming_dir_for_results/*.sorted)
compare_multiple_sam.py $list_of_incoming_sam_files $output_file
END5=$(date +%s)
diff5=$(( END5 - START5 ))
echo -e "$(date)\t$scriptname\tdone merging SAM files on master in $diff5 seconds"
