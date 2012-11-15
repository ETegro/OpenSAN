#!/usr/bin/perl

use warnings;
use strict;

use Time::HiRes qw( usleep );

my $INTERVAL = 250;
$INTERVAL *= 1000; # Microseconds

sub showframe {
	open FD, "< frame$_[0].txt";
	while(<FD>){ print };
	close FD;
	usleep $INTERVAL;
};

while(1){
	showframe 1;
	showframe 2;
	showframe 3;
	showframe 4;
};
