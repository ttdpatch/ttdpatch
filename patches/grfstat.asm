// -------------------------------------------
// Graphic Status and Control Window
//
// It relies
// -------------------------------------------

#include <std.inc>
#include <misc.inc>
#include <textdef.inc>
#include <human.inc>
#include <window.inc>
#include <bitvars.inc>
#include <grf.inc>

extern activatedefault,ctrlkeystate
extern BringWindowToForeground,CreateTooltip,CreateWindow,DestroyWindow
extern DrawWindowElements,FindWindow,SplittextlinesMaxlines,WindowClicked
extern WindowTitleBarClicked,actiongrfstat_actionnum,actionhandler
extern currscreenupdateblock,doresetgraphics,drawsplittextfn,drawspritefn
extern exsshowstats,externalvars,fillrectangle,formatspriteerror,hexdigits
extern invalidatehandle,makegrfidlist,miscmodsflags,numactsprites
extern procallsprites,setactivegrfs,setgrfidact,specialtext1,specialtext2
extern specialtext3,specialtext4
extern spriteblockptr,tempSplittextlinesNumlinesptr
extern totalmem
extern totalnewsprites
extern newtexthandler,int21handler,hasaction12,getutf8char,tmpbuffer1,hexnibbles,errorpopup
extern specialerrtext1,specialerrtext2

extern currentselectedgrf
extern win_grfhelper_create


%assign win_grfstat_nument 10		// entries in the list (max. possible is 16)
%assign win_grfstat_numlines 10		// lines in the info box
%assign win_grfstat_width 300		// width in pixels
%assign win_grfstat_applywidth 120	// width of the apply button
%assign win_grfstat_resetwidth 120	// width of the apply button

	// calculate the resulting height
%assign win_grfstat_listheight 15*win_grfstat_nument
%assign win_grfstat_infoheight 10*win_grfstat_numlines+3
%assign win_grfstat_info_y 13+win_grfstat_listheight+2
%assign win_grfstat_apply_y win_grfstat_info_y+win_grfstat_infoheight+1
%assign win_grfstat_height win_grfstat_apply_y+13

varb win_grfstat_elements
db cWinElemTextBox,cColorSchemeGrey
dw 0, 10, 0, 13, 0x00C5
db cWinElemTitleBar,cColorSchemeGrey
dw 11, win_grfstat_width-1, 0, 13, ourtext(grfstatcaption)
db cWinElemTiledBox,cColorSchemeGrey
dw 0, win_grfstat_width-12, 14, win_grfstat_listheight+14
db 1, win_grfstat_nument
db cWinElemSlider,cColorSchemeGrey
dw win_grfstat_width-11, win_grfstat_width-1, 14, win_grfstat_listheight+14, 0
db cWinElemTextBox, cColorSchemeGrey
dw 0, win_grfstat_applywidth, win_grfstat_apply_y, win_grfstat_height-1, ourtext(grfstatapply)
db cWinElemTextBox, cColorSchemeGrey
dw win_grfstat_applywidth+1, win_grfstat_applywidth+win_grfstat_resetwidth-1, win_grfstat_apply_y, win_grfstat_height-1, ourtext(grfstatreset)
db cWinElemSpriteBox,cColorSchemeGrey
dw 0, win_grfstat_width-1, win_grfstat_listheight+15, win_grfstat_apply_y-1, 0
db cWinElemTextBox, cColorSchemeGrey
dw win_grfstat_applywidth+win_grfstat_resetwidth, win_grfstat_width -1, win_grfstat_apply_y, win_grfstat_height-1, ourtext(grfstatdebug)
db cWinElemLast
endvar

global gameoptionsgrfstat
gameoptionsgrfstat:
	db cWinElemFrameWithText, cColorSchemeGrey
	dw 190, 359, 104, 139, ourtext(initialgrfsettings)
	db cWinElemTextBox, cColorSchemeGrey
	dw 200, 349, 118, 129, statictext(opengrfstatus)

global gameoptionsgrfstathints
gameoptionsgrfstathints:
	times 22 dw 0
	times 2 dw ourtext(initialgrfsettingshint)

uvarb grfstat_titleclimate,1,s	// for what climate the grf setting from the
				// title menu were set; -1 if not set

global do_win_grfstat_create
do_win_grfstat_create:
	mov dl,0x02
	mov bl,1
	xor eax,eax
	xor ecx,ecx
	dopatchaction actiongrfstat,jmp

