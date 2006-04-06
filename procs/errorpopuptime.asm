#include <defs.inc>
#include <frag_mac.inc>


extern errorpopup
extern redpopuptime


global patcherrorpopuptime
patcherrorpopuptime:
	mov edi,[errorpopup]
	movzx eax,byte [redpopuptime]
	or eax,eax
	jnz .settime
	mov ah,0x80			// AX=0x8000 (approx. 9.1 hours)
.settime:
	mov [edi+0x55],ax
	ret
