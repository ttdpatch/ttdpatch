// enhgui.asm
// Copyright 2003 Oskar Eisemuth
//
// Several GUI Window and Code functions.
// Currently this file handles all enhancegui stuff
// - Depot window bigger and trash everywhere
// - Station window
//  . trackbuttons
//  . eyecandy
// - Transparent Station GUI Code
// - New texthandler for company colors in Texts

#include <std.inc>
#include <proc.inc>
#include <flags.inc>
#include <textdef.inc>
#include <window.inc>
#include <misc.inc>
#include <human.inc>
#include <ptrvar.inc>

extern BringWindowToForeground,CreateTooltip,CreateWindow,DestroyWindow
extern DragEWRailUITick,DragNSRailUITick,DrawWindowElements,FindWindow
extern GenerateDropDownMenu,LoadWindowSizesFinish,RefreshLandscapeHighlights
extern RefreshWindowArea,ReleaseNSorEWRail,ResetDefaultWindowSizes
extern SaveWindowSizesPrepare,ScreenToLandscapeCoords,WindowClicked
extern WindowTitleBarClicked,actionhandler,cleararea_actionnum,ctrlkeystate
extern curselclass,curselstation,disallowedlengths,disallowedplatforms
extern findstationforclass,findstationforclass.next,generatesoundeffect
extern getgroundaltitude,guispritebase,int21handler,invalidatehandle
extern makestationclassdropdown,makestationseldropdown,numstationsinclass
extern patchflags,redrawscreen,setmousetool,stationclassesused
extern stationseldropdownclick,windowsizesbufferptr,windowstack
extern winelemdrawptrs,errorpopup
extern depotscalefactor,gettileinfo,numguisprites,guispritebase




var enhanceguifile, db "eguiopt.dat", 0
var enhanceguifilehandle, dw 0

uvard enhanceguioptions_defaultdata	
uvard enhanceguioptions_savedata	

#if 0
uvard windowRailDepotSize,1,s
// Check for mammothtrains otherwise you will kill a runindex at:
uvard windowRailDepotDrawWithEngine,1,s	
uvard windowRailDepotDrawWithNoEngine,1,s
#endif

// The trash drop handle, the first is the rail depot, 
// the others can be mixed in Win or Dos
uvard windowRailDepotDropHandle,1,s
uvard windowDepotDropHandle1,1,s
uvard windowDepotDropHandle2,1,s
uvard windowDepotDropHandle3,1,s

// add new track buttons to the station window
// in:	edi->window element list
global addnewtrackbuttons
addnewtrackbuttons:
	add edi, 3Ch

	mov ax, 20 // x1
	mov bx, 34 // x2
	mov cl, 7

	push edi

.trackbuttons:		// now we create the trackbuttons new

	mov word [edi], 0x0E03
	mov [edi+2h], ax
	mov [edi+4h], bx
	mov dword [edi+6h], 0x00620057 // 57 00 62 00 => y1 & y2
	mov word [edi+0Ah], statictext(num7) + 1 // 0x014A empty
	sub word [edi+0Ah], cx

	add ax, 15
	add bx, 15
	add edi, 12
	loop .trackbuttons

// ------------------
	mov ax, 20
	mov bx, 34
	mov ecx, 7

.lengthbuttons:

	mov word [edi], 0x0E03
	mov [edi+2h], ax
	mov [edi+4h], bx
	mov dword [edi+6h], 0x007B0070 // 79 00 7B 00 => y1 & y2
	mov word [edi+0Ah], statictext(num7) + 1 // 0x014A empty
	sub word [edi+0Ah], cx

	add ax, 15
	add bx, 15
	add edi, 12
	loop .lengthbuttons

	mov ax,0x0403
	xor ebx,ebx
	or ebp,byte -1

	testmultiflags morestationtracks
	jnz .donetrackbuttons

	pop edi
	push edi

	mov cl,4
	mov al,1
	mov ebx,0x80008000
	xor ebp,ebp

.nextoldtrackbutton:
	add dword [edi+2],0x00180018	// move it back to the original place
	add edi,12
	loop .nextoldtrackbutton

	mov cl,3
.nextdummytrackbutton:
	mov [edi],al			// make it a spritebox located outside the window
	or [edi+2],ebx			// (so it won't draw anything and can't be clicked on)
	and [edi+0Ah],bp		// and make it have no actual sprite
	add edi,12
	loop .nextdummytrackbutton

	mov cl,5
.nextoldlengthbutton:
	add dword [edi+2],0x00110011
	add edi,12
	loop .nextoldlengthbutton

	mov cl,2
.nextdummylengthbutton:
	mov [edi],al
	or [edi+2],ebx
	and [edi+0Ah],bp
	add edi,12
	loop .nextdummylengthbutton

.donetrackbuttons:
	pop esi		// shorter than add esp,4

// on \ off buttons
	mov word [edi], 0x0E03
	mov dword [edi+2h], 0x0049000E // 0E 00 49 00 => x1 & x2
	mov dword [edi+6h], 0x00940089 // 89 00 94 00 => y1 & y2
	mov word [edi+0Ah], 0x02DB	 // DB 02
	add edi, 12

	mov word [edi], 0x0E03
	mov dword [edi+2h], 0x0085004A // 4A 00 85 00 => x1 & x2
	mov dword [edi+6h], 0x00940089 // 89 00 94 00 => y1 & y2
	mov word [edi+0Ah], 0x02DA	 // DA 02
	add edi, 12

// new length buttons

	mov word [edi], ax
	mov dword [edi+2h], 0x008B007D
	or [edi+2],ebx
	mov dword [edi+6h], 0x00620057
	mov word [edi+0Ah], statictext(numplus7)
	and [edi+0Ah],bp
	add edi, 12

	mov word [edi], ax
	mov dword [edi+2h], 0x008B007D
	or [edi+2],ebx
	mov dword [edi+6h], 0x007B0070
	mov word [edi+0Ah], statictext(numplus7) // 0x014A empty
	and [edi+0Ah],bp
	add edi, 12

// eyecandy
	testflags newstations
	jnc .nonewstations
	mov word [edi], 0x0705		// box type and colour
	mov dword [edi+2h], 0x00800007	// reversed x1 & x2
	mov dword [edi+6h], 0x0019000F	// reversed y1 & y2
	mov word [edi+0Ah], 6
	add edi, 12

	mov word [edi], 0x0703		// box type and colour
	mov dword [edi+2h], 0x008B0081	// reversed x1 & x2
	mov dword [edi+6h], 0x0019000F	// reversed y1 & y2
	mov word [edi+0Ah], statictext(vehlist_menubutton)	// Caption (downward pointing triangle)
	add edi, 12

	mov word [edi], 0x0705
	mov dword [edi+2h], 0x00800007 // reversed x1 & x2
	mov dword [edi+6h], 0x0054004A // reversed y1 & y2
	mov word [edi+0Ah], 6
	add edi, 12

	mov word [edi], 0x0703
	mov dword [edi+2h], 0x008B0081 // reversed x1 & x2
	mov dword [edi+6h], 0x0054004A // reversed y1 & y2
	mov word [edi+0Ah], statictext(vehlist_menubutton)	// Caption (downward pointing triangle)
	add edi, 12
