#include <defs.inc>
#include <frag_mac.inc>
#include <station.inc>

extern cargoforgettime,inctimesincepickedup.forgettime


global patchselectstationgoods

begincodefragments

codefragment oldfindstations
	cmp byte [ebp+0x84],0

codefragment newfindstations
	call runindex(findstations)
	nop

codefragment oldinctimesincepickedup
	inc al
	jz .overflow
	mov [ebx+esi+stationcargo.timesincevisit+0x1c],al
.overflow:

codefragment newinctimesincepickedup
	call runindex(inctimesincepickedup)
	setfragmentsize 8


endcodefragments

patchselectstationgoods:
	patchcode oldfindstations,newfindstations,1,1
	patchcode oldinctimesincepickedup,newinctimesincepickedup,1,1,,{cmp word [cargoforgettime],2},nz
	push edx
	mov ax,[cargoforgettime]
	mov bx,74
	mul bx
	mov bx,185
	div bx
	mov [inctimesincepickedup.forgettime],al
	pop edx
	ret
