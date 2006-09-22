//dynamic memory allocation
// how this works:
//  at the beginnning of each allocated block, 4 bytes extra are stored. 
//  bit 31 is 0 if this block is free, and 1 otherwise; the other 31 bits
//  indicate the size of the block
// TODO: make dmalloc allocate extra memory if no large enough free block can be found (only possible in WINTTD?)
// TODO: make dmalloc a best-fit instead of first-fit algorithm?

#include <std.inc>



uvard dynmemstart,1,s
uvard dynmemend,1,s

//IN: ecx = size of memory to allocate
//OUT: edi = pointer to memory
global dmalloc
dmalloc:
// first try to find a block that is large enough to contain ecx+4, if this can't be found loop through (not yet implemented)
// the list to merge free blocks together and try again, if still no blocks can be found, fail (allocate extra memory, not possible in dos?)
	push eax
	mov edi, [dynmemstart]
	add ecx, 4
.searchloop:
	cmp edi, [dynmemend]
	jae .fail
	mov eax, [edi]
	test eax, 80000000h
	jnz .next
	and eax, 7fffffffh
	cmp eax, ecx
	jae .found
.next:
	and eax, 7fffffffh
	cmp eax, 0	//shouldn't happen, but somehow it happens quite a lot of times... luckily with this check it works...
	jz .fail
	add edi, eax
	jmp .searchloop
	
.fail:
	extern outofmemoryerror
	jmp outofmemoryerror
	pop eax
	stc
	ret

.found:
	push ebx
	mov ebx, eax
	sub ebx, ecx
	cmp ebx, 16
	jnge .dontsplit
	mov eax, ecx
	mov [edi+eax], ebx
.dontsplit:
	or eax, 80000000h
	mov [edi], eax
	add edi, 4
	pop ebx
	pop eax
	clc
	ret

//IN: edi = pointer to memory
global dfree
dfree:
	sub edi, 4
	mov eax, [edi]
	and eax, 7fffffffh
	lea esi, [edi+eax]
	cmp esi, [dynmemend]
	jae .notnextfree	// this is the last block, so don't check the next
	test dword [esi], 80000000h
	jnz .notnextfree	// the next block isn't free, so don't merge with it
	mov ebx, [esi]
	and ebx, 7fffffffh
	add eax, ebx
.notnextfree:
	mov [edi], eax
	ret

// compact the memory: join adjacent free blocks
exported dmemcompact
	pusha
	mov edi, [dynmemstart]
.searchloop:
	cmp edi, [dynmemend]
	jae .done
	mov eax,[edi]
	btr eax,31
	jc .notempty	// current block not free, can't merge

.mergenext:
	lea esi,[edi+eax+4]
	cmp esi, [dynmemend]
	jae .done

	test dword [esi-4],0x80000000
	jnz .notempty	// next block not free, can't merge more

	add eax,[esi-4]
	mov [edi],eax
	jmp .mergenext
	
.notempty:
	add edi,eax
	jmp .searchloop
.done:
	popa
	ret

