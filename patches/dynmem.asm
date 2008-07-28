//dynamic memory allocation
// how this works:
//  at the beginnning of each allocated block, 4 bytes extra are stored. 
//  bit 31 is 0 if this block is free, and 1 otherwise; the other 31 bits
//  indicate the size of the block
// TODO: make dmalloc allocate extra memory if no large enough free block can be found (only possible in WINTTD?)

#include <std.inc>
#include <pusha.inc>


uvard dynmemstart,1,s
uvard dynmemend,1,s

//IN: ecx = size of memory to allocate
//OUT: edi = pointer to memory
global dmalloc
dmalloc:
// Search for a block that is large enough to contain ecx+4. If multiple such blocks, use the smallest.
// If no such blocks, fail (allocate extra memory, not possible in dos?)
	pusha
	mov esi, [dynmemstart]
	add ecx, 7
	and ecx, ~3
	or eax, byte -1
.searchloop:
	cmp esi, [dynmemend]
	jae .done
	mov edx, [esi]
	btr edx, 31
	jc .next
	cmp edx, ecx		// Big enough?
	jb .next
	cmp edx, eax		// Smaller than previous free block?
	jae .next
	mov eax, edx
	mov edi, esi
.next:
	or edx, edx
	jz .done	// This can only happen if the arena is corrupt; handle it as gracefully as possible.
	add esi, edx
	jmp .searchloop

.done:
	or eax, eax
	extern outofmemoryerror
	js outofmemoryerror

.found:
	mov ebx, eax
	sub ebx, ecx
	cmp ebx, 16
	jnge .dontsplit
	mov eax, ecx
	mov [edi+eax], ebx
.dontsplit:
	bts eax, 31
	mov [edi], eax
	add edi, 4
	mov [esp+_pusha.edi], edi
	popa
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
	lea esi, [edi+eax]
	cmp esi, [dynmemend]
	jae .done

	bt dword [esi],31
	jc .notempty	// next block not free, can't merge more

	add eax,[esi]
	mov [edi],eax
	jmp .mergenext
	
.notempty:
	add edi,eax
	jmp .searchloop
.done:
	popa
	ret

