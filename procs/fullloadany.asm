#include <defs.inc>
#include <frag_mac.inc>

global patchfullloadany

begincodefragments

codefragment oldcheckfull
	mov edi,esi
	mov ax,word [edi+veh.currentload]

codefragment newcheckfull
	call runindex(checkfull)
	ret


endcodefragments

patchfullloadany:
	patchcode oldcheckfull,newcheckfull,1,1
	ret
