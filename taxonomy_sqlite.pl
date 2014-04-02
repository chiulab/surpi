#!/usr/bin/perl -w
#
#	taxonomy_sqlite.pl
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

use strict;
use Time::HiRes qw[gettimeofday tv_interval];

my $test = 0;
my $time = 0;

if ( @ARGV != 3 ) {
	print "=======================================\n";
	print "USAGE: <taxonomy_sqlite-hash.pl> <blast_file/sam_file> <file_type:blast/sam> <nucl/prot> \n";
	print "=======================================\n";
	print "NOTE: If you have blasted against a protein database, the last parameter will be 'prot', and in case of blasting to a nucleotide database, use 'nucl'\n";
	print "Will read the blast output or SAM output, extract the matched reads and append annotation to the blast/sam file\n";
	print "=======================================\n";
	print "OUTPUT: Look at .matched.summary and .all.annotated files\n";
	exit;
}

my ($ofile, $otype, $seq_type) = @ARGV;

########### Extract gi fom blast output ##################
my $line_count=0;
sub trim($);

print "Storing gis into an array\n" if ($test);

my $ofile_tmp = $ofile;
my $basef_ofile = $ofile;
$basef_ofile =~ s{\.[^.]+$}{};

# Removing the sequence headers from sam file since this can contribute to almost 1GB for viral and bacterial dbs!
if ($otype eq "sam"){
# 	print "Removing ", '@SQ', " headers from sam file since this can be pretty bulky\n";
	system ("sed -i '/^\@SQ/d' $ofile");
}

open (MYID, $ofile) or die $!;
open(GID, ">$basef_ofile.gi");

# Store gi from SAM/blast file
while (my $line = <MYID>){
	chomp($line);
	$line = trim($line);
	next if (($line =~ m/^@/) || ($line =~ m/^#/));
	my ($gi, $id);
	my @items = split(/\t/, $line);

	my $read_id = trim($items[0]);

	# Get gi ids from SAM/blast file
	if ($otype eq "blast"){
		$id = trim($items[1]);
	}
	elsif ($otype eq "sam"){
		# The third element is the gi
		if ($items[2] !~ m/\*/){
			print "Match: ", $items[2], "\n" if ($test);
			$id = trim($items[2]);
		}
		else {
			$id = "";
		}
	}

	if ($id =~ /\|/){
		my @defs = split(/\|/, $id);
    	$gi = trim($defs[1]);
	}
	elsif ($id =~ /^\d+$/ ){
		# if its some integer
		$gi = $id;
	}
	else{
		$gi = "";
	}

	print GID "$gi\n";
}
close(GID);
close(MYID);

#create a unique list of gi, make a hash from that list, use the hash to populate the original nonunique list with tax info
#starting point -> file containing all gi to look up
# 1. uniq the list (in RAM - or in file)
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

my $begintime = [gettimeofday()];

# first try - use UNIX sort on output file
# can later try to optimize this by putting gi's into a list & sorting in RAM
system ("sort -u $basef_ofile.gi > $basef_ofile.gi.uniq");
my $sorttime = tv_interval($begintime);
print "time to sort - u: $sorttime seconds\n";

my %taxonomy;

open (UNIQGI, "$basef_ofile.gi.uniq") or die $!;

my $starthash = [gettimeofday()];

while (<UNIQGI>) {
	chomp;
	my ($family, $genus, $species, $lineage) = ("") x 4;
	my $result = `taxonomy_lookup_embedded.pl -fgsl -d $seq_type $_`;
	
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
	my $count = scalar(keys %taxonomy);

	#provide feedback on hash construction
# 	if ($count % 500 == 0) {print "$count\n";}
}
close (UNIQGI);

my $endhash = tv_interval($starthash);
print "time to create hash: $endhash seconds\n";

my $starttaxwrite = [gettimeofday()];

open (ALLGI, "$basef_ofile.gi") or die $!;
open (FINALTAXOUTPUT, ">$basef_ofile.gi.taxonomy") or die $!;
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

my $elapsedtime = tv_interval($begintime);
print STDERR "total time: $elapsedtime seconds\n";


open (TAXONOMY, "$basef_ofile.gi.taxonomy");
open (SAMFILE, $ofile);
open (OUTALL, ">$basef_ofile.all.annotated");
while (my $sam_line = <SAMFILE>) {
	chomp($sam_line);
	my $tax_line = <TAXONOMY>;
	chomp($tax_line);
	print OUTALL "$sam_line\t$tax_line\n";
}
close(OUTALL);
close(SAMFILE);
close (TAXONOMY);
exit;

sub trim ($){
        my $str = shift;
        $str =~ s/^\s+//;
        $str =~ s/\s+$//;
        return $str;
}
