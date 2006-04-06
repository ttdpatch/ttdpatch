#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>
#include <player.inc>

// all switches using the player2 array must be listed here
patchproc anyflagset, patchplayer2array

extern malloccrit,player2array

patchplayer2array:
	push 8*player2_size
	call malloccrit
	pop dword [player2array]
	ret
