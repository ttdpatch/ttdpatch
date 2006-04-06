#!/usr/bin/perl -pl
use warnings;
use strict;

our %sect;
our $sects;
our $sect;
our $prevsect;
our $runindexbase;
BEGIN {
	# read section offsets from binary file on command line
	my $binfile = shift;
	open my $bin, "<", $binfile or die "Can't read $binfile: $!";

	my @sectnames = qw(.bss .bss2 .bss1 .ptr .sbss .sbss2 .sbss1 .aux);
	my $bssofs;
	seek $bin, -@sectnames * 4, 2;
	read $bin, $bssofs, @sectnames * 4;
	@sect{@sectnames} = 
		unpack "L*", $bssofs;

	# don't actually resolve .ptr addresses
	delete $sect{'.ptr'};

	#printf STDERR "Section $_ is at %08X.\n", $sect{$_} for keys %sect;

	$sects = join "|", grep $sect{$_}, keys %sect;
	$sect{__STRUC__} = 0;
	$prevsect = $sect = "__STRUC__";
}

if (/^\s*\d+\s+struc\s+(\w+)/) {
	$prevsect = $sect; $sect = "__STRUC__";
	#print STDERR "$.: In struc $1";
} elsif (/endstruc/ and $sect eq "__STRUC__") {
	$sect = $prevsect;
	#print STDERR "$.: Back in $prevsect";
} elsif (/section\s+([\w\.]+)/) {
	$sect = $1;
	if (/vstart=(\S+)/) {
		my $start = $1;
		$start =~ s/runindexbase/$runindexbase/;
		my $ofs = eval $start;
		#printf STDERR "New section $sect at $start=$ofs (%08X)\n",$ofs;
		$sect{$sect} = $ofs; 
	}
	#print STDERR "$.: In $sect";
} elsif (/runindexbase\s+equ\s+(\w+)/) {
	$runindexbase = oct $1;
	#printf STDERR "runindexbase is at %08X\n", $runindexbase;
}
my $org = $sect{$sect};
if (/^\s*\d+\s+\w{8}.*uvar(.)\s+([.\w]+)(?:\s*,[^,]*)?(,\s*s)?/) {
	my $sign = substr $3 || ",",1;
	my $uvar = { b=>".bss1", bs=>".sbss1", w=>".bss2", ws=>".sbss2",
		  d=>".bss", ds=>".sbss" }->{"$1$sign"};
	#print STDERR "$.: uvar$1 $2,...,$sign is section $uvar";
	$org = $sect{$uvar};
} elsif (/^\s*\d+\s+\w{8}.*uvar(.)/) {
	die "uvar$1 not matched";
} elsif (/getsectsize\s+(\S+)/) {
	$org = $sect{$1};
	#print STDERR "$.: size of section $1";
}

sub trl($$) {
	my $s = $_[0];
	my $ofs = join "", reverse $_[1] =~ m#(..)#g;
	$ofs = unpack 'l', pack 'L', hex $ofs;	# convert to signed
	$ofs=sprintf "%08X", $s + $ofs;
	return join "", reverse $ofs =~ m#(..)#g;
}

# translate address
my $addr;
s/^(\s*\d*\s+)([0-9A-F]{8})/ $1 . sprintf "%08X", $org + hex $2 /gei;

# -p switch, process all remaining arguments and/or stdin
/(\[[0-9a-f]{8}\])/i and print STDERR "Relocation without section: $1 at ",
	substr $_, 7,8;

s/\[($sects):([0-9a-f]{8})\]/
	"[$1:" . trl($sect{$1}, $2) . "]";
/gei;

# change consecutive spaces to tabs to save space
s^( {2,})^
	my $pos = $-[0];
	my $end = $+[0];
	my $tabs = int ($end/8)-int($pos/8);
	#print STDERR join " ", "$.:", $pos, $end, $tabs, $end&~7, $pos&~7 + $tabs*8;
	$tabs ?  ("\t" x $tabs) . (" " x ($end % 8)) : $1;
^ge;

