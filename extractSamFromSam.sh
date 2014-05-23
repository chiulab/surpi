#!/bin/bash
#     
#	extactSamFromSam.sh
# 
#	extract SAM reads corresponding to a SAM header file from another SAM reference file and writes to
#	SAM output file
# 	Chiu Laboratory
# 	University of California, San Francisco
# 	3/15/2014
#
# Copyright (C) 2014 Charles Y Chiu - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
# Last revised 5/19/2014

if [ $# -lt 3 ]; then
    echo "Usage: extractSamFromSam.sh <SAM header file> <SAM reference file> <SAM output file> <optional: # of cores>"
    exit
fi

###
basef=$1
baseg=$2
output_file=$3
cores=$4
###
scriptname=${0##*/}

echo -e "$(date)\t$scriptname\tstarting: "
START1=$(date +%s)

if [ $# -lt 4 ]; then  # using 1 core only
    echo -e "$(date)\t$scriptname\textracting reads from $baseg using headers from $basef..."
    # associative array for lookup
    awk 'FNR==NR { a[$1]=$1; next} $1 in a {print $0}' "$basef" "$baseg" > $output_file
    echo -e "$(date)\t$scriptname\tdone"
else
# splitting input SAM header file by number of cores
    echo -e "$(date)\t$scriptname\tsplitting $basef..."
    let "numlines = `wc -l basef | awk '{print $1}'`"
    let "LinesPerCore = numlines / $cores"
    echo -e "$(date)\t$scriptname\twill use $cores cores with $LinesPerCore entries per core"
    
    split -l $LinesPerCore $basef

    echo -e "$(date)\t$scriptname\textracting reads from $baseg using headers from $basef"
    rm -f $output_file  # delete previous output file, if present

    for f in `ls x??`
    do
    # associative array for lookup, running in background
        awk 'FNR==NR { a[$1]=$1; next} $1 in a {print $0)}' "$f" "$baseg" >> $output_file &
    done

    for job in `jobs -p`
    do
		wait $job
    done

    echo -e "$(date)\t$scriptname\tdone extracting reads for each chunk"
    rm -f x??
fi

END1=$(date +%s)
echo -e "$(date)\t$scriptname\tDone with extractSamFromSam.sh"
diff=$(( $END1 - $START1 ))
echo -e "$(date)\t$scriptname\textractSamFromSam.sh took $diff seconds"
