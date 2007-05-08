#include <defs.inc>
#include <frag_mac.inc>

global patchfullloadany

begincodefragments

codefragment oldcheckfull
	mov edi,esi
	mov ax,word [edi+veh.currentload]

codefragment_jmp newcheckfull, checkfull, 5


endcodefragments

patchfullloadany:
	patchcode oldcheckfull,newcheckfull,1,1
	extern patchflags
	testflags fullloadany
	jc .done
	extern fullloadanycheck
	mov byte [fullloadanycheck], 0C3h // Change jb to ret
.done:
	ret
