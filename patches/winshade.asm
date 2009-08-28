#include <window.inc>
#include <ptrvar.inc>
#include <misc.inc>
#include <view.inc>
#include <flags.inc>

ptrvardec window2ofs

extern RefreshWindowArea,patchflags

// The window didn't handle the middle click. Shade the window if clicked on the titlebar.
global ShadeWindowHandler.toggleshade
exported ShadeWindowHandler
	call WindowCanShade
	jc .exit
extern WindowClicked
	call [WindowClicked]
	js .exit
	movzx ecx, cl
	imul ecx,windowbox_size
	add ecx,[esi+window.elemlistptr]
	cmp byte [ecx+windowbox.type], cWinElemTitleBar
	jne .exit
.toggleshade:				// Shade-button click enters here
	mov ebx, RefreshWindowArea
	mov eax, ShadedWinHandler
	cmp [esi+window.function], eax
	jne .shade

.unshade:
	mov eax, [esi+window2ofs+window2.height]	// also window2.opclassoff
	mov [esi+window.height], eax			// also window.opclassoff

	mov eax, [esi+window2ofs+window2.function]
	mov [esi+window.function],eax

	mov edi, [esi+window.viewptr]
	or edi, edi
	jz .uns_noview
	
	mov eax, [esi+window2ofs+window2.viewwidth]
	mov [edi+view.scrwidth], ax
.uns_noview:

	call GetWindowDeltaWidth
	add [esi+window.width], ax

	jmp [ebx]					// RefreshWindowArea

.exit:
	ret

.shade:
	call [ebx]					// RefreshWindowArea
	//mov eax, ShadedWinHandler
	xchg eax, [esi+window.function]
	mov [esi+window2ofs+window2.function], eax

	mov eax, 0xFFFF000E
	xchg eax, [esi+window.height]			// also window.opclassoff
	mov [esi+window2ofs+window2.height], eax	// also window2.opclassoff

	mov edi, [esi+window.viewptr]
	or edi, edi
	jz .shd_noview
	
	xor eax, eax
	xchg ax, [edi+view.scrwidth]
	mov [esi+window2ofs+window2.viewwidth], ax
.shd_noview:

	call GetWindowDeltaWidth
	sub [esi+window.width], ax


exported WindowCanShade
	extcall WindowCanSticky
	jc .ret
	testmultiflags enhancegui
	jz .noshade			// Forbid shading without enhancegui
	cmp byte [esi+window.type], cWinTypeMainView
	je .noshade
	cmp byte [esi+window.type], cWinTypeNewsMessage
	je .noshade
	cmp byte [esi+window.type], cWinTypeLinkSetup
	je .noshade
	
.shade:
	clc
	ret

.noshade:
	stc
.ret:
	ret


GetWindowDeltaWidth:
	xor eax,eax
	mov edx, [esi+window.elemlistptr]
	cmp word [edx+windowbox_size*2+windowbox.y1], 0
	jne .noresize

	mov eax, [edx+windowbox_size*2+windowbox.x2]
	sub eax, [edx+windowbox_size*2+windowbox.x1]
	inc eax
.noresize:
	ret


extern currscreenupdateblock


global ShadedWinHandler.drawwindowelements_ret
exported ShadedWinHandler
	cmp dl, cWinEventRedraw
	jne .callreal

	mov esi, [edi+window.elemlistptr]
.loop:
	add esi, windowbox_size
	cmp byte [esi-windowbox_size], cWinElemTitleBar
	jne .loop

	push esi
	mov bl, cWinElemLast
	xchg bl, [esi]
	push ebx

	call .callreal
.drawwindowelements_ret:

	pop ebx
	pop esi
	mov [esi],bl
	ret

.callreal:
	mov bx, [edi+window2ofs+window2.opclassoff]
	mov [edi+window.opclassoff], bx
	mov ebx, [edi+window2ofs+window2.function]
	mov [edi+window.function], ebx
	extcall GuiEventFuncEDI

	// Now on stack: Function to call. ebx set if necessary.

	or word [edi+window.opclassoff], byte -1
	mov dword [edi+window.function], ShadedWinHandler

	// call [esp] / add esp, 4 / ret
	//	becomes:
	// add esp, 4 / call [esp-4] / ret
	//	becomes:
	// add esp, 4 / jmp [esp-4]
	//	becomes:
	ret
