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
	push ecx
	test bh, bh
	jnz .bad
	movzx ecx, byte [planeruncostfactor-0xD7+ebx]
	mov ah, 0xE
	mov al, bl
	call GetCallback36
	movzx eax, al
.bad:
	pop ecx
	ret

.lesi:
	push ecx
	push esi
	xor esi, esi
	movzx ecx, byte [planeruncostfactor-0xD7+ebx]
	mov ah, 0xE
	mov al, bl
	call GetCallback36
	movzx eax, al
	pop esi
	pop ecx
	ret

.ledi:
	push ecx
	push ebx
	mov ebx, edi
	movzx ecx, byte [planeruncostfactor-0xD7+ebx]
	mov ah, 0xE
	mov al, bl
	call GetCallback36
	movzx eax, al
	pop ebx
	pop ecx
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
	push ecx
	push esi
	xor esi, esi
	movzx ecx, byte [shipruncostfactor-0xCC+ebx]
	mov ah, 0xF
	mov al, bl
	call GetCallback36
	movzx eax, al
	pop esi
	pop ecx
	ret

.ledi:
	push ecx
	push ebx
	mov ebx, edi
	movzx ecx, byte [shipruncostfactor-0xCC+ebx]
	mov ah, 0xF
	mov al, bl
	call GetCallback36
	movzx eax, al
	pop ebx
	pop ecx
	ret
