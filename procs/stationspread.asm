#include <defs.inc>
#include <frag_mac.inc>

global patchstationspread

begincodefragments

codefragment oldcheckstationspread,3
	sub dx,cx
	cmp dl,0xb

codefragment newcheckstationspread
	nop
	nop
	call runindex(checkstationspread)


endcodefragments

patchstationspread:
	patchcode oldcheckstationspread,newcheckstationspread,1,1
	ret
