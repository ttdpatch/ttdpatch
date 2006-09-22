
#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchprocandor experimentalfeatures,BIT(EXP_NEWTERRAINGEN),, patchterraingen

begincodefragments

codefragment oldrandomland,-27
	and ax,7fh
	mov bx,2

codefragment newrandomland
	icall _makerandomterrain
	icall dmemcompact
	test al,0
	jmp fragmentstart-6

endcodefragments

patchterraingen:
	patchcode randomland
	ret

