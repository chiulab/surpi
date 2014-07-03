#!/bin/bash
#
#	create_SURPI_data.sh
#
#	This program will do the following
#	1. Download databases from NCBI
#	2. Create taxonomy databases
#	3. Create RAPSearch NR database
#	4. Create SNAP-nt indices
#
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# Copyright (C) 2014 Scot Federman - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
# Last revised 7/2/2014  

DATE=$(date +%m%d%Y)
db_dir="NCBI_$DATE"
taxonomy_dir="taxonomy"
RAPSearch_dir="RAPSearch"
SNAP_nt_dir="SNAP_nt"


#download NCBI data to $db_dir
download_SURPI_data.sh -d "$db_dir"

#
##	create taxonomy SQLite dbs and place into $taxonomy_dir
#
if [ ! -d "$taxonomy_dir" ]; then
	mkdir "$taxonomy_dir"
fi

create_taxonomy_db.sh -d "$db_dir"
mv gi_taxid_nucl.db "$taxonomy_dir/gi_taxid_nucl_$DATE.db"
mv gi_taxid_prot.db "$taxonomy_dir/gi_taxid_prot_$DATE.db"
mv names_nodes_scientific.db "$taxonomy_dir/names_nodes_scientific_$DATE.db"

#
##create RAPSearch nr db and move into $RAPSearch_dir
#
if [ ! -d "$RAPSearch_dir" ]; then
	mkdir "$RAPSearch_dir"
fi

pigz -dc -k "$db_directory/nr.gz" > nr
prerapsearch -d nr -n "nr_db_$DATE"
mv nr_db "$RAPSearch_dir"
mv nr_db.info "$RAPSearch_dir"

#
## index SNAP-nt
#
create_snap_to_nt.sh -n 50 -d "$db_dir"
