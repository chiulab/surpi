#!/usr/bin/env perl
#
#	taxonomy_lookup_embedded.pl
#
#	This program will take a gi (or list of gis) as input, and return taxonomic information.
#	Chiu Laboratory
#	University of California, San Francisco
#
# Copyright (C) 2014 Scot Federman - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
# Last revised 1/26/2014

use DBI;
use warnings;
use strict;
use Getopt::Std;
use Time::HiRes qw[gettimeofday tv_interval];

my $test = 0;

my $seq_type;
my $gi_table;
my $sql_taxdb_loc;
my $taxid;

# my $database_directory = "/reference/taxonomy";
my $lineage="";
my $name;
my $gi;
my $gi_count = 0;
sub trim($);
my %rank_to_print;
our ($opt_q, $opt_d, $opt_k, $opt_p, $opt_c, $opt_o, $opt_f, $opt_g, $opt_s, $opt_l, $opt_h, $opt_x);

getopts('q:d:kpcofgslhx');

if ($opt_h) {
	print <<USAGE;

taxonomy_lookup_embedded.pl

This program will query the NCBI taxonomic database and return whatever taxonomy is requested for a gi, or list of gis. The
returned data will be in tabular format, and will be in the following order.

	species	genus	family	order	class	phylum	kingdom

Usage:

To look up taxonomy for a file containing gi
	taxonomy_lookup_embedded.pl -kpcofgsx -d nucl -q "/reference/taxonomy" 149408158

Command Line Switches:

	-h	Show help & ignore all other switches
	-q	folder containing taxonomy databases
		This folder should contain the 3 SQLite files created by the script "create_taxonomy_db.sh"
			gi_taxid_nucl.db - nucleotide db of gi/taxonid
			gi_taxid_prot.db - protein db of gi/taxonid
			names_nodes_scientific.db - db of taxonid/taxonomy

	-d	nucl/prot
		This specifies whether the gi list are nucleotides or protein. It is a required parameter.

	The following switches all will specify which taxonomic information will be returned.
	-k	Kingdom
	-p	Phylum
	-c	Class
	-o	Order
	-f	Family
	-g	Genus
	-s	Species
	-l	Lineage
	-x	Display Taxid in output table

USAGE
	exit;
}

my $database_directory = $opt_q;
my $sql_taxdb_loc_nucl = "$database_directory/gi_taxid_nucl.db";
my $sql_taxdb_loc_prot = "$database_directory/gi_taxid_prot.db";
my $names_nodes = "$database_directory/names_nodes_scientific.db";

if ($opt_k) {$rank_to_print{kingdom} = "1";}
if ($opt_p) {$rank_to_print{phylum} = "1";}
if ($opt_c) {$rank_to_print{class} = "1";}
if ($opt_o) {$rank_to_print{order} = "1";}
if ($opt_f) {$rank_to_print{family} = "1";}
if ($opt_g) {$rank_to_print{genus} = "1";}
if ($opt_s) {$rank_to_print{species} = "1";}

if ($opt_d eq "nucl") {
	$gi_table = "GI_Taxa_nucl";
	$sql_taxdb_loc = $sql_taxdb_loc_nucl;
}
elsif ($opt_d eq "prot") {
	$gi_table = "GI_Taxa_prot";
	$sql_taxdb_loc = $sql_taxdb_loc_prot;
}
else {
	print "\nImproper database specified. Please use nucl or prot with the -d switch.\n\n";
	exit;
}

my $db = DBI->connect("dbi:SQLite:dbname=$sql_taxdb_loc", "", "", {RaiseError => 1, AutoCommit => 1}) or die $DBI::errstr;
my $names_nodes_db = DBI->connect("dbi:SQLite:dbname=$names_nodes", "", "", {RaiseError => 1, AutoCommit => 1}) or die $DBI::errstr;

my $sth;
my $row;

my $begintime = [gettimeofday()];
my $numeric_lineage ="";

$gi = $ARGV[0];
$lineage = "";
chomp $gi;
# convert gi -> taxid
my $ary = $db->selectrow_arrayref("SELECT taxid FROM gi_taxid WHERE gi = \"$gi\" LIMIT 1");
if ($ary){
	$taxid = trim($ary->[0]);
}
print "$gi\t";

if ($taxid) {
	print "$taxid\t" if ($opt_x);
	while ($taxid > 1) {
		# Obtain the scientific name corresponding to a taxid
		my $name_return = $names_nodes_db->selectrow_arrayref("SELECT name FROM names WHERE taxid = $taxid LIMIT 1");
		# Obtain the parent taxa taxid
		# nodes table: taxid - parent_tax id - rank
		$sth = $names_nodes_db->prepare("SELECT * FROM nodes WHERE taxid = $taxid LIMIT 1");
		$sth->execute();
		$row = $sth->fetchrow_arrayref();
		(my $tid, my $parent, my $rank) = @$row;
		if ($name_return){
			$name = trim($name_return->[0]);
		}
		# print the rank if specified on the command line
		if (exists($rank_to_print{$rank})) {
			print "$rank--$name\t";
		}
		# Build the taxonomy path
		$lineage = "$name;$lineage";
		$numeric_lineage = "$tid "."$numeric_lineage ";
		$taxid="$parent";
	}
}
print "lineage--$lineage" if $opt_l;
print "$numeric_lineage" if $test;

print "\n";

my $elapsedtime = tv_interval($begintime);

sub trim ($){
        my $str = shift;
        $str =~ s/^\s+//;
        $str =~ s/\s+$//;
        return $str;
}
