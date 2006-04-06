#ifndef __VAR_INC__
#define __VAR_INC__

// macros for defining variables in TTD's and TTDPatch's memory space
%define addr(x) (x) //-protectedstart+runindexbase)

// all TTDPatch variables need to be counted relative to protectedstart,
// which is really located at runindexbase, so calculate them accordingly
%macro var 1-2+.nolist	// params: variablename [, initialization]
	global %1
	%1: %2;
%endmacro

// ovar defines a variable with an offset to the current position (or
// another variable)
%macro ovar 2-4.nolist $, // params: variablename, offset [, basis [, fullname]]
	global %4%1
	%1 equ addr(%3)+(%2)
%endmacro

// Define an uninitialized variable
// (really it'll be initialized to 0 or -1, but take no space in the .exe file)
// initval can be either z for zero or s for signed (-1) initialization

%macro uvar 1-4.nolist d,1,z	; params: name [,size [,number [,initval]]]
	%error "The uvar macro is no longer supported, please use uvard,uvarw oder uvarb"
%endmacro
%define sectname_1z .bss1
%define sectname_1s .sbss1
%define sectname_2z .bss2
%define sectname_2s .sbss2
%define sectname_4z .bss
%define sectname_4s .sbss
%macro sdef 3.nolist		; params bss-type, varname, varnum
	%define %%sectname sectname_%1
	[section %%sectname]
	global %2
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
	_%1_var: dd $
	__SECT__
	align 4
	%1_ptr: dd %1, _%1_var
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
