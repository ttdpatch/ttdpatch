#include <defs.inc>
#include <frag_mac.inc>

global patchstationspread
patchstationspread:
	patchcode oldcheckstationspread,newcheckstationspread,1,1
	ret



begincodefragments

codefragment oldcheckstationspread,3
	sub dx,cx
	cmp dl,0xb

codefragment newcheckstationspread
	nop
	nop
	call runindex(checkstationspread)


endcodefragments
