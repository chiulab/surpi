#!/bin/bash
#
#	coverage_generator_bp.sh
#
#	This script generates coverage maps, using SAM files as input.
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# input annotated sam file (variable 1) and annotated RAPSearch file (variable 2) , output ps and pdf files (as well as intermediary text report files). For each barcode, the best coverage map for each genus identified in the dataset is shown. Reads contributing to coverage map are derived from assignments present in the 2 input files
#
# Copyright (C) 2014 Samia N Naccache - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.

scriptname=${0##*/}

if [ $# -lt 7 ]
then
	echo "Usage: $scriptname <annotated SNAP file> <annotated RAPSearch file> <e value> <# cores> <top X gis to compare against each other> <top X coverage plots per genus> <basef>"
	exit
fi
###
SNAP_file=$1
RAPSearch_file=$2
e_value=$3
cores=$4
top_gis=$5
top_plots=$6
basef=$7
###

START0=$(date +%s)

echo -e "$(date)\t$scriptname\tStarting coverage_generator_bp.sh"
sed 's/ /_/g' $SNAP_file > $SNAP_file.nospace # removing spaces allows genera with spaces in their names (eg Influenzavirus A to be properly `cat`
create_tab_delimited_table.pl  -f SNAP $SNAP_file.nospace > $SNAP_file.tab  # creates a 4 column tab delimited table: header \t gi \t genus \t family so that genus can be accurately extracted
echo -e "$(date)\t$scriptname\tDone creating $SNAP_file.tab tab delimited table"
#GENERATE LIST OF ALL BARCODES

# create list of barcodes present in $SNAP_file
# to get rid of ambiguity, if N is in the barcode you don't want it to count as a separate barcode.
# Might not be safe if Illumina changes barcoding scheme away from integers and ACTG.
# On other hand don't want to create an infinite number of .pdf files if we have ambigous barcodes
sed 's/#/ /g'  $SNAP_file.tab | sed 's/\// /g' | awk '{print$2}' | sort | uniq | sed '/N/d' > $SNAP_file.barcodes

echo -e "$(date)\t$scriptname\tCreated list of all barcodes in $SNAP_file"

END0=$(date +%s)
diff=$(( END0 - START0 ))
echo -e "$(date)\t$scriptname\tModify $SNAP_file and $RAPSearch_file Took $diff seconds"
echo "-----------------------------"
# LOOP 1 : FOR 	EACH BARCODE Generates a .pdf file with 1 best coverage map for each genus, created by BLASTning all reads from each genus (in $SNAP_file and $RAPSearch_file) against each gi found in $SNAP_file for that barcode and corresponding to that genus.
for bar in `cat $SNAP_file.barcodes`
do
	echo -e "$(date)\t$scriptname\tParsing barcode $f"
	START1=$(date +%s)

	egrep "#$bar/" $SNAP_file.nospace > bar.$bar.$SNAP_file.tmps  # separate tab delimited file created for specific $bar barcode
	egrep "#$bar" $RAPSearch_file > bar.$bar.$RAPSearch_file.tmps # in this instance not including contigs
	END1=$(date +%s)
	diff=$(( END1 - START1 ))
	echo -e "$(date)\t$scriptname\tDemultiplexing Took $diff seconds"

	#LOOP 2: FOR EACH GENUS
	#GENERATE LIST OF ALL GENERA
	START2=$(date +%s)
	egrep "#$bar/" $SNAP_file.tab | awk -F "\t" '{print$4}'  | sort | uniq | sed '/^$/d' | sed '/^ /d' > bar.$bar.$SNAP_file.genus.uniq.list # compiling list of unique genera present in entire sample set. Extra seds required as some entries have no genus, and those entries get uniqued into a blank space.
	echo -e "$(date)\t$scriptname\tDone creating $SNAP_file.genus.uniq.list list of all genera in $SNAP_file"
	# generate a separate fasta file for each each $genus (within each barcode) from $SNAP_file.@ (file which still has read information)
	END2=$(date +%s)
	diff=$(( END2 - START2 ))
	echo -e "$(date)\t$scriptname\tCreating list of genera Took $diff seconds"

	for genus in `cat bar.$bar.$SNAP_file.genus.uniq.list`
	do
		echo "----------------------"
		START3=$(date +%s)

		mixed="$genus.bar.$bar.$basef" # bash is having problems handling strings of variables in names

		grep -w "$genus" bar.$bar.$SNAP_file.tmps > Snap.$mixed.tmps
		awk '{print ">"$1"\n"$10}'  Snap.$mixed.tmps > Snap.$mixed.tmpsfa
		echo -e "$(date)\t$scriptname\tCreated Snap.$mixed.tmpsfa"
		grep -w "$genus" bar.$bar.$RAPSearch_file.tmps | awk '{print ">"$1"\n"$13}' > Rap.$mixed.tmpsfa
		cat Snap.$mixed.tmpsfa Rap.$mixed.tmpsfa > SnRa.$mixed
		echo -e "$(date)\t$scriptname\tCreated SnRa.$mixed "

		# GENERATE LIST of GIs for each genus in order of read number
		awk '{print$3}' Snap.$mixed.tmps  | sort | uniq -c | sed 's/gi|//g' | sed 's/|//g' | sort -g -r -k 1 | awk '{print$2}' | head -n 200 > bar.$bar.$SNAP_file.$genus.gi.list
		# for $genus , GIs are retrieved and ordered by abundance. Only top 200 are retained due to genbank retrieval limit
		echo -e "$(date)\t$scriptname\tCreated bar.$bar.$SNAP_file.$genus.gi.list"
		# create list of curated GIs $SNAP_file.$genus.gi.list.curatedgenome
		# First retain only gis that are complete genomes if no GIs with "complete genomes" are returned, we'll go to GIs  "complete sequences", if no complete sequences, then we just go with the GIs we have

		get_genbankfasta.pl -i bar.$bar.$SNAP_file.$genus.gi.list  > bar.$bar.$SNAP_file.$genus.gi.headers 

		egrep ">gi.*[Cc]omplete [Gg]enome" bar.$bar.$SNAP_file.$genus.gi.headers  | awk -F "|" '{print$2}'  | head -n $top_gis > bar.$bar.$SNAP_file.$genus.gi
		if [ -s bar.$bar.$SNAP_file.$genus.gi ]
		then
			echo -e "$(date)\t$scriptname\tFound complete genomes"
		else
			echo -e "$(date)\t$scriptname\tNo complete genomes"
			egrep ">gi.*[Cc]omplete [Ss]equence" bar.$bar.$SNAP_file.$genus.gi.headers  | awk -F "|" '{print$2}' | head -n $top_gis > bar.$bar.$SNAP_file.$genus.gi
			if [ -s file ]
			then
				echo -e "$(date)\t$scriptname\tFound complete sequences"
			else
				echo -e "$(date)\t$scriptname\tNo complete genomes or complete sequences"
				egrep ">gi" bar.$bar.$SNAP_file.$genus.gi.headers  | awk -F "|" '{print$2}'  | head -n $top_gis > bar.$bar.$SNAP_file.$genus.gi
			fi
		fi
		echo -e "$(date)\t$scriptname\tCreated bar.$bar.$SNAP_file.$genus.gi"
		END3=$(date +%s)
		diff=$(( END3 - START3 ))
		echo -e "$(date)\t$scriptname\tParsing bar $bar into genera Took $diff seconds"

		START4=$(date +%s)
		##### split query ####
		let "numreads = `grep -c ">" SnRa.$mixed`" ###
		let "numreadspercore = numreads / $cores" ###
		echo -e "$(date)\t$scriptname\tnumber of read $numreads"
		echo -e "$(date)\t$scriptname\tnumber of reads per core $numreadspercore"
		if [ $numreadspercore = 0 ]
		then
			split_fasta.pl -i SnRa.$mixed -o SnRa.$mixed -n 1
		else
			split_fasta.pl -i SnRa.$mixed -o SnRa.$mixed -n $numreadspercore
		fi
		END4=$(date +%s)
		diff=$(( END4 - START4 ))
		echo -e "$(date)\t$scriptname\tSplitting SnRa.$mixed into $cores files Took $diff seconds"

		# LOOP 3: COMPARE against AlL GIs for each genus, plot all contained gis against genus-specific fasta from NT and RAPSearch
		for gi in `cat bar.$bar.$SNAP_file.$genus.gi`
		do
			START5=$(date +%s)
			plot_reads_to_gi.sh SnRa.$mixed $gi $genus $e_value $cores
			# highlight Report files
			mv SnRa.$mixed.$gi.$genus.$e_value.report bar.$bar.$genus.$basef.$gi.$e_value.Report
			echo -e "$(date)\t$scriptname\tDone bar.$bar.$genus.$basef.$gi.$e_value.Report"
			rm -f $genus.[1-9]*.fasta
		done # END LOOP 3 (gi)
		rm -f SnRa.${mixed}_[0-9]
		rm -f SnRa.${mixed}_[0-9][0-9]
	done  # END LOOP 2 ( GENUS)

	# Generate bar.$bar.$SNAP_file.genus.report.coverage (concatenated list of all coverage reports for this $bar)
	grep "Coverage in bp" bar.$bar*$basef.*.$e_value.Report | sed 's/Coverage in bp/Coverageinbp/g' | sed 's/.bar./ /g' | sed "s/\."$basef"\./ /g" |  sed "s/."$3"./ "$3" /g" | sed 's/Report://g' | sed 's/\./ /g'   | sort -g -r -k 8 > bar.$bar.$SNAP_file.genus.report.coverage

	# Generate list of  top isolates (GIs) by coverage for each $genus for this $bar
	echo | sed '/^$/d' > bar.$bar.$basef.genus.report.coverage.top
	# LOOP 4 retrieve top isolates for each genus from bar.$bar.$SNAP_file.genus.report.coverage
	END5=$(date +%s)
	diff=$(( END5 - START5 ))
	echo -e "$(date)\t$scriptname\tGenerating coverage maps for SnRa.$mixed Took $diff seconds"

	START6=$(date +%s)
	for genera in `cat bar.$bar.$SNAP_file.genus.uniq.list`
	do
		grep -m "$top_plots" "$genera" bar.$bar.$SNAP_file.genus.report.coverage >>  bar.$bar.$basef.genus.report.coverage.top
	done # END LOOP 4 (top coverage)

	# Concatenate all coverage maps based on bar.$bar.$SNAP_file.genus.report.top (list of top isolates by coverage for each genus)
	echo | sed '/^$/d' > bar.$bar.$basef.genus.top.ps  # create new file each time outside of forloop
	sort -g -r -k 8 bar.$bar.$basef.genus.report.coverage.top | grep -v -w "0" | awk '{print$3, $4}' | awk '{print$2}' > bar.$bar.$basef.genus.report.coverage.top.gis 	# generate list of top gi's for each $genus, sorted by longest coverage in bp from bar.$bar.$SNAP_file.genus.report.top
	# LOOP 5:  concatenate top coverage maps based on  bar.$bar.$SNAP_file.genus.report.top into one .ps file
	for gi in `cat bar.$bar.$basef.genus.report.coverage.top.gis`
	do
		cat SnRa.*bar.$bar.$basef.$gi.*.$e_value*ps >> bar.$bar.$basef.genus.top.ps
	done # END LOOP 5 ( generate .ps file for each $bar)
	ps2pdf14 bar.$bar.$basef.genus.top.ps bar.$bar.$basef.genus.top.pdf
	# Sequester fasta files corresponding to each relevant alignment of $genus specific reads against the top GIs in  bar.$bar.$SNAP_file.genus.report.top (list of top isolates by coverage for each genus
	mkdir genus.bar.$bar.$basef.Blastn.fasta
	# LOOP 6:  concatenate top coverage maps based on  bar.$bar.$SNAP_file.genus.report.top into one .ps file
	for gi in `cat bar.$bar.$basef.genus.report.coverage.top.gis`
	do
		mv SnRa*bar.$bar.$basef.$gi.*Blastn.uniq.ex.fa genus.bar.$bar.$basef.Blastn.fasta
		END6=$(date +%s)
		diff=$(( END6 - START6 ))
	done # END LOOP 6 ( generate .ps file for each $bar)
	echo -e "$(date)\t$scriptname\tGenerating bar.$bar.$basef.genus.top.pdf Took $diff seconds"

	# Cleanup files into proper directories:
	# rm -f bar.$bar.$SNAP_file.genus.report.top.gis

	output_directory="genus.bar.$bar.$basef.plotting"
	mkdir $output_directory
	mv bar.$bar*$basef*$e_value.Report 				$output_directory
	mv bar.$bar.$SNAP_file.genus.report.coverage 	$output_directory
	mv bar.$bar.$basef.genus.report.coverage.top 	$output_directory
	mv bar.$bar.$basef.genus.top.ps  				$output_directory
	mv SnRa*bar.$bar.$basef*$e_value* 				$output_directory
	mv SnRa*bar*$bar*$basef 						$output_directory
# 	mv SnRa*bar.$bar.$basef*Blastn.uniq.ex.fa 		$output_directory
done # END LOOP 1 (barcodes)

#######CLEANUP###############
rm -f $SNAP_file.tab
rm -f $SNAP_file.nospace
#rm -f $RAPSearch_file.nocontig
rm -f $SNAP_file.barcodes
rm -f bar*$SNAP_file*tmps
rm -f bar*$RAPSearch_file*tmps
rm -f bar*$SNAP_file*genus.uniq.list
rm -f Snap*tmps
rm -f Snap*tmpsfa
rm -f Rap*tmpsfa
rm -f bar*$SNAP_file*gi.list
rm -f bar*$SNAP_file*gi.headers
rm -f bar*$SNAP_file*gi
rm -f bar*$basef.genus.report.coverage.top.gis
rm -f formatdb.log

END20=$(date +%s)
diff=$(( END20 - START0 ))
echo -e "$(date)\t$scriptname\tAll coverage_generator_bp.sh Took $diff seconds"
