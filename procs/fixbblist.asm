#include <defs.inc>
#include <frag_mac.inc>
#include <ptrvar.inc>
#include <patchproc.inc>

extern UpdateBBlockVehicleLists, maxveh, datasize

patchproc generalfixes,patchbblist

begincodefragments

codefragment UpdateBBlockVehicleLists_search
	push	ax
	push	ebx
	push	cx
	push	dx
	push	edi
	push	ebp
	xor	ebx, ebx
	cmp	ax, 8000h
	jz	near $+0xB1+6 //loc_55FD1B
	mov	bx, [esi+2Ah]
	cmp	bx, 8000h
	jz	near $+0xCE+6 //loc_55FD47
	mov	dx, [esi+2Eh]

codefragment UpdateBBlockVehicleLists_anticrash
	icall UpdateBBlockVehicleLists_anticrash_proc
	setfragmentsize 8

endcodefragments

patchbblist:
	stringaddress UpdateBBlockVehicleLists_search
	mov [UpdateBBlockVehicleLists], edi
	add edi, 0x55FCCB-0x55FC55
	storefragment UpdateBBlockVehicleLists_anticrash
	mov edi, [datasize]
	shr edi, 7
	mov [maxveh], di

	ret
