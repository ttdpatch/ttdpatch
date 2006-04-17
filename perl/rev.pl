#!/usr/bin/perl -l

$_ = <STDIN>;
/(\d+)/;
my $old = $1 || 0;

$ENV{REV} =~ /(\d+)/;
my $new = $1 || 0;

exit 0 if $new == $old;

my $file = shift;
open my $out, ">", $file or die "Can't write $file: $!\n";
print $out "SVNREV=$new";
close $out;
