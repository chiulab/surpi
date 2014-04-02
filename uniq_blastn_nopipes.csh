#!/bin/csh
#
#	uniq_blastn_nopipes.csh
#
#	input: m8 tabular output with multiple resutlts for a single record (header). Provides an output with only one result per record, based on the result with the smallest e value
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# Copyright (C) 2014 Samia N Naccache - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
# Last revised 1/26/2014    

if ($#argv == 0) then
	echo "Usage:_uniq_blastn.csh <blastn>"
	exit(1)
endif
echo "starting uniq sort on $argv[1]"

sort -k1,1 -k11,11g $argv[1] | sed 's/\t/,/g' | sort -u -t, -k 1,1 | sed 's/,/\t/g' > $argv[1].uniq

echo " Done uniq sort on = $argv[1]"
