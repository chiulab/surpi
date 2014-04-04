#!/bin/csh
#
#	extractHeaderFromFastq.csh
#
#	extract headers from FASTQ file
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# --- uses the C program "fqextract.c" (http://www.biostars.org/p/10353/) ---
#
# Usage: extractHeaderFromFastq.csh <header file> <format of header list file (BLASTN / FASTQ / FASTA)> <data file in FASTQ format> <output file>
#
# Copyright (C) 2014 Charles Y Chiu - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
# Last revised 1/26/2014  

if ($#argv != 4) then
	echo "Usage: extractHeaderFromFastq.csh <header file> <format of header list file (BLASTN / FASTQ / FASTA)> <data file in FASTQ format> <output file>"
	exit(1)
endif

foreach f ($argv[1] $argv[3])
	if (! -e $f) then
		echo $f" not found"
	endif
end

if ("$argv[2]" =~ "BLASTN") then
	cat $argv[1] | awk '{print $1}' | sed '/^$/d' > $argv[1]:r.temp$$
else if ("$argv[2]" =~ "FASTQ") then
	cat $argv[1] | sed "/^[^@]/d" | sed 's/^@//g' | awk '{print $1}' > $argv[1]:r.temp$$
else if ("$argv[2]" =~ "FASTA") then
	cat $argv[1] | sed "/^[^>]/d" | sed 's/^>//g' | awk '{print $1}' > $argv[1]:r.temp$$
else echo "Format of header file not specified"
	exit(1)
endif

cat $argv[3] | fqextract $argv[1]:r.temp$$ > $argv[4]

rm -f $argv[1]:r.temp$$

echo "successfully completed...."
