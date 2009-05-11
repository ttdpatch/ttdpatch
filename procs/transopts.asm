#include <frag_mac.inc>
#include <patchproc.inc>
#include <transopts.inc>
#include <bitvars.inc>

extern newtransopts

begincodefragments

codefragment oldtesttrans
	test byte [displayoptions], 10h

codefragment_call newtesttrans, testtransparency, 5

codefragment oldchangetransparency
	xor byte [displayoptions], 10h

codefragment_jmp newchangetransparency, changetransparency, 5

codefragment finddrawbridge, 2
	jns near $+6+253h

endcodefragments


%macro fragment 1
	db %1
%endmacro

// Note that fragments will be applied from bottom up.
varb transpatchdata
#if WINTTDX
	fragment TROPT_TOWN_BLDG
	fragment TROPT_INDUSTRY
	db 0				// Code for toolbar-dropdown drawing
	fragment TROPT_HQ
	fragment TROPT_OBJECT
	fragment TROPT_STATUE
	fragment TROPT_SHIPDEPOT
	fragment TROPT_TREES
	fragment TROPT_TREES
	fragment TROPT_STATION		// AddRelSprite
	fragment TROPT_STATION		// AddSprite
	fragment TROPT_RAILDEPOT
#else
	fragment TROPT_HQ
	fragment TROPT_OBJECT
	fragment TROPT_STATUE
	fragment TROPT_INDUSTRY
	fragment TROPT_STATION		// AddRelSprite
	fragment TROPT_STATION		// AddSprite
	fragment TROPT_TOWN_BLDG
	fragment TROPT_RAILDEPOT
	fragment TROPT_SHIPDEPOT
	fragment TROPT_TREES
	fragment TROPT_TREES
	// db 0			// Code for toolbar-dropdown drawing (no earlier locations to displace)
#endif
endvar

exported patchmoretransopts

// First, loop through all 12 instances of test byte [displayoptions], 10h
// This is a customized expansion of multipatchcode oldtesttrans, ..., 12
	xor eax,eax
	mov al,12
	mov ecx,eax

.patchloop:
	push ecx
	stringaddress oldtesttrans, 1, eax
	pop ecx
	cmp ecx, 12 - 9*WINTTDX
	jne .nottoolbar
	mov byte [edi+7], 0xEB			// jnz short -> jmp short
	inc edi		// skip this instance in the next search
	jmp short .continue
.nottoolbar:
	mov ah, [transpatchdata + (ecx-1)]
	mov al, 6Ah
	stosw
	storefragment newtesttrans

.continue:
	xor eax,eax		// continue searches
	loop .patchloop

// Transparency toggling
	patchcode changetransparency

// Bridge drawing
	stringaddress finddrawbridge
	add edi, [edi]	// follow the jcc
	sub edi, 18h - 4
	extern drawbridgesprite
	mov eax, drawbridgesprite - 4
	sub eax, edi
	mov [edi], eax
	add eax, 3Ch
	mov [edi-3Ch], eax

// Make getnewsprite update [displayoptions] correctly
	extern skiptransfix
	mov word [skiptransfix], 0D8Bh	// jmp disp8 -> mov ecx, ([addr32])

	extern cfgtransbits,newtransopts
	mov eax, [cfgtransbits]
	mov edi, newtransopts
	stosw		// bits 0..10
	ror eax, 21
	stosw		// bits 21..31
	rol eax, 21-11
	stosw		// bits 11..20

	extjmp setonewayflag
