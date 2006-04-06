//
// bitvars.inc - define bit variables and bit names/values
//
#ifndef __BITVARS_INC__
#define __BITVARS_INC__

%macro defbitvar 2.nolist	// argument: patchflag,variablename
	%push bitvar
%endmacro
%macro defbit 2.nolist		// argument: bitname,bitnumber
	extern %1_VAR
	%xdefine %1_NUM %2
	%assign %1 1<<%2
%endmacro
%macro enddefbits 0.nolist
	%pop
%endmacro
#include "../bitnames.ah"
%undef defbitvar
%undef defbit
%undef enddefbits

#endif // __BITVARS_INC__