win_grfstat_create:
	pusha
	mov cl, 0x2A
	mov dx, 105 // window.id
	call dword [BringWindowToForeground]
	jnz .alreadywindowopen

	// only open window if any graphics are loaded
	mov eax,[spriteblockptr]
	mov eax,[eax+spriteblock.next]
	test eax,eax
	jle .alreadywindowopen

	mov eax, (640-win_grfstat_width)/2 + (((480-win_grfstat_height)/2) << 16) // x, y
	mov ebx, win_grfstat_width + (win_grfstat_height << 16) // width , height

	mov cx, 0x2A			// window type
	mov dx, -1				// -1 = direct handler
	mov ebp, addr(win_grfstat_winhandler)
	call dword [CreateWindow]
	mov dword [esi+window.elemlistptr], addr(win_grfstat_elements)
	mov word [esi+window.id], 105 // window.id

	call win_grfstat_setnewactive	// set .newactive in each spriteblock
	mov dx, 0
	mov eax,[spriteblockptr]
	mov eax,[eax+spriteblock.next]
.next:
	test eax,eax
	jle .done
	mov eax, [eax+spriteblock.next]
	inc dx
	jmp .next
.done:

	mov byte [esi+window.itemstotal], dl
	mov byte [esi+window.itemsvisible], win_grfstat_nument
	mov byte [esi+window.itemsoffset],0

.alreadywindowopen:
	cmp byte [gamemode],0
	jne .nottitle

	// disable "Apply" in title screen
	bts dword [esi+window.disabledbuttons],4

	// change var.83 to return selected new climate, not current one
	mov dword [externalvars+4*3],newgameclimate

	// and var.92 to return 01 (in-game), not 00
	mov dword [externalvars+4*0x12],gamemode_ingame

	// in title mode, check whether the climate has changed since the
	// last time the window was opened; in that case reset it
	mov al,[newgameclimate]
	cmp al,[grfstat_titleclimate]
	je .nottitle

	mov dl,0x04	// "click" reset button
	mov bl,1
	xor eax,eax
	xor ecx,ecx
	dopatchaction actiongrfstat

.nottitle:
	popa
	xor ebx,ebx
	ret
;end win_grfstat_create

var gamemode_ingame, db 1

	// this is called from a DoAction code
	//
	// in:	bh=number of grf file
	///	dh=activation type (ff=regular, 05=forced)
win_grfstat_setgrfactivation:
	pusha

	call findgrfoffset

	// now eax=>spriteblock
	mov eax,[eax+spriteblock.grfid]
	cmp eax,byte -1
	je .bad

	// swap .newactive and .active, make the list of active/inactive
	// grfids, and flip current one from active to inactive or vice versa
	//
	push eax
	call win_grfstat_swapnewactive
	pop eax

	mov dl,dh
	call setgrfidact
	test dh,dh	// ID not found
	jz .bad

	// now go through all .grf files and check whether they would activate
	extern grfstage
	call setactivegrfs
	mov byte [grfstage+1],4
	mov eax,PROCALL_TEST
	call procallsprites
	mov byte [grfstage+1],0

	// and set the real activation back, keep the new one
	call win_grfstat_swapnewactive

	mov al,0x2a
	mov bx,105
	call dword [invalidatehandle]

.bad:
	popa
	xor ebx,ebx
	ret

win_grfstat_setnewactive:
	mov eax,[spriteblockptr]

.setnext:
	mov bl,[eax+spriteblock.active]
	mov [eax+spriteblock.newactive],bl

	mov eax,[eax+spriteblock.next]
	test eax,eax
	jnle .setnext

.done:
	ret


win_grfstat_swapnewactive:
	mov eax,[spriteblockptr]

.setnext:
	mov bl,[eax+spriteblock.active]
	xchg bl,[eax+spriteblock.newactive]
	mov [eax+spriteblock.active],bl

	mov eax,[eax+spriteblock.next]
	test eax,eax
	jnle .setnext

.done:
	ret

	// this is a DoAction code
	// in:	dl=what to do
	//		00 = flip grf entry, number in bh, setgrfidact in dh
	//		01 = apply changes
	//		02 = open grf status window
	//		03 = close grf status window
	//		04 = reset
global actiongrfstat
actiongrfstat:
	test bl,bl
	jnz .forreal

	xor ebx,ebx	// changing grfs is free
	ret

.forreal:
	cmp dl,1
	jb win_grfstat_setgrfactivation
	je .applybutton

	cmp dl,3
	jb win_grfstat_create
	je near .closewindow

