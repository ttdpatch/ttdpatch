#include <std.inc>
#include <textdef.inc>
#include <window.inc>
#include <grf.inc>
#include <spriteheader.inc>

#include <imports/gui.inc>
#include <imports/drawsprite.inc>

extern getnumber
extern newspritedata
extern newspritenum
extern spriteblockptr
extern grfstat_nothing

%assign win_grfhelper_width 270
%assign win_grfhelper_height 200

%assign win_grfhelper_mbuttonx  200
%assign win_grfhelper_mbuttony 35
%assign win_grfhelper_mbuttonsize 14
%assign win_grfhelper_mbuttonmidoffset 3

win_grfhelper_elements:
db cWinElemTextBox,cColorSchemeGrey
dw 0, 10, 0, 13, 0x00C5
db cWinElemTitleBar,cColorSchemeGrey
dw 11, win_grfhelper_width-1, 0, 13, ourtext(grfhelpercaption)
db cWinElemSpriteBox,cColorSchemeGrey
dw 0, win_grfhelper_width-1, 14, win_grfhelper_height-1, 0
db cWinElemTextBox, cColorSchemeYellow
dw 16, 16+100, win_grfhelper_mbuttony, win_grfhelper_mbuttony+14, ourtext(textsprite)
%assign grfhelperb_x win_grfhelper_mbuttonx-win_grfhelper_mbuttonmidoffset-win_grfhelper_mbuttonsize
%assign grfhelperb_y win_grfhelper_mbuttony
db cWinElemTextBox, cColorSchemeYellow
dw grfhelperb_x, grfhelperb_x+win_grfhelper_mbuttonsize, grfhelperb_y, grfhelperb_y+win_grfhelper_mbuttonsize, statictext(numminus)
%assign grfhelperb_x win_grfhelper_mbuttonx+win_grfhelper_mbuttonsize+win_grfhelper_mbuttonmidoffset
%assign grfhelperb_y win_grfhelper_mbuttony
db cWinElemTextBox, cColorSchemeYellow
dw grfhelperb_x, grfhelperb_x+win_grfhelper_mbuttonsize, grfhelperb_y, grfhelperb_y+win_grfhelper_mbuttonsize, statictext(numplus)
%assign grfhelperb_x win_grfhelper_mbuttonx
%assign grfhelperb_y win_grfhelper_mbuttony-win_grfhelper_mbuttonmidoffset-win_grfhelper_mbuttonsize
db cWinElemTextBox, cColorSchemeYellow
dw grfhelperb_x, grfhelperb_x+win_grfhelper_mbuttonsize, grfhelperb_y, grfhelperb_y+win_grfhelper_mbuttonsize, statictext(numminus)
%assign grfhelperb_x win_grfhelper_mbuttonx
%assign grfhelperb_y win_grfhelper_mbuttony+win_grfhelper_mbuttonsize+win_grfhelper_mbuttonmidoffset
db cWinElemTextBox, cColorSchemeYellow
dw grfhelperb_x, grfhelperb_x+win_grfhelper_mbuttonsize, grfhelperb_y, grfhelperb_y+win_grfhelper_mbuttonsize, statictext(numplus)
db cWinElemLast


global currentselectedgrf
uvard currentselectedgrf,1
uvard oldcurrentselectedgrf,1
uvarb win_grfhelper_text,10

uvarw win_grfhelper_selectspritennr,1



uvard win_grfhelper_currentsprite,1
uvarb win_grfhelper_exsdrawsprite,1
uvarb win_grfhelper_exscurfeature,1
uvard win_grfhelper_currentxrelptr,1
uvard win_grfhelper_currentyrelptr,1
uvard win_grfhelper_currentrealxrelptr,1	// non-cached versions
uvard win_grfhelper_currentrealyrelptr,1

//	in:
//		ebx = spritenumber
//		al = exsdrawsprite
//	 	ah = exscurfeature
// 	out: updated win_grfhelper_* see above
win_grfhelper_getspriteinfo:
	pusha
	mov byte [win_grfhelper_exsdrawsprite], al
	mov byte [win_grfhelper_exscurfeature], ah
	mov dword [win_grfhelper_currentsprite], ebx
	cmp byte al, 0
	je .noext
	mov ah, byte [win_grfhelper_exscurfeature]
	mov [exscurfeature], ah
	call exsfeaturespritetoreal
.noext:
	mov edi, ebx	
	mov ebx,[newspritedata]
	mov ebp,[newspritenum]
	
	lea edx,[ebx+edi*4]
	mov edx, [edx]
	add edx, 4
	mov dword [win_grfhelper_currentrealxrelptr], edx
	add edx, 2
	mov dword [win_grfhelper_currentrealyrelptr], edx
	
	lea edx,[ebx+ebp*8]
	lea edx,[edx+ebp*2]
	lea edx,[edx+edi*2]
	mov dword [win_grfhelper_currentxrelptr], edx
	
	lea edx,[ebx+ebp*8]
	lea edx,[edx+ebp*2]
	lea edx,[edx+edi*2]
	mov dword [win_grfhelper_currentxrelptr], edx
	
	lea edx,[ebx+ebp*8]
	lea edx,[edx+ebp*4]
	lea edx,[edx+edi*2]
	mov dword [win_grfhelper_currentyrelptr], edx
	popa
	ret

