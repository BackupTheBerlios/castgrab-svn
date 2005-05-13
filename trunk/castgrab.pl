#!/usr/bin/perl
#-------------------------------------------------------#
#  CastGrab - a Podcast grabber in Perl			#
#                                                       #
#  Brad Peters <brad@fubarpa.com>			#
#=======================================================#
#                                                       #
# This script is free software; you can redistribute it # 
# and/or modify it under the same terms as Perl itself. #
#-------------------------------------------------------#
use strict;
use warnings;

use XML::DOM;
use LWP::UserAgent;

##  Modify these as needed:
my $homedir = $ENV{'HOME'};			#  Your home dir (no trialing /)
my $savedir = "$homedir/media/podcasts/";	#  Where to save podcasts

## -----------------------------------------------------------------------------
my $logfile = "$homedir/.castgrab/castgrab.log";
my $subscriptions = "$homedir/.castgrab/subscriptions";
my $historyfile = "$homedir/.castgrab/history";

#  Fire up LWP and grab any proxy settings, if applicable
my $lwp = LWP::UserAgent->new;
$lwp->env_proxy;
$lwp->agent('CastGrab/0.02 ');    # same as above

my $parser = new XML::DOM::Parser

open (LOG, ">>$logfile") or die "Cannot open $logfile: $!";
open (FEEDS, "<$subscriptions") or die "Cannot open $subscriptions: $!";
open (HISTORY, "<$historyfile") or die "Cannot open $historyfile: $!";
my @previousitems = <HISTORY>;


close HISTORY;

while (<FEEDS>) {
	chomp $_;
	my ($feedname, $feedurl) = split (/::/, $_);
	writelog("Processing $feedname");
	my $feed = $parser->parsefile($feedurl);
	my $itemno = 0;
	foreach my $feeditem ($feed->getElementsByTagName('item')) {
		my $enclosure = $feed->getElementsByTagName ("enclosure")->item($itemno);
		if ($enclosure) {
			my $itemurl = $enclosure->getAttributeNode ("url")->getNodeValue;
			$itemurl =~ m!.*/([\w.]+.mp3)!;
			my $itemfile = $1;
			my $dupefile;
			if (!$itemfile) {
				$dupefile = 1;
			} else {
				foreach (@previousitems) {
					if ($itemfile eq $_) { 
						$dupefile = 1;
					}
				}
			}
			if (!$dupefile) {
				$lwp->mirror( $itemurl, "$savedir$itemfile" );
				writelog("-- Downloaded $savedir$itemfile");
				my $timestamp = localtime;
				open (HISTORY, ">>$historyfile") or die "Cannot open $historyfile : $1";
				print HISTORY "$itemfile\n";
				close HISTORY;
			} else {
				if ($itemfile) {
					writelog("-- Skipping previously downloaded file: $itemfile");
				}
			}
		}
		$itemno++
	}
}
close FEEDS;
close LOG;

sub writelog {
	my ($entry) = @_;
	my $timestamp = localtime;
	print LOG "[$timestamp] $entry\n";
}
