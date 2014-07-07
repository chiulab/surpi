#!/bin/bash
#
#	create_snap_to_nt.sh
#
#	This program will create the SNAP database files necessary to run SNAP to nt. It does the following:
#	1. decompress nt
#	2. Split nt into chunks defined by command-line parameter
#	3. snap index each chunk_size
#	4. rename snap index folder
#
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# Copyright (C) 2014 Scot Federman - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
# Last revised 7/2/2014  

scriptname=${0##*/}
bold=$(tput bold)
normal=$(tput sgr0)
green='\e[0;32m'
red='\e[0;31m'
endColor='\e[0m'
prefix=$(date +%m%d%Y)

#set SNAP index Ofactor. See SNAP documentation for details
Ofactor=1000

while getopts ":n:hs:f:" option; do
	case "${option}" in
		f) fasta_file_to_index=${OPTARG};;
		n) num_chunks=${OPTARG};;
		h) HELP=1;;
		p) prefix=${OPTARG};;
		s) chunk_size=${OPTARG};;
		:)	echo "Option -$OPTARG requires an argument." >&2
			exit 1
      		;;
	esac
done

if [[ ${HELP-} -eq 1  ||  $# -lt 1 ]]
then
	cat <<USAGE
	
${bold}$scriptname${normal}

This program will download necessary databases and run snap index NCBI NT for use with SURPI. 

${bold}Command Line Switches:${normal}

	-h	Show this help

	-f	Specify path to nt file (or other FASTA file to be indexed)
	
	-n	Specify number of chunks
	
	-s	Specify size of chunks	

${bold}Usage:${normal}

	Index NCBI nt DB into 16 SNAP indices
		$scriptname -n 16 -f NCBI_07022014/nt

	Index NCBI nt DB into SNAP indices of size 3000MB
		$scriptname -s 3000 -f NCBI_07022014/nt

USAGE
	exit
fi

if [[ "$num_chunks" > 0 && "$chunk_size" > 0 ]]
then
	echo -e "$(date)\t$scriptname\tPlease set either the -n or the -s option, not both."
	exit
fi

if [ ! -f "$fasta_file_to_index" ]; then
	echo -e "$(date)\t$scriptname\t$fasta_file_to_index database not found. Exiting..."
	exit
else
	echo -e "$(date)\t$scriptname\t$fasta_file_to_index FASTA file present."
fi

#clean up headers to remove all except for gi
if [ ! -f $prefix.nt ]; then
	echo -e "$(date)\t$scriptname\tShrinking headers..."
	sed "s/\(>gi|[0-9]*|\).*/\1/g" $fasta_file_to_index > $prefix.nt
else
	echo -e "$(date)\t$scriptname\t$prefix.nt already present."
fi

#split nt into chunks (since SNAP currently has maximum database size)
if [ ! -f $prefix.nt.1 ]; then
	echo -e "$(date)\t$scriptname\tSplitting $prefix.nt..."
	if [[ $chunk_size > 0 ]]
	then
		echo -e "$(date)\t$scriptname\tgt splitfasta -targetsize $chunk_size $prefix.nt"
		gt splitfasta -targetsize $chunk_size $prefix.nt
	elif [[ $num_chunks > 0 ]]
	then
		echo -e "$(date)\t$scriptname\tgt splitfasta -numfiles $num_chunks $prefix.nt"
		gt splitfasta -numfiles $num_chunks $prefix.nt
	fi
else
	echo -e "$(date)\t$scriptname\tSplit file already present."
	echo -e "$(date)\t$scriptname\t$scriptname is currently not capable of verifying the split files."
	echo -e "$(date)\t$scriptname\tIn order to complete the indexing, please delete, or move the split files out of this directory."
	exit
fi

#SNAP index each chunk
echo -e "$(date)\t$scriptname\tStarting SNAP indexing of nt..."
for f in $prefix.nt.*
do
	echo -e "$(date)\t$scriptname\tStarting SNAP indexing of $f..."
    snap index $f snap_index_$f -O$Ofactor
	echo -e "$(date)\t$scriptname\tCompleted SNAP indexing of $f..."
done
echo -e "$(date)\t$scriptname\tCompleted SNAP indexing of nt."
