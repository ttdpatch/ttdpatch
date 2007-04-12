// Gui Tools
// Camel case for export prefered.

// List of functions:
// GuiSendEventEDI (prefered)		Sends a window event: DL=event, EDI = window
// GuiSendEventESI			Sends a window event: DL=event, ESI = window (wrapper function)

#include <std.inc>
#include <window.inc>
#include <ptrvar.inc>

// in dl event
// safe: all
exported GuiSendEventESI
	pusha
	mov edi, esi
	jmp short GuiSendEventEDI.esientry
exported GuiSendEventEDI
	pusha
GuiSendEventEDI.esientry:
	mov si, [edi+window.opclassoff]
	cmp si, -1
	jz .winfunc
	mov ebx, [edi+window.function]
	movzx esi, si
	mov ebp, [ophandler+esi]
	call dword [ebp+4]
	jmp short .calldone
.winfunc:
	call dword [edi+window.function]
.calldone:
	popa
	ret
