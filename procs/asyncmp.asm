#if WINTTDX
#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchprocandor experimentalfeatures,BIT(EXP_ASYNCMP),, patchasyncmp

begincodefragments

codefragment oldmainmenuoldstart2player, 13
	mov bl, 1
	mov esi, 0x10060
	
codefragment newmainmenuoldstart2player
	ijmp AsyncMPConnectStart
	ret
	
endcodefragments

patchasyncmp:
	patchcode mainmenuoldstart2player
	ret
#endif
