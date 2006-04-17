#!/usr/bin/perl -l

$_ = <STDIN>;
my ($old) = (/(\d+)/, 0);
my ($new) = ($ENV{REV} =~ /^[^:]*:?(\d+)/, 0);

#print "Old: $old New: $new (from $ENV{REV})";
exit 0 if $new == $old;

my $file = shift;
open my $out, ">", $file or die "Can't write $file: $!\n";
print $out "SVNREV=$new";
close $out;
