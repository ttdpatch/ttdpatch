#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchprocandor experimentalfeatures,BIT(EXP_EXTRADETAILS),, patchextradetails

begincodefragments

codefragment olddisplaywagoninforow
	mov bx, 0x882D
	mov al, 0x10

codefragment newdisplaywagoninforow
	ijmp extradetailswagon

endcodefragments

patchextradetails:
	patchcode displaywagoninforow
	ret