.resetbutton:
	cmp byte [gamemode],0
	jne .regularreset

	mov al,[newgameclimate]
	mov [grfstat_titleclimate],al
	mov al,0x2a
	mov bx,105
	call dword [invalidatehandle]	// need to refresh whole window

.regularreset:
	// reset button pressed
	or eax,byte -1
	mov dl,2
	call setgrfidact
	push 5
	jmp .doapply

.applybutton:
	// apply button pressed

	call win_grfstat_swapnewactive
	call win_grfstat_setnewactive

	push 4

.doapply:
	call grfstat_flashhandle
	jz .nowindow

	// go back to general stats
	mov word [esi+window.selecteditem], -1	

.nowindow:
	cmp byte [gamemode],0
	je .titleapply

	call doresetgraphics
	call win_grfstat_setnewactive
	
// let all windows know we have changed grfs
	pusha
	extern windowstack
	mov edi, [windowstack]
.nextwindow:
	cmp edi, [windowstacktop]
	jnb .donewindows
	mov dl, cWinEventGRFChanges
	extcall GuiSendEventEDI
	add edi, window_size
	jmp short .nextwindow
.donewindows:
	popa
	
	xor ebx,ebx
	ret

.titleapply:
	mov byte [activatedefault],1
	call setactivegrfs
	mov byte [grfstage+1],4
	mov eax,PROCALL_TEST
	call procallsprites
	mov byte [grfstage+1],0
	call win_grfstat_swapnewactive
	xor ebx,ebx
	ret

.closewindow:
	cmp byte [gamemode],0
	jne .nottitle

	// change var.83 and 92 back to normal values
	mov dword [externalvars+4*3],climate
	mov dword [externalvars+4*0x12],gamemode

	// make GRF ID list to be used when starting new game
	call win_grfstat_swapnewactive
	call win_grfstat_setnewactive
	mov dh,1
	call makegrfidlist

.nottitle:
	mov cl, 0x2A
	mov dx, 105 // window.id
	call [FindWindow]
	test esi,esi
	jz .done
	jmp [DestroyWindow]
.done:
	xor ebx,ebx
	ret

// flash grf stat window handle
//
// in:	on stack: subhandle number
// out:	esi->window, or 0 (and ZF set) if none exists
// uses:all
grfstat_flashhandle:
	mov cl,0x2a
	mov dx,105
	call [FindWindow]
	jz .nowindow

	mov eax,[esp+4]		// button ID
	bts [esi+0x1a],eax	// flash the button
	or byte [esi+4],5

	mov ah,al
	mov al,0x2a+0x80
	mov bx,105
	call dword [invalidatehandle]
	test esp,esp		// clear ZF

.nowindow:
	ret 4

	align 2
var win_grfstat_hints
	dw 0x18b,0x18c,ourtext(grflisthint)
	dw 0x190,ourtext(grfapplyhint),ourtext(grfresethint),0,ourtext(grfdebughint),0


win_grfstat_clickhandler:
	call dword [WindowClicked]
	jns .click
	ret
.click:
	cmp byte [rmbclicked],0
	je .notrmb

	// generate hints
	movzx eax,cl
	mov ax,[win_grfstat_hints+eax*2]
	jmp [CreateTooltip]

.notrmb:
	cmp cl, 0
	jne .notdestroy

	mov dl,0x03
	mov bl,1
	xor eax,eax
	xor ecx,ecx
	dopatchaction actiongrfstat,jmp

.notdestroy:
	cmp cl, 1
	jnz .nowindowtitlebarclicked
	jmp dword [WindowTitleBarClicked]
.nowindowtitlebarclicked:
	cmp cl, 4
	jne .notapplybutton

	bt dword [esi+window.disabledbuttons],4
	jc .done

	mov dl,0x01
	mov bl,1
	xor eax,eax
	xor ecx,ecx
	dopatchaction actiongrfstat,jmp

.notapplybutton:
	cmp cl, 2
	je .grflist

	cmp cl,5
	jne .notresetbutton

	mov dl,0x04
	mov bl,1
	xor eax,eax
	xor ecx,ecx
	dopatchaction actiongrfstat

.notresetbutton:
	cmp cl, 6
	jne .nogrfhelper

	push CTRL_ANY
	call ctrlkeystate
	jne .nogrfhelper
	call win_grfhelper_create
	jmp short .pressit
.nogrfhelper:
	cmp cl, 7
	je .grflistdebug
.done:
	ret
.grflistdebug:
	call grfstatuscreatedebug
