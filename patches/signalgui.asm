// New signal gui (should replace the ctrl madness)
// by eis_os

#include <std.inc>
#include <misc.inc>
#include <textdef.inc>
#include <human.inc>
#include <window.inc>
#include <imports/gui.inc>
#include <ptrvar.inc>
#include <flags.inc>
#include <bitvars.inc>

extern drawspritefn
extern presignalspritebase, numsiggraphics
extern resheight, reswidth
extern actionhandler, AlterSignalsByGUI_actionnum, ctrlkeystate
extern RefreshWindowArea
extern generatesoundeffect
extern buildautosignals
extern autosignalsep
extern newsignalsdrawsprite, miscmods2flags, patchflags

%assign win_signalgui_timeout 5

%assign win_signalgui_id 110

%assign win_signalgui_signalx 7
%assign win_signalgui_signaly 15
%assign win_signalgui_signalboxwidth 20
%assign win_signalgui_signalboxheight 28

%assign win_signalgui_width win_signalgui_signalboxwidth*5
%assign win_signalgui_height 14+win_signalgui_signalboxheight*2
%assign win_signalgui_signalboxheightX2 win_signalgui_signalboxheight*2

global sigguiwindimensions
vard sigguiwindimensions
dd win_signalgui_width + (win_signalgui_height << 16) // width , height
endvar

varb win_signalgui_elements
db cWinElemTextBox,cColorSchemeDarkGreen
dw 0, 10, 0, 13, 0x00C5
exported signalboxtopbarwnstruc1
db cWinElemSpriteBox,cColorSchemeDarkGreen
dw 11, win_signalgui_width-1, 0, 13, 0
; --- signalbuttons 2
db cWinElemSpriteBox,cColorSchemeDarkGreen
dw win_signalgui_signalboxwidth*0, win_signalgui_signalboxwidth*1-1, 14, 14+win_signalgui_signalboxheight-1, 0
db cWinElemSpriteBox,cColorSchemeDarkGreen
dw win_signalgui_signalboxwidth*1, win_signalgui_signalboxwidth*2-1, 14, 14+win_signalgui_signalboxheight-1, 0
db cWinElemSpriteBox,cColorSchemeDarkGreen
dw win_signalgui_signalboxwidth*2, win_signalgui_signalboxwidth*3-1, 14, 14+win_signalgui_signalboxheight-1, 0
db cWinElemSpriteBox,cColorSchemeDarkGreen
dw win_signalgui_signalboxwidth*3, win_signalgui_signalboxwidth*4-1, 14, 14+win_signalgui_signalboxheight-1, 0
db cWinElemSpriteBox,cColorSchemeDarkGreen
dw win_signalgui_signalboxwidth*0, win_signalgui_signalboxwidth*1-1, 14+win_signalgui_signalboxheight, 14+win_signalgui_signalboxheightX2-1, 0
db cWinElemSpriteBox,cColorSchemeDarkGreen
dw win_signalgui_signalboxwidth*1, win_signalgui_signalboxwidth*2-1, 14+win_signalgui_signalboxheight, 14+win_signalgui_signalboxheightX2-1, 0
db cWinElemSpriteBox,cColorSchemeDarkGreen
dw win_signalgui_signalboxwidth*2, win_signalgui_signalboxwidth*3-1, 14+win_signalgui_signalboxheight, 14+win_signalgui_signalboxheightX2-1, 0
db cWinElemSpriteBox,cColorSchemeDarkGreen
dw win_signalgui_signalboxwidth*3, win_signalgui_signalboxwidth*4-1, 14+win_signalgui_signalboxheight, 14+win_signalgui_signalboxheightX2-1, 0
; --- semaphore 10
db cWinElemSpriteBox,cColorSchemeDarkGreen
dw win_signalgui_signalboxwidth*4, win_signalgui_signalboxwidth*5-1, 14, 14+win_signalgui_signalboxheight-1, 715
; ---  autosignal 11
db cWinElemSpriteBox,cColorSchemeDarkGreen
dw win_signalgui_signalboxwidth*4, win_signalgui_signalboxwidth*5-1, 14+win_signalgui_signalboxheight, 14+win_signalgui_signalboxheightX2-1-7, 0

