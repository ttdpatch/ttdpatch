#include <defs.inc>
#include <frag_mac.inc>


extern newgraphicssetsenabled


global patchmodifysignals

begincodefragments

codefragment oldmodifysignals
		// use "nosplit" to prevent nasm from making this edi+edi
	and [nosplit landscape3+edi*2],bh

codefragment newmodifysignals
	call runindex(modifysignals)
	setfragmentsize 7

codefragment oldshowtrackinfo
	mov ax,0x1021
	and cl,0xc0

codefragment newshowtrackinfo
	call runindex(showtrackinfo)
	setfragmentsize 7


endcodefragments

patchmodifysignals:
	patchcode oldmodifysignals,newmodifysignals,1,1
	patchcode oldshowtrackinfo,newshowtrackinfo,1,1
	or byte [newgraphicssetsenabled],1 << 4
extern semaphoredate, semaphoreyear
	mov al, [semaphoreyear]
	sub al, (1920 & 0xFF)
	mov [semaphoredate],al
	ret
