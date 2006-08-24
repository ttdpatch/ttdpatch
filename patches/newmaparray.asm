#include <std.inc>
#include <win32.inc>
#include <map.inc>

// API: 
//	in	esi = tile index
// 		dx:	0..3 = altitude of info
//			0..4 = all bits set, ground tile
//			5..15 = feature
// nma_findentry	// out: eax data
// nma_addentry		// in: ebx data, uses eax
// nma_removeentry  
//

#if 0
%define MAXSLOTFORMAP MAPSIZE*(32)

uvard nma_xyptrs, MAPSIZE, z

uvard nmadataptr
uvard nmareversedmemory
uvard nmausedmemory

struc nmadata
	.altitude:	// 0..4 bits
	.typeid: resw 1	// 5..15 = feature
	.data: resw 1
endstruc

%macro PAGEALIGN 0-1 esi
	add %1, 0x1FFF		// set to 4K page
	and %1, ~0x1FFF
%endmacro


// GetSystemInfo
//  SYSTEM_INFO system_info;
exported newmaparrayinit
#if WINTTDX
	pusha	
	mov eax, esp
	add esp, SYSTEM_INFO_size
	push eax
	call [GetSystemInfo]
	mov eax, [esp+SYSTEM_INFO.dwAllocationGranularity]
	sub esp, SYSTEM_INFO_size
	cmp eax, 4*1024
	jne .fail
	
	mov eax, MAXSLOTFORMAP*nmadata_size
	PAGEALIGN eax
	
	mov [nmareversedmemory], eax
	
	push byte 4				// PAGE_READWRITE
	push 0x2000				// AllocateType MEM_RESERVE
	push eax				// Reserve (without committing)
	push 0					// Address
	call dword [VirtualAlloc]
	test eax,eax
	jz .fail
	mov [nmadataptr], eax
	popa
	call nmareset
	call nmafindlandscapeptrs
	stc
	ret
 .fail:
 	popa
#endif
	clc
	ret

	// Called if newmaparray is enabled but it wasn't present in the savegame
exported nmaclear
	jmp nmareset

exported nmaloadgame
	call nmafindlandscapeptrs
	ret
	
nmareset:
	mov eax, [nmausedmemory]
	call nmamfreememory
	mov eax, MAPSIZE
	call nmamallocmemory
	mov edi, [nmadataptr]
	mov eax, MAPSIZE
.loop:
	mov word [edi+nmadata.altitude], 0xFFFF
	add edi, nmadata_size
	dec eax
	jnz .loop
	ret

// Update the Landscape XY Pointers, usefully for init and loading games.
// uses: eax, ecx, esi, edi
nmafindlandscapeptrs:
	pusha
	mov edi, nma_xyptrs
	mov ecx, 0
.start:
	cmp ax, word [esi+nmadata.altitude]
	cmp ax, 0xFFFF
	je .end	
.next:
	add esi, nmadata_size
	jmp .start
.end:
	inc ecx
	mov [nma_xyptrs+ecx*4], esi
	cmp ecx, MAPSIZE
	jne .next
.done:
	popa
	ret

//	eax = size to add
nmamallocmemory:
	pusha
#if WINTTDX
	mov esi, [nmadataptr]
	add eax, [nmausedmemory]
	mov [nmausedmemory], eax

	push byte 4		// PAGE_READWRITE
	push 0x1000		// AllocateType MEM_COMMIT
	push eax		// dwSize
	push esi		// Address
	call dword [VirtualAlloc]

	test eax,eax
	jz .nomoremem
	
	popa
	clc
	ret
#endif	
.nomoremem:
	popa
	stc
	ret

	//	eax = size to remove at the end
nmamfreememory:
	pusha
#if WINTTDX
	xchg eax, ebx
	mov eax, [nmausedmemory]
	sub eax, ebx
	mov [nmausedmemory], eax
	PAGEALIGN eax
	
	mov ebx, [nmareversedmemory]	// does:	size = nmareversedmemory-neededpages
	sub ebx, eax					//			startptr = neededpages + nmadataptr
	add eax, [nmadataptr]			//

	push 0x4000		// MEM_DECOMMIT
	push ebx		// dwSize
	push esi		// Address
	call dword [VirtualFree]
	test eax,eax
	jz .error
	popa
	clc
	ret
#endif

.error:
	popa
	stc
	ret
	
	
//	in	esi = tile index
// 		dx:	0..4 = altitude of info
//			5..15 = feature
//	carry if nothing could be found
// out: eax = data
exported nma_findentry
	push esi
	and esi, 0xFFFF
	mov esi, dword [nma_xyptrs+esi*4]
	
.start:
	mov ax, word [esi+nmadata.altitude]
	cmp ax, 0xFFFF
	je .fail
	cmp ax, dx
	je .found
	
.next:
	add esi, nmadata_size
	jmp .start
	
