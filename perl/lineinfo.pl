#!/usr/bin/perl -ps
s/^# (\d+) "(.*)".*/my $f = $2 eq "<stdin>" ? $stdin : $2; "%line ".($1-1)."+1 $f"/e
