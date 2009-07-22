// Mouse wheel support under Windows

#if WINTTDX

#include <std.inc>
#include <proc.inc>
#include <flags.inc>
#include <window.inc>
#include <view.inc>
#include <ptrvar.inc>
#include <misc.inc>

extern FindTopmostWindowAtXY,FindWindow,RefreshWindowArea,mousewheelsettings
extern patchflags
extern windowstretchinv


ptrvar window2ofs


#define WHEEL_DELTA 120

uvard wheeldelta
uvard lastwheelpos,2

#define LastWheelX lastwheelpos
#define LastWheelY (lastwheelpos+4)

uvarb wheelhandled

uvard ScreenToClient

uvard wheelscrollines

uvard wheel_msg		// number of wheel message for legacy drivers

uvarb mbutton		// was wheel button instead

// called in the window procedure instead of a cmp
// capture mouse wheel messages and store their data
// in:	[ebp-38h]: message identifier
//	[ebp+08h]: window handle
//	[ebp+10h]: wParam of message
//	[ebp+14h]: lParam of message
// safe: edi,esi,ebx,eax
global handlemouseeventmsgs
handlemouseeventmsgs:
	mov eax,[ebp-0x38]
	mov ebx,[wheel_msg]
	or ebx,ebx
	jz .nolegacy

	cmp eax,ebx
	jne .nolegacy

// The only difference between legacy messages and WM_MOUSEWHEEL is that
// the whole wParam is used instead of just the high word, so after loading
// the movement value, the same code can be used for both cases
	mov eax,[ebp+0x10]
	jmp short .legacywheel

.nolegacy:
	cmp eax,0x20a			// WM_MOUSEWHEEL
	je .wheel
	
	cmp eax,0x207			// WM_MBUTTONDOWN
	je .mbutton

	cmp eax,0x30f			// WM_QUERYNEWPALETTE, overwritten
	ret

.mbutton:
	mov byte [mbutton],1
	pop eax				// remove return address again
	mov eax,[ebp+0x14]
	movzx ebx,ax			// WM_MWHEELDOWN sends coordinates relative to the client area.
	mov [LastWheelX],ebx
	shr eax,16
	mov [LastWheelY],eax
	jmp short .notwheel
	
.wheel:
	mov eax,[ebp+0x10]		// save message data
	sar eax,16
.legacywheel:
	add [wheeldelta],eax
	pop eax				// remove our return address - we'll jump back to TTD code
	mov eax,[ebp+0x14]		// the message contains screen coordinates,
	movzx ebx,ax			// but we need client coordinates, call
	mov [LastWheelX],ebx		// a Windows function to convert
	shr eax,16
	mov [LastWheelY],eax
	push lastwheelpos
	push dword [ebp+8]
	call [ScreenToClient]
.notwheel:
	testflags stretchwindow
	jnc .notstretched
	mov eax,[LastWheelX]
	imul eax,[windowstretchinv]
	shr eax,16
	mov [LastWheelX],eax
	mov eax,[LastWheelY]
	imul eax,[windowstretchinv]
	shr eax,16
	mov [LastWheelY],eax
.notstretched:
	xor eax,eax			// signal that the message is handled
	mov ebx,0x40e63c
	jmp ebx

uvarb wheeldir		// 0-up 1-down

// Called instead of a "jnc near..." jumping to a ret in DoAllPlayerActions
// Process stored wheel movements here if necessary
global processmouseevents
processmouseevents:
	pushf
	pusha

	cmp byte [demomode],0			// no wheel during demos
	je .processwheeldelta

	mov dword [wheeldelta],0
	mov byte [mbutton],0
	jmp short .nomove

// According to Microsoft, we should notice wheel rolls only when
// their accumulated absolute value reaches WHEEL_DELTA
// Call the wheel handler until the absolute value of wheeldelta
// drops below WHEEL_DELTA
.processwheeldelta:
	cmp dword [wheeldelta],WHEEL_DELTA
	jl .notup

	mov byte [wheeldir],0
	call wheelmove
	sub dword [wheeldelta],WHEEL_DELTA
	jmp short .processwheeldelta
