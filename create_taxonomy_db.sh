#!/bin/bash
#
#	create_taxonomy_db.sh
#
# 	This script will create the taxonomy SQLite database using NCBI downloadable files
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# Copyright (C) 2014 Scot Federman - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
# Last revised 6/24/2014  

START_download=$(date +%s)

#check if all 3 files are present
if [ -f taxdump.tar.gz ] && [ -f gi_taxid_nucl.dmp.gz ] && [ -f gi_taxid_prot.dmp.gz ]; then
	echo "Necessary files have already been downloaded from NCBI."
else
	echo "Downloading taxonomy files from NCBI."
	curl -O "ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz"
	curl -O "ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz.md5"

	md5sum -c --status taxdump.tar.gz.md5
	if [ $? -ne 0 ]; then
		echo "md5check of taxdump.tar.gz failed."
		exit
	else
		echo "md5sum of taxdump.tar.gz: OK"
	fi

	# the below 2 files do not appear to have an md5 available
	curl -O "ftp://ftp.ncbi.nih.gov/pub/taxonomy/gi_taxid_nucl.dmp.gz"
	curl -O "ftp://ftp.ncbi.nih.gov/pub/taxonomy/gi_taxid_prot.dmp.gz"
fi

END_download=$(date +%s)
downloadtime=$(( END_download - $START_download ))
echo "file download took $downloadtime seconds"

echo "unzipping downloads"
tar xfz taxdump.tar.gz
gunzip -c gi_taxid_nucl.dmp.gz > gi_taxid_nucl.dmp
gunzip -c gi_taxid_prot.dmp.gz > gi_taxid_prot.dmp

# the below grep "fixes" the issue whereby aliases, mispellings, and other alternate names are returned.
# We could simply look for a name that is a "scientific name", 
# but this shrinks the db a bit, speeding up lookups, and removes data we do not need at this time.
echo "retaining scientific names..."
grep "scientific name" names.dmp > names_scientificname.dmp

START_indexing=$(date +%s)
create_taxonomy_db.py
END_indexing=$(date +%s)
db_construct_time=$(( END_indexing - START_indexing ))
echo "database construction took $db_construct_time seconds"

rm *.dmp
rm gc.prt
rm readme.txt