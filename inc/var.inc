#ifndef __VAR_INC__
#define __VAR_INC__

// macros for defining variables in TTD's and TTDPatch's memory space
// THIS IS OBSOLETE NOW, DON'T USE IT IN NEW CODE
%define addr(x) (x) //-protectedstart+runindexbase)

%macro endvar 0
	%ifnctx VAR
		%error "endvar not following a var definition"
	%else
		__SECT__
		%pop
	%endif
%endmacro

// macro to eat and discard all parameters
%macro gobbleargs 1+
%endmacro

// prefix macro to not use the "global" declaration
%macro noglobal 1+
	%define GLOBALVAR gobbleargs
	%1
	%define GLOBALVAR global
%endmacro

%define GLOBALVAR global

// preferred form of variable declaration:
// var{b,w,d} <var> [, <value>, ...]
// b/w/d specifies the alignment
// this puts the variable in the data segment which improves performance
// for some CPUs
// if the value is not given, the section will remain .data{b,w,d} and
// has to be manually reset to .text
//
// by default all variables are declared global; preceed the declaration
// with "noglobal" if they shouldn't be (i.e. for local variables)
%macro varb 1-2+.nolist	// params: variablename, value
	%ifnctx VAR
		%push VAR
		%xdefine %$VAR_START __File__:__Line__
	%endif
	[section .datab]
	GLOBALVAR %1
	%if %0>1
		%1: db %2
		endvar
	%else
		%1:
	%endif
%endmacro
%macro varw 1-2+.nolist	// params: variablename, value
	%ifnctx VAR
		%push VAR
		%xdefine %$VAR_START __File__:__Line__
	%endif
	[section .dataw]
	GLOBALVAR %1
	align 2
	%if %0>1
		%1: dw %2
		endvar
	%else
		%1:
	%endif
%endmacro
%macro vard 1-2+.nolist	// params: variablename, value
	%ifnctx VAR
		%push VAR
		%xdefine %$VAR_START __File__:__Line__
	%endif
	[section .datad]
	GLOBALVAR %1
	align 4
	%if %0>1
		%1: dd %2
		endvar
	%else
		%1:
	%endif
%endmacro

// define global variable
%macro var 1-2+.nolist	// params: variablename [, initialization]
	GLOBALVAR %1
	%1: %2;
%endmacro

// ovar defines a global variable with an offset to the current position (or
// another variable)
%macro ovar 1-4.nolist -4,$, // params: variablename, offset [, basis [, fullname]]
	GLOBALVAR %4%1
	%1 equ addr(%3)+(%2)
%endmacro

// Check that code isn't in var context (wrong section!)
%macro mov 2.nolist
	%ifctx VAR
		%error "Missing endvar for var definition at %$VAR_START"
		%pop	// to prevent repeats of this message
	%endif
	mov %1,%2
%endmacro

// Define an uninitialized variable
// (really it'll be initialized to 0 or -1, but take no space in the .exe file)
// initval can be either z for zero or s for signed (-1) initialization

%define sectname_1z .bss1
%define sectname_1s .sbss1
%define sectname_2z .bss2
%define sectname_2s .sbss2
%define sectname_4z .bss
%define sectname_4s .sbss
%macro sdef 3.nolist		; params bss-type, varname, varnum
	%define %%sectname sectname_%1
	[section %%sectname]
	GLOBALVAR %2
	%2: %3
	__SECT__
%endmacro
%macro uvarb 1-3.nolist 1,z	; params: name [,number [,initval]]
	sdef 1%3,%1,resb %2
%endmacro
%macro uvarw 1-3.nolist 1,z
	sdef 2%3,%1,resw %2
%endmacro
%macro uvard 1-3.nolist 1,z
	sdef 4%3,%1,resd %2
%endmacro

// same as uvar{b,w,d} but signed by default
%macro svarb 1-2.nolist 1	; params: name [,number]
	sdef 1s,%1,resb %2
%endmacro
%macro svarw 1-2.nolist 1	; params: name [,number]
	sdef 2s,%1,resw %2
%endmacro
%macro svard 1-2.nolist 1	; params: name [,number]
	sdef 4s,%1,resd %2
%endmacro

//
// define a pointer variable
// access through "name" access the memory pointed to by the pointer variable
// access through "name_ptr" accesses the pointer variable itself
//
// e.g. ptrvar myptr, and myptr being set to 0x123456
// mov eax,[myptr+4] is equivalent to mov eax,[0x123456+4]
// mov eax,[myptr_ptr] is equivalent to mov eax,0x123456
//
// When defining a new ptrvar, also add it to reloc.c
//
// this allows easy indirect memory accesses by using automatically resolved relocations
//

// Just declare the variable, no allocation of memory
%macro ptrvardec 1.nolist
	%ifndef %1_def
		extern _%1
		%1 equ _%1+0x80000000
		%define %1_def
	%endif
%endmacro

// Only allocate the memory
%macro ptrvarall 1.nolist
	global %1,%1_ptr,_%1_var
	[section .relocv]
	_%1_var: dd $		// only needed to get the order in reloc?.inc right
	__SECT__
	align 4
	vard %1_ptr, %1, _%1_var
%endmacro

// This one does both
%macro ptrvar 1.nolist		; param: name
	ptrvardec %1
	ptrvarall %1
%endmacro

//
// define a new variable as an offset to a previously declare pointer variable
// ofsname will be equivalent to ptrname+offset
//
// use this macro for such variables, defining them otherwise will confuse
// the reloc.pl Perl script
//
%macro ptrvarofs 3.nolist	; param: ofsname,ptrname,offset
	%1 equ %2+%3
%endmacro



#endif // __VAR_INC__