.notup:

	cmp dword [wheeldelta],-WHEEL_DELTA
	jg .notdown

	mov byte [wheeldir],1
	call wheelmove
	add dword [wheeldelta],WHEEL_DELTA
	jmp short .processwheeldelta

.notdown:
	cmp byte [mbutton], 0
	je .nomove
	call wheelclick

.nomove:
	popa
	popf
	jc .noexit
	add esp,4
.noexit:
	ret


wheelclick:
	mov byte [mbutton], 0
	mov byte [wheeldir], cWinEventWheelClick-cWinEventWheelUp

wheelmove:
	mov eax,[LastWheelX]		// first of all, find which window received
	mov ebx,[LastWheelY]		// the scrolling
	call [FindTopmostWindowAtXY]
	or esi,esi
	jnz .continue
	ret

.continue:
// We give a chance to the window to handle the scrolling itself
// by sending it a cEventWheelUp or cEventWheelDown message.
// Since unpatched windows don't even know this message, it
// is considered handled only if the window handler sets
// wheelhandled to a nonzero value

	mov byte [wheelhandled],0

	mov cx,bx
#if 0
	push esi
	mov edi,esi
	mov dl,cWinEventWheelUp
	add dl,[wheeldir]
	mov si,[edi+window.opclassoff]
	cmp si,-1
	je .plaincall

	movzx esi,si
	mov ebx,[edi+window.function]
	mov ebp,[ophandler+esi]
	call dword [ebp+4]
	jmp short .calldone

.plaincall:
	call dword [edi+window.function]

.calldone:
	pop esi
#else 
	mov edi,esi
	mov dl,cWinEventWheelUp
	add dl,[wheeldir]
	extcall GuiSendEventEDI
#endif
	cmp byte [wheelhandled],0
	jne .exit2

	cmp byte [wheeldir], cWinEventWheelClick-cWinEventWheelUp
	jne .notmbutton


// The window didn't handle the middle click. Shade the window if clicked on the titlebar.
	extcall WindowCanSticky
	jc .exit2
extern WindowClicked
	call [WindowClicked]
	js .exit2
	movzx ecx, cl
	imul ecx,windowbox_size
	add ecx,[esi+window.elemlistptr]
	cmp byte [ecx+windowbox.type], cWinElemTitleBar
	jne .exit2
	mov ebx, RefreshWindowArea
	mov eax, ShadedWinHandler
	cmp [esi+window.function], eax
	jne .shade

.unshade:
	mov eax, [esi+window2ofs+window2.height]	// also window2.opclassoff
	mov [esi+window.height], eax			// also window.opclassoff

	mov eax, [esi+window2ofs+window2.function]
	mov [esi+window.function],eax

	cmp byte [esi+window.type], cWinTypeFinances
	jne .uns_notfinances
	add word [esi+window.width], 14

.uns_notfinances:
	jmp [ebx]					// RefreshWindowArea

.shade:
	call [ebx]					// RefreshWindowArea
	//mov eax, ShadedWinHandler
	xchg eax, [esi+window.function]
	mov [esi+window2ofs+window2.function], eax

	mov eax, 0xFFFF000E
	xchg eax, [esi+window.height]			// also window.opclassoff
	mov [esi+window2ofs+window2.height], eax	// also window2.opclassoff

	cmp byte [esi+window.type], cWinTypeFinances
	jne .shd_notfinances
	sub word [esi+window.width], 14

.shd_notfinances:
.exit2:
	ret

.notmbutton:

// The window didn't handle the scrolling itself - we try the
// default behaviour: if the window has a scroll bar, it
// is scrolled up or down. Windows without scroll bars ignore
// the mouse wheel.

	mov eax,[esi+window.elemlistptr]
	or eax,eax
	jz .exit

