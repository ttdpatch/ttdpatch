#include <defs.inc>
#include <frag_mac.inc>


extern errorpopup


global patcherrorpopups
patcherrorpopups:
	mov edi,dword [errorpopup]
	add edi,byte 0x12
	storefragment newdisplayerrorpopup
	ret



begincodefragments

codefragment newdisplayerrorpopup
	call runindex(displayerrorpopup)


endcodefragments
