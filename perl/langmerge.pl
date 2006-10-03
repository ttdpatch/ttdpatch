#!/usr/bin/perl
#
# Merge missing switch descriptions from English.
#
# Input: lang/english.h, lang/<lang>.h
# Output: lang/<lang>.tmp, to be #included by proclang.c
#

use strict;
use warnings;

# sort -h, -H, -2, -Xh, -XH, -X2 -Yh, -YH, ...
# strategy: convert to -AH, -Ah, -B2, -XAH, -XAh, -XB2 -YAH, -YAh ...

sub convert ($) {
	my $extsw = "[XYZ]";	# Characters introducing extended switches
	local $_ = $_[0];
	$_ = substr $_, 0, 2 if length > 2 and !/-$extsw/o;

	if (/-[a-z]/ or /-$extsw[a-z]/o) {
		$_ = uc;
	} elsif ( !/-$extsw?\d/o ) {
		/(-$extsw)([A-Z])/o or /(-)([A-Z])/ or die "Failed to parse switch $_[0]\n";
		$_ = $1 . lc $2;
	}

	s/-($extsw?)(\d)$/-$1B$2/o;
	s/-($extsw?)([a-zA-Z])$/-$1A$2/o;

	return $_;
}

sub swsort { return convert($a) cmp convert($b); }

my %halflines;
my %fulllines;
my %cfglines;
my $sw;
my $cfgline = 0;
my $linemod;

while(<>){
	next until /SETNAME/;
	last;
}

while(<>) {
	next if /^\s*\/\//;
	if(/SETNAME/){
		print $_;
		$linemod = $. - 8;
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

my ($readhalf, $readfull) = (0,0);

$cfgline = 0;
my $cfgfile;

while(<>) {
	next if m#^\s*//#;
	if (m#/\*{3,}/#) {
		s#/\*{3,}/##;
		s/\n//;
		while (s/\s{2,}|\t/ /) {}
		printf STDERR "Line %d tagged as untranslated: %s\n", $.-$linemod, substr $_, 0, 40;
	}
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
			$sw = $1 if /"(-\w+)/;
			if (!$cfglines{$sw}) {
				die "Description for $sw not found in english.h\n";
			} elsif ($cfglines{$sw}[1]) {
				$cfglines{$sw}[0] .= $_;
			} else {
				$cfglines{$sw} = [$_, 1, $cfglines{$sw}[2]];
			}
		} else {
			die "Could not find translation for \"cfg-file\" in LANG_FULLSWITCHES block.\n";
		}
	} elsif ($readhalf == 1 and $readfull == 1) {
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
		print '	  "\n"'."\n\n$_";
	} else {
		$sw = "";
		next if /NULL/ or /^\s*};/ or /SETARRAY\(halflines/;
		print $_;
	}
}

die "halflines block not found.\n" unless $readhalf;
die "LANG_FULLSWITCHES block not found.\n" unless $readfull;
