#!/usr/bin/perl -nli.bak
# YOU CAN REMOVE THIS NOW

if (1 .. /^\s*(patchproc|global)/) {
	push @top, $_;
} elsif (/begincodefragments/ .. /endcodefragments/) {
	push @frag, $_;
} elsif (/^\s*extern/ or /^#include/) {
	push @top, @bot,$_;
	@bot = ();
} else {
	push @bot, $_;
}

if (eof) {
	push @top, "" if $top[-1] !~ /^\s*$/ and $frag[0] !~ /^\s*$/;
	push @frag, "" if $frag[-1] !~ /^\s*$/ and $bot[0] !~ /^\s*$/;
	pop @bot while @bot and $bot[-1] =~ /^\s*$/;
	print for @top;
	print for @frag;
	print for @bot;
	@top = @frag = @bot = ();
	$. = 0;
}
