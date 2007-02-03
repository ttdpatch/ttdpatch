
#include <std.inc>
#include <flags.inc>
#include <misc.inc>
#include <textdef.inc>
#include <human.inc>
#include <window.inc>
#include <bitvars.inc>

extern CheckDiagonalSelection,CreateWindow,DestroyWindow
extern DrawPlannedStationAcceptsList,DrawStationImageInSelWindow
extern DrawWindowElements,FindWindow,FindWindowData,GenerateDropDownMenu
extern RefreshWindowArea,ScreenToLandscapeCoords,WindowClicked
extern WindowTitleBarClicked,actionhandler,actionnewstations_actionnum
extern addgroundsprite,addsprite,buildsignal_actionnum,ctrlkeystate
extern currscreenupdateblock,curselclass,curselstation,curtooltracktypeptr
extern dfree,disallowedlengths,disallowedplatforms,dmalloc,drawspritefn
extern drawtextfn,drawtextlen,findstationforclass,generatesoundeffect
extern getgroundaltitude,gettileinfo,guispritebase,invalidatehandle
extern invalidatetile,locationtoxy,locomotionguibits,makestationclassdropdown
extern makestationseldropdown,numsiggraphics,patchflags,pbssettings
extern presignalspritebase,semaphoredate,setmousecursor,setmousetool
extern signaloffsets,signalsprites,stationdropdownnums,unimaglevmode
extern CheckAirportTile

#include "railgui.ah"

var RailDirSprites
	dw 1016, 1013, 1015, 1014
	dw 1012, 1011, 1012, 1011
	dw 1014, 1016, 1013, 1015
var RailDirRailPiece
	db 4, 2, 5, 3
	db 0, 1, 0, 1
	db 3, 4, 2, 5
var RailDirMouseSprites
	dw 1263, 1265, 1263, 1265
	dw 1264, 1266, 1264, 1266
	dw 1265, 1263, 1265, 1263

var RailNextPieces
	db 1, 2, -1
	db 0, 1, 2
	db -1, 0, 1
var RailNextDirs
	db 3, 0, 1, 2
	db 0, 1, 2, 3
	db 1, 2, 3, 0
var DirToXYOffsets
	dw -10h, 0
	dw 0, 10h
	dw 10h, 0
	dw 0, -10h

var RailRemoveMasks
	db 100101b, 101010b, 011001b, 010110b
var AfterRemoveDirs
	db 0, -1, 1, -1, -1, 3
	db -1, 1, -1, 0, -1, 2
	db 2, -1, -1, 3, 1, -1
	db -1, 3, 2, -1, 0, -1

%define RED(c) c | 0x3048000
var RailTileSprites
	dd       0,       8,      16,      25,      34,      42		// 0000
	dd       5,      13,  RED(22), RED(31),     35,      42		// 0001
	dd       5,      10,      16,      26,  RED(38), RED(46)	// 0010
	dd       5,       9,  RED(23),     26,      35,  RED(46)	// 0011
	dd       2,      10,  RED(19), RED(28),     34,      43		// 0100
	dd       1,       9,      17,      26,      35,      43		// 0101
	dd       1,      10,  RED(20),     26,  RED(38),     43		// 0110
	dd       1,       9,      17,      26,      35,      43		// 0111
	dd       2,      13,      17,      25,  RED(40), RED(48)	// 1000
	dd       1,      13,      17,  RED(32),     35,  RED(48)	// 1001
	dd       2,       9,      17,      26,      35,      43		// 1010
	dd       1,       9,      17,      26,      35,      43		// 1011
	dd       2,       9,      17,  RED(29), RED(40),     43		// 1100
	dd       1,       9,      17,      26,      35,      43		// 1101
	dd       1,       9,      17,      26,      35,      43		// 1110
	dd      -1,      -1,      -1,      -1,      -1,      -1		// 1111
	dd      -1,      -1,      -1,      -1,      -1,      -1		//10000
	dd      -1,      -1,      -1,      -1,      -1,      -1		//10001
	dd      -1,      -1,      -1,      -1,      -1,      -1		//10010
	dd      -1,      -1,      -1,      -1,      -1,      -1		//10011
	dd      -1,      -1,      -1,      -1,      -1,      -1		//10100
	dd      -1,      -1,      -1,      -1,      -1,      -1		//10101
	dd      -1,      -1,      -1,      -1,      -1,      -1		//10110
	dd   RED(6), RED(11), RED(17), RED(27), RED(39), RED(47)	//10111
	dd      -1,      -1,      -1,      -1,      -1,      -1		//11000
	dd      -1,      -1,      -1,      -1,      -1,      -1		//11001
	dd      -1,      -1,      -1,      -1,      -1,      -1		//11010
	dd   RED(7), RED(15), RED(24), RED(33), RED(36), RED(44)	//11011
	dd      -1,      -1,      -1,      -1,      -1,      -1		//11100
	dd   RED(3), RED(14), RED(18), RED(26), RED(41), RED(49)	//11101
	dd   RED(4), RED(12), RED(21), RED(30), RED(37), RED(45)	//11110
%undef RED

uvarb CurOrigRailType
uvarb CurRailType
uvarb CurRailHasOverhead
uvarb CurRailConstrDir
uvarb CurRailPiece
uvarb CurRailButton
uvarb LastRailConstrDir
uvarb LastRailPiece

uvarb CurSignalType
uvarb CurPreSignalType,1,s
uvarb CurPbsSignalType
uvarb CurSignalIsSingle //0==double,1==single

uvarb CurRailMouseTool
%define cRailMouseToolNone 		0
%define cRailMouseToolSignals 		1
%define cRailMouseToolRemoveSignals 	2
%define cRailMouseToolBuildRail 	3
%define cRailMouseToolBuildRailCon 	4
%define cRailMouseToolBuildStation	5

uvarw CurSelectionSprites,4
uvarb CurSelectionXs,4
uvarb CurSelectionYs,4
uvarb CurSelectionXSizes,4
uvarb CurSelectionYSizes,4
uvarb CurSelectionZSizes,4
uvarb CurSelectionFlags,4	//1 = is a ground sprite; 2 = don't recolor; 4 = don't adjust height
uvarb CurSelFlags	//1 = don't draw white tile border

uvard CurRailSprites,4
uvarb CurRailXs,4
uvarb CurRailYs,4
uvarb CurRailXSizes,4
uvarb CurRailYSizes,4
uvarb CurRailZSizes,4
uvarb CurRailFlags,4	//1 = is a ground sprite; 2 = don't recolor; 4 = don't adjust height
uvarw CurRailX,1,s
uvarw CurRailY

uvarb CurSignalBits
uvard CurRailBuildCost

uvarb CurStationRotation
uvarb CurStationLength
uvarb CurStationTracks
uvarb CurStationSelClass
uvarb CurStationSelType
var CurMinStationLength, db 0
var CurMaxStationLength, db 14
var CurMinStationTracks, db 0
var CurMaxStationTracks, db 14
uvard CurDisabledStationSizes
uvarb CurCatchmentAreaHighlight

global SwapLomoGuiIcons
SwapLomoGuiIcons:
	testflags locomotiongui
	jc .active
	ret
.active:
	push ebx
	push edi
	movzx ebx, word [guispritebase]
	or bh, bh
	js .nosprites
	add bx, 70
	mov edi, RailConstrWin_railtab_Elems+((RailConstrWin_arrowleft&0xFF) * windowbox_size)
	mov word [edi+windowbox.sprite], bx
	inc bx
	add edi, windowbox_size
	mov word [edi+windowbox.sprite], bx
	inc bx
	add edi, windowbox_size
	mov word [edi+windowbox.sprite], bx
.nosprites:
	pop edi
	pop ebx
	ret

global OpenRailConstrWindow
OpenRailConstrWindow:
	pusha

	mov [CurOrigRailType], dl
	cmp dl, 1
	jb .normal
	testflags electrifiedrail
	jc .electrifiedrailway

	cmp byte [unimaglevmode], 2
	jne .normal

	mov dl, 2
	jmp .normal

.electrifiedrailway:
	test byte [unimaglevmode], 1
	jz .havemaglev

	dec dl
	jmp .normal
.havemaglev:
	cmp dl, 2
	je .normal
	dec dl
.normal:
	mov [CurRailType], dl

	mov cl, 3
	mov dx, 100h
	call [FindWindow]
	call [DestroyWindow]

	mov ecx, 3*8
	call dmalloc
	jc near .fail

	push edi
	mov eax, 100 + (100 << 16) //x, y
	mov ebx, RailConstrWin_width + (RailConstrWin_height << 16)
	mov cx, 3
	mov dx, -1
	mov ebp, addr(RailConstrWinHandler)
	call [CreateWindow]
	mov dword [esi+window.elemlistptr], RailConstrWinElems
	mov word [esi+window.id], 100h
	mov word [esi+window.selecteditem], 0
	mov dword [esi+window.activebuttons], (1 << RailConstrWin_rail)
	mov byte [CurRailConstrDir], 0
	mov byte [CurRailPiece], 1
	mov byte [CurSignalType], 0
	mov ax, [semaphoredate]
	cmp word [currentdate],ax
	jnae .semaphore
	mov byte [CurSignalType], 1
.semaphore:
	mov byte [CurPreSignalType], -1
	mov byte [CurPbsSignalType], 0
	pop edi
	mov dword [.windowptr], esi
	mov dword [esi+window.data], edi
	mov dword [edi], (1 << (RailConstrWin_arrowstraight&0xFF))
	mov dword [edi+4], (1 << (RailConstrWin_remove&0xFF)) | (1 << (RailConstrWin_pickup&0xFF))
	mov dword [edi+8], (1 << (RailConstrWin_class&0xFF)) | (1 << (RailConstrWin_type&0xFF))
	cmp byte [CurCatchmentAreaHighlight], 0
	je .nohighlight
	bts dword [edi+8], (RailConstrWin_catcharea & 0xFF)
