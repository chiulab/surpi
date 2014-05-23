#!/usr/bin/perl
#
#	create_tab_delimited_table.pl
#
#	This program will return a simpler version of a SNAP or RAP output file that has been produced via the SURPI pipeline.
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# Copyright (C) 2014 Scot Federman - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
# Last revised 1/26/2014  

use Getopt::Std;
use strict;

our ($opt_f, $opt_h);

getopts('f:h');

if ($opt_h) {
	print <<USAGE;
	
create_tab_delimited_table.pl

This program will return a simpler version of a SNAP or RAP output file that has been produced via the SURPI pipeline.
Output file is in the following format:

	header	gi	species	genus	family
	

Usage:

create_tab_delimited_table.pl -f RAP sample8.Ecutoff1.virus.RAPSearch.annotated.sorted

create_tab_delimited_table.pl -f SNAP sample8.NT.snap.matched.Viruses.sorted

Command Line Switches:

	-f	Specify SNAP/RAP input format
	
USAGE
	exit;
}
while (<>) {
	my ($species, $genus, $family) = ("") x 3;
	my @columns = split/\t/, $_;
	if (/species--(.*?)\t/) {
		$species = $1;
	}
	if (/genus--(.*?)\t/) {
		$genus = $1;
		}
	if (/family--(.*?)\t/) {
		$family = $1;
	}
	if ($opt_f eq "SNAP") {
		print "$columns[0]\t$columns[2]\t";
	}
	else {
		$columns[1] =~ /(gi\|\d+\|)/;
		print "$columns[0]\t$1\t";
	}
	print "$species\t$genus\t$family\n";
}
