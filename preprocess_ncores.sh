#!/bin/bash
#
#	preprocess_ncores.sh
#
#	This script runs preprocessing across multiple cores (FASTA/FASTQ header modification, quality filtering, adapter trimming, and low-complexity filtering)
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
#
# Copyright (C) 2014 Charles Chiu - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.

scriptname=${0##*/}
source logging.sh

if [ $# != 11 ]; then
	echo "Usage: $scriptname <R1 FASTQ file> <S/I quality> <Y/N uniq> <length cutoff; 0 for no length cutoff> <# of cores> <free cache memory cutoff in GB> <Y/N keep short reads> <adapter_set> <start_nt> <crop_length> <temporary_files_directory> <quality_cutoff>"
	exit
fi

###
inputfile=$1
quality=$2
run_uniq=$3
length_cutoff=$4
cores=$5
keep_short_reads=$6
adapter_set=$7
start_nt=$8
crop_length=${9}
temporary_files_directory=${10}
quality_cutoff=${11}
###

if [ ! -f $inputfile ]
then
	echo "$inputfile not found!"
	exit
fi

START=$(date +%s)

log "Splitting $inputfile..."

let "numlines = `wc -l $inputfile | awk '{print $1}'`"
let "FASTQentries = numlines / 4"
log "There are $FASTQentries FASTQ entries in $inputfile"
let "LinesPerCore = numlines / $cores"
# Prevent leaving a small remainder file after split by adding 1.
let "FASTQperCore = LinesPerCore / 4 + 1"
let "SplitPerCore = FASTQperCore * 4"
log "will use $cores cores with $FASTQperCore entries per core"

split -l $SplitPerCore $inputfile

END_SPLIT=$(date +%s)
diff_SPLIT=$(( END_SPLIT - START ))

log "Done splitting: "
log "SPLITTING took $diff_SPLIT seconds"

log "Running preprocess script for each chunk..."

for f in x??
do
	mv $f $f.fastq
	log "preprocess.sh $f.fastq $quality N $length_cutoff $keep_short_reads $adapter_set $start_nt $crop_length $temporary_files_directory >& $f.preprocess.log &"
	preprocess.sh $f.fastq $quality N $length_cutoff $keep_short_reads $adapter_set $start_nt $crop_length $temporary_files_directory $quality_cutoff >& $f.preprocess.log &
done

for job in `jobs -p`
do
	wait $job
done

log "Done preprocessing for each chunk..."

nopathf2=${1##*/}
basef2=${nopathf2%.fastq}

rm -f $basef2.cutadapt.fastq
rm -f $basef2.preprocessed.fastq
rm -f $basef2*.dusted.bad.fastq

for f in x??.fastq
do
	nopathf=${f##*/}
	basef=${nopathf%.fastq}
	cat $basef.preprocess.log >> $basef2.preprocess.log
	rm -f $basef.preprocess.log
	cat $basef.modheader.cutadapt.summary.log >> $basef2.cutadapt.summary.log
	rm -f $basef.modheader.cutadapt.summary.log
	cat $basef.modheader.adapterinfo.log >> $basef2.adapterinfo.log
	rm -f $basef.modheader.adapterinfo.log
	cat $basef.cutadapt.fastq >> $basef2.cutadapt.fastq
	rm -f $basef.cutadapt.fastq
	cat $basef.cutadapt.cropped.fastq.log >> $basef2.cutadapt.cropped.fastq.log
	rm -f $basef.cutadapt.cropped.fastq.log
	cat $basef.preprocessed.fastq >> $basef2.preprocessed.fastq
	rm -f $basef.preprocessed.fastq
	cat $basef.cutadapt.cropped.dusted.bad.fastq >> $basef2.cutadapt.cropped.dusted.bad.fastq
	rm -f $basef.cutadapt.cropped.dusted.bad.fastq

	rm -f $f
	rm -f $basef.modheader.fastq
	rm -f $basef.cutadapt.summary.log
	rm -f $basef.adapterinfo.log
	rm -f $basef.cutadapt.cropped.fastq
done

log "Done concatenating output..."

if [ $run_uniq == "Y" ]; # selecting unique reads
then
	log "Selecting unique reads"
	START_UNIQ=$(date +%s)
	# selecting unique reads
	sed "n;n;n;d" $basef2.preprocessed.fastq | sed "n;n;d" | sed "s/^@/>/g" > $basef2.preprocessed.fasta
	gt sequniq -force -o $basef2.uniq.fasta $basef2.preprocessed.fasta
	extractHeaderFromFastq.csh $basef2.uniq.fasta FASTA $basef2.preprocessed.fastq $basef2.uniq.fastq
	cp -f $basef2.uniq.fastq $basef2.preprocessed.fastq
	END_UNIQ=$(date +%s)
	diff_UNIQ=$(( END_UNIQ - START_UNIQ ))
	log "UNIQ took $diff_UNIQ seconds"
else
	log "Including duplicates (did not run UNIQ)"
fi

END=$(date +%s)
diff_TOTAL=$(( END - START ))

let "avgtime1=`grep CUTADAPT $basef2.preprocess.log | awk '{print $12}' | sort -n | awk '{ a[i++]=$1} END {print a[int(i/2)];}'`"
log "median CUTADAPT time per core: $avgtime1 seconds"

if [ $run_uniq = "Y" ]; then
	let "avgtime2 = $diff_UNIQ"
	log "UNIQ time: $diff_UNIQ seconds"
else
	let "avgtime2=0"
fi

let "avgtime3=`grep DUST $basef2.preprocess.log | awk '{print $12}' | sort -n | awk '{ a[i++]=$1} END {print a[int(i/2)];}'`"
log "median DUST time per core: $avgtime3 seconds"

let "totaltime = diff_SPLIT + avgtime1 + avgtime2 + avgtime3"
log "TOTAL TIME: $totaltime seconds"

log "TOTAL CLOCK TIME (INCLUDING OVERHEAD): $diff_TOTAL seconds"