.nohighlight:
	mov dword [edi+12], 0
	mov dword [edi+16], (1 << (RailConstrWin_doublesignal&0xFF)) | (1 << (RailConstrWin_signaltype&0xFF)) | (1 << (RailConstrWin_presignaltype&0xFF)) | (1 << (RailConstrWin_pbssignaltype&0xFF))
	mov dword [edi+20], 0
	test byte [pbssettings],PBS_MANUALPBSSIG
	jnz .noautopbs
	or dword [edi+20], (1 << (RailConstrWin_pbssignaltype&0xFF)) | (1 << (RailConstrWin_pbssignaltypedd&0xFF))
.noautopbs:
	mov dword [CurRailBuildCost], 0x80000000
	mov word [CurRailX], -1
	call CheckStationSizes

	call SelectRailTab

.fail:
	popa
	mov esi, 0xFFFFFF
ovar .windowptr, -4, $, OpenRailConstrWindow
	ret

CheckStationSizes:
	pusha
	mov edi, [esi+window.data]
	mov eax, dword [edi+12]
	and eax, ~(0xF << (RailConstrWin_tracksdec & 0xFF))
	mov cl, [CurMinStationLength]
	cmp [CurStationLength], cl
	jne .candeclen
	bts eax, (RailConstrWin_lengthdec & 0xFF)
.candeclen:
	mov cl, [CurMaxStationLength]
	cmp [CurStationLength], cl
	jne .caninclen
	bts eax, (RailConstrWin_lengthinc & 0xFF)
.caninclen:
	mov cl, [CurMinStationTracks]
	cmp [CurStationTracks], cl
	jne .candectracks
	bts eax, (RailConstrWin_tracksdec & 0xFF)
.candectracks:
	mov cl, [CurMaxStationTracks]
	cmp [CurStationTracks], cl
	jne .caninctracks
	bts eax, (RailConstrWin_tracksinc & 0xFF)
.caninctracks:

	mov [edi+12], eax
	call [RefreshWindowArea]
	call UpdateStationSelectionSize
	popa
	ret

SelectRailTab:
	cmp word [CurRailX], -1
	je .newrail
	push cx
	push esi
	mov al, 0
	mov ebx, 0
	call [setmousetool]
	pop esi
	pop cx
	mov byte [CurRailMouseTool], cRailMouseToolBuildRailCon
	ret


.newrail:
	push cx
	push esi
	mov ax, 1 + (3h << 8)
	mov dx, 100h

	movzx ebx, byte [CurRailPiece]
	shl bx, 2
	add bl, [CurRailConstrDir]
	movzx ebx, word [RailDirMouseSprites+2*ebx]
	call [setmousetool]
	mov byte [CurRailMouseTool], cRailMouseToolBuildRail
	pop esi
	pop cx
	push edi
	push ecx
	mov edi, [esi+window.data]
	and dword [edi+0], ~(7 << (RailConstrWin_arrowleft & 0xFF))
	movzx ecx, byte [CurRailPiece]
	add cx, (RailConstrWin_arrowleft & 0xFF)
	bts dword [edi+0], ecx

	and dword [edi+4], ~( (1 << (RailConstrWin_rotate & 0xFF)) | (7 << (RailConstrWin_arrowleft & 0xFF)) )
	or dword [edi+4], (1 << (RailConstrWin_remove & 0xFF)) | (1 << (RailConstrWin_pickup & 0xFF))
	pop ecx
	pop edi
	ret

RailConstrWinClick:
	call [WindowClicked]
	jns .click
.exit:
	ret
.click:
	cmp byte [rmbclicked],0
	jne .exit

	cmp cx, RailConstrWin_closebox
	jne .notdestroy
	jmp [DestroyWindow]
.notdestroy:
	cmp cx, RailConstrWin_titlebar
	jne .notitlebar
	jmp [WindowTitleBarClicked]
.notitlebar:
	cmp cx, RailConstrWin_mainpanel
	je .exit
	cmp cx, RailConstrWin_rail
	jb .exit
	cmp cx, RailConstrWin_signal
	jbe near .tabclicked
	cmp byte [CurRailMouseTool], cRailMouseToolBuildRail
	jne .nobuildrail
	cmp cx, RailConstrWin_rotate
	je near .rotaterail
	cmp cx, RailConstrWin_arrowleft
	jb .noarrow
	cmp cx, RailConstrWin_arrowright
	jna near .arrowclicked
.noarrow:
	jmp .checkedtooltype
.nobuildrail:
	cmp byte [CurRailMouseTool], cRailMouseToolBuildRailCon
	jne .checkedtooltype
	cmp cx, RailConstrWin_arrowleft
	jb .noarrow2
	cmp cx, RailConstrWin_arrowright
	jna near .arrowclicked2
	cmp cx, RailConstrWin_curpiece
	je near .buildrailpiece
	cmp cx, RailConstrWin_remove
	je near .removelastrailpiece
	cmp cx, RailConstrWin_pickup
	je near .pickuprail
.noarrow2:
.checkedtooltype:
	cmp cx, RailConstrWin_doublesignal
	jb .nosignal
	cmp cx, RailConstrWin_removesignal
	jna near .signalclicked
.nosignal:
	cmp cx, RailConstrWin_signaltypedd
	je near .signaltypedropdown
	cmp cx, RailConstrWin_presignaltypedd
	je near .presignaltypedropdown
	test byte [pbssettings],PBS_MANUALPBSSIG
	jz .nomanualpbs
	cmp cx, RailConstrWin_pbssignaltypedd
	je near .pbssignaltypedropdown
.nomanualpbs:
	cmp cx, RailConstrWin_rotatestation
	je near .rotatestation
	cmp cx, RailConstrWin_tracksdec
	jb .noincdec
	cmp cx, RailConstrWin_lengthinc
	jbe near .incdec
.noincdec:
	cmp cx, RailConstrWin_class
	jne .noclass
	inc cx
.noclass:
	cmp cx, RailConstrWin_classdd
	je near .showclassdropdown
	cmp cx, RailConstrWin_type
	jne .notype
	inc cx
.notype:
	cmp cx, RailConstrWin_typedd
	je near .showtypedropdown
	cmp cx, RailConstrWin_catcharea
	je .catchmentarea
	cmp cx, RailConstrWin_buildstation
	je near .buildstation
.disabled:
	ret

.catchmentarea:
	movzx ecx, cl
	mov edi, [esi+window.data]
	btc [edi+8], ecx

	xor byte [CurCatchmentAreaHighlight], 1
	call UpdateStationSelectionSize
	jmp [RefreshWindowArea]

.showclassdropdown:
// Removed code which is now handled by the drop down menus
//
//	mov eax, [GenerateDropDownMenu]
//	mov [OldGenerateDropDownMenu], eax
//	mov dword [GenerateDropDownMenu], addr(GenerateDropDownMenuTab1)
	push dword [curselclass]
	mov al, [CurStationSelClass]
	mov [curselclass], al
	call makestationclassdropdown
	pop dword [curselclass]
//	mov eax, [OldGenerateDropDownMenu]
//	mov [GenerateDropDownMenu], eax
	jmp [RefreshWindowArea]

.showtypedropdown:
//	mov eax, [GenerateDropDownMenu]
//	mov [OldGenerateDropDownMenu], eax
//	mov dword [GenerateDropDownMenu], addr(GenerateDropDownMenuTab1)
	push dword [curselclass]
	mov al, [CurStationSelClass]
	mov [curselclass], al
	mov al, [CurStationSelType]
	mov [curselstation], al
	call makestationseldropdown
	pop dword [curselclass]
//	mov eax, [OldGenerateDropDownMenu]
//	mov [GenerateDropDownMenu], eax
	jmp [RefreshWindowArea]

.incdec:
	push ecx
	movzx ecx, cl
	mov edi, [esi+window.data]
	bt dword [edi+12], ecx
	jc .disabledincdec
	bts dword [edi+8], ecx
	or byte [esi+window.flags], 7
	pop ecx
	cmp cx, RailConstrWin_tracksdec
	je .tracksdec
	cmp cx, RailConstrWin_tracksinc
	je .tracksinc
	cmp cx, RailConstrWin_lengthdec
	je .lengthdec
	jmp .lengthinc
.disabledincdec:
	pop ecx
	ret

.tracksdec:
	movzx eax, byte [CurStationTracks]
	dec al
.tdecloop:
	dec al
	js .tddone
	bt [CurDisabledStationSizes+2], ax
	jc .tdecloop
.tddone:
	inc al
	mov [CurStationTracks], al
	jmp CheckStationSizes

.tracksinc:
	movzx eax, byte [CurStationTracks]
	dec al
.tincloop:
	inc al
	bt [CurDisabledStationSizes+2], ax
	jc .tincloop

	inc al
	mov [CurStationTracks], al
	jmp CheckStationSizes

.lengthdec:
	movzx eax, byte [CurStationLength]
	dec al
.ldecloop:
	dec al
	js .lddone
	bt [CurDisabledStationSizes], ax
	jc .ldecloop
.lddone:
	inc al
	mov [CurStationLength], al
	jmp CheckStationSizes

.lengthinc:
	movzx eax, byte [CurStationLength]
	dec al
.lincloop:
	inc al
	bt [CurDisabledStationSizes], ax
	jc .lincloop

	inc al
	mov [CurStationLength], al
	jmp CheckStationSizes


.rotatestation:
	movzx ecx, cl
	or byte [esi+window.flags], 7
	mov edi, [esi+window.data]
	bts dword [edi+8], ecx

	xor byte [CurStationRotation], 1
	call UpdateStationSelectionSize
	jmp [RefreshWindowArea]

