// Maintainer Oskar
// -------------------------------------------
// hotkey table init for hotkey function
// -------------------------------------------

#include <std.inc>
#include <flags.inc>
#include <textdef.inc>
#include <window.inc>

extern FindWindow,errorpopup,hexdigits,patchflags,redrawscreen,setgamespeed
extern setgamespeed.set,specialerrtext1
extern texthandler




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

#define HT_TABLESIZE 24

//		  0  1    2    3     4   5   6789   01234567890123
// hotkeylist db 'x',0xFF,0xFF,0xFF,'!','"',"§$t%","1234567890-=~]",0,0
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
