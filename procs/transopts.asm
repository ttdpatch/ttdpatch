#include <frag_mac.inc>
#include <patchproc.inc>
#include <transopts.inc>
#include <bitvars.inc>

extern newtransopts

begincodefragments

codefragment oldtesttrans, 2
	test byte [displayoptions], 10h

codefragment newtesttrans
transloc: dd newtransopts
	db 0

codefragment_call callmaybehidetrees, maybehidetrees, 6

codefragment oldchangetransparency
	xor byte [displayoptions], 10h

codefragment_jmp newchangetransparency, changetransparency, 5

codefragment finddrawbridge, 2
	jns near $+6+253h

endcodefragments


%macro fragment 1
	db 1<<(%1 % 8), %1/8
%endmacro

// Note that fragments will be applied from bottom up.
varb transpatchdata
#if WINTTDX
	fragment TROPT_TOWN_BLDG
	fragment TROPT_INDUSTRY
	dw 0				// Code for toolbar-dropdown drawing
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
	// dw 0			// Code for toolbar-dropdown drawing (no earlier locations to displace)
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
#if WINTTDX
	cmp ecx, 3
#else
	cmp ecx, eax
#endif
	jne .nottoolbar
	stringaddress oldtesttrans, 1, eax
	mov byte [edi+5], 0xEB			// jnz short -> jmp short
	jmp short .continue
.nottoolbar:
	mov ebx, transloc
	and byte [ebx], ~1	// newtransopts is at least word aligned
	mov cx, [transpatchdata + (ecx-1)*2]
	add [ebx], ch
	mov [ebx+4], cl

	patchcode testtrans, 1, eax
	xor byte [edi], 1		// swap jnz/jz condition.

	cmp dword [esp], 10-WINTTDX*2
	jne .continue
	inc edi
	inc edi
	storefragment callmaybehidetrees

.continue:
	pop ecx
	xor eax,eax		// continue searches
	dec ecx
	jnz near .patchloop

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

	ret