.tabclicked:
	call [RefreshWindowArea]
	mov word [esi+window.height], RailConstrWin_height

	cmp cx, RailConstrWin_signal
	jne .nosignalclicked

	push cx
	push esi
	mov ax, 1 + (3h << 8)
	mov dx, 100h
	mov ebx, -1
	mov esi, SignalCursorSprites
	call [setmousetool]
	mov byte [CurRailMouseTool], cRailMouseToolSignals
	pop esi
	mov edi, [esi+window.data]
	bts dword [edi+16], (RailConstrWin_doublesignal & 0xFF)
	pop cx
	mov byte [CurSignalIsSingle], 0
	jmp .havemousetool
.nosignalclicked:
	cmp cx, RailConstrWin_rail
	jne .norailclicked
	call SelectRailTab
	jmp .havemousetool

.norailclicked:
	cmp cx, RailConstrWin_station
	jne .nostationclicked

	push esi
	push cx
	mov ax, 1 + (3h << 8)
	mov dx, 100h
	mov ebx, 1300
	call [setmousetool]
	mov byte [CurRailMouseTool], cRailMouseToolBuildStation
	pop cx
	pop esi

	mov word [esi+window.height], RailConstrWin_height+40
	mov edi, [esi+window.data]
	bts dword [edi+8], (RailConstrWin_buildstation & 0xFF)

	call UpdateStationSelectionSize
	jmp .havemousetool
.nostationclicked:
	cmp byte [CurRailMouseTool], cRailMouseToolNone
	je .havemousetool

	push cx
	push esi
	mov al, 0
	mov ebx, 0
	call [setmousetool]
	pop esi
	pop cx
	mov byte [CurRailMouseTool], cRailMouseToolNone
.havemousetool:
	movzx ecx, cx
	and dword [esi+window.activebuttons], ~(7 << RailConstrWin_rail)
	bts dword [esi+window.activebuttons], ecx
	sub cl, RailConstrWin_rail
	mov word [esi+window.selecteditem], cx
	pusha
	call RailConstrUITick
	popa
	jmp [RefreshWindowArea]

.arrowclicked2:
	movzx ecx, cl
	mov edi, [esi+window.data]
	bt dword [edi+4], ecx
	jc .disabled
	and dword [edi+0], ~(7 << RailConstrWin_arrowleft)
	bts dword [edi+0], ecx
	sub cl, RailConstrWin_arrowleft & 0xFF

	mov byte [CurRailButton], cl

	movzx ebx, byte [LastRailPiece]
	lea ebx, [ebx*3]
	mov bl, [RailNextPieces + ebx + ecx]
	mov [CurRailPiece], bl
	jmp [RefreshWindowArea]

.arrowclicked:
	movzx ecx, cl
	mov edi, [esi+window.data]
	and dword [edi+0], ~(7 << RailConstrWin_arrowleft)
	bts dword [edi+0], ecx
	sub cl, RailConstrWin_arrowleft & 0xFF
	mov [CurRailPiece], cl

	push esi
	movzx ebx, byte [CurRailPiece]
	shl bx, 2
	add bl, [CurRailConstrDir]
	movzx ebx, word [RailDirMouseSprites+2*ebx]
	call [setmousecursor]
	pop esi

	jmp [RefreshWindowArea]

.buildrailpiece:
	movzx ecx, cl
	or byte [esi+window.flags], 7
	mov edi, [esi+window.data]
	bts dword [edi+0], ecx

	mov ax, [CurRailX]
	mov cx, [CurRailY]
	push esi
	call RailConstrMouseToolClick.buildrail
	pop esi

	call RailConstrUITick

	jmp [RefreshWindowArea]

.removelastrailpiece:
	movzx ecx, cl
	or byte [esi+window.flags], 7
	mov edi, [esi+window.data]
	bts dword [edi+0], ecx

	mov ax, [CurRailX]
	mov cx, [CurRailY]

	movzx ebx, byte [CurRailConstrDir]
	sub ax, [DirToXYOffsets + 4*ebx]
	sub cx, [DirToXYOffsets + 4*ebx + 2]

	movzx edi,cx
	and edi,byte ~15
	shl edi,8
	or di,ax
	shr edi,4
	mov dl, byte [landscape4(di)]
	and dl, 0xF0
	cmp dl, 10h
	je .israil
	cmp dl, 20h
	je .isroad
	ret
.israil:
	mov dl, byte [landscape5(di)]
	and dx, 3Fh
	and dl, byte [RailRemoveMasks + ebx]
	bsf dx, dx
	jnz .hasrail
	ret

.isroad:
	mov dl, byte [landscape5(di)]
	mov dh, [CurRailConstrDir]
	and dh, 1
	xor dh, 1
	shl dh, 3
	add dh, 10h
	cmp dl, dh
	je .isroadcrossing
	ret

.isroadcrossing:
	movzx edx, dl
	shr dl, 3
	and dl, 1
	xor dl, 1

.hasrail:
	pusha
	add dx, 8
	mov si, dx
	shl esi, 16
	mov si, 8

	mov bl, 1
	mov word [operrormsg1], 0x1012
	call [actionhandler]
	cmp ebx, 0x80000000
	je .removefailed

	popa
	movzx edx, dx
	lea ebx, [3*ebx]
	mov bl, [AfterRemoveDirs + 2*ebx + edx]
	mov [CurRailConstrDir], bl
	mov [LastRailConstrDir], bl
	mov byte [CurRailPiece], 1
	mov byte [LastRailPiece], 1
	mov [CurRailX], ax
	mov [CurRailY], cx
	mov edi, [esi+window.data]

	and dword [edi+4], ~( (1 << (RailConstrWin_remove & 0xFF) ) | (1 << (RailConstrWin_pickup & 0xFF) ) )
	and dword [edi+4], ~(7 << (RailConstrWin_arrowleft & 0xFF) )
	or dword [edi+4], (1 << (RailConstrWin_rotate & 0xFF) )

	call RailConstrUITick
	jmp [RefreshWindowArea]

.removefailed:
	popa
	ret

.pickuprail:
	movzx ecx, cl
	or byte [esi+window.flags], 7
	mov edi, [esi+window.data]
	bts dword [edi+0], ecx

	mov word [CurRailX], -1
	mov word [CurRailY], -1

	call SelectRailTab
	call RailConstrUITick
	jmp [RefreshWindowArea]

.rotaterail:
	movzx ecx, cl
	or byte [esi+window.flags], 7	//enable timer
	mov edi, [esi+window.data]
	bts dword [edi+0], ecx

	inc byte [CurRailConstrDir]
	and byte [CurRailConstrDir], 3

	push esi
	movzx ebx, byte [CurRailPiece]
	shl bx, 2
	add bl, [CurRailConstrDir]
	movzx ebx, word [RailDirMouseSprites+2*ebx]
	call [setmousecursor]
	pop esi

	jmp [RefreshWindowArea]

.buildstation:
	movzx ecx, cl
	mov edi, [esi+window.data]
	btc dword [edi+8], ecx
	jc .stopbuild

	push esi
	push cx
	mov ax, 1 + (3h << 8)
	mov dx, 100h
	mov ebx, 1300
	call [setmousetool]
	mov byte [CurRailMouseTool], cRailMouseToolBuildStation
	pop cx
	pop esi

	call UpdateStationSelectionSize

	jmp [RefreshWindowArea]
.stopbuild:
	mov byte [CurRailMouseTool], cRailMouseToolNone
	mov ebx, 0
	mov al, 0
	call [setmousetool]
	jmp [RefreshWindowArea]

.signalclicked:
	push ecx
	movzx ecx, cl
	mov edi, [esi+window.data]
	bt dword [edi+16], ecx
	pop ecx
	jc .resetsignalbuttons

	push cx
	push esi
	mov ax, 1 + (3h << 8)
	mov dx, 100h
	mov ebx, -1
	mov esi, SignalCursorSprites
	call [setmousetool]
	mov byte [CurRailMouseTool], cRailMouseToolSignals
	pop esi
	pop cx


	movzx ecx, cl
	mov edi, [esi+window.data]
	and dword [edi+16], ~(7 << (RailConstrWin_doublesignal & 0xFF))
	bts dword [edi+16], ecx
	sub cl, RailConstrWin_doublesignal&0xFF
	mov byte [CurSignalIsSingle], cl
	cmp cl, 2
	jne .noremove
	mov byte [CurRailMouseTool], cRailMouseToolRemoveSignals
	bts word [mouseflags], 4
.noremove:
	jmp [RefreshWindowArea]

.resetsignalbuttons:
	and dword [edi+16], ~(7 << (RailConstrWin_doublesignal & 0xFF))
	mov byte [CurRailMouseTool], cRailMouseToolNone
	mov ebx, 0
	mov al, 0
	call [setmousetool]
	jmp [RefreshWindowArea]

.signaltypedropdown:
	movzx dx, byte [CurSignalType]
	mov word [tempvar], ourtext(rcw_semaphores)
	mov word [tempvar+2], ourtext(rcw_lights)
	mov word [tempvar+4], 0xFFFF
	xor ebx, ebx
	jmp .generatedropdown

.presignaltypedropdown:
	movsx dx, byte [CurPreSignalType]
	inc dx
	mov word [tempvar], ourtext(rcw_automatic)
	mov word [tempvar+2], ourtext(rcw_normal)
	mov word [tempvar+4], ourtext(rcw_entry)
	mov word [tempvar+6], ourtext(rcw_exit)
	mov word [tempvar+8], ourtext(rcw_combo)
	mov word [tempvar+10], 0xFFFF
	xor ebx, ebx
	jmp .generatedropdown

