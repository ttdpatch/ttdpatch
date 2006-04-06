#include <defs.inc>
#include <frag_mac.inc>

global patchrailconsmenu

begincodefragments

codefragment oldopentrackconstruction,3
	movzx edx,dx
	db 0x88, 0x15	// mov [curtooltracktype],dl

codefragment newopentrackconstruction
	call runindex(opentrackconstruction)


endcodefragments

patchrailconsmenu:
	patchcode oldopentrackconstruction,newopentrackconstruction,1,1
	ret
