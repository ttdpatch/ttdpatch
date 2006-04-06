// The list of 'system' texts loaded from lang/*h files
// The indices are given the form systext_LANG_XXXXX

%assign numsystemtexts 0

%macro definesystext 1.nolist
	systext_%1 equ numsystemtexts
	%assign numsystemtexts numsystemtexts+1
%endmacro

#define systxt(name) definesystext name
#include "../systexts.h"
#undef systxt


