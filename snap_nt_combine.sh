#!/bin/bash
#
#	snap_nt_combine.sh
#
#	This script runs SNAP against the NT database
#
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# This script will successively run SNAP against NT partitions and then combine the results
#
# Note: for the NT database, default FASTQ headers will cause segmentation fault in SNAP
# need to change FASTQ headers to gi only
# 1/16/13
#
# Note: you need to use SNAP 0.15 or a higher version which outputs the "d" value in the SAM file
#
# Copyright (C) 2014 Charles Chiu - All Rights Reserved
# Permission to copy and modify is granted under the BSD license
# Last revised 3/21/2014

expected_args=6

if [ $# -lt $expected_args ]
then
	echo "Usage: snap_nt_combine.sh <FASTQ input file> <directory containing SNAP NT indexes> <number of cores> <free cache memory cutoff in GB> <SNAP d-value cutoff> <# of simultaneous SNAP runs>"
	exit 65
fi

###
inputfile=$1
SNAP_NT_index_directory=$2
cores=$3
free_cache_cutoff=$4
SNAP_d_cutoff=$5
simultaneous_SNAPs=$6
###

echo -n "starting: "
date
START1=$(date +%s)

echo "Found file $inputfile"
nopathf=${inputfile##*/} # remove the path to file
echo "After removing path: $nopathf"
basef=${nopathf%.fastq} # remove FASTQextension
echo "After removing FASTQ extension: $basef"

echo "Mapping $basef to NT..."

rm -f $basef.NT.sam

NTpartitionList=($SNAP_NT_index_directory/*)
NTpartitionList=("${NTpartitionList[@]}" "END")

curPosition=0
sizeList=${#NTpartitionList[@]}
snap_index=${NTpartitionList[curPosition]}

# echo "Number of NT partitions = "$sizeList

while [ $snap_index != "END" ]; do
	freemem=`free -g | awk '{print $4}' | head -n 2 | tail -1 | more`
	echo "There is $freemem GB available free memory...[cutoff=$free_cache_cutoff GB]"
	if [ $freemem -lt $free_cache_cutoff ]
	then
		echo "Clearing cache..."
		dropcache
	fi

	echo -n "starting: "
	date
	START2=$(date +%s)
######################## RUN SNAP ##########################

	numRuns=1
	while [ $snap_index != "END" ] && [ $numRuns -le $simultaneous_SNAPs ]; do
		nopathsnap_index=${snap_index##*/} # remove the path to file
		echo "Found $snap_index ... processing ..."
		/usr/bin/time -o $basef.$nopathsnap_index.snap.log snap single $snap_index $basef.fastq -o $basef.$nopathsnap_index.sam -t $cores -x -f -h 250 -d $SNAP_d_cutoff -n 25 > $basef.$nopathsnap_index.time.log &
		curPosition=`expr $curPosition + 1`
		snap_index=${NTpartitionList[curPosition]}
		numRuns=`expr $numRuns + 1`
	done

	for jobs in `jobs -p`
	do
		wait $job
	done

	sed '/^@/d' $basef.$nopathsnap_index.sam > $basef.$nopathsnap_index.noheader.sam &

	END2=$(date +%s)

	echo -n "Done to $snap_index "
	date
	diff=$(( $END2 - $START2 ))
	echo "Mapping to $snap_index took $diff seconds"
done

for jobs in `jobs -p`
do
	wait $job
done

#SNAP does not sort its results, so in order to compare files linearly, we need to sort them manually.
for file in *.noheader.sam
do
	sort --parallel=$cores $file > $file.sorted
done

# find the best alignment hit for each line
FILEARRAY=()
for snap_index in $SNAP_NT_index_directory/* ; do
	nopathsnap_index=${snap_index##*/} # remove the path to file
	FILEARRAY=("${FILEARRAY[@]}" "$basef.$nopathsnap_index.noheader.sam.sorted")
done

for jobs in `jobs -p`
do
	wait $job
done

FILEARRAY=("${FILEARRAY[@]}" "$basef.NT.sam")
# find the best alignment hit for each line
compare_multiple_sam.py ${FILEARRAY[@]}

#convertSam2Fastq.sh $basef.NT.sam

END1=$(date +%s)
echo -n "Done with SNAP_NT "
date
diff=$(( $END1 - $START1 ))
echo "output written to $basef.NT.sam"
echo "SNAP_NT took $diff seconds"