db cWinElemTextBox,cColorSchemeDarkGreen
dw win_signalgui_signalboxwidth*4,win_signalgui_signalboxwidth*5-1-win_signalgui_signalboxwidth/2, 14+win_signalgui_signalboxheightX2-1-6, 14+win_signalgui_signalboxheightX2-1, 0x0188
db cWinElemTextBox,cColorSchemeDarkGreen
dw win_signalgui_signalboxwidth*4+win_signalgui_signalboxwidth/2, win_signalgui_signalboxwidth*5-1, 14+win_signalgui_signalboxheightX2-1-6, 14+win_signalgui_signalboxheightX2-1, 0x0189
exported signalboxptbtnwnstruc1
; --- pass-through 14
db cWinElemDummyBox,cColorSchemeDarkGreen
dw win_signalgui_signalboxwidth*5, win_signalgui_signalboxwidth*6-1, 14, 14+win_signalgui_signalboxheight-1, 0
; --- 1-2 inversion 15
db cWinElemDummyBox,cColorSchemeDarkGreen
dw win_signalgui_signalboxwidth*5, win_signalgui_signalboxwidth*6-1, 14+win_signalgui_signalboxheight, 14+win_signalgui_signalboxheightX2-1, 0

global signalboxrobjendpt1
signalboxrobjendpt1:
; --- restriction object 16

db cWinElemLast,cColorSchemeDarkGreen
dw 0, win_signalgui_width-1, 14+win_signalgui_signalboxheightX2, 14+win_signalgui_signalboxheightX2+13, ourtext(tr_siggui_text)

db cWinElemLast
endvar

struc signalguidata
	.xy resw 1	// 00: xy of tile to change
	.x:	resw 1	// 02: x of tile to change
	.y:	resw 1	// 04: y of tile to change
	.life:	resb 1	// 06: seconds left before closing
	.piece:	resb 1	// 07: track piece bit to change
	.type:	resb 1	// 08: signal type (pre/pbs/semaphore) to change //0=plain, 2=pre, 4=exit, 6=combo, +8=semaphore, +16=PBS, +32=through, +64=1-2 inversion
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
	push ecx
	mov cl, 0x2A
	mov dx, win_signalgui_id // window.id
	call [FindWindow]
	pop ecx
	test esi,esi
	jz .noold
	cmp word [esi+window.data+signalguidata.x], ax
	jne .differentlocation
	cmp word [esi+window.data+signalguidata.y], cx
	jne .differentlocation
	or byte [esi+window.flags], 7	// this allows the signalwindow recognize signal changes :)
	popa
	jmp .dooldcode
.differentlocation:
	call [DestroyWindow]
.noold:
	//mov eax, (640-win_signalgui_width)/2 + (((480-win_signalgui_height)/2) << 16) // x, y
	movzx eax, word [mousecursorscry]
	add eax, 1
	mov bx, word [resheight]
	sub bx, win_signalgui_height+26
	cmp ax, bx
	jb .yok
	mov ax, bx
.yok:
	shl eax, 16
	mov ax, word [mousecursorscrx]
	add ax, 1
	mov bx, [reswidth]
	sub bx, win_signalgui_width
	cmp ax, bx
	jb .xok
	mov ax, bx
.xok:
		
	mov ebx, [sigguiwindimensions]

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
	
	mov word [esi+window.data+signalguidata.xy], di
	mov word [esi+window.data+signalguidata.x], ax
	mov word [esi+window.data+signalguidata.y], cx
	mov byte [esi+window.data+signalguidata.life], win_signalgui_timeout
	mov byte [esi+window.data+signalguidata.piece], dl

	mov byte [esi+window.data+signalguidata.type], -1
	call win_signalgui_refreshtilestatus
	or byte [esi+window.flags], 7
	pop esi
	
	mov ebx, 0
	add esp, 4		// unwind the stack, need to be changed to do jc after the icall in fragment, but ohh well it works
	ret


