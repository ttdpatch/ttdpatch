#!/usr/bin/perl -wlp

# Go through assembly code, collect info about the sizes of struct members
# and specify that size for each access where no size is specified yet

our %sizes = (b => "byte", w => "word", d => "dword");
our @re;
our @var;
our $instruc;
our $label;

if (tr/[// && tr/]// && tr/+//) {

	# cut off everything after a comment or C/nasm preprocessor directive
	my $comment= s~(\s*(%|#|;|//).*)$~~ ? $1 : '';

	# study character frequencies; this speeds up regex processing
	study;

	for my $i (0..$#re) {
		my $re = $re[$i];
		my $var = $var[$i];
		if (/$re/) {
#			print "Found @$var[0] with $re, is @$var[1]";
			if (/(d?word|byte)\s*\[/) {
#				print "Already has a size ($1).";
				last;
			}
			s/\[/$sizes{@$var[1]} [/;
			last;
		}
	}


	# and append the comment (etc.) again
	$_.=$comment;
}

if ($instruc) {
	$instruc = 0 if /endstruc/;

	$label = $1 if /(\w+):/;
	if ($label && /res(.) \d/) {
		push @var, [$label, $1];
		push @re, qr/\[.*\+.*?\b\Q$label\E\b.*?\]/i;
#		print "Have $var[-1][0], is $var[-1][1], RE $re[-1]";
		$label = undef;
	}
} else {
	$instruc = /struc (\w+)/;
}
