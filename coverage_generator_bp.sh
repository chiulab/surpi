#!/bin/bash
#
#	coverage_generator_bp.sh
#
#	This script generates coverage maps, using SAM files as input.
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# input annotated sam file (variable 1) and annotated RAPsearch file (variable 7) , output ps and pdf files (as well as intermediary text report files). For each barcode, the best coverage map for each genus identified in the dataset is shown. Reads contributing to coverage map are derived from assignments present in the 2 input files
#
# Copyright (C) 2014 Samia N Naccache - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
# Last revised 1/26/2014    

if [ $# -lt 11 ]
then
	echo "Usage: <annotated sam file> <SNAP/RAP> <gi Y/N> <species Y/N> <genus Y/N> <family Y/N> <annotated RAPSearch file> <e value> <# cores> <top X complete genomes> <top X coverage plots>" 
	# added head -n 200 as a cap on how many genomes to retrieve initially (because get_genbankfasta.pl has limit) on 12/6/2013"
    exit
fi
ten="${10}"
eleven="${11}"

#substitute forward slash with @_ because forward slash in species name makes it ungreppable. using @_ because @ is used inside the contig barcode (ie. #@13 is barcode 13, contig generated) 
sed 's/ /_/g'  $1 | sed 's/,/_/g' | sed 's/\//@_/g' > $1.@
create_tab_delimited_table.pl  -f $2 $1.@  > $1.tempsorted
echo "done creating $1.tempsorted"
#GENERATE BARCODE LIST
sed 's/#/ /g'  $1.tempsorted | sed 's/\// /g' | awk '{print$2}' | sed 's/^/#/g' | sed 's/[1-2]$//g' | sort | uniq > $1.barcodes.int #makes a barcode list from the entire file #change $1.tempsorted to $1 once no need for temp table
echo "created list of barcodes"

sed '/N/d' $1.barcodes.int > $1.barcodes

#GENERATE genus LIST 
if [ "$5" != "N" ]
then
	sort -k4,4 -k4,4g $1.tempsorted | sed 's/\t/,/g' | sort -u -t, -k 4,4 | sed 's/,/\t/g' | awk -F "\t" '{print$4,"\t"$5}' | sed '/^$/d' | sed '/^ /d' > $1.genus.uniq.columntable
	awk -F "\t" '{print$1}'  $1.genus.uniq.columntable | sed '/^$/d' | sed '/^ /d' > $1.genus.uniq.column
	echo "done creating $1.genus.uniq.column"
	# Creating list of barcodes
	for f in `cat $1.barcodes` ; do
		echo "bar$f" > bar$f.$1.genus.output
		echo "parsing barcode $f "
		grep "$f" $1.tempsorted > bar.$f.$1.tempsorted

		# Creating list of Genus
		for genus in `cat $1.genus.uniq.column` ; do
			grep -c -w "$genus" bar.$f.$1.tempsorted  >> bar$f.$1.genus.output
			#########GENERATE COVERAGE from GENUS #
			# fasta for each genus
			grep -w "$genus" $1.@ |  grep "$f" | awk '{print ">"$1"\n"$10}'  > Snap.$genus.bar.$f.$1.tempsorted.fasta 
			echo "created $genus.bar.$f.$1.tempsorted.fasta"  
		
			sed 's/ /_/g' $7 | sed 's/,/_/g' | sed 's/\//@_/g' > $7.@ # fasta for each genus from Rapsearch
			grep "$f" $7.@ > bar.$f.$7.@
			echo "done generating bar.$f.$7.@ "
			grep -w "$genus" bar.$f.$7.@ | awk '{print ">"$1"\n"$13}' > Rap.$genus.bar.$f.$1.tempsorted.fasta
			cat Snap.$genus.bar.$f.$1.tempsorted.fasta Rap.$genus.bar.$f.$1.tempsorted.fasta > $genus.bar.$f.$1.tempsorted.fasta
			echo "created $genus.bar.$f.$1.tempsorted.fasta +RAPsearch creation"		

			# list of gis for each genus in order of read number
			# added head -n 200 as a cap on how many genomes to retrieve initially (because get_genbankfasta.pl has limit) on 12/6/2013
			grep "$genus" bar.$f.$1.tempsorted  | awk '{print$2}' | sort | uniq -c | sed 's/gi|//g' | sed 's/|//g' | sort -g -r -k 1 | awk '{print$2}' | head -n 200 > $1.$genus.gi.list 
			echo "created $1.$genus.gi.list"
			# retain only gis that are complete genomes
			get_genbankfasta.pl -i $1.$genus.gi.list | egrep ".omplete .enome"  | awk -F "|" '{print$2}' | head -n "$ten" > $1.$genus.gi.list.curatedgenome
			# if no gis with complete genomes, then gis with complete sequences, if no complete sequences, then anything
			if [ -s $1.$genus.gi.list.curatedgenome ]
			then
				echo "found complete genomes"
			else 
				echo "no complete genomes"
				get_genbankfasta.pl -i $1.$genus.gi.list | egrep ".omplete .equence"  | awk -F "|" '{print$2}' | head -n "$ten" > $1.$genus.gi.list.curatedgenome 
				if [ -s file ]
				then
					echo "found complete sequences"
				else
					echo "no complete genomes or complete sequences"
					get_genbankfasta.pl -i $1.$genus.gi.list | awk -F "|" '{print$2}' | head -n "$ten" > $1.$genus.gi.list.curatedgenome				
				fi
			fi
			echo "created $1.$genus.gi.list.curatedgenomes"
		
			# for each genus, plot all contained gis against genus-specific fasta from NT and RAPSearch 
			for gi in `cat $1.$genus.gi.list.curatedgenome` ; do
				plot_reads_to_gi.sh $genus.bar.$f.$1.tempsorted.fasta $gi $genus $8 $9
				# highlight Report files
				cp $genus.bar.$f.$1.tempsorted.fasta.$gi.$genus.$8.report $genus.bar.$f.$1.$gi.$8.Report 
				rm -f "$genus".[0-9]*.fasta 
				echo "Done $genus.bar.$f.$1.$gi.$8.Report"
			done
	
		done

		# Generate concatenated list of all reports for this barcode			
		grep "Coverage in bp" *bar.$f.$1.*.Report | sed 's/Coverage in bp/Coverageinbp/g' | sed 's/.bar./ /g' | sed 's/@_/ /g' |  sed "s/$1//g" |  sed "s/.$8./ $8 /g" | sed 's/Report://g' | sed 's/\.\.//g'   | sort -g -r -k 7 > bar.$f.$1.genus.report.coverage 	
			
		# Generate list of  &&1&& top species by coverage for each genus			
		echo | sed '/$^/d' > bar.$f.$1.genus.report.top 
		for genus in `cat $1.genus.uniq.column` ; do
			grep -m "$eleven" "$genus" bar.$f.$1.genus.report.coverage >>  bar.$f.$1.genus.report.top  
		done #loop4_done
			
		# Concatenate all coverage maps based on list of  &&1 && top species by coverage for each genus						
		echo | sed '/$^/d' > bar.$f.$1.genus.top.ps  
		awk '{print$3, $7}' bar.$f.$1.genus.report.top | sort -g -r -k 2 | sed 's/0\./0/g' | grep -v -w "0" | awk '{print$1}' > bar.$f.$1.genus.report.top.gis 
		for gi in `cat bar.$f.$1.genus.report.top.gis` ; do
			cat *.$gi.*ps >> bar.$f.$1.genus.top.ps
		done # loop5_done
		ps2pdf14 bar.$f.$1.genus.top.ps bar.$f.$1.genus.top.pdf	
			
		rm -f bar.$f.$1.genus.report.top.gis
		mkdir genus.bar.$f.$1.plotting
		mv *.bar.$f.$1.tempsorted.fasta* genus.bar.$f.$1.plotting
	
	done # loop1_barcodes
### Continue building Genus table###
fi
		
#########CLEANUP###############

rm -f $1.barcodes
rm -f $1.barcodes.int
rm -f $1.family.counttable_temp
rm -f $1.family.uniq.column
rm -f $1.family.uniq.column_nogenus
rm -f $1.genus.counttable_temp
rm -f $1.genus.uniq.column
rm -f $1.genus.uniq.columntable
rm -f $1.gi.counttable_temp
rm -f $1.gi.uniq.column
rm -f $1.gi.uniq.columntable
rm -f $1.header
rm -f $1.species.counttable_temp
rm -f $1.species.uniq.column
rm -f $1.species.uniq.columntable
rm -f $1.tempsorted
rm -f $1.tempsorted
rm -f bar*.$1.family.output
rm -f bar*.$1.genus.output
rm -f bar*.$1.gi.output
rm -f bar*.$1.species.output
rm -f bar*.$1.family.output
rm -f bar*.$1.genus.output
rm -f bar*.$1.gi.output
rm -f bar*.$1.species.output
rm -f bar.*.$1.tempsorted
rm -f $1*gi.list.curatedgenome
rm -f $1*gi.list
#rm -f bar.*.$1.top
rm -f $1.@
rm -f $7.@
rm -f $1.tempsorted
rm -f formatdb.log
