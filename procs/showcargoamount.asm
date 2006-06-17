#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc freighttrains,newships,newrvs,newtrains,newplanes, patchshowcargoamount

begincodefragments

codefragment oldshowwagoncap
	mov bx,0x013f

codefragment newshowwagoncap
	call runindex(showwagoncap)
	setfragmentsize 9

codefragment oldshowrvcap
	mov bx,0x9012

codefragment newshowsinglecap
	call runindex(showsinglecap)
	setfragmentsize 9

codefragment oldshowshipcap
	mov bx,0x9817

codefragment oldshowplanecap
	mov bx,0xa019

codefragment newshowdoublecap
	call runindex(showdoublecap)
	setfragmentsize 7


endcodefragments

patchshowcargoamount:
	patchcode oldshowwagoncap,newshowwagoncap
//	patchcode oldshowrvcap,newshowsinglecap
//	this is now done in articulated road vehicles to show multiple cargo types.
	patchcode oldshowshipcap,newshowsinglecap
	patchcode oldshowplanecap,newshowdoublecap
	ret
