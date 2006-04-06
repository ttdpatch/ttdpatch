#!/usr/bin/perl

use strict;
use warnings;

my @bits;
$#bits = 255;

open COMMON, "common.h" or die "Can't open common.h: $!";

while (<COMMON>) {
	if (m@^// BEGIN PATCHFLAGS@ .. m@// END PATCHFLAGS@) {
		/^#define\s+([a-z0-9]+)\s+(\d+)\s*/ and $bits[$2] = $1;
	}
}

close COMMON;

my $skip = 1;

while (<>) {
	if (/^\s*u8\s*switchorder\[\]\s*=/ .. /^\s*\};/) {
		s@//.*$@@;
		s/\s//g;
		s/^\{//;
		foreach my $bit (split /,/) {
			($bit =~ /^\d+$/) && defined($bits[$bit]) and $bit = $bits[$bit];
			print "\t$bit,\n";
		}
	}
}
