#!/usr/bin/env python
#
#	compare_multiple_sam.py
#
#	This program compares multiple SAM files to find the best SNAP alignment hit
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# Copyright (C) 2014 Charles Y Chiu - All Rights Reserved
# Permission to copy and modify is granted under the BSD license
# Last revised 3/21/2014  

import sys

usage = "compare_multiple_sam.py <annotated SAM file1> <annotated SAM file2> <annotated SAM filen> <output file>"

if len(sys.argv) < 3:
	print usage
	sys.exit(0)

outputFile = sys.argv[len(sys.argv)-1]
#print outputFile

fileObjList = []

for n in range(0, len(sys.argv)-2):
	fileName = sys.argv[n+1]
	fileObj = open(fileName, "r")
	fileObjList.append(fileObj)

#file1 = open(SAMfile1, "r")

outputFile = open(outputFile, "w")

lineList = []

for file in fileObjList:
	lineList.append(file.readline())

cur_snapd = 0
best_snapd = 999
best_line = ""

while lineList[0] != '':
#	print lineList
	for line in lineList:
		data = line.split()
		if (data[0][0]!="@"): #line is a SAM data line
			if (len(data)==14): #there is a match for that line
				cur_snapd = data[13].split(":")[2]
				if (int(cur_snapd) <= int(best_snapd)): #current match is better than best so far
					best_snapd = cur_snapd
					best_line = line
	if (best_line==""): #no match at all
		best_line = lineList[0]
	outputFile.write(best_line)
	cur_snapd = 0
	best_snapd = 999
	best_line = ""
	lineList = []
	for file in fileObjList:
		lineList.append(file.readline())
		
for file in fileObjList:
	file.close()
outputFile.close()
