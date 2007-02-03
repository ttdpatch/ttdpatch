#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>
#include <ptrvar.inc>
#include <textdef.inc>
#include <misc.inc>
#include <vehtype.inc>

extern vehcallback

uvard	rvCollisionPointX
uvard	rvCollisionPointY
;		   N  NE E  SE S  SW W  NW
var	arrayX, db 00,01,00,00,00,01,00,00
var	arrayY, db 00,00,00,01,00,00,00,01


global adjustVehicleOffsetsForShortVehiclesX
adjustVehicleOffsetsForShortVehiclesX:
	push	eax
	mov	eax, dword [rvCollisionPointX]
	add	eax, ebx
	movzx	dx, [eax]
	xor	eax, eax
	mov	al, 0x11
	call	vehcallback
	jnc	.isshortened
	pop	eax
	retn
.isshortened:
	push	ebx
	xor	ebx, ebx
	mov	bl, [arrayX+ebp]
	imul	ax, bx
	pop	ebx
	sub	dl, al
	pop	eax
	retn

global adjustVehicleOffsetsForShortVehiclesY
adjustVehicleOffsetsForShortVehiclesY:
	push	eax
	mov	eax, dword [rvCollisionPointY]
	add	eax, ebx
	mov	dl, [eax]
	xor	eax, eax
	mov	al, 0x11
	call	vehcallback
	jnc	.isshortened
	pop	eax
	retn
.isshortened:
	push	ebx
	xor	ebx, ebx
	mov	bl, [arrayY+ebp]
	imul	ax, bx
	pop	ebx
	sub	dl, al
	pop	eax
	retn