.nonewstations:
	mov byte [edi], 0x0B
	ret

// -------------------------------------------
// Rail Station Window
// -------------------------------------------
//uvard wcurrentstationsizeptr,1,s

global stationwindowclickhandler
stationwindowclickhandler:
	cmp cl,0x17
	jb .notstationsel
	inc cl
	and cl,~1	// pretend pressing button 18/1A for button 17/19

.notstationsel:
	bt [esi+window.disabledbuttons],cx
	jnc .notdisabled

	mov cl,255
	ret

.notdisabled:
	cmp cl, 1
	jne .nowindowclick
	jmp dword [WindowTitleBarClicked]

.nowindowclick:
	cmp cl, 15h
	jne .notrackextends
	call trackextend
	ret

.notrackextends:
	cmp cl, 16h
	jne .nolengthextends
	call lengthextend
	ret

.nolengthextends:
	cmp cl,17h
	jb .notstationselbutton

	cmp cl,1ah
	ja .notstationselbutton

	cmp cl,18h
	jbe near makestationclassdropdown
	jmp makestationseldropdown

.notstationselbutton:
	ret
;endp stationwindowclickhandler

global stationwindowactivehandler
stationwindowactivehandler:
	and bp, 7F00h
	shr bp, 8
	cmp bp, 6
	jna .smalltracks
	sub bp, 7
	bts ebx, 15h
.smalltracks:
	add bp, 5
	bts ebx, ebp

	mov bp, ax
	and bp, 0xFF
	cmp bp, 6
	jna .smalllength
	sub bp, 7
	bts ebx, 16h
.smalllength:
	add ebp, 12
	bts ebx, ebp

	// if eyecandy need to change toggle status.
	mov ebp,[esi+0x1a]
	and ebp,-1<<0x17
	or ebx,ebp

	call setstationdisabledbuttons

	ret

global setstationdisabledbuttons
setstationdisabledbuttons:
	pusha

	// set disabled buttons
	xor edx,edx

	// disable class selection buttons if no other classes available

	cmp dword [stationclassesused],1
	ja .havenewclasses

	or edx,(0<<0x17) + (1<<0x18)

.havenewclasses:

	// and the station selection also if less than two stations available
	// in this class

	push edx

	movzx eax,byte [curselclass]
	cmp byte [numstationsinclass+eax],1
	jbe .disablestationsel

	// there are at least two stations in the class, let's see if they
	// are actually available

	call findstationforclass
	jc .disablestationsel

	call findstationforclass.next
	jnc .havenewstations

.disablestationsel:
	or dword [esp],(0<<0x19) + (1<<0x1a)

.havenewstations:
	pop edx

	// buttons 5..B = station platforms, C..12 = length, 13/14 = on/off
	// 15 = + for platforms, 16 = + for length
	//
	movzx eax,byte [curselstation]

	mov cl,[disallowedplatforms+eax]
	test cl,cl
	jns .nodisableplusplat
	bts edx,0x15
.nodisableplusplat:
	and ecx,01111111b
	shl ecx,5
	or edx,ecx

	mov cl,[disallowedlengths+eax]
	test cl,cl
	jns .nodisablepluslength
	bts edx,0x16
.nodisablepluslength:
	and ecx,01111111b
	shl ecx,12
	or edx,ecx

	mov [esi+window.disabledbuttons],edx
	popa
	ret

global createstationwindow
createstationwindow:
	call $+5
ovar .old,-4,$,createstationwindow

	// see if current station selection is still valid

	movzx eax,byte [curselclass]
	cmp byte [numstationsinclass+eax],0
	je .badclass

	call findstationforclass
	jnc .ok

.badclass:
	mov dl,0
	mov [curselclass],dl

.ok:
	mov [curselstation],dl
	ret

global stationwindoweventhandler
stationwindoweventhandler:
	mov bx,cx
	mov esi,edi

	cmp dl,0x10
	je stationseldropdownclick

	cmp dl,5
	jne near $
ovar .oldhandler,-4,$,stationwindoweventhandler

	mov eax,0x17

.nextbutton:
	btr [esi+0x1a],eax
	jnc .notactive

		// refresh button
	push eax
	mov ah,al
	mov al,[esi]
	or al,0x80
	mov bx,[esi+6]
	call dword [invalidatehandle]
	pop eax

.notactive:
	inc eax
	cmp al,0x1a
	jbe .nextbutton
	ret


trackextend:
	push eax
	push esi
	mov esi, wcurrentstationsize
	mov ax, word [esi]
	and word [esi], 80FFh	// wipe away old
	and ax, 7F00h		// we have the station orientation in the word too
	cmp ah, 6
	ja .removebigtrack
	add ah, 7
	jmp short .writebigtrack
.removebigtrack:
	sub ah, 7
.writebigtrack:
	or word [esi], ax
	pop esi
	pop eax
	mov al,[esi]
	mov bx,[esi+6]
	call dword [invalidatehandle]
	pop eax
	ret
;endp lengthextend:

lengthextend:
	push eax
	push esi
	mov esi, wcurrentstationsize
	mov ax, word [esi]
	cmp al, 6
	ja .removebiglength
	add al, 7
	jmp short .writebiglength
.removebiglength:
	sub al, 7
.writebiglength:
	mov word [esi], ax
	pop esi
	pop eax
	mov al,[esi]
	mov bx,[esi+6]
	call dword [invalidatehandle]
	pop eax
	ret


;endp lengthextend:





// -------------------------------------------
// Enhance GUI Toolbox Window
// -------------------------------------------

