// New signal gui (should replace the ctrl madness)
// by eis_os

#include <std.inc>
#include <misc.inc>
#include <textdef.inc>
#include <human.inc>
#include <window.inc>
#include <imports/gui.inc>
#include <ptrvar.inc>

extern drawspritefn
extern presignalspritebase, numsiggraphics
extern resheight, reswidth
extern actionhandler, AlterSignalsByGUI_actionnum, ctrlkeystate
extern RefreshWindowArea
extern generatesoundeffect
extern buildautosignals
extern autosignalsep

%assign win_signalgui_timeout 5

%assign win_signalgui_id 110

%assign win_signalgui_signalx 17
%assign win_signalgui_signaly 1
%assign win_signalgui_signalboxwidth 17
%assign win_signalgui_signalboxheight 28

%assign win_signalgui_width 11+11+win_signalgui_signalboxwidth*4
%assign win_signalgui_height win_signalgui_signalboxheight*2
%assign win_signalgui_signalboxheightX2 win_signalgui_signalboxheight*2

varb win_signalgui_elements
db cWinElemTextBox,cColorSchemeDarkGreen
dw 0, 10, 0, 13, 0x00C5
db cWinElemSpriteBox,cColorSchemeDarkGreen
dw 0, 10, 14, win_signalgui_height-1, 0
db cWinElemSpriteBox,cColorSchemeDarkGreen
dw 11+win_signalgui_signalboxwidth*4, 11+win_signalgui_signalboxwidth*4+10, 0, 13, 0
db cWinElemSpriteBox,cColorSchemeDarkGreen
dw 11+win_signalgui_signalboxwidth*4, 11+win_signalgui_signalboxwidth*4+10, 14, win_signalgui_height-1, 0

;db cWinElemSpriteBox,cColorSchemeDarkGreen
;dw 11, win_signalgui_width-1, 0, win_signalgui_height-1, 0
db cWinElemSpriteBox,cColorSchemeDarkGreen
dw 11+win_signalgui_signalboxwidth*0, 11+win_signalgui_signalboxwidth*1-1, 0, win_signalgui_signalboxheight-1, 0
db cWinElemSpriteBox,cColorSchemeDarkGreen
dw 11+win_signalgui_signalboxwidth*1, 11+win_signalgui_signalboxwidth*2-1, 0, win_signalgui_signalboxheight-1, 0
db cWinElemSpriteBox,cColorSchemeDarkGreen
dw 11+win_signalgui_signalboxwidth*2, 11+win_signalgui_signalboxwidth*3-1, 0, win_signalgui_signalboxheight-1, 0
db cWinElemSpriteBox,cColorSchemeDarkGreen
dw 11+win_signalgui_signalboxwidth*3, 11+win_signalgui_signalboxwidth*4-1, 0, win_signalgui_signalboxheight-1, 0
db cWinElemSpriteBox,cColorSchemeDarkGreen
dw 11+win_signalgui_signalboxwidth*0, 11+win_signalgui_signalboxwidth*1-1, win_signalgui_signalboxheight, win_signalgui_signalboxheightX2-1, 0
db cWinElemSpriteBox,cColorSchemeDarkGreen
dw 11+win_signalgui_signalboxwidth*1, 11+win_signalgui_signalboxwidth*2-1, win_signalgui_signalboxheight, win_signalgui_signalboxheightX2-1, 0
db cWinElemSpriteBox,cColorSchemeDarkGreen
dw 11+win_signalgui_signalboxwidth*2, 11+win_signalgui_signalboxwidth*3-1, win_signalgui_signalboxheight, win_signalgui_signalboxheightX2-1, 0
db cWinElemSpriteBox,cColorSchemeDarkGreen
dw 11+win_signalgui_signalboxwidth*3, 11+win_signalgui_signalboxwidth*4-1, win_signalgui_signalboxheight, win_signalgui_signalboxheightX2-1, 0
db cWinElemLast
endvar

struc signalguidata
	.life:	resb 1	// 00: seconds left before closing
	.unused:resb 1	// 01: unused
	.x:	resw 1	// 02: x of tile to change
	.y:	resw 1	// 04: y of tile to change
	.piece:	resb 1	// 06: track piece bit to change
	.type:	resb 1	// 07: signal type (pre/pbs/semaphore) to change
endstruc


// in:	ax, cx = location
//		edi = xy
//		dl = trackpiece to change
// safe: dh

uvard win_signalgui_winptr	// to lazy to build a stack frame
exported win_signalgui_create
	mov word [operrormsg1],0x1010	// overwritten
	
	push byte CTRL_ANY + CTRL_MP
	call ctrlkeystate
	jnz .dooldcode
	
	mov dh,[landscape4(di,1)]
	and dh,0xF0
	cmp dh,0x10
	jne .dooldcode
	
	test byte [landscape5(di,1)], 0xC0
	jz .track
	js .depot
	jmp short .signalpresent
	
