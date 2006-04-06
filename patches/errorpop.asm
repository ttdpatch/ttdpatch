//
// change how error popups are displayed
// (move them to the top-left corner)
//

#include <defs.inc>
#include <ttdvar.inc>


// in:	ax=landscape X coord
//	bx=text index first line
//	cx=landscape Y coord
//	dx=text index second line
//	on stack: saved ax, cx

global displayerrorpopup
displayerrorpopup:
	xor ax,ax
	mov cx,-0x1000
	mov [esp+4],cx
	mov [esp+6],ax

	mov edx,[textrefstack]
	ret
; endp displayerrorpopup 
