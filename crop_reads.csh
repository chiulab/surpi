#!/bin/csh
#
#	crop_reads.csh
#
# 	crops FASTA/FASTQ reads from $argv[1] to $argv[2]
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
#
# will go from position 10 to 85  (or whatever size is available)
#                          
#
# $1 = file to crop
# $2 = position to start crop ($start_nt)
# $3 = length (nt) to crop, inclusive
#
# Copyright (C) 2014 Charles Y Chiu - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
# Last revised 1/26/2014  
                                                                                                      
if ($#argv != 3) then
	echo "Usage: crop_reads.csh <input FASTQ/FASTA file> <start pos> <cropped length>"
	exit(1)
endif

cat $argv[1] | awk '(NR%2==1){print $0} (NR%2==0){print substr($0,'"$argv[2]"','"$argv[3]"')}' 
