//
//
//

// Includes
#include <std.inc>
#include <ptrvar.inc>

// External functions, variables etc
extern GetCallBack36 // The most IMPORTANT function for this file

// ** Aircraft Functions **
global aircraftmaintcost, aircraftmaintcost.ledi, aircraftmaintcost.lesi
aircraftmaintcost:
	push ecx
	test bh, bh
	jnz .bad
	movzx ecx, byte [planeruncostfactor-0xD7+ebx]
	mov ah, 0xE
	mov al, bl
	call GetCallBack36 
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
	call GetCallBack36 
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
	call GetCallBack36 
	movzx eax, al
	pop ebx
	pop ecx
	ret

