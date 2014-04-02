#!/bin/csh
#
# 	cutadapt_quality.csh
#
#	runs cutadapt to remove primer sequences from Illumina files
#	also accepts a quality argument for Illumina / Sanger quality 
#	user specifies length cutoff
#	user specifies whether short reads less than length cutoff are kept; if so, they are converted to size=1
#
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# *** modified by Scot Federman, 2013 ***
#     -- Added TEMPDIR var for portability to AWS
#     -- TEMPDIR specifies a directory that can be used for temp storage during the life of this program execution
#     -- AWS typically has boot volumes of only 8GB, which is too small for the data created.
#
# Copyright (C) 2014 Charles Chiu - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
# Last revised 1/26/2014    

set TEMPDIR = "/tmp/"
                                                                                                             
if ($#argv != 5) then
	echo "Usage: cutadapt_quality.csh <input FASTQ file> <quality S/I> <length cutoff> <keep short reads Y/N> <adapter_set>"
	exit(1)
endif

###
set inputfile = $argv[1]
set quality = $argv[2]
set length_cutoff = $argv[3]
set keep_short_reads = $argv[4]
set adapter_set = $argv[5]
###

set numreads_start = `egrep -c "@HWI|@M00|@SRR" $inputfile`
echo $numreads_start" reads at beginning of cutadapt"

if ($quality == "S") then
	echo "Quality is Sanger, quality filtering <15 by default"
	set qual = 33
else
	echo "Quality is Illumina, quality filtering <15 by default"
	set qual = 64
endif

if ($adapter_set == "Truseq") then
	if ($keep_short_reads == "N") then # delete short reads
		cutadapt -g GTTTCCCACTGGAGGATA -a TATCCTCCAGTGGGAAAC -a AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGTAGATCTCGGTGGTCGCCGTATCATT -g GTGACTGGAGTTCAGACGTGTGCTCTTCCGATC -a GATCGGAAGAGCACACGTCTGAACTCCAGTCAC -a AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATC -n 15 -O 10 -q 15 -m $length_cutoff --quality-base=$qual -o $TEMPDIR{$$} --info-file=$inputfile:r.adapterinfo.log $inputfile > $inputfile:r.cutadapt.summary.log
		echo -n "****** removing reads of size less than "
		echo -n $length_cutoff
		echo " bp ******"
		sed 's/^$/N/g' $TEMPDIR{$$} > $inputfile:r.cutadapt.fastq
	else
		cutadapt -g GTTTCCCACTGGAGGATA -a TATCCTCCAGTGGGAAAC -a AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGTAGATCTCGGTGGTCGCCGTATCATT -g GTGACTGGAGTTCAGACGTGTGCTCTTCCGATC -a GATCGGAAGAGCACACGTCTGAACTCCAGTCAC -a AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATC -n 15 -O 10 -q 15 --quality-base=$qual -o $TEMPDIR{$$} --info-file=$inputfile:r.adapterinfo.log $inputfile > $inputfile:r.cutadapt.summary.log
		# convert entries <50 to size=1 ("N")
		echo -n "****** converting reads of size less than "
		echo -n $length_cutoff
		echo " bp to N ******"
		sed 's/^$/N/g' $TEMPDIR{$$} | awk 'NR%2==1 {print $0} NR%2==0 {if ( length ( $0 ) < '$length_cutoff') print "N"; else print $0}' > $inputfile:r.cutadapt.fastq
	endif
else if ($adapter_set == "Nextera") then
	if ($keep_short_reads == "N") then # delete short reads
		cutadapt -a CTGTCTCTTATACACATCTCCGAGCCCACGAGAC -a CTGTCTCTTATACACATCTGACGCTGCCGACGA -a CTGTCTCTTATACACATCT -n 15 -O 15 -q 15 -m $length_cutoff --quality-base=$qual -o $TEMPDIR{$$} --info-file=$inputfile:r.adapterinfo.log $inputfile > $inputfile:r.cutadapt.summary.log
		echo -n "****** removing reads of size less than "
		echo -n $length_cutoff
		echo " bp ******"
		sed 's/^$/N/g' $TEMPDIR{$$} > $inputfile:r.cutadapt.fastq
	else
		cutadapt -a CTGTCTCTTATACACATCTCCGAGCCCACGAGAC -a CTGTCTCTTATACACATCTGACGCTGCCGACGA -a CTGTCTCTTATACACATCT -n 15 -O 15 -q 15 --quality-base=$qual -o $TEMPDIR{$$} --info-file=$inputfile:r.adapterinfo.log $inputfile > $inputfile:r.cutadapt.summary.log
		# convert entries <50 to size=1 ("N")
		echo -n "****** converting reads of size less than "
		echo -n $length_cutoff
		echo " bp to N ******"
		sed 's/^$/N/g' $TEMPDIR{$$} | awk 'NR%2==1 {print $0} NR%2==0 {if ( length ( $0 ) < '$length_cutoff') print "N"; else print $0}' > $inputfile:r.cutadapt.fastq
	endif
else if ($adapter_set == "NexSolB") then
	if ($keep_short_reads == "N") then # delete short reads
		cutadapt -g GTTTCCCACTGGAGGATA -a TATCCTCCAGTGGGAAAC -a CTGTCTCTTATACACATCTCCGAGCCCACGAGAC -a CTGTCTCTTATACACATCTGACGCTGCCGACGA -a CTGTCTCTTATACACATCT -n 15 -O 15 -q 15 -m $length_cutoff --quality-base=$qual -o $TEMPDIR{$$} --info-file=$inputfile:r.adapterinfo.log $inputfile > $inputfile:r.cutadapt.summary.log
		echo -n "****** removing reads of size less than "
		echo -n $length_cutoff
		echo " bp ******"
		sed 's/^$/N/g' $TEMPDIR{$$} > $inputfile:r.cutadapt.fastq
	else
		cutadapt -g GTTTCCCACTGGAGGATA -a TATCCTCCAGTGGGAAAC -a CTGTCTCTTATACACATCTCCGAGCCCACGAGAC -a CTGTCTCTTATACACATCTGACGCTGCCGACGA -a CTGTCTCTTATACACATCT -n 15 -O 15 -q 15 --quality-base=$qual -o $TEMPDIR{$$} --info-file=$inputfile:r.adapterinfo.log $inputfile > $inputfile:r.cutadapt.summary.log
		# convert entries <50 to size=1 ("N")
		echo -n "****** converting reads of size less than "
		echo -n $length_cutoff
		echo " bp to N ******"
		sed 's/^$/N/g' $TEMPDIR{$$} | awk 'NR%2==1 {print $0} NR%2==0 {if ( length ( $0 ) < '$length_cutoff') print "N"; else print $0}' > $inputfile:r.cutadapt.fastq
	endif
else
	echo "No adapter set selected!!!!!"
endif

set numreads_end = `egrep -c "@HWI|@M00|@SRR" $inputfile:r.cutadapt.fastq`

@ reads_removed = $numreads_start - $numreads_end
echo $reads_removed" reads removed by cutadapt" 
echo $numreads_end" reads at end of cutadapt"
rm -f $TEMPDIR{$$}
