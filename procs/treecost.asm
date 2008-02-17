#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc plantmanytrees,generalfixes, patchtreecost

begincodefragments

codefragment oldgettreecost
	mov ebx,[treeplantcost]

codefragment newgettreecost
	call runindex(planttree2)

//codefragment oldmonthlyindustryloop,14
//	mov esi,[industryarrayptr]
//	mov cl,0x5a
//
//codefragment newmonthlyindustryloop
//	call runindex(checkindustry)
//	setfragmentsize 9
//
//codefragment findindustryrefresh
//	cmp byte [esi+8],0xff
//	db 0x74,0x72	//je...*/
//
// These are no longer needed for the lumber mill warning, but they might be useful later

endcodefragments

patchtreecost:
	patchcode oldgettreecost,newgettreecost,1,1
	ret