win_etoolbox_elements:
db cWinElemTextBox,cColorSchemeDarkGreen
dw 0, 10, 0, 13, 0x00C5
db cWinElemTitleBar,cColorSchemeDarkGreen
dw 11, 167, 0, 13, ourtext(txtetoolbox)
db cWinElemSpriteBox,cColorSchemeDarkGreen
dw 0, 167, 14, 123, 0
db cWinElemTextBox, cColorSchemeYellow
dw 10, 10+134, 20, 20+11, ourtext(txtetoolbox_tsigns)
db cWinElemTextBox, cColorSchemeYellow
dw 10+135, 10+147, 20, 20+11, statictext(txtetoolbox_dropdown)
db cWinElemDummyBox, cColorSchemeYellow			//remove the depot size here, because this is handled by winsize.asm now. 
dw 10, 10+134, 34, 34+11, ourtext(txtetoolbox_dsize)	//completely removing these window-elements would change the idx'es of
//db cWinElemDummyBox, cColorSchemeYellow			//the other buttons, and would rquire changing all code refering to them
//dw 10+135, 10+147, 34, 34+11, statictext(txtetoolbox_dropdown)
db cWinElemTextBox, cColorSchemeYellow
dw 10, 10+147, 56+32, 56+11+32, ourtext(txtetoolbox_resetdefaultsizes)
db cWinElemTextBox, cColorSchemeYellow
dw 10, 10+134, 34, 34+11, ourtext(txtetoolbox_depotalltrash)
db cWinElemTextBox, cColorSchemeYellow
dw 10+135, 10+147, 34, 34+11, statictext(txtetoolbox_dropdown)
db cWinElemTextBox, cColorSchemeGrey
dw 10, 10+147, 56, 56+11, ourtext(txtetoolbox_saveinsavegame)
db cWinElemTextBox, cColorSchemeGrey
dw 10, 10+147, 56+14, 56+11+14, ourtext(txtetoolbox_usedefaultinsave)
db cWinElemTextBox, cColorSchemeYellow
dw 10, 10+147, 56+18+32, 56+11+18+32, ourtext(txtetoolbox_saveasdefault)
db cWinElemLast


global win_etoolbox_create
win_etoolbox_create:
	pusha
	mov cl, cWinTypeTTDPatchWindow
	mov dx, cPatchWindowEnhGUI // window.id
	call dword [BringWindowToForeground]
	jnz .alreadywindowopen
	
	mov eax, 236 + (180 << 16) // x, y
  	mov ebx, 168 + (124 << 16) // width , height

	mov cx, cWinTypeTTDPatchWindow	// window type
	mov dx, -1				// -1 = direct handler
	mov ebp, addr(win_etoolbox_winhandler)
	call dword [CreateWindow]
	mov dword [esi+24h], addr(win_etoolbox_elements)
	mov word [esi+window.id], cPatchWindowEnhGUI // window.id
.alreadywindowopen:
	popa
	ret
;end win_toolbox_create


win_etoolbox_clickhandler:
	call dword [WindowClicked]
	jns .click
.exit:
	ret
.click:
	cmp byte [rmbclicked],0
	jne .exit

	cmp cl, 0
	jnz .notdestroy 
	jmp dword [DestroyWindow]
.notdestroy:
 	cmp cl, 1
	jnz .nowindowtitlebarclicked
 	jmp dword [WindowTitleBarClicked]
.nowindowtitlebarclicked:
	cmp cl, 4
	jnz .notransparentstationsign
	movzx dx, byte [egui_stationsignstyle]
 	mov word [tempvar], ourtext(txtetoolbox_tsignstrans) 
 	mov word [tempvar+2], ourtext(txtetoolbox_tsignsold)
	mov word [tempvar+4], 0xFFFF
 	xor ebx, ebx
	jmp dword [GenerateDropDownMenu]
.notransparentstationsign:
#if 0
	cmp cl, 6
	jnz .nodepotadjust
	movzx dx, byte [egui_depotsize]
	shr dx,1
	sub dx,4
	mov word [tempvar], ourtext(txtetoolbox_d8) 
 	mov word [tempvar+2], ourtext(txtetoolbox_d10)
	mov word [tempvar+4], ourtext(txtetoolbox_d12) 
 	mov word [tempvar+6], ourtext(txtetoolbox_d14)
	mov word [tempvar+8], ourtext(txtetoolbox_d16)
	mov word [tempvar+10], ourtext(txtetoolbox_d18)
	mov word [tempvar+12], ourtext(txtetoolbox_d20) 
 	mov word [tempvar+14], 0xFFFF
	xor ebx, ebx
	jmp dword [GenerateDropDownMenu]
.nodepotadjust:
#endif
	cmp cl, 6
	jnz .noresetdefaultsizes
	pusha
	call ResetDefaultWindowSizes
	popa
	jmp short .switch
.noresetdefaultsizes:
	cmp cl, 8
	movzx dx, byte [egui_depotalltrash]
	jnz .nodepotalltrash
	mov word [tempvar], ourtext(txtetoolbox_off) 
 	mov word [tempvar+2], ourtext(txtetoolbox_on)
 	mov word [tempvar+4], 0xFFFF
	xor ebx, ebx
	jmp dword [GenerateDropDownMenu]
.nodepotalltrash:
	cmp cl, 11
	jne .nosaveasdefault
	call saveenhanceguisettingstofile
	jmp short .switch
.nosaveasdefault:
	cmp cl, 9
	jne .nosavetosavegame
	pusha
	mov esi, [enhanceguioptions_savedata]
	call saveenhanceguisettingstobuffer
	popa
	jmp short .switch
.nosavetosavegame:
	cmp cl, 10
	jne .nosavegameusedefault
	pusha
	mov esi, [enhanceguioptions_savedata]
	call initenhanceguisettingsbuffer
	call loadenhanceguisettingsfromfile
	call enhancegui_settingschanged
	popa
	jmp short .switch
.nosavegameusedefault:
	ret

.switch:
	movzx ecx, cl
	bts dword [esi+0x1A], ecx //window.activebuttons
	or byte [esi+0x04], 7
	mov al,[esi]
	mov bx,[esi+6]
	or al, 80h
	mov ah, cl
	call dword [invalidatehandle]
	ret
;endp win_etoolbox_clickhandler


win_etoolbox_winhandler:
	mov bx, cx
 	mov esi, edi
 	cmp dl, cWinEventRedraw
 	jz win_etoolbox_redraw
 	cmp dl, cWinEventClick
 	jz win_etoolbox_clickhandler
 	cmp dl, cWinEventTimer
 	jz win_etoolbox_timer
	cmp dl, cWinEventDropDownItemSelect
	jz win_etoolbox_dropdown
.end:
	ret	
;endp win_etoolbox_winhandler

win_etoolbox_redraw:
	call dword [DrawWindowElements]
	ret
;endp win_etoolbox_redraw

win_etoolbox_timer:
	mov ah, 6
	btr dword [esi+0x1A], 6 //window.activebuttons
	jb .switch
	mov ah, 9
	btr dword [esi+0x1A], 9 //window.activebuttons
	jb .switch
	mov ah, 10
	btr dword [esi+0x1A], 10 //window.activebuttons
	jb .switch
	mov ah, 11
	btr dword [esi+0x1A], 11 //window.activebuttons
	jb .switch
	ret

