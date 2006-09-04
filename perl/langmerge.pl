#!/usr/bin/perl
#
# Merge missing switch descriptions from English.
#
# Input: lang/english.h, lang/<lang>.h
# Output: lang/<lang>.tmp, to be #included by proclang.c
#

use strict;
use warnings;

# sort -l, -L, -2, -Xl, -XL, -Yl, -YL, ...
# strategy: convert to -L, -l, -A2, -XL, -Xl, -YL, -Yl, ... then check length first.

sub convert ($) {
	my $sw = $_[0];
	if ((length($sw) > 2) && ($sw !~ /-[XYZ]/)){
		$sw = substr $sw, 0, 2;
	}
	$sw =~ s/-(\d)/-a$1/;
	if ($sw =~ /-[a-z]/ or $sw =~ /-[XYZ][a-z]/) {
		$sw = uc $sw;
	} else {
		$sw =~ /(-[XYZ])([A-Z])/ or $sw =~ /(-)([A-Z])/ or die "Failed to parse switch $_[0]\n";
		$sw = $1 . lc $2;
	}
	return $sw;
}

my ($c, $d);

sub swsort ($$){
	($c, $d) = (convert($_[0]), convert($_[1]));
	return length $c <=> length $d if length $c <=> length $d;
	return $c cmp $d;
}


my %halflines;
my %fulllines;
my %cfglines;
my $sw;
my $cfgline = 0;

while(<>){
	next until /SETNAME/;
	last;
}

while(<>) {
	next if /^\s*\/\//;
	if(/SETNAME/){
		print $_;
		last;
	}elsif (/TEXTARRAY\(halflines/ .. /NULL/) {
		next if /ARRAY/ or /NULL/;
		$sw = $1 if /"(-\w+):/;
		die "Halfline is not attached to a switch:\n$_ " unless $sw;
		if ($halflines{$sw}){
			$halflines{$sw}[0] .= $_;
		} else {
			$halflines{$sw} = [$_, 0];
		}
	} elsif (/SETTEXT\(LANG_FULLSWITCHES/ .. /^\s*"\\n"/) {
		next if /"\\n"/ or /SETTEXT/;
		$cfgline = 1;
		$sw = $1 if /"(-\w+) #/;
		die "Switch line $_ not attached to a switch.\n" unless $sw;
		if ($fulllines{$sw}){
			$fulllines{$sw}[0] .= $_;
		} else {
			$fulllines{$sw} = [$_, 0];
		}
	} elsif ($cfgline .. /^\s*"\\n"/) {
		if (/\s*"\\n"/) {
			$cfgline = 0;
			next;
		}
		$sw = $1 if /"(-\w+) c/;
		if ($cfglines{$sw}) {
			$cfglines{$sw}[0] .= $_;
		} else {
			s/cfg-file/###/;
			$cfglines{$sw} = [$_, 0, $cfgline++];
		}
	} else {
		$sw = "";
	}
}

# Done reading english.h; read <lang>.h/write <lang>.tmp

my ($readhalf, $readfull, $readcfg) = (0,0,0);

$cfgline = 0;
my $cfgfile;

while(<>) {
	next if /^\s*\/\//;
	if (/TEXTARRAY\(halflines/ .. /NULL/) {
		die "Multiple halfline blocks!\n" if $readhalf == 2;
		$readhalf = 1;
		next if (!$_ or /ARRAY/ or /NULL/);
		$sw = $1 if /"(-\w+):/;
		s/{/ /;
		die "Halfline $_ not attached to a switch.\n" unless $sw;
		if ($fulllines{$sw}) {
			print STDERR "Description for $sw in English is in LANG_FULLSWITCHES.\n";
			$halflines{$sw} = [ $_, 1 ];
			delete $fulllines{$sw};
		} elsif (!$halflines{$sw}) {
			die "Description for $sw not found in english.h\n";
		} elsif ($halflines{$sw}[1]){
			$halflines{$sw}[0] .= $_;
		} else {
			$halflines{$sw} = [$_, 1];
		}
	} elsif (/SETTEXT\(LANG_FULLSWITCHES/ .. /^\s*"\\n"/) {
		$cfgline = 1;
		next if /^\s*"\\n"/;
		die "Multiple LANG_FULLSWITCHES entries!\n" if $readfull == 2;
		$readfull = 1;
		next if !$_ or /SETTEXT/;
		$sw = $1 if /"(-\w+) #/;
		die "Switch line $_ not attached to a switch.\n" unless $sw;
		if ($halflines{$sw}) {
			print STDERR "Description for $sw in English is in halflines.\n";
			$fulllines{$sw} = [ $_, 1 ];
			delete $halflines{$sw};
		} elsif (!$fulllines{$sw}) {
			die "Description for $sw not found in english.h\n";
		} elsif ($fulllines{$sw}[1]) {
			$fulllines{$sw}[0] .= $_;
		} else {
			$fulllines{$sw} = [$_, 1];
		}
	} elsif ($cfgline .. /^\s*"\\n"/) {
		next if /^\s*"\\n"/;
		$cfgfile = $1 if !$cfgfile and /-\w+ (.*?)\s*:/;
		if ($cfgfile) {
			$cfgline = 0;
			$readcfg = 1;
			$sw = $1 if /"(-\w+)/;
			if (!$cfglines{$sw}) {
				die "Description for $sw not found in english.h\n";
			} elsif ($cfglines{$sw}[1]) {
				$cfglines{$sw}[0] .= $_;
			} else {
				$cfglines{$sw} = [$_, 1, $cfglines{$sw}[2]];
			}
		}
	} elsif ($readhalf == 1 and $readfull == 1 and $readcfg == 1) {
		$readhalf++; $readfull++;
		print "TEXTARRAY(halflines,) = {\n";
		for (sort swsort keys %halflines) {
			print "$halflines{$_}[0]";
			print STDERR "halflines missing description of option $_\n" unless $halflines{$_}[1];
		}
		print "\t  NULL };\n";
		print "SETARRAY(halflines);\n";
		print "SETTEXT(LANG_FULLSWITCHES, \"\\n\"\n";
		for (sort swsort keys %fulllines) {
			print $fulllines{$_}[0];
			print STDERR "LANG_FULLSWITCHES missing description of option $_\n" unless $fulllines{$_}[1];
		}
		print '	  "\n"' . "\n\n";
		for (sort {return $cfglines{$a}[2] <=> $cfglines{$b}[2]} keys %cfglines) {
			$cfglines{$_}[0] =~ s/###/$cfgfile/;
			print $cfglines{$_}[0];
			print STDERR "LANG_FULLSWITCHES missing description of option $_\n" unless $cfglines{$_}[1];
		}
		print '	  "\n"'."\n\n";
		print $_;
	} else {
		$sw = "";
		next if /NULL/ or /^\s*};/ or /SETARRAY\(halflines/;
		print $_;
	}
}

die "halflines block not found.\n" unless $readhalf;
die "LANG_FULLSWITCHES block not found.\n" unless $readfull;
die "Could not find translation for \"cfg-file\" in LANG_FULLSWITCHES block.\n" unless $readcfg;
