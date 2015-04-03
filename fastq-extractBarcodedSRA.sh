#!/bin/bash
#
#	fastq-extractBarcodedSRA.sh
#
#	This program extracts individually barcoded fastq files from an SRA
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# Copyright (C) 2014 Charles Chiu - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.

scriptname=${0##*/}

if [ $# -lt 1 ]; then
    echo "Usage: $scriptname <SRA file>"
    exit
fi

# 
# gets absolute path to SRA file
#
SRA_PATH=$(readlink -e $1)
echo -e "$(date)\t$scriptname\tExtracting individually barcoded FASTQ files from $SRA_PATH"
#
# extract SRA to FASTQ files
fastq-dump --split-files -G $SRA_PATH
nopathSRA_PATH=${SRA_PATH##*/}

header=$(echo $nopathSRA_PATH | sed 's/.sra//g')

files=($header*.fastq)

# restore barcode and R1/R2 designation to FASTQ headers
for f in "${files[@]}"
do 
    barcode=$(echo "$f" | sed 's/_[12]//g' | sed 's/.fastq//g' | sed 's/.*_//g')
    readnum=$(echo "$f" | sed 's/.*_\([12]\).fastq/\1/g' | sed '/'$header'/d')
    echo -e "$(date)\t$scriptname\tRestoring barcode # $barcode and R1/R2 designation to $f"
    OUTPUTF=$(echo "$f" | sed 's/^/bc/g')
    if [ "$readnum" = "1" ] || [ "$readnum" = "2" ]
    then
		cat $f | sed 's/[[:blank:]]/_/g' | sed 's/\(^[@+]'$header'.*\)/\1#'$barcode'\/'$readnum'/g' > $OUTPUTF
    else
		cat $f | sed 's/[[:blank:]]/_/g' | sed 's/\(^[@+]'$header'.*\)/\1#'$barcode'/g' > $OUTPUTF
    fi
done
