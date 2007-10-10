//
//
//

// Includes
#include <std.inc>
#include <ptrvar.inc>

// External functions, variables etc
extern GetCallback36 // The most IMPORTANT function for this file

// ** Aircraft Functions **
global aircraftmaintcost, aircraftmaintcost.ledi, aircraftmaintcost.lesi
aircraftmaintcost:
	test bh, bh	// Skip special vehicles: UFOs, military, &c.
	jnz .bad
.notest:
	push ecx
	movzx ecx, byte [planeruncostfactor-0xD7+ebx]
	mov ah, 0xE
	mov al, bl
	call GetCallback36
	movzx eax, al
	pop ecx
.bad:
	ret

.lesi:
	push esi
	xor esi, esi
	call .notest
	pop esi
	ret

.ledi:
	push ebx
	mov ebx, edi
	call .notest
	pop ebx
	ret

// ** Ship Functions **
global shipmaintcost, shipmaintcost.ledi, shipmaintcost.lesi
shipmaintcost:
	push ecx
	movzx ecx, byte [shipruncostfactor-0xCC+ebx]
	mov ah, 0xF
	mov al, bl
	call GetCallback36
	movzx eax, al
	pop ecx
	ret

.lesi:
	push esi
	xor esi, esi
	call shipmaintcost
	pop esi
	ret

.ledi:
	push ebx
	mov ebx, edi
	call shipmaintcost
	pop ebx
	ret
