#include <defs.inc>
#include <frag_mac.inc>

global patchdiskmenu

extern tooldiskbardropdown, changeabandontext, changeabandonaction

begincodefragments

codefragment olddiskmenu
	jz $+2+7
	or dx,dx

codefragment newdiskmenu
	call runindex(diskmenuselection)
	jc $+2+0x25
	setfragmentsize 9

codefragment olddisktoolbardropdown, -14
	mov ebx, 160 + (42 << 16)

codefragment newdisktoolbardropdown
	icall tooldiskbardropdown
	mov eax, 44 + (22 << 16)
	mov bx, 160
	push ecx
	setfragmentsize 19

codefragment newdisksettoolbarnum
	pop ecx
	mov [esi+0x2a],cx
	setfragmentsize 6

codefragment olddisktoolbardropdown2, -9
	mov eax, 44 + (22 << 16)
	mov ebx, 160 + (52 << 16)

codefragment newdisktoolbardropdown2
	icall tooldiskbardropdown
	mov eax, 44 + (22 << 16)
	mov bx, 160
	push ecx
	setfragmentsize 19

codefragment oldchangeabandontext
	mov bx, 0x160

codefragment newchangeabandontext
	icall changeabandontext
	setfragmentsize 17

codefragment oldchangeabandonaction
	mov dl, 2
	mov esi, 0x10038

codefragment newchangeabandonaction
	icall changeabandonaction
	setfragmentsize 7

endcodefragments

patchdiskmenu:
	patchcode olddiskmenu,newdiskmenu,1,1

	// Patches for Disk Menu alterations
	stringaddress olddisktoolbardropdown
	storefragment newdisktoolbardropdown
	add edi,lastediadj+50
	storefragment newdisksettoolbarnum

	stringaddress olddisktoolbardropdown2
	storefragment newdisktoolbardropdown2
	add edi,lastediadj+50
	storefragment newdisksettoolbarnum

	patchcode oldchangeabandontext, newchangeabandontext
	patchcode oldchangeabandonaction, newchangeabandonaction, 1, 2
	ret
