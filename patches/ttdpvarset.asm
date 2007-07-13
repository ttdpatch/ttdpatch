// This is a basic list of includes
#include <std.inc>
#include <textdef.inc>

%macro patchvar 1
	extern %1
	dd %1
	global %1_varnum
	%1_varnum equ %$varnum<<16
	%assign %$varnum %$varnum+1
%endmacro
%macro enddwords 0-1.nolist 0
	%ifctx dwordvars
		dword_varcount equ %$varnum
		%repl wordvars
	%endif
%endmacro
%macro endwords 0-1.nolist 0
	%ifctx wordvars
		word_varcount equ %$varnum - dword_varcount
		%repl bytevars
	%endif
%endmacro


%macro startpatchvars 0
	vard SetTTDpatchVarList
	%push dwordvars
	%assign %$varnum 0
%endmacro
%macro endpatchvars 0
	enddwords
	endwords
	byte_varcount equ %$varnum - word_varcount - dword_varcount
	%pop
	endvar
%endmacro


// patchvar[bwd] each take the name of the variable, and generate {variable}_varnum for moving into ebx.

%macro patchvarb 1.nolist
	enddwords
	endwords
	patchvar %1
%endmacro
%macro patchvarw 1.nolist
	enddwords
	%ifctx bytevars
		%error "A byte-sized patchvar appears before here."
	%endif
	patchvar %1
%endmacro
%macro patchvard 1.nolist
	%ifctx wordvars
		%error "A word-sized patchvar appears before here."
	%elifctx bytevars
		%error "A byte-sized patchvar appears before here."
	%endif
	patchvar %1
%endmacro


// The most important part, since there is no master list (shame), you will be required to write your own entries here.
// Format is basically the same as the patchaction list. Variables must be sorted widest first.
startpatchvars
	patchvarb newgameyesno
endpatchvars


// The actual meat of this, very simplistic.
// Input:	ebx (top 16 bits) - variable to set. Usually, "mov ebx, {var}_varnum + 1".
//		edi - value to store there
// Trashes everything (Actionhandler's fault)
exported SetTTDpatchVar
//	int3 // For testing purposes
	test bl, 1 // no point in going further on bl = 0
	jz .ret

	shr ebx, 16 // Move the variable type to here
	mov eax, edi // mov our value to store to a more usable registor.

	mov edi, [SetTTDpatchVarList+ebx*4] // Move variables location to edi so we can write to it later


%if dword_varcount // don't bother assembling useless code
	sub ebx, 0+dword_varcount
	jb .Dword
%endif
%if word_varcount
	sub ebx, 0+word_varcount
	jb .Word
%endif
	cmp ebx, 0+byte_varcount
	jb .Byte

// We should not have got here, bad input was given so give a fatal crash back!
.bad:
	ud2

	// Lazy so this basically moves the same value in for higher number of bytes.
%if word_varcount || dword_varcount
%if word_varcount
.Word:
	o16		// demote next instruction to 16 bits
%endif
.Dword:
	mov dword [edi], eax
%endif
.Byte:
	mov byte [edi], al

.ret:
	xor ebx, ebx // This has no cost and theorically can not fail.
	ret

