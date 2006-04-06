//
// Basic setup of the assembly environment
//
// *Every* asm file must include either this of std.inc at the very top
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

cpu 386
bits 32

; if you get errors in the following lines, your nasm is not up-to-date
; with the needed TTDPatch-related changes, see nasm/00readme

[warning +orphan-labels]	  // enable warnings about orphaned labels
[warning +opsize-from-immediate]  // and about undefined opsizes with imm8 op

[list sectionnames]	// add section names to relocations in .lst file
[list hexwidth 22]	// make hex column a bit wider

bits 32

%ifdef PREPROCESSONLY
%error Do not compile the results of preprocessing!	// no "", so it's a warning
%endif

// Define a new endstruc macro that sets the "bits" setting properly
%imacro endstruc_32 0.nolist
	endstruc
	bits 32
%endmacro

// define section attributes
section .bss nobits align=4
section .bss2 nobits align=2
section .bss1 nobits align=1
section .sbss nobits align=4
section .sbss2 nobits align=2
section .sbss1 nobits align=1
section .indrct align=4
section .pproc align=1
section .relocv align=4

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