.track:
.depot:
.dooldcode:
	ret
	
	
.signalpresent:	
	pusha
	mov cl, 0x2A
	mov dx, win_signalgui_id // window.id
	call [FindWindow]
	test esi,esi
	jz .noold
	call [DestroyWindow]
.noold:
	//mov eax, (640-win_signalgui_width)/2 + (((480-win_signalgui_height)/2) << 16) // x, y
	movzx eax, word [mousecursorscry]
	mov bx, word [resheight]
	sub bx, win_signalgui_height+26
	cmp ax, bx
	jb .yok
	mov ax, bx
.yok:
	shl eax, 16
	mov ax, word [mousecursorscrx]
	mov bx, [reswidth]
	sub bx, win_signalgui_width
	cmp ax, bx
	jb .xok
	mov ax, bx
.xok:
		
	mov ebx, win_signalgui_width + (win_signalgui_height << 16) // width , height

	mov cx, 0x2A			// window type
	mov dx, -1				// -1 = direct handler
	mov ebp, addr(win_signalgui_winhandler)
	call dword [CreateWindow]
	mov dword [esi+window.elemlistptr], addr(win_signalgui_elements)
	mov word [esi+window.id], win_signalgui_id // window.id
	mov dword [win_signalgui_winptr], esi
	popa
	
	push esi
	movzx edi, di
	mov esi, dword [win_signalgui_winptr]
	mov byte [esi+window.data+signalguidata.life], win_signalgui_timeout
	mov word [esi+window.data+signalguidata.x], ax
	mov word [esi+window.data+signalguidata.y], cx
	mov byte [esi+window.data+signalguidata.piece], dl
	
	mov dl, byte [landscape3+1+edi*2]
	test byte [landscape6+edi], 8
	jz .nopbstoggle
	or dx, 16
.nopbstoggle:
	and dl, 11110b
	mov byte [esi+window.data+signalguidata.type], dl
	pop esi
	
	mov ebx, 0
	add esp, 4		// unwind the stack, need to be changed to do jc after the icall in fragment, but ohh well it works
	ret

win_signalgui_winhandler:
	mov bx, cx
	mov esi, edi
	cmp dl, cWinEventRedraw
	jz near win_signalgui_redraw
	cmp dl, cWinEventClick
	jz near win_signalgui_clickhandler
	cmp dl, cWinEventTimer
	jz win_signalgui_timer
	cmp dl, cWinEventSecTick
	jz win_signalgui_sectick
	ret
	
win_signalgui_timer:
	mov ah, 2
	btr dword [esi+window.activebuttons], 2
	jb .switch
	mov ah,3
	btr dword [esi+window.activebuttons], 3
	jb .switch
	ret

.switch:
	mov al,[esi]
	mov bx,[esi+window.id]
	or al, 80h
	call dword [invalidatehandle]
	ret
	
win_signalgui_sectick:
	dec byte [esi+window.data+signalguidata.life]
	js .closewindow
	mov al,[esi]
	mov bx,[esi+window.id]
	call [invalidatehandle]
	ret
.closewindow:
	jmp [DestroyWindow]
	
win_signalgui_redraw:
	call dword [DrawWindowElements]	
	mov cx, [esi+window.x]
	add cx, win_signalgui_signalx
	mov dx, [esi+window.y]
	add dx, win_signalgui_signaly
	
	mov eax, 0
	test byte [esi+window.data+signalguidata.type], 8
	jz .nosemp
	add eax, 8
.nosemp:
	
	push ecx
	call win_signalgui_drawsignal
	add cx, win_signalgui_signalboxwidth
	add eax, 2
	call win_signalgui_drawsignal
	add cx, win_signalgui_signalboxwidth
	add eax, 2
	call win_signalgui_drawsignal
	add cx, win_signalgui_signalboxwidth
	add eax, 2
	call win_signalgui_drawsignal
	pop ecx
	
	add dx, win_signalgui_signalboxheight
	add eax, 16-6
	call win_signalgui_drawsignal
	add cx, win_signalgui_signalboxwidth
	add eax, 2
	call win_signalgui_drawsignal
	add cx, win_signalgui_signalboxwidth
	add eax, 2
	call win_signalgui_drawsignal
	add cx, win_signalgui_signalboxwidth
	add eax, 2
	call win_signalgui_drawsignal
	ret
	
	
