#!/bin/bash
#
#	readcount.sh
#
#	script to generate readcount table
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014 3/15/2014
#
#
# Copyright (C) 2014 Samia N Naccache, Scot Federman, and Charles Y Chiu - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
# Last revised 1/26/2014    
if [ $# -lt 12 ]
then
	echo "Usage: <base name> <header common string> <multiple barcodes Y/N default Y> <raw> <preproc> <unmatchedhum> <matchedNT> <matchedNTVir> <matchedNTBac> <matchedNTnonchoreuk> <unmatchedNT> <matchedRapVir>"
	echo "if you want to count more files, add to commandline"
	echo "assumes # is the delimitor for barcode"
	exit
fi


#common string is the part of header that is common among all read headers in file (e.g. HWI M00 M02 SCS SRR )
###
basef="${1}"
headerid="${2}"
multiplexed="${3}"
# order of file names to count
four="${4}"
five="${5}"
six="${6}"
seven="${7}"
eight="${8}"
nine="${9}"
ten="${10}"
eleven="${11}"
twelve="${12}"
###
scriptname=${0##*/}

##### Generating total report#######
##### total report is a list of all files and readcounts per file, all files are entered as variables 4->

echo -e "$(date)\t$scriptname\tStarting: generating readcounts.$basef.Total.log report"
START1=$(date +%s)

echo "Total_readcounts_$basef" > readcounts.$basef.Total.temp 

for f in $four $five $six $seven $eight $nine $ten $eleven $twelve
do
	#establishing appropriate headerid prefix (for fastq = @M00 for .sam = M00 for example.	
	headeridwithprefix=$(grep -m 1 "$headerid" $f | sed 's/'$headerid'/'$headerid' /g' | awk '{print$1}')
	echo -e "$(date)\t$scriptname\tcounting total reads in $f using $headeridwithprefix as string"
	#counting occurrences of headerid
	echo -n "$f " >> readcounts.$basef.Total.temp
	egrep -c "^$headeridwithprefix" $f >> readcounts.$basef.Total.temp
done

cp readcounts.$basef.Total.temp readcounts.$basef.log

echo -e "$(date)\t$scriptname\tDone: generating readcounts.$1.Total.log report"
END1=$(date +%s)
diff=$(( END1 - START1 ))
echo -e "$(date)\t$scriptname\tGenerating Total read count report Took $diff seconds"

#### Generating # reads by barcode ########
if [ $multiplexed = "Y" ]
then 
	touch readcounts.$basef.BarcodeR12.log
	mv readcounts.$basef.BarcodeR12.log readcounts.$basef.BarcodeR1R2.log # to ensure a new file gets created each time, since us$

	echo "Total_readcounts_$basef" > readcounts.$basef.Barcode.temp

	for f in $four $five $six $seven $eight $nine $ten $eleven $twelve
	do
		headeridwithprefix=$(grep -m 1 "$headerid" $f | sed 's/'$headerid'/'$headerid' /g' | awk '{print$1}')

		echo -e "$(date)\t$scriptname\tcounting number of reads per barcode in $f using $headerwithprefix"
		echo "$f" > $f.readcounts.$basef.Barcode.temp
		grep "$headeridwithprefix" $f | sed 's/#/ /g' | awk '{print$2}' | sort | uniq -c >> $f.readcounts.$basef.Barcode.temp 
		
		# generate general readcounts.$basef.log with readcounts for R1 and R2 separate               
		cat $f.readcounts.$basef.Barcode.temp >> readcounts.$basef.log
		
		# generate a .temp file with R1 and R2 counts combined. awk retrieved online for adding column 1 numbers if column2 is same
		sed 's/\/[1-2]/\//g' $f.readcounts.$basef.Barcode.temp | sed 's/[1-2]:N:0://g' | sed '/'$basef'/d' | awk '{arr[$2]+=$1} END {for (i in arr) {print i,arr[i]}}' | sed 's/^/#/g' | sort -r -g -k 1 | sed 's/^/'$f'\t/g' > $f.readcounts.$basef.BarcodeR1R2.temp
		cat $f.readcounts.$basef.BarcodeR1R2.temp >> readcounts.$basef.BarcodeR1R2.log
	done
fi

#### Generating Readcount matrix for each barcode ####
## remove / because file names can't be made with / in them
#sed 's/\///g' readcounts.$basef.BarcodeR1R2.log | sed '/@/d' > readcounts.$basef.BarcodeR1R2.log.tmp

## make a list of barcodes without /
#awk '{print$2}' readcounts.$basef.BarcodeR1R2.log.tmp | sort | uniq > readcounts.$basef.BarcodeR1R2.log.barcodeslist.tmp

#	for f in `cat readcounts.$basef.BarcodeR1R2.log.barcodeslist.tmp`
#		do
#		echo "$f $f" > readcounts.$f.$basef.BarcodeR1R2.tmp
#		grep "$f" readcounts.$basef.BarcodeR1R2.log.tmp | awk '{print$1,$3}' >> readcounts.$f.$basef.BarcodeR1R2.tmp
#	done 
#rm -f *readcounts*$basef.*tmp

rm -f *readcounts*$basef.*temp
echo -e "$(date)\t$scriptname\tdone readcount generation "
END2=$(date +%s)
diff=$(( END2 - START1 ))
echo -e "$(date)\t$scriptname\treadcount generation took $diff"