.switch:
	mov al,[esi]
	mov bx,[esi+6]
	or al, 80h
	call dword [invalidatehandle]
	ret
;endp win_etoolbox_timer

win_etoolbox_dropdown:
	cmp cl, 4
	jnz .nodropdown_stationsign
	mov byte [egui_stationsignstyle], al
	call redrawscreen
	ret
.nodropdown_stationsign:
/*	cmp cl, 6
	jnz .nodropdown_depotsize
	shl al, 1
	add al, 8
	mov byte [egui_depotsize], al
	call updateraildepotsize
	call redrawscreen
	ret*/
.nodropdown_depotsize:
	cmp cl, 8
	jnz .nodropdown_depotalltrash
	mov byte [egui_depotalltrash], al
	call updatedepottrash
	ret
.nodropdown_depotalltrash:
	ret
;endp win_etoolbox_dropdown



// -------------------------------------------
// Functions that need to know when settings changed
// -------------------------------------------

global enhancegui_settingschanged
enhancegui_settingschanged:
//	call updateraildepotsize
	call updatedepottrash
	ret
;endp enhancegui_settingschanged

// -------------------------------------------
// Enhancegui Settings Load/Save Helper Functions
// -------------------------------------------


loadenhanceguisettingsfrombuffer:
	cmp dword [esi], 'EG01'
	jne .invalid
	mov ax, [esi+4]
	mov byte [egui_stationsignstyle], al
	mov byte [egui_depotalltrash], ah
	mov ax, [esi+6]
//	mov byte [egui_depotsize], al // Byte no longer used
	cmp byte [depotscalefactor], 0
	jne .invalid
	mov byte [depotscalefactor], al // replacing with the scale factor
.invalid:
	ret
;endp	loadenhanceguisettingsfrombuffer		

saveenhanceguisettingstobuffer:
	mov dword [esi], 'EG01'
	mov al, byte [egui_stationsignstyle]
	mov ah, byte [egui_depotalltrash]
	mov [esi+4], ax
//	mov al, byte [egui_depotsize] // Byte no longer used
	mov al, byte [depotscalefactor] // Replacing with scale factor
	mov ah, 0
	mov [esi+6], ax 
	mov dword [esi+8], 0
	ret
;endp saveenhanceguisettingstobuffer		

initenhanceguisettingsbuffer:	
	// simple make a invalid entry :)
	mov edi, 0
	mov [esi], edi
	mov [esi+4], edi
	mov [esi+8], edi
	ret
;endp initenhanceguisettingsbuffer	

// Savegame specific data read and init 
// (mostly redirect to right functions)

global enhancegui_newgame
enhancegui_newgame:
	cmp dword [enhanceguioptions_savedata],0
	je .noenhancegui
	call enhancegui_insave_setdefaultuse
	call loadenhanceguisettingsfromfile
	call enhancegui_settingschanged
.noenhancegui:
	ret
;endp enhancegui_newgame

global enhancegui_insave_setdefaultuse
enhancegui_insave_setdefaultuse:
	mov esi, [enhanceguioptions_savedata]
	call initenhanceguisettingsbuffer
	ret
;endp enhancegui_insave_setdefaultuse

global enhancegui_insave_init
enhancegui_insave_init:
	call loadenhanceguisettingsfromfile // reset to file defaul
	mov esi, [enhanceguioptions_savedata]
	call loadenhanceguisettingsfrombuffer
	call enhancegui_settingschanged
	ret
;endp enhancegui_insave_init

// Dat File specific load/save 

global loadenhanceguisettingsfromfile
loadenhanceguisettingsfromfile:
	pusha
	mov edx, enhanceguifile
	mov ah,3dh		//file open
	mov al,0		//open for read
	CALLINT21
	jc .done
	mov [enhanceguifilehandle],ax
	mov bx, ax
	xor ecx,ecx
	mov cl, 12		// ECX=12 = number of bytes to read
	mov edx, [enhanceguioptions_defaultdata]
	mov ah,3fh
	CALLINT21
	jc .readfail
	
	mov cl, 40
	mov edx, [windowsizesbufferptr]
	mov ah, 3fh
	CALLINT21
	jc .read2fail
	cmp ax, 40
	jne .read2fail
	call LoadWindowSizesFinish

.read2fail:
	jmp .goodread1
.readfail:
	mov esi, [enhanceguioptions_defaultdata]
	call initenhanceguisettingsbuffer

.goodread1:
	mov esi, [enhanceguioptions_defaultdata]
	call loadenhanceguisettingsfrombuffer

	mov bx, [enhanceguifilehandle]
	mov ah,3eh
	CALLINT21
	mov word [enhanceguifilehandle], 0
.done:
	popa
	ret
;endp loadenhanceguisettings


saveenhanceguisettingstofile:
	pusha
	mov edx, enhanceguifile
	xor ecx,ecx
	mov ah,3ch		//create file
	mov al,0		
	CALLINT21
	jc .done
	mov [enhanceguifilehandle],ax

	mov esi, [enhanceguioptions_defaultdata]
	call saveenhanceguisettingstobuffer

	mov bx, [enhanceguifilehandle]
	xor ecx,ecx
	mov cl, 12		// ECX=12 = number of bytes to write
	mov edx, esi
	mov ah,40h
	CALLINT21
	jc .error_exit

	
	call SaveWindowSizesPrepare
	mov cl, 40
	mov edx, [windowsizesbufferptr]
	mov ah, 40h
	CALLINT21
	jc .error_exit
	
.error_exit:
	mov bx, [enhanceguifilehandle]
	mov ah,3eh
	CALLINT21
	mov word [enhanceguifilehandle], 0
.done:
	popa
	ret
;endp saveenhanceguisettings

// -------------------------------------------
// Rail Depot Size Update
// -------------------------------------------
var egui_depotsize, db 10
#if 0	// Rail depot size is now handled by winsize.asm
updateraildepotsize:
	pusha
	// make the rail depot window bigger, and move the trashbutton...
	mov bh, [egui_depotsize]
	mov edi, [windowRailDepotSize]	// edi points to window size  height & width
	mov esi, [edi+15h]			// now esi at window elements

