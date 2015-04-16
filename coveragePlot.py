#!/usr/bin/env python
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


import matplotlib
matplotlib.use('Agg')
from pylab import *
from pylab import figure, show, legend
from matplotlib import pyplot as plt
from distutils.version import LooseVersion

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
	print "usage: coveragePlot.py <data file .map/.report> <title of plot> <log y-axes Y/N/B=both>"
	sys.exit(-1)

dataFile = sys.argv[1]

mpl_version=matplotlib.__version__

# print "Installed version is: %s." % mpl_version

#load function is deprecated as of matplotlib v1.3.1, replaced with
if (LooseVersion(mpl_version) >= LooseVersion('1.3.1') ):
	data = np.loadtxt(dataFile)
else:
	data = mlab.load(dataFile)

outputFile = os.path.splitext(dataFile)[0]+".ps"
reportFile = os.path.splitext(dataFile)[0]+".report"

with open(reportFile) as f:
    reportContent = f.readlines()

reportText = ""

logPlot = sys.argv[3]

for line in reportContent:
	stripped_line = line.rstrip('\r\n\t ')
	reportText = reportText + smart_truncate1(stripped_line, max_length=100, suffix='...') + "\n"

print "Loaded " + dataFile
hold(True)

if logPlot=='N':
    fig=plt.figure(figsize=[8.5,4.5])
    ax = fig.add_subplot(111)
    fig.text(0.1,0.0,reportText, fontsize=9)
    color ='k-'
    plot(data[:,0],data[:,1],color)
    xlabel("base position",fontsize=8)
    ylabel("fold coverage",fontsize=8)
    title_text = sys.argv[2]
    suptitle(title_text,fontsize=9)
    xMin, xMax, yMin, yMax = min(data[:,0]),max(data[:,0]),min(data[:,1]),max(data[:,1])
    # add a 10% buffer to yMax
    yMax *= 1.1
    axis([xMin,xMax,yMin,yMax])
    gcf().subplots_adjust(bottom=0.60)
    plt.show()

if logPlot=='B':
    fig=plt.figure(figsize=[8.5,4.5])
    ax1 = fig.add_subplot(211)
    color ='k-'
    plot(data[:,0],data[:,1],color)
    xlabel("base position",fontsize=8)
    ylabel("fold coverage",fontsize=8)
    xMin, xMax, yMin, yMax = min(data[:,0]),max(data[:,0]),min(data[:,1]),max(data[:,1])
    yMax *= 1.1
    axis([xMin,xMax,yMin,yMax])
    plt.show()
    ax2 = fig.add_subplot(212)
    ax2.set_yscale('symlog')
    fig.text(0.1,0.0,reportText, fontsize=9)
    color ='k-'
    plot(data[:,0],data[:,1],color)
    xlabel("base position",fontsize=8)
    ylabel("fold coverage",fontsize=8)
    title_text = sys.argv[2]
    suptitle(title_text,fontsize=9)
    xMin, xMax, yMin, yMax = min(data[:,0]),max(data[:,0]),min(data[:,1]),max(data[:,1])
    yMax *= 1.1
    axis([xMin,xMax,yMin,yMax])
    gcf().subplots_adjust(bottom=0.40)
    plt.show()

if logPlot=='Y':
    fig=plt.figure(figsize=[8.5,4.5])
    ax = fig.add_subplot(111)
    ax.set_yscale('symlog')
    fig.text(0.1,0.0,reportText, fontsize=9)
    color ='k-'
    plot(data[:,0],data[:,1],color)
    xlabel("base position",fontsize=8)
    ylabel("fold coverage",fontsize=8)
    title_text = sys.argv[2]
    suptitle(title_text,fontsize=9)
    xMin, xMax, yMin, yMax = min(data[:,0]),max(data[:,0]),min(data[:,1]),max(data[:,1])
    yMax *= 1.1
    axis([xMin,xMax,yMin,yMax])
    gcf().subplots_adjust(bottom=0.60)
    plt.show()

savefig(outputFile)
