
#include <bitvars.inc>

%macro expand 3-*.nolist
	%rep %1
		%if %2 == patchprocbitflag
			db %2
			dd %3
			db %4
			%rotate 3
		%else
			db %2
			%rotate 1
		%endif
	%endrep
%endmacro

	// run procname if any of the bits is set
	//
	// arguments may be:
	// - a patchflag bit from common.h
	// - a flagdata bit from bitnames.ah using BIT(bitname) or NOTBIT(bitname)
	//	this *doesn't* test whether the corresponding switch is on!
	//
%macro patchproc 2-*.nolist // params: bits...,procname
	[section .pproc]
	%rotate -1
	__%1__procdef:	// create label containing the procname for the .lst file
	%rotate 1
	db %0-1
	%rep %0-1
		expand 1,%1,%2,%3
		%rotate 1
	%endrep
#ifdef __extern_procs__
        extern %1
#endif
	dd %1
	__SECT__
%endmacro

	// run procname if all of the andbits plus any of the orbits (if any
	// are given) is set
	// list of andbits and orbits is seperated by an empty argument
	// e.g.	patchprocandor andbit1,andbit2,,orbit1,procname
	// or	patchprocandor andbit1,andbit2,andbit3,,procname
	//
	// patchprocandor A,B,C,,D,E,F,procname means the following:
	//	A && B && C && (D || E || F)
	// patchprocandor A,B,C,,procname means
	//	A && B && C
%macro patchprocandor 3-*.nolist // params: andbits...,,orbits...,procname
	[section .pproc]
	%rotate -1
	__%1__procdef:
	%rotate 1
	%push andor
	%define %$andlist
	%assign %$andnum 0
	%rep %0-1
		%ifidn {%1},{}
			%rotate 1
			%exitrep
		%endif
		%assign %$andnum %$andnum+1
		%xdefine %$andlist %$andlist,%1
		%rotate 1
	%endrep
	%if %$andnum==0
		%error "patchprocandor with no ANDed bits not supported"
	%endif
	%if %$andnum==%0-1
		%error "separate andbits and orbits by an empty argument"
	%endif
	%xdefine %$ornum %0-2-%$andnum
	db 0,%$andnum
	expand %$andnum %$andlist
	db %$ornum
	%rep %$ornum
		expand 1,%1,%2,%3
		%rotate 1
	%endrep
#ifdef __extern_procs__
        extern %1
#endif
	dd %1
	%pop
	__SECT__
%endmacro

#define BIT(bit) { patchprocbitflag,bit ## _VAR,bit ## _NUM }
#define NOTBIT(bit) { patchprocbitflag,bit ## _VAR,bit ## _NUM |0x80 }


