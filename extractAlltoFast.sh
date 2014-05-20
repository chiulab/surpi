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
	echo " <1.inputfile> <2.BLASTN/FASTA/FASTQ> <3.parent file> <4.FASTA/FASTQ> <5. output file> <6.output format: FASTA/FASTQ>" 
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

if [ $inputfile_type = BLASTN ]
then
	echo "prepare BLASTN file"
	awk '{print$1}' $inputfile > $inputfile.header
	echo "uniqued blastn file, replaced beginning with @"
	if [ $parentfile_type = FASTA ]
	then
		seqtk subseq $parentfile $inputfile.header > $outputfile
	fi

	if [ $parentfile_type = FASTQ ]
	then
		if [ $output_format = FASTQ]
		then
			cat $parentfile | fqextract $inputfile.header > $outputfile
		fi
		if [ $output_format = FASTA ]
		then
			cat $parentfile | fqextract $inputfile.header > $inputfile.ex.fq
			sed "n;n;n;d" $inputfile.ex.fq | sed "n;n;d" | sed "s/^@/>/g" > $outputfile
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

	if [ $parentfile_type = FASTA ]
	then   
		seqtk subseq $parentfile $inputfile.header > $outputfile
	fi

	if [ $parentfile_type = FASTQ ]
	then
		if [ $output_format = FASTQ ]
		then        
			cat $parentfile | fqextract $inputfile.header > $outputfile
		fi

		if [ $output_format = FASTA ]
		then
			cat $parentfile | fqextract $inputfile.header > $inputfile.ex.fq
			sed "n;n;n;d" $inputfile.ex.fq | sed "n;n;d" | sed "s/^@/>/g" > $outputfile
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
		seqtk subseq $parentfile $inputfile.header > $outputfile
	fi

	if [ $parentfile_type = FASTQ ]
	then
		if [ $output_format = FASTQ ]
		then
			cat $parentfile | fqextract $inputfile.header > $inputfile.ex.fq
		fi

		if [ $output_format = FASTA ]
		then
			cat $parentfile | fqextract $inputfile.header > $inputfile.ex.fq
			sed "n;n;n;d" $inputfile.ex.fq | sed "n;n;d" | sed "s/^@/>/g" > $outputfile
			rm -f $inputfile.ex.fq
		fi
	fi
	rm -f $inputfile.header
fi
