#!/bin/bash
#
#	SURPI_v22_15.sh
#
#	This is the main driver script for the SURPI pipeline.
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
#
# Copyright (C) 2014 Samia N Naccache, Scot Federman, and Charles Y Chiu - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
# Last revised 1/26/2014    

optspec=":a:c:d:f:hi:l:m:n:p:q:r:s:vx:z:"
bold=$(tput bold)
normal=$(tput sgr0)
host=$(hostname)
scriptname=${0##*/}

while getopts "$optspec" option; do
	case "${option}" in
		a) adapter_set=${OPTARG};;	#Truseq/Nextera
		c) cores=${OPTARG};;	# use all cores if not specified
		d) cache_reset=${OPTARG};;
		f) config_file=${OPTARG};; # get parameters from config file if specified
		h) HELP=1;;
		i) inputfile=${OPTARG};; # input FASTQ file to pipeline
		l) crop_length=${OPTARG};; #75 is default
		m) human_mapping=${OPTARG};;
		n) alignment=${OPTARG};;
		p) preprocess=${OPTARG};;
		q) quality=${OPTARG};;	#Sanger/Illumina
		r) rapsearch_database=${OPTARG};;	#Viral/NR
		s) start_nt=${OPTARG};;	#10 is default
		u) run_mode=${OPTARG};; #Comprehensive/Fast
		v) VERIFY_FASTQ=${OPTARG};; #1 is default
		x) length_cutoff=${OPTARG};;
		z)	create_config_file=${OPTARG}
			configprefix=${create_config_file%.fastq}
			;;
		:)	echo "Option -$OPTARG requires an argument." >&2
			exit 1
      		;;
	esac
done