// try to find a scroll bar among window elements
.nextbox:
	mov ebx,[eax+windowbox.type]
	cmp bl,cWinElemLast	// no scroll bar - exit
	je .exit
	cmp bl,cWinElemSlider
	je .defaultscroll
	add eax,windowbox_size
	jmp short .nextbox

// the window can be scrolled - adjust itemsoffset if possible
// and redraw the window
.defaultscroll:
// According to MS, if the user's wheel scroll setting is more than the
// count of visible items, we should scroll a page instead. This also
// works if the user selected the "scroll whole page" option because
// it sets wheelscrollines to MAXINT.
	movzx ebx,byte [esi+window.itemsvisible]
	mov eax,[wheelscrollines]
	cmp eax,ebx
	jb .notpage
	mov eax,ebx
.notpage:
	movzx ebx,byte [esi+window.itemsoffset]
	cmp byte [wheeldir],0
	jne .down

	sub ebx,eax
	jmp short .checkneg

.down:
	add ebx,eax
	mov eax,ebx
	movzx ecx,byte [esi+window.itemsvisible]
	add eax,ecx
	cmp eax,255
	ja .toomuch
	cmp al,[esi+window.itemstotal]
	jbe .nottoomuch
.toomuch:
	movzx ebx,byte [esi+window.itemstotal]
	sub ebx,ecx
.nottoomuch:
.checkneg:
	or ebx,ebx
	jns .setit
	xor ebx,ebx
.setit:
	mov [esi+window.itemsoffset],bl

	call [RefreshWindowArea]

.exit:
	ret

extern currscreenupdateblock

ShadedWinHandler:
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

	mov ebx, [currscreenupdateblock]
	mov word [ebx+scrnblockdesc.height], 14

	call .callreal

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


// Called instead of a near jump in the handler of the main window
// Capture mouse wheel events and zoom the view according to them
// If bit 2 of the flags, two consecutive rolls in the
// same direction within 7 ticks (approx. 200 ms) is needed to
// trigger zoom
// If bit 1 of the flags is set, we mimic OpenTTD's wheel handling,
// trying to keep the landscape point the mouse points to at the same place.
// If it's clear, we zoom to the center of the screen
global mainwindowhandler
mainwindowhandler:
	pop ecx
	jne .notredraw	// recreate the conditional jump we've overwritten
	sub ecx,409
	jmp ecx

.notredraw:
// reset roll count (stored in itemsoffset) if the 7 ticks elapsed
	cmp dl,cWinEventSecTick
	jne .nottimer
	mov byte [esi+window.itemsoffset],0
	ret

.nottimer:
	cmp dl,cWinEventWheelUp
	jb .nearexit
	cmp dl,cWinEventWheelDown
	ja .nearexit

	mov byte [wheelhandled],1
// find out which toolbar buttons to disable if necessary
// also cancel zooming on the title screen
	mov cl,[gamemode]
	or cl,cl
	jz .nearexit
	cmp cl,1
	jne .scenedit
	mov cl,16
	jmp short .continue

.nearexit:
	ret

.scenedit:
	mov cl,8

.continue:
	movzx ecx,cl
// Find the main toolbar window
	push edx
	push ecx
	mov edi,esi
	mov cl,1
	xor dx,dx
	call [FindWindow]
	xchg edi,esi
	pop ecx
	pop edx

	or byte [esi+window.flags],7		// set up timer
	mov ebp,[esi+window.viewptr]
	sub ax,[ebp+view.scrx]			// create view-relative coordinates from screen-relative ones
	sub bx,[ebp+view.scry]			// (if OTTD-zoom is disabled, the registers will be overwritten)
	cmp dl,cWinEventWheelUp
	jne .down
// if the corresponding flag is enabled, don't do anything if this isn't the second roll up
	test byte [mousewheelsettings],2
	jz .continueup
	inc byte [esi+window.itemsoffset]
	cmp byte [esi+window.itemsoffset],2
	jl .nearexit
