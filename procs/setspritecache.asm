#include <defs.inc>
#include <frag_mac.inc>


extern allocspritecache,removespritefromcache
extern spritecache


global patchsetspritecache
patchsetspritecache:
	stringaddress oldloadspriteheader,1,1
	mov eax,[edi-4]
	mov [tempspriteheaderp1],eax
	storefragment newloadspriteheader
	patchcode oldloadspriteheader2,newloadspriteheader,1,1

#if !WINTTDX
		// patch DOS version to use DS memory for sprite cache
	call allocspritecache
	patchcode oldallocspritecache,newallocspritecache,1,1
	mov byte [edi+lastediadj+0xe2],0x89	// xor -> mov
	multipatchcode oldgetspritecache,newgetspritecache,3
	patchcode oldgetspritecachess,newgetspritecachess,1,1

	mov edi,[removespritefromcache]
	add edi,12
	storefragment newremovespritefromcache
#endif
	ret


begincodefragments

codefragment oldloadspriteheader,9
	mov esi,[esp]
	db 0x66,0xa1		// mov ax,[tempspriteheader+1]

codefragment newloadspriteheader
	call runindex(loadspriteheader)
	jc $+2+68
	setfragmentsize 9

codefragment oldloadspriteheader2,7
	pop esi
	mov ax,[0]
tempspriteheaderp1 equ $-4


endcodefragments

begincodefragments

#if !WINTTDX
codefragment oldallocspritecache,-6
	db 0x18
	db 0x0f,0x85,0x81,0x00	// jnz near...

codefragment newallocspritecache
	mov ecx,[spritecache]
	mov eax,ds
	jmp fragmentstart+0xd9	// jump to the last-resort page lock attempt

codefragment oldgetspritecache
	db 0x66
	mov es,[spritecacheselector]
	xor esi,esi

codefragment newgetspritecache
	mov esi,[spritecache]
	push ds
	pop es
	nop

codefragment oldgetspritecachess,-2
	mov es,[spritecacheselector]
	xor esi,esi

codefragment newgetspritecachess
	mov esi,[ss: spritecache]
	push ss
	pop es
	nop

codefragment newremovespritefromcache
	call runindex(clearspritecacheblock)
	setfragmentsize 7
#endif


endcodefragments
