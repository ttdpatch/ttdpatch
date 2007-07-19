// Maintainer Oskar
// -------------------------------------------
// hotkey table init for hotkey function
// -------------------------------------------

#include <std.inc>
#include <flags.inc>
#include <textdef.inc>
#include <window.inc>
#include <smartpad.inc>

extern FindWindow,errorpopup,hexdigits,patchflags,redrawscreen,setgamespeed
extern setgamespeed.set,specialerrtext1
extern texthandler,saTramConstrWindowElemList
extern LandscapeGenWindowHandler

// The order here must match the order of WinTitleWidths in procs/morehotheys.asm
struc saWindowElemList
	.RoadConstr:	resd 1
	.AirportConstr:	resd 1
//	.PlantTrees:	resd 1
endstruc

uvard saWindowElemLists, saWindowElemList_size/4


#define HT_DEBUG 0
#define HT_GSSLOWER 1		// Set gamespeed slower
#define HT_GSNORMAL 2		// Set gamespeed normal
#define HT_GSFASTER 3		// Set gamespeed faster
#define HT_DISPLAYBYTE1 4	// +01h Town names displaye
#define HT_DISPLAYBYTE2 5	// +02h Station names displayed
#define HT_DISPLAYBYTE3 6	// +04h Signs displayed
#define HT_DISPLAYBYTE4 7	// +08h Full animation
#define HT_DISPLAYBYTE5 8	// +10h No building transparenc
#define HT_DISPLAYBYTE6 9	// +20h Full detail
#define HT_DISPLAYBYTENUM 6
#define HT_TOOLS 10
#define HT_TOOLSNUM 14
#define HT_ORDERS 24
#define HT_ORDERSNUM 6

#define HT_TABLESIZE 30

//		  0                                 1         2
//		  0  1    2    3     4   5   6789   0123456789012345678
// hotkeylist db 'x',0xFF,0xFF,0xFF,'!','"',"§$t%","1234567890-=~]dfghj",0,0
// Keyboard Layouts: http://www.uni-regensburg.de/EDV/Misc/KeyBoards/


// set to 1 to enable showing all hotkeys
#define HT_SHOWHOTKEYS 1
#if HT_SHOWHOTKEYS
var hotkeydisp, db 94h,"Key code: ",5ch
var hotkeydisphex1, db 0
var hotkeydisphex2, db 0
	db ", Character: "
var hotkeydispchar, db 0
	db 0
#endif


// -------------------------------------------
// hotkey function
// -------------------------------------------
// in:	al = ascii keycode
// not safe: al, ax
// -------------------------------------------
// the call for hotkeyfunction will replace:
// 00558AAB   3C 63            CMP AL,63
// 00558AAD   75 04            JNZ SHORT TTDLOADW.00558AB3
// 00558AAF   32C0             XOR AL,AL
// 00558AB1   EB 	            JMP
//
// to:
// call runindex(hotkeyfunction)
// jz ...
// -------------------------------------------

	
global hotkeyfunction
hotkeyfunction:
	push eax
	mov ax,ourtext(hotkeylistdos) + WINTTDX
	call texthandler
	pop eax

#if HT_SHOWHOTKEYS
	cmp byte [esi+HT_DEBUG],'?'
	jne .dontshow

	movzx ecx,al
	shr ecx,4
	mov cl,[hexdigits+ecx]
	mov byte [hotkeydisphex1],cl
	mov cl,al
	and cl,0x0f
	mov cl,[hexdigits+ecx]
	mov byte [hotkeydisphex2],cl
	mov dword [specialerrtext1],hotkeydisp
	pusha
	cmp al,' '	// show space instead of codes<20h
	jb .notchar
	cmp al,'z'	// or between 7Bh and 9Eh
	jbe .ok
	cmp al,0x9e
	ja .ok
.notchar:
	mov al,' '
.ok:
	mov byte [hotkeydispchar],al
	mov bx,statictext(specialerr1)
	mov dx,-1
	xor ax,ax
	xor cx,cx
	call dword [errorpopup]
	popa
.dontshow:
#endif
	xor ecx,ecx
