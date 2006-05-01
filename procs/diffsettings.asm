#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc generalfixes,morecurrencies, patchdiffsettings


extern fndrawstring

begincodefragments

codefragment oldshowdifficultynums,-10
	pop ebp
	pop dx
	pop cx
	add dx,0xb

codefragment newshowdifficultynums
	call runindex(showdifficultynums)
	setfragmentsize 10


endcodefragments


patchdiffsettings:
	xor ecx,ecx
	stringaddress oldshowdifficultynums,1,1
	copyrelative fndrawstring,lastediadj+6
	storefragment newshowdifficultynums
	ret
