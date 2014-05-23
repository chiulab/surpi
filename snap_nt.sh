#!/bin/bash
#                                                                                                                                
#	snap_nt.sh
#
#	This script runs SNAP against the NT database
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# Note: for the NT database, default FASTQ headers will cause segmentation fault in SNAP
# need to change FASTQ headers to gi only 
# 1/16/13
#
# Note: SNAP appears unable to handle the size of the NT chunks is split into 14 (e.g. 40,000,000 lines)
# Need to split into 20,000,000 lines (between size of hg19 and virus)
# this is into 28 chunks
# 1/17/13
#
# Note: you need to use the latest version of SNAP 0.15 which outputs the "d" value in the SAM file
# 
# Copyright (C) 2014 Charles Chiu - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
# Last revised 1/26/2014    
                 
expected_args=5

if [ $# -lt $expected_args ]
then
	echo "Usage: snap_nt.sh <FASTQ input file> <directory containing SNAP NT indexes> <number of cores> <free cache memory cutoff in GB> <SNAP d-value cutoff>"
	exit 65
fi

###
inputfile=$1
SNAP_NT_index_directory=$2
cores=$3
free_cache_cutoff=$4
SNAP_d_cutoff=$5
###
scriptname=${0##*/}

echo -e "$(date)\t$scriptname\tstarting"
START1=$(date +%s)

echo -e "$(date)\t$scriptname\tFound file $inputfile"
nopathf=${inputfile##*/} # remove the path to file
echo -e "$(date)\t$scriptname\tAfter removing path: $nopathf"
basef=${nopathf%.fastq} # remove FASTQextension
echo -e "$(date)\t$scriptname\tAfter removing FASTQ extension: $basef"

echo -e "$(date)\t$scriptname\tMapping $basef to NT..."

rm -f $basef.prev.sam
rm -f $basef.tmp.sam
rm -f $basef.tmp2.sam
rm -f $basef.NT.sam

counter=0

for snap_index in $SNAP_NT_index_directory/* ; do
	freemem=`free -g | awk '{print $4}' | head -n 2 | tail -1 | more`
	echo -e "$(date)\t$scriptname\tThere is $freemem GB available free memory...[cutoff=$free_cache_cutoff GB]"
	if [ $freemem -lt $free_cache_cutoff ]
	then
		echo -e "$(date)\t$scriptname\tClearing cache..."
		dropcache
	fi
	nopathsnap_index=${snap_index##*/} # remove the path to file
	echo -e "$(date)\t$scriptname\tFound $snap_index ... processing ..."
	echo -n -e "$(date)\t$scriptname\tstarting: "
	START2=$(date +%s)

######################## RUN SNAP ##########################

	if [ $counter -eq 0 ]
	then
		/usr/bin/time -o $basef.snap.log snap single $snap_index $basef.fastq -o $basef.tmp.sam -t $cores -x -f -h 250 -d $SNAP_d_cutoff -n 25 > $basef.time.log
		cp $basef.tmp.sam temp.sam
	else
		/usr/bin/time -o $basef.snap.log snap single $snap_index $basef.tmp.fastq -o $basef.tmp.sam -t $cores -x -f -h 250 -d $SNAP_d_cutoff -n 25 > $basef.time.log
	fi

	cat $basef.snap.log >> $basef.snapNT.log
	cat $basef.time.log >> $basef.timeNT.log

    
	compare_sam.py $basef.tmp.sam $basef.prev.sam
	cat $basef.prev.sam | egrep -v "^@" | awk '{print "@"$1"\n"$10"\n""+"$1"\n"$11}' > $basef.tmp.fastq

	counter=1
    
	END2=$(date +%s)

	echo -e "$(date)\t$scriptname\tDone with $snap_index "
	diff=$(( $END2 - $START2 ))
	echo -e "$(date)\t$scriptname\tMapping of $snap_index took $diff seconds"
done

# need to restore the hits
update_sam.py $basef.prev.sam $basef.NT.sam 

rm -f $basef.tmp.sam
rm -f $basef.tmp.fastq
rm -f $basef.prev.sam

END1=$(date +%s)
echo -e "$(date)\t$scriptname\tDone with SNAP_NT "
diff=$(( $END1 - $START1 ))
echo -e "$(date)\t$scriptname\toutput written to $basef.NT.sam"
echo -e "$(date)\t$scriptname\tSNAP_NT took $diff seconds"
