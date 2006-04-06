#include <defs.inc>
#include <frag_mac.inc>
#include <ptrvar.inc>
#include <patchproc.inc>

patchproc buildwhilepaused, patchbuildwhilepaused

begincodefragments

codefragment checkpauseconstruction,14
	dd 719		// cmp [mousecursorsprite],719
	db 0x74		// jz ...

codefragment checkpausetextedit,10
	ret
	cmp byte [gamesemaphore],0
	db 0x0f		// jne near ...

codefragment newfindemptytexteffect
	call runindex(findemptytexteffect)
	jmp fragmentstart+18


endcodefragments


patchbuildwhilepaused:
	stringaddress checkpauseconstruction,1,1
	mov byte [edi],0
	stringaddress checkpausetextedit,1,1
	mov byte [edi],0

	// make text effects reuse oldest slot if no unused ones available
	// (will probably move this to generalfixes when tested a little more)
	mov eax,[ophandler+0x14*8]
	mov eax,[eax+1*4]
	mov eax,[eax+3]
	mov edi,[eax]
	add edi,14
	storefragment newfindemptytexteffect
	ret
