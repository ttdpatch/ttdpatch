#include <defs.inc>
#include <frag_mac.inc>

global patchclearcrashedtrain

begincodefragments

codefragment oldclearcrashedtrain
	mov word [edi+veh.nextunitidx],-1
	cmp edi,esi

codefragment newclearcrashedtrain
	call runindex(clearcrashedtrain)


endcodefragments

patchclearcrashedtrain:
	patchcode oldclearcrashedtrain,newclearcrashedtrain,1,1
	ret
