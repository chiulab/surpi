#!/bin/bash
#
#	create_snap_nt_db.sh
#
# 	This script will create SNAP databases from the NCBI NT database.
#	1. download NCBI nt database 
#	2. split NT into chunks
#	3. create SNAP databases from each chunk
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# Copyright (C) 2014 Scot Federman - All Rights Reserved
# Permission to copy and modify is granted under the BSD license 
# Last revised 4/21/2014  

number_of_chunks="15"
targetsize="3950"
SNAP_seed=20
SNAP_O=1000
SNAP_version="snap_1.0b10"

START=$(date +%s)

curl -O "ftp://ftp.ncbi.nih.gov/blast/db/FASTA/nt.gz.md5"
curl -O "ftp://ftp.ncbi.nih.gov/blast/db/FASTA/nt.gz"

# check md5sum

gunzip nt.gz

#strip headers from nt
sed "s/\(>gi|[0-9]*|\).*/\1/g" nt > nt.stripped_header.fasta

#split fasta file into chunks
# gt splitfasta -numfiles $number_of_chunks nt.stripped_header.fasta
gt splitfasta -targetsize $targetsize nt.stripped_header.fasta

#use SNAP to index each chunk
for f in nt.stripped_header.fasta.*
do
	$SNAP_version index $f snap_index_042214.$f -s $SNAP_seed -O$SNAP_O 
done
