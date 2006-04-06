#include <defs.inc>
#include <frag_mac.inc>
#include <ptrvar.inc>


global patchremovespecobjects
patchremovespecobjects:
	mov edi,[ophandler+0xa*8]
	mov edi,[edi+0x18]
	add edi,18
	xor ecx,ecx
	storefragment newremoveobject
	ret



begincodefragments

codefragment newremoveobject
	call runindex(removeobject)
	setfragmentsize 14


endcodefragments
