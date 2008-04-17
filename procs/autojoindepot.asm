#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc custombridgeheads, patchautojoinraildepot
patchproc custombridgeheads,newstations,trams, patchautojoinroaddepot

begincodefragments

codefragment oldrailautojoincheck, 2
	cmp al, 0x10
	jnz $+2+0x2f+2*WINTTDX

codefragment_call newrailautojoincheck, autojoinraildepotcheck, 8+2*WINTTDX

codefragment oldroadautojoincheck, -2
	cmp al, 0x20
	jnz $+2+0x52

codefragment_call newroadautojoincheck, autojoinroaddepotcheck, 6

endcodefragments

patchautojoinraildepot:
	patchcode railautojoincheck
	ret

patchautojoinroaddepot:
	patchcode roadautojoincheck
	ret
