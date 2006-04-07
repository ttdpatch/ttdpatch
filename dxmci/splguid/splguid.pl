#!/usr/bin/perl -w
#
# Split a .c file containing many GUID definitions into
# many .c files, one for for each GUID.
#
# This allows the linker to only include those GUIDs that
# are actually needed.
#
# SYNOPSIS: perl splguid.pl <input>.c [<input2>.c ...]
#
# Splits the input file(s), and puts the resulting files in 
# one directory for each input.
#

use strict;

for my $file (@ARGV) {

$file =~ s/.c$// or die "Not a .c file: $file";

open C, "<$file.c" or die "Can't read $file.c: $!";

my @GUIDS;
my ($pre,$post);

while (<C>) {
	# strip //-style comments
	s#//.*$##;

	if (/GUID\(/) {
		push @GUIDS, $_ 
	} else {
		$pre .= $_;
	}
}

# make a file in $file/ for each guid

mkdir $file unless -d $file;

my %UIDS;
for (@GUIDS) {
	my ($guid) = /GUID\((.*?),/;
	die "Duplicate GUID $guid in $file" if exists $UIDS{$guid};
	$UIDS{$guid}++;

	$guid = "$file/$guid.c";
	print "Making $guid\n";
	open G, ">$guid" or die "Can't write $guid: $!";
	print G $pre, $_;
	close G;
}

}