global win_grfhelper_create
win_grfhelper_create:
	pusha
	mov cl, cWinTypeTTDPatchWindow
	mov dx, cPatchWindowGRFHelper  // window.id
	call dword [BringWindowToForeground]
	jnz .alreadywindowopen

	mov eax,[spriteblockptr]
	mov eax,[eax+spriteblock.next]
	test eax,eax
	jle .alreadywindowopen

	mov eax, (640-win_grfhelper_width)/2 + (((480-win_grfhelper_height)/2) << 16) // x, y
	mov ebx, win_grfhelper_width + (win_grfhelper_height << 16) // width , height

	mov cx, cWinTypeTTDPatchWindow	// window type
	mov dx, -1				// -1 = direct handler
	mov ebp, addr(win_grfhelper_winhandler)
	call dword [CreateWindow]
	mov dword [esi+window.elemlistptr], addr(win_grfhelper_elements)
	mov word [esi+window.id], cPatchWindowGRFHelper

.alreadywindowopen:
	popa
	ret
	
win_grfhelper_timer:
	mov ah, 2
	btr dword [esi+window.activebuttons], 2
	jb .switch
	mov ah, 3
	btr dword [esi+window.activebuttons], 3
	jb .switch
	mov ah, 4
	btr dword [esi+window.activebuttons], 4
	jb .switch
	mov ah, 5
	btr dword [esi+window.activebuttons], 5
	jb .switch
	mov ah, 6
	btr dword [esi+window.activebuttons], 6
	jb .switch
	mov ah, 7
	btr dword [esi+window.activebuttons], 7
	jb .switch
	ret	
.switch:
	mov al,[esi]
	mov bx,[esi+window.id]
	or al, 80h
	call dword [invalidatehandle]
	ret
	
win_grfhelperchangedspritetext:
	pusha 
	mov ebx, 0
	mov esi, baTextInputBuffer
	call getnumber
	cmp edx, -1
	jz .error
	mov eax, dword [currentselectedgrf]
	cmp eax, 0
	je .error
	cmp dx, word [eax+spriteblock.numsprites]
	jae .error
	
	mov word [win_grfhelper_selectspritennr],dx
	dec edx		// the first sprite in a grf is not used
	mov ecx, edx
	mov ebx,[eax+spriteblock.spritelist]
	mov esi,[ebx+edx*4]
	cmp byte [_prespriteheader(esi,pseudoflag)], 0x58
	jne .error // is it a real sprite?
	
.next:
	dec edx
	mov edi,[ebx+edx*4]
	cmp byte [_prespriteheader(edi,pseudoflag)], 0x59
	jne .next
	// now we are at?
	cmp byte [edi], 0x05
	je .action5
	cmp byte [edi], 0x01
	jne .error
.action1:
	mov al, 1
	mov ah, byte [edi+1]
	jmp .action1_5
.action5:
	mov ax, 0
.action1_5:	
	movzx ebx, word [_prespriteheader(edi,actionfeaturedata)]
	sub edx, ecx
	neg edx
	dec edx
	add bx, dx
	and ebx, 0xFFFF

	//		ebx = spritenumber
	//		al = exsdrawsprite
	//	 	ah = exscurfeature
	call win_grfhelper_getspriteinfo
	jmp .done
.error:
	mov word [win_grfhelper_selectspritennr],0
	mov dword [win_grfhelper_currentsprite], 0
	mov byte [win_grfhelper_exsdrawsprite],0
	mov byte [win_grfhelper_exscurfeature],0
.done:
	popa
	// refresh win
	mov al,[esi]
	mov bx,[esi+window.id]
	call dword [invalidatehandle]
	ret

win_grfhelper_winhandler:
	mov bx, cx
	mov esi, edi
	cmp dl, cWinEventRedraw
	jz near win_grfhelper_redraw
	cmp dl, cWinEventClick
	jz near win_grfhelper_clickhandler
	cmp dl, cWinEventTimer
	jz near win_grfhelper_timer
	cmp dl, cWinEventTextUpdate
	jz near win_grfhelperchangedspritetext
	ret

var grfhelperbuttonhandler
	dd win_grfhelper_clickchangesprite
	dd win_grfhelper_clickxrelminus
	dd win_grfhelper_clickxrelplus
	dd win_grfhelper_clickyrelminus
	dd win_grfhelper_clickyrelplus

