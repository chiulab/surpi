#!/bin/bash
#
#	table_generator.sh
#
#	This program generates a table showing taxonomic statistics using a SAM file as input.
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# input file: annotated sam or annotated -m 8 file with taxonomies provided in the following format at the end of the .sam and -m 8 file: 
# "gi# --family --genus --species"
# Output files are tab delimited  files ending in .counttable whereby rows represent taxonomic annotations at various levels (family, genus, species, gi)
# Columns represent individual barcodes found in the dataset, and cells contain the number of reads
# Variables 3,4,5,6 allow the generation of gi, species, genus or family -centric tables respectively if set to Y.
#
# Copyright (C) 2014 Samia N Naccache - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.

scriptname=${0##*/}

if [ $# -lt 6 ]; then
	echo "Usage: $scriptname <annotated file> <SNAP/RAP> <gi Y/N> <species Y/N> <genus Y/N> <family Y/N> " 
    exit
fi

###
inputfile=$1
file_type=$2
gi=$3
species=$4
genus=$5
family=$6
###

###substitute forward slash with @_ because forward slash in species name makes it ungreppable. using @_ because @ is used inside the contig barcode (ie. #@13 is barcode 13, contig generated) 
create_tab_delimited_table.pl -f $file_type $inputfile  |  sed 's/ /_/g' | sed 's/,/_/g' | sed 's/\//@_/g' > $inputfile.tempsorted
echo -e "$(date)\t$scriptname\tdone creating $inputfile.tempsorted"

###########GENERATE BARCODE LIST#####################
sed 's/#/ /g'  $inputfile.tempsorted | sed 's/\// /g' | awk '{print$2}' | sed 's/^/#/g' | sed 's/[1-2]$//g' | sort | uniq > $inputfile.barcodes.int #makes a barcode list from the entire file #change $inputfile.tempsorted to $inputfile once no need for temp table
echo -e "$(date)\t$scriptname\tcreated list of barcodes"

sed '/N/d' $inputfile.barcodes.int > $inputfile.barcodes

######GENERATE gi LIST ##############
if [ "$gi" != "N" ]
then
	sort -k2,2 -k2,2g $inputfile.tempsorted | sed 's/\t/,/g' | sort -u -t, -k 2,2 | sed 's/,/\t/g' | awk -F "\t" '{print$2,"\t"$3,"\t"$4,"\t"$5}' | sed '/^$/d' | sed '/^ /d' > $inputfile.gi.uniq.columntable
	awk -F "\t" '{print$1}'  $inputfile.gi.uniq.columntable | sed '/^$/d' | sed '/^ /d' > $inputfile.gi.uniq.column
	echo -e "$(date)\t$scriptname\tdone creating $inputfile.gi.uniq.column"
	for f in `cat $inputfile.barcodes`
		do
			echo "bar$f" > bar$f.$inputfile.gi.output
			echo -e "$(date)\t$scriptname\tparsing barcode $f "
			grep "$f" $inputfile.tempsorted > bar.$f.$inputfile.tempsorted
			for d in `cat $inputfile.gi.uniq.column`
			do
				grep -F -c -w "$d" bar.$f.$inputfile.tempsorted  >> bar$f.$inputfile.gi.output
			done
		done
	echo -e "GI\tSpecies\tGenus\tFamily(@=contigbarcode)" > $inputfile.header
	cat $inputfile.header $inputfile.gi.uniq.columntable > $inputfile.gi.counttable_temp
	paste $inputfile.gi.counttable_temp bar*.$inputfile.gi.output > $inputfile.gi.counttable 
	sed -i 's/@_/ /g' $inputfile.gi.counttable
	echo -e "$(date)\t$scriptname\tdone generating gi counttable"
fi

######GENERATE species LIST ##############
if [ "$species" != "N" ]
then
	sort -k3,3 -k3,3g $inputfile.tempsorted | sed 's/\t/,/g' | sort -u -t, -k 3,3 | sed 's/,/\t/g' | awk -F "\t" '{print$3,"\t"$4,"\t"$5}' | sed '/^$/d' | sed '/^ /d' > $inputfile.species.uniq.columntable
	awk -F "\t" '{print$1}'  $inputfile.species.uniq.columntable | sed '/^$/d' | sed '/^ /d' > $inputfile.species.uniq.column
	echo -e "$(date)\t$scriptname\tdone creating $inputfile.species.uniq.column"
	for f in `cat $inputfile.barcodes`
	do
		echo "bar$f" > bar$f.$inputfile.species.output
		echo -e "$(date)\t$scriptname\tparsing barcode $f "
		grep "$f" $inputfile.tempsorted > bar.$f.$inputfile.tempsorted
		for d in `cat $inputfile.species.uniq.column`
		do
			grep -F -c -w "$d" bar.$f.$inputfile.tempsorted  >> bar$f.$inputfile.species.output
		done
	done
	echo -e "Species\tGenus\tFamily(@=contigbarcode)" > $inputfile.header
	cat $inputfile.header $inputfile.species.uniq.columntable > $inputfile.species.counttable_temp
	paste $inputfile.species.counttable_temp bar*.$inputfile.species.output > $inputfile.species.counttable 
	sed -i 's/@_/ /g' $inputfile.species.counttable
	echo -e "$(date)\t$scriptname\tdone generating species counttable"
fi
######GENERATE genus LIST ##############
if [ "$genus" != "N" ]
then
	sort -k4,4 -k4,4g $inputfile.tempsorted | sed 's/\t/,/g' | sort -u -t, -k 4,4 | sed 's/,/\t/g' | awk -F "\t" '{print$4,"\t"$5}' | sed '/^$/d' | sed '/^ /d' > $inputfile.genus.uniq.columntable
	awk -F "\t" '{print$1}'  $inputfile.genus.uniq.columntable | sed '/^$/d' | sed '/^ /d' > $inputfile.genus.uniq.column
	echo -e "$(date)\t$scriptname\tdone creating $inputfile.genus.uniq.column"
	for f in `cat $inputfile.barcodes`
	do
		echo "bar$f" > bar$f.$inputfile.genus.output
		echo -e "$(date)\t$scriptname\tparsing barcode $f"
		grep "$f" $inputfile.tempsorted > bar.$f.$inputfile.tempsorted
		for d in `cat $inputfile.genus.uniq.column`
		do
			grep -F -c -w "$d" bar.$f.$inputfile.tempsorted  >> bar$f.$inputfile.genus.output
		done
	done
	echo -e "Genus\tFamily(@=contigbarcode)" > $inputfile.header
	cat $inputfile.header $inputfile.genus.uniq.columntable > $inputfile.genus.counttable_temp
	paste $inputfile.genus.counttable_temp bar*.$inputfile.genus.output > $inputfile.genus.counttable 
	sed -i 's/@_/ /g' $inputfile.genus.counttable
	echo -e "$(date)\t$scriptname\tdone generating genus counttable"
fi
######GENERATE family LIST ##############
if [ "$family" != "N" ]
then
	sort -k5,5 -k5,5g $inputfile.tempsorted | sed 's/\t/,/g' | sort -u -t, -k 5,5 | sed 's/,/\t/g' | awk -F "\t" '{print$5}' | sed '/^$/d' | sed '/^ /d' > $inputfile.family.uniq.column
	echo -e "$(date)\t$scriptname\tdone creating $inputfile.family.uniq.column"
	for f in `cat $inputfile.barcodes`
	do
		echo "bar$f" > bar$f.$inputfile.family.output
		echo -e "$(date)\t$scriptname\tparsing barcode $f"
		grep "$f" $inputfile.tempsorted > bar.$f.$inputfile.tempsorted
		for d in `cat $inputfile.family.uniq.column`
		do
			grep -F -c -w "$d" bar.$f.$inputfile.tempsorted  >> bar$f.$inputfile.family.output
		done
	done
	echo "Family(@=contigbarcode)" > $inputfile.header
	cat $inputfile.header $inputfile.family.uniq.column > $inputfile.family.counttable_temp
	paste $inputfile.family.counttable_temp bar*.$inputfile.family.output > $inputfile.family.counttable
	sed -i 's/@_/ /g' $inputfile.family.counttable
	echo -e "$(date)\t$scriptname\tdone generating family counttable"
fi

#########CLEANUP###############
rm -f $inputfile.barcodes
rm -f $inputfile.barcodes.int
rm -f $inputfile.family.counttable_temp
rm -f $inputfile.family.uniq.column
rm -f $inputfile.genus.counttable_temp
rm -f $inputfile.genus.uniq.column
rm -f $inputfile.genus.uniq.columntable
rm -f $inputfile.gi.counttable_temp
rm -f $inputfile.gi.uniq.column
rm -f $inputfile.gi.uniq.columntable
rm -f $inputfile.header
rm -f $inputfile.species.counttable_temp
rm -f $inputfile.species.uniq.column
rm -f $inputfile.species.uniq.columntable
rm -f $inputfile.tempsorted
rm -f $inputfile.tempsorted
rm -f bar*.$inputfile.family.output
rm -f bar*.$inputfile.genus.output
rm -f bar*.$inputfile.gi.output
rm -f bar*.$inputfile.species.output
rm -f bar*.$inputfile.family.output
rm -f bar*.$inputfile.genus.output
rm -f bar*.$inputfile.gi.output
rm -f bar*.$inputfile.species.output
rm -f bar.*.$inputfile.tempsorted