// in eax = 0=plain, 2=pre, 4=exit, 6=combo, +8=semaphore, +16=PBS
win_signalgui_drawsignal:
	pusha
	// undo default sprite xyrel
	add cx, 2
	add dx, 22

	movzx ebx,byte [esi+window.data+signalguidata.life]
	and ebx,1
	add ebx, 0x4fb+12
	and eax, [numsiggraphics]
	jz .nopresignal
	lea ebx,[ebx-0x4fb+eax*8-16]
	add ebx,[presignalspritebase]
.nopresignal:
	call [drawspritefn]
	popa
	ret

win_signalgui_clickhandler:
	mov byte [esi+window.data+signalguidata.life], win_signalgui_timeout
	call dword [WindowClicked]
	jns .click
	ret
.click:
	cmp cl, 0
	jne .notdestroy
	jmp [DestroyWindow]
.notdestroy:
	cmp cl, 1
	jne .nottilebar
	jmp dword [WindowTitleBarClicked]
.nottilebar:
	cmp cl, 2
	je .semptoggleclick
	cmp cl, 3
	je .autosignalclick
	cmp cl, 4
	jnb .signalclick
	ret
.signalclick:
	sub cl, 4
	cmp cl, 8
	jb near .onsignalbutton
	ret
	
.semptoggleclick:
	pusha
	mov ax, word [esi+window.data+signalguidata.x]
	mov cx, word [esi+window.data+signalguidata.y]
	movzx edx, byte [esi+window.data+signalguidata.piece]

	mov bh, 101000b
	mov bl, 3 //  cA_DOIT or cA_NOBLDOVER
	dopatchaction AlterSignalsByGUI
	cmp ebx, 0x80000000
	popa
	je .semptogglefailed
	
	xor byte [esi+window.data+signalguidata.type], 8

.playsound:
	push eax
	push esi
	mov esi, -1
	push ebx
	mov bx, ax
	mov eax, 0x1E
	call [generatesoundeffect]
	pop ebx
	pop esi
	pop eax
	
.semptogglefailed:
	jmp win_signalgui_pressit

.autosignalclick:
	pusha
	mov ax, word [esi+window.data+signalguidata.x]
	mov cx, word [esi+window.data+signalguidata.y]
	mov edx,[autosignalsep-2]	// set edx(16:23)=separation
	mov dl, byte [esi+window.data+signalguidata.piece]
	mov dh, 1

	mov bl, 3 //  cA_DOIT or cA_NOBLDOVER
	dopatchaction AlterSignalsByGUI
	cmp ebx, 0x80000000
	popa
	je .semptogglefailed
	jmp .playsoundandclose

.onsignalbutton:
	pusha
	mov word [operrormsg1],0x1010	//CantBuildSignalsHere
	
	and ecx, 0x0F
	mov bh, byte [signalgui_signalbits+ecx]
	
	mov ax, word [esi+window.data+signalguidata.x]
	mov cx, word [esi+window.data+signalguidata.y]
	movzx edx, byte [esi+window.data+signalguidata.piece]
	
;	mov esi, 0x060008				//CreateAlterSignals
;	call [actionhandler]
	mov bl, 3 //  cA_DOIT or cA_NOBLDOVER
	dopatchaction AlterSignalsByGUI
	cmp ebx, 0x80000000
	popa
	je .signalalterfailed
.playsoundandclose:
	push eax
	push esi
	mov esi, -1
	push ebx
	mov bx, ax
	mov eax, 0x1E
	call [generatesoundeffect]
	pop ebx
	pop esi
	pop eax
	jmp [DestroyWindow]
.signalalterfailed:
	ret

win_signalgui_pressit:
	movzx ecx, cl
	bts dword [esi+window.activebuttons], ecx
	or byte [esi+window.flags], 7
;	mov al,[esi]
;	mov bx,[esi+window.id]
;	or al, 80h
;	mov ah, cl
;	call dword [invalidatehandle]
	call dword [RefreshWindowArea]
	ret
	
	
varb signalgui_signalbits
db 000b
db 010b
db 100b
db 110b
db 10000b
db 10010b 
db 10100b
db 10110b
endvar


//IN:	ax,cx=x,y
//	bl=actionflags
//	bh=pre+exit bits,semaphore toggle bit!+pbs bit
//	dl=trackpiece
// 	dh=action type; 0=set signal type, 1=build autosignals
global altersignalsbygui_flags
uvarb altersignalsbygui_flags

exported AlterSignalsByGUI
	cmp dh,1
	je buildautosignals

	or bh, 0x80
	mov byte [altersignalsbygui_flags], bh
	mov esi, 0x060000
	mov ebp, [ophandler+1*8]
	call [ebp+0x10]
	mov byte [altersignalsbygui_flags], 0
	ret

