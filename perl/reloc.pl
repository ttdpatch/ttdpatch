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

=comment
while (<>) {
	my @F = split;

	# remember ptrvar definition
	if ($F[4] and $F[4] eq 'ptrvar' or $F[1] and $F[1] eq 'ptrvarofs') {
		if ($F[1] and $F[1] eq 'ptrvarofs') {
			#print STDERR join "; ", map("$_: $F[$_]", 0..$#F), "\n";
			my $arg = "@F[2..$#F]";
			$arg =~ s/\s+//g;
			#print STDERR "Arg $arg\n";
			my ($ofsvar,$ptrvar,$ofs) = split /,/, $arg, 3;
			die "Variable $ofsvar ends in _ptr" if $ofsvar =~ /_ptr$/;
			$ofsvars{$ofsvar} = $ptrvar;
			#print STDERR "Have ofsvar $ofsvar at $ofs from $ptrvar\n";
		} else {
			my $ind = (hex($F[1]) - $baseofs)/4;
			die "Variable $F[5] ends in _ptr" if $F[5] =~ /_ptr$/;
			$ptrvars[$ind] = $F[5];
			#print STDERR "Found ptrvar $F[5] at $F[1]=$ind\n";
		}
		my $ptr_names = join "|", @ptrvars;
		my $ofs_names = join "|", keys %ofsvars;
		$ofs_names = "|$ofs_names" if $ofs_names;
		$ptr_re = qr/\b((?:$ptr_names)(?:_ptr)?$ofs_names)\b/;
		#print STDERR "Ptr RE: $ptr_re\n";
	}

	next unless @F > 2;

	# collect all continuation lines
	my $line = $_;
	while (@F > 2 and $F[2] =~ /-$/) {
		$F[2] =~ s/-$/$_=<>;$line.=$_;(split)[2]/e;
		#	print "Now $F[2] after adding new line $_\n";
	}

	# skip lines which don't have a "[" in the byte code
	next unless $F[2] =~ tr/[//;

	#print "Found $F[2] in $_\n";

	# collect all lines with relocations for processing later
	push @lines, [ $line, @F ] if $F[2] =~ /^([0-9a-f]*)\[(.*?):([0-9a-f]{8})\]/i;
}
for my $relocline (@lines) {
	my $line;
	our @F;
	($line, @F) = @$relocline;

	# find all relocations and record the lower 16 bits of their addresses
	while ($F[2] =~ s/^([0-9a-f]*)\[(.*?):([0-9a-f]{8})\]/$1$3/i) {
		my $type = $2;
		next unless $type eq ".ttd" or $type eq ".ptr";
		my $rel = (length $1)/2;
		my $addr = ($rel + hex $F[1]) & 0xffffff;
		my $xaddr = sprintf "%06x", $addr;
		#	print "Relocation: $2 at $xaddr ($1=$rel before it)\n";
		my @names;
		if ($type eq ".ttd") {
			@names = qw(win_relocs);
		} else {
			@names = $line =~ /$ptr_re/g;
			@names = ('section.ptr.start_ptr') if $line =~ /section.ptr.start/;
			# translate offset variables to their ptrvars
			exists $ofsvars{$_} and $_ = $ofsvars{$_} for @names;
			if (@names == 1 and $names[0] =~ /_ptr$/) {
				#print STDERR "Ignoring $names[0] access in line $F[0]\n";
				next;
			}
			die "Can't find ptrvar in line $F[0]" if @names < 1;
			die "Multiple ptrvar accesses (@names) in line $F[0]" if @names > 1;
		}
		#print STDERR "Found $names[0] relocation at $xaddr\n";
		push @{$ptrs{$names[0]}{substr $xaddr,-6,4}}, "0x" . substr $xaddr, -2;
	}
}
=cut

my %varofs;
while(<>) {
	if (/^\.relocv/ ... /^$/) {
		next unless /^\s*(0x[0-9a-f]{8})\s+(\w+)_var/;
		$varofs{$2} = hex $1;
		#print STDERR "Var $2 is at $1 ($varofs{$2})\n";
		next;
	}
	next unless /(0x[0-9a-f]{8})\s+_+fu\d+_(\w+)/;
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