if [[ $HELP -eq 1  ||  $# -lt 1 ]]
then
	cat <<USAGE

${bold}$scriptname${normal}

This program will run the SURPI pipeline with the parameters supplied by either the config file, or specified on the command line.

${bold}Usage:${normal}

Run SURPI pipeline with a config file:
	$scriptname -f config

Run SURPI pipeline specifying parameters on command line:
	$scriptname -i test.fastq -q Sanger -a Truseq -x 50 -r Viral

Create default config and go file
	$scriptname -z test.fastq
	
${bold}Command Line Switches:${normal}

	-h	Show help & ignore all other switches

	-f	Specify config file & ignore all other switches
	-i	Specify FASTQ input file

	-q	Specify quality type [mandatory] (Sanger/Illumina)
	-x	Specify length_cutoff [mandatory]
	-a	Specify adapter_set [mandatory] (Truseq/Nextera)
	-r	Specify final RAPSearch database [mandatory] (Viral/NR)

	-s	Specify crop - startnt [optional] (default: 10)
	-l	Specify crop - crop_length [optional] (default: 75)
	-c	Specify cores [optional] (default: use all cores on machine)
	-d	Specify cache_reset [optional] (default: use a calculated value, 200, 100, or 50GB)
	
	-p	Skip preprocessing [Currently only a placeholder - not functional]
	-m	Skip Human Mapping [Currently only a placeholder - not functional]
	-n	Skip Snap to NT [Currently only a placeholder - not functional]
	
	-u	SURPI Run mode [optional] (Comprehensive [default], Fast)
	-v	Verify FASTQ quality [optional] (0 / 1 [default] / 2 / 3)
		FASTQ validation uses FastQValidator. See http://genome.sph.umich.edu/wiki/FastQ_Validation_Criteria for details.
		If quality fails, then pipeline run may end depending on selection. Details will be logged in the .quality file.

		0 - Skip entire FASTQ validation process
		1 - Run FASTQ Validation process - do not check for unique names - quit pipeline on failure ${bold}[default]${normal}
		2 - Run FASTQ Validation process - include check for unique names - quit pipeline on failure
		3 - Run FASTQ Validation process - include check for unique names - pipeline proceeds on failure

	-z	Create default config file and go file. [optional] (specify fastq filename)
		This option will create a standard .config file, and go file.


USAGE
	exit
fi

if [[ $create_config_file ]]
then
	echo "nohup $scriptname -f $configprefix.config > SURPI.$configprefix.log 2> SURPI.$configprefix.err" > go_$configprefix
	chmod +x go_$configprefix
#------------------------------------------------------------------------------------------------
(
	cat <<EOF
# This is the config file used by SURPI, starting with v22_2. It contains mandatory parameters, 
# optional parameters, and server related constants.


##########################
#  Mandatory parameters  
##########################


#FASTQ input file
inputfile="$create_config_file"

#FASTQ quality type. Must be Sanger or Illumina
quality="Sanger"

#length_cutoff
length_cutoff="50"

#Adapter set used. Must be Truseq, Nextera, or NexSolB
adapter_set="Truseq"

#RAPSearch database method to use. Must be Viral or NR
rapsearch_database="Viral"

#SNAP edit distance
d_human=12

#RAPSearch e_cutoffs
ecutoff_Vir="1"
ecutoff_NR="0"

##########################
# Optional Parameters
##########################

#Run mode to use. Must be Comprehensive or Fast.
run_mode="Comprehensive"

#Number of cores to use. Will use all cores on machine if unspecified.
#Uncomment the parameter to set explicitly.
#cores=64

#Cropping values. Where to start crop, and how long to crop.
start_nt=10
crop_length=75

abysskmer=34

#Verify FASTQ quality  (0 = skip validation / 1 [default]= run validation, dont check uniq names, quit on failure / 2 = run validation, check uniq names, quit on failure / 3= run validatoin check uniq names, do not quit on failure )
VERIFY_FASTQ=1

##########################
# Server related values
##########################

# directory containing SNAP databases (for subtraction phase)
SNAP_directory="/reference/reference"

# directory for SNAP databases (for mapping phase/comprehensive mode)
SURPI_db_directory_COMP="/reference/reference/COMP_SNAP"

# directory for SNAP databases (for mapping phase/FAST mode)
SURPI_db_directory_FAST="/reference/reference/FAST_SNAP"

#prefix of SNAP nt database
snapNTdb="snap_index_"

#RAPSearch database location
RAPSearch_db_directory="/reference/reference/RAPSearch"

#RAPSearch viral database
RAPSearchDB_Vir="rapsearch_viral_aa_130628_db_v2.12"

#RAPSearch nr database
RAPSearchDB_NR="rapsearch_nr_130624_db_v2.12"

#RAPSearch executable path 
rapsearch="rapsearch"
EOF
) > $configprefix.config
#------------------------------------------------------------------------------------------------
echo "$configprefix.config generated. Please edit it to contain the proper parameters for your analysis."
echo "go_$configprefix generated. Initiate the pipeline by running this program. (./go_$configprefix)"
echo
exit
fi

#Check if config file is specified, and grab parameters from it
if [[ $config_file ]]
then # use config file
	if [[ -r $config_file ]]
	then
		source "$config_file"
	else
		echo "The config file specified: $config_file is not present."
		exit 65
	fi
else # parameters must be specified
	if [ ! -r $inputfile ]
	then
		echo "The inputfile specified: $inputfile is not present."
		exit 65
	fi
fi

#set cores. if none specified, use all cores present on machine
if [ ! $cores ]
then
	total_cores=$(grep processor /proc/cpuinfo | wc -l)
	cores=${cores:-$total_cores}
fi

if [ ! $run_mode ]
then
	run_mode="Comprehensive"
fi

if [ "$run_mode" != "Comprehensive" -a "$run_mode" != "Fast" ]
then
	echo "${bold}$run_mode${normal} is not a valid run mode - must be Comprehensive or Fast."
	echo "Please specify a valid run mode using the -u switch."
	exit 65
fi

#set cache_reset. if none specified:
# >500GB -> 200GB
# >200GB -> 150GB
# otherwise -> 50GB
# note: this may cause problems on a machine with <50GB RAM
if [ ! $cache_reset ]
then
	total_ram=$(grep MemTotal /proc/meminfo | awk '{print $2}')
	if [ "$total_ram" -gt "500000000" ] #500GiB
	then
		cache_reset=200 # This is 200GB
	elif [ "$total_ram" -gt "200000000" ] #200 GiB
	then
		cache_reset=150
	else
		cache_reset=50
	fi
fi

#these 2 parameters are for cropping prior to snap in the preprocessing stage
if [ ! $start_nt ]
then
	start_nt=10
fi

if [ ! $crop_length ]
then
	crop_length=75
fi

if [ "$adapter_set" != "Truseq" -a "$adapter_set" != "Nextera" -a "$adapter_set" != "NexSolB" ]
then
	echo "${bold}$adapter_set${normal} is not a valid adapter_set - must be Truseq, Nextera, or NexSolB."
	echo "Please specify a valid adapter set using the -a switch."
	exit 65
fi

if [ "$quality" != "Sanger" -a "$quality" != "Illumina" ]
then
	echo "${bold}$quality${normal} is not a valid quality - must be Sanger or Illumina."
	echo "Please specify a valid quality using the -q switch."
	exit 65
fi
if [ $quality = "Sanger" ]
then
	quality="S"
else
	quality="I"
fi

#RAPSearch e_cutoffs
if [ ! $ecutoff_Vir ]
then
	ecutoff_Vir="1"
fi

if [ ! $ecutoff_NR ]
then
	ecutoff_NR="0"
fi

if [ ! $d_human ]
then
	d_human=12
fi

if [ ! $length_cutoff ]
then
	echo "${bold}length_cutoff${normal} was not specified."
	echo "Please specify a valid length_cutoff using the -x switch."
	exit 65
fi

if [ "$rapsearch_database" != "Viral" -a "$rapsearch_database" != "NR" ]
then
	echo "${bold}$rapsearch_database${normal} is not a valid RAPSearch database - must be Viral or NR."
	echo "Please specify a valid rapsearch_database using the -r switch, or place one of the above options in your config file."
	exit 65
fi

if [ ! $abysskmer ]
then
	abysskmer=34
fi

nopathf=${inputfile##*/} # remove the path to file
basef=${nopathf%.fastq}

if [ "$VERIFY_FASTQ" = 1 ]
then
	fastQValidator --file $inputfile --printBaseComp --avgQual --disableSeqIDCheck > quality.$basef.log
	if [ $? -eq 0 ]
	then
		echo "$inputfile appears to be a valid FASTQ file. Check the quality.$basef.log file for details."
	else
		echo "$inputfile appears to be a invalid FASTQ file. Check the quality.$basef.log file for details."
		echo "You can bypass the quality check by not using the -v switch."
		exit 65
	fi
elif [ "$VERIFY_FASTQ" = 2 ]
then
	fastQValidator --file $inputfile --printBaseComp --avgQual > quality.$basef.log
	if [ $? -eq 0 ]
	then
		echo "$inputfile appears to be a valid FASTQ file. Check the $basef.quality file for details."
	else
		echo "$inputfile appears to be a invalid FASTQ file. Check the $basef.quality file for details."
		echo "You can bypass the quality check by not using the -v switch."
		exit 65
	fi
elif [ "$VERIFY_FASTQ" = 3 ]
then
	fastQValidator --file $inputfile --printBaseComp --avgQual > quality.$basef.log
fi

let "length = $(head -n 2 $inputfile | sed '/@/d' | awk 'BEGIN{FS=""}{for(i=1;i<=NF;i++)c++}END{print c}')"
contigcutoff=$(perl -le "print int(1.75 * $length)")
echo "-----------------------------------------------------------------------------------------"
echo "INPUT PARAMETERS"
echo "-----------------------------------------------------------------------------------------"
echo "Command Line Usage: $scriptname $@"
echo "config_file: $config_file"
echo "Server: $host"
echo "run_mode: $run_mode"
echo "inputfile: $inputfile"
echo "cores used: $cores"
echo "Raw Read quality: $quality"
echo "Read length_cutoff for preprocessing under which reads are thrown away: $length_cutoff"
echo "SURPI_db_directory housing the reference databases for Comprehensive Mode: $SURPI_db_directory_COMP"
echo "SURPI_db_directory housing the reference databases for Fast Mode: $SURPI_db_directory_FAST"

echo "SNAP human indexed database SNAP_directory: $SNAP_directory"
echo "Version of SNAP indexed NT database from snap_nt.sh: $snapNTdb"
echo "SNAP edit distance for SNAP to Human and SNAP to NT d_human: $d_human"

echo "RAPSearch directory used: $RAPSearch_db_directory"
echo "RAPSearch indexed viral db used: $RAPSearchDB_Vir"
echo "RAPSearch indexed NR db used: $RAPSearchDB_NR"
echo "RAPSearch program version used: $rapsearch"
echo "rapsearch_database: $rapsearch_database"

echo "adapter_set: $adapter_set"

echo "Raw Read length: $length"
echo "contigcutoff for abyss assembly unitigs: $contigcutoff"
echo "abysskmer length: $abysskmer"

echo "cache_reset: $cache_reset"
echo "start_nt: $start_nt"
echo "crop_length: $crop_length"
echo "-----------------------------------------------------------------------------------------"

curdate=$(date)
tweet.pl "Starting SURPI Pipeline on $host: $inputfile ($curdate) ($scriptname)"

###########################################################
echo "#################### STARTING SURPI PIPELINE ##################"
START0=$(date +%s)
echo "Found file $inputfile"
echo "After removing path: $nopathf"
############ PREPROCESSING ##################
if [ "$preprocess" != "skip" ]
then
	echo "############ PREPROCESSING ##################"
	echo -n "Starting: preprocessing using $cores cores "
	date
	START2=$(date +%s)
	echo "Parameters: preprocess_ncores.sh $basef.fastq $quality N $length_cutoff $cores Y N $adapter_set $start_nt $crop_length>& $basef.preprocess.log"
	preprocess_ncores.sh $basef.fastq $quality N $length_cutoff $cores Y N $adapter_set $start_nt $crop_length>& $basef.preprocess.log
	echo -n "Done: preprocessing "
	date
	END2=$(date +%s)
	diff=$(( END2 - START2 ))
	echo "$inputfile Preprocessing Took $diff seconds"
	echo "$inputfile Preprocessing Took $diff seconds" > timing.$basef.log
fi
############# BEGIN SNAP PIPELINE #################
freemem=$(free -g | awk '{print $4}' | head -n 2 | tail -1 | more)
echo "There is $freemem GB available free memory...[cutoff=$cache_reset GB]"
if [ "$freemem" -lt "$cache_reset" ]
then
	echo "Clearing cache..."
	dropcache
fi
############# HUMAN MAPPING #################
if [ "$human_mapping" != "skip" ]
then
	echo "############# SNAP TO HUMAN  #################"
	for d_human in $d_human; do
		basef_h=${nopathf%.fastq}.preprocessed.s20.h250n25d${d_human}xfu # remove fastq extension
		echo "Base file: $basef_h"
		echo -n "Starting: $basef_h human mapping"
		date
		START6=$(date +%s)
		echo "Parameters: snap single ${SNAP_directory}/snap_index_hg19_rRNA_mito_Hsapiens_rna $basef.preprocessed.fastq -o $basef_h.human.snap.unmatched.sam -t $cores -x -f -h 250 -d ${d_human} -n 25 -F u"
		snap single ${SNAP_directory}/snap_index_hg19_rRNA_mito_Hsapiens_rna $basef.preprocessed.fastq -o $basef_h.human.snap.unmatched.sam -t $cores -x -f -h 250 -d ${d_human} -n 25 -F u     
		echo -n "Done: SNAP to human"
		date
		END6=$(date +%s)
		diff=$(( END6 - START6 ))
		echo "$basef.preprocessed.fastq Human mapping Took $diff seconds"
		echo "$basef.preprocessed.fastq Human mapping Took $diff seconds" >> timing.$basef.log
		egrep -v "^@" $basef_h.human.snap.unmatched.sam | awk '{if($3 == "*") print "@"$1"\n"$10"\n""+"$1"\n"$11}' > $(echo "$basef_h".human.snap.unmatched.sam | sed 's/\(.*\)\..*/\1/').fastq
	done
fi
######dropcache?#############
freemem=$(free -g | awk '{print $4}' | head -n 2 | tail -1 | more)
echo "There is $freemem GB available free memory...[cutoff=$cache_reset GB]"
if [ "$freemem" -lt "$cache_reset" ]
then
	echo "Clearing cache..."
	dropcache
fi
############################# SNAP TO NT ##############################       
if [ "$alignment" != "skip" ]
then
	if [ ! -f $basef.NT.snap.sam ];
	then
		echo "############# SNAP UNMATCHED SEQUENCES TO NT #################"
		echo -n "Calculating number of sequences to analyze using SNAP to NT..."
		date
		echo $(awk 'NR%4==1' "$basef_h".human.snap.unmatched.fastq | wc -l)
		echo -n "Starting: Mapping  by SNAP to NT from $basef_h.human.snap.unmatched.fastq"
		date
		START11=$(date +%s)
		# SNAP to NT for unmatched reads (d value threshold cutoff = 12)

		if [ $run_mode = "Comprehensive" ]
		then
			echo "Parameters: snap_nt.sh $basef_h.human.snap.unmatched.fastq ${SURPI_db_directory_COMP} $cores $cache_reset $d_human $snapNTdb"
			snap_nt.sh $basef_h.human.snap.unmatched.fastq ${SURPI_db_directory_COMP} $cores $cache_reset $d_human $snapNTdb
		elif [ $run_mode = "Fast" ]
		then
			echo "Parameters: snap_nt.sh $basef_h.human.snap.unmatched.fastq ${SURPI_db_directory_FAST} $cores $cache_reset $d_human $snapNTdb"
			snap_nt.sh $basef_h.human.snap.unmatched.fastq ${SURPI_db_directory_FAST} $cores $cache_reset $d_human $snapNTdb
		fi
		
		echo -n "Done:  SNAP to NT"
		date
		END11=$(date +%s)
		diff=$(( END11 - START11 ))
		echo "$basef_h.human.snap.unmatched.fastq SNAP to NT all dbs Took $diff seconds"
		echo "$basef_h.human.snap.unmatched.fastq SNAP to NT all dbs Took $diff seconds" >> timing.$basef.log
		mv -f $basef_h.human.snap.unmatched.NT.sam $basef.NT.snap.sam #SAMIA# changed from cp to mv, is that okay?
	fi
	echo -n "Starting: parsing $basef.NT.snap.sam "
	date
	echo -n "extract matched/unmatched $basef.NT.snap.sam"
	date
	egrep -v "^@" $basef.NT.snap.sam | awk '{if($3 != "*") print }' > $basef.NT.snap.matched.sam
	egrep -v "^@" $basef.NT.snap.sam | awk '{if($3 == "*") print }' > $basef.NT.snap.unmatched.sam
	echo -n "convert sam to fastq from $basef.NT.snap.sam "
	date
	#convertSam2Fastq.sh $basef.NT.snap.sam #SAMIA# use actual converter
	egrep -v "^@" "$basef.NT.snap.unmatched.sam" | awk '{if($3 == "*") print "@"$1"\n"$10"\n""+"$1"\n"$11}' > $(echo "$basef.NT.snap.unmatched.sam" | sed 's/\(.*\)\..*/\1/').fastq
	egrep -v "^@" "$basef.NT.snap.matched.sam" | awk '{if($3 != "*") print "@"$1"\n"$10"\n""+"$1"\n"$11}' > $(echo "$basef.NT.snap.matched.sam" | sed 's/\(.*\)\..*/\1/').fastq
	echo -n "Done: parsing $basef.NT.snap.unmatched.sam  "
	date
	if [ ! -f "$basef.NT.snap.matched.all.annotated" ];
	then
		## convert to FASTQ and retrieve full-length sequences
		echo -n "convert to FASTQ and retrieve full-length sequences for SNAP NT matched hits "
		date
		extractHeaderFromFastq.csh "$basef.NT.snap.matched.fastq" FASTQ "$basef.cutadapt.fastq" "$basef.NT.snap.matched.fulllength.fastq"
		sort -k1,1 "$basef.NT.snap.matched.sam"  > "$basef.NT.snap.matched.sorted.sam"
		cut -f1-9 "$basef.NT.snap.matched.sorted.sam" > "$basef.NT.snap.matched.sorted.sam.tmp1"
		cut -f11- "$basef.NT.snap.matched.sorted.sam" > "$basef.NT.snap.matched.sorted.sam.tmp2"
		awk '(NR%4==1) {printf("%s\t",$0)} (NR%4==2) {printf("%s\n", $0)}' "$basef.NT.snap.matched.fulllength.fastq" | sort -k1,1 | awk '{print $2}' > "$basef.NT.snap.matched.fulllength.sequence.txt"
		paste "$basef.NT.snap.matched.sorted.sam.tmp1" "$basef.NT.snap.matched.fulllength.sequence.txt" "$basef.NT.snap.matched.sorted.sam.tmp2" > "$basef.NT.snap.matched.fulllength.sam"
		###retrieve taxonomy matched to NT ###
		echo -n "taxonomy retrieval for $basef.NT.snap.matched.fulllength.sam"
		date
		taxonomy_sqlite.pl "$basef.NT.snap.matched.fulllength.sam" sam nucl >& "$basef.taxonomy.SNAPNT.log"
		sed 's/NM:i:\([0-9]\)/0\1/g' "$basef.NT.snap.matched.fulllength.all.annotated" | sort -k 14,14 > "$basef.NT.snap.matched.fulllength.all.annotated.sorted"
		rm -f  "$basef.NT.snap.matched.fulllength.gi" "$basef.NT.snap.matched.fullength.gi.taxonomy"
	fi
# adjust filenames for FAST mode
	grep "Viruses;" "$basef.NT.snap.matched.fulllength.all.annotated.sorted" > "$basef.NT.snap.matched.fl.Viruses.annotated"
	grep "Bacteria;" "$basef.NT.snap.matched.fulllength.all.annotated.sorted" > "$basef.NT.snap.matched.fl.Bacteria.annotated"
	
	if [ $run_mode = "Comprehensive" ]
	then
		grep "Primates;" "$basef.NT.snap.matched.fulllength.all.annotated.sorted" > "$basef.NT.snap.matched.fl.Primates.annotated"
		grep -v "Primates" "$basef.NT.snap.matched.fulllength.all.annotated.sorted" | grep "Mammalia" > "$basef.NT.snap.matched.fl.nonPrimMammal.annotated"
		grep -v "Mammalia" "$basef.NT.snap.matched.fulllength.all.annotated.sorted" | grep "Chordata" > "$basef.NT.snap.matched.fl.nonMammalChordat.annotated"
		grep -v "Chordata" "$basef.NT.snap.matched.fulllength.all.annotated.sorted" | grep "Eukaryota" > "$basef.NT.snap.matched.fl.nonChordatEuk.annotated"
	
		fi
	echo "Done taxonomy retrieval"
	#Table generation
	table_generator.sh "$basef.NT.snap.matched.fl.Viruses.annotated" SNAP Y Y Y Y>& "$basef.table_generator_snap.matched.fl.log"
	if [ $run_mode = "Comprehensive" ]
	then
		### convert to FASTQ and retrieve full-length sequences to add to unmatched SNAP for viral RAPSearch###
		egrep -v "^@" "$basef.NT.snap.matched.fl.Viruses.annotated" | awk '{if($3 != "*") print "@"$1"\n"$10"\n""+"$1"\n"$11}' > $(echo "$basef.NT.snap.matched.fl.Viruses.annotated" | sed 's/\(.*\)\..*/\1/').fastq
		echo -n "Done: convert to FASTQ and retrieve full-length sequences for SNAP NT hits "
	fi
	date
	echo "############# SORTING unmatched to NT BY LENGTH AND UNIQ AND LOOKUP ORIGINAL SEQUENCES  #################"
	if [ $run_mode = "Comprehensive" ]
	then
		extractHeaderFromFastq.csh "$basef.NT.snap.unmatched.fastq" FASTQ "$basef.cutadapt.fastq" "$basef.NT.snap.unmatched.fulllength.fastq"
		sed "n;n;n;d" "$basef.NT.snap.unmatched.fulllength.fastq" | sed "n;n;d" | sed "s/^@/>/g" > "$basef.NT.snap.unmatched.fulllength.fasta"
	fi
	cat "$basef.NT.snap.unmatched.fulllength.fasta" | perl -e 'while (<>) {$h=$_; $s=<>; $seqs{$h}=$s;} foreach $header (reverse sort {length($seqs{$a}) <=> length($seqs{$b})} keys %seqs) {print $header.$seqs{$header}}' > $basef.NT.snap.unmatched.fulllength.sorted.fasta
	if [ $run_mode = "Comprehensive" ]
	then
		echo "we will be using 50 as the length of the cropped read for removing unique and low-complexity reads"
		crop_reads.csh "$basef.NT.snap.unmatched.fulllength.sorted.fasta" 25 50 > "$basef.NT.snap.unmatched.fulllength.sorted.cropped.fasta"
		echo "*** reads cropped ***"
		gt sequniq -seqit -force -o "$basef.NT.snap.unmatched.fulllength.sorted.cropped.uniq.fasta" "$basef.NT.snap.unmatched.fulllength.sorted.cropped.fasta"
		extractHeaderFromFastq.csh "$basef.NT.snap.unmatched.fulllength.sorted.cropped.uniq.fasta" FASTA "$basef.cutadapt.fastq" "$basef.NT.snap.unmatched.uniq.fl.fastq"
		sed "n;n;n;d" "$basef.NT.snap.unmatched.uniq.fl.fastq" | sed "n;n;d" | sed "s/^@/>/g" > "$basef.NT.snap.unmatched.uniq.fl.fasta"
	fi
	echo " Done uniquing full length sequences of unmatched to NT "
fi
curdate=$(date)
tweet.pl "Finished SNAP mapping on $host: $inputfile ($curdate) ($scriptname)"

####################### DENOVO CONTIG ASSEMBLY #####
if [ $run_mode = "Comprehensive" ]
then
	echo "############# Running ABYSS and Minimus #################"
	echo -n "Starting assembly process "
	date
	START40=$(date +%s)
	echo " adding matched viruses to NT unmatched" 
	sed "n;n;n;d" "$basef.NT.snap.matched.fl.Viruses.fastq" | sed "n;n;d" | sed "s/^@/>/g" | sed 's/>/>Vir/g' > "$basef.NT.snap.matched.fl.Viruses.fasta"
	gt sequniq -seqit -force -o "$basef.NT.snap.matched.fl.Viruses.uniq.fasta" "$basef.NT.snap.matched.fl.Viruses.fasta"
	cat "$basef.NT.snap.unmatched.uniq.fl.fasta" "$basef.NT.snap.matched.fl.Viruses.uniq.fasta" > "$basef.NT.snap.unmatched_addVir_uniq.fasta"
	echo "starting deNovo assembly"
	abyss_minimus.sh "$basef.NT.snap.unmatched_addVir_uniq.fasta" "$length" "$contigcutoff" "$cores" "$abysskmer"
	echo -n "Completed deNovo assembly: generated all.$basef.NT.snap.unmatched_addVir_uniq.fasta.unitigs.cut${length}.${contigcutoff}-mini.fa"
	date
	END40=$(date +%s)
	diff=$(( END40 - START40 ))
fi
#######RAPSEARCH#####
#################### RAPSearch to Vir ###########
if [ $run_mode = "Comprehensive" ]
then
	if [ "$rapsearch_database" == "Viral" ]
	then
		if [ -f "$basef.NT.snap.unmatched.uniq.fl.fasta" ]
		then
			echo "############# RAPSEARCH to ${RAPSearchDB_Vir} ON NT-UNMATCHED SEQUENCES #################"
			dropcache
			echo -n "Starting: RAPSearch $basef.NT.snap.unmatched.uniq.fl.fasta "
			date
			START14=$(date +%s)
			echo "$rapsearch -q $basef.NT.snap.unmatched.uniq.fl.fasta -d ${RAPSearch_db_directory}/${RAPSearchDB_Vir} -o $basef.$rapsearch_database.RAPsearch.e1 -z $cores -e $ecutoff_Vir -v 1 -b 1 -t N >& $basef.$rapsearch_database.RAPSearch.log"
			"$rapsearch" -q "$basef.NT.snap.unmatched.uniq.fl.fasta" -d ${RAPSearch_db_directory}/${RAPSearchDB_Vir} -o $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir} -z "$cores" -e "$ecutoff_Vir" -v 1 -b 1 -t N >& $basef.$rapsearch_database.RAPSearch.log
			echo -n "Done RAPSearch: "
			date
			END14=$(date +%s)
			diff=$(( END14 - START14 ))
			echo "RAPSearch to Vir Took $diff seconds"
			echo -n "Starting: add FASTA sequences to RAPsearch m8 output file "
			date
			START15=$(date +%s)
			sed -i '/^#/d' $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.m8
			seqtk subseq $basef.NT.snap.unmatched.uniq.fl.fasta $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.m8 > $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.m8.fasta

			sed '/>/d' $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.m8.fasta >  $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.m8.fasta.seq
			paste $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.m8 $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.m8.fasta.seq > $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.addseq.m8
			taxonomy_sqlite.pl $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.addseq.m8 blast prot 
			mv $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.addseq.all.annotated $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.annotated
	
			table_generator.sh $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.annotated RAP Y Y Y Y
			echo -n "Done: converting RAPsearch Vir output to fasta "
			date
			END15=$(date +%s)
			diff=$(( END15 - START15 ))
			echo "converting RAPsearch Vir output to fasta sequences Took $diff seconds"
			echo "converting RAPsearch Vir output to fasta sequences Took $diff seconds" >> timing.$basef.log
			cat "$basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.m8.fasta" "all.$basef.NT.snap.unmatched_addVir_uniq.fasta.unitigs.cut${length}.${contigcutoff}-mini.fa" > "$basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.m8.fasta"
		else
			echo "Cannot run viral RAPSearch - necessary input file ($basef.$rapsearch_database.RAPsearch.e$ecutoff_Vir.m8) does not exist"
			echo "concatenating RAPSearchvirus output and Contigs"
		fi
		echo "############# Cleanup RAPSearch Vir by RAPSearch to NR #################"
		if [ -f $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.m8.fasta ]
		then
			echo -n "Starting: RAPSearch to $RAPSearchDB_NR of $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.m8.fasta :"
			date
			START16=$(date +%s)
			"$rapsearch" -q $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.m8.fasta -d ${RAPSearch_db_directory}/${RAPSearchDB_NR} -o $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.NR.e${ecutoff_NR} -z $cores -e $ecutoff_NR -v 1 -b 1 -t N -a T
			echo "rapsearch to nr done"
			sed -i '/^#/d' $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.m8
			echo "removed extra #"
			END16=$(date +%s)
			diff=$(( END16 - START16 ))
			echo "$basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.NR.e${ecutoff_NR} RAPSearch to NR Took $diff seconds"
			echo "$basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.NR.e${ecutoff_NR} RAPSearch to NR Took $diff seconds" >> timing.$basef.log
			echo -n "Starting: Seq retrieval and Taxonomy $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}  :"
			date
			START17=$(date +%s)
			seqtk subseq $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.m8.fasta $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.m8  > $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.m8.fasta
			echo " $(date) retrieved sequences"
			cat $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.m8.fasta | awk '{if (substr($0,1,1)==">"){if (p){print "\n";} print $0} else printf("%s",$0);p++;}END{print "\n"}' | sed '/^$/d' | sed '/>/d' > $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.m8.fasta.seq
			paste $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e$ecutoff_Vir.NR.e${ecutoff_NR}.m8 $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.m8.fasta.seq > $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.addseq.m8
			echo "made addseq file $(date)"
			echo "############# RAPSearch Taxonomy $(date)"
			taxonomy_sqlite.pl $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.addseq.m8 blast prot 
			cp $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.addseq.all.annotated $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.annotated
			echo "retrieved taxonomy"
			grep "Viruses" $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.annotated > $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.Viruses.annotated
			egrep "^contig" $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.annotated > $basef.Contigs.NR.RAPSearch.e${ecutoff_NR}.annotated
			echo "extracted RAPSearch taxonomy $(date) "
			echo "Starting Readcount table $(date)"
			table_generator.sh $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.Viruses.annotated RAP Y Y Y Y
			table_generator.sh $basef.Contigs.NR.RAPSearch.e${ecutoff_NR}.annotated RAP Y Y Y Y
			#allow contigs to be incorporated into coverage maps by making contig barcodes the same as non-contig barcodes (removing the @)
			sed 's/@//g' $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.Viruses.annotated > $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.Viruses.annotated.bar.inc
			echo "making coverage maps"
			coverage_generator_bp.sh $basef.NT.snap.matched.fl.Viruses.annotated SNAP N N Y N $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.Viruses.annotated.bar.inc 1e-20 1 10 1

			awk '{print$1}'  $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.annotated > $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.annotated.header
 			awk '{print$1}' $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.annotated > $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.annotated.header
			# find headers in viral rapsearch that are no longer found in rapsearch to nr 
			sort $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.annotated.header $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.annotated.header | uniq -d | sort $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.annotated.header - | uniq -u > $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.annotated.not.in.NR.header
			rm -r $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.annotated.header $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.annotated
			split -l 400 -a 6 $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.annotated.not.in.NR.header $basef.not.in.NR.
			for f in $basef.not.in.NR.[a-z][a-z][a-z][a-z][a-z][a-z]
			do grep  -f "$f" $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.annotated > $f.annotated
			done
			cat $basef.not.in.NR.[a-z][a-z][a-z][a-z][a-z][a-z].annotated > $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.annotated.not.in.NR.annotated
			rm -r $basef.not.in.NR.[a-z][a-z][a-z][a-z][a-z][a-z]
			rm -r $basef.not.in.NR.[a-z][a-z][a-z][a-z][a-z][a-z].annotated
			table_generator.sh $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.annotated.not.in.NR.annotated RAP N Y N N
			
		
			END17=$(date +%s)
			diff=$(( END17 - START17 ))
			echo "RAPSearch seq retrieval, taxonomy and readcount Took $diff seconds"
			echo "RAPSearch seq retrieval, taxonomy and readcount Took $diff seconds" >> timing.$basef.log
		else
			echo "Cannot run RAPSearch to NR - necessary input file ($basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.m8.fasta) does not exist"
		fi
	fi
	##################RAPSearch to NR #######
	if [ "$rapsearch_database" == "NR" ]
	then
		echo "#################### RAPSearch to NR ###########"
		cat "$basef.NT.snap.unmatched.uniq.fl.fasta" "all.$basef.NT.snap.unmatched_addVir_uniq.fasta.unitigs.cut${length}.${contigcutoff}-mini.fa" > "$basef.Contigs.NT.snap.unmatched.uniq.fl.fasta"
		if [ -f $basef.Contigs.NT.snap.unmatched.uniq.fl.fasta ]
		then
			echo "############# RAPSEARCH to NR #################"
			echo -n "Starting: RAPSearch to NR $basef.Contigs.NT.snap.unmatched.uniq.fl.fasta"
			date
			START16=$(date +%s)
			$rapsearch -q $basef.Contigs.NT.snap.unmatched.uniq.fl.fasta -d ${RAPSearch_db_directory}/${RAPSearchDB_NR} -o $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_NR}  -z $cores -e $ecutoff_NR -v 1 -b 1 -t N -a T
			echo "rapsearch  to nr done"
			sed -i '/^#/d' $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_NR}.m8
			echo "removed extra #"
			END16=$(date +%s)
			diff=$(( END16 - START16 ))
			echo "$basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_NR} RAPSearch to NR Took $diff seconds"
			echo "$basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_NR} RAPSearch to NR Took $diff seconds" >> timing.$basef.log
			echo -n "Starting: Seq retrieval and Taxonomy $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_NR}"
			date
			START17=$(date +%s)
			seqtk subseq $basef.Contigs.NT.snap.unmatched.uniq.fl.fasta $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_NR}.m8 > $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_NR}.m8.fasta
			echo " $(date) retrieved sequences"
			sed '/>/d' $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_NR}.m8.fasta > $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_NR}.m8.fasta.seq
			paste $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_NR}.m8 $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_NR}.m8.fasta.seq > $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_NR}.addseq.m8
			echo "made addseq file $(date)"
			echo "############# RAPSearch Taxonomy $(date)"
			taxonomy_sqlite.pl $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_NR}.addseq.m8 blast prot
			cp $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_NR}.addseq.all.annotated $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_NR}.annotated
			echo "retrieved taxonomy"
			grep "Viruses" $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_NR}.annotated > $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_NR}.Viruses.annotated
			egrep "^contig" $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_NR}.annotated > $basef.Contigs.$rapsearch_database.RAPsearch.e${ecutoff_NR}.annotated 
			echo "extracted RAPSearch taxonomy $(date) "
			echo "Starting Readcount table $(date)"
			table_generator.sh $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_NR}.Viruses.annotated RAP Y Y Y Y
			grep -v Viruses $basef.Contigs.$rapsearch_database.RAPsearch.e${ecutoff_NR}.annotated > $basef.Contigs.$rapsearch_database.RAPsearch.e${ecutoff_NR}.noVir.annotated
			table_generator.sh $basef.Contigs.$rapsearch_database.RAPsearch.e${ecutoff_NR}.noVir.annotated RAP N Y N N
			sed 's/@//g' $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_NR}.Viruses.annotated > $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_NR}.Viruses.annotated.bar.inc
			echo "making coverage maps"
			coverage_generator_bp.sh $basef.NT.snap.matched.fl.Viruses.annotated SNAP N N Y N $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_NR}.Viruses.annotated.bar.inc 1e-20 1 10 1
			END17=$(date +%s)
			diff=$(( END17 - START17 ))
			echo "RAPSearch seq retrieval, taxonomy and table readcount and coverage Took $diff seconds"
			echo "RAPSearch seq retrieval, taxonomy and table readcount and coverage Took $diff seconds" >> timing.$basef.log
		else
			echo "Cannot run RAPSearch to NR - necessary input file ($basef.Contigs.NT.snap.unmatched.uniq.fl.fasta) does not exist"
		fi
	fi
	dropcache
