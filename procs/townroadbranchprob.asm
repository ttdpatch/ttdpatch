#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc townroadbranchprob, patchtownroadbranchprob


extern branchprobab

begincodefragments

codefragment oldtownbranchprobab,2
	cmp ax,0x6666
	pop eax



endcodefragments


patchtownroadbranchprob:
	stringaddress oldtownbranchprobab,1,1
	mov eax,[branchprobab]
	mov [edi],ax
	ret