win_grfhelper_clickchangesprite:
	pusha
	mov ax, -1
	mov bp, ourtext(grfhelpercaption)
	mov dword [baTempBuffer1], 0
	mov ch, 8
	mov bl, 80
	mov cl, cWinTypeTTDPatchWindow
	mov dx, cPatchWindowGRFHelper  // window.id
	call [CreateTextInputWindow]
	popa
	ret
win_grfhelper_clickxrelminus:
	mov edi, [win_grfhelper_currentxrelptr]
	cmp edi, 0
	je .exit
	dec word [edi]
	mov edi, [win_grfhelper_currentrealxrelptr]
	dec word [edi]
.exit:
	ret
win_grfhelper_clickxrelplus:
	mov edi, [win_grfhelper_currentxrelptr]
	cmp edi, 0
	je .exit
	inc word [edi]
	mov edi, [win_grfhelper_currentrealxrelptr]
	inc word [edi]
.exit:
	ret
win_grfhelper_clickyrelminus:
	mov edi, [win_grfhelper_currentyrelptr]
	cmp edi, 0
	je .exit
	dec word [edi]
	mov edi, [win_grfhelper_currentrealyrelptr]
	dec word [edi]
.exit:
	ret
win_grfhelper_clickyrelplus:
	mov edi, [win_grfhelper_currentyrelptr]
	cmp edi, 0
	je .exit
	inc word [edi]
	mov edi, [win_grfhelper_currentrealyrelptr]
	inc word [edi]
.exit:
	ret
	
	
win_grfhelper_clickhandler:
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
	jnz .notbackground
	ret
.notbackground:
	push ecx
	movzx ecx, cl
	
	cmp ecx, 3+5
	jae .nohandler

	bts dword [esi+window.activebuttons],ecx
	or byte [esi+window.flags], 7
	mov al,[esi]
	mov bx,[esi+window.id]
	or al, 80h
	mov ah, cl
	call dword [invalidatehandle]
	
	sub ecx, 3

	call [grfhelperbuttonhandler+ecx*4]
	call redrawscreen
.nohandler:
	pop ecx
	ret

win_grfhelper_redraw:
	call dword [DrawWindowElements]
	pusha
	mov ecx, dword [currentselectedgrf]
	cmp ecx, [oldcurrentselectedgrf] 
 	je .nonewgrf
	mov dword [oldcurrentselectedgrf], ecx
	mov dword [win_grfhelper_currentsprite], 0
.nonewgrf:
	mov cx, [esi+window.x]
	mov dx, [esi+window.y]

	mov edi, grfstat_nothing
	mov eax, dword [currentselectedgrf]
	cmp eax, 0
	jz .validfilenameptr
	mov edi, [eax+spriteblock.filenameptr]
	test edi, edi
	jnz .validfilenameptr
	mov edi, grfstat_nothing
.validfilenameptr:
	mov [specialtext1],edi
	mov [specialtext2],edi
	
	push edx
	push ecx
	add cx, 16
	add dx, 20
	mov edi, [currscreenupdateblock]
	mov bx, statictext(grfnamelineselected)
	mov bp, win_grfhelper_width - 100
	mov word [textrefstack],statictext(special1)
	mov dword [SplittextlinesMaxlines],1
	call [drawsplittextfn]
	
	pop ecx
	pop edx
	cmp dword [win_grfhelper_currentsprite], 0
	jz near .nodrawing

	pusha
	add dx, 100
 	add cx, win_grfhelper_width/2

	mov bl, byte [win_grfhelper_exsdrawsprite]
	mov bh, byte [win_grfhelper_exscurfeature]
	mov byte [exsdrawsprite], bl
	mov byte [exscurfeature], bh
	mov ebx, [win_grfhelper_currentsprite]
	mov edi, [currscreenupdateblock]
	
	call [drawspritefn]
	popa

	mov ebx, [win_grfhelper_currentsprite]
		
	cmp byte [win_grfhelper_exsdrawsprite], 0
	je .noext
	mov bh, byte [win_grfhelper_exscurfeature]
	mov [exscurfeature], bh
	call exsrealtofeaturesprite
.noext:
	mov edi, ebx
	pusha
	mov bx, word [win_grfhelper_selectspritennr]
	mov word [textrefstack], bx

	mov edx, dword [win_grfhelper_currentxrelptr]
	mov dx, word [edx]
	mov word [textrefstack+2], dx
	
	mov edx, dword [win_grfhelper_currentyrelptr]
	mov dx, word [edx]
	mov word [textrefstack+4], dx	
	popa

	add cx, 16
	add dx, 56
	mov edi, [currscreenupdateblock]
	mov bx, ourtext(grfhelper_displxrelyrel)
	mov bp, win_grfhelper_width - 100
	mov dword [SplittextlinesMaxlines],1
	call [drawsplittextfn]
.nodrawing:	
	popa
	ret