.pressit:
	movzx ecx, cl
	bts dword [esi+window.activebuttons], ecx
	or byte [esi+0x04], 7
	mov al,[esi]
	mov bx,[esi+window.id]
	or al, 80h
	mov ah, cl
	call dword [invalidatehandle]
	ret

.grflist:
	// find if click was on one of the flags
	sub ax,[esi+window.x]
	sub bx,[esi+window.y]
	sub bx,14
	xchg ax,bx
	aam 15	// ah = y/15=number of entry, al=y%15=ypos within entry
	cmp ah,win_grfstat_nument
	jb .ok
	mov al,14
	mov ah,win_grfstat_nument-1
.ok:
	add ah,[esi+window.itemsoffset]

	push eax
	push esi

	cmp bx,4
	jb .notflag
	cmp bx,17
	ja .notflag
	cmp al,3
	jb .notflag
	cmp al,10
	ja .notflag

	mov bh,ah
	mov dl,0x00
	mov bl,1
	mov dh,0xff

	push CTRL_ANY
	call ctrlkeystate
	jne .notforced

	mov dh,5

.notforced:
	xor eax,eax
	xor ecx,ecx
	dopatchaction actiongrfstat

.notflag:
	pop esi
	pop eax
.notflag_nopop:
	mov al,ah
	mov ah,0
	mov [esi+window.selecteditem],ax

	// redraw window
	mov al,[esi]
	mov bx,[esi+window.id]
	call dword [invalidatehandle]
	ret
;endp win_grfstat_clickhandler

win_grfstat_timer:
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
;endp win_grfstat_timer

win_grfstat_winhandler:
	mov bx, cx
	mov esi, edi
	cmp dl, cWinEventRedraw
	jz win_grfstat_redraw
	cmp dl, cWinEventClick
	jz win_grfstat_clickhandler
	cmp dl, cWinEventTimer
	jz win_grfstat_timer
	cmp dl, cWinEventUITick
	jnz .no_grfstat_uitick
	push esi
	push edx
	mov ax, 0x8000
	call dword [WindowClicked]
	pop edx
	pop esi
.no_grfstat_uitick:
.end:
	ret
;endp win_grfstat_winhandler


findgrfoffset:
	mov eax,[spriteblockptr]
	mov eax,[eax+spriteblock.next]
	mov bl,0
.next:
	test eax,eax
	jle .notfound
	cmp bl,bh
	je .done
	mov eax,[eax+spriteblock.next]
	inc bl
	jmp .next

.notfound:
	or al,1		// clear zero flag

.done:
	ret

win_grfstat_redraw:
	call dword [DrawWindowElements]

	mov cx, [esi+window.x]
	mov dx, [esi+window.y]
	add cx, 4
	add dx, 15

	mov dword [currentselectedgrf], 0
	mov bh,[esi+window.selecteditem]
	call findgrfoffset
	jnz .showgeneral

	mov dword [currentselectedgrf], eax

	// fill info box at bottom
	mov bl,1
	call win_grfstat_drawspriteinfo
	jmp short .showlist

.showgeneral:
	call win_grfstat_showgeneralinfo

.showlist:
	mov bh,[esi+window.itemsoffset]
	call findgrfoffset
	jnz .done

	xor ebx,ebx
.shownextgrf:
	call win_grfstat_drawspriteinfo

	mov eax, [eax+spriteblock.next]
	test eax,eax
	jz .done
	add edx, 15
	inc bh
	cmp bh,win_grfstat_nument
	jb .shownextgrf

.done:
	ret
;endp win_etoolbox_redraw

var grfstat_grfiddisp,	db 0x94,"GRF-ID: ",0x95
var grfstat_hexdisplay,	db "00000000",13	// 0 terminator is in following line
var grfstat_nothing,	db 0
global grfstat_nothing

win_grfstat_showgeneralinfo:
	pusha
	mov edi,textrefstack
	movzx eax,byte [esi+window.itemstotal]
	stosd
	mov eax,[totalmem]
	shr eax,10
	stosd
	mov eax,[totalnewsprites]
	stosd
	movzx eax,word [numactsprites]
	sub eax,baseoursprites
	stosd
	mov ax,ourtext(grfstatmax)
	stosw
	mov ax,16383-baseoursprites
	stosd

	add dword [SplittextlinesMaxlines],win_grfstat_numlines
	mov dx, [esi+window.y]
	add dx,win_grfstat_info_y+2
	mov bp, win_grfstat_width-10
	mov bx, ourtext(grfstatgeninfo1)

	test byte [miscmodsflags+2],MISCMODS_SMALLSPRITELIMIT>>16
	jnz .small

	mov word [edi-6],6	// empty textid (no explicit max for total active sprites)

	call exsshowstats	// in grfloadx.asm
