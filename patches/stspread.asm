
// New station spread check

#include <defs.inc>

extern isrealhumanplayer,newstationspread





// In:	DL=spread in X, DH=in y
// Out:	CY if not allowed, NC if allowed
// Safe:EAX,EBX,ECX,EDX

global checkstationspread
checkstationspread:
	mov al,byte [newstationspread]

	call isrealhumanplayer
	je short .ishuman

	// it's a computer, use the default spread
	mov al,11

.ishuman:
	cmp dl,al
	ja short .done

	cmp dh,al
.done:
	ret
; endp checkstationspread 
