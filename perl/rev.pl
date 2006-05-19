#!/usr/bin/perl -l

$_ = <STDIN>;
my ($old) = (/(\d+M?)/, 0);
$_ = $ENV{REV};
my ($new) = (/:(\d+M?)\D*$/, /(\d+M?)\D*$/, 0);
my @lines = split /\n/;
$new .= "M" if @lines > 3 and $lines[3] !~ /:/;

#print "Old: $old New: $new (from $ENV{REV})";
exit 0 if $new == $old;

my $file = shift;
open my $out, ">", $file or die "Can't write $file: $!\n";
$new =~ s/M/E/;
print $out "SVNREV=$new";
close $out;
