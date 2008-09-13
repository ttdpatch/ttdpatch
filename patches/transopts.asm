#include <std.inc>
#include <window.inc>
#include <windowext.inc>
#include <transopts.inc>
#include <textdef.inc>
#include <human.inc>
#include <bitvars.inc>

%assign win_transopts_id 115

// The storage for the new transparency options.
// For code that is called by or promptly after getnewsprite,
// testing [displayoptions] is preferred, especially if it may draw sprites
// for multiple features.
varw newtransopts
	dw 1<<TROPT_ONEWAY	// default "transparent"  -- aka hidden, for oneway signs.
	dw 1<<TROPT_ROADDEPOT | 1<<TROPT_BRIDGE | 1<<TROPT_ONEWAY	// default not toggled by [t]
	dw 0			// default invisible
endvar
	

// This order much match the order of the defines in transopts.inc
guiwindow win_transopts, 262, 36
guicaption cColorSchemeDarkGreen, ourtext(transopts_caption)
noglobal ovar spritestart, windowbox.sprite
guiele trees,    cWinElemSpriteBox, cColorSchemeDarkGreen, x,0,   y,14, w,22, h,22, data,0
guiele townbldg, cWinElemSpriteBox, cColorSchemeDarkGreen, x,22,  y,14, w,22, h,22, data,0
guiele industry, cWinElemSpriteBox, cColorSchemeDarkGreen, x,44,  y,14, w,22, h,22, data,0
guiele station,  cWinElemSpriteBox, cColorSchemeDarkGreen, x,66,  y,14, w,22, h,22, data,0
guiele raildepot,cWinElemSpriteBox, cColorSchemeDarkGreen, x,88,  y,14, w,22, h,22, data,0
guiele roaddepot,cWinElemSpriteBox, cColorSchemeDarkGreen, x,110, y,14, w,22, h,22, data,0
guiele shipdepot,cWinElemSpriteBox, cColorSchemeDarkGreen, x,132, y,14, w,22, h,22, data,0
guiele bridges,  cWinElemSpriteBox, cColorSchemeDarkGreen, x,154, y,14, w,42, h,22, data,0
guiele objects,  cWinElemSpriteBox, cColorSchemeDarkGreen, x,196, y,14, w,22, h,22, data,0
guiele company,  cWinElemSpriteBox, cColorSchemeDarkGreen, x,218, y,14, w,22, h,22, data,0
noglobal ovar overlaydrawstart, windowbox.x1
guiele oneway,   cWinElemSpriteBox, cColorSchemeDarkGreen, x,240, y,14, w,22, h,22, data,0
endguiwindow

varw ttdguisprites, 742, 4077, 741, 1299, 1294, 1295, 748, 2594, 4085, 743, 0


exported changetransparency
	mov cl, cWinTypeTTDPatchWindow
	mov dx, win_transopts_id
	extern FindWindow
	call [FindWindow]
	test esi, esi
	jnz .ret

	pusha
	mov eax, 22 << 16
	mov ebx, win_transopts_width + (win_transopts_height << 16)
	mov cx, cWinTypeTTDPatchWindow	// window type
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
	push ebx
	mov eax, [newtransopts]
	mov ebx, eax
	shr ebx, 10h
	cwde
	not ebx
	test eax, ebx
	jz .setunlocked
.clearunlocked:
	not ebx
	and eax, ebx
	jmp short .store
.setunlocked:
	or eax, ebx
.store:
	mov [newtransopts], ax
	pop ebx
exported setonewayflag
	test byte [newtransopts+transopts.opts+1], 1<<(TROPT_ONEWAY-8)
	extern openedroadconstruction
	setz [openedroadconstruction]
	ret


exported drawbridgesprite
	test byte [newtransopts], 1<<TROPT_BRIDGE
	jz .nottrans
	test byte [newtransopts+transopts.invis], 1<<TROPT_BRIDGE
	jz .trans
	ret
.trans:
	and ebx, 3FFFh
	or ebx, 3224000h
.nottrans:
	extern addsprite
	jmp [addsprite]


extern DrawWindowElements, WindowClicked, DestroyWindow, WindowTitleBarClicked, CreateTooltip
extern numguisprites, guispritebase, drawspritefn, ctrlkeystate

transparencywindow_handler:
	mov bx, cx
	mov esi, edi
	cmp dl, cWinEventRedraw
	jnz NEAR .noredraw

// Do we have gui sprites available?
	mov ecx, [guispritebase]
	add ecx, 92
	cmp dword [numguisprites],92
	seta dl
	ja .nottdspr
	mov cx,723
.nottdspr:
	mov [ttdguisprites+10*2],cx
	mov ecx, .spriteloop+1
	mov eax, [newtransopts]
	and dword [esi+window.activebuttons], 0
	mov byte [ecx], 0ABh	// [o16] stosd
	shl eax, 2
	mov bl,.nottrans-(.3overlayjmp+1)
	test dl, dl
	jz .noguisprites
	extern miscmods2flags
	test byte [miscmods2flags], MISCMODS2_NOTALWAYSTHREESTATETRANS
	setnz dh
	jz .gotsprites
	mov bl,.lock-(.3overlayjmp+1)
	jmp short .loadoldfirst

// Use the old ones.
.noguisprites:
	mov [esi+window.activebuttons], eax
.loadoldfirst:
	mov byte [ecx], 0A5h	// [o16] movsd