win_signalgui_refreshtilestatus:
	push edx
	push edi
	movzx edi, word [esi+window.data+signalguidata.xy]
	mov dh,[landscape4(di,1)]
	and dh,0xF0
	cmp dh,0x10
	jne .suicide
	
	test byte [landscape5(di,1)], 0xC0
	jz .suicide
	js .suicide
	//signal present
	
	mov dl, byte [landscape3+1+edi*2]

	testflags isignals
	jc .noclearisig
	and dl, ~0x40
.noclearisig:

	//robj,psig
	and dl, ~(0x30|0x81)
	//robj,psig

	mov ebx,landscape6
	test ebx,ebx
	jle .nottoggle
	test byte [ebx+edi], 8
	jz .nopbstoggle
	or dl, 16
.nopbstoggle:
	testflags tsignals
	jnc .nottoggle
	testflags pathbasedsignalling
	jnc .nottoggle
	test byte [ebx+edi], 4
	jz .nottoggle
	or dl, 32
.nottoggle:
	pop edi
	cmp byte [esi+window.data+signalguidata.type], dl
	je .nochange
	mov byte [esi+window.data+signalguidata.type], dl
	call win_signalgui_setdisabledbuttons
.nochange:
	pop edx
	clc
	ret
.suicide:
	pop edi
	pop edx
	stc
	ret
	
win_signalgui_setdisabledbuttons:
	mov dword [esi+window.disabledbuttons], 0
	push edx
	movzx edx, byte [esi+window.data+signalguidata.type]
	test dl, 32
	jz .nott
	or dword [esi+window.disabledbuttons], 1<<14
.nott:
	test dl, 64
	jz .notinv
	or dword [esi+window.disabledbuttons], 1<<15
.notinv:
	and dl, 10110b
	shr dx, 1
	btr dx, 3
	jnc .notpbs
	add dl, 4
.notpbs:
	add dl, 2
	bts dword [esi+window.disabledbuttons], edx
	pop edx
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
	mov dword [esi+window.activebuttons], 0
	call win_signalgui_refreshtilestatus
	jnc .nosuicide
	jmp [DestroyWindow]
.nosuicide:	
	mov al,[esi]
	mov bx,[esi+window.id]
	call dword [invalidatehandle]
	or byte [esi+window.flags], 7 
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
	
	movzx eax, WORD [esi+window.data+signalguidata.xy]
	movzx eax, BYTE [landscape3+1+eax*2]
	and al, 0x30
	shl eax, 3
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

	// display semaphore toggle button
	add cx, win_signalgui_signalboxwidth
	sub eax, 6
	push eax
	xor eax, 8
	and eax, 8
	add eax, 512
	call win_signalgui_drawsignal
	add cx, win_signalgui_signalboxwidth
	testflags tsignals
	jnc .nothrough
	testflags pathbasedsignalling
	jnc .nothrough
	mov eax, 32
	call win_signalgui_drawsignal
.nothrough:
	testflags isignals
	jnc .noinv
	mov eax, 64
	add dx, win_signalgui_signalboxheight
	call win_signalgui_drawsignal
	sub dx, win_signalgui_signalboxheight
.noinv:
	pop eax
	pop ecx
	
	add dx, win_signalgui_signalboxheight
	add eax, 16 //-6
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

	mov eax,1
	add cx, win_signalgui_signalboxwidth-5
	sub dx,1
	call win_signalgui_drawsignal
	add cx,5
	sub dx,3
	call win_signalgui_drawsignal
	add cx,5
	sub dx,3
	call win_signalgui_drawsignal

	movzx eax,byte [autosignalsep]
	mov [textrefstack],eax
	mov bx,statictext(whitedword)
	sub cx,3
	add dx,11
	call [drawcenteredtextfn]
	ret
	
	
