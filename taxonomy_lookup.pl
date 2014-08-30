#!/usr/bin/perl -w
#
#	taxonomy_lookup.pl
#
#	This script will parse a SAM/blast file and generate an annotated sam /blast file.
#	It will append the family/genus/species name and the taxonomic lineage tree to the end of each hit/line.
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# Copyright (C) 2014 Scot Federman - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
# Last revised 1/26/2014    

# use strict;
# use diagnostics;
use Time::HiRes qw[gettimeofday tv_interval];
use DBI;

if ( @ARGV != 5 ) {
	print "USAGE: taxonomy_lookup.pl <blast_file/sam_file> <file_type:blast/sam> <nucl/prot> <cores> <taxonomy_reference_directory>\n";
	exit;
}

my ($inputfile, $filetype, $seq_type, $cores, $database_directory) = @ARGV;

my $sql_taxdb_loc_nucl = "$database_directory/gi_taxid_nucl.db";
my $sql_taxdb_loc_prot = "$database_directory/gi_taxid_prot.db";
my $names_nodes        = "$database_directory/names_nodes_scientific.db";
my $begintime = [gettimeofday()];
my $gi_table;
my $sql_taxdb_loc;

my $basef_inputfile = $inputfile;
$basef_inputfile =~ s{\.[^.]+$}{};

# First, extract gi from SAM/BLAST inputfile
if ($filetype eq "sam") {
	system ("awk {'print \$3'} $inputfile | awk -F \"|\" {'print \$2'} > $basef_inputfile.gi");
} elsif ($filetype eq "blast") {
	system ("awk {'print \$2'} $inputfile | awk -F \"|\" {'print \$2'} > $basef_inputfile.gi");
}

if ($seq_type eq "nucl") {
	$gi_table = "GI_Taxa_nucl";
	$sql_taxdb_loc = $sql_taxdb_loc_nucl;
}
elsif ($seq_type eq "prot") {
	$gi_table = "GI_Taxa_prot";
	$sql_taxdb_loc = $sql_taxdb_loc_prot;
}
else {
	print "\nImproper database specified.\n\n";
	exit;
}

my $extracttime = tv_interval($begintime);
print "time to extract gi: $extracttime seconds\n";

#create a unique list of gi, make a hash from that list, use the hash to populate the original nonunique list with tax info
#starting point -> file containing all gi to look up
# 1. uniq the list
# 2. foreach unique gi
#		look up tax info
#		put tax info into hash of hashes like below
# 		%taxonomy = (
# 			149408158	=> {
# 				family		=> "Hominidae",
# 				genus		=> "Homo",
# 				species		=> "sapiens"
# 			},
# 			06292007	=> {
# 				family		=> "Muridae",
# 				genus		=> "Mus",
# 				species		=> "Mus musculus",
# 			},
# 		 );
# 3. lookup taxonomy for original gi within hash & output to .gi.taxonomy file


# sort/uniq gi file
my $startsort = [gettimeofday()];
system ("sort --parallel=$cores -u $basef_inputfile.gi > $basef_inputfile.gi.uniq");
my $sorttime = tv_interval($startsort);
print "time to sort -u: $sorttime seconds\n";

# Parallelization can occur at this point in the code. Since the file in now sorted, it can be split into n chunks 
# with no overlap.
my %taxonomy;

open (UNIQGI, "$basef_inputfile.gi.uniq") or die $!;

my $starthash = [gettimeofday()];

while (<UNIQGI>) {
	chomp;
	my ($family, $genus, $species, $lineage) = ("") x 4;
	my $result = taxonomy_fgsl($_, $seq_type);
	
	if ($result =~ /family--(.*?)\t/) {
		$family = $1;
	}
	
	if ($result =~ /genus--(.*?)\t/) {
		$genus = $1;
	}
	
	if ($result =~ /species--(.*?)\t/) {
		$species = $1;
	}
	
	if ($result =~ /lineage--(.*)$/) {
		$lineage = $1;
	}

	$taxonomy{$_}{"family"} = $family;
	$taxonomy{$_}{"genus"} = $genus;
	$taxonomy{$_}{"species"} = $species;
	$taxonomy{$_}{"lineage"} = $lineage;

	#provide feedback on hash construction
# 	my $count = scalar(keys %taxonomy);
#  	if ($count % 500 == 0) {print "$count\n";}
}
close (UNIQGI);

