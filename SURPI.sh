#!/bin/bash
#
#	SURPI.sh
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
# Last revised 5/19/2014

SURPI_version="1.0.13" #SURPI version

optspec=":a:c:d:f:hi:l:m:n:p:q:r:s:vw:x:z:"
bold=$(tput bold)
normal=$(tput sgr0)
green='\e[0;32m'
red='\e[0;31m'
endColor='\e[0m'

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
		v) VERIFICATION=1;;
		w) VERIFY_FASTQ=${OPTARG};; #1 is default
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

${bold}SURPI version ${SURPI_version}${normal}

This program will run the SURPI pipeline with the parameters supplied by either the config file, or specified on the command line.

${bold}Usage:${normal}

Run SURPI pipeline with a config file:
	$scriptname -f config

Run SURPI pipeline in verification mode:
	$scriptname -f config -v

Run SURPI pipeline specifying parameters on command line:
	$scriptname -i test.fastq -q Sanger -a Truseq -x 50 -r Viral

Create default config and go file
	$scriptname -z test.fastq

${bold}Command Line Switches:${normal}

	-h	Show help & ignore all other switches
	-v	Verification mode
		SURPI will verify the following:
			• software dependencies
			• reference data specified in config file
			• taxonomy lookup functionality
			• FASTQ file (if requested in config file)

	-f	Specify config file & ignore all other switches
	-i	Specify FASTQ input file

	The below options may be mandatory or optional.
	Mandatory: option must be present in either config file or on command line
	Optional: option may be present in either config file or command line.
				A default value may be applied if not specified.

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
	-w	Verify FASTQ quality [optional] (0 / 1 [default] / 2 / 3)
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
# This is the config file used by SURPI. It contains mandatory parameters,
# optional parameters, and server related constants.
# Do not change the config_file_version - it is auto-generated.
# 	and used to ensure that the config file used matches the version of the SURPI pipeline run.
config_file_version="$SURPI_version"

##########################
#  Mandatory parameters
##########################


#To create this file, concatenate the entirety of a sequencing run into one FASTQ file.
#SURPI currently does not have paired-end functionality, we routinely concatenate Read 1 and Read 2 into the unified input file.
#For SURPI to provide proper readcount statistics, all read headers in a single SURPI input dataset should share a
#common 3 letter string (eg: M00, HWI, HIS, SCS, SRR for example). SURPI currently selects the string from the first and last reads only.
inputfile="$create_config_file"

#input filetype. [FASTA/FASTQ]
inputtype="FASTQ"

#FASTQ quality score type: [Sanger/Illumina]
#Sanger = Sanger score (ASCII-33)
#Illumina = Illumina score (ASCII-64)
quality="Sanger"

#length_cutoff: after quality and adaptor trimming, any sequence with length smaller than length_cutoff will be discarded
length_cutoff="50"

#Adapter set used. [Truseq/Nextera/NexSolB]
#Truseq = trims truseq adaptors
#Nextera = trims Nextera adaptors
adapter_set="Truseq"

#RAPSearch database method to use. [Viral/NR]
#Viral database contains viral proteins derived from genbank
#NR contains all NR proteins
rapsearch_database="Viral"

#SNAP edit distance [Highly recommended default: d_human=12]
#see Section 3.1.2 MaxDist description: http://snap.cs.berkeley.edu/downloads/snap-1.0beta-manual.pdf
d_human=12

#RAPSearch e_cutoffs
#E-value of 1e+1, 1e+0 1e-1 is represented by RAPSearch2 http://omics.informatics.indiana.edu/mg/RAPSearch2/ in log form (1,0,-1).
#Larger E-values are required to find highly divergent viral sequences.
ecutoff_Vir="1"
ecutoff_NR="0"

#e value for BLASTn used in coverage map generation
eBLASTn="1e-15"

##########################
# Optional Parameters
##########################

#Run mode to use. [Comprehensive/Fast]
#Comprehensive mode allows SNAP to NT -> denovo contig assembly -> RAPSearch to Viral proteins or NR
#Fast mode allows SNAP to curated FAST databases
run_mode="Comprehensive"

#Which method to use for SNAP to nt [AWS_master_slave/solo]
# AWS_master_slave will start up a slave instance on AWS for each division of the nt database
# It will be more costly, but should run significantly faster than the solo method, which 
# runs each NT division through SNAP serially on a single machine.
# If using the "AWS_master_slave" option, be sure that all parameters in the AWS section below are
# set properly.
snap_nt_procedure="solo"
# snap_nt_procedure="AWS_master_slave"

#Number of cores to use. Will use all cores on machine if unspecified.
#Uncomment the parameter to set explicitly.
#cores=64

#Cropping values. Highly recommended default = 10,75
#Cropping quality trimmed reads prior to SNAP alignment
#snapt_nt = Where to start crop
#crop_length = how long to crop
start_nt=10
crop_length=75

#kmer value for ABySS in DeBruijn portion of denovo contig assembly. Highly recommended default=34
abysskmer=34

#Verify FASTQ quality
#	0 = skip validation
#	1 [default] = run validation, don't check for unique names, quit on failure
#	2 = run validation, check for unique names, quit on failure (helpful with newer MiSeq output that has same name for read1 and read2 due to spacing)
#	3 = run validation, check for unique names, do not quit on failure
VERIFY_FASTQ=1

#Below options are to skip specific steps.
#Uncomment preprocess parameter to skip preprocessing
#(useful for large data sets that have already undergone preprocessing step)
# If skipping preprocessing, be sure these files exist in the working directory.
# $basef.cutadapt.fastq
# $basef.preprocessed.fastq
# $basef.preprocessed.s20.h250n25d12xfu.human.unmatched.fastq
#preprocess="skip"

#snap_nt iterator to use. [inline/end]
#inline : compares each SNAP iteration to the previous as they are completed
#				Uses more disk space, and should be faster for larger input files.
#				also allows for concurrent SNAP runs.
#end	: compares all SNAP iterations once they have all completed.
#These two methods should give identical results, but may have different performance.
snap_integrator="end"

#only used if snap_integrator=end
#if using this parameter, the SNAP databases should reside on separate disks in order to increase throughput.
#(Mechanism for doing this is not yet in place)
num_simultaneous_SNAP_runs=1;

