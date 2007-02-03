// Various functions needed to handle the landscape8 array

#include <std.inc>
#include <flags.inc>
#include <loadsave.inc>
#include <house.inc>

extern l8switches, patchflags
ptrvar landscape8

//
// Usage of L8 Array
//
// Class	Usage
// (in L4)
//
//

// Called if landscape8 is enabled but it wasn't present in the savegame
// Clear landscape8 and l8switches so the initialization can proceed
global landscape8clear
landscape8clear:
	pusha
	mov edi, landscape8		// first, fill it with zeroes
	xor eax, eax
	mov ecx, 0x20000/4
	rep stosd
	and dword [l8switches],0
	popa
	ret

// Fill landscape8 entries with default values and/or values derived from existing arrays
// if the given feature wasn't active at save time
// l6switches contains the bitmap of which L8 switches were active at save time
global landscape8init
landscape8init:
	pusha
	mov eax, landscape8
	xor ecx, ecx

	popa
	ret

