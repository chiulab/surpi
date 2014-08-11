#!/bin/bash
#
#	abyss_minimus.sh
#
#	This script performs de novo asembly on a fasta file using AbySS and Minimo
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# (1) accepts fasta file with multiple barcodes
# (2) splits fasta file into individual barcodes, for each barcode: runs abyss (both on the entire file, and on separate splits of the file).
# (3) outputs contig assemblies, including all.$1.unitigs.cut$2.$3-mini.fa
# (4) user specifies length cutoff after abyss assembly, and cutoff after minimo assembly, as well as number of cores and kmer value
#
# Copyright (C) 2014 Samia N Naccache - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
# Last revised 8/11/2014

if [ $# -lt 5 ]
then
	echo "usage <1.fasta> <2.cutoff_post Abyss> <3.cutoff_post Minimo> <4.#cores> <5.kmer> <6.ignoreBarcodeInfo (Y/N)>"
	exit 65
fi
###
inputfile=$1
cutoff_post_Abyss=$2
cutoff_post_Minimo=$3
cores=$4
kmer=$5
ignore_barcodes=$6
###
scriptname=${0##*/}

#### create list of barcodes in the fasta file in the following format: #barcode 
echo -e "$(date)\t$scriptname\tStarting split barcode"
START_DEMULTIPLEX=$(date +%s)

#The sed '/^#$/d' removes a blank #. This is needed in cases where barcodes are present along with reads that have no barcodes
grep ">" $1 | sed 's/#/ /g' | awk '{print$2}' | sort | uniq | sed 's/\// /g' | awk '{print$1}' | sort | uniq | sed 's/^/#/g' | sed '/^#$/d' > $1.barcodes

if [ -s $1.barcodes ]
then
# this takes care of scenario where entire file has no pound delimited barcodes (#12, etc...).
# It adds a single pound to force the below for loop to treat entire file as 1 "barcode"
	NOBARCODES="0"
else
	NOBARCODES="1"
	echo "#" > $1.barcodes
fi

if [ $ignore_barcodes ]
then
	NOBARCODES="1"
	echo "#" > $1.barcodes
fi

echo -e "$(date)\t$scriptname\tDone split barcode"
END_DEMULTIPLEX=$(date +%s)
diff_DEMULTIPLEX=$(( END_DEMULTIPLEX - START_DEMULTIPLEX ))
echo -e "$(date)\t$scriptname\tsplit barcode Took $diff_DEMULTIPLEX s"
###
### generate fasta file for every separate barcode (demultiplex)

for f in `cat $1.barcodes` ; do
	if [ $NOBARCODES ]
	then
		ln -s $1 bar$f.$1
	else
		grep -Fw "$f" $1 -A 1 | sed '/--/d' > bar$f.$1
	fi
	# split demultiplexed fasta file into 100,000 read sub-fastas
	echo -e "$(date)\t$scriptname\tStarting split fasta"
	START_SPLIT=$(date +%s)
	
	cp bar$f.$1 bar$f.$1_n # So that the unsplit demultiplexed file is also denovo assembled #
	split_fasta.pl -i bar$f.$1 -o bar$f.$1 -n 100000
	echo -e "$(date)\t$scriptname\tDone split fasta"
	END_SPLIT=$(date +%s)
	diff_SPLIT=$(( $END_SPLIT - $START_SPLIT ))
	echo -e "$(date)\t$scriptname\tsplit fasta Took $diff_SPLIT s"
	###
	### run abyss (deBruijn assembler) on each 100,000 read demultiplexed fasta file, including the unsplit demultiplexed file 
	echo -e "$(date)\t$scriptname\tStarting abyss on each 100k"
	START_ABYSS=$(date +%s)
	
	for d in bar$f.$1_* ; do 
		abyss-pe k=$kmer name=$d.f se=$d np=$cores >& $d.abyss.log
	done
	echo -e "$(date)\t$scriptname\tDone abyss on each 100k"
	END_ABYSS=$(date +%s)
	diff_ABYSS=$(( END_ABYSS - START_ABYSS ))
	echo -e "$(date)\t$scriptname\tabyss Took $diff_ABYSS s"
###
### contigs from split files concatenated, after which reads smaller than the cutoff value are eliminated
	echo -e "$(date)\t$scriptname\tStarting concatenating and cutoff of abyss output"
	START_CATCONTIGS=$(date +%s)
	
	#concatenating contig files from different fasta splits, and adding kmer infromation and barcode information to contig headers
	cat bar$f.$1_*.f-unitigs.fa | sed 's/ /_/g' | sed "s/$/"_kmer"$kmer""/g;n" | sed "s/$/"$f"/g;n" > all.bar$f.$1.unitigs.fa
	# only contigs larger than $2 are retained
 	cat all.bar$f.$1.unitigs.fa | awk 'NR%2==1 {x = $0} NR%2==0 { if (length($0) >= '$2') printf("%s\n%s\n",x,$0)}' > all.bar$f.$1.unitigs.cut$2.fa

	echo -e "$(date)\t$scriptname\tDone concatenating and cutoff of abyss output"
	END_CATCONTIGS=$(date +%s)
	diff_CATCONTIGS=$(( END_CATCONTIGS - START3_CATCONTIGS ))
	echo -e "$(date)\t$scriptname\tconcatenating and cutoff of abyss output Took $diff_CATCONTIGS s"
###
### run Minimo (OLC assembler) 
	echo -e "$(date)\t$scriptname\tStarting Minimo"
	START_MINIMO=$(date +%s)
	Minimo all.bar$f.$1.unitigs.cut$2.fa -D FASTA_EXP=1
	echo -e "$(date)\t$scriptname\tDone Minimo"
	END_MINIMO=$(date +%s)
	diff_MINIMO=$(( END_MINIMO - START_MINIMO ))
	echo -e "$(date)\t$scriptname\tMinimo Took $diff_MINIMO s"
###########
	echo -e "$(date)\t$scriptname\tStarting cat barcode addition and cutoff of minimo output"
	START_MIN_PROCESS=$(date +%s)
	# Minimo output gives more than one line per sequence, so here we linearize sequences (linearization protocol from here http://seqanswers.com/forums/showthread.php?t=27567 ) 
	# then we add the relevant barcode to the end of the header contig. Contigs that survive untouched from abyss already have a barcode at the end of them, so that extra barcode is taken away
	cat all-contigs.fa | awk '{if (substr($0,1,1)==">"){if (p){print "\n";} print $0} else printf("%s",$0);p++;}END{print "\n"}' | sed '/^$/d' | sed 's/ /_/g' | sed "s/$/"$f"/g;n" | sed "s/"$f""$f"/"$f"/g" | sed 's/#/#@/g' | sed 's/^>/>contig_/g' > all.bar$f.$1.unitigs.cut$2-minim.fa	
	# change generic name all-contigs.fa 
	mv all-contigs.fa all-contigs.fa.$f
	# only contigs larger than $3 are retained
	cat all.bar$f.$1.unitigs.cut$2-minim.fa | awk 'NR%2==1 {x = $0} NR%2==0 { if (length($0) >= '$3') printf("%s\n%s\n",x,$0)}' > all.bar$f.$1.unitigs.cut$2.$3-mini.fa

	echo -e "$(date)\t$scriptname\tDone cat barcode addition and cutoff of minimo output"
	END_MIN_PROCESS=$(date +%s)
	diff_MIN_PROCESS=$(( END_MIN_PROCESS - START_MIN_PROCESS ))
	echo -e "$(date)\t$scriptname\tcat barcode addition and cutoff of minimo output took $diff_MIN_PROCESS s"
done
###
### concatenate deBruijn -> OLC contigs from all barcodes together
echo -e "$(date)\t$scriptname\tStarting concatenate all barcodes"
START_CAT=$(date +%s)
echo -e "$(date)\t$scriptname\tDone concatenating all barcodes"
cat all.bar*.$1.unitigs.cut$2.$3-mini.fa > all.$1.unitigs.cut$2.$3-mini.fa
END_CAT=$(date +%s)
diff_CAT=$(( END_CAT - START_CAT ))
echo -e "$(date)\t$scriptname\tbarcode concatenation took $diff_CAT s"

# cleaning up files by organizing directories, moving files into directories, and removing temporary files
mkdir $1.dir
mv bar*$1*.fa $1.dir
if [ -e all.$1.contigs.abyssmini.cut$2.$3.e1.NR.RAPSearch.m8 ]
then
	mv all.$1.contigs.abyssmini.cut$2.$3.e1.NR.RAPSearch.m8 $1.dir
fi
rm -f all.$1.contigs.abyssmini.cut$2.$3.e1.NR.RAPSearch.aln
rm -f all.$1.contigs.abyssmini.e1.NR.RAPSearch.m8.noheader
rm -f all.$1.contigs.abyssmini.e1.NR.RAPSearch.m8.noheader.seq
rm -f all.$1.contigs.abyssmini.e1.NR.RAPSearch.m8.noheader 
rm -f all.$1.contigs.abyssmini.e1.NR.RAPSearch.m8.noheader.ex.fa
rm -f all.$1.unitigs.cut$2-contigs.sortlen.seq
rm -f all-contigs*
rm -f all.bar*.$1.unitigs.cut$2-minim.fa
#rm -f $1.barcodes
rm -f all.$1.contigs.abyssmini.e1.NR.RAPSearch.m8.noheader.fasta
rm -f all.$1.contigs.abyssmini.cut$2.$3.e1.NR.RAPSearch.addseq.gi
rm -f all.$1.contigs.abyssmini.cut$2.$3.e1.NR.RAPSearch.addseq.gi.uniq
rm -f all.$1.contigs.abyssmini.cut$2.$3.e1.NR.RAPSearch.addseq.gi.taxonomy
rm -f bar#*.$1_*
rm -f bar#*$1*fasta
rm -f *$1.unitigs.cut$2.fa.runAmos.log
rm -f all.bar*.$1.unitigs.cut$2.$3-mini.fa
rm -f bar*$1 
