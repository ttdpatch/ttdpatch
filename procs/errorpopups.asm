#include <defs.inc>
#include <frag_mac.inc>


extern errorpopup


global patcherrorpopups

begincodefragments

codefragment newdisplayerrorpopup
	call runindex(displayerrorpopup)


endcodefragments

patcherrorpopups:
	mov edi,dword [errorpopup]
	add edi,byte 0x12
	storefragment newdisplayerrorpopup
	ret