.pbssignaltypedropdown:
	movzx dx, byte [CurPbsSignalType]
	mov word [tempvar], ourtext(rcw_nopbs)
	mov word [tempvar+2], ourtext(rcw_pbs)
	mov word [tempvar+4], 0xFFFF
	xor ebx, ebx
	jmp .generatedropdown

.generatedropdown:
// Reduant By fixed dropdown code
//
//	push dword [esi+window.elemlistptr]
//	push dword [esi+window.activebuttons]
//	push dword [esi+window.disabledbuttons]
//
//	push dx
//	mov dh, cWinDataTabs
//	call FindWindowData
//	jc .failed
//	push edi
//	mov edi, [edi]
//	mov edi, [edi+4*2]
//	mov [esi+window.elemlistptr], edi
//	pop edi
//	pop dx
//
//	push eax
//	mov edi, [esi+window.data]
//	mov eax, [edi+2*8]
//	mov [esi+window.activebuttons], eax
//	mov eax, [edi+2*8+4]
//	mov [esi+window.disabledbuttons], eax
//	pop eax
//
	call [GenerateDropDownMenu] // Should work with the above
//
//	mov edi, [esi+window.data]
//	mov eax, [esi+window.activebuttons]
//	mov [edi+2*8], eax
//	mov eax, [esi+window.disabledbuttons]
//	mov [edi+2*8+4], eax
//.failed:
//	pop dword [esi+window.disabledbuttons]
//	pop dword [esi+window.activebuttons]
//	pop dword [esi+window.elemlistptr]
	jmp [RefreshWindowArea]

UpdateStationSelectionSize:
	movzx ax, [CurStationLength]
	shl ax, 4
	jnz .notzerolen
	mov ax, 10h
.notzerolen:
	movzx bx, [CurStationTracks]
	shl bx, 4
	jnz .notzerotracks
	mov bx, 10h
.notzerotracks:
	cmp byte [CurStationRotation], 0
	je .norotate
	xchg ax, bx
.norotate:
	mov word [highlightareainnerxsize], ax
	mov word [highlightareainnerysize], bx
	mov word [highlightareaouterxsize], ax
	mov word [highlightareaouterysize], bx
	cmp byte [CurCatchmentAreaHighlight], 0
	je .nohighlight
	add ax, 80h
	add bx, 80h
	mov word [highlightareaouterxsize], ax
	mov word [highlightareaouterysize], bx
	mov word [landscapemarkerareaouterxoffs], -40h
	mov word [landscapemarkerareaouteryoffs], -40h
.nohighlight:
	ret

GenerateDropDownMenuTab1:
	push dword [esi+window.elemlistptr]
	push dword [esi+window.activebuttons]
	push dword [esi+window.disabledbuttons]

	push dx
	mov dh, cWinDataTabs
	call FindWindowData
	jc .failed2
	push edi
	mov edi, [edi]
	mov edi, [edi+4*1]
	mov [esi+window.elemlistptr], edi
	pop edi
	pop dx

	push eax
	mov edi, [esi+window.data]
	mov eax, [edi+1*8]
	mov [esi+window.activebuttons], eax
	mov eax, [edi+1*8+4]
	mov [esi+window.disabledbuttons], eax
	pop eax

	call [OldGenerateDropDownMenu]

	mov edi, [esi+window.data]
	mov eax, [esi+window.activebuttons]
	mov [edi+1*8], eax
	mov eax, [esi+window.disabledbuttons]
	mov [edi+1*8+4], eax
.failed2:
	pop dword [esi+window.disabledbuttons]
	pop dword [esi+window.activebuttons]
	pop dword [esi+window.elemlistptr]
	ret

uvard OldGenerateDropDownMenu

uvarb tempiselectrified
uvarb temprailtype
uvard AcceptsListDrawWidthPtr
uvard AcceptsTextIdPtr

RailConstrWinRedraw:
	call [DrawWindowElements]

	cmp word [esi+window.selecteditem], 0
	jne near .norail
	pusha
	mov ebx, [CurRailBuildCost]
	cmp ebx, 0x80000000
	je .nocost2
	mov [textrefstack], ebx

	mov cx, [esi+window.x]
	add cx, 7
	mov dx, [esi+window.y]
	add dx, 135
	mov al, -1
	mov bx, 0x482F
	call [drawtextfn]
.nocost2:
	popa


	push ax
	mov bl, 82
	mov al, [CurRailType]
	mul bl
	movzx ebx, byte [CurRailConstrDir]
	movzx edx, byte [CurRailPiece]
	shl dx, 3
	mov bx, [RailDirSprites + ebx*2 + edx]
	add bx, ax
	pop ax
	mov cx, [esi+window.x]
	add cx, 49
	mov dx, [esi+window.y]
	add dx, 100
	push cx
	push dx
	push edi
	call [drawspritefn]
	pop edi
	pop dx
	pop cx
	movzx ebx, byte [CurRailPiece]
	shl ebx, 2
	add bl, [CurRailConstrDir]
	test word [guispritebase], 8000h
	jnz .nosprites
	add bx, word [guispritebase]
	add bx, 3
	call [drawspritefn]
.nosprites:
.norail:
	cmp word [esi+window.selecteditem], 2
	je near .drawsignals
	cmp word [esi+window.selecteditem], 1
	je .drawstation
	ret
.drawstation:

	mov edi, [currscreenupdateblock]

	pusha
	mov cx, [esi+window.x]
	add cx, RailConstrWin_class_x1
	mov dx, [esi+window.y]
	add dx, RailConstrWin_class_y1-10
	mov al, 10h
	mov bx, ourtext(rcw_class)
	call [drawtextfn]
	popa
	pusha
	mov cx, [esi+window.x]
	add cx, RailConstrWin_class_x1+2
	mov dx, [esi+window.y]
	add dx, RailConstrWin_class_y1+1
	mov al, 10h
	mov bh, 0xC0
	mov bl, [CurStationSelClass]
	mov bp, RailConstrWin_class_x2 - RailConstrWin_class_x1 - 14
	call drawtextlen
	popa
	pusha
	mov cx, [esi+window.x]
	add cx, RailConstrWin_type_x1
	mov dx, [esi+window.y]
	add dx, RailConstrWin_type_y1-10
	mov al, 10h
	mov bx, ourtext(rcw_type)
	call [drawtextfn]
	popa
	pusha
	mov cx, [esi+window.x]
	add cx, RailConstrWin_type_x1+2
	mov dx, [esi+window.y]
	add dx, RailConstrWin_type_y1+1
	mov al, 10h
	mov bh, 0xC1
	mov bl, [CurStationSelType]
	mov bp, RailConstrWin_type_x2 - RailConstrWin_type_x1 - 14
	call drawtextlen
	popa
	pusha
	mov cx, [esi+window.x]
	add cx, RailConstrWin_tracksinc_x2 + 3
	mov dx, [esi+window.y]
	add dx, RailConstrWin_tracksinc_y1
	mov al, 10h
	mov word [textrefstack], ourtext(rcw_drag)
	mov bl, [CurStationTracks]
	cmp bl, 0
	je .dragtracks
	mov word [textrefstack], statictext(printbyte)
	mov byte [textrefstack+2], bl
.dragtracks:
	mov bx, ourtext(rcw_tracks)
	call [drawtextfn]
	popa
	pusha
	mov cx, [esi+window.x]
	add cx, RailConstrWin_lengthinc_x2 + 3
	mov dx, [esi+window.y]
	add dx, RailConstrWin_lengthinc_y1
	mov al, 10h
	mov word [textrefstack], ourtext(rcw_drag)
	mov bl, [CurStationLength]
	cmp bl, 0
	je .draglength
	mov word [textrefstack], statictext(printbyte)
	mov byte [textrefstack+2], bl
.draglength:
	mov bx, ourtext(rcw_length)
	call [drawtextfn]
	popa

	pusha
	mov cx, [esi+window.x]
	add cx, 37
	mov dx, [esi+window.y]
	add dx, 137
	mov bl, [CurStationRotation]
	add bl, 2
	push word [curselstation]
	mov al, [CurStationSelType]
	mov byte [curselstation], al
	mov al, [CurOrigRailType]
	call [DrawStationImageInSelWindow]
	pop word [curselstation]
	popa
	pusha
	mov ax, [landscapemarkerorigx]
	mov cx, [landscapemarkerorigy]
	cmp ax, -1
	je near .noaccepts
	test word [mouseflags], 100b
	jz .noaccepts
	cmp byte [CurRailMouseTool], cRailMouseToolBuildStation
	jne .noaccepts
	mov bp, ax
	mov di, cx
	add bp, [highlightareainnerxsize]
	add di, [highlightareainnerxsize]
	mov bx, cx
	rol bx, 8
	or bx, ax
	ror bx, 4
	mov cx, di
	rol cx, 8
	or cx, bp
	ror cx, 4
	sub cx, 101h
	mov ax, [esi+window.x]
	mov dx, [esi+window.y]
	add ax, 2
	add dx, 180
	mov edi, [AcceptsListDrawWidthPtr]
	mov ebp, [AcceptsTextIdPtr]
	mov word [edi], 96
	mov word [ebp], ourtext(rcw_accepts)
	push edi
	push ebp
	call [DrawPlannedStationAcceptsList]
	pop ebp
	pop edi
	mov word [edi], 144
	mov word [ebp], 0x000D
.noaccepts:
	popa
	ret

