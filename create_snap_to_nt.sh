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

#set SNAP index Ofactor. See SNAP documentation for details
Ofactor=1000

while getopts ":d:n:hs:" option; do
	case "${option}" in
		d) db_directory=${OPTARG};;
		n) num_chunks=${OPTARG};;
		h) HELP=1;;
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

	-d	Specify directory containing NCBI data
	
	-n	Specify number of chunks
	
	-s	Specify size of chunks	

${bold}Usage:${normal}

	Index NCBI nt DB into 16 SNAP indices
		$scriptname -n 16 -f NCBI_07022014

	Index NCBI nt DB into SNAP indices of size 3000MB
		$scriptname -s 3000 -f NCBI_07022014

USAGE
	exit
fi

if [[ "$num_chunks" > 0 && "$chunk_size" > 0 ]]
then
	echo "Please set either the -n or the -s option, not both."
	exit
fi

if [ ! -f "$db_directory/nt.gz" ]; then
	echo "nt database not found. Exiting..."
	exit
else
	echo "nt.gz database present."
fi

if [ ! -f "nt" ]; then
	echo "Decompressing nt..."
	pigz -dc -k "$db_directory/nt.gz" > nt
else
	echo "nt database present, and already decompressed."
fi

#clean up headers to remove all except for gi
if [ ! -f nt.noheader ]; then
	echo "Shrinking headers..."
	sed "s/\(>gi|[0-9]*|\).*/\1/g" nt > nt.noheader
else
	echo "Headers already shrunk."
fi

#split nt into chunks (since SNAP currently has maximum database size)
if [ ! -f nt.noheader.1 ]; then
	echo "Splitting file..."
	if [[ $chunk_size > 0 ]]
	then
		echo "gt splitfasta -targetsize $chunk_size nt.noheader"
		gt splitfasta -targetsize $chunk_size nt.noheader
	elif [[ $num_chunks > 0 ]]
	then
		echo "gt splitfasta -numfiles $num_chunks nt.noheader"
		gt splitfasta -numfiles $num_chunks nt.noheader
	fi
else
	echo "Split file already present."
	echo "$scriptname is currently not capable of verifying the split files."
	echo "In order to complete the indexing, please delete, or move the split files out of this directory."
	exit
fi

#SNAP index each chunk
for f in nt.noheader.*
do
    snap index $f snap_index_$f -O$Ofactor
done

