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

codefragment oldrailtoolselect
	sub al,'1'
	cmp al,4
maxtoolnum equ $-1

codefragment newrailtoolselect
	nop
	mov ah,0
	call runindex(toolselect)
	setfragmentsize 9

reusecodefragment oldrvtoolselect,oldrailtoolselect,-4

codefragment newrvtoolselect
	push ax
	icall rvtoolselect
	jne fragmentstart+0x18c-0x178
	setfragmentsize 13

endcodefragments

patchmorehotkeys:
	patchcode oldhotkeycenter,newhotkeycenter,1,1

	mov byte [edi+lastediadj+19],0
	mov byte [edi+lastediadj+23],0
	mov byte [edi+lastediadj+52],0x90

	patchcode railtoolselect
	mov ebx,maxtoolnum
	mov byte [ebx],2	// 2 tools selectable for road vehicles
	patchcode rvtoolselect
	ret