.nextdisplaybytekey:
	cmp al,[esi+ecx+HT_DISPLAYBYTE1]
	jnz .not_key

	btc [displayoptions],ecx
	call redrawscreen

.not_key:
	inc ecx
	cmp ecx,HT_DISPLAYBYTENUM
	jb .nextdisplaybytekey
  
//
// Gamespeed patch keys
//

	testflags gamespeed
	jnc .endgamespeed

	xor ecx, ecx
	cmp al, [esi+HT_GSFASTER]
	jnz .nospeedup
	mov cl,1
	call setgamespeed
	jmp short .endgamespeed

.nospeedup:
	cmp al, [esi+HT_GSSLOWER]
	jnz .noslowdown

	mov cl,-1
	call setgamespeed
	jmp short .endgamespeed

.noslowdown:
	cmp al, [esi+HT_GSNORMAL]
	jnz .endgamespeed
	mov cl,3
	call setgamespeed.set

.endgamespeed:
	// add more hotkeys here

#if 0
//OSDEBUG
	cmp al, [esi+HT_DEBUG]		//78h			// x pressed? (Its my Debug hotkey, please don't use it in normal use)
	jnz .not_x

.not_x:
#endif

	cmp al,' '
	jne .notspace

	mov cl, 2
	xor dx, dx
	call [FindWindow]
	jz .notspace

	cmp word [esi+window.data], -1280
	jle .notspace

	mov word [esi+window.data], -1280+2

.notspace:
	cmp al,63h		// c key = center
	jnz .nocenter
	xor al, al 		// We need more than 4 bytes, so this bad trick to get more
				// [not that bad, it's actually quite common in TTDPatch ;-) -- Marcin]
.nocenter:

	// WARNING: ADD NOTHING AFTER .nocenter
	// or the 'c' key will break

	ret
;endp hotkeyfunction


// -------------------------------------------
//	Josefs Code for Toolbar Hotkeys
// -------------------------------------------
//
// scan build tool hotkey list for current key
//
// in:	al=key
//	ah=0 for rail, 1 for road
// out:	eax=tool index; skip call if wrong key
// safe:?
//
global toolselect
toolselect:
	push esi
	push ebx

	xchg eax,ecx
	mov ax,ourtext(hotkeylistdos) + WINTTDX
	call texthandler
	mov eax,ecx
	add esi, HT_TOOLS

	xor ebx,ebx

.nextkeyinlist:
	lodsb
	cmp al, 0
	je .notinlist
	inc ebx
	cmp al, cl
	jne .nextkeyinlist

	lea eax,[ebx-1]
	// now eax=tool index
	
	cmp al, HT_TOOLSNUM
	jae .notinlist

	// skip keys 3 and 4 for road construction
	cmp ch,1
	jne .notroadadjust

	cmp al,2	// "1" or "2"?
	jb .notroadadjust

	sub al,2
	cmp al,2
	jb .notinlist	// was "3" or "4"

.notroadadjust:
	pop ebx
	pop esi
	ret

.notinlist:
	pop ebx
	pop esi
	add dword [esp],7	// skip the call
	ret

// called when checking whether road toolbar is active
//
// in:	esi->toolbar window
//	al=key code
//	ZF=1 if is road toolbar
// out:	ZF=1 if road/tram toolbar, ZF=0 if not
//	al=tool index if road toolbar
// safe:eax
global rvtoolselect
rvtoolselect:
	je .isroad
	cmp dword [esi+window.elemlistptr],saTramConstrWindowElemList
	jne .notroad

.isroad:
	mov ah,1
	call toolselect
	pad 5		// because toolselect skips 7 bytes if no match and returns with ZF=0
	test al,0	// make sure ZF=1

.notroad:
	ret

// Tables for mapping the return from toolselect to toolbar control indexes.
// In most cases (except for scenEdLandMap), these are index+1, and the call
// table is positioned to have a dummy 0 entry.
// If the high bit is set, clear it and set [forcectrlkey]. (#if 0'ed out)
// keys :   1  2  3  4  5  6  7  8  9  0  -  =  `  \  <eol>
varb dockToolMap // This one contains control indices, not call-table indices
	db  2, 3, 4, 0, 5, 6, 7, 3, 2, 4,10, 0, 0, 8
