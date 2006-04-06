#include <defs.inc>
#include <frag_mac.inc>


extern fullloadtest


global patchloadtimedone

begincodefragments

codefragment oldloadtimedone
	dec word [esi+veh.loadtime]
	db 0x75		// jnz @@notdoneyet

codefragment newloadtimedone
	call runindex(loadtimedone)
	jnz short $-8
	nop
	db 0x72


endcodefragments

patchloadtimedone:
	multipatchcode oldloadtimedone,newloadtimedone,4
	mov byte [fullloadtest],1 << MOD_NOTDONEYET
	ret
