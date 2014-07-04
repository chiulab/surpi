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
curated_dir="curated_$DATE"
taxonomy_dir="taxonomy"
RAPSearch_dir="RAPSearch"
FAST_dir="FAST_SNAP"
SNAP_nt_dir="SNAP_nt"

#set SNAP index Ofactor. See SNAP documentation for details
Ofactor=1000

#download NCBI data to $db_dir, curated data to $curated_dir
download_SURPI_data.sh -d "$db_dir" -c "$curated_dir"

#
##	create taxonomy SQLite dbs and place into $taxonomy_dir
#
if [ ! -d "$taxonomy_dir" ]; then
	mkdir "$taxonomy_dir"
fi

# create_taxonomy_db.sh -d "$db_dir"
# mv gi_taxid_nucl.db "$taxonomy_dir/gi_taxid_nucl_$DATE.db"
# mv gi_taxid_prot.db "$taxonomy_dir/gi_taxid_prot_$DATE.db"
# mv names_nodes_scientific.db "$taxonomy_dir/names_nodes_scientific_$DATE.db"

#
##create RAPSearch nr db and move into $RAPSearch_dir
#
if [ ! -d "$RAPSearch_dir" ]; then
	mkdir "$RAPSearch_dir"
fi

# pigz -dc -k "$db_directory/nr.gz" > nr
# prerapsearch -d nr -n "nr_db_$DATE"
# mv nr_db "$RAPSearch_dir"
# mv nr_db.info "$RAPSearch_dir"

#
## Index curated data
#

#decompress curated data
echo "Decompressing curated data..."
pigz -dc -k "$curated_dir/Bacterial_Refseq_05172012.CLEAN.LenFiltered.uniq.fa.gz" > Bacterial_Refseq_05172012.CLEAN.LenFiltered.uniq.fa
pigz -dc -k "$curated_dir/hg19_rRNA_mito_Hsapiens_rna.fa.gz" > hg19_rRNA_mito_Hsapiens_rna.fa
pigz -dc -k "$curated_dir/rapsearch_viral_aa_130628_db_v2.12.fasta.gz" > rapsearch_viral_aa_130628_db_v2.12.fasta
pigz -dc -k "$curated_dir/viruses-5-2012_trimmedgi-MOD_addedgi.fa.gz" > viruses-5-2012_trimmedgi-MOD_addedgi.fa

echo "Indexing databases..."
snap index Bacterial_Refseq_05172012.CLEAN.LenFiltered.uniq.fa snap_index_Bacterial_Refseq_05172012.CLEAN.LenFiltered.uniq -s 16 -O$Ofactor
snap index hg19_rRNA_mito_Hsapiens_rna.fa snap_index_hg19_rRNA_mito_Hsapiens_rna -hg19 -O$Ofactor
prerapsearch -d rapsearch_viral_aa_130628_db_v2.12.fasta -n "rapsearch_viral_aa_130628_db_v2.12"
snap index viruses-5-2012_trimmedgi-MOD_addedgi.fa snap_index_viruses-5-2012_trimmedgi-MOD_addedgi -O$Ofactor 

if [ ! -d "$FAST_dir" ]; then
	mkdir "$FAST_dir"
fi

mv snap_index_Bacterial_Refseq_05172012.CLEAN.LenFiltered.uniq $FAST_dir
mv rapsearch_viral_aa_130628_db_v2.12 $RAPSearch_dir
mv snap_index_viruses-5-2012_trimmedgi-MOD_addedgi $FAST_dir

#
## index SNAP-nt
#
# create_snap_to_nt.sh -n 50 -d "$db_dir"
