.normalnewdepotsize:
	mov al, 30
	mul bh
	cwde

	// 15 + 30 * vehicles + 10 + 24 Trashcan
	add eax, 14
	mov word [esi+1Ch], ax	// list x
	
	add eax, 1
	mov word [esi+32h], ax	// scroll x1
	add ax, 10
	mov word [esi+34h], ax	// scroll x2
	
	add ax, 1
	mov word [esi+26h], ax	// trashcan x1
	add ax, 22 
	mov word [esi+28h], ax	// trashcan x2

	mov word [esi+4Ch],ax	// button location x2
	mov word [esi+10h],ax	// captionbar x

	add ax, 1
	add eax, (110 << 16)
	mov dword [edi], eax	// overwrite the window width (and the height)

	testmultiflags mammothtrains
	jnz .havemammothtrains
	
	mov edi, [windowRailDepotDrawWithEngine]
	mov byte [edi],  bh
.havemammothtrains:

	mov [trainvehsperdepotrow],bh

	mov edi, [windowRailDepotDrawWithNoEngine]
	dec bh
	mov byte [edi], bh

	// Find all rail depot window and change the size
	mov esi, [windowstack]

.nextloop:
	cmp esi, [windowstacktop]
	jnb .donedepotwindows
	cmp byte [esi], 12h	// window.type = depot
	jnz .nextwindow
	//cmp [esi+0x6], 		 //window id
	cmp word [esi+0x10], 80h 
	// if the operation offset = 80 it's a train depot
	// 88h would be a road depot as example
	jnz .nextwindow
	
	// we have found a rail depot
	mov [esi+0x0C], eax	// overwrite window width and height
	
.nextwindow:
	add esi, 0+window_size
	jmp short .nextloop
.donedepotwindows:
	popa
	// 	call redrawscreen
	// not a good idea while init
	ret
;endp updateraildepotsize
#endif

// -------------------------------------------
// Depot Trash Update
// -------------------------------------------
var egui_depotalltrash, db 0
updatedepottrash:
	mov edi, [windowRailDepotDropHandle]
	call updatedepottrash_switch
	mov edi, [windowDepotDropHandle1]
	call updatedepottrash_switch
	mov edi, [windowDepotDropHandle2]
	call updatedepottrash_switch
	mov edi, [windowDepotDropHandle3]
	call updatedepottrash_switch
	ret
;endp updatedepottrash

updatedepottrash_switch:
	cmp byte [egui_depotalltrash], 1
	jz short .oldstyle
	mov byte [edi+2h], 0x03 // now CMP CL,3
	mov byte [edi+3h], 0x74 // now jz (totrash)
	ret
.oldstyle:
	mov byte [edi+2h], 0x02 // now CMP CL,2
	mov byte [edi+3h], 0x75 // now jnz (totrash)
	ret
;endp updatedepottrash_switchon


// -------------------------------------------
// Transparent Station Sign Handler
// -------------------------------------------
var egui_stationsignstyle, db 0
global addstationsigntoeffects
addstationsigntoeffects:
	cmp byte [egui_stationsignstyle], 1
	jnz short .newstyle
	mov [ebx+16h], ax
	mov [ebx+18h], dx
	ret
.newstyle:
	mov word [ebx+16h], 0
	mov word [ebx+18h], 0
	mov ax,[ebx]
	sub ax,0x305c
	shl ax,4
 	add ax, statictext(signstationcol1)
	add ax, dx
	mov word [ebx], ax
	ret
;endp addstationsigntoeffects


// -------------------------------------------
// New Text Color Handler (0x99 + old/newcolor)
// -------------------------------------------
// provides via code 0x99 oldcolors 
// & companycolors

// New Text Color Command...
global specialcolortextbytes
specialcolortextbytes:
	cmp al, 0x9A
	jnb short .normaltext
	cmp al, 0x88
	jnb short .colorcode
.normaltext:
	clc
	ret	

.colorcode:
	cmp al, 0x99
	jne .simplecolor	// seems we use ttd internal color codes
	lodsb			// get the next byte in text for special colors
	
.simplecolor:
	stc
	ret

;endp specialcolortextbytes


// New color table including company colors

var textcolortablewithcompany
#if WINTTDX
	incbin "embedded/tcc_w.dat"
#else
	incbin "embedded/tcc_d.dat"
#endif


// Sticky windows
global closeallwindows
closeallwindows:
	cmp al, 24h	// cWinTypePullDownMenu
	jz .return
	cmp al, 27h	// cWinTypeToolTip
	jz .return
	push byte CTRL_ANY | CTRL_MP
	call ctrlkeystate
	jz .closeall
	mov bx, [esi+window.flags]	//XXX: isn't there a better way to have zf set if a bit is set?
	not bx
	test bx, 0x4000
.return:
	ret
.closeall:
	test al, 0xff // clear zf
	ret

// called to find closeable window
//
// in:	ESI->end of window stack
// out:	ESI->window to replace
// safe:---
global replacewindow
proc replacewindow
	local windowstackend,closestickywnd

	_enter

	mov [%$windowstackend],esi
	mov byte [%$closestickywnd],0

.again:
	mov esi,[windowstack]

.next:
	cmp byte [esi+window.type],0	// main view
	je .keep
	cmp byte [esi+window.type],1	// main tool bar
	je .keep
	cmp byte [esi+window.type],2	// main status bar
	je .keep
	cmp byte [esi+window.type],4	// news message
	je .keep

	test byte [%$closestickywnd],1	// second round, close stickies too?
	jnz .done

	test byte [esi+window.flags+1],0x40
	jz .done

.keep:
	add esi,0+window_size
	cmp esi,[%$windowstackend]
	jb .next

	mov byte [%$closestickywnd],1	// didn't find a non-sticky
	jmp .again

.done:
	mov byte [%$closestickywnd],0
	_ret
endproc

uvard olddrawtitlebar,1,s
uvard temp_drawwindow_active_ptr,1,s

global drawtitlebar
drawtitlebar:
//dirty hack to make all windows sticky-able, we patch the code to draw a title-bar, to draw the titlebar 11 pixels smaller,
//and draw a button next to it.

	call WindowCanSticky
	jnc .havesticky
	jmp [olddrawtitlebar]

.havesticky:
	push dword [ebp]
	push dword [ebp+4]
	push dword [ebp+8]
	push esi
	mov esi, [winelemdrawptrs+4*cWinElemDummyBox]
	mov byte [esi], 0xC3	// ret
	pop esi
	
	push eax

	sub word [ebp+windowbox.x2], 11
	extcall WindowCanShade
	pushf
	jc .drawtitle
	sub word [ebp+windowbox.x2], 11
.drawtitle:
	call [olddrawtitlebar]

	popf		// call WindowCanShade
	jc .noshade

	mov ax, statictext(shadebutton_unshaded)
	mov ecx, 4*(cWinElemTextBox-cWinElemSpriteBox)

	extern ShadedWinHandler
	cmp dword [esi+window.function], ShadedWinHandler
	jne .notshaded
	dec eax
	bts eax,16

.notshaded:
	call .dodraw

