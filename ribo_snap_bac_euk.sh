#!/bin/bash
#
#	ribo_snap_bac_euk.sh
#
# 	Chiu Laboratory
# 	University of California, San Francisco
#
#
# Copyright (C) 2014 Samia Naccache - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
#
scriptname=${0##*/}

if [ $# -lt 4 ]
then
	echo "Usage: $scriptname <.sorted> <BAC/EUK> <cores> <folder containing SNAP databases>"
	exit 65
fi

###
inputfile=$1
inputfile_type=$2
cores=$3
directory=$4
###
nopathf=${1##*/}
basef=${nopathf%.annotated}

if [ $inputfile_type == "BAC" ]
then
	SNAP_index_Large="$directory/snap_index_23sRNA"
	SNAP_index_Small="$directory/snap_index_rdp_typed_iso_goodq_9210seqs"
fi

if [ $inputfile_type == "EUK" ]
then
	SNAP_index_Large="$directory/snap_index_28s_rRNA_gene_NOT_partial_18s_spacer_5.8s.fa"
	SNAP_index_Small="$directory/snap_index_18s_rRNA_gene_not_partial.fa"
fi

awk '{print ">"$1"\n"$10}' $inputfile > $inputfile.fasta # if Bacteria.annotated file has full quality, convert from Sam -> Fastq at this step
fasta_to_fastq $inputfile.fasta > $inputfile.fakq # if Bacteria.annotated file has full quality, convert from Sam -> Fastq at this step

crop_reads.csh $inputfile.fakq 10 75 > $inputfile.fakq.crop
# snap against large ribosomal subunit
snap single $SNAP_index_Large -fastq $inputfile.fakq.crop -o $inputfile.noLargeS.unmatched.sam -t $cores -x -f -h 250 -d 18 -n 200 -F u
egrep -v "^@" $inputfile.noLargeS.unmatched.sam | awk '{if($3 == "*") print "@"$1"\n"$10"\n""+"$1"\n"$11}' > $(echo "$inputfile".noLargeS.unmatched.sam | sed 's/\(.*\)\..*/\1/').fastq
echo -e "$(date)\t$scriptname\tDone: first snap alignment"

# snap against small ribosomal subunit
snap single $SNAP_index_Small -fastq $inputfile.noLargeS.unmatched.fastq -o $inputfile.noSmallS_LargeS.sam -t $cores -h 250 -d 18 -n 200 -F u
echo -e "$(date)\t$scriptname\tDone: second snap alignment"

# convert snap unmatched to ribo output to header format
awk '{print$1}' $inputfile.noSmallS_LargeS.sam | sed '/^@/d' > $inputfile.noSmallS_LargeS.header.sam

# retrieve reads from original $inputfile

extractSamFromSam.sh $inputfile.noSmallS_LargeS.header.sam $inputfile $basef.noRibo.annotated
echo -e "$(date)\t$scriptname\tCreated $inputfile.noRibo.annotated"
table_generator.sh $basef.noRibo.annotated SNAP N Y N N

rm -f $inputfile.noLargeS.sam
rm -f $inputfile.noLargeS.matched.sam
rm -f $inputfile.noLargeS.unmatched.sam
rm -f $inputfile.noSmallS_LargeS.sam
rm -f $inputfile.noSmallS_LargeS.sam.header
rm -f $inputfile.noLargeS.unmatched.fastq
rm -f $inputfile.fakq
rm -f $inputfile.fakq.crop
rm -f $inputfile.fasta
rm -f $inputfile.sorted
rm -f $inputfile.noSmallS_LargeS.header.sam
