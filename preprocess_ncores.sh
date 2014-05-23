#!/bin/bash
#                      
#	preprocess_ncores.sh
#
#	This script runs preprocessing across multiple cores (FASTA/FASTQ header modification, quality filtering, adapter trimming, and low-complexity filtering)
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# 4/22/13 - changed the extract headers from FASTQ to use 'extractHeaderFromFastq.csh' script
#
# Copyright (C) 2014 Charles Chiu - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
# Last revised 1/26/2014    

if [ $# != 11 ]; then
	echo "Usage: preprocess_ncores.sh <R1 FASTQ file> <S/I quality> <Y/N uniq> <length cutoff; 0 for no length cutoff> <# of cores> <Y/N clear_cache> <Y/N keep short reads> <adapter_set> <start_nt> <crop_length> <temporary_files_directory>"
	exit
fi

###
inputfile=$1
quality=$2
run_uniq=$3
length_cutoff=$4
cores=$5
clear_cache=$6
keep_short_reads=$7
adapter_set=$8
start_nt=$9
crop_length=${10}
temporary_files_directory=${11}
###
scriptname=${0##*/}

if [ ! -f $inputfile ];
then
	echo "$inputfile not found!"
	exit
fi

if [ $clear_cache = "Y" ]
then
    dropcache
fi

echo `date`
START1=$(date +%s)

echo "splitting $inputfile..."

let "numlines = `wc -l $inputfile | awk '{print $1}'`"
let "FASTQentries = numlines / 4"
echo -e "$(date)\t$scriptname\tthere are $FASTQentries FASTQ entries in $inputfile"
let "LinesPerCore = numlines / $cores"
let "FASTQperCore = LinesPerCore / 4"
let "SplitPerCore = FASTQperCore * 4"
echo -e "$(date)\t$scriptname\twill use $cores cores with $FASTQperCore entries per core"
echo -e "$(date)\t$scriptname\tquality is $quality"
echo -e "$(date)\t$scriptname\tuniq is $run_uniq"
echo -e "$(date)\t$scriptname\tlength cutoff is $length_cutoff"
echo -e "$(date)\t$scriptname\tkeep short reads? $keep_short_reads"
echo -e "$(date)\t$scriptname\tadapter_set is $adapter_set"
echo -e "$(date)\t$scriptname\tcropping will start at: $start_nt and extend for $crop_length more nt"

split -l $SplitPerCore $inputfile

END1=$(date +%s)
echo -e "$(date)\t$scriptname\tDone splitting: "
diff=$(( $END1 - $START1 ))
echo -e "$(date)\t$scriptname\tSPLITTING took $diff seconds"

echo -e "$(date)\t$scriptname\trunning preprocess script for each chunk..."

for f in `ls x??` 
do
	mv $f $f.fastq
	echo -e "$(date)\t$scriptname\tpreprocessing $f.fastq..."
	echo -e "$(date)\t$scriptname\tpreprocess.sh $f.fastq $quality N $length_cutoff $keep_short_reads $adapter_set $start_nt $crop_length >& $f.preprocess.log &"
	preprocess.sh $f.fastq $quality N $length_cutoff $keep_short_reads $adapter_set $start_nt $crop_length $temporary_files_directory >& $f.preprocess.log &
done

for job in `jobs -p`
do
	wait $job
done

echo -e "$(date)\t$scriptname\tdone preprocessing for each chunk..."

nopathf2=${1##*/}
basef2=${nopathf2%.fastq}

rm -f $basef2.cutadapt.fastq
rm -f $basef2.preprocessed.fastq
rm -f $basef2*.dusted.bad.fastq

for f in `ls x??.fastq`
do
	nopathf=${f##*/}
	basef=${nopathf%.fastq}
	cat $basef.preprocess.log >> $basef2.preprocess.log
	cat $basef.modheader.cutadapt.summary.log >> $basef2.cutadapt.summary.log
	cat $basef.modheader.adapterinfo.log >> $basef2.adapterinfo.log
	cat $basef.cutadapt.fastq >> $basef2.cutadapt.fastq
	cat $basef.cutadapt.cropped.fastq.log >> $basef2.cutadapt.cropped.fastq.log
	cat $basef.preprocessed.fastq >> $basef2.preprocessed.fastq
	cat $basef.cutadapt.cropped.dusted.bad.fastq >> $basef2.cutadapt.cropped.dusted.bad.fastq
done

for f in `ls x??.fastq`
do
	nopathf=${f##*/}
	basef=${nopathf%.fastq}
	rm -f $f
	rm -f $basef.modheader.fastq
	rm -f $basef.modheader.cutadapt.summary.log
	rm -f $basef.modheader.adapterinfo.log
	rm -f $basef.preprocess.log
	rm -f $basef.cutadapt.summary.log
	rm -f $basef.adapterinfo.log
	rm -f $basef.cutadapt.fastq
	rm -f $basef.cutadapt.cropped.fastq 
	rm -f $basef.cutadapt.cropped.fastq.log
	rm -f $basef.preprocessed.fastq
	rm -f $basef.cutadapt.cropped.dusted.bad.fastq 
done

echo -e "$(date)\t$scriptname\tdone concatenating output..."

if [ $run_uniq == "Y" ]; # selecting unique reads
then
	echo -e "$(date)\t$scriptname\tselecting unique reads"
	START3=$(date +%s)
	date
	# selecting unique reads
	sed "n;n;n;d" $basef2.preprocessed.fastq | sed "n;n;d" | sed "s/^@/>/g" > $basef2.preprocessed.fasta
	gt sequniq -force -o $basef2.uniq.fasta $basef2.preprocessed.fasta
	extractHeaderFromFastq.csh $basef2.uniq.fasta FASTA $basef2.preprocessed.fastq $basef2.uniq.fastq
	cp -f $basef2.uniq.fastq $basef2.preprocessed.fastq
	END3=$(date +%s)
	date
	diff3=$(( $END3 - $START3 ))
	echo -e "$(date)\t$scriptname\tUNIQ took $diff3 seconds"
else
	echo -e "$(date)\t$scriptname\tincluding duplicates (did not run UNIQ)"
fi

END2=$(date +%s)
date
diff2=$(( $END2 - $START1 ))

echo -e "$(date)\t$scriptname\tSPLITTING time: $diff seconds"

let "avgtime1=`cat $basef2.preprocess.log | grep "CUTADAPT" | awk '{print $3}' | sort | awk '{ a[i++]=$1} END {print a[int(i/2)];}'`"
echo -e "$(date)\t$scriptname\tmedian CUTADAPT time per core: $avgtime1 seconds"

if [ $run_uniq = "Y" ]; then
	let "avgtime2 = $diff3"
	echo -e "$(date)\t$scriptname\tUNIQ time: $diff3 seconds"
else
	let "avgtime2=0"
fi

let "avgtime3=`cat $basef2.preprocess.log | grep "DUST" | awk '{print $3}' | sort | awk '{ a[i++]=$1} END {print a[int(i/2)];}'`"
echo -e "$(date)\t$scriptname\tmedian DUST time per core: $avgtime3 seconds"

let "totaltime = diff + avgtime1 + avgtime2 + avgtime3"
echo -e "$(date)\t$scriptname\tTOTAL TIME: $totaltime seconds"

echo -e "$(date)\t$scriptname\tTOTAL CLOCK TIME (INCLUDING OVERHEAD): $diff2 seconds"