##########################
# Server related values
##########################

# SNAP-indexed database of host genome (for subtraction phase)
SNAP_subtraction_db="/reference/snap_index_hg19_rRNA_mito_Hsapiens_rna"

# directory for SNAP-indexed databases of NCBI NT (for mapping phase in comprehensive mode)
# directory must ONLY contain snap indexed databases
SNAP_COMPREHENSIVE_db_dir="/reference/COMP_SNAP"

# directory for SNAP-indexed databases for mapping phase in FAST mode
# directory must ONLY contain snap indexed databases
SNAP_FAST_db_dir="/reference/FAST_SNAP"

#Taxonomy Reference data directory
#This folder should contain the 3 SQLite files created by the script "create_taxonomy_db.sh"
#gi_taxid_nucl.db - nucleotide db of gi/taxonid
#gi_taxid_prot.db - protein db of gi/taxonid
#names_nodes_scientific.db - db of taxonid/taxonomy
taxonomy_db_directory="/reference/taxonomy"

#RAPSearch viral database name: indexed protein dataset (all of Viruses)
#make sure that directory also includes the .info file 
RAPSearch_VIRUS_db="/reference/RAPSearch/rapsearch_viral_aa_130628_db_v2.12"

#RAPSearch nr database name: indexed protein dataset (all of NR)
#make sure that directory also includes the .info file 
RAPSearch_NR_db="/reference/RAPSearch/rapsearch_nr_130624_db_v2.12"

ribo_snap_bac_euk_directory="/reference/RiboClean_SNAP"

#specify a location for storage of temporary files.
#Space needed may be up to 10x the size of the input file.
#This folder will not be created by SURPI, so be sure it already exists with proper permissions.
temporary_files_directory="/tmp/"

##########################
# AWS related values
##########################

# These values are only used if the "AWS_master_slave" option is set above.

# AWS_master_slave will start up a slave instance on AWS for each division of the nt database
# It will be more costly, but should run significantly faster than the solo method, which 
# runs each NT division through SNAP serially on a single machine.
# If using the "AWS_master_slave" option, be sure that all parameters in the AWS section below are
# set properly.

#ami-b93264d0 = Ubuntu 12.04 HVM 64-bit
#ami-5ef61936 = custom AMI (ami-b93264d0 + SNAP setup)
ami_id="ami-5ef61936"

#needs to match the number of divisions of nt in SNAP db (29, currently). Can test process with fewer.
number_of_instances=29

instance_type="c3.8xlarge"

keypair="surpi"

security_group="SURPI"

availability_zone="us-east-1d"

placement_group="surpi"

#specify directory for incoming data from slaves
#this directory will not be created by SURPI - it should pre-exist.
#There must be sufficient space in this directory to contain all returning compressed SAM files
incoming_dir="/ssd4/incoming"

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
		#verify that config file version matches SURPI version
		if [ "$config_file_version" != "$SURPI_version" ]
		then
			echo "The config file $config_file was created with SURPI $config_file_version."
			echo "The current version of SURPI running is $SURPI_version."
			echo "Please generate a new config file with SURPI $SURPI_version in order to run SURPI."
			exit 65
		fi
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