.drawsignals:
	mov edi, [currscreenupdateblock]

	pusha
	mov cx, [esi+window.x]
	add cx, 7
	mov dx, [esi+window.y]
	add dx, 51
	mov al, 10h
	movzx bx, byte [CurSignalType]
	add bx, ourtext(rcw_semaphores)
	call [drawtextfn]
	popa

	pusha
	mov cx, [esi+window.x]
	add cx, 7
	mov dx, [esi+window.y]
	add dx, 66
	mov al, -1
	movsx bx, byte [CurPreSignalType]
	add bx, ourtext(rcw_normal)
	call [drawtextfn]
	popa

	pusha
	mov cx, [esi+window.x]
	add cx, 7
	mov dx, [esi+window.y]
	add dx, 81
	mov al, -1
	mov bx, ourtext(rcw_automatic)
	test byte [pbssettings],PBS_MANUALPBSSIG
	jz .nomanualpbs
	movzx bx, byte [CurPbsSignalType]
	add bx, ourtext(rcw_nopbs)
.nomanualpbs:
	call [drawtextfn]
	popa

	pusha
	mov ebx, [CurRailBuildCost]
	cmp ebx, 0x80000000
	je .nocost
	mov [textrefstack], ebx

	mov cx, [esi+window.x]
	add cx, 7
	mov dx, [esi+window.y]
	add dx, 165
	mov al, -1
	mov bx, 0x482F
	call [drawtextfn]
.nocost:
	popa

	pusha
	mov dh, [CurSignalType]
	xor dh, 1
	shl dh, 3
	mov dl, [CurPreSignalType]
	cmp dl, -1
	je .gotbits
	shl dl, 1
	or dh, dl

	jmp .gotbits
.gotbits:
	mov dl, [CurPbsSignalType]
	shl dl, 4
	or dh, dl
	mov ebx, 1288

	movzx edx, dh
	and edx, [numsiggraphics]
	jz .nopresignal

	lea ebx, [ebx-1275 + edx*8-16]
	add ebx, [presignalspritebase]
.nopresignal:
	mov cx, [esi+window.x]
	add cx, RailConstrWin_doublesignal_x1+8
	mov dx, [esi+window.y]
	add dx, RailConstrWin_doublesignal_y2-2
	pusha
	call [drawspritefn]
	popa
	add ebx, 2
	add cx, 10
	pusha
	call [drawspritefn]
	popa
	sub ebx, 2
	add cx, RailConstrWin_singlesignal_x1-RailConstrWin_doublesignal_x1-6
	call [drawspritefn]
	popa

	ret

RailConstrWinHandler:
	mov bx, cx
	mov esi, edi
	cmp dl, cWinEventRedraw
	jz RailConstrWinRedraw
	cmp dl, cWinEventClick
	jz RailConstrWinClick
	cmp dl, cWinEventDropDownItemSelect
	jz near RailConstrWinDropDownSelect
	cmp dl, cWinEventTimer
	jz near RailConstrWinTimer
	cmp dl, cWinEventUITick
	jz near RailConstrUITick
	cmp dl, cWinEventMouseToolClose
	jz near RailConstrMouseToolClose
	cmp dl, cWinEventMouseToolClick
	jz near RailConstrMouseToolClick
	cmp dl, cWinEventClose
	je near RailConstrWinClose
	cmp dl, cWinEventMouseDragUITick
	je RailConstrWinMouseDragUITick
	cmp dl, cWinEventMouseDragRelease
	je near RailConstrWinMouseDragRelease
	ret

RailConstrWinMouseDragUITick:
	cmp byte [CurRailMouseTool], cRailMouseToolBuildStation
	je .station
	ret
.station:
	push esi
	call [ScreenToLandscapeCoords]
	pop esi
	cmp ax, -1
	jz near .nothing
	and ax, 0xFFF0
	and cx, 0xFFF0
	push edi
	push esi
	movzx bx, byte [CurStationLength]
	movzx dx, byte [CurStationTracks]
	mov esi, [CurDisabledStationSizes-2]
	mov si, [CurMinStationLength]
	mov edi, [CurDisabledStationSizes]
	mov di, [CurMinStationTracks]
	// now esi bits 16..31 are the mask of disable length's, bits 0..7 is the minlength and bits 8..15 is the maxlength
	cmp byte [CurStationRotation], 0
	je .norotate
	xchg dx, bx
	xchg esi, edi
.norotate:
	shl bx, 4
	jz .dragx
	add bx, [dragtoolstartx]
	sub bx, 10h
	mov ax, bx
	jmp .nodragx
.dragx:
	//check x size
	push ecx
	push dx
	mov ecx, esi
	dec cl
	dec ch
	mov dx, ax
	sub dx, [dragtoolstartx]
	js .negsizex
	shr dx, 4
	or cl,cl
	js .xlongenough
	cmp dl,cl
	jae .xlongenough
	mov dl, cl
.xlongenough:
	cmp dl, ch
	jbe .xshortenough
	mov dl, ch
.xshortenough:
	movzx dx, dl
	shr ecx, 16
.testloopx:
	bt cx, dx
	jnc .havex
	inc dx
	jmp .testloopx
.havex:
	shl dx, 4
	add dx, [dragtoolstartx]
	mov ax, dx
	jmp .havesizex
.negsizex:
	neg dx
	shr dx, 4
	or cl, cl
	js .xlongenough2
	cmp dl, cl
	jae .xlongenough2
	mov dl, cl
.xlongenough2:
	cmp dl, ch
	jbe .xshortenough2
	mov dl, ch
.xshortenough2:
	movzx dx, dl
	shr ecx, 16
.testloopx2:
	bt cx, dx
	jnc .havex2
	inc dx
	jmp .testloopx2
.havex2:
	shl dx, 4
	neg dx
	add dx, [dragtoolstartx]
	mov ax, dx
.havesizex:

	pop dx
	pop ecx
.nodragx:
	shl dx, 4
	jz .dragy
	add dx, [dragtoolstarty]
	sub dx, 10h
	mov cx, dx
	jmp .nodragy
.dragy:
	//check y size
	push eax
	push bx
	mov eax, edi
	dec al
	dec ah
	mov bx, cx
	sub bx, [dragtoolstarty]
	js .negsizey
	shr bx, 4
	or al,al
	js .ylongenough
	cmp bl,al
	jae .ylongenough
	mov bl, al
.ylongenough:
	cmp bl, ah
	jbe .yshortenough
	mov bl, ah
.yshortenough:
	movzx bx, bl
	shr eax, 16
.testloopy:
	bt ax, bx
	jnc .havey
	inc bx
	jmp .testloopy
.havey:
	shl bx, 4
	add bx, [dragtoolstarty]
	mov cx, bx
	jmp .havesizey
.negsizey:
	neg bx
	shr bx, 4
	or al, al
	js .ylongenough2
	cmp bl, al
	jae .ylongenough2
	mov bl, al
.ylongenough2:
	cmp bl, ah
	jbe .yshortenough2
	mov bl, ah
.yshortenough2:
	movzx bx, bl
	shr eax, 16
.testloopy2:
	bt ax, bx
	jnc .havey2
	inc bx
	jmp .testloopy2
.havey2:
	shl bx, 4
	neg bx
	add bx, [dragtoolstarty]
	mov cx, bx
.havesizey:

	pop bx
	pop eax
.nodragy:
	mov [dragtoolendx], ax
	mov [dragtoolendy], cx
	pop esi
	pop edi

	sub ax, [dragtoolstartx]
	jns .notnegx
	neg ax
.notnegx:
	sub cx, [dragtoolstarty]
	jns .notnegy
	neg cx
.notnegy:
	add ax, 10h
	add cx, 10h
	mov [highlightareaouterxsize], ax
	mov [highlightareaouterysize], cx
	cmp byte [CurCatchmentAreaHighlight], 0
	je .nohighlight
	add ax, 80h
	add cx, 80h
	mov [highlightareaouterxsize], ax
	mov [highlightareaouterysize], cx
	mov word [landscapemarkerareaouterxoffs], -40h
	mov word [landscapemarkerareaouteryoffs], -40h
.nohighlight:
	ret
.nothing:
	mov word [dragtoolendx], -1
	ret

RailConstrWinClose:
	mov byte [CurRailMouseTool], cRailMouseToolNone
	push esi
	call RailConstrUITick
	pop esi
	mov edi, [esi+window.data]
	call dfree
	ret

RailConstrWinMouseDragRelease:
	mov bx, [dragtoolendx]
	sub bx, [dragtoolstartx]
	jns .notnegativex
	neg bx
.notnegativex:
	shr bx, 4
	add bx, 1
	mov dx, [dragtoolendy]
	sub dx, [dragtoolstarty]
	jns .notnegativey
	neg dx
.notnegativey:
	shr dx, 4
	add dx, 1
	mov dh, bl
	cmp byte [CurStationRotation], 0
	jne .norotate
	xchg dh, dl
.norotate:
	pusha
	mov bx, 1
	mov al, [CurStationSelClass]
	mov dh, al
	mov al, [CurStationSelType]
	mov dl, al
	xor eax, eax
	xor ecx, ecx
	dopatchaction actionnewstations
	popa

	push esi
	mov ax, [landscapemarkerorigx]
	and al, 0xF0
	mov cx, [landscapemarkerorigy]
	and cl, 0xF0
	mov bh, [CurStationRotation]
	movzx di, byte [CurOrigRailType]
	mov esi, 0x28
	mov bl, 11
	mov word [operrormsg1], 0x100F
	call [actionhandler]

	mov ax, 1 + (3h << 8)
	mov dx, 100h
	mov ebx, 1300
	call [setmousetool]
	mov byte [CurRailMouseTool], cRailMouseToolBuildStation
	call UpdateStationSelectionSize
	pop esi
	mov edi, [esi+window.data]
	bts dword [edi+8],  RailConstrWin_buildstation & 0xFF

	ret

