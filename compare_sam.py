#!/usr/bin/env python
#
#	compare_sam.py
#
# 	This script compares a SAM file with most recent SNAP alignment comparison and chooses better hit.
#	Chiu Laboratory
#	University of California, San Francisco
#
# Copyright (C) 2014 Charles Y Chiu - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.

import sys
import os

def logHeader():
    import os.path, sys, time
    return "%s\t%s\t" % (time.strftime("%a %b %d %H:%M:%S %Z %Y"), os.path.basename(sys.argv[0]))

usage = "compare_sam.py <annotated SAM file> <outputFile>"
if len(sys.argv) != 3:
    print usage
    sys.exit(0)

SAMfile1 = sys.argv[1]
outputFile1 = sys.argv[2]

file1 = open(SAMfile1, "r")
outputFile = open(outputFile1, "w")

replacements=0
existing_hits=0
new_hits=0
sum_data1=0
sum_edistance_new=0
sum_edistance_existing=0
switch = 0
linenum=0

line1 = file1.readline()
linenum += 1

while line1 != '':
    data1 = line1.split()

    # check to see whether line is in the SAM header or alignment section
    if (data1[0][0]!="@"):
        #We are in the SAM alignment section

        edit_distance=int(data1[12].split(":")[2])
        mapped = not bool(int(data1[1]) & 0x4)

        #using old snap (<=v0.15.4), could use length of line to determine if it was a hit or miss.
        #new snap (>=v1.0) instead uses an edit distance of -1 to signify a miss.

        # Not sure what above is saying.
        # Use 0x4 mask in FLAG field to check for unmapped reads.
        if (mapped):
            #this is a hit
            new_hits += 1
            sum_edistance_new += edit_distance
            firstentry = data1[0].split("|")
            if (len(firstentry)>=2):
                # this has been previously flagged as a hit, and is also now a hit. Compare edit distances to find best hit.
                edit_distance_previous=firstentry[1]
                edit_distance_current = data1[12].split(":")[2]

                existing_hits += 1
                sum_edistance_existing += int(edit_distance_previous)

                if (int(edit_distance_current) <= int(edit_distance_previous)):
                    replacements += 1
                    sum_data1 += int(edit_distance_current)
                    # need to pick the new gi, not the old gi, bug fix 1/27/13
                    gi=data1[2].split("|")[1]
                    replacement_line = line1.replace("|" + firstentry[1] + "|" + firstentry[2],"|" + str(edit_distance_current) + "|" + str(gi),1)
                    outputFile.write(replacement_line)
                else:
                    sum_data1 += int(edit_distance_previous)
                    outputFile.write(line1)
            else:
                edit_distance_current = data1[12].split(":")[2]
                existing_hits += 1
                sum_data1 += int(edit_distance_current)
                gi=data1[2].split("|")[1]
                replacement_line = line1.replace(data1[0],data1[0] + "|" + str(edit_distance_current) + "|" + str(gi),1)
                outputFile.write(replacement_line)
                replacements+=1
        else:
            #this is a miss
            outputFile.write(line1)
            firstentry = data1[0].split("|")
            if (len(firstentry)>=2):
                edit_distance_previous=firstentry[1]
                existing_hits += 1
                sum_data1 += int(edit_distance_previous)
                sum_edistance_existing += int(edit_distance_previous)
    else:
        #We are in the SAM header section
        outputFile.write(line1)

    line1 = file1.readline()
    linenum += 1
file1.close()
outputFile.close()

print "%s%s (%s existing hits, sum of edit distance = %s -> %s )" % (logHeader(), SAMfile1, existing_hits, sum_edistance_existing, sum_data1)
print "%s%s (%s new hits, sum of edit distance = %s)" % (logHeader(), outputFile1, new_hits, sum_edistance_new)
print "%sThere were %s replacements" % (logHeader(), replacements)
