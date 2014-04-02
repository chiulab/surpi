#!/usr/bin/python
#
#	coveragePlot.py
#
#	This program generates genomic coverage plots 
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# Copyright (C) 2014 Charles Y Chiu - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
# Last revised 1/26/2014  

import matplotlib
#import matplotlib.numerix as nx
matplotlib.use('Agg')
from pylab import *
from pylab import figure, show, legend
from matplotlib import pyplot as plt
import numpy as np

import sys, os

import re

def smart_truncate1(text, max_length=100, suffix='...'):
    """Returns a string of at most `max_length` characters, cutting
    only at word-boundaries. If the string was truncated, `suffix`
    will be appended.
    """

    if len(text) > max_length:
        pattern = r'^(.{0,%d}\S)\s.*' % (max_length-len(suffix)-1)
        return re.sub(pattern, r'\1' + suffix, text)
    else:
        return text

if len(sys.argv) < 3:
	print "usage: coveragePlot.py <data file> <title of plot>"
	sys.exit(-1)

dataFile = sys.argv[1]

data = mlab.load(dataFile)
outputFile = os.path.splitext(dataFile)[0]+".ps"
reportFile = os.path.splitext(dataFile)[0]+".report"

with open(reportFile) as f:
    reportContent = f.readlines()

reportText = ""

for line in reportContent:
	stripped_line = line.rstrip('\r\n\t ')
	reportText = reportText + smart_truncate1(stripped_line, max_length=100, suffix='...') + "\n"

print "Loaded " + dataFile
hold(True)
fig=plt.figure(figsize=[8.5,3.0])
# ontsize to 8
# text(0, 0, 'help!')
color ='k-'
plot(data[:,0],data[:,1],color)
xlabel("base position",fontsize=8)
ylabel("fold coverage",fontsize=8)
title_text = sys.argv[2] 
suptitle(title_text,fontsize=9)

# suptitle(reportContent[1],fontsize=10)
# title(sys.argv[1])
# for item in reportContent:
#	text(0.50,0.50,item)

xMin, xMax, yMin, yMax = min(data[:,0]),max(data[:,0]),min(data[:,1]),max(data[:,1])
# add a 10% buffer to yMax
yMax *= 1.1
axis([xMin,xMax,yMin,yMax])
gcf().subplots_adjust(bottom=0.60)

fig.text(0.1,0.0,reportText, fontsize=9)
#fig.text(0.1,0.0,'this is a test.\nThis is only a test\nthis is a test\nthisisonly a test\nthis is a test\n')

plt.show()

savefig(outputFile)
