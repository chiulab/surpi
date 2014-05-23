#!/bin/bash
#
#	extractAlltoFast.sh
#
# 	retrieve FASTA or FASTQ records (parent file) from an input file that's either BLASTn (m8 table, sam file, or list of headers); FASTA; FASTQ
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# --- uses the C program "fqextract.c" (http://www.biostars.org/p/10353/) ---
#
# Copyright (C) 2014 Samia Naccache - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
# Last revised 5/19/2014

if [ $# -lt 6 ]
then
	echo "<inputfile> <Input File Type [BLASTN/FASTA/FASTQ]> <Parent file> <Parent File Type [FASTA/FASTQ]> <Output file> <Output format: [FASTA/FASTQ]>" 
	exit 65
fi

###
inputfile=$1
inputfile_type=$2
parentfile=$3
parentfile_type=$4
outputfile=$5
output_format=$6
###
scriptname=${0##*/}

echo -e "$(date)\t$scriptname\tprepare $inputfile_type file"

if [ $inputfile_type = BLASTN ]
then
	awk '{print$1}' $inputfile > $inputfile.header
	echo -e "$(date)\t$scriptname\tuniqued blastn file, replaced beginning with @"
	
	if [ $parentfile_type = FASTA ]
	then
		seqtk subseq $parentfile $inputfile.header > $outputfile
	elif [ $parentfile_type = FASTQ ]
	then
		if [ $output_format = FASTQ]
		then
			cat $parentfile | fqextract $inputfile.header > $outputfile
		elif [ $output_format = FASTA ]
		then
			cat $parentfile | fqextract $inputfile.header > $inputfile.ex.fq
			sed "n;n;n;d" $inputfile.ex.fq | sed "n;n;d" | sed "s/^@/>/g" > $outputfile
			rm -f $inputfile.ex.fq
		fi
	fi
	rm -f $inputfile.header
elif [ $inputfile_type = FASTA ]
then
	grep ">" $inputfile | sed 's/>//g' > $inputfile.header
	echo -e "$(date)\t$scriptname\tDone preparing input Fasta file "

	if [ $parentfile_type = FASTA ]
	then   
		seqtk subseq $parentfile $inputfile.header > $outputfile
	elif [ $parentfile_type = FASTQ ]
	then
		if [ $output_format = FASTQ ]
		then        
			cat $parentfile | fqextract $inputfile.header > $outputfile
		elif [ $output_format = FASTA ]
		then
			cat $parentfile | fqextract $inputfile.header > $inputfile.ex.fq
			sed "n;n;n;d" $inputfile.ex.fq | sed "n;n;d" | sed "s/^@/>/g" > $outputfile
			rm -f $inputfile.ex.fq
		fi
	fi
	rm -f $inputfile.header
elif [ $inputfile_type = FASTQ ]
then
	grep "^@" $inputfile | sed 's/@//g' > $inputfile.header
	echo -e "$(date)\t$scriptname\tDone preparing input Fastq file"

	if [ $parentfile_type = FASTA ]
	then
		seqtk subseq $parentfile $inputfile.header > $outputfile
	elif [ $parentfile_type = FASTQ ]
	then
		if [ $output_format = FASTQ ]
		then
			cat $parentfile | fqextract $inputfile.header > $inputfile.ex.fq
		elif [ $output_format = FASTA ]
		then
			cat $parentfile | fqextract $inputfile.header > $inputfile.ex.fq
			sed "n;n;n;d" $inputfile.ex.fq | sed "n;n;d" | sed "s/^@/>/g" > $outputfile
			rm -f $inputfile.ex.fq
		fi
	fi
	rm -f $inputfile.header
fi
