#!/bin/bash
#
#	plot_reads_to_gi.sh
#
#	This program maps reads found in input fasta file to a given gi by blastn at different e values.
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# maps reads found in input fasta file to a given gi by blastn at different e values. retrieves gi from genbank automatically, or can map to locally available fasta file if variable 3 is set to FA.
#
# Copyright (C) 2014 Samia N Naccache - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.

scriptname=${0##*/}

if [ $# -lt 5 ]; then
    echo "Usage: $scriptname <.fasta> <gi # OR reference fasta> <name of gi / FA (if reference in fasta form> <e value> <cores available>"
    echo "not uniquing Blastn anymore 9/13/13 given a fasta file and the GI or FASTA of the reference to assemble to -> makes an assembly.  blastn e value in 1e-8 format . jedi has 16 cores available"
    exit
fi

plot_log="B" # set coveragePlotLog.py to display both log and linear plots

if [ $3 != "FA" ]
then
	get_genbankfasta.pl $2 > $3.$2.fasta
	echo -e "$(date)\t$scriptname\tReference fasta retrieved from genbank"
	formatdb -p F -i $3.$2.fasta
fi

if [ $3 = "FA" ]
then
	cp $2 $3.$2.fasta
	formatdb -p F -i $3.$2.fasta
fi

###### split query ####
let "numreads = `grep -c ">" $1`" ###
let "numreadspercore = numreads / $5" ###
echo -e "$(date)\t$scriptname\tnumber of read $numreads"
echo -e "$(date)\t$scriptname\tnumber of reads per core $numreadspercore"
if [ $numreadspercore = 0 ]
then
	split_fasta.pl -i $1 -o $1 -n 1
else
	split_fasta.pl -i $1 -o $1 -n $numreadspercore
fi

echo -e "$(date)\t$scriptname\tBlasting fasta file against reference "
for f in $1_* ; do
	blastall -p blastn -m 8 -a 1 -b 1 -K 1 -d $3.$2.fasta -i $f -o $f.$2.$3.$4.blastn -e $4 >& $f.$2.$3.$4.error &
done

for job in `jobs -p` ; do
	wait $job
done

cat $1*.$2.$3.$4.blastn > $1.$2.$3.$4.Blastn

uniq_blastn_nopipes.sh $1.$2.$3.$4.Blastn
extractAlltoFast.sh $1.$2.$3.$4.Blastn.uniq BLASTN $1 FASTA $1.$2.$3.$4.Blastn.uniq.ex.fa FASTA

####figuring out length of sequence in gi#######

let "gilength = `sed '/>/d' $3.$2.fasta | awk 'BEGIN{FS=""}{for(i=1;i<=NF;i++)c++}END{print c}'`"         ##from internets http://stackoverflow.com/questions/5026214/counting-number-of-characters-in-a-file-through-shell-script
echo -e "$(date)\t$scriptname\tReference sequence length = $gilength bp"
mapPerfectBLASTtoGenome.py $1.$2.$3.$4.Blastn $1.$2.$3.$4.map $gilength
echo -e "$(date)\t$scriptname\tDone mapping to reference"

#####
let "notcoverage = `awk '{print$2}' $1.$2.$3.$4.map | grep -c "^0$"`"
#echo "Number of bp not covered = $notcoverage"

let "coverage = $gilength - $notcoverage"
echo -e "$(date)\t$scriptname\tNumber of bp covered = $coverage bp"
echo -e -n "$(date)\t$scriptname\t%Coverage = "
echo "scale=6;100*$coverage/$gilength" | bc

let "sumofcolumntwo = `awk '{print$2}' $1.$2.$3.$4.map | awk '{sum += $1} END{print sum}'`"
echo -e -n "$(date)\t$scriptname\tAverage depth of coverage (x) = "
echo "scale=6;$sumofcolumntwo/$gilength" | bc
let "numberBlastnReads = `egrep -c "^SCS|^HWI|gi|^M00|^kmer|^SRR" $1.$2.$3.$4.Blastn.uniq`"
echo -e "$(date)\t$scriptname\tNumber of reads contributing to assembly  $numberBlastnReads"

#####generating report#########
echo "mapping $1" > $1.$2.$3.$4.report
echo "against $3.$2.fasta" with gi definition >> $1.$2.$3.$4.report
grep ">" $3.$2.fasta | sed 's/>//g' >> $1.$2.$3.$4.report
echo "___" >> $1.$2.$3.$4.report

echo "Reference sequence length = $gilength bp" >> $1.$2.$3.$4.report
echo "Coverage in bp = $coverage" >> $1.$2.$3.$4.report
echo -n "%Coverage = " >> $1.$2.$3.$4.report
echo "scale=6;100*$coverage/$gilength" | bc >> $1.$2.$3.$4.report
echo -n "Average depth of coverage = " >> $1.$2.$3.$4.report
echo "scale=6;$sumofcolumntwo/$gilength" | bc >> $1.$2.$3.$4.report
#echo "Average depth of coverage = $averagedepthcoverage x " >> $1.$2.$3.$4.report
echo "Number of reads contributing to assembly = $numberBlastnReads" >> $1.$2.$3.$4.report

####coverage plot#####
coveragePlot.py $1.$2.$3.$4.map $3_$2 $plot_log
ps2pdf14 $1.$2.$3.$4.ps $1.$2.$3.$4.pdf

#### Cleanup ########
rm -f $1*$2.$3.$4.blastn
rm -f $1*$2.$3.$4.error
rm -f $3.$2.fasta.nhr
rm -f $3.$2.fasta.nin
rm -f $3.$2.fasta.nsq
#rm -f $1.$2.$3.$4.Blastn
rm -f $1_*
rm -f formatdb