.small:
	mov edi, [currscreenupdateblock]
	call [drawsplittextfn]
	popa
	ret

win_grfstat_drawspriteinfo:
	push ebp
	mov ebp,win_grfstat_numlines

	// if this is the selected entry and has an error, show it
	test bl,bl
	jz near .noerror

	test byte [eax+spriteblock.flags],2	// off because of resource conflict?
	jnz .conflict

	cmp word [eax+spriteblock.errsprite],0
	je near .noerror

	pusha

	mov edi, [currscreenupdateblock]
	add [SplittextlinesMaxlines],ebp

	// Get an error text for a grf
	//  in: eax pointer to spriteblock
	//  out: bx with textid, textrefstack and specialtext1 changed
	//  uses: ecx, edx
	call win_grfstat_geterrorinfo
	jmp short .goterrmsg

.conflict:
	pusha

	mov edi, [currscreenupdateblock]
	add [SplittextlinesMaxlines],ebp

	// in: eax pointer to spriteblock
	// out: bx with textid, textrefstack and specialtext1 changed
	// uses: ecx
	call win_grfstat_geterrconflictinfo

.goterrmsg:
	mov cx, [esi+window.x]
	add cx, 4
	mov dx, [esi+window.y]
	add dx,win_grfstat_info_y+2
	mov bp, win_grfstat_width-10
	call [drawsplittextfn]

	popa
	push eax
	mov eax,[tempSplittextlinesNumlinesptr]
	movzx eax,word [eax]
	inc eax
	sub ebp,eax
	pop eax

.noerror:
	// in; eax pointer to spriteblock
	// out: specialtext1 = name, 2 = file, 3 = grfid, 4 = copyright info
	call win_grfstat_getspriteblockinfo
	

	pusha
	mov edi, [currscreenupdateblock]

	// if this is the selected entry, fill the info box
	test bl,bl
	jz .notselected

	test ebp,ebp
	jle .done		// can't fit more lines

	mov word [textrefstack+0],statictext(special1)
	mov word [textrefstack+2],statictext(special2)
	mov word [textrefstack+4],statictext(special3)
	mov word [textrefstack+6],statictext(special4)
	add [SplittextlinesMaxlines],ebp
	mov dx, [esi+window.y]
	add dx,win_grfstat_info_y+2
	imul ebp,byte -10
	lea dx,[edx+ebp+win_grfstat_numlines*10]
	mov bp, win_grfstat_width-10
	mov bx, ourtext(grfinfotext)
	call [drawsplittextfn]

.done:
	popa
	pop ebp
	ret

.notselected:
	// draw the flag
	xor ebx, ebx
	mov bl, [eax+spriteblock.newactive]
	test bl,bl
	js .gray
	test byte [eax+spriteblock.flags],2	// off because of resource conflict
	jnz .orange
	cmp dword [eax+spriteblock.grfid], byte -1
	je .blue
	and bl, 1
	cmp bl, 1
	je .green
.red:
	mov bl, cColorSchemeRed
	jmp short .drawremappedstatus
.gray:
	mov bl, cColorSchemeGrey
	jmp short .drawremappedstatus
.orange:
	mov bl, cColorSchemeOrange
	jmp short .drawremappedstatus
.green:
	mov bl, cColorSchemeGreen
	jmp short .drawremappedstatus
.blue:
	mov bl, cColorSchemeBlue

.drawremappedstatus:
	add bx, 775
	shl ebx, 10h
	mov bx, 747+8000h
	add edx, 2

	// draw a black rectangle to accentuate the flag sprite
	pusha
	lea eax,[ecx+1]		// X1
	lea ebx,[eax+13]	// X2
	lea ecx,[edx+1]		// Y1
	add edx,8		// Y2
	mov bp,0 + 0xd7*WINTTDX	// black
	call [fillrectangle]
	popa

	call [drawspritefn]
	popa

	// draw the entry in the list
	pusha
	mov word [textrefstack],statictext(special1)
	cmp byte [eax+spriteblock.errsprite],0
	mov al,bh
	mov bx, statictext(grfwitherrorselected)
	jne .haserror
	mov bx, statictext(grfnamelineselected)
.haserror:
	add al,[esi+window.itemsoffset]
	cmp al,[esi+window.selecteditem]
	je .selected
	dec bx