.noshade:
	xor eax, eax
	inc eax

	test byte [esi+window.flags+1], 0x40
	jz .notsticky1
	inc eax
	bts eax,16
.notsticky1:

	xor ecx, ecx
	cmp [numguisprites], ax
	jbe .notenough
	add ax, [guispritebase]
	jmp short .drawstick

.notenough:
	mov ax, statictext(stickybutton)
	mov ecx, 4*(cWinElemTextBox-cWinElemSpriteBox)
.drawstick:
	call .dodraw	

	pop eax

	push esi
	mov esi, [winelemdrawptrs+4*cWinElemDummyBox]
	mov byte [esi], 0x83
	pop esi

	pop dword [ebp+8]
	pop dword [ebp+4]
	pop dword [ebp]
	jmp [winelemdrawptrs+4*cWinElemDummyBox]


//  In:	ax: sprite number or text ID
//	eax:16 Set if button is to be depressed
//	ebp->element to the immediate left of this button
//	ecx: offset to pointer to element function
.dodraw:
	mov [ebp+windowbox.extra], ax
	add ecx, winelemdrawptrs+4*cWinElemSpriteBox

	mov ax, [ebp+windowbox.x2]
	inc ax
	mov [ebp+windowbox.x1], ax
	add ax, 10
	mov [ebp+windowbox.x2], ax

	mov ebx, [temp_drawwindow_active_ptr]
	rcr dword [ebx],1
	bt eax, 16
	rcl dword [ebx],1

	jmp [ecx]


//IN: ESI=window
//OUT: cf set if this window can't be stickyfied
exported WindowCanSticky
	cmp byte [esi+window.type], 15h
	jz .nosticky
	cmp byte [esi+window.type], 16h
	jz .nosticky
	cmp byte [esi+window.type], 17h
	jz .nosticky
	cmp byte [esi+window.type], 20h
	jz .nosticky
	cmp byte [esi+window.type], 21h
	jz .nosticky
	cmp byte [esi+window.type], 22h
	jz .nosticky
	clc
	ret

.nosticky:
	stc
	ret

global TitleBarClicked
TitleBarClicked:
	call WindowCanSticky
	jc .return

	mov dx, [ebp+windowbox.x2]
	add dx, [esi+window.x]
	sub dx, 11
	cmp ax, dx
	jbe .notstick
	mov cx, -1
	cmp byte [rmbclicked], 0
	jnz .rightclicked
	
	btc word [esi+window.flags], 14
	call [RefreshWindowArea]	//TODO: only redraw the title bar
	ret
	
.rightclicked:
	mov ax, ourtext(stickytooltip)
.createtip:
	jmp [CreateTooltip]

.notstick:
	call WindowCanShade
	jc .return
	sub dx, 11
	cmp ax, dx
	jbe .return
	mov cx, -1
	cmp byte [rmbclicked], 0
	extern ShadeWindowHandler.toggleshade
	je ShadeWindowHandler.toggleshade

.rightclicked2:
	mov ax, ourtext(winshadetooltip)
	jmp short .createtip

.return:
	ret

//code to make the map window fixable to the current location

global mapwindowclicked
mapwindowclicked:
	jns .noskipcaller
	pop eax
.return:
	ret

.noskipcaller:
	cmp cl, 15
	jne .return
	
	push eax
	push esi
	mov esi, 0
	mov eax, 13h
	call [generatesoundeffect]
	pop esi
	pop eax

	btc dword [esi+window.activebuttons], 15
	jmp [RefreshWindowArea]


//Dragable bulldozer
uvard RailToolMouseDragDirectionPtr,1
uvard RoadToolMouseDragDirectionPtr,1
global DemolishTile
DemolishTile:
	and al, 0xF0
	and cl, 0xF0
	mov [dragtoolstartx], ax
	mov [dragtoolstarty], cx
	mov [dragtoolendx], ax
	mov [dragtoolendy], cx
	mov byte [curmousetooltype], 3
	bts word [uiflags], 13
	push edi
	mov edi, [RailToolMouseDragDirectionPtr]
	mov byte [edi], 3
	mov edi, [RoadToolMouseDragDirectionPtr]
	mov byte [edi], 3
	pop edi
	mov byte [curdiagtool], 0
	ret

global RailConstrDragUITick
RailConstrDragUITick:
	jz near .draguitick
	cmp dl, cWinEventMouseDragRelease
	je .dragrelease
	ret
.dragrelease:
	push edi
	mov edi, [RailToolMouseDragDirectionPtr]
	cmp byte [edi], 3
	je .releasebdozer
	pop edi
	ret
	
.releasebdozer:
	pop edi
	pop ebx

	cmp byte [curdiagtool], 0
	jnz near ReleaseNSorEWRail

	pusha
	
	mov ax, [dragtoolendx]
	cmp ax, -1
	je .error
	mov bx, [dragtoolstartx]
	mov cx, [dragtoolendy]
	mov dx, [dragtoolstarty]
	shl edx, 16
	mov dx, bx
	mov bl, 1
	dopatchaction cleararea
	cmp ebx, 80000000h
	je .error
	push eax
	push esi
	mov esi, -1
	push ebx
	mov bx, ax
	mov eax, 10h
	call [generatesoundeffect]
	pop ebx
	pop esi
	pop eax
.error:
	popa
	push esi
	mov ebx, -1
	mov esi, AnimDynamiteCursorSprites
	mov ax, 1 + (3 << 8)
	xor dx, dx
	call [setmousetool]
	pop esi
	bts dword [esi+window.activebuttons], 6
	mov word [selectedtool], 0x0E
	ret
	
.draguitick:
	sub dword [esp], 431
	push edi
	mov edi, [RailToolMouseDragDirectionPtr]
	cmp byte [edi], 3
	je .noret
	pop edi
	ret
.noret:
	pop edi
	pop ebx
	bt dword [esi+window.activebuttons], 2
	jc near DragNSRailUITick
	bt dword [esi+window.activebuttons], 4
	jc near DragEWRailUITick
	push esi
	call [ScreenToLandscapeCoords]
	pop esi
	cmp ax, -1
	je .havecoord
	and ax, 0xFFF0
	and cx, 0xFFF0
.havecoord:
	mov [dragtoolendx], ax
	mov [dragtoolendy], cx
	ret

global RoadConstrDragUITick
RoadConstrDragUITick:
	jz near .draguitick
	cmp dl, cWinEventMouseDragRelease
	je .dragrelease
	ret
.dragrelease:
	push edi
	mov edi, [RoadToolMouseDragDirectionPtr]
	cmp byte [edi], 3
	je .releasebdozer
	pop edi
	ret
	
