#!/usr/bin/perl -wlp

use strict;

# Go through assembly code, make struct members local to the struct

our %struct;	# structure name for each member

if (/^\s*struc\s+(\w+)/ && (our $curstruc = $1) .. /^\s*endstruc/) {
	next if $curstruc eq 'versiondata' || $curstruc eq 'cheatentrystruc';

	if (/^\s*(\w+):/) {	# note: will ignore local labels, they start with a '.' which isn't \w
		$struct{$1} = $curstruc;
		substr $_, $-[1], 0, '.';	# place dot in front of member name
	}
} else {
	# cut off everything after a comment or C/nasm preprocessor directive
	my $comment = s~((%|#|;|//).*)$~~ ? $1 : '';

	while (/(?<![.\w])(\w+)\b/g) {		# find words that aren't preceded by . or \w
		# put structure name in front, if the identifier is a struct member
		substr $_, $-[1], 0, "$struct{$1}." if $struct{$1};
	}

	# append the comment (etc.) again
	$_ .= $comment;
}

print STDERR "$0: $ARGV done" if eof;