my $endhash = tv_interval($starthash);
print "time to create hash: $endhash seconds\n";

my $starttaxwrite = [gettimeofday()];

open (ALLGI, "$basef_inputfile.gi") or die $!;
open (FINALTAXOUTPUT, ">$basef_inputfile.gi.taxonomy") or die $!;
while (my $gi = <ALLGI>) {
	chomp $gi;
	print FINALTAXOUTPUT "$gi\t";
	print FINALTAXOUTPUT "family--$taxonomy{$gi}{\"family\"}\t";
	print FINALTAXOUTPUT "genus--$taxonomy{$gi}{\"genus\"}\t";
	print FINALTAXOUTPUT "species--$taxonomy{$gi}{\"species\"}\t";
	print FINALTAXOUTPUT "lineage--$taxonomy{$gi}{\"lineage\"}\n";
}
close (ALLGI);
close (FINALTAXOUTPUT);

my $endtaxwrite = tv_interval($starttaxwrite);
print "time to write taxonomy file: $endtaxwrite seconds\n";

my $startannotatedwrite = [gettimeofday()];

open (TAXONOMY, "$basef_inputfile.gi.taxonomy");
open (SAMFILE, "$inputfile");
open (OUTALL, ">$basef_inputfile.all.annotated");
while (my $sam_line = <SAMFILE>) {
	chomp($sam_line);
	my $tax_line = <TAXONOMY>;
	chomp($tax_line);
	print OUTALL "$sam_line\t$tax_line\n";
}
close(OUTALL);
close(SAMFILE);
close (TAXONOMY);

my $annotatedtime = tv_interval($starttaxwrite);
print "time to write annotated file: $annotatedtime seconds\n";

my $elapsedtime = tv_interval($begintime);
print "total time: $elapsedtime seconds\n";

exit;

sub trim ($){
        my $str = shift;
        $str =~ s/^\s+//;
        $str =~ s/\s+$//;
        return $str;
}

sub taxonomy_fgsl {
	my ($gi, $seq_type) = @_;

	my $taxid;
	
	my $lineage = "";
	my $name;
	my $gi_count = 0;
	my %rank_to_print;
	my $taxonomy;

	$rank_to_print{family} = "1";
	$rank_to_print{genus} = "1";
	$rank_to_print{species} = "1";

	my $db = DBI->connect("dbi:SQLite:dbname=$sql_taxdb_loc", "", "", {RaiseError => 1, AutoCommit => 1}) or die $DBI::errstr;
	my $names_nodes_db = DBI->connect("dbi:SQLite:dbname=$names_nodes", "", "", {RaiseError => 1, AutoCommit => 1}) or die $DBI::errstr;

	my $sth;
	my $row;

	my $begintime = [gettimeofday()];
	my $numeric_lineage ="";

	# convert gi -> taxid
	my $ary = $db->selectrow_arrayref("SELECT taxid FROM gi_taxid WHERE gi = $gi LIMIT 1");
	if ($ary){
		$taxid = trim($ary->[0]);
	}
	$taxonomy = "$gi\t";

	if ($taxid) {
		while ($taxid > 1) {
			# Obtain the scientific name corresponding to a taxid
			my $name_return = $names_nodes_db->selectrow_arrayref("SELECT name FROM names WHERE taxid = $taxid LIMIT 1");
			# Obtain the parent taxa taxid
			# nodes table: taxid - parent_tax id - rank
			$sth = $names_nodes_db->prepare("SELECT * FROM nodes WHERE taxid = $taxid LIMIT 1");
			$sth->execute();
			if ($sth) {
				$row = $sth->fetchrow_arrayref();
				(my $tid, my $parent, my $rank) = @$row;
		
				if ($name_return){
					$name = trim($name_return->[0]);
				}
				# print the rank if specified on the command line
				if (exists($rank_to_print{$rank})) {
					$taxonomy = $taxonomy."$rank--$name\t";
				}
				# Build the taxonomy path
				$lineage = "$name;$lineage";
				$numeric_lineage = "$tid "."$numeric_lineage ";
				$taxid="$parent";
			}
		}
	}
	$taxonomy = $taxonomy."lineage--$lineage";
# 	print "$numeric_lineage" if $test;

	my $elapsedtime = tv_interval($begintime);
	return $taxonomy;
}