.found:
	movzx eax, word [esi+nmadata.data]
	pop esi
	clc
	ret
.fail:
	pop esi
	stc
	ret
	
//	in:	esi = tile index
// 		dx:	0..4 = altitude of info
//			5..15 = feature
//		ebx = data
// uses: eax
exported nma_addentry
	push eax
	push esi
	and esi, 0xFFFF
	mov esi, dword [nma_xyptrs+esi*4]
.start:
	mov ax, word [esi+nmadata.altitude]
	cmp ax, 0x0
	je .foundemptyslot
	cmp ax, 0xFFFF
	je .noemptyslotfound
	
.next:
	add esi, nmadata_size
	jmp .start
	
.noemptyslotfound:
	// in esi on 0xFFFF marker
	call nma_addslot
	jc .fail
	mov word [esi+nmadata.altitude], dx
	mov word [esi+nmadata.data], bx
	
	mov esi, [esp] // get esi from stack!
	and esi, 0xFFFF
	lea esi, [nma_xyptrs+esi*4]
	mov edi, nma_xyptrs+MAPSIZE*4
.fixxynext:
	add esi, 4
	add dword [esi], nmadata_size
	cmp esi, edi
	jne .fixxynext
	
	pop esi
	pop eax
	ret
.foundemptyslot:
	mov word [esi+nmadata.altitude], dx
	mov word [esi+nmadata.data], bx
	clc
.fail:
	pop esi
	pop eax
	ret
	
//	in	esi = tile index
// 		dx:	0..4 = altitude of info
//			5..15 = feature
exported nma_removeentry
	push eax
	push esi
	and esi, 0xFFFF
	mov esi, dword [nma_xyptrs+esi*4]
.start:
	mov ax, word [esi+nmadata.altitude]
	cmp ax, 0xFFFF
	je .fail
	cmp ax, dx
	je .found
	
.next:
	add esi, nmadata_size
	jmp .start
	
.found:
	call nma_remslot
	jc .fail
	mov esi, [esp] // get esi from stack!
	and esi, 0xFFFF
	lea esi, [nma_xyptrs+esi*4]
	mov edi, nma_xyptrs+MAPSIZE*4
.fixxynext:
	add esi, 4
	sub dword [esi], nmadata_size
	cmp esi, edi
	jne .fixxynext
	
	pop esi
	pop eax
	clc
	ret
.fail:
	pop esi
	pop eax
	stc
	ret

//	in	esi = tile index
// 		dx:	0..4 = altitude of info
nma_removeentrys:
	
	ret
	
//	in	esi = tile index
nma_removeallentrys:
	
	ret

	
// in:	esi = pointer where to add an entry (dword aligned)
nma_addslot:
	push eax
	push ebx
	push esi
	push ecx
	mov eax, nmadata_size
	call nmamallocmemory
	jc .notok
	mov ecx, [nmadataptr]
	add ecx, [nmausedmemory]
	sub ecx, esi
	shr ecx, 2
	
	mov eax, [esi]
.next:
	xchg ebx, eax
	add esi, 4
	mov eax, [esi]
	mov [esi], ebx
	dec ecx
	jnz .next
	clc
.notok:
	pop ecx
	pop esi
	pop ebx
	pop eax
	ret

// in:	esi = pointer where to remove an entry (dword aligned)
nma_remslot:
	push eax
	push ecx
	push esi
	push edi
	mov eax, nmadata_size
	call nmamfreememory
	jc .notok
	mov ecx, [nmadataptr]
	add ecx, [nmausedmemory]
	sub ecx, esi
	
	lea edi, [esi+4]
	xchg esi, edi
	rep movsd
	clc
.notok:
	pop edi
	pop esi
	pop ecx
	pop eax
	ret

	
#if 0
// in:	esi = pointer		// dword aligned
//		edi = end pointer
//		ecx = direction +/-	//multiply of 4 if > 3
nma_memmoverelative:
	push eax
	push esi
	push edi
	mov eax, edi
	sub eax, esi
	xchg ecx, eax
	cmp eax, 0
	jg .reverse
	je .done
	
	lea edi, [esi+eax]

	cld
	shr ecx, 1
	jnc .f1
	movsb
.f1:
	shr ecx, 1
	jnc .f2
	movsw
.f2:
	rep movsd
	
	
.done:
	pop edi
	pop esi
	pop eax
	ret
	
	
.reverse:
	std
	lea edi, [esi+eax]
	lea edi, [edi+ecx-1]
	lea esi, [esi+ecx-1]
	shr ecx, 1
	jnc .r1
	movsb
.r1:
	sub edi, 1
	sub esi, 1
	shr ecx, 1
	jnc .r2
	movsw
.r2:
	sub edi, 2
	sub esi, 2
	rep movsd
	
	cld
	pop edi
	pop esi
	pop eax
	ret
#endif
#endif
