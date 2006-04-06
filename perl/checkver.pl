#!/usr/bin/perl -n
next unless /VERSION\s*=\s*([\w.]+)/;
die "Set the version ($1)" if -e "e:/diffs/$1";
