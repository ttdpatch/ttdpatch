
#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchprocandor experimentalfeatures,BIT(EXP_NEWTERRAINGEN),, patchterraingen

begincodefragments

codefragment oldrandomland,-5
	mov edx, eax
	shr edx, 16

codefragment_call newrandomland,_makerandomterrain,5

endcodefragments

patchterraingen:
//	patchcode randomland
	ret

