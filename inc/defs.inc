//
// Basic setup of the assembly environment
//
// *Every* asm file must include either this or std.inc at the very top
//

//#if !WINTTDX && !LINTTDX
//#	include "versiond.h"
//#else
//#	include "versionw.h"
//#endif

; TTDPatch TTDPATCHVERSION

; Compiled with "WINTTDX"=<WINTTDX>, "LINTTDX"=<LINTTDX>, "DEBUG"=<DEBUG>
; __DATE__ __TIME__
#if WINTTDX
; "WINTTDX" is on.
#else
; "WINTTDX" is off.
#endif
#if LINTTDX
; "LINTTDX" is on.
#else
; "LINTTDX" is off.
#endif
#if DEBUG
; "DEBUG" is on.
#else
; "DEBUG" is off.
#endif

#define ASSEMBLER

%ifndef __Line__
	%error "Your nasm binary is outdated, please use the one from the nasm/ directory."
%endif

cpu 386
bits 32

; if you get errors in the following lines, your nasm is not up-to-date
; with the needed TTDPatch-related changes, see nasm/00readme

[warning +orphan-labels]	  // enable warnings about orphaned labels
[warning +opsize-from-immediate]  // and about undefined opsizes with imm8 op

;[list sectionnames]	// add section names to relocations in .lst file
;[list hexwidth 22]	// make hex column a bit wider

%ifdef PREPROCESSONLY
%error Do not compile the results of preprocessing!	// no "", so it's a warning
%endif

// define section attributes
section .bss nobits align=4	// zero-initialized space, D/W/B sized
section .bss2 nobits align=2
section .bss1 nobits align=1
section .sbss nobits align=4	// all-ones-initialized space, D/W/B sized
section .sbss2 nobits align=2
section .sbss1 nobits align=1
section .datab align=1		// initialized variables, D/W/B sized
section .dataw align=2
section .datad align=4
section .indrct align=4		// holds list of indirect call/jmp pointers
section .pproc align=1		// holds list of patchproc definitions
section .relocv align=4		// holds order of ptrvar definitions
section .varlist align=4

// default section
section .text align=4

	// if NOINT3 is set (in Makefile), don't add int3 breakpoints
%define CALLINT3 ;				// do nothing by default
%ifndef NOINT3
	%define CALLINT3 int3			// you have a good debuger
%elif NOINT3 eq 1
	%define CALLINT3 jmp $			// endless loop
%endif
#if !DEBUG
	%define CALLINT3 ;
#endif

#if WINTTDX
#define CALLINT21 call [int21handler]
#else
#define CALLINT21 int 0x21
#endif

#include <opimm8.inc>

// Macros for catching division-by-zero
extern overflowhandler,realoverflowreturn
%macro div 1-2.nolist 1
	%if %2
		%ifndef overflowreturn_abs
			%error "Include ttdvar.inc please"
		%endif
#if DEBUG
		mov dword [realoverflowreturn],%%postdiv
		mov dword [overflowreturn],overflowhandler
#else
		mov dword [overflowreturn],%%postdiv
#endif
	%endif
	div %1
%%postdiv:
%endmacro

%macro idiv 1-2.nolist 1
	%if %2
		%ifndef overflowreturn_abs
			%error "Include ttdvar.inc please"
		%endif
#if DEBUG
		mov dword [realoverflowreturn],%%postdiv
		mov dword [overflowreturn],overflowhandler
#else
		mov dword [overflowreturn],%%postdiv
#endif
	%endif
	idiv %1
%%postdiv:
%endmacro

%macro exported 1.nolist
	global %1
	%1:
%endmacro

#if MAKEGUARD
%macro CHECKMEM 0.nolist 
	extern checkmemoryconsistency
	call checkmemoryconsistency
%endmacro
#else
%define CHECKMEM ;
#endif