RailConstrMouseToolClick:
	cmp byte [CurRailMouseTool], cRailMouseToolSignals
	jz near .buildsignals
	cmp byte [CurRailMouseTool], cRailMouseToolRemoveSignals
	je near .removesignals
	cmp byte [CurRailMouseTool], cRailMouseToolBuildRail
	je near .buildrail
	cmp byte [CurRailMouseTool], cRailMouseToolBuildStation
	je .buildstation
	ret

.buildstation:
	movzx bx, byte [CurStationLength]
	movzx dx, byte [CurStationTracks]
	cmp byte [CurStationRotation], 0
	je .norotate
	xchg dx, bx
.norotate:
	or bl, bl
	jz .havedrag
	or dl, dl
	jz .havedrag

	pusha
	mov bx, 1
	mov al, [CurStationSelClass]
	mov dh, al
	mov al, [CurStationSelType]
	mov dl, al
	xor eax, eax
	xor ecx, ecx
	dopatchaction actionnewstations
	popa

	and al, 0xF0
	and cl, 0xF0
	mov dl, [CurStationLength]
	mov dh, [CurStationTracks]
	mov bh, [CurStationRotation]
	movzx di, byte [CurOrigRailType]
	mov esi, 0x28
	mov bl, 11
	mov word [operrormsg1], 0x100F
	call [actionhandler]

	ret
.havedrag:
	and al, 0xF0
	and cl, 0xF0
	mov [dragtoolstartx], ax
	mov [dragtoolstarty], cx
	shl bx, 4
	shl dx, 4
	add bx, ax
	add dx, cx
	cmp ax, bx
	je .dragx
	sub bx, 10h
.dragx:
	cmp cx, dx
	je .dragy
	sub dx, 10h
.dragy:
	mov [dragtoolendx], bx
	mov [dragtoolendy], dx
	mov byte [curmousetooltype], 3
	bts word [uiflags], 13
	ret

.removesignals:
	and al, 0xF0
	and cl, 0xF0
	mov word [operrormsg1], 0x1013
	mov bl, 1
	mov esi, 0xE0008 // RemoveSignals
	call [actionhandler]
	cmp ebx, 80000000h
	je .noremovesound
	push eax
	push esi
	mov esi, -1
	push ebx
	mov bx, ax
	mov eax, 1Eh
	call [generatesoundeffect]
	pop ebx
	pop esi
	pop eax
.noremovesound:
	ret


.buildrail:
	mov dl, [CurOrigRailType]
	mov ebx, [curtooltracktypeptr]
	push word [ebx]
	mov [ebx], dl
	pop word [ebx]
	and al, 0xF0
	and cl, 0xF0
	push ax
	push cx
	push esi
	movzx ebx, byte [CurRailConstrDir]
	movzx esi, byte [CurRailPiece]
	movzx esi, byte [RailDirRailPiece + ebx + esi*4]
	shl esi, 16
	or esi, 8
	mov bl, 9
	mov word [operrormsg1], 0x1011
	call [actionhandler]
	cmp ebx, 80000000h
	pop esi
	jne .success
	pop cx
	pop ax
	ret
.success:

	mov edi, [esi+window.data]
	and dword [edi+4], ~( (1 << (RailConstrWin_remove & 0xFF) ) | (1 << (RailConstrWin_pickup & 0xFF) ) )
	or dword [edi+4], (1 << (RailConstrWin_rotate & 0xFF) )
	cmp byte [CurRailMouseTool], cRailMouseToolBuildRail
	jne .nomousetool
	mov al, 0
	mov ebx, 0
	push esi
	call [setmousetool]
	pop esi
.nomousetool:
	mov byte [CurRailMouseTool], cRailMouseToolBuildRailCon

	push eax
	push esi
	mov esi, -1
	push ebx
	mov bx, ax
	mov eax, 1Eh
	call [generatesoundeffect]
	pop ebx
	pop esi
	pop eax

	mov bl, byte [CurRailConstrDir]
	mov [LastRailConstrDir], bl
	movzx ebx, byte [CurRailPiece]
	mov [LastRailPiece], bl
	mov byte [CurRailButton], 1

	movzx ecx, byte [LastRailConstrDir]
	movzx ecx, byte [RailNextDirs + 4*ebx + ecx]
	mov [CurRailConstrDir], cl

	pop dx
	pop ax
	add ax, [DirToXYOffsets + 4*ecx]
	mov [CurRailX], ax
	add dx, [DirToXYOffsets + 4*ecx + 2]
	mov [CurRailY], dx

	mov edi, [esi+window.data]
	and dword [edi+4], ~(7 << (RailConstrWin_arrowleft & 0xFF))

	cmp byte [RailNextPieces+ebx+0], -1
	jne .haveleft
	bts dword [edi+4], (RailConstrWin_arrowleft & 0xFF)
.haveleft:
	cmp byte [RailNextPieces+ebx+2], -1
	jne .haveright
	bts dword [edi+4], (RailConstrWin_arrowright & 0xFF)
.haveright:

	mov ecx, RailConstrWin_arrowstraight
	jmp RailConstrWinClick.arrowclicked2

.buildsignals:
	mov bh, [CurSignalType]
	xor bh, 1
	shl bh, 3
	mov bl, [CurPreSignalType]
	cmp bl, -1
	je .autopre
	shl bl, 1
	or bl, 80h
	or bh, bl
.autopre:

	mov dl, [CurSignalBits]
	mov dh, [CurPbsSignalType]
	mov bl, 1

	mov word [operrormsg1], 0x1010
	dopatchaction buildsignal
	cmp ebx, 80000000h
	je .nosound
	push eax
	push esi
	mov esi, -1
	push ebx
	mov bx, ax
	mov eax, 1Eh
	call [generatesoundeffect]
	pop ebx
	pop esi
	pop eax
.nosound:
	ret

RailConstrMouseToolClose:
	mov edi, [esi+window.data]
	btr dword [edi+16], RailConstrWin_singlesignal & 0xFF
	btr dword [edi+16], RailConstrWin_doublesignal & 0xFF
	btr dword [edi+16], RailConstrWin_removesignal & 0xFF
	btr dword [edi+8],  RailConstrWin_buildstation & 0xFF
	mov byte [CurRailMouseTool], cRailMouseToolNone
	jmp [RefreshWindowArea]
	ret

RailConstrWinTimer:
	mov edi, [esi+window.data]
	btr dword [edi+0], (RailConstrWin_rotate & 0xFF)
	jc .switch
	btr dword [edi+0], (RailConstrWin_curpiece & 0xFF)
	jc .switch
	btr dword [edi+0], (RailConstrWin_remove & 0xFF)
	jc .switch
	btr dword [edi+0], (RailConstrWin_pickup & 0xFF)
	jc .switch
	btr dword [edi+8], (RailConstrWin_tracksdec & 0xFF)
	jc .switch
	btr dword [edi+8], (RailConstrWin_tracksinc & 0xFF)
	jc .switch
	btr dword [edi+8], (RailConstrWin_lengthdec & 0xFF)
	jc .switch
	btr dword [edi+8], (RailConstrWin_lengthinc & 0xFF)
	jc .switch
	btr dword [edi+8], (RailConstrWin_rotatestation & 0xFF)
	jc .switch

	ret
.switch:
	jmp [RefreshWindowArea]

RailConstrWinDropDownSelect:
	cmp cx, RailConstrWin_signaltypedd
	jne .noSignalType
	mov byte [CurSignalType], al
	jmp [RefreshWindowArea]
.noSignalType:
	cmp cx, RailConstrWin_presignaltypedd
	jne .noPreSignalType
	dec al
	mov byte [CurPreSignalType], al
	jmp [RefreshWindowArea]
.noPreSignalType:
	cmp cx, RailConstrWin_pbssignaltypedd
	jne .noPbsSignalType
	mov byte [CurPbsSignalType], al
	jmp [RefreshWindowArea]
.noPbsSignalType:
	cmp cx, RailConstrWin_classdd
	jne .nostationclass

	movzx eax, al
	call findstationforclass
	mov ah, dl
	jnc .nodflt
	xor ax, ax
.nodflt:
	mov byte [CurStationSelClass], al
	mov byte [CurStationSelType], ah
	movzx eax, ah
	jmp .updatestationtype

.nostationclass:
	cmp cx, RailConstrWin_typedd
	jne .nostationtype

	movzx eax, al
	mov al, [stationdropdownnums+eax]
	mov [CurStationSelType], al
	jmp .updatestationtype

.nostationtype:
	ret

.updatestationtype:
	// disallowed*: bit 0..6=lengths 1..7, bit 7=+7
	// so length bits 1..14 would be 0..6, 0|7, 1|7, 2|7... 7|7
	movsx ecx,byte [disallowedplatforms+eax]
	or ch,cl
	or ch,0x80
	shl cl,1
	shl ecx,16
	sar ecx,1

	movsx cx,byte [disallowedlengths+eax]
	or ch,cl
	or ch,0x80
	shl cl,1
	sar cx,1

	mov eax,ecx     // now eax bits 0..13 = lengths 1..14, bits 16..29 = platforms 1..14 (bit set if disabled)
	push ecx
	xor eax, 0xFFFF
	and eax, 0x3FFF
	bsf ecx, eax
	inc ecx
	mov [CurMinStationLength], cl
	bsr ecx, eax
	inc ecx
	mov [CurMaxStationLength], cl
	cmp [CurMinStationLength], cl
	jne .notonelength
	mov [CurStationLength], cl
	jmp .havelen
.notonelength:
	mov byte [CurMinStationLength], 0
.havelen:
	pop ecx
	mov eax, ecx
	push ecx
	shr eax, 16
	xor eax, 0xFFFF
	and eax, 0x3FFF
	bsf ecx, eax
	inc ecx
	mov [CurMinStationTracks], cl
	bsr ecx, eax
	inc ecx
	mov [CurMaxStationTracks], cl
	cmp [CurMinStationTracks], cl
	jne .notonetracks
	mov [CurStationTracks], cl
	jmp .havetracks
