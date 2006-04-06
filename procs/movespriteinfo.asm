#include <defs.inc>
#include <frag_mac.inc>
#include <grf.inc>

extern dofindstring.failmiserably,exsgetspritecount,malloc
extern lastsearchcalladdr,newspritedata,newspritenum,patchflags
extern spritearraysize,spriteblockptr
extern storespritelastrequestnum


global patchmovespriteinfo
patchmovespriteinfo:
		// patch TTD to use new variables for all
		// sprite arrays between 7f9e8 and 9c458

		// this would create too much version data, so we
		// do the searching even with version data
	xor edi,edi

		// note, if search indicates failure at this line,
		// it was probably the total count of spritearray
		// references below that was incorrect
	stringaddress findspriteprocstart,1,0

	mov dword [lastsearchcalladdr],addr(.checktotaloccurences)+5

	mov cl,11
	mov eax,spritedata

#if 1
	push ecx
	call exsgetspritecount
	imul ebx, ebx, 24
	pop ecx
	push ebx
#else 
	push 24*16384	// make room for 16384 sprites
#endif
	call malloc
	pop ebx
	jnc .havememory

		// no memory for new sprite data
		// keep only the first block
	mov eax,[spriteblockptr]
	and dword [byte eax+spriteblock.next],0
	movzx eax,word [byte eax+spriteblock.numsprites]
	testflags canmodifygraphics,btc
	ret

.havememory:
	mov [newspritedata],ebx
	
#if 1
	push ebx
	call exsgetspritecount
	mov dword [newspritenum], ebx
	pop ebx
#else
	mov dword [newspritenum],16384
#endif	
	xor esi,esi

#if WINTTDX
	sub edi,0x400	// In TTD/Win the sprite array accesses start earlier
#endif

.nextvar:
	push edi
	push ecx

	mov ecx,0x40000
.continue:
	repne scasb
	jne short .done
	cmp [edi-1],eax
	jne short .continue

	cmp eax,spritelastrequestnum
	jne short .dontpatchtranslation

	cmp word [edi-4],0x3489
	jne short .dontpatchtranslation

	pusha
	mov bl,0x90
	sub edi,byte 5
	cmp byte [edi],0x36
	jne short .notss

	mov [edi-1],bl

.notss:
	cmp byte [edi+3],0x5d
	je short .noteax
	mov bl,0x93
.noteax:
	xor ecx,ecx
	storefragment newtranslatesprite
	mov [edi+lastediadj],bl
	mov [edi+lastediadj+7],bl
	popa
	mov [storespritelastrequestnum],ebx
	inc esi
	jmp short .continue

.dontpatchtranslation:
	mov [edi-1],ebx
	inc esi		// count number of changes
	jmp short .continue

.done:
	pop ecx
	mov edi,ecx
	neg edi
	movzx edi,byte [edi+spritearraysize+11]
#if 1
	push ecx
	push edi
	push ebx
	call exsgetspritecount
	imul edi, ebx
	pop ebx
	add ebx, edi
	pop edi
	pop ecx
#else
	shl edi,14 	// *16384
	add ebx,edi
	shr edi,14
#endif

	imul edi,totalsprites
	add eax,edi
	pop edi
	dec ecx
	jnz .nextvar
.checktotaloccurences:
	cmp esi,121
	jne near dofindstring.failmiserably
	ret



begincodefragments

codefragment findspriteprocstart,-17
	mov es,[spritecacheselector]

codefragment newtranslatesprite
	nop
	call runindex(translatesprite)
	nop


endcodefragments
