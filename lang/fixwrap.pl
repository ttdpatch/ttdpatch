#!/usr/bin/perl -lpi.bak

my $numquot = () = /(?<!\\)"/g;
my $iscomm = () = m#^//#g;

next unless $iscomm or ($numquot & 1);

my $follow = <>;
chomp $follow;

my $firstlen = length;
my $seclen = length $follow;

print STDERR "$iscomm $numquot $firstlen $seclen in ...", 
	substr($_, -30), " +++ ", 
	substr($follow, 0, 20), "...";

if ($firstlen < 81 and $firstlen + $seclen >= 74 and
		$follow =~ /^\w/ and $follow !~ /^[A-Z]+\(/) {
	$_ .= $follow;
	print STDERR "Concated.";
} else {
	print;
	$_ = $follow;
	redo;
}
