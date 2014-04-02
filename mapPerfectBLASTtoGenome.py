#!/usr/bin/python
#
# Simple script to iterate over the -m 8 results from a
# BLAST and spits out the number of hits at each base of the
# query database.  
#
# Peter Skewes-Cox
# February 3, 2009
# *** modified by Charles Chiu, Feburary 8, 2013 to only include bases from the actual BLAST match to the genome ***
# SURPI has been released under a modified BSD license.
# Please see license file for details.
# Last revised 2/8/2013

usage = "blast2Histogram.py <blast file> <output file> <genome length>"

import sys

if len(sys.argv) != 4:
    print usage
    sys.exit(-1)
else:
    blastFile = open(sys.argv[1], "r")
    outputFile = open(sys.argv[2], "w")
    gLength = int(sys.argv[3])
#    oLength = int(sys.argv[4])

genome = []

for base in range(gLength):
    genome.append(0)

for line in blastFile.readlines():
    data = line.split()
    oStart = int(data[6])
    oEnd = int(data[7])
    oLength = oEnd - oStart + 1
    gStart = min(int(data[8]),int(data[9]))
    gEnd = max(int(data[8]),int(data[9]))
    hitStart = max(0,(gStart-oStart+1))
    hitEnd = min(gLength,(gEnd+(oLength-oEnd)))
    for hit in range(hitStart,hitEnd+1):
        genome[hit-1]+=1

for entry in range(len(genome)):
    outputFile.write(str((entry)+1)+"\t")
    outputFile.write(str(genome[entry])+"\n")
