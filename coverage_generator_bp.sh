#!/bin/bash
#
#	coverage_generator_bp.sh
#
#	This script generates coverage maps, using SAM files as input.
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# input annotated sam file (variable 1) and annotated RAPSearch file (variable 7) , output ps and pdf files (as well as intermediary text report files). For each barcode, the best coverage map for each genus identified in the dataset is shown. Reads contributing to coverage map are derived from assignments present in the 2 input files
#
# Copyright (C) 2014 Samia N Naccache - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
# Last revised 1/26/2014

if [ $# -lt 7 ]
then
	echo "Usage: <annotated SNAP file> <annotated RAPSearch file> <e value> <# cores> <top X gis to compare against each other> <top X coverage plots per genus><basef>"
	exit
fi
basef=$7
####
date
START20=$(date +%s)
####

date
START0=$(date +%s)

sed 's/ /_/g' $1 > $1.nospace # removing spaces allows genera with  spaces in their names (eg Influenzavirus A to be properly `cat`
create_tab_delimited_table.pl  -f SNAP $1.nospace > $1.tab  # creates a 4 column tab delimited table: header \t gi \t genus \t family so that  genus can be accurately extracted
echo "done creating $1.tab tab delimited table"
#GENERATE LIST OF ALL BARCODES
sed 's/#/ /g'  $1.tab | sed 's/\// /g' | awk '{print$2}' | sort | uniq | sed '/N/d' > $1.barcodes # creates list of barcodes present in $1 #to get rid of amiguitiy, if N is in the barcode you don't want it to count as a separate barcode. Might not be safe if Illumina changes barcoding scheme away from integers and ACTG. On other hand don't want to create an infinite number of .pdf files if we have ambigous barcodes
echo "created list of all barcodes in $1"

date
END0=$(date +%s)
diff=$(( END0 - START0 ))
echo " Modify $1 and $2 Took $diff seconds"

# LOOP 1 : FOR 	EACH BARCODE Generates a .pdf file with 1 best coverage map for each genus, created by BLASTning all reads from each genus (in $1 and $2) against each gi found in $1 for that barcode and corresponding to that genus.
for bar in `cat $1.barcodes`
do
	echo "parsing barcode $f "
	date
	START1=$(date +%s)

	egrep "#$bar/" $1.nospace > bar.$bar.$1.tmps  # separate tab delimited file created for specific $bar barcode
	egrep "#$bar" $2 > bar.$bar.$2.tmps # in this instance not including contigs
	date
	END1=$(date +%s)
	diff=$(( END1 - START1 ))
	echo " demultiplexing Took $diff seconds"

	#LOOP 2: FOR EACH GENUS
	#GENERATE LIST OF ALL GENERA
	date
	START2=$(date +%s)
	egrep "#$bar/" $1.tab | awk -F "\t" '{print$4}'  | sort | uniq | sed '/^$/d' | sed '/^ /d' > bar.$bar.$1.genus.uniq.list # compiling list of unique genera present in entire sample set. Extra seds required as some entries have no genus, and those entries get uniqued into a blank space.
	echo "done creating $1.genus.uniq.list list of all genera in $1"
	# generate a separate fasta file for each each $genus (within each barcode) from $1.@ (file which still has read information)
	END2=$(date +%s)
	diff=$(( END2 - START2 ))
	echo " creating list of genera Took $diff seconds"

	for genus in `cat bar.$bar.$1.genus.uniq.list`
	do
		date
		START3=$(date +%s)

		mixed=$genus.bar.$bar.$basef # bash is having problems handling strings of variables in names

		grep -w "$genus" bar.$bar.$1.tmps > Snap.$mixed.tmps
		awk '{print ">"$1"\n"$10}'  Snap.$mixed.tmps > Snap.$mixed.tmpsfa
		echo "created Snap.$mixed.tmpsfa"
		grep -w "$genus" bar.$bar.$2.tmps | awk '{print ">"$1"\n"$13}' > Rap.$mixed.tmpsfa
		cat Snap.$mixed.tmpsfa Rap.$mixed.tmpsfa > SnRa.$mixed
		echo "created SnRa.$mixed "

		# GENERATE LIST of GIs for each genus in order of read number
		awk '{print$3}' Snap.$mixed.tmps  | sort | uniq -c | sed 's/gi|//g' | sed 's/|//g' | sort -g -r -k 1 | awk '{print$2}' | head -n 200 > bar.$bar.$1.$genus.gi.list  
		# for $genus , GIs are retrieved and ordered by abundance. Only top 200 are retained due to genbank retrieval limit
		echo "created bar.$bar.$1.$genus.gi.list"
		# create list of curated GIs $1.$genus.gi.list.curatedgenome
		# First retain only gis that are complete genomes if no GIs with "complete genomes" are returned, we'll go to GIs  "complete sequences", if no complete sequences, then we just go with the GIs we have

		get_genbankfasta.pl -i bar.$bar.$1.$genus.gi.list  > bar.$bar.$1.$genus.gi.headers 

		egrep ">gi.*[C|c]omplete [G|g]enome" bar.$bar.$1.$genus.gi.headers  | awk -F "|" '{print$2}'  | head -n $5 > bar.$bar.$1.$genus.gi
		if [ -s bar.$bar.$1.$genus.gi ]
		then
			echo "found complete genomes"
		else
			echo "no complete genomes"
			egrep ">gi.*[C|c]omplete [S|s]equence" bar.$bar.$1.$genus.gi.headers  | awk -F "|" '{print$2}' | head -n $5 > bar.$bar.$1.$genus.gi
			if [ -s file ]
			then
				echo "found complete sequences"
			else
				echo "no complete genomes or complete sequences"
				egrep ">gi" bar.$bar.$1.$genus.gi.headers  | awk -F "|" '{print$2}'  | head -n $5 > bar.$bar.$1.$genus.gi
			fi
		fi
		echo "created bar.$bar.$1.$genus.gi"
		date
		END3=$(date +%s)
		diff=$(( END3 - START3 ))
		echo " Parsing bar $bar into genera Took $diff seconds"

		date
		START4=$(date +%s)
		##### split query ####
		let "numreads = `grep -c ">" SnRa.$mixed`" ###
		let "numreadspercore = numreads / $4" ###
		echo "number of read $numreads"
		echo "number of reads per core $numreadspercore"
		if [ $numreadspercore = 0 ]
		then
			split_fasta.pl -i SnRa.$mixed -o SnRa.$mixed -n 1
		else
			split_fasta.pl -i SnRa.$mixed -o SnRa.$mixed -n $numreadspercore
		fi
		date
		END4=$(date +%s)
		diff=$(( END4 - START4 ))
		echo " Splitting  SnRa.$mixed into $4 files Took $diff seconds"

		# LOOP 3: COMPARE against AlL GIs for each genus, plot all contained gis against genus-specific fasta from NT and RAPSearch
		for gi in `cat bar.$bar.$1.$genus.gi`
		do	
			date
			START5=$(date +%s)
			plot_reads_to_gi.sh SnRa.$mixed $gi $genus $3 $4
			# highlight Report files
			mv SnRa.$mixed.$gi.$genus.$3.report bar.$bar.$genus.$basef.$gi.$3.Report
			echo "Done bar.$bar.$genus.$basef.$gi.$3.Report"
			rm -f $genus.[1-9]*.fasta
		done # END LOOP 3 (gi)
		rm -f SnRa.${mixed}_[0-9]
		rm -f SnRa.${mixed}_[0-9][0-9]
	done  # END LOOP 2 ( GENUS)

	# Generate  bar.$bar.$1.genus.report.coverage (concatenated list of all coverage reports for this $bar)
	grep "Coverage in bp" bar.$bar*$basef.*.$3.Report | sed 's/Coverage in bp/Coverageinbp/g' | sed 's/.bar./ /g' | sed "s/\."$basef"\./ /g" |  sed "s/."$3"./ "$3" /g" | sed 's/Report://g' | sed 's/\./ /g'   | sort -g -r -k 8 > bar.$bar.$1.genus.report.coverage

	# Generate list of  top isolates (GIs) by coverage for each $genus for this $bar
	echo | sed '/^$/d' > bar.$bar.$basef.genus.report.coverage.top
	# LOOP 4 retrieve top isolates for each genus from bar.$bar.$1.genus.report.coverage
	date
	END5=$(date +%s)
	diff=$(( END5 - START5 ))
	echo " Generating coverage maps for SnRa.$mixed Took $diff seconds"

	date
	START6=$(date +%s)
	for genera in `cat bar.$bar.$1.genus.uniq.list`
	do
		grep -m "$6" "$genera" bar.$bar.$1.genus.report.coverage >>  bar.$bar.$basef.genus.report.coverage.top
	done # END LOOP 4 (top coverage)

	# Concatenate all coverage maps based on bar.$bar.$1.genus.report.top (list of top isolates by coverage for each genus)
	echo | sed '/^$/d' > bar.$bar.$basef.genus.top.ps  # create new file each time outside of forloop
	sort -g -r -k 8 bar.$bar.$basef.genus.report.coverage.top | grep -v -w "0" | awk '{print$3, $4}' | awk '{print$2}' > bar.$bar.$basef.genus.report.coverage.top.gis 	# generate list of top gi's for each $genus, sorted by longest coverage in bp from bar.$bar.$1.genus.report.top
	# LOOP 5:  concatenate top coverage maps based on  bar.$bar.$1.genus.report.top into one .ps file
	for gi in `cat bar.$bar.$basef.genus.report.coverage.top.gis`
	do
		cat SnRa.*bar.$bar.$basef.$gi.*.$3*ps >> bar.$bar.$basef.genus.top.ps
	done # END LOOP 5 ( generate .ps file for each $bar)
	ps2pdf14 bar.$bar.$basef.genus.top.ps bar.$bar.$basef.genus.top.pdf
	# Sequester  fasta files corresponding to each relevant alignment of $genus specific reads against the top GIs in  bar.$bar.$1.genus.report.top (list of top isolates by coverage for each genus
	mkdir genus.bar.$bar.$basef.Blastn.fasta
	# LOOP 6:  concatenate top coverage maps based on  bar.$bar.$1.genus.report.top into one .ps file
	for gi in `cat bar.$bar.$basef.genus.report.coverage.top.gis`
	do
		mv SnRa*bar.$bar.$basef.$gi.*Blastn.uniq.ex.fa genus.bar.$bar.$basef.Blastn.fasta
		date
		END6=$(date +%s)
		diff=$(( END6 - START6 ))
		echo " Generating bar.$bar.$basef.genus.top.pdf Took $diff seconds"

	done # END LOOP 6 ( generate .ps file for each $bar)
	#mixed=$genus.bar.$bar.$basef # bash is having problems handling strings of variables in names


	# Cleanup files into proper directories:
	# rm -f bar.$bar.$1.genus.report.top.gis
	mkdir genus.bar.$bar.$basef.plotting
	mv bar.$bar*$basef*$3.Report genus.bar.$bar.$basef.plotting
	mv bar.$bar.$1.genus.report.coverage genus.bar.$bar.$basef.plotting
	mv  bar.$bar.$basef.genus.report.coverage.top genus.bar.$bar.$basef.plotting
	mv bar.$bar.$basef.genus.top.ps  genus.bar.$bar.$basef.plotting 
	mv SnRa*bar.$bar.$basef*$3* genus.bar.$bar.$basef.plotting
	mv SnRa*bar*$bar*$basef genus.bar.$bar.$basef.plotting 
	mv SnRa*bar.$bar.$basef*Blastn.uniq.ex.fa genus.bar.$bar.$basef.plotting 
done # END LOOP 1 (barcodes)

#######CLEANUP###############
rm -f $1.tab 
rm -f $1.nospace
#rm -f $2.nocontig
rm -f $1.barcodes
rm -f bar*$1*tmps 
rm -f bar*$2*tmps 
rm -f bar*$1*genus.uniq.list 
rm -f Snap*tmps
rm -f Snap*tmpsfa
rm -f Rap*tmpsfa
rm -f bar*$1*gi.list  
rm -f bar*$1*gi.headers 
rm -f bar*$1*gi
rm -f bar*$basef.genus.report.coverage.top.gis
rm -f formatdb.log

END20=$(date +%s)
diff=$(( END20 - START20 ))
echo " All coverage_generator_bp.sh Took $diff seconds"