fi

############################# OUTPUT FINAL COUNTS ##############################       
echo -n " Starting: generating readcounts.$basef.log report"
date
START17=$(date +%s)
# Generate reports for .sorted (frequency of families etc)

echo -n "$inputfile " > readcounts.$basef.temp
egrep -c "@HWI|^@M00|^@SRR" $inputfile >> readcounts.$basef.temp
echo -n "$basef.preprocessed.fastq " >> readcounts.$basef.temp
egrep -c "@HWI|^@M00|^@SRR" $basef.preprocessed.fastq >> readcounts.$basef.temp
echo -n "$basef_h.human.snap.unmatched.sam " >> readcounts.$basef.temp
egrep -c "HWI|^M00|^SRR" $basef_h.human.snap.unmatched.sam >> readcounts.$basef.temp
echo -n "$basef.NT.snap.matched.sam " >> readcounts.$basef.temp
egrep -c "HWI|^M00|^SRR" $basef.NT.snap.matched.sam >> readcounts.$basef.temp
echo -n "$basef.NT.snap.unmatched.sam " >> readcounts.$basef.temp
egrep -c "HWI|^M00|^SRR" $basef.NT.snap.unmatched.sam >> readcounts.$basef.temp
echo -n "$basef.NT.snap.matched.fl.Viruses.annotated " >> readcounts.$basef.temp
egrep -c "HWI|^M00|^SRR" $basef.NT.snap.matched.fl.Viruses.annotated >> readcounts.$basef.temp
echo -n "$basef_r.virus.contigs.RAPvir.1e+0nr.Viruses.sorted " >> readcounts.$basef.temp
egrep -c "HWI|^M00|^F1" $basef_r.virus.contigs.RAPvir.1e+0nr.Viruses.sorted >> readcounts.$basef.temp