// in eax = 0=plain, 2=pre, 4=exit, 6=combo, +8=semaphore, +16=PBS, +32=through, +64=1-2 inversion, +128=restricted, +256=programmed, +512=don't bother with new-signals
//	+1 = diagonal view
win_signalgui_drawsignal:
	pusha
	// undo default sprite xyrel
	add cx, 2
	add dx, 22

	btr eax,0
	sbb ebx,ebx
	and ebx,byte -12	// now ebx=-12 for diagonal view, 0 for normal
	lea esi, [eax*8+12+ebx]
	add ebx, 0x4fb+12
	and eax, [numsiggraphics]
	jz .nopresignal
	lea ebx,[ebx-0x4fb+eax*8-16]
	add ebx,[presignalspritebase]
.nopresignal:
	test esi, 512<<3
	jnz .nons
	test BYTE [miscmods2flags], MISCMODS2_NONEWSIGNALSIGGUI
	jnz .nons
	mov eax, esi
	movzx eax, al	//cut off all past PBS
	and esi, (32+64+128+256)<<3
	lea eax, [eax+esi*4]
	mov esi, eax
	and eax, ~((128+256)<<5)
	and esi, ((128+256)<<5)
	shr esi, 4
	or eax, esi

	xor esi, esi

	call newsignalsdrawsprite
	popa
	ret
.nons:
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

	//trace restriction
	extern tracerestrict_createwindow
	cmp cl, 16
	je tracerestrict_createwindow
	//trace restriction

	cmp cl, 11
	je .autosignalclick
	cmp cl,12
	je .autosignalup
	cmp cl,13
	je .autosignaldown
	cmp cl, 2
	jnb .signalclick
	ret
.signalclick:
	sub cl, 2
	cmp cl, 12
	jb near .onsignalbutton
	testflags tsignals
	jnc .nottclick
	testflags pathbasedsignalling
	jnc .nottclick
	cmp cl, 12
	je near .onsignalbutton
.nottclick:
	testflags isignals
	jnc .noitclick
	cmp cl, 13
	je near .onsignalbutton
.noitclick:
	ret

.autosignalup:
	cmp byte [autosignalsep],255
	jae .press
	inc byte [autosignalsep]
	jmp short .press

.autosignaldown:
	cmp byte [autosignalsep],0
	je .press
	dec byte [autosignalsep]
.press:
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
	je near win_signalgui_pressit
	jmp .playsoundandclose

.onsignalbutton:
	pusha
	mov word [operrormsg1],0x1010	//CantBuildSignalsHere
	
	and ecx, 0x0F
	mov bh, byte [signalgui_signalbits+ecx]
	test bh, 0x68
	jz .noaddoldpretype
	mov bl, [esi+window.data+signalguidata.type]
	and bl, 6+16	//pre+pbs state
	or bh, bl
.noaddoldpretype:
	mov ax, word [esi+window.data+signalguidata.x]
	mov cx, word [esi+window.data+signalguidata.y]
	movzx edx, byte [esi+window.data+signalguidata.piece]

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
	add cl, 2

win_signalgui_pressit:
	movzx ecx, cl
	bts dword [esi+window.activebuttons], ecx
	or byte [esi+window.flags], 7
	mov al,[esi]
	mov bx,[esi+window.id]
	call [invalidatehandle]
	mov byte [esi+window.data+signalguidata.life], win_signalgui_timeout
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
db 1000b	// special: toggle only semaphore!
db 0		//ignore: autosig
db 0		//...
db 0		//...
db 32		//through
db 64		//1-2 inversion //button disabled
endvar


//IN:	ax,cx=x,y
//	bl=actionflags
//	bh=pre+exit bits,semaphore toggle bit!+pbs bit+only semaphore bit,through+inv bits
//	dl=trackpiece
// 	dh=action type; 0=set signal type, 1=build autosignals
//	build autosignals: edx(16:23)=separation
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
	cmp ebx, 0x80000000
	je .failedornotneeded
	mov dh, [altersignalsbygui_flags]
	test dh, 8	//semaphore
	jz .failedornotneeded
	cmp ebx, 0
	jne .failedornotneeded
	mov ebx, [signalremovecost]
.failedornotneeded:
	mov byte [altersignalsbygui_flags], 0
	ret