.notonetracks:
	mov byte [CurMinStationTracks], 0
.havetracks:
	pop ecx
	mov [CurDisabledStationSizes], ecx

	movzx ecx, byte [CurStationLength]
	cmp cl, [CurMinStationLength]
	jae .longenough
	mov cl, [CurMinStationLength]
.longenough:
	cmp cl, [CurMaxStationLength]
	jbe .shortenough
	mov cl, [CurMaxStationLength]
.shortenough:
	dec cl
	js .havelength
.lengthloop:
	bt [CurDisabledStationSizes], cx
	jnc .havelength
	inc cl
	jmp .lengthloop
.havelength:
	inc cl
	mov [CurStationLength], cl

	movzx ecx, byte [CurStationTracks]
	cmp cl, [CurMinStationTracks]
	jae .highenough
	mov cl, [CurMinStationTracks]
.highenough:
	cmp cl, [CurMaxStationTracks]
	jbe .lowenough
	mov cl, [CurMaxStationTracks]
.lowenough:
	dec cl
	js .havetrack
.tracksloop:
	bt [CurDisabledStationSizes+2], cx
	jnc .havetrack
	inc cl
	jmp .tracksloop
.havetrack:
	inc cl
	mov [CurStationTracks], cl

	jmp CheckStationSizes

RailConstrUITick:
	mov word [CurSelectionSprites+0], 0
	mov word [CurSelectionSprites+2], 0
	mov word [CurSelectionSprites+4], 0
	mov word [CurSelectionSprites+6], 0
	mov dword [CurRailSprites+0], 0
	mov dword [CurRailSprites+4], 0
	mov dword [CurRailSprites+8], 0
	mov dword [CurRailSprites+12], 0
	mov byte [CurSelectionFlags+0], 0
	mov byte [CurSelectionFlags+1], 0
	mov byte [CurSelectionFlags+2], 0
	mov byte [CurSelectionFlags+3], 0
	mov byte [CurSelFlags], 0
	mov dword[CurRailBuildCost], 0x80000000

	cmp byte [CurRailMouseTool], cRailMouseToolSignals
	je near .signals
	cmp byte [CurRailMouseTool], cRailMouseToolRemoveSignals
	je near .removesignals
	cmp byte [CurRailMouseTool], cRailMouseToolBuildRail
	je .buildrail
	cmp byte [CurRailMouseTool], cRailMouseToolBuildRailCon
	je near .buildrailcon
	cmp byte [CurRailMouseTool], cRailMouseToolBuildStation
	je .buildstation

	jmp .nosignals

.buildstation:
	call [RefreshWindowArea]

	mov byte [CurSelectionXSizes+0], 10h
	mov byte [CurSelectionYSizes+0], 10h
	mov byte [CurSelectionZSizes+0], 1h
	test word [guispritebase], 8000h
	jnz .nosprites3
	movzx bx, byte [CurStationRotation]
	shl bx, 3
	add bx, [guispritebase]
	add bx, 15
	mov [CurSelectionSprites], bx
	mov byte [CurSelectionFlags+0], 7
	mov byte [CurSelFlags], 1
.nosprites3:
	jmp .havesprite

.buildrail:
	mov ax, [mousecursorscrx]
	mov cx, [mousecursorscry]
	call [ScreenToLandscapeCoords]
	cmp ax, -1
	je near .havesprite
	and al, 0xf0
	and cl, 0xf0
	call [gettileinfo]

	mov byte [CurSelectionXSizes+0], 10h
	mov byte [CurSelectionYSizes+0], 10h
	mov byte [CurSelectionZSizes+0], 1h
	mov byte [CurSelectionXSizes+1], 10h
	mov byte [CurSelectionYSizes+1], 10h
	mov byte [CurSelectionZSizes+1], 1h

	test word [guispritebase], 8000h
	jnz .nosprites
	movzx ebx, byte [CurRailConstrDir]
	movzx edx, byte [CurRailPiece]
	movzx ebx, byte [RailDirRailPiece + ebx + edx*4]
	movzx edi, di
	lea edi, [edi*3]
	shl edi, 3
	mov ebx, dword [RailTileSprites + ebx*4 + edi]
	add bx, [guispritebase]
	add bx, 15
	mov word [CurSelectionSprites+2], bx

	movzx ebx, byte [CurRailPiece]
	shl ebx, 2
	add bl, [CurRailConstrDir]
	add bx, word [guispritebase]
	add bx, 3
	mov word [CurSelectionSprites+0], bx
	mov byte [CurSelectionFlags+0], 7
	mov byte [CurSelectionFlags+1], 7

	mov byte [CurSelFlags], 1
.nosprites:
	jmp .havesprite

.buildrailcon:
	mov ax, [CurRailX]
	mov cx, [CurRailY]
	call [gettileinfo]

	mov byte [CurRailXSizes+0], 10h
	mov byte [CurRailYSizes+0], 10h
	mov byte [CurRailZSizes+0], 1h
	mov byte [CurRailXSizes+1], 10h
	mov byte [CurRailYSizes+1], 10h
	mov byte [CurRailZSizes+1], 1h

	test word [guispritebase], 8000h
	jnz .nosprites2

	movzx ebx, byte [CurRailConstrDir]
	movzx edx, byte [CurRailPiece]
	movzx ebx, byte [RailDirRailPiece + ebx + edx*4]
	movzx edi, di
	lea edi, [edi*3]
	shl edi, 3
	mov ebx, dword [RailTileSprites + ebx*4 + edi]
	add bx, [guispritebase]
	add bx, 15
	mov dword [CurRailSprites+4], ebx

	movzx ebx, byte [CurRailPiece]
	shl ebx, 2
	add bl, [CurRailConstrDir]
	add bx, word [guispritebase]
	add bx, 3
	mov dword [CurRailSprites+0], ebx
	mov byte [CurRailFlags+0], 7
	mov byte [CurRailFlags+1], 7
.nosprites2:
	pusha
	mov ax, [CurRailX]
	mov cx, [CurRailY]
	mov dl, [CurOrigRailType]
	mov ebx, [curtooltracktypeptr]
	push word [ebx]
	mov [ebx], dl
	pop word [ebx]
	movzx ebx, byte [CurRailConstrDir]
	movzx esi, byte [CurRailPiece]
	movzx esi, byte [RailDirRailPiece + ebx + esi*4]
	shl esi, 16
	or esi, 8
	mov bl, 8
	call [actionhandler]
	mov [CurRailBuildCost], ebx
	mov al, 3
	mov bx, 100h
	call [invalidatehandle]
	popa

	jmp .havespriteandpos

.removesignals:
	mov ax, [landscapemarkerorigx]
	mov cx, [landscapemarkerorigy]
	and ax, 0xFF0
	and cx, 0xFF0

	mov bl, 0
	mov esi, 0xE0008 // RemoveSignals
	call [actionhandler]
	mov dword [CurRailBuildCost], ebx

	mov al, 3
	mov bx, 100h
	call [invalidatehandle]

	jmp .nosignals

.signals:
	mov ax, [landscapemarkerorigx]
	mov cx, [landscapemarkerorigy]
	and ax, 0xFF0
	and cx, 0xFF0

	mov byte [CurSelectionXSizes+0], 1
	mov byte [CurSelectionYSizes+0], 1
	mov byte [CurSelectionZSizes+0], 0Ah
	mov byte [CurSelectionXSizes+1], 1
	mov byte [CurSelectionYSizes+1], 1
	mov byte [CurSelectionZSizes+1], 0Ah
	mov byte [CurSignalBits], 0

	pusha

	call locationtoxy
	mov bl, [landscape4(si)]
	and bl, 0xF0
	cmp bl, 10h
	jne near .nosignal

	movzx ebx, byte [landscape5(si)]
	and bl, 3Fh
	bsf eax, ebx
	bsr ecx, ebx
	cmp eax,ecx
	je .havesignal
	cmp bl, 0Ch
	jne .noWE
	mov eax, 6
	jmp .havesignal
.noWE:
	cmp bl, 30h
	jne near .nosignal
	mov eax, 7
.havesignal:
	push eax
	mov ax, [mousecursorscrx]
	mov cx, [mousecursorscry]
	call [ScreenToLandscapeCoords]
	cmp ax, -1
	je near .nosignal2
	//now find out what edge is the closest to the mouse...
	xor ebx, ebx
	and al, 0Fh
	and cl, 0Fh
	cmp al, cl
	jbe .notwest
	add bl, 2
.notwest:
	add al, cl
	cmp al, 0x0F
	jbe .notsouth
	add bl, 1
.notsouth:
	pop eax
	//now, ebx: 0 = NE, 1 = SE, 2 = NW, 3 = SW
	//     eax: 0: xdir, 1: ydir, 2: northc, 3: southc, 4: westc, 5: eastc, 6: north+south, 7: west+east
	push edx
	mov dh, [CurSignalType]
	xor dh, 1
	shl dh, 3
	mov dl, [CurPreSignalType]
	cmp dl, -1
	je .gotbits
	shl dl, 1
	or dh, dl
	jmp .gotbits
.gotbits:
	mov dl, [CurPbsSignalType]
	shl dl, 4
	or dh, dl
	mov ecx, 1276

	movzx edx, dh
	and edx, [numsiggraphics]
	jz .nopresignal

	lea ecx, [ecx-1275 + edx*8-16]
	add ecx, [presignalspritebase]
