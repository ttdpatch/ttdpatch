#include <window.inc>
#include <ptrvar.inc>

ptrvar window2ofs

// Shift both window and window2 arrays.
exported FinishCloseWindow
	shr ecx, 1	// overwritten

// window
	pusha
	rep movsw	// overwritten
	popa

// window2
	add esi, [window2ofs_ptr]
	add edi, [window2ofs_ptr]
	rep movsw

	ret

exported BringToFront
	xor ecx,ecx
	mov cl, window_size/4

	push edi
	lea edi, [esi+window2ofs]
.loop:
	mov edx, [esi]
	mov eax, [edi]
	xchg edx, [esi+window_size]
	xchg eax, [edi+window2_size]
	mov [esi], edx
	add esi, 4
	stosd		// mov [edi], eax / add edi, 4
	loop .loop
	pop edi
	ret