echo "$inputfile" > barcode_readcounts.$basef.1.temp
egrep "^@HW|^@M0|^@SRR" $inputfile | sed 's/#/ /g' | awk '{print$2}' | sort | uniq -c >> barcode_readcounts.$basef.1.temp
echo "$basef.preprocessed.fastq" > barcode_readcounts.$basef.2.temp
egrep "^@HW|^@M0|^@SRR" $basef.preprocessed.fastq | sed 's/#/ /g' | awk '{print$2}' | sort | uniq -c >> barcode_readcounts.$basef.2.temp
echo "$basef_h.human.snap.unmatched.sam" > barcode_readcounts.$basef.3.temp
sed 's/#/ /g' $basef_h.human.snap.unmatched.sam | awk '{print$2}' | sort | uniq -c | sed '/:/d' >> barcode_readcounts.$basef.3.temp
echo "$basef_h.human.snap.matched.sam" > barcode_readcounts.$basef.4.temp
sed 's/#/ /g'  $basef_h.human.snap.matched.sam| awk '{print$2}' | sort | uniq -c | sed '/:/d' >> barcode_readcounts.$basef.4.temp
echo "$basef_h.human.snap.unmatched.sam" >barcode_readcounts.$basef.5.temp
sed 's/#/ /g' $basef_h.human.snap.unmatched.sam | awk '{print$2}' | sort | uniq -c | sed '/:/d'>> barcode_readcounts.$basef.5.temp
echo "$basef.NT.snap.matched.sam" > barcode_readcounts.$basef.6.temp
sed 's/#/ /g' $basef.NT.snap.matched.sam | awk '{print$2}' | sort | uniq -c | sed '/:/d' >> barcode_readcounts.$basef.6.temp
echo "$basef.NT.snap.unmatched.sam" > barcode_readcounts.$basef.7.temp
sed 's/#/ /g' $basef.NT.snap.unmatched.sam | awk '{print$2}' | sort | uniq -c | sed '/:/d' >> barcode_readcounts.$basef.7.temp
echo "$basef.NT.snap.matched.fl.Viruses.annotated" > barcode_readcounts.$basef.8.temp
sed 's/#/ /g' $basef.NT.snap.matched.fl.Viruses.annotated | awk '{print$2}' | sort | uniq -c | sed '/:/d' >> barcode_readcounts.$basef.8.temp
echo "$basef.Ecutoff1.virus.contigs.RAPSearch.addseq.m8" > barcode_readcounts.$basef.9.temp
sed 's/#/ /g' $basef.Ecutoff1.virus.contigs.RAPSearch.addseq.m8 | awk '{print$2}' | sort | uniq -c | sed '/:/d' >> barcode_readcounts.$basef.9.temp

