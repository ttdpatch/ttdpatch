#if WINTTDX

#include <defs.inc>
#include <frag_mac.inc>
#include <proc.inc>
#include <window.inc>
#include <win32.inc>
#include <patchproc.inc>

patchproc mousewheel, patchmousewheel

extern FindTopmostWindowAtXY,currmapmode,ScreenToClient,user32hnd
extern wheel_msg,wheelscrollines,mousewheelsettings

#if 0
%macro errmsg 2
	j%-1 %%skip
	pusha
	push 0
	push 0
	push %2
	push 0
	call dword [MessageBoxA]
	popa
	jmp .normalwheel

%%skip:
%endmacro

var nowindow, db "No wheel window found",0
var nosupportmsg, db "Failed to obtain MSG_WHEELSUPPRT message",0
var wheeldisabled, db "Wheel support present but disabled",0
var nowheelmsg, db "Failed to obtain roll message",0
var legacyok, db "Legacy mouse support installed OK",0
#endif

proc patchmousewheel
	local RegisterWindowMessageA,MouseZ_handle

	_enter

	//install mouse wheel capture fragments
	mov edi,0x40e5db
	storefragment newhandlemouseeventmsgs
	patchcode oldprocessmouseevents,newprocessmouseevents,2,2
	storeaddress findFindTopmostWindowAtXY,1,1,FindTopmostWindowAtXY
	patchcode oldmainwindowhandler,newmainwindowhandler,1,1
	storeaddresspointer findcurrentmapmode,1,6,currmapmode
	patchcode oldmapwindowhandler,newmapwindowhandler,1,1
	pusha
	push dword aScreenToClient
	push dword [user32hnd]
	call dword [GetProcAddress]	// GetProcAddress(user32,"ScreenToClient")
	mov [ScreenToClient],eax

	test byte [mousewheelsettings],4
	jz near .normalwheel

// Check for old-style (rather hack-ish) mouse wheel handling that
// was used by old IntelliMouse drivers (and apparently others as well)
// because WM_MOUSEWHEEL was introduced only in Win98 and NT 4.0
//
// It consists of an invisible window that can be asked if the wheel is
// available and how many lines it scrolls, and three system-wide
// messages whose actual numbers can be queried by RegisterWindowMessage:
//
// "MSWHEEL_ROLLMSG": notification about the user rolling the wheel
//	lParam:	position of the pointer (x in low word, y in high word)
//	wParam: amount of rolling (signed)
//
// "MSH_WHEELSUPPORT_MSG": can be sent to the invisible window to ask
//	if the wheel is available. Returns a nonzero value if it is.
//	lParam,wParam ignored
//
// "MSH_SCROLL_LINES_MSG": can be sent to the invisible window to
//	ask how many lines a wheel movement should scroll. Returns
//	the number of lines.
//	lParam,wParam ignored
//
// If anything goes wrong while trying to detect this setup, we fall back
// to the default handling, assuming that no legacy drivers are present

// First try to find the invisible wheel window - if it's not present,
// it's very likely that no legacy drivers are present
	push aMouseZTitle
	push aMouseZClassName
	call [FindWindowA]
	or eax,eax
	jz .normalwheel
//	errmsg z,nowindow
	mov [%$MouseZ_handle],eax

// now, get the address of RegisterWindowMessageA
	push dword aRegisterWindowMessageA
	push dword [user32hnd]
	call dword [GetProcAddress]
	mov [%$RegisterWindowMessageA],eax

// ask if wheel is actually present
	push aMSH_WHEELSUPPORT
	call eax	// eax still points to RegisterWindowMessageA
	or eax,eax
	jz .normalwheel
//	errmsg z,nosupportmsg

	push eax	// "push eax" is one byte smaller than "push 0", and this parameter is ignored anyway
	push eax
	push eax
	push dword [%$MouseZ_handle]
	call [SendMessageA]
	or eax,eax
	jz .normalwheel	// it's disabled, but falling back to default handling won't hurt anyway
//	errmsg z,wheeldisabled

// We have a working wheel, so it's now worth asking the wheel message
	push aMSH_MOUSEWHEEL
	call [%$RegisterWindowMessageA]
	or eax,eax
	jz .normalwheel
//	errmsg z,nowheelmsg
	mov [wheel_msg],eax

// now try to get the scroll line setting
// this isn't crucial, so assume 3 on error

//	push 0
//	push 0
//	push legacyok
//	push 0
//	call [MessageBoxA]
	mov dword [wheelscrollines],3

	push aMSH_SCROLL_LINES
	call [%$RegisterWindowMessageA]
	or eax,eax
	jz .hasscrollines

	push eax
	push eax
	push eax
	push dword [%$MouseZ_handle]
	call [SendMessageA]
	mov [wheelscrollines],eax
	jmp short .hasscrollines	

.normalwheel:
// Default mouse wheel handling, supported since Win98 and NT 4.0
//
// The OS sends a WM_MOUSEWHEEL message to the active window when
// the wheel is rolled, with the following parameters:
//	low word of wParam:	flags for some modifiers ( ctrl, shift, mouse buttons)
//	high word of wParam:	amount of rolling (signed)
//	lParam:			position of pointer (y in high word, x in low word)
//
// the scroll line setting can be queried by calling SystemParametersInfo

	push dword aSystemParametersInfoA
	push dword [user32hnd]
	call dword [GetProcAddress]	// GetProcAddress(user32,"aSystemParametersInfoA")
	push 0
	push wheelscrollines
	push 0
	push 104			// SPI_GETWHEELSCROLLLINES
	call eax
	or eax,eax
	jne .hasscrollines
	mov dword [wheelscrollines],3
.hasscrollines:
	popa
	_ret
endproc

aScreenToClient: db "ScreenToClient",0
aSystemParametersInfoA: db "SystemParametersInfoA",0
aRegisterWindowMessageA: db "RegisterWindowMessageA",0

aMouseZClassName: db "MouseZ",0
aMouseZTitle: db "Magellan MSWHEEL",0

aMSH_MOUSEWHEEL: db "MSWHEEL_ROLLMSG",0
aMSH_WHEELSUPPORT: db "MSH_WHEELSUPPORT_MSG",0
aMSH_SCROLL_LINES: db "MSH_SCROLL_LINES_MSG",0

begincodefragments

// no codefragment oldhandlemouseeventmsgs - the offset is the same in all Win versions

codefragment newhandlemouseeventmsgs
	call runindex(handlemouseeventmsgs)
	setfragmentsize 7

codefragment oldprocessmouseevents,38
	xor ax,ax
	mov cx,ax
	mov bl,1
	mov esi,0x30038

codefragment newprocessmouseevents
	call runindex(processmouseevents)

codefragment findFindTopmostWindowAtXY,-15
	jb $+2+0x25
	mov dx,[esi+window.x]

codefragment oldmainwindowhandler,8
	mov bx, cx
	mov esi, edi
	cmp dl, cWinEventRedraw
	jz near $+6-409
	retn

codefragment newmainwindowhandler
	call runindex(mainwindowhandler)

codefragment findcurrentmapmode,14
	and dword [esi+window.activebuttons],~0x7e0

codefragment oldmapwindowhandler,13
	shr bx,1
	add bx,word [esi+window.y]

codefragment newmapwindowhandler
	call runindex(mapwindowhandler)
	setfragmentsize 8

endcodefragments
#endif

