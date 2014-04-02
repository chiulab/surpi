#!/bin/bash
#
#	extractAlltoFast.csh
#
# 	retrieve FASTA or FASTQ records(parent file) from an input file that's either BLASTn (m8 table, sam file, or list of headers); FASTA; FASTQ
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# --- uses the C program "fqextract.c" (http://www.biostars.org/p/10353/) ---
#
# Copyright (C) 2014 Scot Federman - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
# Last revised 1/26/2014  

if [ $# -lt 5 ]
then
	echo " <1.inputfile> <2.BLASTN/FASTA/FASTQ> <3.parent file> <4.FASTA/FASTQ> <5.output format: FASTA/FASTQ>" 
	exit 65
fi

###
inputfile=$1
inputfile_type=$2
parentfile=$3
parentfile_type=$4
output_format=$5
###

if [ $inputfile_type = BLASTN ]
then
	echo "prepare BLASTN file"
	#sort -k1,1 -k11,11g $1 | sed 's/\t/,/g' | sort -u -t, -k 1,1 | sed 's/,/\t/g' > $1.uniq
	awk '{print$1}' $1 > $1.header
	echo "uniqued blastn file, replaced beginning with @"
	if [ $parentfile_type = FASTA ]
	then
		seqtk subseq $parentfile $inputfile.header > $inputfile.ex.fa
	fi

	if [ $parentfile_type = FASTQ ]
	then
		cat $parentfile | fqextract $inputfile.header > $inputfile.ex.fq 
		if [ $output_format = FASTA ]
		then
			sed "n;n;n;d" $inputfile.ex.fq | sed "n;n;d" | sed "s/^@/>/g" > $inputfile.ex.fa
			rm -f $inputfile.ex.fq
		fi
	fi
	rm -f $inputfile.header
fi

if [ $inputfile_type = FASTA ]
then
	echo "prepare FASTA file"
	grep ">" $inputfile | sed 's/>//g' > $inputfile.header
	echo "Done preparing input Fasta file "

	#### REPLACE HERE WITH SQ	
	if [ $parentfile_type = FASTA ]
	then   
		seqtk subseq $parentfile $inputfile.header > $inputfile.ex.fa
	fi

	if [ $parentfile_type = FASTQ ]
	then
		cat $parentfile | fqextract $inputfile.header > $inputfile.ex.fq
		if [ $output_format = FASTA ]
		then
			sed "n;n;n;d" $inputfile.ex.fq | sed "n;n;d" | sed "s/^@/>/g" > $inputfile.ex.fa
			rm -f $inputfile.ex.fq
		fi
	fi
	rm -f $inputfile.header
fi
if [ $inputfile_type = FASTQ ]
then
	echo "prepare FASTQ file"
	grep "^@" $inputfile | sed 's/@//g' > $inputfile.header
	echo "Done preparing input Fastq file "

	if [ $parentfile_type = FASTA ]
	then
		seqtk subseq $parentfile $inputfile.header > $inputfile.ex.fa
	fi

	if [ $parentfile_type = FASTQ ]
	then
		cat $parentfile | fqextract $inputfile.header > $inputfile.ex.fq
		if [ $output_format = FASTA ]
		then
			sed "n;n;n;d" $inputfile.ex.fq | sed "n;n;d" | sed "s/^@/>/g" > $inputfile.ex.fa
			rm -f $inputfile.ex.fq
		fi
	fi
	rm -f $inputfile.header
fi
