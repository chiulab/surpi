#!/usr/bin/perl
#split_fasta.pl version 1.0
#This script accepts a file consisting of multiple FASTA formatted sequence records.
#It splits the file into multiple new files, each consisting of a subset of the original records.
#
#There are three command line options:
#
#-i input file.
#-o output file prefix. This script will append numbers to this prefix name so that each created file is unique.
#-n the number of sequences to place in each output file.
#
#Example usage:
#
#perl split_fasta.pl -i sample_in.txt -o new_sequences -n 100
#
#Written by Paul Stothard, Canadian Bioinformatics Help Desk.
#
#stothard@ualberta.ca

use strict;
use warnings;

#Command line processing.
use Getopt::Long;

my $inputFile;
my $outputFile;
my $numberToCopy;

Getopt::Long::Configure ('bundling');
GetOptions ('i|input_file=s' => \$inputFile,
	        'o|output_file_prefix=s' => \$outputFile,
	    'n|number=i' => \$numberToCopy);

if(!defined($inputFile)) {
    die ("Usage: split_fasta.pl -i <input file> -o <output file> -n <number of sequences to write per file>\n");
}

if(!defined($outputFile)) {
    die ("Usage: split_fasta.pl -i <input file> -o <output file> -n <number of sequences to write per file>\n");
}

if(!defined($numberToCopy)) {
    die ("Usage: split_fasta.pl -i <input file> -o <output file> -n <number of sequences to write per file>\n");
}

if ($numberToCopy <= 0) {
    die ("-n value must be greater than 0.\n");
}

#count the number of sequences in the file
#read each record from the input file

my $seqCount = 0;
my $fileCount = 0;
my $seqThisFile = 0;

open (OUTFILE, ">" . $outputFile . "_" . $fileCount) or die ("Cannot open file for output: $!");

open (SEQFILE, $inputFile) or die( "Cannot open file : $!" );
$/ = ">";

while (my $sequenceEntry = <SEQFILE>) {

    if ($sequenceEntry =~ m/^\s*>/){
		next;
    }

    my $sequenceTitle = "";
    if ($sequenceEntry =~ m/^([^\n]+)/){
		$sequenceTitle = $1;
    }
    else {
		$sequenceTitle = "No title was found!";
    }

    $sequenceEntry =~ s/^[^\n]+//;
    $sequenceEntry =~ s/[^A-Za-z]//g;

    #write record to file
    print (OUTFILE ">$sequenceTitle\n");
    print (OUTFILE "$sequenceEntry\n");
    $seqCount++;   
    $seqThisFile++;

    if ($seqThisFile == $numberToCopy) {
		$fileCount++;
		$seqThisFile = 0;
		close (OUTFILE) or die( "Cannot close file : $!");
		open (OUTFILE, ">" . $outputFile . "_" . $fileCount) or die ("Cannot open file for output: $!");
    }

}#end of while loop

close (SEQFILE) or die( "Cannot close file : $!");

close (OUTFILE) or die( "Cannot close file : $!");