varb airportToolMap
	db  1, 0, 0, 0, 2, 3, 4, 0, 1, 0, 0, 0, 0, 5
varb scenEdRoadToolMap
	db  1, 2, 0, 0, 3, 4, 5, 0, 0, 0, 9,10,11,12
varb scenEdLandMap
	db  5, 7,12, 4, 5,11, 3, 6,10, 0, 0, 0, 0, 0
endvar

global othertoolselect
othertoolselect:
	push eax
	call toolselect
	mov cl,3
	xor dx,dx
	jmp short .continue
// If toolselect "fails", it will return here.
	test al, al
	jz short .ret1	// It really did fail.

.orderwin:
	mov dx, 0
ovar lastOrderWin, -2
	mov cl, cWinTypeVehicleOrders
	call [FindWindow]
	jz short .ret1
//	al is HT_TOOLSNUM + 0..5 (Skip, Delete, Non-stop, Goto, Full-load, Unload)
//	Want cl:	    4..9
	lea ecx, [eax - (HT_TOOLSNUM-4)]
	extern VehOrdersWindowHandler
	mov eax, [VehOrdersWindowHandler]
	add eax, 19h+9*2	// Skip over entry bookkeeping that doesn't apply to faked clicks,
	call eax		// plus first two tests (Close and Drag).
	jmp short .ret1

.continue:
	mov ebx, saWindowElemLists
	call [FindWindow]
	jz .maybeScenRoad
	mov edi, [esi+window.elemlistptr]

	extern win_dockconstgui_elements
	cmp edi, win_dockconstgui_elements
	jne .maybeairport

	mov al,[dockToolMap+eax]
	test al,al
	jz .ret1
#if 0
	extern forcectrlkey
	sets ah
	mov [forcectrlkey], ah
	// Don't bother checking whether the toolbar button is pressed.
	// If it is, [canaltooltype] is valid
	// If it isn't, unpressing it again won't hurt anything.
	extern canaltooltype
	cmp ah, [canaltooltype]
	je .cont
	and byte [esi+window.activebuttons+1], ~1
.cont:
	and eax, 7Fh
#endif
	extcall DockWaterConstr_ClickHandler.notdestroy
#if 0
	mov byte [forcectrlkey], 0
#endif
.ret1:
	jmp short .ret
	
.maybeairport:
	cmp edi, [ebx+saWindowElemList.AirportConstr]
	jne .maybetrees
	
	mov al,[airportToolMap+eax]
	test eax,eax
	jz .ret
	call [eax*4+edi+67h]
	jmp short .ret

.maybetrees:
/*
	TODO:	Make tree planting window work?
		Must find the window's handler first, though
	
	cmp edi, [saPlantTreesWinElemList]
	jne .maybeScenRoad
	mov ebx, [saPlantTreesWinElemList]
	call [eax*4+ebx+???]
	jmp short .ret
*/

.maybeScenRoad:
	mov cl,3Ch
	call [FindWindow]
	jz .maybeScenLand
	mov al,[scenEdRoadToolMap+eax]
	test eax,eax
	jz .ret
	mov ebx, [ebx+saWindowElemList.RoadConstr]
	call [eax*4+ebx+0C9h]
	jmp short .ret

.maybeScenLand:
	mov cl,38h
	call [FindWindow]
	jz .ret
	mov cl,[scenEdLandMap+eax]
	jcxz .ret
	call [LandscapeGenWindowHandler]

	// TODO: Redraw the screen after using controls 6 or 7
	
.ret:
	pop eax
//These two instructions were pulled from TTD code to make space for the icall.
	xor ebx,ebx
	cmp al,1Bh
	ret

global StoreOrderWindow.new, StoreOrderWindow.drag

// In:	esi->window struct
//	 cl: window type
//	 dx: window ID
StoreOrderWindow:
.new:
	pop eax
	pop dx		//overwritten
	mov [esi+6], dx	//overwritten
	push eax
.drag:
.check:
	cmp cl, cWinTypeVehicleOrders
	jne .ret
	cmp byte [esi+window.height], 58h // e if the skip, delete, goto, &c buttons are present.
	jne .ret
	mov [lastOrderWin], dx
.ret:
	ret
