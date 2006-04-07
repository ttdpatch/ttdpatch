#include <defs.inc>
#include <frag_mac.inc>


extern keyscantochar.chartable,translatewinchar.addtoqueuefn


global patchkbdhandler

begincodefragments

#if WINTTDX
codefragment findoldaddchartoqueue,35
	sub dword [ebp-0x38],0x100

codefragment newaddchartoqueue
	call runindex(translatewinchar)
	setfragmentsize 9

#else
codefragment oldkeyscantochar
	db 0x0a,0xd8	// or bl,al
	db 0x8a,0x83	// mov al,byte [ebx+...

codefragment newkeyscantochar
	call runindex(keyscantochar)
newkeyscantochar.jumpoffset equ $-fragmentstart
	jc short $+2+0x18

codefragment oldcheckmouseemualt,9
	pop ax
	push ax
	db 0xa0		// mov al,...

codefragment newcheckmouseemualt
	call runindex(checkmouseemualt)
	jnz short $+2+0x65		// skip Insert and Home as well
#endif

codefragment oldcheckforexitkey,-2
	jnz short $+2+0xa
	db 0x66,0x0f,0xba	// bts word...

codefragment newcheckforexitkey
	call runindex(checkforexitkey)
	jc short $+0x1e-0x16*WINTTDX
	js short $+0x25-0x16*WINTTDX
	jnz short $+2+2
	ret

codefragment oldcheckforarrowkeys
	jz short $+2+0x71
	xor ax,ax

codefragment newcheckforarrowkeys
	call runindex(checkforarrowkeys)
	jz short $+2+0x6b


endcodefragments

patchkbdhandler:
#if WINTTDX
	stringaddress findoldaddchartoqueue
	mov edi,[edi]
	add edi,3
	copyrelative translatewinchar.addtoqueuefn,2
	storefragment newaddchartoqueue
#else
	stringaddress oldkeyscantochar,1,2
	mov eax,[edi+4]
	mov [keyscantochar.chartable],eax
	storefragment newkeyscantochar
	patchcode oldkeyscantochar,newkeyscantochar,1,0
	mov byte [edi+lastediadj+newkeyscantochar.jumpoffset+1],8

	patchcode oldcheckmouseemualt,newcheckmouseemualt,1,1
#endif
	patchcode oldcheckforexitkey,newcheckforexitkey,1,1
	patchcode oldcheckforarrowkeys,newcheckforarrowkeys,1,1
	ret
