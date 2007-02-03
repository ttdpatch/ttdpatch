#!/usr/bin/perl -l

$_ = <STDIN>;
my ($old) = (/(\d+E?)/, 0);
$_ = $ENV{REV};
my ($new) = (/:(\d+M?)[^\d']*$/, /(\d+M?)[^\d']*$/m, 0);
my @lines = split /\n/;
$new .= "M" if @lines > 3 and $lines[3] !~ /:/;

$new =~ s/M/E/;

#print "Old: $old New: $new (from $ENV{REV})";
exit 0 if $new eq $old;

my $file = shift;
open my $out, ">", $file or die "Can't write $file: $!\n";
print $out "SVNREV=$new";
close $out;
