#!/usr/bin/perl
#
#	tweet.pl
#
#	This program will tweet from the command-line. It is used to give reports on pipeline status.
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
#In order to use this script, the consumer_key, consumer_secret, oauth_token, and oauth_token_secret must be filled in with 
#proper values for your chosen Twitter account.
#
# Copyright (C) 2014 Scot Federman - All Rights Reserved
# SURPI has been released under a modified BSD license.
# Please see license file for details.
# Last revised 1/26/2014    

use Net::Twitter::Lite::WithAPIv1_1;
use Scalar::Util 'blessed';

$consumer_key = "";
$consumer_secret = "";
$oauth_token = "";
$oauth_token_secret = "";

$status_update = "$ARGV[0]";

if (! $ARGV[0]) {
	print "Please supply the tweet as a parameter.";
}
my $nt = Net::Twitter::Lite::WithAPIv1_1->new(
    consumer_key        => $consumer_key,
    consumer_secret     => $consumer_secret,
    access_token        => $oauth_token,
    access_token_secret => $oauth_token_secret,
    legacy_lists_api    => 0,
    ssl					=> 1
);
#print "$status_update\n"
$nt->update($status_update);