// we should zoom the view in
.continueup:
	cmp word [ebp+view.zoomlevel],0
	je .nearexit
	dec word [ebp+view.zoomlevel]
	sar word [ebp+view.width],1
	sar word [ebp+view.height],1
	test byte [mousewheelsettings],1
	jnz .ottdzoomin

// normal zooming - shift the view by one quarter of the old size
	mov ax,[ebp+view.width]
	mov bx,[ebp+view.height]
	shr ax,1
	shr bx,1
	jmp short .dozoomin

.ottdzoomin:
// OTTD zoom - shift the view by the mouse coordinates if zooming to level 0 or twice of them if zooming to level 1
	cmp word [ebp+view.zoomlevel],1
	jne .dozoomin
	shl ax,1
	shl bx,1
	
.dozoomin:
// shift the view by the calculated coordinates
	add [esi+window.data+2],ax
	add [esi+window.data+4],bx
// disable "zoom in button" if we're at level 0 - enable both zoom buttons otherwise
	btr dword [edi+window.disabledbuttons],ecx
	cmp word [ebp+view.zoomlevel],0
	jne .nodisable
	bts dword [edi+window.disabledbuttons],ecx

.nodisable:
	inc ecx
	btr dword [edi+window.disabledbuttons],ecx
	jmp short .redraw

.down:
// if the corresponding flag is enabled, don't do anything if this isn't the second roll down
	test byte [mousewheelsettings],2
	jz .continuedown
	dec byte [esi+window.itemsoffset]
	cmp byte [esi+window.itemsoffset],-2
	jg .exit
// same as above, but for zooming out
.continuedown:
	cmp word [ebp+view.zoomlevel],2
	je .exit
	inc word [ebp+view.zoomlevel]
	test byte [mousewheelsettings],1
	jnz .ottdzoomout

	mov ax,[ebp+view.width]
	mov bx,[ebp+view.height]
	shr ax,1
	shr bx,1
	jmp short .dozoomout

.ottdzoomout:
	cmp word [ebp+view.zoomlevel],2
	jne .dozoomout
	shl ax,1
	shl bx,1

.dozoomout:
	shl word [ebp+view.width],1
	shl word [ebp+view.height],1
	sub [esi+window.data+2],ax
	sub [esi+window.data+4],bx
	btr dword [edi+window.disabledbuttons],ecx
	inc ecx
	btr dword [edi+window.disabledbuttons],ecx
	cmp word [ebp+view.zoomlevel],2
	jne .redraw
	bts dword [edi+window.disabledbuttons],ecx

.redraw:
// refresh both the toolbar and the main view
	xchg esi,edi
	call [RefreshWindowArea]
	xchg esi,edi
	call [RefreshWindowArea]
	mov byte [esi+window.itemsoffset],0
	
.exit:
	ret

uvard currmapmode

global mapwindowhandler
mapwindowhandler:
	mov bx,cx		// overwritten
	mov esi,edi		// ditto
	cmp dl,cWinEventWheelUp
	je .up
	cmp dl,cWinEventWheelDown
	je .down
	cmp dl,cWinEventRedraw
	ret

.up:
	mov eax,[currmapmode]
	xor ecx,ecx
	mov cl,[eax]
	dec cl
	jns .gotnewmode
	mov cl,5
	jmp short .gotnewmode

.down:
	mov eax,[currmapmode]
	xor ecx,ecx
	mov cl,[eax]
	inc cl
	cmp cl,5
	jbe .gotnewmode
	xor cl,cl
.gotnewmode:
	and dword [esi+window.activebuttons], ~0x7e0
	add cl,5
	bts dword [esi+window.activebuttons],ecx
	sub cl,5
	mov [eax],cl
	pop eax
	mov byte [wheelhandled],1
	jmp dword [RefreshWindowArea]

#endif