.selected:
	add ecx, 17
	add edx, 2
	mov bp, win_grfstat_width-20-12
	add dword [SplittextlinesMaxlines],1
	call [drawsplittextfn]
	popa
	pop ebp
	ret
;endp win_grfstat_drawspriteinfo

// in
// eax = dword
// edi = ptr to buffer
eaxtohexascii:
	push ecx
	push edx
// bswap
	xchg al,ah
	rol eax,16
	xchg al,ah

	xchg edx, eax
	mov ecx, 8
.next4bit:
	dec ecx
	mov eax, edx
	and eax, 0x0f
	mov al, byte [hexdigits+eax]
	mov [edi+ecx],al
	ror edx, 4
	cmp ecx, 0
	ja .next4bit
	pop edx
	pop ecx
	ret



// Get an error text for a grf
//  in: eax pointer to spriteblock
//  out: bx with textid, textrefstack and specialtext1 changed
//  uses: ecx, edx

win_grfstat_geterrorinfo:	
	xor ebx,ebx
	movzx edx,word [eax+spriteblock.errsprite]
	test dh,dh
	jns .actionberror

	// error not generated by grf but by patch
	mov cx,[eax+spriteblock.cursprite]
	inc cx		// first sprite is sprite #1
	mov [textrefstack+2],cx
	mov ecx,[eax+spriteblock.filenameptr]
	mov [specialtext1],ecx
	mov word [textrefstack],statictext(special1)
	mov ebx,[eax+spriteblock.errparam]
	mov [textrefstack+4],ebx
	cmp dx,ourtext(grfbefore)
	je .beforeafter
	cmp dx,ourtext(grfafter)
	jne .notbeforeafter

.beforeafter:	// for before/after messages, error param is a string pointer
	mov word [textrefstack+2],statictext(special2)
	mov [specialtext2],ebx
.notbeforeafter:
	mov ebx,edx
	ret
.actionberror:
	push esi
	push edi
	xchg eax,edx
	call formatspriteerror
	pop edi
	pop esi
	ret
	
	
// Get an conflict error text (only use if flags say so)
//  in: eax pointer to spriteblock
//  out: bx with textid, textrefstack and specialtext1 changed
//  uses: ecx
win_grfstat_geterrconflictinfo:
	mov bx,statictext(special1)
	mov ecx,[eax+spriteblock.errparam]
	test ecx,ecx
	jle .noconflictarg

	mov ecx,[ecx+spriteblock.nameptr]
	test ecx,ecx
	jg .haveconflictarg

.noconflictarg:
	mov bx,6	// empty text ID

.haveconflictarg:
	mov [textrefstack],bx
	mov [specialtext1],ecx
	mov ecx,[eax+spriteblock.errparam+4]
	mov [textrefstack+2],ecx
	mov bx,ourtext(grfconflict)
	ret
	
// in: eax pointer to spriteblock
// out: specialtext1 = name, 2 = file, 3 = grfid, 4 = copyright info
win_grfstat_getspriteblockinfo:
	pusha
	mov edi, [eax+spriteblock.filenameptr]
	test edi, edi
	jnz .validfilenameptr
	mov edi, grfstat_nothing
.validfilenameptr:
	mov [specialtext1],edi		// use filename as default if no desc
	mov [specialtext2],edi

	push eax
	mov edi, grfstat_nothing
	mov eax, [eax+spriteblock.grfid]
	cmp eax,byte -1
	je .nogrfid
	mov edi, grfstat_grfiddisp
	push edi
	add edi,byte grfstat_hexdisplay-grfstat_grfiddisp

	call eaxtohexascii
	pop edi
.nogrfid:
	mov [specialtext3],edi
	pop eax

	mov ecx,[eax+spriteblock.action8]
	mov edi,grfstat_nothing
	test ecx, ecx
	jz .tooshort

	lea edi,[ecx+5]

	cmp byte [edi],0
	je .nodesc
	mov [specialtext1],edi
.nodesc:

	mov al, 0
	mov ecx,[edi-10]	// sprite size is stored in front of data
	sub ecx,7
	mov [edi+ecx],al	// make sure last byte is zero terminator
	jbe .tooshort
	cld
	repne	scasb
.tooshort:
	mov [specialtext4],edi
	popa
	ret
	

// code dealing with the GRF Status window in the game options menu

// click handler
// in:	cl=clicked element index
// out:
// safe:all?
global gameoptionsclick
gameoptionsclick:
	cmp cl,21
	je near $