.gotsprites:
	mov [.3overlayjmp],bl
	mov ebx,eax
	and ah, 1<<(TROPT_ONEWAY-8+2)
	or [esi+window.activebuttons+1], ah
	push esi
	xor ecx, ecx
	mov cl, TROPT__COUNT
	mov edi, spritestart
	mov esi, ttdguisprites
	mov eax, [guispritebase]
	add eax, 82

// Store the correct sprites in the windowelements.
.spriteloop:
	stosw		// Without new sprites or with notalwaysthreestatetrans, becomes "movsw"
	test dl,dh	// enough gui sprites && notalwaysthreestatetrans
	jz .nextsprite
	cmp ecx,1
	je .spritesdone
	push ecx
	neg ecx
	add ecx, TROPT__COUNT+2
	bt ebx,ecx
	jnc .popnext
	mov [edi-2],ax
.popnext:
	pop ecx
.nextsprite:
	inc eax
	add edi, windowbox_size-2
	loop .spriteloop
.spritesdone:
	pop esi

// and draw
	call [DrawWindowElements]

// Now the toolbar is present, add overlays.
/*	for(int i=TROPT_LAST;i>=0;i--){
		if (i!=TROPT_ONEWAY){	// oneway is two-state
			if(HAVE_SEL_SPRITES)
				addsprite(selection);	// ebx: sprite cx&dx: x&y edi:from DrawWindowElements
			else if(ISINVISIBLE(i))
				addsprite(LETTER_I);
		}
		if(IS_LOCKED(i)){
			if(HAVE_LOCK)
				addsprite(GUI_LOCK);
			else
				addsprite(LETTER_L);
		}
	}
*/
	mov edx, [esi+window.y]
	add edx, 16
	mov ecx, [esi+window.x]
	mov esi, newtransopts
	mov ebp, overlaydrawstart
	mov eax, TROPT__LAST
	jmp short .lock			// oneway-indicator is two-state
.loop:
	xor ebx, ebx
	cmp eax, TROPT_BRIDGE
	sete bl
	lea ebx, [ebx*3]	// bridges require different selection sprites; initialize ebx to 0 or 3
	cmp dword [numguisprites], 92
	jbe .useI
	add bx, [guispritebase]
	bt [esi+transopts.opts], eax
	jnc short .lock
noglobal ovar .3overlayjmp, -1
	inc ebx
	bt [esi+transopts.invis],eax
.nottrans:
	adc ebx, 76
	pusha
	jmp short .dodraw
.useI:
	bt [esi+transopts.opts],eax
	jnc .lock
	bt [esi+transopts.invis],eax
	jnc .lock
	pusha
	lea ecx, [ecx+ebx*8+16]
	sub ecx, ebx	// want ebx*7
	mov bl, 43
.dodraw:
	add ecx, [ebp]
	call [drawspritefn]
	popa
.lock:
	bt dword [esi+transopts.locked], eax
	jnc .next
	mov bx, 46
	cmp dword [numguisprites], 4Bh
	jbe .gotlock
	movzx ebx, word [guispritebase]
	add ebx, 4Bh
.gotlock:
	pusha
	add ecx, [ebp]
	inc ecx
	call [drawspritefn]
	popa
.next:
	sub ebp, windowbox_size
	dec eax
	jns .loop
.ret:
	ret

.noredraw:
	cmp dl, cWinEventClick
	jnz .ret
	call [WindowClicked]
	js .ret
	movzx ebx, cl	// [e]bx so I can save a byte in the lea by using 16-bit addressing.
	cmp byte [rmbclicked],0 // Was it the right mouse button
	jne short .rmb
	param_call ctrlkeystate, CTRL_MP
	jnz .notctrl
	sub ebx, 2
	js .ret
	btc [newtransopts+transopts.locked], ebx
	jmp short .redraw

.notctrl:
	dec ebx		// win_transopts_elements.caption_close_id == 0
	js short .destroy
	dec ebx		// win_transopts_elements.caption_id == 1
	js short .titlebar
	mov ecx, newtransopts
	btc [ecx+transopts.opts], ebx
	cmp ebx, TROPT_ONEWAY
	je .redraw
	bts [ecx+transopts.opts], ebx
	jnc .wastrans
	btr [ecx+transopts.invis], ebx
.redraw:
	call setonewayflag
	extjmp redrawscreen
.wastrans:
	bts [ecx+transopts.invis], ebx
	jnc short .redraw
.wasinvis:
	btr [ecx+transopts.opts], ebx
	btr [ecx+transopts.invis], ebx
	jmp short .redraw
	
.destroy:
	jmp [DestroyWindow]
.titlebar:
	jmp [WindowTitleBarClicked]

.rmb:
	mov ax, 18Bh
	dec ebx
	js .done
	inc eax
	dec ebx
	js .done
	lea eax, [bx+ourtext(transopts_cttrees)]
.done:
	jmp [CreateTooltip]


// In: On stack: transparency bit to test
// Out: nz if transparent, zf if not transparent, fudged return if invisible.
exported testtransparency
	pusha
	mov eax, [esp+24h]
	mov ebx, newtransopts
	bt [ebx+transopts.opts], eax
	jnc short .retnz
	bt [ebx+transopts.invis], eax
	jnc short .retz
	popa
	pop eax				// returns to a j[n]z short
	movzx ebx, byte [eax+1]
	lea eax, [eax+ebx+2]		// follow the jump
	cmp byte [eax], 81h
	jne .loop
	add eax, 12+5
.loop:
	cmp byte [eax], 0E8h
	je .next
	pop ebx
	jmp eax
.next:
	add eax, 5
	jmp short .loop

.retz:
	cmp eax, eax
	jmp short .ret
.retnz:
	test esp, esp
.ret:
	popa
	ret 4
