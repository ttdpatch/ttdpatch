#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc newcargodistribution, patchdistributecargo


extern addcargotostation

begincodefragments

codefragment olddistributecargo, 2
	db 72h, 0d2h
	movzx edi, dh
	imul di, 8Eh

codefragment newdistributecargo
	icall distributecargo
	setfragmentsize 10 // to make it a short jump
	jmp short fragmentstart+8Ah

endcodefragments


patchdistributecargo:
	stringaddress olddistributecargo,1,1
	storefragment newdistributecargo
	ret
