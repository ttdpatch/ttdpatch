#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchprocandor experimentalfeatures,BIT(EXP_SIGNALGUI),, patchsignalgui

begincodefragments

codefragment oldusercreatealtersignals
	mov word [operrormsg1],0x1010
	mov esi, 0x060008

codefragment newusercreatealtersignals
	icall win_signalgui_create
	setfragmentsize 9

endcodefragments

patchsignalgui:
	patchcode usercreatealtersignals
	ret

