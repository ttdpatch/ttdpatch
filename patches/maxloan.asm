
// Borrow/repay maximum amount with ctrl

#include <defs.inc>
#include <ttdvar.inc>

extern curplayerctrlkey


	// ebx: amount to borrow
	// dl: player
	// esi: player data array
	// ebp: maximum loan size
global borrow
borrow:
	cmp byte [curplayerctrlkey],0
	jz short .doit

	push edi
	mov edi,ebx
	sub ebp,[esi+0x14]

.increasevolume:
	cmp ebx,ebp
	jge short .gotit
	add ebx,edi
	jmp .increasevolume

.gotit:
	pop edi

.doit:
	add [esi+0x14],ebx
	add [esi+0x10],ebx
	ret
; endp borrow 


	// ebp: amount to repay
	// dl: player
	// esi: player data array
global repay
repay:
	cmp byte [curplayerctrlkey],0
	jz short .doit

	push edi
	mov edi,ebp

.increasevolume:
	add ebp,edi
	jo short .gotit
	cmp ebp,[esi+0x14]
	jg short .gotit
	cmp ebp,[esi+0x10]		// can't repay more than money available
	jle .increasevolume

.gotit:
	sub ebp,edi
	pop edi

.doit:
	// safety check -- don't repay more than we've borrowed...
	cmp ebp,[esi+0x14]
	jle short .done
	mov ebp,[esi+0x14]

.done:
	mov [textrefstack],ebp		// overwritten
	ret
; endp repay 