.releasebdozer:
	pop edi
	pop ebx
	pusha
	
	mov ax, [dragtoolendx]
	cmp ax, -1
	je .error
	mov bx, [dragtoolstartx]
	mov cx, [dragtoolendy]
	mov dx, [dragtoolstarty]
	shl edx, 16
	mov dx, bx
	mov bl, 1
	dopatchaction cleararea
	cmp ebx, 80000000h
	je .error
	push eax
	push esi
	mov esi, -1
	push ebx
	mov bx, ax
	mov eax, 10h
	call [generatesoundeffect]
	pop ebx
	pop esi
	pop eax
.error:
	popa
	push esi
	mov ebx, -1
	mov al, 1
	mov ah, [esi+window.type]
	mov esi, AnimDynamiteCursorSprites
	xor dx, dx
	call [setmousetool]
	pop esi
	bts dword [esi+window.activebuttons], 4
	mov word [selectedtool], 8
	ret
	
.draguitick:
	sub dword [esp], 466
	push edi
	mov edi, [RoadToolMouseDragDirectionPtr]
	cmp byte [edi], 3
	je .noret
	pop edi
	ret
.noret:
	pop edi
	pop ebx
	push esi
	call [ScreenToLandscapeCoords]
	pop esi
	cmp ax, -1
	je .havecoord
	and ax, 0xFFF0
	and cx, 0xFFF0
.havecoord:
	mov [dragtoolendx], ax
	mov [dragtoolendy], cx
	ret

global AirportConstrDragUITick
AirportConstrDragUITick:
	jnz .noreturn
	sub dword [esp], 150
	ret
.noreturn:
	cmp dl, cWinEventMouseDragUITick
	jz near .draguitick
	cmp dl, cWinEventMouseDragRelease
	je .dragrelease
	ret
.dragrelease:
	pusha
	
	mov ax, [dragtoolendx]
	cmp ax, -1
	je .error
	mov bx, [dragtoolstartx]
	mov cx, [dragtoolendy]
	mov dx, [dragtoolstarty]
	shl edx, 16
	mov dx, bx
	mov bl, 1
	dopatchaction cleararea
	cmp ebx, 80000000h
	je .error
	push eax
	push esi
	mov esi, -1
	push ebx
	mov bx, ax
	mov eax, 10h
	call [generatesoundeffect]
	pop ebx
	pop esi
	pop eax
.error:
	popa
	push esi
	mov ebx, -1
	mov esi, AnimDynamiteCursorSprites
	mov ax, 1 + (3 << 8)
	xor dx, dx
	call [setmousetool]
	pop esi
	bts dword [esi+window.activebuttons], 3
	mov word [selectedtool], 2
	ret
	
.draguitick:
	push esi
	call [ScreenToLandscapeCoords]
	pop esi
	cmp ax, -1
	je .havecoord
	and ax, 0xFFF0
	and cx, 0xFFF0
.havecoord:
	mov [dragtoolendx], ax
	mov [dragtoolendy], cx
	ret

global LandscapeGenDragUITick
LandscapeGenDragUITick:
	jnz .noreturn
	sub dword [esp], 339
	ret
.noreturn:
	cmp dl, cWinEventMouseDragUITick
	jz near .draguitick
	cmp dl, cWinEventMouseDragRelease
	je .dragrelease
	ret
.dragrelease:
	pusha
	
	mov ax, [dragtoolendx]
	cmp ax, -1
	je .error
	mov bx, [dragtoolstartx]
	mov cx, [dragtoolendy]
	mov dx, [dragtoolstarty]
	shl edx, 16
	mov dx, bx
	mov bl, 1
	dopatchaction cleararea
	cmp ebx, 80000000h
	je .error
	push eax
	push esi
	mov esi, -1
	push ebx
	mov bx, ax
	mov eax, 10h
	call [generatesoundeffect]
	pop ebx
	pop esi
	pop eax
.error:
	popa
	push esi
	mov ebx, -1
	mov esi, AnimDynamiteCursorSprites
	mov ax, 1 + (38h << 8)
	xor dx, dx
	call [setmousetool]
	pop esi
	bts dword [esi+window.activebuttons], 5
	mov word [selectedtool], 2
	ret
	
.draguitick:
	push esi
	call [ScreenToLandscapeCoords]
	pop esi
	cmp ax, -1
	je .havecoord
	and ax, 0xFFF0
	and cx, 0xFFF0
.havecoord:
	mov [dragtoolendx], ax
	mov [dragtoolendy], cx
	ret

var AnimDynamiteCursorSprites
	dw 704, 29
	dw 705, 29
	dw 706, 29
	dw 707, 29
	dw -1

uvarb TempActionFlags
uvard TempActionCost
uvard TempCAActionErrorCount
global cleararea
cleararea:
	//bl|=0x10 for no explosion animation
	mov word [operrormsg1], 0x00B5
	mov [TempActionFlags], bl
	and dword [TempActionCost], 0
	or byte [TempActionFlags], 80h
	and DWORD [TempCAActionErrorCount], 0
	pusha
	and ax, 0xFFF0
	and cx, 0xFFF0
	mov bx, dx
	shr edx, 16
	and bx, 0xFFF0
	and dx, 0xFFF0
	
	cmp ax, bx
	jna .noswapx
	xchg ax, bx
.noswapx:
	cmp cx, dx
	jna .noswapy
	xchg cx, dx
.noswapy:

.loopy:
	push ax
.loopx:
	push bx
	push dx
	push ax
	push cx
	
	movzx ebx, BYTE [TempActionFlags]
	and bl, ~1
	mov esi, 0
	call [actionhandler]
	cmp ebx, 80000000h
	je .ignoreerror1

	and byte [TempActionFlags], 7Fh

	add [TempActionCost], ebx
	test byte [TempActionFlags], 1
	jz .ignoreerror
	
	movzx ebx, BYTE [TempActionFlags]
	mov esi, 0
	
	mov ax, [esp+2]
	mov cx, [esp]
	push DWORD .ignoreerror
	jmp [actionhandler]

.ignoreerror1:
	inc DWORD [TempCAActionErrorCount]
.ignoreerror:
	pop cx
	pop ax
	pop dx
	pop bx
	add ax, 10h
	cmp ax, bx
	jbe .loopx

	pop ax
	add cx, 10h
	cmp cx, dx
	jbe .loopy

	popa

	
	and ax, 0xFFF0
	and cx, 0xFFF0
	push ax
	push cx
	mov bx, dx
	shr edx, 16
	and bx, 0xFFF0
	and dx, 0xFFF0

	test byte [TempActionFlags], 1
	jz .haveexplosion
	test byte [TempActionFlags], 0x10
	jnz .haveexplosion

	cmp ax, bx
	jne .largeexplosion
	cmp cx, dx
	jne .largeexplosion
	call CreateSmallExplosion
	jmp .haveexplosion