cat barcode_readcounts.$basef*temp > barcode_readcounts.$basef.log
cat readcounts.$basef.temp barcode_readcounts.$basef.log > readcounts.$basef.log

echo -n " Done: generating readcounts.$basef.log report"
date
END17=$(date +%s)
diff=$(( END17 - START17 ))
echo "Generating read count report Took $diff seconds"
echo "Generating read count report Took $diff seconds" >> timing.$basef.log
	
echo "#################### SURPI PIPELINE COMPLETE ##################"
END0=$(date +%s)
echo -n "Done: "
date
diff=$(( END0 - START0 ))
echo "Total run time of pipeline Took $diff seconds" 
echo "Total run time of pipeline Took $diff seconds" >> timing.$basef.log

echo "Script and Parameters = $0 $@ " > $basef.pipeline_parameters.log
echo " Raw Read quality = $quality" >> $basef.pipeline_parameters.log
echo "Raw Read length = $length" >> $basef.pipeline_parameters.log
echo " Read length_cutoff for preprocessing under which reads are thrown away = $length_cutoff" >> $basef.pipeline_parameters.log
echo "SURPI_db_directory housing all the reference databases = $SURPI_db_directory" >> $basef.pipeline_parameters.log
echo "SNAP edit distance for SNAP to Human and SNAP to NT d_human = $d_human" >> $basef.pipeline_parameters.log
echo " Version of SNAP indexed  NT database from snap_nt.sh = $snapNTdb " >> $basef.pipeline_parameters.log
echo "RAPSearch indexed viral db used = $RAPSearchDB" >> $basef.pipeline_parameters.log
echo "contigcutoff for abyss assembly unitigs = $contigcutoff"  >> $basef.pipeline_parameters.log
echo "abysskmer length = $abysskmer"  >> $basef.pipeline_parameters.log
echo "adapter_set = $adapter_set" >> $basef.pipeline_parameters.log

