#!/usr/bin/perl
#
# Converts all language files to their proper code page, both for DOS and
# Windows editors (Windows files are in Windows\ subdirectory)
#
# Parameter: either a file glob or a code page
# 	If it's a file glob, those files are processed
#	If it's a code page, convert STDIN to that code page and write to STDOUT
#

require v5.8.0;
use strict;
use warnings;
use Encode;

my @files = @ARGV;
@files = ("*.h","windows/*.h") unless @files;

my %seen;
$seen{$_}=1 for map {$_=lc "/$_";substr $_,1+rindex $_, "/"} map glob, @files;

@files=sort keys %seen;

my $forcemap;

if (!$#files && $files[0] eq eval{no warnings;$files[0]+0}) {
	$forcemap = $files[0];
	@files=("-");
}

for my $file (@files) {
	# only change files where the DOS and Windows versions have different
	# time stamps (or all if codepage is forced)

	my ($temp,$dest,$mtime);
	my %CP = map {$_=>undef} qw(DOS WIN EDITOR DEST);

	if ($forcemap) {
		*IN = *STDIN; *OUT = *STDOUT;
		$CP{DEST} = \$forcemap;
	} else {
		my $dos = $file;
		my $win = "windows/$file";

		my $dostime = (stat $dos)[9] || 0;
		my $wintime = (stat $win)[9] || 0;

		print STDERR "$dos has mtime $dostime, $win has mtime $wintime.\n";

		next if $dostime == $wintime and not $forcemap;

		print STDERR "Updating ";
		if ($dostime > $wintime) {
			($temp,$dest,$mtime)=("$win.tmp",$win,$dostime);
			open IN, "< $dos" or die "Can't open $dos: $!";
			open OUT, "> $temp" or die "Can't open $temp: $!";
			$CP{DEST}=\$CP{WIN};
			print STDERR "$win, DOS";
		} else {
			($temp,$dest,$mtime)=("$dos.tmp",$dos,$wintime);
			open IN, "< $win" or die "Can't open $win: $!";
			open OUT, "> $temp" or die "Can't open $temp: $!";
			$CP{DEST}=\$CP{DOS};
			print STDERR "$dos, Windows";
		}
		print STDERR " is newer.\n";
	}
	binmode IN;
	binmode OUT;

	# figure out DOS, Windows and the Editor's code pages

	while (<IN>) {
		next unless /(\w+)CODEPAGE\((.+)\)/;
		print STDERR "$1 codepage is $2.\n";
		$CP{$1}=$2;
		last unless grep {!defined} values %CP;
	}
	die "Not all codepages in $file" if grep {!defined} values %CP;

	print STDERR "Codepages: ", join "; ", map "$_=$CP{$_}", keys %CP;
	print STDERR "\nDEST is actually ${$CP{DEST}}\n";

	seek IN, 0, 0;		# rewind
	$.=0;

	while (<IN>) {
		s/(EDITORCODEPAGE)\((\d+)\)/$1(${$CP{DEST}})/;
		my $unicode = decode("cp$CP{EDITOR}", $_, Encode::FB_CROAK);
		my $esc;
		my $ucn;

		while (($esc, $ucn) = ($unicode =~ /(\&\#x([[:xdigit:]]+)\;)/)) {
			my $c = chr(hex $ucn);
			$unicode =~ s/\Q$esc\E/$c/;
		}

		print OUT encode("cp${$CP{DEST}}", $unicode, Encode::FB_XMLCREF);
	}

	close IN;
	close OUT;

	unlink $dest;
	rename $temp, $dest;
	utime $mtime,$mtime,$dest if $mtime;
}
