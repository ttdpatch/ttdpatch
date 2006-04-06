#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc freighttrains, patchfreighttrains

begincodefragments

codefragment oldshowwagonload,-6
	mov bx,0x8813
	jmp $+6

codefragment newshowwagonload
	call runindex(showwagonload)
	setfragmentsize 10


endcodefragments

patchfreighttrains:
	patchcode oldshowwagonload,newshowwagonload,1,1
	ret