########CLEANUP############
mkdir LOG_$basef
mkdir OUTPUT_$basef
mkdir TRASH_$basef
mkdir DATASETS_$basef
if [ $run_mode = "Comprehensive" ]
then
	mkdir deNovoASSEMBLY_$basef
	mkdir COVERAGEMAPS_$basef
fi

#mv $basef.pipeline_parameters.log OUTPUT_$basef
mv $basef.@*.k$abysskmer-*.fa DATASETS_$basef
mv $basef.@*.k$abysskmer-unitigs.fa DATASETS_$basef
mv $basef.preprocessed.fastq TRASH_$basef #SNN changed 12/27/2013
mv $basef.cutadapt.fastq DATASETS_$basef
mv $basef.preprocessed.s20.h250n25d12xfu.human.snap.unmatched.sam DATASETS_$basef
mv $basef.NT.snap.sam DATASETS_$basef
mv $basef.NT.snap.matched.fulllength.sam DATASETS_$basef
mv $basef.NT.snap.matched.fulllength.fastq DATASETS_$basef
mv $basef.NT.snap.unmatched.fulllength.fastq DATASETS_$basef
mv $basef.NT.snap.unmatched.uniq.fl.fastq DATASETS_$basef
mv "$basef.@*.k$abysskmer-unitigs.cutoff$contigcutoff.fa" "DATASETS_$basef"
mv "$basef.NT.snap.unmatched_addVir_uniq.fasta.k$abysskmer-unitigs.cutoff$contigcutoff.all.fa" "OUTPUT_$basef"
mv $basef.NT.snap.unmatched.fulllength.fasta DATASETS_$basef
mv $basef.NT.snap.matched.fl.Viruses.uniq.fasta DATASETS_$basef
mv $basef.NT.snap.unmatched_addVir_uniq.fasta DATASETS_$basef
mv $basef.NT.snap.unmatched.uniq.contigs.fasta DATASETS_$basef
mv $basef.Ecutoff1.virus.contigs.RAPSearch.m8 DATASETS_$basef
mv $basef.Ecutoff1.virus.contigs.RAPSearch.addseq.m8 DATASETS_$basef
mv $basef.Ecutoff1.virus.contigs.RAPSearch.aln DATASETS_$basef
mv $basef.@*k$abysskmer-bubbles.fa LOG_$basef
mv $basef.@*k$abysskmer*.adj LOG_$basef
mv $basef.@*k$abysskmer*.path LOG_$basef
mv $basef.@*k$abysskmer-indel.fa LOG_$basef
mv abyss.@*$basef.log LOG_$basef
mv $basef.@*.k$abysskmer-*.dot LOG_$basef
mv coverage.hist LOG_$basef
mv $basef.cutadapt.summary.log LOG_$basef
mv $basef.adapterinfo.log LOG_$basef
mv $basef.cutadapt.cropped.fastq.log LOG_$basef
mv $basef.preprocess.log LOG_$basef
mv $basef.preprocessed.s20.h250n25d12xfu.human.snap.unmatched.time.log LOG_$basef
mv $basef.preprocessed.s20.h250n25d12xfu.human.snap.unmatched.snap.log LOG_$basef
mv $basef.preprocessed.s20.h250n25d12xfu.human.snap.unmatched.timeNT.log LOG_$basef
mv $basef.preprocessed.s20.h250n25d12xfu.human.snap.unmatched.snapNT.log LOG_$basef
mv $basef.taxonomy.SNAPNT.log LOG_$basef
mv $basef.Ecutoff1.virus.RAPSearch.log LOG_$basef
mv $basef.taxonomy.contigs.RAPSearch.log LOG_$basef
#mv $basef*log LOG_$basef
mv $basef.NT.snap.matched.fulllength.all.annotated.sorted OUTPUT_$basef
mv $basef.NT.snap.matched.fl.Viruses.annotated OUTPUT_$basef
mv $basef.NT.snap.matched.fl.Bacteria.annotated OUTPUT_$basef
mv $basef.NT.snap.matched.fl.Primates.annotated OUTPUT_$basef
mv $basef.NT.snap.matched.fl.nonPrimMammal.annotated OUTPUT_$basef
mv $basef.NT.snap.matched.fl.nonMammalChordat.annotated OUTPUT_$basef
mv $basef.NT.snap.matched.fl.nonChordatEuk.annotated OUTPUT_$basef
mv $basef.Ecutoff1.virus.contigs.RAPSearch.annotated*.sorted OUTPUT_$basef
mv readcounts.$basef.log OUTPUT_$basef
mv timing.$basef.log OUTPUT_$basef
mv $basef*table OUTPUT_$basef
mv $basef.cutadapt.cropped.dusted.bad.fastq TRASH_$basef
mv temp.sam TRASH_$basef
mv $basef.NT.snap.matched.sam TRASH_$basef
mv $basef.NT.snap.unmatched.sam TRASH_$basef
mv $basef.preprocessed.s20.h250n25d12xfu.human.snap.unmatched.fastq TRASH_$basef
mv $basef.NT.snap.matched.sorted.sam TRASH_$basef
mv $basef.NT.snap.matched.sorted.sam.tmp2 TRASH_$basef
mv $basef.NT.snap.unmatched.fastq TRASH_$basef
mv $basef.NT.snap.matched.fastq TRASH_$basef
mv $basef.NT.snap.matched.sorted.sam.tmp1 TRASH_$basef
mv $basef.NT.snap.matched.fulllength.sequence.txt TRASH_$basef
mv $basef.NT.snap.matched.fulllength.gi.taxonomy TRASH_$basef
mv $basef.NT.snap.matched.fulllength.all.annotated TRASH_$basef
mv $basef.NT.snap.matched.fl.Viruses.fastq TRASH_$basef
mv $basef.NT.snap.unmatched.fulllength.sorted.cropped.fasta.bsr TRASH_$basef
mv $basef.NT.snap.unmatched.fulllength.sorted.cropped.fasta.bsi TRASH_$basef
mv $basef.NT.snap.matched.fl.Viruses.fasta.bsr TRASH_$basef
mv $basef.NT.snap.matched.fl.Viruses.fasta.bsi TRASH_$basef
mv $basef.NT.snap.unmatched_addVir_uniq.fasta.barcodes TRASH_$basef
mv $basef.NT.snap.unmatched.fulllength.sorted.fasta TRASH_$basef
mv $basef.NT.snap.unmatched.fulllength.sorted.cropped.fasta TRASH_$basef
mv $basef.NT.snap.unmatched.fulllength.sorted.cropped.uniq.fasta TRASH_$basef
mv $basef.NT.snap.unmatched.uniq.fl.fasta TRASH_$basef
mv $basef.NT.snap.matched.fl.Viruses.fasta TRASH_$basef
mv $basef.NT.snap.unmatched_addVir_uniq.fasta.@*.fasta TRASH_$basef
mv "$basef.NT.snap.unmatched_addVir_uniq.fasta.k$abysskmer-unitigs.cutoff$contigcutoff.all.fastq" "TRASH_$basef"
mv $basef.cutadapt.andcontigs.fastq TRASH_$basef
mv $basef.Ecutoff1.virus.contigs.RAPSearch.m8.fastq TRASH_$basef
mv $basef.Ecutoff1.virus.contigs.RAPSearch.addseq.all.annotated TRASH_$basef
mv $basef.Ecutoff1.virus.contigs.RAPSearch.m8.noheader TRASH_$basef
mv $basef.Ecutoff1.virus.contigs.RAPSearch.m8.header.fastq TRASH_$basef
mv readcounts.$basef.temp TRASH_$basef
mv barcode_readcounts.$basef.[123456789].temp TRASH_$basef
mv barcode_readcounts.$basef.log TRASH_$basef
      
