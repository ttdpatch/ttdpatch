#include <defs.inc>
#include <frag_mac.inc>
#include <town.inc>

global patchtowninit
patchtowninit:
	patchcode oldinitializetown,newinitializetown,1,1
	ret



begincodefragments

codefragment oldinitializetown
	mov word [esi+town.waterlastmonth],0

codefragment newinitializetown
	call runindex(initializetownex)


endcodefragments
