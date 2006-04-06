#!/usr/bin/perl -l

#
# Script to read a tsc_####.dat file and produce a text output
#
# Usage: parsetsc.pl <tsc-file>
#

use strict;
use warnings;

use Math::BigInt;	# 64-bit integers are not supported everywhere, so use this
use Math::BigFloat;

open my $tsc, "<", $ARGV[0] or die "Can't read $ARGV[0]: $!";
binmode $tsc;

my $data;
read $tsc, $data, (stat $tsc)[7];

my @values = unpack "L*", $data;
sub getq {
	my $low = shift @values;
	die "Ran out of values at ".(caller)[2].";".(caller 1)[2] unless @values;
	my $high =  shift @values;
	my $num = Math::BigInt->new($high);
	$num = ($num << 32) + $low;
	return $num;
}
sub getd {
	die "Ran out of values at ".(caller)[2].";".(caller 1)[2] unless @values;
	return shift @values;
}
sub getqa {
	my @vals; #local $_;
	$vals[$_] = getq for 0..($_[0]-1);
	return @vals;
}
sub getda {
	my @vals; #local $_;
	$vals[$_] = getd for 0..($_[0]-1);
	return @vals;
}

my (@ticks,@calls,@varticks,@varcalls,@cbticks,@cbcalls);

my $lastval = @values;
my $features = getd;
my $callbacks = getd;

#print "$features features, $callbacks callbacks, ", 2+scalar @values, " values";

@ticks = getqa 2*($features+1);
@calls = getda 2*($features+1);

@ticks = map $ticks[$_*2-1] + $ticks[$_*2], 1..$features;
@calls = map $calls[$_*2-1] + $calls[$_*2], 1..$features;

@cbticks = getqa $callbacks;
$varticks[$_] = [getqa 0x40] for 0..($features-1);

@cbcalls = getda $callbacks;
$varcalls[$_] = [getda 0x40] for 0..($features-1);

die "Still have ",scalar @values, " values left" if @values;

my @features = qw(
	Trains RVs Ships Planes Stations Canals
	Bridges Houses Generic IndusTile Industry
	Cargos Sounds
);

print map { sprintf "%-12s", $_ } qw (Feature Ticks Calls Ticks/call);
$calls[$_] and
	print map { sprintf "%-12s", $_ } 
		$features[$_], $ticks[$_], $calls[$_], $ticks[$_]/$calls[$_]
	for 0..$features-1;

print "";
print map { sprintf "%-12s", $_ } qw (Callback Ticks Calls Ticks/call);
$cbcalls[$_] and
	print map { sprintf "%-12s", $_ } 
		sprintf("%02X",$_), $cbticks[$_], $cbcalls[$_], $cbticks[$_]/$cbcalls[$_]
	for 0..$callbacks-1;

my $oh = Math::BigFloat->new(100);
for my $feat (0..$features-1) {
	next unless  $calls[$feat];
	my (@pct_ticks,@pct_calls);
	@pct_ticks = map $oh*$_/$ticks[$feat], @{$varticks[$feat]} if $ticks[$feat];
	@pct_calls = map $oh*$_/$calls[$feat], @{$varcalls[$feat]} if $calls[$feat];

	print "";
	print "$features[$feat]";
	print map { sprintf "%-12s", $_ } qw (Variable Ticks Calls Ticks/call %Ticks %Calls);
	$varcalls[$feat][$_] and
		print map { sprintf "%-12s", $_ } 
			sprintf("%02x",$_+0x40),
				$varticks[$feat][$_], $varcalls[$feat][$_],
				$varticks[$feat][$_]/$varcalls[$feat][$_],
			map { sprintf "%.1f", $_ }
				$pct_ticks[$_], $pct_calls[$_]
	for 0..0x39;
}