ovar .savevehnames, -4,$,gameoptionsclick

	cmp cl,23
	je .grfstat
	ret

.grfstat:
	or byte [esi+window.activebuttons+2],1<<(23-16)
	or byte [esi+window.flags],5

	mov bx,[esi+window.id]
	mov al,[esi+window.type]
	or al,0x80
	mov ah,23	
	call [invalidatehandle]

	call do_win_grfstat_create
	ret

global gameoptionstimer
gameoptionstimer:
	mov ah,21
	btr dword [esi+window.activebuttons],21
	jc .done
	mov ah,23
	btr dword [esi+window.activebuttons],23
.done:
	ret

	
varb grfstatusdebugfile
	db "grfdebug.txt", 0
varb grfstatusdebugtextcom
	db 13,10,"# ", 0
varb grfstatusdebugtextnl
	db 13,10,0
varb grfdebug_txtfaulty
	db "Faulty",0
varb grfdebug_txtconflict
	db "Conflict",0
varb grfdebug_txtspecial
	db "Special",0
varb grfdebug_txtactive
	db "Active",0
varb grfdebug_txtdeactive
	db "Inactive",0 
vard grfstatusdebugfilehandle
	dd 0
varb grfstatusdebugparam
	db "Parameter 0x##: 0x######## ",0 
endvar

uvarb grfstatusdebugfinish,5

uvarb grfstatusbuffer, 4048	// for grf creators who get overexcited

// in esi = buffer to output
grfstatuscreatedebugstrout:
	pusha
	mov edx, esi
	xor ecx,ecx
.nextlen:
	cmp byte [esi],0
	je .gotlength
	inc esi
	inc ecx
	jmp short .nextlen
.gotlength:
	mov bx, [grfstatusdebugfilehandle]
	mov al, 0
	mov ah, 0x40
	CALLINT21
	popa
	ret
	
grfstatuscreatedebug:

	pusha
	mov dword [grfstatusdebugfinish], 'FAIL'
	mov edx, grfstatusdebugfile
	xor ecx,ecx
	mov ah,0x3c		//create file
	mov al,0		
	CALLINT21
	jc near .done
	mov [grfstatusdebugfilehandle],ax

	extern ttdpatchversion,ttdpatchversion_end
	mov esi,grfstatusdebugtextcom
	call grfstatuscreatedebugstrout
	mov al,0
	xchg al,[ttdpatchversion_end]
	mov esi,ttdpatchversion
	call grfstatuscreatedebugstrout
	mov [ttdpatchversion_end],al

	mov ebp,[spriteblockptr]
	mov ebp,[ebp+spriteblock.next]
	
.nextgrf:
	// in; eax pointer to spriteblock
	// out: specialtext1 = name, 2 = file, 3 = grfid, 4 = copyright info
	xchg eax, ebp
	call win_grfstat_getspriteblockinfo
	xchg ebp, eax
	
	mov esi, grfstatusdebugtextcom
	call grfstatuscreatedebugstrout
	mov esi, [specialtext1]
	call grfstatuscreatedebugstrout
	
	
	mov esi, grfstatusdebugtextnl
	call grfstatuscreatedebugstrout
	mov esi, [specialtext2]
	call grfstatuscreatedebugstrout
	
	mov esi, grfstatusdebugtextcom
	call grfstatuscreatedebugstrout
	mov esi, [specialtext3]
	cmp byte [esi], 0
	je .nogrfid
	add esi, 10
	mov edi, grfstatusbuffer
	movsd
	movsd
	mov byte [edi], 0
	mov esi, grfstatusbuffer
.nogrfid:
	call grfstatuscreatedebugstrout
	
	mov esi, grfstatusdebugtextcom
	call grfstatuscreatedebugstrout
	mov esi, [specialtext4]
	mov edi, grfstatusbuffer
	call removepecialcodesfromstring
	mov esi, grfstatusbuffer
	call grfstatuscreatedebugstrout
	
// status		
	mov esi, grfstatusdebugtextcom
	call grfstatuscreatedebugstrout 

	xor ebx, ebx
	mov bl, [ebp+spriteblock.active]
	mov esi, grfdebug_txtfaulty
	test bl,bl
	js .donestatus
	mov esi, grfdebug_txtspecial
	cmp dword [ebp+spriteblock.grfid], byte -1
	je .donestatus
	mov esi, grfdebug_txtactive
	and bl, 1
	cmp bl, 1
	je .donestatus
	mov esi, grfdebug_txtconflict
	test byte [ebp+spriteblock.flags],2	// off because of resource conflict
	jnz .donestatus
	mov esi, grfdebug_txtdeactive
