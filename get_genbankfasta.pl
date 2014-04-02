#!/usr/bin/perl
#
#	get_genbankfasta.pl
#
#	This program retrieves FASTA formatted files from Genbank for a list of gi.
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# Copyright (C) 2014 Scot Federman - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
# Last revised 1/26/2014

use LWP::Simple;
use Getopt::Std;

my $id;
my $url;


my $db = "sequences";
my $rettype = "fasta";
my $retmode = "text";

getopts("hi:o:f:");

if ($opt_f eq "fasta") {
	$rettype = "fasta";
}
elsif ($opt_f eq "docsum" || $opt_f eq "docsum_oneline") {
	$rettype = "docsum";
}
else {$rettype = "fasta"}

if ($opt_h) {
	print <<USAGE;
	
get_genbankfasta.pl

Currently, the maximum number of sequences this program can retrieve in a single run is about 750.
Depending on the sequence sizes, this program may take awhile to download the sequence file.

Usage:

1. To retrieve sequence for a single gi
	get_genbankfasta.pl 149408158

2. To retrieve sequence for a short list of gis from the command line
	get_genbankfasta.pl 149408158 116734707

3. To retrieve multiple sequences from a file of gis
	get_genbankfasta.pl -i gi_list

4. To output to a file, use the -o switch
	get_genbankfasta.pl -o outputfile 149408158 116734707
		note: all command line switches must be present before gi on command line
		
	get_genbankfasta.pl -i gi_list -o outputfile

5. Use the -f switch to select the output type:

	fasta - retrieve FASTA file for gi input
	docsum - retrieve Document Summary for gi input
	docsum_oneline - retrieve Document Summary for gi input & collapse to one line per gi
		
		get_genbankfasta.pl -f docsum_oneline 149408158 410777373
		get_genbankfasta.pl -f fasta -i gi_list
		get_genbankfasta.pl -f docsum_oneline -i gi_list


USAGE
	exit;
}

if ($opt_i) {
	open INPUTFILE, "$opt_i" or die "Couldn't open file: $!";
	while (<INPUTFILE>) {
		chomp;
		$id = $id . " ". $_;
	}
	close (INPUTFILE);
}
else {
	$id="@ARGV";
}

$url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=$db&id=$id&rettype=$rettype&retmode=$retmode";

$result = get($url);
if ($opt_f eq "docsum_oneline") {
	$result =~ s/(\w)\n/\1\t/g;
	$result =~ s/\n\n/\n/g;
	$result =~ s/\n\n/\n/g;
}

if ($opt_o) {
	open OUTPUTFILE, ">$opt_o" or die "Couldn't open file: $!";
	print OUTPUTFILE $result;
	close (OUTPUTFILE);
}
else {
	print $result;
}


