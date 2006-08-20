#include <std.inc>
#include <win32.inc>

#if 0
%define MAPSIZE 256*256
%define MAXSLOTFORMAP MAPSIZE*(32)

uvard nma_xyptrs, MAPSIZE, z

uvard nmadataptr
uvard nmareversedmemory
uvard nmausedmemory

struc nmadata
	.altitude:	// 0..3 bits
	.typeid: resw 1	
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

nmareset:
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
	ret
#endif	
.nomoremem:
	popa
	ud2
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
	ret
#endif

.error:
	popa
	UD2
	ret
	
	
//	in	esi = tile index
// 		dx:	0..3 = altitude of info
//			4..15 = feature
//	carry if nothing could be found
// out: eax = data
exported getlandscapedata
	push esi
	and esi, 0xFFFF
	mov eax, dword [nma_xyptrs]
	mov esi, dword [eax*4+esi]
	
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
// 		dx:	0..3 = altitude of info
//			4..15 = feature
//		ebx = data
// uses: eax
nma_addentry:
	push esi
	and esi, 0xFFFF
	mov eax, dword [nma_xyptrs]
	mov esi, dword [eax*4+esi]
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
	push edi
	mov eax, nmadata_size
	call nmamallocmemory
	
	mov edi, [nmadataptr]
	add edi, [nmausedmemory]
	sub edi, nmadata_size
	mov ecx, nmadata_size
	call nma_memmoverelative
	
	mov word [esi+nmadata.altitude], dx
	mov word [esi+nmadata.data], bx
	
	pop edi
	pop esi
	ret

.foundemptyslot:
	mov word [esi+nmadata.altitude], dx
	mov word [esi+nmadata.data], bx
	pop esi
	ret
	
//	in	esi = tile index
// 		dx:	0..3 = altitude of info
//			4..15 = feature
nma_removeentry:
	
	ret

//	in	esi = tile index
// 		dx:	0..3 = altitude of info
nma_removeentrys:
	
	ret
	
//	in	esi = tile index
nma_removeallentrys:
	
	ret
	
	
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
