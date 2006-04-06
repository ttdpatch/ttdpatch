#include <defs.inc>
#include <frag_mac.inc>

global patchmaintcheck

begincodefragments

codefragment oldneedsmaintcheck
	mov ax,word [esi+veh.lastmaintenance]
	add ax,word [esi+veh.serviceinterval]

codefragment newneedsmaintcheck
	call runindex(needsmaintcheck)
	setfragmentsize 15,1


endcodefragments

patchmaintcheck:
	multipatchcode oldneedsmaintcheck,newneedsmaintcheck,4
	ret
