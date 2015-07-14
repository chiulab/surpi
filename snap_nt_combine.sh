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

expected_args=5
scriptname=${0##*/}

if [ $# -lt $expected_args ]
then
	echo "Usage: $scriptname <FASTQ input file> <directory containing SNAP NT indexes> <number of cores> <free cache memory cutoff in GB> <SNAP d-value cutoff> <# of simultaneous SNAP runs>"
	exit 65
fi

###
inputfile=$1
SNAP_NT_index_directory=$2
cores=$3
SNAP_d_cutoff=$4
simultaneous_SNAPs=$5
###

echo -e "$(date)\t$scriptname\tStarting SNAP to NT"
START1=$(date +%s)

echo -e "$(date)\t$scriptname\tInput file: $inputfile"
nopathf=${inputfile##*/} # remove the path to file
echo -e "$(date)\t$scriptname\tAfter removing path: $nopathf"
basef=${nopathf%.fastq} # remove FASTQextension
echo -e "$(date)\t$scriptname\tAfter removing FASTQ extension: $basef"

echo -e "$(date)\t$scriptname\tMapping $basef to NT..."

# rm -f $basef.NT.sam # this is removing the output file, if it is present? Should not be necessary, but commenting out for now.

for snap_index in $SNAP_NT_index_directory/*; do
	START2=$(date +%s)
	nopathsnap_index=${snap_index##*/} # remove the path to file
	echo -e "$(date)\t$scriptname\tStarting SNAP on $nopathsnap_index"

	START_SNAP=$(date +%s)
	/usr/bin/time -o $basef.$nopathsnap_index.snap.log snap single $snap_index $basef.fastq -o $basef.$nopathsnap_index.sam -t $cores -x -f -h 250 -d $SNAP_d_cutoff -n 25 > $basef.$nopathsnap_index.time.log
	SNAP_DONE=$(date +%s)
	snap_time=$(( SNAP_DONE - START_SNAP ))
	echo -e "$(date)\t$scriptname\tCompleted running SNAP using $snap_index in $snap_time seconds."

	echo -e "$(date)\t$scriptname\tRemoving headers..."
	START_HEADER_REMOVAL=$(date +%s)
	sed '/^@/d' $basef.$nopathsnap_index.sam > $basef.$nopathsnap_index.noheader.sam
	END_HEADER_REMOVAL=$(date +%s)
	header_removal_time=$(( END_HEADER_REMOVAL - START_HEADER_REMOVAL ))
	echo -e "$(date)\t$scriptname\tCompleted removing headers in $header_removal_time seconds."

	END2=$(date +%s)
	diff=$(( END2 - START2 ))
	echo -e "$(date)\t$scriptname\tMapping to $snap_index took $diff seconds"
done

#SNAP does not sort its results, so in order to compare files linearly, we need to sort them manually.
echo -e "$(date)\t$scriptname\tSorting..."
START_SORT=$(date +%s)

# did some testing with optimizing the number of simultaneous sorts - maximizing this number was the speediest, so no need for GNU parallel - SMF 5/22/14
# parallel -j $cores "sort {} > {}.sorted;" ::: *.noheader.sam

for file in *.noheader.sam
do
	sort $file > $file.sorted &
done

for jobs in `jobs -p`
do
	wait $job
done
END_SORT=$(date +%s)
sort_time=$(( END_SORT - START_SORT ))
echo -e "$(date)\t$scriptname\tCompleted sorting in $sort_time seconds."

# find the best alignment hit for each line
FILEARRAY=()
for snap_index in $SNAP_NT_index_directory/* ; do
	nopathsnap_index=${snap_index##*/} # remove the path to file
	FILEARRAY=("${FILEARRAY[@]}" "$basef.$nopathsnap_index.noheader.sam.sorted")
done

echo -e "$(date)\t$scriptname\tStarting comparison of all SAM files."
START_COMPARE=$(date +%s)
FILEARRAY=("${FILEARRAY[@]}" "$basef.NT.sam")
# find the best alignment hit for each line
compare_multiple_sam.py ${FILEARRAY[@]}
END1=$(date +%s)
comparison_time=$(( END1 - START_COMPARE ))
echo -e "$(date)\t$scriptname\tComparison took $comparison_time seconds."

echo -e "$(date)\t$scriptname\tDone with SNAP_NT "
diff=$(( END1 - START1 ))
echo -e "$(date)\t$scriptname\toutput written to $basef.NT.sam"
echo -e "$(date)\t$scriptname\tSNAP_NT took $diff seconds"

#delete intermediate SAM files
rm *.noheader.sam
rm *.noheader.sam.sorted
for snap_index in $SNAP_NT_index_directory/* ; do
	nopathsnap_index=${snap_index##*/} # remove the path to file
	rm *.$nopathsnap_index.sam
done
