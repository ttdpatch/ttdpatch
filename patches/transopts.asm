#include <std.inc>
#include <window.inc>
#include <windowext.inc>
#include <transopts.inc>
#include <textdef.inc>

%assign win_transopts_id 115

// The storage for the new transparency options.
// For code that is called by or promptly after getnewsprite,
// testing [displayoptions] is preferred, especially if it may draw sprites
// for multiple features.
vard newtransopts, defaulttrans << 16

exported maybehidetrees
	test byte [newtransopts+1], 1<<(TROPT_INVISIBLETREES-8)
	jz .nohide
	pop ecx		// remove return address
	pop ecx		// overwritten from ...
	pop eax		// ... 
	ret		// ... hidetranstrees code.

.nohide:
	and ebx, 3FFFh	//overwritten from TTD code
	ret

// This order much match the order of the defines in transopts.inc
guiwindow win_transopts, 263, 37
guicaption cColorSchemeDarkGreen, ourtext(transopts_caption)
guiele trees,    cWinElemSpriteBox, cColorSchemeDarkGreen, x,0,   y,14, w,22, h,22, data,742
guiele townbldg, cWinElemSpriteBox, cColorSchemeDarkGreen, x,22,  y,14, w,22, h,22, data,4077
guiele industry, cWinElemSpriteBox, cColorSchemeDarkGreen, x,44,  y,14, w,22, h,22, data,741
guiele station,  cWinElemSpriteBox, cColorSchemeDarkGreen, x,66,  y,14, w,22, h,22, data,1299
guiele raildepot,cWinElemSpriteBox, cColorSchemeDarkGreen, x,88,  y,14, w,22, h,22, data,1294
guiele roaddepot,cWinElemSpriteBox, cColorSchemeDarkGreen, x,110, y,14, w,22, h,22, data,1295
guiele shipdepot,cWinElemSpriteBox, cColorSchemeDarkGreen, x,132, y,14, w,22, h,22, data,748
guiele bridges,  cWinElemSpriteBox, cColorSchemeDarkGreen, x,154, y,14, w,43, h,22, data,2594
guiele objects,  cWinElemSpriteBox, cColorSchemeDarkGreen, x,197, y,14, w,22, h,22, data,4085
guiele company,  cWinElemSpriteBox, cColorSchemeDarkGreen, x,219, y,14, w,22, h,22, data,743
guiele invtrees, cWinElemSpriteBox, cColorSchemeDarkGreen, x,241, y,14, w,21, h,22, data,723
endguiwindow

exported changetransparency
	mov cl, 2Ah
	mov dx, win_transopts_id
	extern FindWindow
	call [FindWindow]
	test esi, esi
	jnz .ret

	pusha
	mov eax, 22 << 16
	mov ebx, win_transopts_width + (win_transopts_height << 16)
	mov cx, 2Ah	// window type
	mov dx, -1	// operation class offset
	mov ebp, transparencywindow_handler
	extern CreateWindow
	call [CreateWindow]
	mov word [esi+window.id], win_transopts_id
	mov dword [esi+window.elemlistptr], win_transopts_elements
	popa

.ret:
	ret

exported toggletransparency
	mov eax, [newtransopts]
	rol eax, 16
	test ax, alltrans	// If new and
	jz .ok1
	test eax, alltrans<<16	// old tranparencies are both not clear, 
	jz .ok1
	and ax, ~defaulttrans	// clear new transparency
.ok1:
	test eax, alltrans | alltrans<<16 // if both transparencies are clear
	jnz .ok2
	or ax, defaulttrans	// set default transparencies
.ok2:
	mov [newtransopts], eax
	ret


exported drawbridgesprite
	test byte [newtransopts], 1<<TROPT_BRIDGE
	jz .nottrans
	and ebx, 3FFFh
	or ebx, 3224000h
.nottrans:
	extern addsprite
	jmp [addsprite]


extern DrawWindowElements, WindowClicked, DestroyWindow, WindowTitleBarClicked, CreateTooltip

transparencywindow_handler:
	mov bx, cx
	mov esi, edi
	cmp dl, cWinEventRedraw
	jnz .noredraw
	and byte [esi+window.disabledbuttons+1], ~(1<<(TROPT_INVISIBLETREES-8+2))
	mov eax, [newtransopts]
	test al, 1<<TROPT_TREES
	jne .nodisable
	and ah, ~(1<<(TROPT_INVISIBLETREES-8))
	or byte [esi+window.disabledbuttons+1], 1<<(TROPT_INVISIBLETREES-8+2)
.nodisable:
	shl eax, 2
	mov [esi+window.activebuttons], eax
	jmp [DrawWindowElements]
.noredraw:
	cmp dl, cWinEventClick
	jnz .ret
	call [WindowClicked]
	js .ret
	movzx ebx, cl	// [e]bx so I can save a byte in the lea by using 16-bit addressing.
	cmp byte [rmbclicked],0 // Was it the right mouse button
	jne .rmb
	dec ebx		// win_transopts_elements.caption_close_id == 0
	js .destroy
	dec ebx		// win_transopts_elements.caption_id == 1
	js .titlebar
	btc [newtransopts], ebx
	extjmp redrawscreen
.destroy:
	jmp [DestroyWindow]
.titlebar:
	jmp [WindowTitleBarClicked]
.ret:
	ret

.rmb:
	mov ax, 18Bh
	dec ebx
	js .done
	inc eax
	dec ebx
	js .done
	lea eax, [bx+ourtext(transopts_tttrees)]
.done:
	jmp [CreateTooltip]