mv $basef.NT.snap.unmatched_addVir_uniq.fasta.dir deNovoASSEMBLY_$basef
mv all.$basef.NT.snap.unmatched_addVir_uniq.fasta.unitigs*.fa deNovoASSEMBLY_$basef
mv all.bar*.$basef.NT.snap.unmatched_addVir_uniq.fasta.unitigs.cut*.fa deNovoASSEMBLY_$basef
mv all.bar*.$basef.NT.snap.unmatched_addVir_uniq.fasta.unitigs.fa deNovoASSEMBLY_$basef
mv toAmos.error deNovoASSEMBLY_$basef

mv $basef.Contigs.and.NTunmatched.Vir.RAPsearch.e*.m*.fasta TRASH_$basef
mv $basef.Contigs.and.NTunmatched.Vir.RAPsearch.e*.NR.e*.addseq.* TRASH_$basef
mv $basef.Contigs.and.NTunmatched.Vir.RAPsearch.e*.NR.e*.aln TRASH_$basef
mv $basef.Contigs.and.NTunmatched.Vir.RAPsearch.e*.NR.e*.m8.fast* TRASH_$basef
mv $basef.Viral.RAPsearch.e1.m8.fasta.seq

mv $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.addseq.m8 TRASH_$basef
mv $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.addseq.gi TRASH_$basef
mv $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.addseq.gi.uniq TRASH_$basef 
mv $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.addseq.gi.taxonomy TRASH_$basef
mv $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.annotated.header TRASH_$basef

