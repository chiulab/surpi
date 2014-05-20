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
# Last revised 5/19/2014


if [ $# -lt 4 ]
then
	echo "<#cores> <parent file fq> <query1 sam> <output fq> <query2 sam> <output2 fq>"
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

date=$(date)

echo "$date | Starting splitting $inputfile "

#deriving # of lines to split
headerid=$(head -1 $parentfile | cut -c1-4)
date=$(date)
echo "$date | headerid = $headerid"
echo "$date | Starting grep of FASTQentries"
FASTQentries=$(grep -c "$headerid" $parentfile)
date=$(date)
echo "$date | there are $FASTQentries FASTQ entries in $queryfile"
let "numlines = $FASTQentries * 4"
echo "$date | numlines = $numlines"
let "FASTQPerCore = $FASTQentries / $cores"
echo "$date | FASTQPerCore = $FASTQPerCore"
let "LinesPerCore = $FASTQPerCore * 4"
echo "$date | LinesPerCore = $LinesPerCore"

#splitting
date=$(date)
echo "$date | splitting $parentfile into $cores parts with prefix $parentfile.SplitXS"
split -l $LinesPerCore -a 3 $parentfile $parentfile.SplitXS &
awk '{print$1}' $queryfile > $queryfile.header &
date=$(date)
echo "$date | extracting header from $queryfile" &

for job in `jobs -p`
do
	wait $job
done

date=$(date)
echo "$date | Done splitting $parentfile into $cores parts with prefix $parentfile.SplitXS, and Done extracting $queryfile.header"

# retrieving fastqs
date=$(date)
echo "$date | Starting retrieval of $queryfile headers from each $parentfile subsection"
for f in $parentfile.SplitXS[a-z][a-z][a-z]
do
	cat $f | fqextract $queryfile.header > $queryfile.$f &
done

for job in `jobs -p`
do
	wait $job
done

# concatenating split retrieves into output file
date=$(date)
echo "$date | Starting concatenation of all $queryfile.$parentfile.SplitXS"
cat $queryfile.$parentfile.SplitXS[a-z][a-z][a-z] > $output
date=$(date)
echo "$date | Done generating $output"

# need to fix this so that there's a conditional trigger of this second query file retrieval
echo "processing second query file"
awk '{print$1}' $queryfile2 > $queryfile2.header

for f in $parentfile.SplitXS[a-z][a-z][a-z]
do
	cat $f | fqextract $queryfile2.header > $queryfile2.$f &
done

for job in `jobs -p`
do
	wait $job
done

date=$(date)
echo "$date | Done retrieval of $queryfile2 headers from each $parentfile subsection"
date=$(date)
echo "$date | Starting concatenation of all $queryfile2.$parentfile.SplitXS"
cat $queryfile2.$parentfile.SplitXS[a-z][a-z][a-z] > $output2
date=$(date)
echo "$date | Done generating $output2"
rm -f $queryfile2.header
rm -f $queryfile2.$parentfile.SplitXS[a-z][a-z][a-z]	

#cleanup
rm -f $queryfile.header
rm -f $queryfile.$parentfile.SplitXS[a-z][a-z][a-z]
rm -f $parentfile.SplitXS[a-z][a-z][a-z]
