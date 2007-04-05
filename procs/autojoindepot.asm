#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc custombridgeheads, enhancetunnels, patchautojoinraildepot

begincodefragments

codefragment oldautojoincheck, 2
	cmp al, 0x10
	jnz $+2+0x2f+2*WINTTDX

codefragment_call newautojoincheck, autojoinraildepotcheck, 8+2*WINTTDX

endcodefragments

patchautojoinraildepot:
	patchcode autojoincheck
	ret
