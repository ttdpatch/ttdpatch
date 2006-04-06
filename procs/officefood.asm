#include <defs.inc>
#include <frag_mac.inc>

global patchofficefood

begincodefragments

codefragment oldcollectaccepts
	or ah,ah
	db 0x74,0xb	// jz +0b
	mov dl,al

codefragment newcollectaccepts
	call runindex(collectaccepts)
	jnc short $+2+7
	setfragmentsize 10,0


endcodefragments

patchofficefood:
	multipatchcode oldcollectaccepts,newcollectaccepts,6
	ret


	// enable the sign cheats
