#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>
#include <ptrvar.inc>

extern rvovertakeparamsvalue, detectedcolidedrvptrptr
patchproc rvovertakeparams, patchrvovertakeparams

begincodefragments

codefragment rvovertakefrag1, 0x16647F-0x001664AB
	movzx edi, WORD [esi+veh.XY]
	mov ax, 2
	push esi
	db 0xE8

codefragment rvotfiller1
	setfragmentsize 11
	
codefragment rvotfiller2
	setfragmentsize 7

codefragment rvovertakemaxcounter,6
	inc     BYTE [esi+0x67]
	cmp     BYTE [esi+0x67], 23h

codefragment rvotcall1
	icall rvotcall1_hook
	setfragmentsize 8

endcodefragments

global patchrvovertakeparams
patchrvovertakeparams:
	stringaddress rvovertakefrag1
	push edi
	mov eax, [rvovertakeparamsvalue]

	test al, 1
	jz .nopatch1
	storefragment rvotfiller1
	mov edi, [esp]
.nopatch1:

	test al, 2
	jz .nopatch2
	add edi, 0x1664D7-0x16647F
	storefragment rvotfiller2
	mov edi, [esp]
.nopatch2:

	test al, 4
	jz .nopatch3
	add edi, 0x1664E9-0x16647F
	storefragment rvotfiller2
	mov edi, [esp]
.nopatch3:

	test al, 8
	jz .nopatch4
	add edi, 0x166510-0x16647F
	storefragment rvotfiller2
	mov edi, [esp]
.nopatch4:

	test al, 32
	jz .nopatch5
	add edi, 0x166527-0x16647F
	mov ecx, eax
	shr ecx, 16
	mov [edi], cl
	mov edi, [esp]
	xor ecx, ecx
.nopatch5:

	test al, 64
	jz .nopatch6
	add edi, 0x1664BA-0x16647F
	storefragment rvotcall1
	mov edi, [esp]
	mov ecx, [edi+2+0x166461-0x16647F]
	mov [detectedcolidedrvptrptr], ecx		//ecx=ptr to veh ptr
	xor ecx, ecx
.nopatch6:

	pop edi
	push eax
	stringaddress rvovertakemaxcounter
	pop eax
	test al, 16
	jz .nopatch7
	mov [edi], ah
.nopatch7:

ret
