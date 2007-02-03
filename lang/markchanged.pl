#!/bin/perl
#
# Output: Tags all texts in all other languages that have been changed in english.h,
#	as determined by reading the output of svn diff as run in line 35.
# 
# Special instructions: 
# Must be run from the lang directory.
# Do not use when lines have been added to halflines or LANG_FULLSWITCHES.

use warnings;
use strict;
use Tie::File;

sub findtag ($$$@) {
	my ($name, $line, $max, @txt) = @_;
	#print "$max\n";
	for (0 .. $max-1) {
		#printf "%d:$txt[$line+$k]\n", $line+$_+1;
		#printf "%d:$txt[$line-$k]\n", $line-$_+1;		
		return -$_ if $txt[$line+$_] =~ /"\\n"/;
		return $_ if $txt[$line-$_] =~ /"\\n"/ or $txt[$line-$_] =~ /\Q$name/;
	}
	return undef;
}

my $line=0;	# 1-based line number in english.h of changed text in the diff
my $def;	# 0-based line number in english.h of *TEXT(NAME line
my @eng;	# tied to english.h
my @lang;	# tied to each <lang>.h, in sequence
my %texts;	# contains *TEXT(NAME => (x, y1, y2, ...) where:
		#	x is $def for *TEXT(NAME
		#	yn is the changed line, 0-based offset from x.

tie @eng, 'Tie::File', "english.h" or die "Can't open english.h\n";
open STDIN, "svn diff english.h |" or die "svn diff english.h failed";

while(<>){
	next if /^-/;
	$line++;
	die "svn diff did not produce an svn diff:\n$_" unless /^([+ I=]|@@)/;
	$line = $1 - 1 if /^@@ -\d+,\d+ \+(\d+)/;
	next unless /^\+/;
	next if /^\+{3} english.h\t/;
	if (/^\+\w+\((\w+),/) {
		#print "$line:$1\n";
		$texts{$1}=[$line-1,0];
		next;
	}
	next if m#^\+\s*//# or /^$/;
	$def = $line-1;
	until ( $eng[--$def] =~ /^\w+\((\w+),/ ) {
		#printf "%d:$english[$def]\n", $def+1;
		die "Changed line $line is before first text.\n" if !$def;
	}
	#printf "%d:$eng[$def]\n", $def+1;
	$eng[$def] =~ /^\w+\((\w+),/;
	#printf "%d:%d:$1\n", $def+1, $line;
	if ($texts{$1}) {
		push @{$texts{$1}}, $line-$def-1;
	} else {
		$texts{$1}=[$def,$line-$def-1];
	}
}

die "No changes detected.\n" unless keys %texts;

while(<*.h>){
	next if $_ eq "english.h";
	tie @lang, 'Tie::File', $_ or die "Can't open $_\n";
	print "Updating $_\n";
	for (0 .. @lang-1) {
		next unless $lang[$_] =~ /^\w+\((\w+),/ and $texts{$1};
		#print "  Found $1 near line $_\n";
		my ($eng, $name, $oldoff) = (${$texts{$1}}[0], $1, undef);
		for my $i (1 .. @{$texts{$name}} - 1) {
			my $j = ${$texts{$name}}[$i];
			if ($j) {
				my $k = findtag($name, $eng + $j, $j, @eng);
				#print "    English offset from nearest tag: $k\n";
				if ($k) {
					my $l = findtag($name, $_ + $j, (abs($k)+1)*2, @lang);
					#print "    Translated offset from nearest tag: $l\n" if defined $l;
					if (!defined $l or abs(($k <=> 0) - ($l <=> 0)) == 2) {
						$j += $oldoff if defined $oldoff;
						printf "  Could not verify adjustment for changed line %d of english.h.\n".
							"  Tagging line %d.\n", $eng+$j+1, $_+$j+1;
					} else {
						#printf "    Moving offset from $j to %d.\n", $j + $k - $l;
						$j += ($oldoff = $k - $l);
					}
				}
			}
			$lang[$_+$j] = "/***/" . $lang[$_+$j] unless  $lang[$_+$j] =~ m#/\*{3}/#;
		}
	}
	untie @lang;
}

untie @eng;