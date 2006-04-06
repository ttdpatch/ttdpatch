#!/usr/bin/perl
use warnings;
use strict;

my $filename = shift;
open my $logfile, "<", $filename or die "Can't read $filename: $!";
my $recsize = (7+16)*4;
local $/=\$recsize;

sub p {
	for (@_) {
		if (defined $_ && $_>-1024) {
			print $_ < 0 ? "-" : " ";
			$_ = abs $_;
		} else {
			print " ";
		}
		if (defined) {
			printf "%08x ", $_ & 0xffffffff;
		} else {
			print "undef  ";
		}
	}
}

my $starttime;
my $last;
my $repeated;
my %callid;
my $callid=0;
while (<$logfile>) {
	if (defined $last and $last eq $_) {
		$repeated++;
		next;
	} else {
		print "(above repeated $repeated times)\n" if $repeated;
		$last = $_;
		$repeated = 0;
	}
	my $thisid;
	if (exists $callid{$_}) {
		$thisid = $callid{$_};
	} else {
		$thisid = $callid{$_} = $callid++;
	}
#	printf "%02x ",$_ for unpack 'C*', $_;
#	print "\n";
	my ($time,$org,$obj,$ofs,$meth,$parsize,$result,@params)
		= unpack 'l*', $_;
	$parsize = -$parsize;

	unless (defined $starttime) {
		map {printf "%-8s  ",$_} qw(ID Time From Obj Ofs Method Result Param);
		print "\n";
		$starttime = $time;
	}
	printf "%-8d  %-8d ", $thisid, $time-$starttime;
	p $org,$obj,$ofs,$meth,$result,@params[0..$parsize/4-1];
	print "\n";
}
