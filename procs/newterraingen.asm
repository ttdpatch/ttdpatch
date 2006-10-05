
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

codefragment oldsetupdesert,10
	add ax,16
	cmp ax,0xfef

codefragment newsetupdesert
	ret

endcodefragments

patchterraingen:
	patchcode randomland
	patchcode setupdesert
	ret

