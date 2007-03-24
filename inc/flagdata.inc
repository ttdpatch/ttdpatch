	// the values that go with some of the patches are in flagdata.h
	// here we define the one-line macros needed

%assign flags_size 0
%assign maxwidth 4
%macro defflag 2-3.nolist 1
	extern %1
	%assign %1_OFS flags_size
	%if %2 > maxwidth
		%if %2 == 4
			%error "dword flags must preceed byte and word flags."
		%else
			%error "word flags must preceed byte flags."
		%endif
	%else
		%assign maxwidth %2
	%endif
	%assign flags_size flags_size+(%2*%3)
%endmacro

#define defbyte(name)		defflag name,1
#define defword(name)		defflag name,2
#define deflong(name)		defflag name,4
#define defbytes(name, count)	defflag name,1,count
#define defwords(name, count)	defflag name,2,count
#define deflongs(name, count)	defflag name,4,count

extern startflagvars

#include "../flagdata.h"

extern endflagdata

	// then we undefine them so that they may be re-used

#undef defbyte
#undef defword
#undef deflong
#undef defbytes
#undef defwords
#undef deflongs

	// compatibility labels

	curvetype	equ mctype
	mountaintype	equ mctype+1
	signal1waitdays	equ signalwaittimes
	signal2waitdays	equ signalwaittimes+1
