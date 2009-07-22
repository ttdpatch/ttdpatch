// Gui Tools
// Camel case for export prefered.

// List of functions:
// GuiSendEventEDI (prefered)		Sends a window event: DL=event, EDI = window
// GuiSendEventESI			Sends a window event: DL=event, ESI = window (wrapper function)
// GuiEventFuncEDI (prefered)		Returns the function to call for window events on the stack: ESI = window, may update EBX
// GuiEventFuncESI			Returns the function to call for window events on the stack: ESI = window, may update EBX (wrapper function)

#include <std.inc>
#include <window.inc>
#include <ptrvar.inc>
#include <pusha.inc>

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

exported GuiEventFuncESI
	push eax
	pusha
	mov edi, esi
	jmp short GuiEventFuncEDI.esientry
exported GuiEventFuncEDI
	push eax
	pusha
.esientry:
	mov si, [edi+window.opclassoff]
	cmp si, -1
	jz .winfunc
	mov ebx, [edi+window.function]
	mov [esp+_pusha.ebx], ebx
	movzx esi, si
	mov ebp, [ophandler+esi]
	mov eax, [ebp+4]
	jmp short .calldone
.winfunc:
	mov eax, [edi+window.function]
.calldone:
	// Now eax has function ptr, and ebx will be set correctly if necessary
	xchg eax, [esp+24h]	// Replace return address with function pointer
	mov [esp+20h], eax	// And place function pointer in dummy slot
	popa
	ret