.nopresignal:
	pop edx


	cmp byte [CurSignalIsSingle], 0
	je .doublesignal

	push ax
	mov al, [SingleSignalBits+8*ebx+eax]
	mov [CurSignalBits], al
	pop ax

	movsx ebx, byte [SingleRailSignals+8*ebx+eax]
	cmp ebx, -1
	je near .nosignal

	push edi
	mov edi, 0
	testmultiflags signalsontrafficside
	jz .notrafficside
	test byte [roadtrafficside], 10h
	jz .notrafficside
	mov edi, 24
.notrafficside:

	mov al, [signaloffsets+ebx+edi]
	mov [CurSelectionXs+0], al
	mov al, [signaloffsets+ebx+12+edi]
	mov [CurSelectionYs+0], al
	mov bx, word [signalsprites+2*ebx]
	sub bx, 1275
	add bx, cx
	mov [CurSelectionSprites+0], bx
	pop edi
	jmp .nosignal
.doublesignal:
	push edi
	mov edi, 0
	testmultiflags signalsontrafficside
	jz .notrafficside2
	test byte [roadtrafficside], 10h
	jz .notrafficside2
	mov edi, 24
.notrafficside2:


	push ebx
	push eax

	push ax
	mov al, [DoubleSignalBits+8*ebx+eax]
	mov [CurSignalBits], al
	pop ax

	movsx ebx, byte [DoubleRailSignals+8*ebx+eax]
	cmp ebx, -1
	je .nofirstsignal

	mov al, [signaloffsets+ebx+edi]
	mov [CurSelectionXs+0], al
	mov al, [signaloffsets+ebx+12+edi]
	mov [CurSelectionYs+0], al
	mov bx, [signalsprites+2*ebx]
	sub bx, 1275
	add bx, cx
	mov [CurSelectionSprites+0], bx
.nofirstsignal:
	pop eax
	pop ebx

	movsx ebx, byte [DoubleRailSignals+4*8+8*ebx+eax]
	cmp ebx, -1
	je .nosecondsignal

	mov al, [signaloffsets+ebx+edi]
	mov [CurSelectionXs+1], al
	mov al, [signaloffsets+ebx+12+edi]
	mov [CurSelectionYs+1], al
	mov bx, [signalsprites+2*ebx]
	sub bx, 1275
	add bx, cx
	mov [CurSelectionSprites+2], bx
.nosecondsignal:
	pop edi
	jmp .nosignal

.nosignal2:
	pop eax
.nosignal:

	mov dword [CurRailBuildCost], 0x80000000
	mov ax, [mousecursorscrx]
	mov cx, [mousecursorscry]
	call [ScreenToLandscapeCoords]
	cmp ax, -1
	je .nosignal3
	mov dl, [CurSignalBits]
	mov bl, 0
	dopatchaction buildsignal
	mov dword [CurRailBuildCost], ebx
	cmp ebx, 80000000h
	jne .nosignal3
	mov word [CurSelectionSprites+0], 0
	mov word [CurSelectionSprites+2], 0
	mov word [CurSelectionSprites+4], 0
	mov word [CurSelectionSprites+6], 0
.nosignal3:

	mov al, 3
	mov bx, 100h
	call [invalidatehandle]
	popa

.nosignals:

.havesprite:
	mov ax, [landscapemarkerorigx]
	mov cx, [landscapemarkerorigy]
	and ax, 0xFF0
	and cx, 0xFF0
.havespriteandpos:
	call [invalidatetile]
	ret

global collectlandscapemarkers
collectlandscapemarkers:
	pusha
	test word [mouseflags], 1100b
	jz near .nosignal
	mov bx, [landscapemarkerorigx]
	cmp ax, bx
	jb near .nosignal
	add bx, [highlightareainnerxsize]
	cmp ax, bx
	jae near .nosignal

	mov bx, [landscapemarkerorigy]
	cmp cx, bx
	jb near .nosignal
	add bx, [highlightareainnerysize]
	cmp cx, bx
	jae near .nosignal

	mov ebx, 3
.loop:
	push di
	push si
	push dx
	push ax
	push cx

	push ebx
	test byte [CurSelectionFlags+ebx], 4
	or al, byte [CurSelectionXs+ebx]
	or cl, byte [CurSelectionYs+ebx]
	jnz .noheightadj
	call [getgroundaltitude]
.noheightadj:
	mov edi, ebx
	movzx ebx, word [CurSelectionSprites+2*ebx]
	cmp bx, 0
	je .nosprite
	movzx si, byte [CurSelectionYSizes+edi]
	mov dh, [CurSelectionZSizes+edi]
	test byte [CurSelectionFlags+edi], 2
	jnz .norecolor
	or ebx, 8000h + (773 << 16)
.norecolor:
	test byte [CurSelectionFlags+edi], 1
	jz .noground
	call [addgroundsprite]
	jmp .nosprite
.noground:
	movzx di, byte [CurSelectionXSizes+edi]
	call [addsprite]
.nosprite:
	pop ebx

	pop cx
	pop ax
	pop dx
	pop si
	pop di
	dec ebx
	jns .loop
.nosignal:
	popa


	pusha
	cmp ax, [CurRailX]
	jne near .nosignal2
	cmp cx, [CurRailY]
	jne near .nosignal2

	mov ebx, 3
.loop2:
	push di
	push si
	push dx
	push ax
	push cx

	push ebx
	test byte [CurRailFlags+ebx], 4
	or al, byte [CurRailXs+ebx]
	or cl, byte [CurRailYs+ebx]
	jnz .noheightadj2
	call [getgroundaltitude]
.noheightadj2:
	mov edi, ebx
	mov ebx, [CurRailSprites+4*ebx]
	cmp bx, 0
	je .nosprite2
	movzx si, byte [CurRailYSizes+edi]
	mov dh, [CurRailZSizes+edi]
	test byte [CurRailFlags+edi], 2
	jnz .norecolor2
	or ebx, 8000h + (773 << 16)
.norecolor2:
	test byte [CurRailFlags+edi], 1
	jz .noground2
	call [addgroundsprite]
	jmp .nosprite2
.noground2:
	movzx di, byte [CurRailXSizes+edi]
	call [addsprite]
.nosprite2:
	pop ebx

	pop cx
	pop ax
	pop dx
	pop si
	pop di
	dec ebx
	jns .loop2
.nosignal2:
	popa


	mov bx, [landscapemarkerorigx]
	cmp ax, bx
	jb near .noskipcaller
	add bx, [highlightareainnerxsize]
	cmp ax, bx
	jae near .noskipcaller

	mov bx, [landscapemarkerorigy]
	cmp cx, bx
	jb near .noskipcaller
	add bx, [highlightareainnerysize]
	cmp cx, bx
	jae near .noskipcaller


	test byte [CurSelFlags], 1
	jz .noskipcaller
	pop ebx
.noskipcaller:

	call CheckDiagonalSelection
	call CheckAirportTile

	test word [mouseflags], 1100b
	ret

var SignalCursorSprites
	dw 1292, 148
	dw 1293, 128
	dw -1

var SingleRailSignals // 4 * 8 offsets (index into signalsprites/signaloffsets)
	//	xdir	ydir	north	south	west	east	ns	we
	db 	11,	-1,	5,	-1,	-1,	2,	5,	2	//NE
	db	-1,	9,	-1,	7,	-1,	3,	7,	3	//SE
	db	-1,	8,	4,	-1,	0,	-1,	4,	0	//NW
	db	10,	-1,	-1,	6,	1,	-1,	6,	1	//SW

var DoubleRailSignals // the same for double signals, but this time two tables, one for each signal
	db	11,	9,	5,	-1,	-1,	2,	5,	2
	db	11,	9,	-1,	7,	-1,	3,	7,	3
	db	10,	8,	4,	-1,	0,	-1,	4,	0
	db	10,	8,	-1,	6,	1,	-1,	6,	1

	db	10,	8,	4,	-1,	-1,	3,	4,	3
	db	10,	8,	-1,	6,	-1,	2,	6,	2
	db	11,	9,	5,	-1,	1,	-1,	5,	1
	db	11,	9,	-1,	7,	0,	-1,	7,	0

var SingleSignalBits
	db	40h,	00h,	40h,	00h,	00h,	10h,	40h,	10h
	db	00h,	40h,	00h,	10h,	00h,	20h,	10h,	20h
	db	00h,	80h,	80h,	00h,	40h,	00h,	80h,	40h
	db	80h,	00h,	00h,	20h,	80h,	00h,	20h,	80h
var DoubleSignalBits
	db	0C0h,	0C0h,	0C0h,	00h,	00h,	30h,	0C0h,	30h
	db	0C0h,	0C0h,	00h,	30h,	00h,	30h,	30h,	30h
	db	0C0h,	0C0h,	0C0h,	00h,	0C0h,	00h,	0C0h,	0C0h
	db	0C0h,	0C0h,	00h,	30h,	0C0h,	00h,	30h,	0C0h

global openrailconstrwindow
openrailconstrwindow:
	push byte PL_DEFAULT
	call ctrlkeystate
	setz cl
	test byte [locomotionguibits], locomotiongui_defaultnewgui
	setz ch
	cmp cl, ch
	jnz .oldgui
	pop ecx
	jmp OpenRailConstrWindow
.oldgui:
	pop ecx
	push dx
	push ecx
	mov cl, 3
	xor dx, dx
	ret

global createrailstationselectwindow
createrailstationselectwindow:
	pusha
	push byte PL_DEFAULT
	call ctrlkeystate
	setz cl
	test byte [locomotionguibits], locomotiongui_defaultstation
	setz ch
	cmp cl, ch
	jnz .oldgui
	popa
	pop ebx
	mov dl, [currconstrtooltracktype]
	call OpenRailConstrWindow
	mov cx, RailConstrWin_station
	jmp RailConstrWinClick.tabclicked
.oldgui:
	popa
	mov ebx, 148 + (185 << 16)
	mov dx, 28h
	ret
