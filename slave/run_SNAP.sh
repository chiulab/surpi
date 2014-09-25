#!/bin/bash
#
# 	run_SNAP.sh
#
# 	This script runs on a clustered slave machine. It starts once the master copies the initial data to the machine.
# 	It runs SNAP on the inputfile, processes and compresses the result, and copies the result back to the master.
# 	Chiu Laboratory
# 	University of California, San Francisco
# 	January, 2014
#
# Copyright (C) 2014 Scot Federman - All Rights Reserved
# Permission to copy and modify is granted under the BSD license
# Last revised 5/15/2014


expected_args=4

if [ $# -lt $expected_args ]
then
	echo "Usage: run_SNAP.sh <inputfile> <master_IP> <incoming_directory_on_master> <SNAP d-value cutoff>"
	exit 65
fi

###
inputfile=$1
master=$2
incoming_directory_on_master=$3
SNAP_d_cutoff=$4
###

#Use all cores on slave
total_cores=$(grep processor /proc/cpuinfo | wc -l)

fastq_file=$(basename "$inputfile" .gz)

database=$(ls -d /reference/snap*)
nt_section="${database##*/}"
snap_outputfile=$fastq_file.$nt_section.sam

logfile=/home/ubuntu/slave.$nt_section.log

touch $logfile

echo "inputfile: $inputfile" >> $logfile 2>&1
echo "fastq_file: $fastq_file" >> $logfile 2>&1
echo "database: $database" >> $logfile 2>&1
echo "nt_section: $nt_section" >> $logfile 2>&1
echo "snap_outputfile: $snap_outputfile" >> $logfile 2>&1

#decompress inputfile
pigz -d $inputfile

#run snap
START1=$(date +%s)
/usr/bin/time -o snap.time.log snap single $database $fastq_file -o $snap_outputfile -t $total_cores -x -f -h 250 -d $SNAP_d_cutoff -n 25 >$
END1=$(date +%s)
diff1=$(( END1 - START1 ))
echo "snap ran in $diff1 seconds."

#remove header
START2=$(date +%s)
sed '/^@/d' $snap_outputfile > $snap_outputfile.noheader
END2=$(date +%s)
diff2=$(( END2 - START2 ))
echo "header removed in $diff2 seconds."

#sort file
START3=$(date +%s)
sort --parallel=$total_cores -T /mnt/tmp $snap_outputfile.noheader > $snap_outputfile.noheader.sorted
END3=$(date +%s)
diff3=$(( END3 - START3 ))
echo "sort completed in $diff3 seconds."

#compress final output before returning to master
START4=$(date +%s)
pigz $snap_outputfile.noheader.sorted >> $logfile 2>&1
END4=$(date +%s)
diff4=$(( END4 - START4 ))
echo "compressed snap results in $diff4 seconds."

#copy output to master
START5=$(date +%s)
rsync -azv -e 'ssh -o StrictHostKeyChecking=no -i /home/ubuntu/.ssh/surpi.pem' $snap_outputfile.noheader.sorted.gz  ubuntu@$master:$incoming_directory_on_master
END5=$(date +%s)
diff5=$(( END5 - START5 ))
echo "results copied to master in $diff5 seconds."

END_TOTAL=$(date +%s)
diff_total=$(( END_TOTAL - START1 ))
echo "Total runtime on slave: $diff_total seconds."

#sync slave logfile back to master
rsync -azv -e 'ssh -o StrictHostKeyChecking=no -i /home/ubuntu/.ssh/surpi.pem' $logfile  ubuntu@$master:$incoming_directory_on_master
