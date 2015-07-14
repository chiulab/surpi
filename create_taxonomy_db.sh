#!/bin/bash
#
#	create_taxonomy_db.sh
#
# 	This script creates the SQLite taxonomy database using NCBI downloadable files
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

while getopts ":d:h" option; do
	case "${option}" in
		d) db_directory=${OPTARG};;
		h) HELP=1;;
		:)	echo "Option -$OPTARG requires an argument." >&2
			exit 1
      		;;
	esac
done

if [[ ${HELP-} -eq 1  ||  $# -lt 1 ]]
then
	cat <<USAGE

${bold}$scriptname${normal}

This script will create the taxonomy SQLite database using NCBI downloadable files.

${bold}Command Line Switches:${normal}

	-h	Show this help

	-d	Specify directory containing NCBI data

${bold}Usage:${normal}

	Index NCBI nt DB into 16 SNAP indices
		$scriptname -n 16 -f NCBI_07022014

	Index NCBI nt DB into SNAP indices of size 3000MB
		$scriptname -s 3000 -f NCBI_07022014

USAGE
	exit
fi

#check if all 3 files are present
if [ -f "$db_directory/taxdump.tar.gz" ] && [ -f "$db_directory/gi_taxid_nucl.dmp.gz" ] && [ -f "$db_directory/gi_taxid_prot.dmp.gz" ]; then
	echo -e "$(date)\t$scriptname\tTaxonomy files found."
else
	echo -e "$(date)\t$scriptname\tNecessary files not found. Exiting..."
	exit
fi

echo -e "$(date)\t$scriptname\tUnzipping downloads..."
tar xfz "$db_directory/taxdump.tar.gz"
pigz -dc -k "$db_directory/gi_taxid_nucl.dmp.gz" > gi_taxid_nucl.dmp
pigz -dc -k "$db_directory/gi_taxid_prot.dmp.gz" > gi_taxid_prot.dmp

# the below grep "fixes" the issue whereby aliases, mispellings, and other alternate names are returned.
# We could simply look for a name that is a "scientific name",
# but this shrinks the db a bit, speeding up lookups, and removes data we do not need at this time.
echo -e "$(date)\t$scriptname\tRetaining scientific names..."
grep "scientific name" names.dmp > names_scientificname.dmp

echo -e "$(date)\t$scriptname\tStarting creation of taxonomy SQLite databases..."
create_taxonomy_db.py
echo -e "$(date)\t$scriptname\tCompleted creation of taxonomy SQLite databases."

rm *.dmp
rm gc.prt
rm readme.txt