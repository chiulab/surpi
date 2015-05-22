#!/bin/bash
#
#	extractHeaderFromFastq_ncores
#
# 	script to retrieve fastq entries given a list of headers, when fastq entries reside in a large parent file (fqextract fails)
# 	Chiu Laboratory
# 	University of California, San Francisco
# 	3/15/2014
#
#
# Copyright (C) 2014 Samia N Naccache, Scot Federman, and Charles Y Chiu - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.

scriptname=${0##*/}

if [ $# -lt 4 ]
then
	echo "Usage: $scriptname <#cores> <parent file fq> <query1 sam> <output fq> <query2 sam> <output2 fq>"
	exit 65
fi

###
cores="$1"
parentfile="$2"
queryfile="$3"
output="$4"
queryfile2="$5"
output2="$6"
###

echo -e "$(date)\t$scriptname\tStarting splitting $inputfile"

#deriving # of lines to split
headerid=$(head -1 $parentfile | cut -c1-4)
echo -e "$(date)\t$scriptname\theaderid = $headerid"
echo -e "$(date)\t$scriptname\tStarting grep of FASTQentries"
FASTQentries=$(grep -c "$headerid" $parentfile)
echo -e "$(date)\t$scriptname\tthere are $FASTQentries FASTQ entries in $queryfile"
let "numlines = $FASTQentries * 4"
echo -e "$(date)\t$scriptname\tnumlines = $numlines"
let "FASTQPerCore = $FASTQentries / $cores"
echo -e "$(date)\t$scriptname\tFASTQPerCore = $FASTQPerCore"
let "LinesPerCore = $FASTQPerCore * 4"
echo -e "$(date)\t$scriptname\tLinesPerCore = $LinesPerCore"

#splitting
echo -e "$(date)\t$scriptname\tSplitting $parentfile into $cores parts with prefix $parentfile.SplitXS"
split -l $LinesPerCore -a 3 $parentfile $parentfile.SplitXS &
awk '{print$1}' $queryfile > $queryfile.header &
echo -e "$(date)\t$scriptname\textracting header from $queryfile"

for job in $(jobs -p)
do
	wait $job
done

echo -e "$(date)\t$scriptname\tDone splitting $parentfile into $cores parts with prefix $parentfile.SplitXS, and Done extracting $queryfile.header"

# retrieving fastqs
echo -e "$(date)\t$scriptname\tStarting retrieval of $queryfile headers from each $parentfile subsection"

let "adjusted_cores = $cores / 4"

parallel --gnu -j $adjusted_cores "cat {} | fqextract $queryfile.header > $queryfile.{}" ::: $parentfile.SplitXS[a-z][a-z][a-z]

# concatenating split retrieves into output file
echo -e "$(date)\t$scriptname\tStarting concatenation of all $queryfile.$parentfile.SplitXS"
cat $queryfile.$parentfile.SplitXS[a-z][a-z][a-z] > $output
echo -e "$(date)\t$scriptname\tDone generating $output"

# need to fix this so that there's a conditional trigger of this second query file retrieval
echo -e "$(date)\t$scriptname\tprocessing second query file"
awk '{print$1}' $queryfile2 > $queryfile2.header

echo -e "$(date)\t$scriptname\tparallel -j $adjusted_cores -i bash -c cat {} | fqextract $queryfile2.header > $queryfile2.{} -- $parentfile.SplitXS[a-z][a-z][a-z]"
parallel --gnu -j $adjusted_cores "cat {} | fqextract $queryfile2.header > $queryfile2.{}" ::: $parentfile.SplitXS[a-z][a-z][a-z]

echo -e "$(date)\t$scriptname\tDone retrieval of $queryfile2 headers from each $parentfile subsection"
echo -e "$(date)\t$scriptname\tStarting concatenation of all $queryfile2.$parentfile.SplitXS"
cat $queryfile2.$parentfile.SplitXS[a-z][a-z][a-z] > $output2
echo -e "$(date)\t$scriptname\tDone generating $output2"
rm -f $queryfile2.header
rm -f $queryfile2.$parentfile.SplitXS[a-z][a-z][a-z]

#cleanup
rm -f $queryfile.header
rm -f $queryfile.$parentfile.SplitXS[a-z][a-z][a-z]
rm -f $parentfile.SplitXS[a-z][a-z][a-z]
