#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc morehotkeys, patchmorehotkeys

begincodefragments

codefragment oldhotkeycenter
	cmp al, 63h
	jnz $+2+4		//00558AAD   75 04    JNZ SHORT TTDLOADW.00558AB3
	xor al,al
	db 0xEB		//jmp 

codefragment newhotkeycenter
	call runindex(hotkeyfunction)
	db 0x74	 //jz

codefragment oldtoolselect
	sub al,'1'
	cmp al,4
maxtoolnum equ $-1

codefragment newtoolselect
	nop
	mov ah,0
tooltype equ $-1
	call runindex(toolselect)
	setfragmentsize 9


endcodefragments

patchmorehotkeys:
	patchcode oldhotkeycenter,newhotkeycenter,1,1

	mov byte [edi+lastediadj+19],0
	mov byte [edi+lastediadj+23],0
	mov byte [edi+lastediadj+52],0x90

	patchcode oldtoolselect,newtoolselect,1,1
	mov ebx,maxtoolnum
	mov byte [ebx],2	// 2 tools selectable for road vehicles
	mov byte [byte ebx+tooltype-maxtoolnum],1	// mark as road vehicles
	patchcode oldtoolselect,newtoolselect,1,1
	ret
