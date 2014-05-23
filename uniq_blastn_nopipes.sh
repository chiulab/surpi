#!/bin/bash
#
#	uniq_blastn_nopipes.sh
#
#	input: m8 tabular output with multiple resutlts for a single record (header). Provides an output with only one result per record, based on the result with the smallest e value
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# Copyright (C) 2014 Samia N Naccache - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
# Last revised 5/20/2014    

if [ $# = 0 ]
then
	echo "Usage:_uniq_blastn.sh <blastn>"
	exit
fi

scriptname=${0##*/}

echo -e "$(date)\t$scriptname\tStarting uniq sort on $1"
sort -k1,1 -k11,11g $1 | sed 's/\t/,/g' | sort -u -t, -k 1,1 | sed 's/,/\t/g' > $1.uniq
echo -e "$(date)\t$scriptname\tDone uniq sort on = $1"
