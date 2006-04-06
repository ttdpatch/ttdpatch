#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc planespeed, patchplanespeed


extern moveplane.doit,moveplane.factor
extern planespeedfactor

begincodefragments

codefragment oldmoveplane
	push edi
	cmp byte [edi+veh.subclass],2

codefragment newmoveplane
	jmp runindex(moveplane)
	push edi


endcodefragments


patchplanespeed:
	patchcode oldmoveplane,newmoveplane,1,1
	storerelative moveplane.doit,edi+lastediadj+6
	mov al,[planespeedfactor]
	mov [moveplane.factor],al
	ret
