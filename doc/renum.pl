#!/usr/bin/perl -i.bak -ln
#
# Perl script to canonicalize a GRFCodec .NFO file.  It
# - makes correct sprite numbers
# - for pseudo-sprites, calculates the correct size
# - remove all comments except the first set
# - remove empty lines
#
# Usage:	perl renum.pl <nfo-file>
#
# The source file will be renamed to .bak (unless a backup exists already),
# and must be of the correct form for a .nfo file.  That is, it must have 
# sprite numbers (though they need not be correct).
#
s#//.*## if !m#//# .. "never";
next unless length;
sub done {
	for ($cur) {
		next unless defined;
		chomp;
		$count = 0;
		s/^(\s*\d+\s+\*)\s+\d+\s+/$cut=$1;''/e;
		$count++ while /[\da-f]{2}/gi;
		$_ = "$cut $count\t $_";
		print;
		$_=undef;
	}
}
if (s/^(\s*\d+)\s*\*/sprintf '%*d *',(length $1),$a++/e) {
	done;
	$cur.="$_$/";
} elsif (s/^(\s*\d+\s)(?!\s*[\da-fA-F]{2}(\s|$))/sprintf '%*d ',(length $1)-1,$a++/e) {
	done;
	print;
} elsif ($cur) {
	$cur.="$_$/";
} else {
	done;
	print;
}
done if eof;