mv $basef.NT.snap.matched.fulllength.gi.uniq TRASH_$basef
mv $basef.Vir.RAPSearch.e*.aln TRASH_$basef
mv $basef.Vir.RAPSearch.e*.m8.fasta TRASH_$basef

mv $basef.Contigs.and.NTunmatched.Vir.RAPSearch.e*.NR.e*.m8 DATASETS_$basef
mv $basef.Vir.RAPSearch.e*.m8 DATASETS_$basef

mv $basef.Contigs.and.NTunmatched.Vir.RAPsearch.e*.NR.e*.annotated OUTPUT_$basef
mv $basef.Contigs.and.NTunmatched.Vir.RAPsearch.e*.NR.e*.Viruses.annotated OUTPUT_$basef
mv $basef.Contigs.NR.RAPSearch.e*.annotated OUTPUT_$basef
mv $basef.quality OUTPUT_$basef

mv *$basef*.Report COVERAGEMAPS_$basef
mv bar*$basef*.pdf OUTPUT_$basef
mv bar*$basef* COVERAGEMAPS_$basef
mv *bar*$basef* COVERAGEMAPS_$basef
mv $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.addseq.all.annotated TRASH_$basef
mv *.annotated OUTPUT_$basef
mv $basef.Contigs.NT.snap.unmatched.uniq.fl.fasta DATASETS_$basef
mv $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e*.addseq* TRASH_$basef
mv $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e*.aln TRASH_$basef
mv $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e*.m8 DATASETS_$basef
mv $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e*.m8.fasta TRASH_$basef
mv $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e*.m8.fasta.seq TRASH_$basef
mv $basef.$rapsearch_database.RAPsearch.e*.m8.fasta.seq TRASH_$basef
mv $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPsearch.e*.Viruses.annotated.bar.inc TRASH_$basef
mv $basef.snap.unmatched_addVir_uniq.fasta.dir deNovoASSEMBLY_$basef

mv $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.aln TRASH_$basef
mv $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.m8 DATASETS_$basef
mv $basef.$rapsearch_database.RAPsearch.e${ecutoff_Vir}.m8.fasta TRASH_$basef

cp SURPI.$basef.log OUTPUT_$basef
cp SURPI.$basef.err OUTPUT_$basef
cp $basef.config OUTPUT_$basef
cp quality.$basef.log OUTPUT_$basef
mv $basef*log LOG_$basef
mv quality.$basef.log LOG_$basef

curdate=$(date)

tweet.pl "Completed SURPI Pipeline on $host: $inputfile. ($curdate) ($scriptname)"