.donestatus:
	call grfstatuscreatedebugstrout
	
	pusha
	mov edi, grfstatusbuffer
	mov dword [edi], " A: "
	mov dword [edi+4], "  F:"
	mov dword [edi+8], 0
	add edi, 3
	movzx eax, byte [ebp+spriteblock.active]
	mov cl, 2
	call hexnibbles
	add edi, 3
	movzx eax, byte [ebp+spriteblock.flags]
	mov cl, 2
	call hexnibbles
	popa
	mov esi, grfstatusbuffer
	call grfstatuscreatedebugstrout
		
// error message
	pusha
	mov esi, grfstatusdebugtextcom
	call grfstatuscreatedebugstrout
	
	mov eax, ebp	
	test byte [eax+spriteblock.flags],2	// off because of resource conflict?
	jnz .conflict

	cmp word [eax+spriteblock.errsprite],0
	je .noerror

	// Get an error text for a grf
	//  in: eax pointer to spriteblock
	//  out: bx with textid, textrefstack and specialtext1 changed
	//  uses: ecx, edx
	call win_grfstat_geterrorinfo
	jmp short .goterrmsg
.conflict:
	// in: eax pointer to spriteblock
	// out: bx with textid, textrefstack and specialtext1 changed
	// uses: ecx
	call win_grfstat_geterrconflictinfo
.goterrmsg:
	mov edi, grfstatusbuffer
	pusha
	mov eax, ebx
	call newtexthandler
	popa
	mov esi, grfstatusbuffer
	call grfstatuscreatedebugstrout
.noerror:
	popa
		
	pusha
	movzx ecx, byte [ebp+spriteblock.orgnumparam]
	test ecx,ecx
	jz .noparams

	mov esi, grfstatusdebugtextcom
	call grfstatuscreatedebugstrout
.nextparm:
	dec ecx
	
	mov eax, ecx
	mov edi, grfstatusdebugparam
	push ecx
	add edi, 12
	mov cl, 2
	call hexnibbles
	pop ecx
	
	add edi, 4
	
	push ecx
	mov eax, [ebp+spriteblock.orgparamptr]
	mov eax, [eax+ecx*4]
	mov cl, 8
	call hexnibbles
	pop ecx
	mov esi, grfstatusdebugparam
	call grfstatuscreatedebugstrout

	mov esi, grfstatusdebugtextcom
	call grfstatuscreatedebugstrout

	cmp ecx, 0
	jnz .nextparm
.noparams:
	popa
	
	
	mov esi, grfstatusdebugtextnl
	call grfstatuscreatedebugstrout

	mov ebp, [ebp+spriteblock.next]
	test ebp,ebp
	jnz near .nextgrf
	
	mov bx, [grfstatusdebugfilehandle]
	mov al, 0
	mov ah, 0x3e
	CALLINT21
	mov word [grfstatusdebugfilehandle], 0
	mov dword [grfstatusdebugfinish], 'OK'
.done:
	mov dword [specialerrtext1], grfstatusdebugfinish
	mov dword [specialerrtext2], grfstatusdebugfile
	mov dword [textrefstack],(statictext(specialerr1)<<16)+statictext(specialerr2)
	mov bx,ourtext(grfdebugmsg)
	mov dx,-1
	xor ax,ax
	xor cx,cx
	call dword [errorpopup]
	popa
	ret

// Strip special chars in a TTD Text string
// esi = source string
// edi = dest string
exported removepecialcodesfromstring
	pusha
.copyloop:
	cmp byte [hasaction12],0
	je .notutf8
	push esi
	call getutf8char
	pop ecx
	sub esi,ecx
	xchg esi,ecx	// now ecx=number of bytes in UTF-8 sequence, esi->sequence
	jmp short .check
.notutf8:
	movzx eax,byte [esi]
	mov ecx,1
.check:
	test eax,eax
	jz .zero
	cmp eax, 0Dh
	jz .lbl0Dh
	cmp eax, 20h
	jb .skip
	cmp eax, 88h
	jb .lbl88h
	cmp eax, 99h
	jb .skip
	
.lbl88h:
	rep movsb
	jmp .copyloop

.lbl0Dh:
	mov dword [edi], 20202020h
	add edi, 4

.skip:
	add esi,ecx
	jmp .copyloop

.zero:
	mov [edi], al
	popa
	ret
