#!/bin/bash
#
#	download_SURPI_data.sh
#
#	This program will download the data files necessary to construct SURPI reference data.
#	It verifies the md5sum if available.
#
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# Copyright (C) 2014 Scot Federman - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
# Last revised 7/2/2014  

scriptname=${0##*/}
bold=$(tput bold)
normal=$(tput sgr0)
green='\e[0;32m'
red='\e[0;31m'
endColor='\e[0m'
DATE=$(date +%m%d%Y)
destination_dir="NCBI_$DATE"
curated_dir="curated_$DATE"

while getopts ":hd:c:" option; do
	case "${option}" in
		h) HELP=1;;
		d) destination_dir=${OPTARG};;
		c) curated_dir=${OPTARG};;
		:)	echo "Option -$OPTARG requires an argument." >&2
			exit 1
      		;;
	esac
done

if [[ ${HELP-} -eq 1 ]]
then
	cat <<USAGE
	
${bold}$scriptname${normal}

This program will download necessary files from NCBI for use with SURPI. 

${bold}Command Line Switches:${normal}

	-h	Show this help

	-d	Specify directory to create for downloaded data
		(optional. If unsupplied, will default to NCBI_[current date] )

	-c	Specify directory to create for curated data
		(optional. If unsupplied, will default to curated_[current date] )

${bold}Usage:${normal}

$scriptname -d NCBI_07022014

USAGE
	exit
fi

NCBI="ftp://ftp.ncbi.nih.gov/"
chiulab_dir="http://chiulab.ucsf.edu/SURPI/databases"
FASTA_dir="blast/db/FASTA/"
TAXONOMY_dir="pub/taxonomy/"

nt="nt.gz"
nt_md5="nt.gz.md5"

nr="nr.gz"
nr_md5="nr.gz.md5"

taxdump="taxdump.tar.gz"
taxdump_md5="taxdump.tar.gz.md5"

#These files do not have md5 (as of 6/2014)
gi_taxid_nucl="gi_taxid_nucl.dmp.gz"
gi_taxid_prot="gi_taxid_prot.dmp.gz"

download_file ()
{
	destination_folder=$1
	remote_dir=$2
	file=$3
	md5=$4
	
	( cd $destination_folder ; curl -O "$remote_dir/$file" )
	if [[ $md5 ]]
	then
		( cd $destination_folder ; curl -O "$remote_dir/$md5" )
		( cd $destination_folder ; md5sum -c --status "$md5" )
		if [ $? -ne 0 ]; then
			echo -e "${red}md5check of $file: failed.${endColor}"
			exit
		else
			echo -e "${green}md5sum of $file: OK${endColor}"
		fi
	fi
}

#
## Download NCBI data
#

if [ ! -d "$destination_dir" ]; then
	mkdir "$destination_dir"
fi

if [ ! -f "$destination_dir/$nt" ]; then
	echo -e "$(date)\t$scriptname\tDownloading $nt"
	download_file "$destination_dir" "$NCBI$FASTA_dir" "$nt" "$nt_md5"
else
	echo -e "$(date)\t$scriptname\t$nt already present."
fi

if [ ! -f "$destination_dir/$nr" ]; then
	echo -e "$(date)\t$scriptname\tDownloading $nr"
	download_file "$destination_dir" "$NCBI$FASTA_dir" "$nr" "$nr_md5"
else
	echo -e "$(date)\t$scriptname\t$nr already present."
fi

if [ ! -f "$destination_dir/$taxdump" ]; then
	echo -e "$(date)\t$scriptname\tDownloading $taxdump"
	download_file "$destination_dir" "$NCBI$TAXONOMY_dir" "$taxdump" "$taxdump_md5"
else
	echo -e "$(date)\t$scriptname\t$taxdump already present."
fi

if [ ! -f "$destination_dir/$gi_taxid_nucl" ]; then
	echo -e "$(date)\t$scriptname\tDownloading $gi_taxid_nucl"
	download_file "$destination_dir" "$NCBI$TAXONOMY_dir" "$gi_taxid_nucl"
else
	echo -e "$(date)\t$scriptname\t$gi_taxid_nucl already present."
fi

if [ ! -f "$destination_dir/$gi_taxid_prot" ]; then
	echo -e "$(date)\t$scriptname\tDownloading $gi_taxid_prot"
	download_file "$destination_dir" "$NCBI$TAXONOMY_dir" "$gi_taxid_prot"
else
	echo -e "$(date)\t$scriptname\t$gi_taxid_prot already present."
fi

#
## Download Chiulab curated data
#
declare -a download_list=(	"Bacterial_Refseq_05172012.CLEAN.LenFiltered.uniq.fa.gz" \
							"hg19_rRNA_mito_Hsapiens_rna.fa.gz" \
							"rapsearch_viral_aa_130628_db_v2.12.fasta.gz" \
							"viruses-5-2012_trimmedgi-MOD_addedgi.fa.gz" \
							"18s_rRNA_gene_not_partial.fa.gz" "23s.fa.gz" \
							"28s_rRNA_gene_NOT_partial_18s_spacer_5.8s.fa.gz" \
							"rdp_typed_iso_goodq_9210seqs.fa.gz")

if [ ! -d "$curated_dir" ]; then
	mkdir "$curated_dir"
fi

for download in "${download_list[@]}"
do
	if [ ! -f "$curated_dir/$download" ]; then
		echo -e "$(date)\t$scriptname\tDownloading $download"
		download_file "$curated_dir" "$chiulab_dir" "$download" "$download.md5"
	else
		echo -e "$(date)\t$scriptname\t$download already present."
	fi
done

echo -e "$(date)\t$scriptname\t${green}Download complete.${endColor}"