.largeexplosion:
	call CreateLargeExplosion
	push eax
	mov ax, bx
	call CreateLargeExplosion
	mov cx, dx
	call CreateLargeExplosion
	pop eax
	call CreateLargeExplosion
.haveexplosion:

	mov ebx, 80000000h
	test byte [TempActionFlags], 80h
	jnz .error
	mov ebx, [TempActionCost]
.error:
	pop cx
	pop ax
	ret

CreateSmallExplosion:
	mov di, 0x0E
	jmp CreateCenteredPseudoVehicle
	
CreateLargeExplosion:
	mov di, 0x0A
CreateCenteredPseudoVehicle:
	push eax
	push ebx
	push ecx
	push edx
	add ax, 8
	add cx, 8
	call [getgroundaltitude]
	add dl, 2
	mov ebp, [ophandler+0x14*8]
	mov ebx, 4
	call [ebp+4]
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret

//Dragable N-S and E-W rails
uvarb diagonalflags	// bit 0: set if dragging NS/EW
			// bit 1: clear for NS, set for EW
			// bit 2: indicates if the second row of tiles is to the left/top or right/bottom
uvarb curdiagtool	// 1 == NS, 2 == EW
uvarb curdiagstartpiece
uvard railbuttons
// in: AX,CX,DL = tile X&Y&Z coordinates of north corner of current tile
// out: skip callers caller if this tile shouldn't be marked due to a diagonal selection
global CheckDiagonalSelection
CheckDiagonalSelection:
	test byte [diagonalflags], 1
	jnz .noreturn
	ret
.noreturn:
	bt word [uiflags], 13
	jnc .noskip
	push dx
	mov bx, [dragtoolstartx]
	sub bx, ax
	mov dx, [dragtoolstarty]
	sub dx, cx
	test byte [diagonalflags], 2
	jz .northsouth
	neg dx
.northsouth:
	sub bx, dx
	pop dx
	or bx, bx
	je .noskip
	test byte [diagonalflags], 4
	jz .otherside
	cmp bx, 16
	je .noskip
	jmp .skip
.otherside:
	cmp bx, -16
	je .noskip
.skip:
	pop ebx
	pop ebx
.noskip:
	ret

global RailNSPieceToolClick
RailNSPieceToolClick:
	and al, 0xF0
	and cl, 0xF0
	mov [dragtoolstartx], ax
	mov [dragtoolstarty], cx
	mov [dragtoolendx], ax
	mov [dragtoolendy], cx
	mov byte [curmousetooltype], 3
	bts word [uiflags], 13
	push edi
	mov edi, [RailToolMouseDragDirectionPtr]
	mov byte [edi], 3
	pop edi
	mov byte [diagonalflags], 1
	mov byte [curdiagtool], 1
	mov eax, [esi+window.activebuttons]
	mov dword [railbuttons], eax

	mov bx, [mousetoolclicklocfinex]
	mov byte [curdiagstartpiece], 4
	cmp bl, bh
	ja .west
	mov byte [curdiagstartpiece], 5
.west:
	ret

global RailEWPieceToolClick
RailEWPieceToolClick:
	and al, 0xF0
	and cl, 0xF0
	mov [dragtoolstartx], ax
	mov [dragtoolstarty], cx
	mov [dragtoolendx], ax
	mov [dragtoolendy], cx
	mov byte [curmousetooltype], 3
	bts word [uiflags], 13
	push edi
	mov edi, [RailToolMouseDragDirectionPtr]
	mov byte [edi], 3
	pop edi
	mov byte [diagonalflags], 3
	mov byte [curdiagtool], 2
	mov eax, [esi+window.activebuttons]
	mov dword [railbuttons], eax

	mov bx, [mousetoolclicklocfinex]
	add bl, bh
	mov byte [curdiagstartpiece], 2
	cmp bl, 0x0F
	jbe .north
	mov byte [curdiagstartpiece], 3
.north:
	ret

global RailConstrOrigMouseToolClose
RailConstrOrigMouseToolClose:
	mov byte [diagonalflags], 0
	mov cl, 0x1B
	call [FindWindow]
	ret

global builddiagtrackspan
builddiagtrackspan:
	push ax
	push cx
	
	mov dword [.totalcost], 0
	movzx esi, di
	mov dword [.endposx], edx

	// some ugly code to fix problems with building 2-piece rails
	cmp cx, [.endposy]
	jne .noproblem
	mov dx, ax
	sub dx, [.endposx]
	test si, 4
	jz .otherside
	cmp dx, -10h
	je .noswap
	or si, 8
	jmp .noswap
.otherside:
	cmp dx, 10h
	je .noswap
	or si, 8
	jmp .noswap

.noproblem:
	cmp cx,[.endposy]
	jbe .noswap
	or si, 8
.noswap:
	mov edx, edi
	shr edx, 16
	and ax, 0xFFF0
	and cx, 0xFFF0
	
.loop:
	push esi
	and esi, 7
	test bh, 1
	jz .build
	add esi, 8
.build:
	shl esi, 16
	or esi, 8
	push ebx
	push eax
	push ecx
	push edx
	call [actionhandler]
	cmp ebx, 0x80000000
	jne .nofail
	cmp word [operrormsg2], 0x1007
	je .nofail2
	jmp .fail
.nofail:
	add [.totalcost], ebx
.nofail2:
	pop edx
	pop ecx
	pop eax
	pop ebx
	pop esi
	cmp ax, [.endposx]
	jne .notdone
	cmp cx, [.endposy]
	je .done
.notdone:
	add ax, [.dx + esi*2]
	add cx, [.dy + esi*2]
	test si, 6
	jz .nodiag
	xor si, 1
.nodiag:
	jmp .loop

.fail:
	pop edx
	pop ecx
	pop eax
	pop ebx
	pop esi
.done:
	
	mov ebx, [.totalcost]
	cmp ebx, 0
	jne .havecost
	mov ebx, 0x80000000
.havecost:

	pop cx
	pop ax
	ret

	align 4
.endposx: dw 0
.endposy: dw 0
.totalcost: dd 0
.dx:
	dw -16,   0, -16,  0,  16,   0,   0,0
	dw  16,   0,   0, 16,   0, -16
.dy:
	dw   0,  16,   0, 16,   0,  16,   0,0
	dw   0, -16, -16,  0, -16,   0

global resetmarkedtiles
resetmarkedtiles:
	pusha
	call [RefreshLandscapeHighlights]
	popa
	mov word [highlightareainnerxsize], 10h
	ret
