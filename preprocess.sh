#!/bin/bash
#
#	preprocess.sh
#
#	This script preprocesses a FASTQ-formatted file
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# cutadapt=>crop->dust removal (no uniq) ***
#                                                                                                                                
# 12/20/12 - modified to switch to cutadapt for trimming
# 12/31/12 - modified from Cshell to BASH version for timing
#
# Copyright (C) 2014 Charles Chiu - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
# Last revised 8/11/2014    

if [ $# != 9 ]; then
	echo "Usage: preprocess.sh <R1 FASTQ file> <S/I quality> <Y/N uniq> <length_cutoff; 0 for no length_cutoff> <Y/N keep short reads> <adapter_set> <start_nt> <crop_length> <temporary_files_directory>"
	exit
fi

###
inputfile=$1
quality=$2
run_uniq=$3
length_cutoff=$4
keep_short_reads=$5
adapter_set=$6
start_nt=$7
crop_length=$8
temporary_files_directory=$9
###
scriptname=${0##*/}

if [ ! -f $inputfile ];
then
	echo "$inputfile not found!"
	exit
fi

if [ $quality = "S" ]
then
	echo -e "$(date)\t$scriptname\tselected Sanger quality"
else
	echo -e "$(date)\t$scriptname\tselected Illumina quality"
fi

# fix header if space is present
s=`head -1 $inputfile | awk '{if ($0 ~ / /) {print "SPACE"} else {print "NOSPACE"}}'`

echo -e "$(date)\t$scriptname\t$s in header"

nopathf=${1##*/}
basef=${nopathf%.fastq}

#################### START OF PREPROCESSING, READ1 #########################

# run cutadapt, Read1
echo -e "$(date)\t$scriptname\t********** running cutadapt, Read1 **********"
if [ $s == "SPACE" ]
then
	sed "s/\([@HWI|@M00135|@SRR][^ ]*\) \(.\):.:0:\(.*\)/\1#\3\/\2/g" $inputfile > $basef.modheader.fastq
	# modified to take into account anything in there [N or Y]
	START1=$(date +%s)
	cutadapt_quality.csh $basef.modheader.fastq $quality $length_cutoff $keep_short_reads $adapter_set $temporary_files_directory
	mv $basef.modheader.cutadapt.fastq $basef.cutadapt.fastq
	rm -f $basef.modheader.fastq
else
	START1=$(date +%s)
	cutadapt_quality.csh $inputfile $quality $length_cutoff $keep_short_reads $adapter_set $temporary_files_directory
fi

END1=$(date +%s)
diff=$(( $END1 - $START1 ))
echo -e "$(date)\t$scriptname\tDone cutadapt: CUTADAPT took $diff seconds"

# run uniq, Read1
if [ $run_uniq == "Y" ]
then
	echo -e "$(date)\t$scriptname\t********** running uniq, Read1 **********"
	START1=$(date +%s)

	if [ $quality = "S" ]
	then
		fastq filter --unique --adjust 64 $basef.cutadapt.fastq > $basef.cutadapt.uniq.fastq
	else
		fastq filter --unique --adjust 32 $basef.cutadapt.fastq > $basef.cutadapt.uniq.fastq
	fi

	END1=$(date +%s)
	diff=$(( $END1 - $START1 ))
	echo -e "$(date)\t$scriptname\tDone uniq: UNIQ took $diff seconds"
fi

# run crop, Read 1
echo -e "$(date)\t$scriptname\t********** running crop, Read1 **********"
START1=$(date +%s)

if [ $run_uniq == "Y" ] 
then
	echo -e "$(date)\t$scriptname\tWe will be using $crop_length as the length of the cropped read"
	crop_reads.csh $basef.cutadapt.uniq.fastq $start_nt $crop_length > $basef.cutadapt.uniq.cropped.fastq
else
	echo -e "$(date)\t$scriptname\tWe will be using $crop_length as the length of the cropped read"
	crop_reads.csh $basef.cutadapt.fastq $start_nt $crop_length > $basef.cutadapt.cropped.fastq
fi

END1=$(date +%s)
diff=$(( $END1 - $START1 ))
echo -e "$(date)\t$scriptname\tDone crop: CROP took $diff seconds"

# run dust, Read1
echo -e "$(date)\t$scriptname\t********** running dust, Read1 **********"
START1=$(date +%s)

if [ $run_uniq == "Y" ] 
then
	prinseq-lite.pl -fastq $basef.cutadapt.uniq.cropped.fastq -out_format 3 -out_good $basef.cutadapt.uniq.cropped.dusted -out_bad $basef.cutadapt.uniq.cropped.dusted.bad -log -lc_method dust -lc_threshold 7
	mv -f $basef.cutadapt.uniq.cropped.dusted.fastq $basef.preprocessed.fastq
else
	prinseq-lite.pl -fastq $basef.cutadapt.cropped.fastq -out_format 3 -out_good $basef.cutadapt.cropped.dusted -out_bad $basef.cutadapt.cropped.dusted.bad -log -lc_method dust -lc_threshold 7
	mv -f $basef.cutadapt.cropped.dusted.fastq $basef.preprocessed.fastq
fi

END1=$(date +%s)
diff=$(( $END1 - $START1 ))
echo -e "$(date)\t$scriptname\tDone dust: DUST took $diff seconds"
