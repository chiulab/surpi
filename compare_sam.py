#!/usr/bin/python
#
#	compare_sam.py
#
# 	This script compares a SAM file with most recent SNAP alignment comparison and chooses better hit.
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# Copyright (C) 2014 Charles Y Chiu - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
# Last revised 1/26/2014  

import sys

usage = "compare_sam.py <annotated SAM file> <outputFile>"
if len(sys.argv) != 3:
	print usage
	sys.exit(0)

SAMfile1 = sys.argv[1]
outputFile = sys.argv[2]

file1 = open(SAMfile1, "r")
outputFile = open(outputFile, "w")

counter=0
count_data1=0
count_data2=0
sum_data1=0
sum_data2=0
sum_data3=0
switch = 0
linenum=0

line1 = file1.readline()
linenum += 1

while line1 != '':
	data1 = line1.split()

# check to see wheter line is a SAM line     
	if (data1[0][0]!="@"):
		if (len(data1)==14):
			count_data2 += 1
			sum_data2 += int(data1[13].split(":")[2])
			firstentry = data1[0].split("|")
			if (len(firstentry)>=2):
				dvalue=firstentry[1]
				snapd = data1[13].split(":")[2]
				if (int(snapd) <= int(dvalue)):
					counter += 1
					count_data1 += 1
					sum_data1 += int(snapd)
					sum_data3 += int(dvalue)
# need to pick the new gi, not the old gi, bug fix 1/27/13
					gi=data1[2].split("|")[1]
					line2 = line1.replace("|" + firstentry[1] + "|" + firstentry[2],"|" + str(snapd) + "|" + str(gi),1)
					outputFile.write(line2)
				else:
					count_data1 += 1
					sum_data1 += int(dvalue)
					sum_data3 += int(dvalue)
					outputFile.write(line1)
			else:
				snapd = data1[13].split(":")[2]
				count_data1 += 1
				sum_data1 += int(snapd)
				gi=data1[2].split("|")[1]
				line2 = line1.replace(data1[0],data1[0] + "|" + str(snapd) + "|" + str(gi),1)
				outputFile.write(line2)
				counter+=1
		else:
			outputFile.write(line1)
			firstentry = data1[0].split("|")
			if (len(firstentry)>=2):
				dvalue=firstentry[1]
				count_data1 += 1
				sum_data1 += int(dvalue)
				sum_data3 += int(dvalue)
	else:
		outputFile.write(line1)

	line1 = file1.readline()
	linenum += 1
file1.close()
outputFile.close()

print "%s (%s existing hits, sum of edit distance = %s -> %s ) vs. %s (%s new hits, sum of edit distance = %s): there were %s replacements" % (sys.argv[1], count_data1, sum_data3, sum_data1, sys.argv[2], count_data2, sum_data2, counter)

