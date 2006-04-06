
// Changable gamespeed -- by Sander van Schouwenburg
//
// Todo:
//  v non-miscmods 8192 support
//  * dynamic keys -- Pg Up/Pg Dn support
//  v dynamic speeds (i.e.: more than just double/normal)

#include <std.inc>
#include <textdef.inc>
#include <misc.inc>

extern drawrighttextfn,drawtextfn,invalidatehandle


// NOTE: most part of this patch is applied in the 'generalfixes' (in win2k.asm)
// and the 'hotkeys' patch. Therefore this file is quite empty.

var waittimes
	db GS_WAITBASE*8,GS_WAITBASE*4,GS_WAITBASE*2,GS_WAITBASE*1
	db GS_WAITBASE/2,GS_WAITBASE/4,0

GS_FACTORS equ (addr($)-waittimes)	// amount of speed factors

uvarb currwaitfactor
uvard currwaittime

#if !WINTTDX
uvard waitforretrace
#endif

// Show the current speed near the date display
// in:	arguments for call DrawCenteredText to display date
// out:	same
// safe:---
global showgamespeed
showgamespeed:
	pusha
	mov al,0x16	// red
	movzx ebx,byte [currwaitfactor]
	cmp ebx,0+GS_DEFAULTFACTOR
	je .done
	jb .left
	add cx,0x40
	add bx,statictext(gamespeed0)
	call [drawrighttextfn]
	jmp short .done
.left:
	sub cx,0x40
	add bx,statictext(gamespeed0)
	call [drawtextfn]
.done:
	popa
	ret


// Alternative to the waitloop defined in win2k.asm
// Used when miscmods 8192 is set, or when generalfixes is turned off
global dynwaitloop
dynwaitloop:
	mov ebx, eax
	sub eax, [dword 0]
ovar dynprevtickcount, -4
	cmp eax, [currwaittime]
	retn


// Called when changing gamespeed
//
// in:	ecx=+1, -1
// out:	---
// safe:bl esi
global setgamespeed,setgamespeed.set
setgamespeed:
	add cl,[currwaitfactor]
	js .toosmall

	cmp cl, GS_FACTORS-1
	jb .set

#if WINTTDX
	mov dword [0x407ee8],0xe900768d		// 3-byte nop, 1-byte jmp we don't want to overwrite
#else
	mov esi,[waitforretrace]
	mov byte [esi+1],0
	mov byte [esi+6],0
#endif
	mov cl, GS_FACTORS-1
	jmp short .setmax

.toosmall:
	mov cl,0

.set:
#if WINTTDX
	mov dword [0x407ee8],0xe95850ff		// call [eax+58h], 1-byte jmp we don't want to overwrite
#else
	mov esi,[waitforretrace]
	mov byte [esi+1],0xfb
	mov byte [esi+6],0xfb
#endif

.setmax:
	mov [currwaitfactor], cl
	mov bl, [waittimes+ecx]
	mov byte [currwaittime], bl

	pusha
	mov ax,0x82
	xor ebx,ebx
	call [invalidatehandle]
	popa
	ret
