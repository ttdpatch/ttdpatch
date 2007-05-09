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
	jnc .done
	extern fullloadanycheck
	mov dword [fullloadanycheck], 0AB0F0374h // Adjust jump and change the bt to bts
.done:
	ret
