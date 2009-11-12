#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>
#include <window.inc>
#include <win32.inc>
#include <dest.inc>

extern outofmemoryerror,cargodestdata,cargodestdata_size

patchproc cargodest, patchcargodest

patchproc cargodest, BIT(MISCMODS2_NOSTATCARGOLEAK), patchnocargoleak

begincodefragments

codefragment oldtestratingcargoamountinstationratingcheck, 6	//_CS:0014F85A, 0054BC98
	add     ah, dl
	mov     [ebx+esi+0x1F], ah
	cmp     ah, 40h
	db	0x77

codefragment newtestratingcargoamountinstationratingcheck
	xor di, di
	setfragmentsize 5

endcodefragments

patchcargodest:
#if WINTTDX
	pushad
/*
	push byte 4				// PAGE_READWRITE
	push 0x2000				// AllocateType MEM_RESERVE
	push cargopacketstore_reservesize	// Size
	push 0					// Address
	call dword [VirtualAlloc]
	mov [cargopacketstore], eax
	or eax, eax
	jz NEAR outofmemoryerror
*/

	push byte 4				// PAGE_READWRITE
	push 0x2000				// AllocateType MEM_RESERVE
	push cargodestdata_reservesize		// Size
	push 0					// Address
	call dword [VirtualAlloc]
	mov [cargodestdata], eax
	or eax, eax
	jz NEAR outofmemoryerror
	
	popad
#else
	push DWORD cargodestdata_initialsize
	extern calloccrit
	call calloccrit
	pop eax
	mov [cargodestdata], eax
	mov DWORD [cargodestdata_size], cargodestdata_initialsize
#endif
ret

patchnocargoleak:
	patchcode testratingcargoamountinstationratingcheck
	ret
