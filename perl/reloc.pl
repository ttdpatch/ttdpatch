#!/usr/bin/perl -w

use strict;

our $os;
my %baseofs = (d => 0x200000, w=>0x600000);
die "Invalid OS type `$os'" unless exists $baseofs{$os};
my $baseofs = $baseofs{$os};

my %ptrs;
my %ofsvars;
my $ptr_re = qr/(?!a)a/;	# RE that never matches; until changed below
my @lines;

my %varofs;
while(<>) {
	if (/^\.relocv/ ... /^$/) {
		next unless /^\s*(0x[0-9a-f]{8,16})\s+(\w+)_var/;
		$varofs{$2} = hex $1;
		#print STDERR "Var $2 is at $1 ($varofs{$2})\n";
		next;
	}
	next unless /(0x[0-9a-f]{8,16})\s+_+fu\d+_(\w+)/;
	#print STDERR "Found reloc for $2 at $1\n";
	push @{$ptrs{$2}{substr $1,-6,4}},"0x".substr $1, -2;
}

die "No relocations found (is your nasm is not patched properly?)" unless $ptrs{_ttdvar_base};

defined $varofs{$_} or die "$_ has no varofs" for keys %ptrs;

print "$_.reloc: dd $_.reloc.start - \$\n" for sort { $varofs{$a} <=> $varofs{$b} } keys %ptrs;

sub printreloc {
my $name = shift;
my %relocs = @_;
my $lastblock = $baseofs/256;
print "$name.reloc.start:\n";
%relocs = () if $os eq 'd' and $name eq 'ttdvar_base';
my $bytes = 0;
my $numrel = 0;
for (sort {hex $a <=> hex $b} keys %relocs) {
	my $block = hex;
	my $skipblock = $block - $lastblock;

	#printf ";In block %4xxx: skip $skipblock; addrs @{$relocs{$_}}\n", $block;

	while ($skipblock > 14) {
		# skip a number of blocks to the next relocation address
		# up to 14 will be handled by the actual relocation block below
		# 15 can't be encoded (is marker for 0xnf below), must be split as 14+1
		# otherwise, n multiples of 16 can be skipped using 0xnf

		#printf ";Want to skip $skipblock blocks (%4xxx to %4xxx)\n", $lastblock, $block;
		my $skipofs = $skipblock >> 4;	# number of multiples of 16
		$skipofs = 15 if $skipofs > 15;	# can skip at most 15*16 blocks at once

		if ($skipofs) {
			# skipping a multiple of 16 blocks ($skipofs)
			$lastblock += $skipofs << 4;
			#printf ";Skipping %d blocks\n", $skipofs<<4;
			printf "\tdb 0x%xf\t;skip to %4xxx\n", $skipofs, $lastblock;
			$skipblock -= $skipofs << 4;
		} else {
			# must be 15 blocks, do 14 now and the rest later
			$lastblock += 14;
			#printf ";Skipping 14 blocks\n";
			printf "\tdb 0x%02x\t;skip to %4xxx\n", 14, $lastblock;
			$skipblock -= 14;
		}
		$bytes++;
		#printf ";Last block now %xxx, remaining $skipblock skips\n", $lastblock;
	}

	$lastblock = $block;

	my @relocs = sort { hex $a <=> hex $b } @{$relocs{$_}};

	while (@relocs) {
		my $num = @relocs;
		$num = 15 if $num > 15;

		my @slice = splice @relocs, 0, $num;

		my $code = sprintf "0x%2x", $skipblock + (@slice << 4);
		local $" = ',';
		print "\tdb $code,\t@slice\t; ${_}xx\n";
		$bytes += 1 + $num;
		$numrel += $num;

		$skipblock = 0;
	}
}
print "\tdb 0\n";
$bytes++;
printf "\t; $numrel relocations using $bytes bytes (%.1f bytes/reloc)\n", 
	$numrel?$bytes/$numrel:0;
}

printreloc $_, %{$ptrs{$_}} for keys %ptrs;

