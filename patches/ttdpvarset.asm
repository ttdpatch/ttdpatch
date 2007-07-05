// This is a basic list of includes
#include <std.inc>
#include <textdef.inc>

// The actual meat of this, very simplistic.
// Input:	ebx (top 16 bits) - variable to set, see list below. (0 is the first variable)
//		edi - value to store there
// Trashes everything (Actionhandler's fault)
exported SetTTDpatchVar
//	int3 // For testing purposes
	test bl, 1 // no point in going further on bl = 0
	jz .ret

	shr ebx, 16 // Move the variable type to here
	mov eax, edi // mov our value to store to a more usable registor.

	lea ecx, [SetTTDpatchVarList+ebx*5] // Get the offset in the list
	cmp ecx, SetTTDpatchVarListLast // We must NOT exceed this list, bad input otherwise
	jae .bad

	mov edi, [ecx] // Move variables location to edi so we can write to it later
	cmp byte [ecx+4], 2 // whats our size?
	jb .Byte
	je .Word

	// Lazy so this basically moves the same value in for higher number of bytes.
	mov dword [edi], eax
.Word:
	mov word [edi], ax
.Byte:
	mov byte [edi], al

.ret:
	mov ebx, 0 // This has no cost and theorically can not fail.
	ret

// We should not have got here, bad input was given so give a fatal crash back!
.bad:
	ud2
	ret

// The most important part, since there is no master list (shame), you will be required to write your own entries here.
// Format is quite simple (below), please not size must be a byte, word or dowrd. Qwords (8 bytes) are not supported.
// extern <var>
// dd <var>
// db <size>
// This gives it the offset every 5 bytes and the fifth byte is the size.
//
// DO NOT CHANGE THE ORDER OF THESE!
var SetTTDpatchVarList
extern newgameyesno	//  Yay I get first entry, needed otherwise you will get a crash when trying to
	dd newgameyesno	// use the disk menu's 'new game' option I added along time ago.
	db 1


 // pointer is used to determine the end of the list, to stop overflows
var SetTTDpatchVarListLast
	db 0

