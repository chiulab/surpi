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
# (3) outputs contig assemblies, including all.$inputfile.unitigs.cut$cutoff_post_Abyss.$3-mini.fa
# (4) user specifies length cutoff after abyss assembly, and cutoff after minimo assembly, as well as number of cores and kmer value
#
# Copyright (C) 2014 Samia N Naccache - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
scriptname=${0##*/}
source debug.sh
source logging.sh

if [ $# -lt 5 ]
then
	echo "Usage: $scriptname <1.fasta> <2.cutoff_post Abyss> <3.cutoff_post Minimo> <4.#cores> <5.kmer> <6.ignoreBarcodeInfo (Y/N)>"
	exit
fi
###
inputfile=$1
cutoff_post_Abyss=$2
cutoff_post_Minimo=$3
cores=$4
kmer=$5
ignore_barcodes=$6
###
split_FASTA_size=100000

#### create list of barcodes in the fasta file in the following format: #barcode
log "Demultiplexing barcodes..."
START_DEMULTIPLEX=$(date +%s)

#The sed '/^#$/d' removes a blank #. This is needed in cases where barcodes are present along with reads that have no barcodes
grep ">" $inputfile | sed 's/#/ /g' | awk '{print$2}' | sort | uniq | sed 's/\// /g' | awk '{print$1}' | sort | uniq | sed 's/^/#/g' | sed '/^#$/d' > $inputfile.barcodes

if [ -s $inputfile.barcodes ] #if $inputfile.barcodes exists and has size>0, then we have multiple barcodes, but check if user wants to flatten & run together
then
	if [ $ignore_barcodes = "Y" ]
	then
		FLATTEN_BARCODES="1"
		echo "#" > $inputfile.barcodes
	else
		FLATTEN_BARCODES="0"
	fi
else #$inputfile.barcodes doesn't exist, or size=0, then we only have 1 barcode, so flatten & assemble entire run together
	FLATTEN_BARCODES="1"
	echo "#" > $inputfile.barcodes
fi

log "Completed demultiplexing barcodes."
END_DEMULTIPLEX=$(date +%s)
diff_DEMULTIPLEX=$(( END_DEMULTIPLEX - START_DEMULTIPLEX ))
log "Barcode demultiplex took $diff_DEMULTIPLEX s."
### generate fasta file for every separate barcode (demultiplex)

for f in `cat $inputfile.barcodes` ; do
	if [ $FLATTEN_BARCODES = "1" ]
	then
		ln -s $inputfile bar$f.$inputfile
	else
		grep -E "$f(/|$)" $inputfile -A 1 --no-group-separator > bar$f.$inputfile
	fi
	# split demultiplexed fasta file into 100,000 read sub-fastas
	log "Splitting FASTA into chunks of size: $split_FASTA_size."
	START_SPLIT=$(date +%s)

	cp bar$f.$inputfile bar$f.${inputfile}_n # So that the unsplit demultiplexed file is also denovo assembled #
	split_fasta.pl -i bar$f.$inputfile -o bar$f.$inputfile -n $split_FASTA_size
	log "Completed splitting FASTA file."
	END_SPLIT=$(date +%s)
	diff_SPLIT=$(( $END_SPLIT - $START_SPLIT ))
	log "Splitting FASTA took $diff_SPLIT s."
	### run abyss (deBruijn assembler) on each 100,000 read demultiplexed fasta file, including the unsplit demultiplexed file
	log "Running abyss on each $split_FASTA_size chunk..."
	START_ABYSS=$(date +%s)

	for d in bar$f.${inputfile}_* ; do
    echo $d
	  log "Command: abyss-pe k=$kmer name=$d.f se=$d np=$cores >& $d.abyss.log"
		#abyss-pe k=$kmer name=$d.f se=$d np=$cores >& $d.abyss.log
		abyss-pe k=$kmer name=$d.f se=$d >& $d.abyss.log
	done

	log "Completed running abyss on each $split_FASTA_size chunk."
	END_ABYSS=$(date +%s)
	diff_ABYSS=$(( END_ABYSS - START_ABYSS ))
	log "Abyss took $diff_ABYSS s."
###
### contigs from split files concatenated, after which reads smaller than the cutoff value are eliminated
	log "Starting concatenating and cutoff of abyss output"
	START_CATCONTIGS=$(date +%s)

	#concatenating contig files from different fasta splits, and adding kmer infromation and barcode information to contig headers
	cat bar$f.${inputfile}_*.f-unitigs.fa | sed 's/ /_/g' | sed "s/$/"_kmer"$kmer""/g;n" | sed "s/$/"$f"/g;n" > all.bar$f.$inputfile.unitigs.fa
	# only contigs larger than $cutoff_post_Abyss are retained
 	cat all.bar$f.$inputfile.unitigs.fa | awk 'NR%2==1 {x = $0} NR%2==0 { if (length($0) >= '$2') printf("%s\n%s\n",x,$0)}' > all.bar$f.$inputfile.unitigs.cut$cutoff_post_Abyss.fa

	log "Done concatenating and cutoff of abyss output"
	END_CATCONTIGS=$(date +%s)
	diff_CATCONTIGS=$(( END_CATCONTIGS - START_CATCONTIGS ))
	log "Concatenating and cutoff of abyss output took $diff_CATCONTIGS s."
###
### run Minimo (OLC assembler)
	log "Starting Minimo..."
	START_MINIMO=$(date +%s)
  log "Command: Minimo all.bar$f.$inputfile.unitigs.cut$cutoff_post_Abyss.fa -D FASTA_EXP=1"
	Minimo all.bar$f.$inputfile.unitigs.cut$cutoff_post_Abyss.fa -D FASTA_EXP=1
	log "Completed Minimo."
	END_MINIMO=$(date +%s)
	diff_MINIMO=$(( END_MINIMO - START_MINIMO ))
	log "Minimo took $diff_MINIMO s."
###########
	log "Starting cat barcode addition and cutoff of minimo output"
	START_MIN_PROCESS=$(date +%s)
	# Minimo output gives more than one line per sequence, so here we linearize sequences (linearization protocol from here http://seqanswers.com/forums/showthread.php?t=27567 )
	# then we add the relevant barcode to the end of the header contig. Contigs that survive untouched from abyss already have a barcode at the end of them, so that extra barcode is taken away
	cat all-contigs.fa | awk '{if (substr($0,1,1)==">"){if (p){print "\n";} print $0} else printf("%s",$0);p++;}END{print "\n"}' | sed '/^$/d' | sed 's/ /_/g' | sed "s/$/"$f"/g;n" | sed "s/"$f""$f"/"$f"/g" | sed 's/#/#@/g' | sed 's/^>/>contig_/g' > all.bar$f.$inputfile.unitigs.cut$cutoff_post_Abyss-minim.fa
	# change generic name all-contigs.fa
	mv all-contigs.fa all-contigs.fa.$f
	# only contigs larger than $cutoff_post_Minimo are retained
	cat all.bar$f.$inputfile.unitigs.cut$cutoff_post_Abyss-minim.fa | awk 'NR%2==1 {x = $0} NR%2==0 { if (length($0) >= '$3') printf("%s\n%s\n",x,$0)}' > all.bar$f.$inputfile.unitigs.cut$cutoff_post_Abyss.${cutoff_post_Minimo}-mini.fa

	log "Done cat barcode addition and cutoff of minimo output"
	END_MIN_PROCESS=$(date +%s)
	diff_MIN_PROCESS=$(( END_MIN_PROCESS - START_MIN_PROCESS ))
	log "cat barcode addition and cutoff of minimo output took $diff_MIN_PROCESS s"
done
###
### concatenate deBruijn -> OLC contigs from all barcodes together
log "Concatenating all barcodes together..."
START_CAT=$(date +%s)
cat all.bar*.$inputfile.unitigs.cut$cutoff_post_Abyss.${cutoff_post_Minimo}-mini.fa > all.$inputfile.unitigs.cut$cutoff_post_Abyss.${cutoff_post_Minimo}-mini.fa
log "Completed concatenating all barcodes."
END_CAT=$(date +%s)
diff_CAT=$(( END_CAT - START_CAT ))
log "Barcode concatenation took $diff_CAT s."

# cleaning up files by organizing directories, moving files into directories, and removing temporary files
mkdir --parents $inputfile.dir
mv bar*$inputfile*.fa $inputfile.dir
if [ -e all.$inputfile.contigs.abyssmini.cut$cutoff_post_Abyss.$cutoff_post_Minimo.e1.NR.RAPSearch.m8 ]
then
	mv all.$inputfile.contigs.abyssmini.cut$cutoff_post_Abyss.$cutoff_post_Minimo.e1.NR.RAPSearch.m8 $inputfile.dir
fi
rm -f all.$inputfile.contigs.abyssmini.cut$cutoff_post_Abyss.$cutoff_post_Minimo.e1.NR.RAPSearch.aln
rm -f all.$inputfile.contigs.abyssmini.e1.NR.RAPSearch.m8.noheader
rm -f all.$inputfile.contigs.abyssmini.e1.NR.RAPSearch.m8.noheader.seq
rm -f all.$inputfile.contigs.abyssmini.e1.NR.RAPSearch.m8.noheader
rm -f all.$inputfile.contigs.abyssmini.e1.NR.RAPSearch.m8.noheader.ex.fa
rm -f all.$inputfile.unitigs.cut$cutoff_post_Abyss-contigs.sortlen.seq
rm -f all-contigs*
rm -f all.bar*.$inputfile.unitigs.cut$cutoff_post_Abyss-minim.fa
rm -f $inputfile.barcodes
rm -f all.$inputfile.contigs.abyssmini.e1.NR.RAPSearch.m8.noheader.fasta
rm -f all.$inputfile.contigs.abyssmini.cut$cutoff_post_Abyss.$cutoff_post_Minimo.e1.NR.RAPSearch.addseq.gi
rm -f all.$inputfile.contigs.abyssmini.cut$cutoff_post_Abyss.$cutoff_post_Minimo.e1.NR.RAPSearch.addseq.gi.uniq
rm -f all.$inputfile.contigs.abyssmini.cut$cutoff_post_Abyss.$cutoff_post_Minimo.e1.NR.RAPSearch.addseq.gi.taxonomy
rm -f bar#*.${inputfile}_*
rm -f bar#*$inputfile*fasta
rm -f *$inputfile.unitigs.cut$cutoff_post_Abyss.fa.runAmos.log
rm -f all.bar*.$inputfile.unitigs.cut$cutoff_post_Abyss.${cutoff_post_Minimo}-mini.fa
rm -f bar*$inputfile