#check that $inputfile is a FASTQ file, and has a FASTQ suffix.
# convert from FASTA if necessary, add FASTQ suffix if necessary.
if [ $inputtype = "FASTQ" ]
then
	if [ ${inputfile##*.} != "fastq" ]
	then
		ln -s $inputfile $inputfile.fastq
		FASTQ_file=$inputfile.fastq
	else
		FASTQ_file=$inputfile
	fi
elif [ $inputtype = "FASTA" ]
then
	echo "Converting $inputfile to FASTQ format..."
	FASTQ_file="$inputfile.fastq"
	fasta_to_fastq $inputfile > $FASTQ_file
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

if [ ! $eBLASTn ]
then
	eBLASTn=1e-15
fi
nopathf=${FASTQ_file##*/} # remove the path to file
basef=${nopathf%.fastq}

#This is the point to verify all input before the SURPI run initiates
# add verification for all databases and access to all dependencies

#verify that all software dependencies are properly installed
declare -a dependency_list=("gt" "seqtk" "fastq" "fqextract" "cutadapt" "prinseq-lite.pl" "dropcache" "snap" "rapsearch" "fastQValidator" "abyss-pe" "Minimo")
echo "-----------------------------------------------------------------------------------------"
echo "DEPENDENCY VERIFICATION"
echo "-----------------------------------------------------------------------------------------"
for command in "${dependency_list[@]}"
do
        if hash $command 2>/dev/null; then
                echo -e "$command: ${green}OK${endColor}"
        else
                echo
                echo -e "$command: ${red}BAD${endColor}"
                echo "$command does not appear to be installed properly."
                echo "Please verify your SURPI installation and \$PATH, then restart the pipeline"
                echo
				dependency_check="FAIL"
        fi
done
echo "-----------------------------------------------------------------------------------------"
echo "REFERENCE DATA VERIFICATION"
echo "-----------------------------------------------------------------------------------------"
if [ -f $SNAP_subtraction_db/Genome ]
then
		echo -e "SNAP_subtraction_db: $SNAP_subtraction_db: ${green}OK${endColor}"
else
		echo -e "SNAP_subtraction_db: $SNAP_subtraction_db: ${red}BAD${endColor}"
		reference_check="FAIL"
fi

for f in $SNAP_COMPREHENSIVE_db_dir/*
do
	if [ -f $f/Genome ]
	then
		echo -e "$f: ${green}OK${endColor}"
	else
		echo -e "$f: ${red}BAD${endColor}"
		reference_check="FAIL"
	fi
done

for f in $SNAP_FAST_db_dir/*
do
	if [ -f $f/Genome ]
	then
		echo -e "$f: ${green}OK${endColor}"
	else
		echo -e "$f: ${red}BAD${endColor}"
		reference_check="FAIL"
	fi
done

#verify taxonomy is functioning properly
result=$( taxonomy_lookup_embedded.pl -d nucl -q $taxonomy_db_directory 149408158 )
if [ $result = "149408158" ]
then
	echo -e "taxonomy: ${green}OK${endColor}"
else
	echo -e "taxonomy: ${red}BAD${endColor}"
	echo "taxonomy appears to be malfunctioning. Please check logs and config file to verify proper taxonomy functionality."
	reference_check="FAIL"
fi

if [ -f $RAPSearch_VIRUS_db ]
then
	echo -e "$RAPSearch_VIRUS_db: ${green}OK${endColor}"
else
	echo -e "$RAPSearch_VIRUS_db: ${red}BAD${endColor}"
	echo
	reference_check="FAIL"
fi

if [ -f $RAPSearch_VIRUS_db.info ]
then
	echo -e "$RAPSearch_VIRUS_db.info: ${green}OK${endColor}"
else
	echo -e "$RAPSearch_VIRUS_db.info: ${red}BAD${endColor}"
	echo
	reference_check="FAIL"
fi

if [ -f $RAPSearch_NR_db ]
then
	echo -e "$RAPSearch_NR_db: ${green}OK${endColor}"
else
	echo -e "$RAPSearch_NR_db: ${red}BAD${endColor}"
	echo
	reference_check="FAIL"
fi

if [ -f $RAPSearch_NR_db.info ]
then
	echo -e "$RAPSearch_NR_db.info: ${green}OK${endColor}"
else
	echo -e "$RAPSearch_NR_db.info: ${red}BAD${endColor}"
	echo
	reference_check="FAIL"
fi
if [[ ($dependency_check = "FAIL" || $reference_check = "FAIL") ]]
then
	echo -e "${red}There is an issue with one of the dependencies or reference databases above.${endColor}"
	exit 65
else
	echo -e "${green}All dependencies and reference data pass.${endColor}"
fi
length=$( expr length $( head $FASTQ_file | tail -1 ) ) # get length of 1st sequence in FASTQ file
contigcutoff=$(perl -le "print int(1.75 * $length)")
echo "-----------------------------------------------------------------------------------------"
echo "INPUT PARAMETERS"
echo "-----------------------------------------------------------------------------------------"
echo "Command Line Usage: $scriptname $@"
echo "SURPI version: $SURPI_version"
echo "config_file: $config_file"
echo "config file version: $config_file_version"
echo "Server: $host"
echo "Working directory: $( pwd )"
echo "run_mode: $run_mode"
echo "inputfile: $inputfile"
echo "inputtype: $inputtype"
echo "FASTQ_file: $FASTQ_file"
echo "cores used: $cores"
echo "Raw Read quality: $quality"
echo "Read length_cutoff for preprocessing under which reads are thrown away: $length_cutoff"

echo "temporary files location: $temporary_files_directory"

echo "SNAP human indexed database (for subtraction): $SNAP_subtraction_db"

echo "SNAP_db_directory housing the reference databases for Comprehensive Mode: $SNAP_COMPREHENSIVE_db_dir"
echo "SNAP_db_directory housing the reference databases for Fast Mode: $SNAP_FAST_db_dir"

echo "SNAP edit distance for SNAP to Human and SNAP to NT d_human: $d_human"

echo "RAPSearch indexed viral db used: $RAPSearch_VIRUS_db"
echo "RAPSearch indexed NR db used: $RAPSearch_NR_db"
echo "rapsearch_database: $rapsearch_database"

echo "taxonomy database directory: $taxonomy_db_directory"
echo "adapter_set: $adapter_set"

echo "Raw Read length: $length"
echo "contigcutoff for abyss assembly unitigs: $contigcutoff"
echo "abysskmer length: $abysskmer"

echo "cache_reset: $cache_reset"
echo "start_nt: $start_nt"
echo "crop_length: $crop_length"

echo "e value for BLASTn used in coverage map generation: $eBLASTn"

echo "---------------------------------------------"
echo "Cluster settings"

echo "snap_nt_procedure: $snap_nt_procedure"
echo "ami_id: $ami_id"
echo "number_of_instances: $number_of_instances"
echo "instance_type: $instance_type"
echo "keypair: $keypair"
echo "security_group: $security_group"
echo "placement_group: $placement_group"
echo "availability_zone: $availability_zone"
echo "incoming_dir: $incoming_dir"
echo "---------------------------------------------"

echo "-----------------------------------------------------------------------------------------"

if [ "$VERIFY_FASTQ" = 1 ]
then
	fastQValidator --file $FASTQ_file --printBaseComp --avgQual --disableSeqIDCheck > quality.$basef.log
	if [ $? -eq 0 ]
	then
		echo -e "${green}$FASTQ_file appears to be a valid FASTQ file. Check the quality.$basef.log file for details.${endColor}"
	else
		echo -e "${red}$FASTQ_file appears to be a invalid FASTQ file. Check the quality.$basef.log file for details.${endColor}"
		echo -e "${red}You can bypass the quality check by not using the -v switch.${endColor}"
		exit 65
	fi
elif [ "$VERIFY_FASTQ" = 2 ]
then
	fastQValidator --file $FASTQ_file --printBaseComp --avgQual > quality.$basef.log
	if [ $? -eq 0 ]
	then
		echo -e "${green}$FASTQ_file appears to be a valid FASTQ file. Check the quality.$basef.log file for details.${endColor}"
	else
		echo -e "${red}$FASTQ_file appears to be a invalid FASTQ file. Check the quality.$basef.log file for details.${endColor}"
		echo -e "${red}You can bypass the quality check by not using the -v switch.${endColor}"
		exit 65
	fi
elif [ "$VERIFY_FASTQ" = 3 ]
then
	fastQValidator --file $FASTQ_file --printBaseComp --avgQual > quality.$basef.log
fi
if [[ $VERIFICATION -eq 1 ]]
then
	exit
fi
curdate=$(date)

# tweet.pl "Starting SURPI Pipeline on $host: $FASTQ_file ($curdate) ($scriptname)"

###########################################################
echo "#################### STARTING SURPI PIPELINE ##################"
START0=$(date +%s)
echo "Found file $FASTQ_file"
echo "After removing path: $nopathf"
############ Start up AWS slave machines ##################

#move below parameters to config file before publishing code

file_with_slave_ips="slave_list.txt"

if [ "$snap_nt_procedure" = "AWS_master_slave" ]
then
	# start the slaves as a background process. They should be ready to run at the SNAP to NT step in the pipeline.
	start_slaves.sh $ami_id $number_of_instances $instance_type $keypair $security_group $availability_zone $file_with_slave_ips $placement_group & # > $basef.AWS.log 2>&1
fi

############ PREPROCESSING ##################
if [ "$preprocess" != "skip" ]
then
	echo "############ PREPROCESSING ##################"
	echo -n "Starting: preprocessing using $cores cores "
	date
	START2=$(date +%s)
	echo "Parameters: preprocess_ncores.sh $basef.fastq $quality N $length_cutoff $cores Y N $adapter_set $start_nt $crop_length $temporary_files_directory >& $basef.preprocess.log"
	preprocess_ncores.sh $basef.fastq $quality N $length_cutoff $cores Y N $adapter_set $start_nt $crop_length $temporary_files_directory >& $basef.preprocess.log
	echo -n "Done: preprocessing "
	date
	END2=$(date +%s)
	diff=$(( END2 - START2 ))
	echo "$FASTQ_file Preprocessing Took $diff seconds" | tee timing.$basef.log
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
		echo "Parameters: snap single $SNAP_subtraction_db $basef.preprocessed.fastq -o $basef_h.human.snap.unmatched.sam -t $cores -x -f -h 250 -d ${d_human} -n 25 -F u"
		snap single $SNAP_subtraction_db $basef.preprocessed.fastq -o $basef_h.human.snap.unmatched.sam -t $cores -x -f -h 250 -d ${d_human} -n 25 -F u     
		echo -n "Done: SNAP to human"
		date
		END6=$(date +%s)
		diff=$(( END6 - START6 ))
		echo "$basef.preprocessed.fastq Human mapping Took $diff seconds" | tee -a timing.$basef.log
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
			if [ $snap_integrator = "inline" ]
			then
				echo "Parameters: snap_nt.sh $basef_h.human.snap.unmatched.fastq ${SNAP_COMPREHENSIVE_db_dir} $cores $cache_reset $d_human"
				snap_nt.sh $basef_h.human.snap.unmatched.fastq ${SNAP_COMPREHENSIVE_db_dir} $cores $cache_reset $d_human
			elif [ $snap_integrator = "end" ]
			then
				if [ "$snap_nt_procedure" = "AWS_master_slave" ]
				then
					#this parameter is currently tied to the $keypair used during slave_setup.sh. should be cleaned up prior to release
					pemkey="/home/ubuntu/.ssh/surpi.pem"

					# transfer data to slave, start SNAP on each slave, and wait for results
					#check if slave_setup is running before progressing to snap_on_slave.sh
					#slave_setup should be responsible for verifying that all slaves are properly running.
					echo -n "Waiting for slave_setup to complete."
					while [ ! -f $file_with_slave_ips ]
					do
						echo -n "."
						sleep 2
					done
					echo
					echo "snap_on_slave.sh $basef_h.human.snap.unmatched.fastq $pemkey $file_with_slave_ips $incoming_dir ${basef}.NT.snap.sam $d_human"
					snap_on_slave.sh "$basef_h.human.snap.unmatched.fastq" "$pemkey" "$file_with_slave_ips" "$incoming_dir" "${basef}.NT.snap.sam" "$d_human"> $basef.AWS.log 2>&1
					
				elif [ "$snap_nt_procedure" = "solo" ]
				then
					echo "Parameters: snap_nt_combine.sh $basef_h.human.snap.unmatched.fastq ${SNAP_COMPREHENSIVE_db_dir} $cores $cache_reset $d_human $num_simultaneous_SNAP_runs"
					snap_nt_combine.sh $basef_h.human.snap.unmatched.fastq ${SNAP_COMPREHENSIVE_db_dir} $cores $cache_reset $d_human $num_simultaneous_SNAP_runs
				fi
			fi
		elif [ $run_mode = "Fast" ]
		then
			echo "Parameters: snap_nt.sh $basef_h.human.snap.unmatched.fastq ${SNAP_FAST_db_dir} $cores $cache_reset $d_human"
			snap_nt.sh $basef_h.human.snap.unmatched.fastq ${SNAP_FAST_db_dir} $cores $cache_reset $d_human
		fi
		
		echo -n "Done:  SNAP to NT"
		date
		END11=$(date +%s)
		diff=$(( END11 - START11 ))
		echo "$basef_h.human.snap.unmatched.fastq SNAP to NT all dbs Took $diff seconds" | tee -a timing.$basef.log
		mv -f $basef_h.human.snap.unmatched.NT.sam $basef.NT.snap.sam
	fi
	echo -n "Starting: parsing $basef.NT.snap.sam "
	date
	echo -n "extract matched/unmatched $basef.NT.snap.sam"
	date
	egrep -v "^@" $basef.NT.snap.sam | awk '{if($3 != "*") print }' > $basef.NT.snap.matched.sam
	egrep -v "^@" $basef.NT.snap.sam | awk '{if($3 == "*") print }' > $basef.NT.snap.unmatched.sam
	echo -n "convert sam to fastq from $basef.NT.snap.sam "
	date
	echo -n "Done: parsing $basef.NT.snap.unmatched.sam  "
	date
	if [ ! -f "$basef.NT.snap.matched.all.annotated" ];
	then
		## convert to FASTQ and retrieve full-length sequences
		echo -n "convert to FASTQ and retrieve full-length sequences for SNAP NT matched hits "
		date

		extractHeaderFromFastq_ncores.sh "$cores" "$basef.cutadapt.fastq" "$basef.NT.snap.matched.sam" "$basef.NT.snap.matched.fulllength.fastq" "$basef.NT.snap.unmatched.sam" "$basef.NT.snap.unmatched.fulllength.fastq"   #SNN140507
		sort -k1,1 "$basef.NT.snap.matched.sam"  > "$basef.NT.snap.matched.sorted.sam"
		cut -f1-9 "$basef.NT.snap.matched.sorted.sam" > "$basef.NT.snap.matched.sorted.sam.tmp1"
		cut -f12- "$basef.NT.snap.matched.sorted.sam" > "$basef.NT.snap.matched.sorted.sam.tmp2" #SNN140507 -f11 -> -f12
		awk '(NR%4==1) {printf("%s\t",$0)} (NR%4==2) {printf("%s\t", $0)} (NR%4==0) {printf("%s\n",$0)}' "$basef.NT.snap.matched.fulllength.fastq" | sort -k1,1 | awk '{print $2 "\t" $3}' > "$basef.NT.snap.matched.fulllength.sequence.txt" #SNN140507 change this to bring in quality lines as well
		paste "$basef.NT.snap.matched.sorted.sam.tmp1" "$basef.NT.snap.matched.fulllength.sequence.txt" "$basef.NT.snap.matched.sorted.sam.tmp2" > "$basef.NT.snap.matched.fulllength.sam"
		###retrieve taxonomy matched to NT ###
		echo -n "taxonomy retrieval for $basef.NT.snap.matched.fulllength.sam"
		date
		taxonomy_lookup.pl "$basef.NT.snap.matched.fulllength.sam" sam nucl $cores $taxonomy_db_directory >& "$basef.taxonomy.SNAPNT.log"
		sed 's/NM:i:\([0-9]\)/0\1/g' "$basef.NT.snap.matched.fulllength.all.annotated" | sort -k 14,14 > "$basef.NT.snap.matched.fulllength.all.annotated.sorted"
		rm -f  "$basef.NT.snap.matched.fulllength.gi" "$basef.NT.snap.matched.fullength.gi.taxonomy"
	fi
# adjust filenames for FAST mode
	grep "Viruses;" "$basef.NT.snap.matched.fulllength.all.annotated.sorted" > "$basef.NT.snap.matched.fl.Viruses.annotated"
	grep "Bacteria;" "$basef.NT.snap.matched.fulllength.all.annotated.sorted" > "$basef.NT.snap.matched.fl.Bacteria.annotated"
	
	##SNN140507 cleanup bacterial reads 
	ribo_snap_bac_euk.sh $basef.NT.snap.matched.fl.Bacteria.annotated BAC $cores $ribo_snap_bac_euk_directory #SNN140507
	
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
		#SNN 140507 extractHeaderFromFastq.csh "$basef.NT.snap.unmatched.fastq" FASTQ "$basef.cutadapt.fastq" "$basef.NT.snap.unmatched.fulllength.fastq"
		sed "n;n;n;d" "$basef.NT.snap.unmatched.fulllength.fastq" | sed "n;n;d" | sed "s/^@/>/g" > "$basef.NT.snap.unmatched.fulllength.fasta"
	fi
	cat "$basef.NT.snap.unmatched.fulllength.fasta" | perl -e 'while (<>) {$h=$_; $s=<>; $seqs{$h}=$s;} foreach $header (reverse sort {length($seqs{$a}) <=> length($seqs{$b})} keys %seqs) {print $header.$seqs{$header}}' > $basef.NT.snap.unmatched.fulllength.sorted.fasta
	if [ $run_mode = "Comprehensive" ]
	then
		echo "we will be using 50 as the length of the cropped read for removing unique and low-complexity reads"
		crop_reads.csh "$basef.NT.snap.unmatched.fulllength.sorted.fasta" 25 50 > "$basef.NT.snap.unmatched.fulllength.sorted.cropped.fasta"
		echo "*** reads cropped ***"
		gt sequniq -seqit -force -o "$basef.NT.snap.unmatched.fulllength.sorted.cropped.uniq.fasta" "$basef.NT.snap.unmatched.fulllength.sorted.cropped.fasta"
#SNN140507              extractHeaderFromFastq.csh "$basef.NT.snap.unmatched.fulllength.sorted.cropped.uniq.fasta" FASTA "$basef.cutadapt.fastq" "$basef.NT.snap.unmatched.uniq.fl.fastq"
#SNN140507             sed "n;n;n;d" "$basef.NT.snap.unmatched.uniq.fl.fastq" | sed "n;n;d" | sed "s/^@/>/g" > "$basef.NT.snap.unmatched.uniq.fl.fasta"
      	 extractAlltoFast.sh "$basef.NT.snap.unmatched.fulllength.sorted.cropped.uniq.fasta" FASTA "$basef.NT.snap.unmatched.fulllength.fasta" FASTA "$basef.NT.snap.unmatched.uniq.fl.fasta" FASTA #SNN140507

	fi
	echo " Done uniquing full length sequences of unmatched to NT "
fi
curdate=$(date)
# tweet.pl "Finished SNAP mapping on $host: $FASTQ_file ($curdate) ($scriptname)"

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
#######RAPSearch#####
#################### RAPSearch to Vir ###########
if [ $run_mode = "Comprehensive" ]
then
	if [ "$rapsearch_database" == "Viral" ]
	then
		if [ -f "$basef.NT.snap.unmatched.uniq.fl.fasta" ]
		then
			echo "############# RAPSearch to ${RAPSearch_VIRUS_db} ON NT-UNMATCHED SEQUENCES #################"
			dropcache
			echo -n "Starting: RAPSearch $basef.NT.snap.unmatched.uniq.fl.fasta "
			date
			START14=$(date +%s)
			echo "rapsearch -q $basef.NT.snap.unmatched.uniq.fl.fasta -d $RAPSearch_VIRUS_db -o $basef.$rapsearch_database.RAPSearch.e1 -z $cores -e $ecutoff_Vir -v 1 -b 1 -t N >& $basef.$rapsearch_database.RAPSearch.log"
			rapsearch -q "$basef.NT.snap.unmatched.uniq.fl.fasta" -d $RAPSearch_VIRUS_db -o $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir} -z "$cores" -e "$ecutoff_Vir" -v 1 -b 1 -t N >& $basef.$rapsearch_database.RAPSearch.log
			echo -n "Done RAPSearch: "
			date
			END14=$(date +%s)
			diff=$(( END14 - START14 ))
			echo "RAPSearch to Vir Took $diff seconds"
			echo -n "Starting: add FASTA sequences to RAPSearch m8 output file "
			date
			START15=$(date +%s)
			sed -i '/^#/d' $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.m8
			seqtk subseq $basef.NT.snap.unmatched.uniq.fl.fasta $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.m8 > $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.m8.fasta

			sed '/>/d' $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.m8.fasta >  $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.m8.fasta.seq
			paste $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.m8 $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.m8.fasta.seq > $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.addseq.m8
			taxonomy_lookup.pl $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.addseq.m8 blast prot $cores $taxonomy_db_directory
			mv $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.addseq.all.annotated $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.annotated
	
			table_generator.sh $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.annotated RAP Y Y Y Y
			echo -n "Done: converting RAPSearch Vir output to fasta "
			date
			END15=$(date +%s)
			diff=$(( END15 - START15 ))
			echo "converting RAPSearch Vir output to fasta sequences Took $diff seconds" | tee -a timing.$basef.log
			cat "$basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.m8.fasta" "all.$basef.NT.snap.unmatched_addVir_uniq.fasta.unitigs.cut${length}.${contigcutoff}-mini.fa" > "$basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.m8.fasta"
		else
			echo "Cannot run viral RAPSearch - necessary input file ($basef.$rapsearch_database.RAPSearch.e$ecutoff_Vir.m8) does not exist"
			echo "concatenating RAPSearchvirus output and Contigs"
		fi
		echo "############# Cleanup RAPSearch Vir by RAPSearch to NR #################"
		if [ -f $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.m8.fasta ]
		then
			echo -n "Starting: RAPSearch to $RAPSearch_NR_db of $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.m8.fasta :"
			date
			START16=$(date +%s)
			rapsearch -q $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.m8.fasta -d $RAPSearch_NR_db -o $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.NR.e${ecutoff_NR} -z $cores -e $ecutoff_NR -v 1 -b 1 -t N -a T
			echo "rapsearch to nr done"
			sed -i '/^#/d' $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.m8
			echo "removed extra #"
			END16=$(date +%s)
			diff=$(( END16 - START16 ))
			echo "$basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.NR.e${ecutoff_NR} RAPSearch to NR Took $diff seconds" | tee -a timing.$basef.log
			echo -n "Starting: Seq retrieval and Taxonomy $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}  :"
			date
			START17=$(date +%s)
			seqtk subseq $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.m8.fasta $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.m8  > $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.m8.fasta
			echo " $(date) retrieved sequences"
			cat $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.m8.fasta | awk '{if (substr($0,1,1)==">"){if (p){print "\n";} print $0} else printf("%s",$0);p++;}END{print "\n"}' | sed '/^$/d' | sed '/>/d' > $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.m8.fasta.seq
			paste $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e$ecutoff_Vir.NR.e${ecutoff_NR}.m8 $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.m8.fasta.seq > $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.addseq.m8
			echo "made addseq file $(date)"
			echo "############# RAPSearch Taxonomy $(date)"
			taxonomy_lookup.pl $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.addseq.m8 blast prot $cores $taxonomy_db_directory
			cp $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.addseq.all.annotated $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.annotated
			echo "retrieved taxonomy"
			grep "Viruses" $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.annotated > $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.Viruses.annotated
			egrep "^contig" $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.annotated > $basef.Contigs.NR.RAPSearch.e${ecutoff_NR}.annotated
			echo "extracted RAPSearch taxonomy $(date) "
			echo "Starting Readcount table $(date)"
			table_generator.sh $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.Viruses.annotated RAP Y Y Y Y
			table_generator.sh $basef.Contigs.NR.RAPSearch.e${ecutoff_NR}.annotated RAP Y Y Y Y
			#allow contigs to be incorporated into coverage maps by making contig barcodes the same as non-contig barcodes (removing the @)
			sed 's/@//g' $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.Viruses.annotated > $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.Viruses.annotated.bar.inc
			echo "making coverage maps"
			# coverage_generator_bp.sh (divides each fasta file into $cores cores then runs BLASTn using one core each.
			coverage_generator_bp.sh $basef.NT.snap.matched.fl.Viruses.annotated $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.Viruses.annotated.bar.inc $eBLASTn $cores 10 1 $basef

			awk '{print$1}'  $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.annotated > $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.annotated.header
			awk '{print$1}' $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.annotated > $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.annotated.header
			# find headers in viral rapsearch that are no longer found in rapsearch to nr 
			sort $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.annotated.header $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.annotated.header | uniq -d | sort $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.annotated.header - | uniq -u > $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.annotated.not.in.NR.header
			rm -r $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.annotated.header $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.annotated
			split -l 400 -a 6 $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.annotated.not.in.NR.header $basef.not.in.NR.
			for f in $basef.not.in.NR.[a-z][a-z][a-z][a-z][a-z][a-z]
			do grep  -f "$f" $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.annotated > $f.annotated
			done
			cat $basef.not.in.NR.[a-z][a-z][a-z][a-z][a-z][a-z].annotated > $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.annotated.not.in.NR.annotated
			rm -r $basef.not.in.NR.[a-z][a-z][a-z][a-z][a-z][a-z]
			rm -r $basef.not.in.NR.[a-z][a-z][a-z][a-z][a-z][a-z].annotated
			table_generator.sh $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.annotated.not.in.NR.annotated RAP N Y N N
			
		
			END17=$(date +%s)
			diff=$(( END17 - START17 ))
			echo "RAPSearch seq retrieval, taxonomy and readcount Took $diff seconds" | tee -a timing.$basef.log
		else
			echo "Cannot run RAPSearch to NR - necessary input file ($basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.m8.fasta) does not exist"
		fi
	fi
	##################RAPSearch to NR #######
	if [ "$rapsearch_database" == "NR" ]
	then
		echo "#################### RAPSearch to NR ###########"
		cat "$basef.NT.snap.unmatched.uniq.fl.fasta" "all.$basef.NT.snap.unmatched_addVir_uniq.fasta.unitigs.cut${length}.${contigcutoff}-mini.fa" > "$basef.Contigs.NT.snap.unmatched.uniq.fl.fasta"
		if [ -f $basef.Contigs.NT.snap.unmatched.uniq.fl.fasta ]
		then
			echo "############# RAPSearch to NR #################"
			echo -n "Starting: RAPSearch to NR $basef.Contigs.NT.snap.unmatched.uniq.fl.fasta"
			date
			START16=$(date +%s)
			rapsearch -q $basef.Contigs.NT.snap.unmatched.uniq.fl.fasta -d $RAPSearchDB_NR -o $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_NR}  -z $cores -e $ecutoff_NR -v 1 -b 1 -t N -a T
			echo "rapsearch  to nr done"
			sed -i '/^#/d' $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_NR}.m8
			echo "removed extra #"
			END16=$(date +%s)
			diff=$(( END16 - START16 ))
			echo "$basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_NR} RAPSearch to NR Took $diff seconds" | tee -a timing.$basef.log
			echo -n "Starting: Seq retrieval and Taxonomy $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_NR}"
			date
			START17=$(date +%s)
			seqtk subseq $basef.Contigs.NT.snap.unmatched.uniq.fl.fasta $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_NR}.m8 > $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_NR}.m8.fasta
			echo " $(date) retrieved sequences"
			sed '/>/d' $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_NR}.m8.fasta > $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_NR}.m8.fasta.seq
			paste $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_NR}.m8 $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_NR}.m8.fasta.seq > $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_NR}.addseq.m8
			echo "made addseq file $(date)"
			echo "############# RAPSearch Taxonomy $(date)"
			taxonomy_lookup.pl $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_NR}.addseq.m8 blast prot $cores $taxonomy_db_directory
			cp $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_NR}.addseq.all.annotated $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_NR}.annotated
			echo "retrieved taxonomy"
			grep "Viruses" $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_NR}.annotated > $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_NR}.Viruses.annotated
			egrep "^contig" $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_NR}.annotated > $basef.Contigs.$rapsearch_database.RAPSearch.e${ecutoff_NR}.annotated 
			echo "extracted RAPSearch taxonomy $(date) "
			echo "Starting Readcount table $(date)"
			table_generator.sh $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_NR}.Viruses.annotated RAP Y Y Y Y
			grep -v Viruses $basef.Contigs.$rapsearch_database.RAPSearch.e${ecutoff_NR}.annotated > $basef.Contigs.$rapsearch_database.RAPSearch.e${ecutoff_NR}.noVir.annotated
			table_generator.sh $basef.Contigs.$rapsearch_database.RAPSearch.e${ecutoff_NR}.noVir.annotated RAP N Y N N
			sed 's/@//g' $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_NR}.Viruses.annotated > $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_NR}.Viruses.annotated.bar.inc
			echo "making coverage maps"
			
			coverage_generator_bp.sh $basef.NT.snap.matched.fl.Viruses.annotated $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_NR}.Viruses.annotated.bar.inc $eBLASTn 10 10 1 $basef
			END17=$(date +%s)
			diff=$(( END17 - START17 ))
			echo "RAPSearch seq retrieval, taxonomy and table readcount and coverage Took $diff seconds" | tee -a timing.$basef.log
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

headerid_top=$(head -1 $basef.fastq | cut -c1-4)
headerid_bottom=$(tail -4 $basef.fastq | cut -c1-4 | head -n 1)

if [ "$headerid_top" == "$headerid_bottom" ]
# This code is checking that the top header is equal to the bottom header.
# We should adjust this code to check that all headers are unique, rather than just the first and last
then
	headerid=$(head -1 $basef.fastq | cut -c1-4 | sed 's/@//g')
	echo " headerid_top $headerid_top = headerid_bottom $headerid_bottom and headerid = $headerid"
	readcount.sh $basef $headerid Y $basef.fastq $basef.preprocessed.fastq $basef.preprocessed.s20.h250n25d12xfu.human.snap.unmatched.fastq $basef.NT.snap.matched.fulllength.all.annotated.sorted $basef.NT.snap.matched.fl.Viruses.annotated $basef.NT.snap.matched.fl.Bacteria.annotated $basef.NT.snap.matched.fl.nonChordatEuk.annotated $basef.NT.snap.unmatched.sam $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.NR.e${ecutoff_NR}.Viruses.annotated  
	echo -n " Done: generating readcounts.$basef.log report"
	date
	END17=$(date +%s)
	diff=$(( END17 - START17 ))
	echo "Generating read count report Took $diff seconds" | tee -a timing.$basef.log
else
	echo "readcount.sh aborted due to non-unique header id"
fi

echo "#################### SURPI PIPELINE COMPLETE ##################"
END0=$(date +%s)
echo -n "Done: "
date
diff=$(( END0 - START0 ))
echo "Total run time of pipeline Took $diff seconds" | tee -a timing.$basef.log

echo "Script and Parameters = $0 $@ " > $basef.pipeline_parameters.log
echo "Raw Read quality = $quality" >> $basef.pipeline_parameters.log
echo "Raw Read length = $length" >> $basef.pipeline_parameters.log
echo "Read length_cutoff for preprocessing under which reads are thrown away = $length_cutoff" >> $basef.pipeline_parameters.log

echo "SURPI_db_directory housing the reference databases for Comprehensive Mode: $SNAP_COMPREHENSIVE_db_dir" >> $basef.pipeline_parameters.log
echo "SURPI_db_directory housing the reference databases for Fast Mode: $SNAP_FAST_db_dir" >> $basef.pipeline_parameters.log

echo "SNAP edit distance for SNAP to Human and SNAP to NT d_human = $d_human" >> $basef.pipeline_parameters.log
echo "RAPSearch indexed viral db used = $RAPSearchDB" >> $basef.pipeline_parameters.log
echo "contigcutoff for abyss assembly unitigs = $contigcutoff"  >> $basef.pipeline_parameters.log
echo "abysskmer length = $abysskmer"  >> $basef.pipeline_parameters.log
echo "adapter_set = $adapter_set" >> $basef.pipeline_parameters.log

########CLEANUP############

dataset_folder="DATASETS_$basef"
log_folder="LOG_$basef"
output_folder="OUTPUT_$basef"
trash_folder="TRASH_$basef"
denovo_folder="deNovoASSEMBLY_$basef"

mkdir $log_folder
mkdir $output_folder
mkdir $trash_folder
mkdir $dataset_folder
if [ $run_mode = "Comprehensive" ]
then
	mkdir $denovo_folder
fi

#Move files to DATASETS

mv $basef.cutadapt.fastq $dataset_folder
mv $basef.preprocessed.s20.h250n25d12xfu.human.snap.unmatched.sam $dataset_folder
mv $basef.NT.snap.sam $dataset_folder
mv $basef.NT.snap.matched.fulllength.sam $dataset_folder
mv $basef.NT.snap.matched.fulllength.fastq $dataset_folder
mv $basef.NT.snap.unmatched.fulllength.fastq $dataset_folder
mv $basef.NT.snap.unmatched.uniq.fl.fastq $dataset_folder
mv $basef.NT.snap.unmatched.fulllength.fasta $dataset_folder
mv $basef.NT.snap.matched.fl.Viruses.uniq.fasta $dataset_folder
mv $basef.NT.snap.unmatched_addVir_uniq.fasta $dataset_folder
mv genus.bar*$basef.plotting $dataset_folder
mv $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.NR.e[0-9].m8 $dataset_folder
mv $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.m8 $dataset_folder

#Move files to deNovoASSEMBLY
mv $basef.NT.snap.unmatched_addVir_uniq.fasta.dir $denovo_folder
mv all.$basef.NT.snap.unmatched_addVir_uniq.fasta.unitigs*.fa $denovo_folder
mv all.bar*.$basef.NT.snap.unmatched_addVir_uniq.fasta.unitigs.cut*.fa $denovo_folder
mv all.bar*.$basef.NT.snap.unmatched_addVir_uniq.fasta.unitigs.fa $denovo_folder

#Move files to LOG
mv coverage.hist $log_folder
mv $basef.cutadapt.summary.log $log_folder
mv $basef.adapterinfo.log $log_folder
mv $basef.cutadapt.cropped.fastq.log $log_folder
mv $basef.preprocess.log $log_folder
mv $basef.taxonomy.SNAPNT.log $log_folder
mv $basef.pipeline_parameters.log $log_folder
mv $basef.table_generator_snap.matched.fl.log $log_folder
mv $basef*.snap.log $log_folder
mv $basef*.time.log $log_folder
mv $basef.$rapsearch_database.RAPSearch.log $log_folder
mv quality.$basef.log $log_folder

mv $basef.NT.snap.matched.fulllength.all.annotated $trash_folder

#Move files to OUTPUT
mv $basef.NT.snap.matched.fulllength.all.annotated.sorted $output_folder
mv $basef.NT.snap.matched.fl.Viruses.annotated $output_folder
mv $basef.NT.snap.matched.fl.Bacteria.annotated $output_folder
mv $basef.NT.snap.matched.fl.Primates.annotated $output_folder
mv $basef.NT.snap.matched.fl.nonPrimMammal.annotated $output_folder
mv $basef.NT.snap.matched.fl.nonMammalChordat.annotated $output_folder
mv $basef.NT.snap.matched.fl.nonChordatEuk.annotated $output_folder
mv readcounts.$basef.*log $output_folder
mv timing.$basef.log $output_folder
mv $basef*table $output_folder
mv $basef.Contigs.NR.RAPSearch.e*.annotated $output_folder
if [ -e $basef.quality ]; then mv $basef.quality $output_folder; fi
mv bar*$basef*.pdf $output_folder
mv genus.bar*$basef.Blastn.fasta $output_folder
mv *.annotated $output_folder

#Move files to TRASH
mv $basef.preprocessed.fastq $trash_folder
mv $basef.cutadapt.cropped.dusted.bad.fastq $trash_folder
if [ -e temp.sam ]; then mv temp.sam $trash_folder; fi
mv $basef.NT.snap.matched.sam $trash_folder
mv $basef.NT.snap.unmatched.sam $trash_folder
mv $basef.preprocessed.s20.h250n25d12xfu.human.snap.unmatched.fastq $trash_folder
mv $basef.NT.snap.matched.sorted.sam $trash_folder
mv $basef.NT.snap.matched.sorted.sam.tmp2 $trash_folder
mv $basef.NT.snap.unmatched.fastq $trash_folder
mv $basef.NT.snap.matched.fastq $trash_folder
mv $basef.NT.snap.matched.sorted.sam.tmp1 $trash_folder
mv $basef.NT.snap.matched.fulllength.sequence.txt $trash_folder
mv $basef.NT.snap.matched.fulllength.gi.taxonomy $trash_folder
mv $basef.NT.snap.matched.fl.Viruses.fastq $trash_folder
mv $basef.NT.snap.unmatched.fulllength.sorted.fasta $trash_folder
mv $basef.NT.snap.unmatched.fulllength.sorted.cropped.fasta $trash_folder
mv $basef.NT.snap.unmatched.fulllength.sorted.cropped.uniq.fasta $trash_folder
mv $basef.NT.snap.unmatched.uniq.fl.fasta $trash_folder
mv $basef.NT.snap.matched.fl.Viruses.fasta $trash_folder
mv $basef.Contigs.and.NTunmatched.Viral.RAPSearch.e*.NR.e*.annotated.header $trash_folder
mv $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.addseq.m8 $trash_folder
mv $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.addseq.gi $trash_folder
mv $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.addseq.gi.uniq $trash_folder 
mv $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.addseq.gi.taxonomy $trash_folder
mv $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.annotated.not.in.NR.header $trash_folder
mv $basef.NT.snap.matched.fulllength.gi.uniq $trash_folder
mv $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e*.addseq* $trash_folder
mv $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e*.aln $trash_folder
mv $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e*.m8.fasta $trash_folder
mv $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e*.m8.fasta.seq $trash_folder
mv $basef.$rapsearch_database.RAPSearch.e*.m8.fasta.seq $trash_folder
mv $basef.Contigs.and.NTunmatched.$rapsearch_database.RAPSearch.e*.Viruses.annotated.bar.inc $trash_folder
mv $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.aln $trash_folder
mv $basef.$rapsearch_database.RAPSearch.e${ecutoff_Vir}.m8.fasta $trash_folder

cp SURPI.$basef.log $output_folder
cp SURPI.$basef.err $output_folder
cp $basef.config $output_folder
cp $log_folder/quality.$basef.log $output_folder
# mv $basef*log $log_folder

curdate=$(date)

# tweet.pl "Completed SURPI Pipeline on $host: $FASTQ_file. ($curdate) ($scriptname)"
