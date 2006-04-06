#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc generalfixes,newplanes,planespeed, patchplanebreakdownspeed

begincodefragments

codefragment oldplanebreakdownspeed,-2
	mov bx,27

codefragment newplanebreakdownspeed
	call runindex(planebreakdownspeed)


endcodefragments

patchplanebreakdownspeed:
	patchcode oldplanebreakdownspeed,newplanebreakdownspeed,1,1
	ret
