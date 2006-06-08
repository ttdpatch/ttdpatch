#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>
#include <player.inc>
#include <ptrvar.inc>

// all switches using the player2 array must be listed here
patchproc anyflagset, patchplayer2array

extern malloccrit,player2array,reloc

ptrvar player2ofs

patchplayer2array:
	push 8*player2_size
	call malloccrit
	pop eax
	mov [player2array],eax
	sub eax,[playerarrayptr]
	param_call reloc, eax,player2ofs_ptr
	ret
