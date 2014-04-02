#!/bin/csh
#
#	split_nt.csh
#
#	This script splits nt into chunks usable by the SNAP nucleotide aligner
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# Copyright (C) 2014 Charles Chiu - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
# Last revised 1/26/2014    

split --bytes=4250MB -d nt
foreach f ( x?? )
    tail -100000 $f | grep ">" | tail -1 > header.txt
    if ($f == "x00") then
	mv $f $f.fasta
    else
	tail -100000 $f | grep ">" | tail -1 > header.txt
	cat header.txt $f | sed "s/\(>gi|[0-9]*|\).*/\1/g" > $f.fasta
	echo $f.fasta
	echo "----------------------"
	head $f.fasta
    endif
end
rm header.txt
