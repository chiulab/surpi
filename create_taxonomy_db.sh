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
# Last revised 1/26/2014  

START=$(date +%s)
curl -O "ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz"
curl -O "ftp://ftp.ncbi.nih.gov/pub/taxonomy/gi_taxid_nucl.dmp.gz"
curl -O "ftp://ftp.ncbi.nih.gov/pub/taxonomy/gi_taxid_prot.dmp.gz"

tar xfz taxdump.tar.gz
gunzip -c gi_taxid_nucl.dmp.gz > gi_taxid_nucl.dmp
gunzip -c gi_taxid_prot.dmp.gz > gi_taxid_prot.dmp

# the below grep "fixes" the issue whereby aliases, mispellings, and other alternate names are returned. We could simply look for a name that is a "scientific name"
# but this shrinks the db a bit, speeding up lookups, and removes data we do not need at this time.
grep "scientific name" names.dmp > names_scientificname.dmp

END=$(date +%s)
downloadtime=$(( $END - $START ))
echo "file download took $downloadtime seconds"

START=$(date +%s)
create_taxonomy_db.py
END=$(date +%s)
db_construct_time=$(( $END - $START ))
echo "database construction took $db_construct_time seconds"

rm *.dmp
rm gc.prt
rm readme.txt