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
# Last revised 7/7/2014

scriptname=${0##*/}
green='\e[0;32m'
red='\e[0;31m'
endColor='\e[0m'

DATE=$(date +%m%d%Y)
echo $DATE > DATE.txt
db_dir="NCBI"
curated_dir="curated"

cleanup_dir="rawdata"

#These parameters specify the folder names for the final databases.
# $reference_dir is the top level folder name
# the rest will be created within $reference_dir
#You should likely stick with the default values here. If changing them, then the corresponding
#values will also need to be changed within the SURPI config file.
reference_dir="reference"
subtraction_dir="Subtraction_SNAP"
taxonomy_dir="taxonomy"
RAPSearch_dir="RAPSearch"
FAST_dir="FAST_SNAP"
SNAP_nt_dir="COMP_SNAP"
RiboClean_dir="RiboClean_SNAP"

# SNAP_nt_chunks=  # of chunks to split nt into, SNAP index will be created for each chunk.
# Currently, the minimum number of chunks is around 17-20
# SNAP 0.15.4 will not successfully index nt with less than 17 chunks, though this will vary a bit with each NT release.
# I picked 20 here as a safe default.
# This will likely have to be increased when using SNAP 1.0, which has different indexing characteristics,
# and may not allow its individual chunks to be as large as SNAP 0.15.4.
# This number may be able to be reduced if manually curating NT to reduce the number of sequences.
SNAP_nt_chunks="20"

if [ ! -d "$reference_dir" ]; then
	mkdir "$reference_dir"
fi

#download NCBI data to $db_dir, curated data to $curated_dir
echo -e "$(date)\t$scriptname\tdownload_SURPI_data.sh -d $db_dir -c $curated_dir"
download_SURPI_data.sh -d "$db_dir" -c "$curated_dir"

#
##	create taxonomy SQLite dbs and place into $taxonomy_dir
#
if [ ! -d "$reference_dir/$taxonomy_dir" ]; then
	mkdir "$reference_dir/$taxonomy_dir"
fi

create_taxonomy_db.sh -d "$db_dir"
mv gi_taxid_nucl.db "$reference_dir/$taxonomy_dir/gi_taxid_nucl.db"
mv gi_taxid_prot.db "$reference_dir/$taxonomy_dir/gi_taxid_prot.db"
mv names_nodes_scientific.db "$reference_dir/$taxonomy_dir/names_nodes_scientific.db"

#
##create RAPSearch nr db and move into $RAPSearch_dir
#
if [ ! -d "$reference_dir/$RAPSearch_dir" ]; then
	mkdir "$reference_dir/$RAPSearch_dir"
fi

echo -e "$(date)\t$scriptname\tDecompressing nr..."
pigz -dc -k "$db_dir/nr.gz" > nr

echo -e "$(date)\t$scriptname\tStarting prerapsearch on nr..."
prerapsearch -d nr -n "rapsearch_nr_db_v2.12"
echo -e "$(date)\t$scriptname\tCompleted prerapsearch on nr."
mv rapsearch_nr_db_v2.12 "$reference_dir/$RAPSearch_dir"
mv rapsearch_nr_db_v2.12.info "$reference_dir/$RAPSearch_dir"

#
## Index curated data
#

#decompress curated data
echo -e "$(date)\t$scriptname\tDecompressing curated data..."

pigz -dc -k "$curated_dir/Bacterial_Refseq_05172012.CLEAN.LenFiltered.uniq.fa.gz" > Bacterial_Refseq_05172012.CLEAN.LenFiltered.uniq.fa
pigz -dc -k "$curated_dir/hg19_rRNA_mito_Hsapiens_rna.fa.gz" > hg19_rRNA_mito_Hsapiens_rna.fa
pigz -dc -k "$curated_dir/rapsearch_viral_aa_130628_db_v2.12.fasta.gz" > rapsearch_viral_aa_130628_db_v2.12.fasta
pigz -dc -k "$curated_dir/viruses-5-2012_trimmedgi-MOD_addedgi.fa.gz" > viruses-5-2012_trimmedgi-MOD_addedgi.fa

#Riboclean additions
pigz -dc -k "$curated_dir/18s_rRNA_gene_not_partial.fa.gz" > 18s_rRNA_gene_not_partial.fa
pigz -dc -k "$curated_dir/23s.fa.gz" > 23s.fa
pigz -dc -k "$curated_dir/28s_rRNA_gene_NOT_partial_18s_spacer_5.8s.fa.gz" > 28s_rRNA_gene_NOT_partial_18s_spacer_5.8s.fa
pigz -dc -k "$curated_dir/rdp_typed_iso_goodq_9210seqs.fa.gz" > rdp_typed_iso_goodq_9210seqs.fa

echo -e "$(date)\t$scriptname\tIndexing curated data..."

echo -e "$(date)\t$scriptname\tSNAP indexing hg19_rRNA_mito_Hsapiens_rna.fa..."
snap index hg19_rRNA_mito_Hsapiens_rna.fa snap_index_hg19_rRNA_mito_Hsapiens_rna -hg19 -locationSize 5
echo -e "$(date)\t$scriptname\tSNAP indexing Bacterial_Refseq_05172012.CLEAN.LenFiltered.uniq.fa..."
snap index Bacterial_Refseq_05172012.CLEAN.LenFiltered.uniq.fa snap_index_Bacterial_Refseq_05172012.CLEAN.LenFiltered.uniq_s16 -s 16 -locationSize 5
echo -e "$(date)\t$scriptname\tStarting prerapsearch on rapsearch_viral_aa_130628_db_v2.12.fasta..."
prerapsearch -d rapsearch_viral_aa_130628_db_v2.12.fasta -n "rapsearch_viral_aa_130628_db_v2.12"
echo -e "$(date)\t$scriptname\tSNAP indexing viruses-5-2012_trimmedgi-MOD_addedgi.fa..."
snap index viruses-5-2012_trimmedgi-MOD_addedgi.fa snap_index_viruses-5-2012_trimmedgi-MOD_addedgi -locationSize 5

#RiboClean additions
if [ ! -d "$reference_dir/$RiboClean_dir" ]; then
	mkdir "$reference_dir/$RiboClean_dir"
fi

echo -e "$(date)\t$scriptname\tSNAP indexing 18s_rRNA_gene_not_partial.fa..."
snap index 18s_rRNA_gene_not_partial.fa snap_index_18s_rRNA_gene_not_partial.fa -locationSize 5
echo -e "$(date)\t$scriptname\tSNAP indexing viruses-5-2012_trimmedgi-MOD_addedgi.fa..."
snap index 23s.fa snap_index_23sRNA -locationSize 5
echo -e "$(date)\t$scriptname\tSNAP indexing rdp_typed_iso_goodq_9210seqs.fa..."
snap index 28s_rRNA_gene_NOT_partial_18s_spacer_5.8s.fa snap_index_28s_rRNA_gene_NOT_partial_18s_spacer_5.8s.fa -locationSize 5
echo -e "$(date)\t$scriptname\tSNAP indexing viruses-5-2012_trimmedgi-MOD_addedgi.fa..."
snap index rdp_typed_iso_goodq_9210seqs.fa snap_index_rdp_typed_iso_goodq_9210seqs -locationSize 5

if [ ! -d "$reference_dir/$FAST_dir" ]; then
	mkdir "$reference_dir/$FAST_dir"
fi

if [ ! -d "$reference_dir/$subtraction_dir" ]; then
	mkdir "$reference_dir/$subtraction_dir"
fi

echo -e "$(date)\t$scriptname\tMoving curated data into place..."
mv snap_index_hg19_rRNA_mito_Hsapiens_rna "$reference_dir/$subtraction_dir"
mv snap_index_Bacterial_Refseq_05172012.CLEAN.LenFiltered.uniq_s16 "$reference_dir/$FAST_dir"
mv rapsearch_viral_aa_130628_db_v2.12 "$reference_dir/$RAPSearch_dir"
mv rapsearch_viral_aa_130628_db_v2.12.info "$reference_dir/$RAPSearch_dir"
mv snap_index_viruses-5-2012_trimmedgi-MOD_addedgi "$reference_dir/$FAST_dir"

mv snap_index_18s_rRNA_gene_not_partial.fa "$reference_dir/$RiboClean_dir"
mv snap_index_23sRNA "$reference_dir/$RiboClean_dir"
mv snap_index_28s_rRNA_gene_NOT_partial_18s_spacer_5.8s.fa "$reference_dir/$RiboClean_dir"
mv snap_index_rdp_typed_iso_goodq_9210seqs "$reference_dir/$RiboClean_dir"

#
## index SNAP-nt
#
if [ ! -f "nt" ]; then
	echo -e "$(date)\t$scriptname\tDecompressing nt..."
	pigz -dc -k "$db_dir/nt.gz" > nt
else
	echo -e "$(date)\t$scriptname\tnt database present, and already decompressed."
fi
echo -e "$(date)\t$scriptname\tStarting indexing of SNAP-nt..."
echo -e "$(date)\t$scriptname\tcreate_snap_to_nt.sh -n $SNAP_nt_chunks -f nt"
create_snap_to_nt.sh -n "$SNAP_nt_chunks" -f "nt" -p "prefix"
echo -e "$(date)\t$scriptname\tCompleted indexing of SNAP-nt."

if [ ! -d "$reference_dir/$SNAP_nt_dir" ]; then
	mkdir "$reference_dir/$SNAP_nt_dir"
fi

mv "snap_index_prefix.nt."* "$reference_dir/$SNAP_nt_dir"

#
## Cleanup
#

if [ ! -d "$cleanup_dir" ]; then
	mkdir "$cleanup_dir"
fi

mv *.fa "$cleanup_dir"
mv *.fasta "$cleanup_dir"
mv nr "$cleanup_dir"
mv nt "$cleanup_dir"
mv "prefix"* "$cleanup_dir"

echo -e "$(date)\t$scriptname\t${green}Completed creation of SURPI reference data.${endColor}"
