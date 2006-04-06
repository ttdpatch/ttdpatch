#include <defs.inc>
#include <frag_mac.inc>

global patchnoinflation

begincodefragments

codefragment oldinflation
	imul ebx,ebx,byte 0x36
	db 0xbe		// mov esi,...

codefragment newinflation
	xor ebx,ebx
	nop


endcodefragments

patchnoinflation:
	patchcode oldinflation,newinflation,1,2
	patchcode oldinflation,newinflation,1,1
	ret
