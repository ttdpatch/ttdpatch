
// Borrow/repay maximum amount with ctrl

#include <defs.inc>
#include <ttdvar.inc>
#include <ptrvar.inc>
#include <flags.inc>
#include <player.inc>

extern curplayerctrlkey,patchflags


	// ebx: amount to borrow
	// dl: player
	// esi: player data array
	// ebp: maximum loan size
global borrow
borrow:
	cmp byte [curplayerctrlkey],0
	jz short .doit
	testmultiflags maxloanwithctrl
	jz .doit

	push edi
	mov edi,ebx
	sub ebp,[esi+player.loan]

.increasevolume:
	cmp ebx,ebp
	jge short .gotit
	add ebx,edi
	jmp .increasevolume

.gotit:
	pop edi

.doit:
	pusha
	add [esi+player.cash],ebx
	add [esi+player.loan],ebx
	mov eax,ebx
	cdq
	add [esi+player2ofs+player2.cash],eax
	adc [esi+player2ofs+player2.cash+4],edx
	popa
	ret
; endp borrow 


	// ebp: amount to repay
	// dl: player
	// esi: player data array
global repay
repay:
	cmp byte [curplayerctrlkey],0
	jz short .doit
	testmultiflags maxloanwithctrl
	jz .doit

	push edi
	mov edi,ebp

.increasevolume:
	add ebp,edi
	jo short .gotit
	cmp ebp,[esi+player.loan]
	jg short .gotit
	cmp ebp,[esi+player.cash]	// can't repay more than money available
	jle .increasevolume

.gotit:
	sub ebp,edi
	pop edi

.doit:
	// safety check -- don't repay more than we've borrowed...
	cmp ebp,[esi+player.loan]
	jle short .done

	mov ebp,[esi+player.loan]

.done:
	mov [textrefstack],ebp		// overwritten
	ret
; endp repay 

; called after the above, if we're not just checking
exported dorepay
	mov ebx,ebp
	neg ebx
	jmp borrow.doit

