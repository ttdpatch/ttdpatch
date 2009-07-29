#include <frag_mac.inc>
#include <patchproc.inc>
#include <window.inc>

// all switches that use window2 must be listed here.
patchproc enhancegui, patchwindow2

extern malloc, newwindowcount, patchflags, windowstack, reloc, window2ofs_ptr

begincodefragments

codefragment oldfinishclosewindow, -2
	rep movsw

codefragment_call newfinishclosewindow, FinishCloseWindow, 5

codefragment oldbringtofront, -7
	xchg ax, [esi+window_size]

codefragment_call newbringtofront, BringToFront, 20

endcodefragments

patchwindow2:
	testmultiflags morewindows
	jnz .morewins

	push dword 10*window_size
	jmp short .malloc

.morewins:
	movzx eax, byte [newwindowcount]
	imul eax, window_size
	push eax
.malloc:
	call malloc
	pop eax
	sub eax, [windowstack]
	param_call reloc, eax, window2ofs_ptr

	patchcode finishclosewindow
	patchcode bringtofront
	ret
