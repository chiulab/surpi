#!/usr/bin/python
#
#	update_sam.py
#       this script reannotates the SAM file based on the better hit identified in "compare_sam.py"
#
#	Chiu Laboratory
#	University of California, San Francisco
#
# Copyright (C) 2014 Charles Chiu - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.

import sys
import os

def logHeader():
	import os.path, sys, time
	return "%s\t%s\t" % (time.strftime("%a %b %d %H:%M:%S %Z %Y"), os.path.basename(sys.argv[0]))

usage = "update_sam.py <annotated SAM file> <outputFile>"
if len(sys.argv) != 3:
	print usage
	sys.exit(0)

SAMfile1 = sys.argv[1]
outputFile1 = sys.argv[2]

file1 = open(SAMfile1, "r")
outputFile = open(outputFile1, "w")

line1 = file1.readline()

while line1 != '':
	data1 = line1.split()
	if (data1[0][0]!="@"):
		header = data1[0].split("|")
		if (len(header)>=2): # these is a hit in header
			dvalue=header[1]
			gi=header[2]
			edit_distance=int(data1[12].split(":")[2])

			line2a = line1.replace(data1[2], "gi|" + str(gi) + "|",1)
			line2b = line2a.replace(data1[0], header[0],1)
			if (edit_distance >= 0): # then there is already a hit in the SAM entry
				line2c = line2b.replace(data1[13], "NM:i:" + str(dvalue))
			else:
				line2c = line2b.replace(data1[12], data1[12] + "\t" + "NM:i:" + str(dvalue),1)
			outputFile.write(line2c)
		else:
			outputFile.write(line1)
	else:
		outputFile.write(line1)
	line1 = file1.readline()

file1.close()
outputFile.close()

print "%sRestored file %s in SAM format and copied to %s" % (logHeader(), SAMfile1, outputFile1)
