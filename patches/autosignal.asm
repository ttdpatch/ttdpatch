// auto-signal code

#include <std.inc>

// called from patch action handler for signal gui
//
// in:	ax=tile X
//	bl=action handler flags
//	cx=tile Y
//	dl=track piece
//	dh=1
// out:	ebx=cost
// safe:as in action handler
exported buildautosignals
	mov ebx,0x80000000
	ret

