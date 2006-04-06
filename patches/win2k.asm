//
// Windows 2000 patches
//

#if WINTTDX

#include <std.inc>
#include <proc.inc>
#include <flags.inc>
#include <veh.inc>
#include <win32.inc>

extern SetStretchBltMode,Sleep
extern StretchBlt,currwaittime,isbadreadptr,kernel32hnd
extern noprevexceptionhandler,patchflags
extern prevexceptionhandler,spriteerror,spriteerrortype,win2kexceptionhandler
extern windowsize


global alignedint21handler
alignedint21handler:

	push	ebp
	mov	ebp,esp
	and	esp, byte ~ 3	// aligned esp on a 4 byte boundry

	cmp	ax,0x4200
	jne	short .normalint21
	call	$
ovar int21seekfrombegin,-4

	jmp	short .restoresp

.normalint21:
	call	$
ovar int21restofhandler,-4

.restoresp:
	leave
	ret
; endp alignedint21handler

global alignedplaysound
alignedplaysound:

	push	ebp
	mov	ebp,esp
	and	esp, byte ~ 3	// aligned esp on a 4 byte boundry

	push	ecx
	push	ebx
	push	eax
	call	$		// will be modified in init.ah
ovar savedplaysound,-4

	pop	eax
	pop	ebx
	pop	ecx

	leave
	ret
; endp alignedplaysound 

var savedsendstring,	dd 0
global alignedsendstring
alignedsendstring:
	push	ebp
	mov	ebp,esp
	and	esp, byte ~ 3	// aligned esp on a 4 byte boundry

	push	dword [ebp+0x14]
	push	dword [ebp+0x10]
	push	dword [ebp+0xC]
	push	dword [ebp+0x8]
	call	dword [savedsendstring]

	leave
	ret
; endp alignedsendstring

// similar as above, but using dxmci.dll and checking for errors
calldxmciSendString:
	push dword [esp+0x10]
	push dword [esp+0x10]
	push dword [esp+0x10]
	push dword [esp+0x10]
	call [dxmciSendString]
	add esp,0x10

	push eax
	mov eax,[dxmcierrptr]
	test eax,eax
	jz .nodxmcierr

	mov eax,[eax]
	test eax,eax
	jz .nodxmcierr

	and dword [dxmcierrptr],0	// show message only once

	mov [dxmcierr],eax

	// use grf error system, bit 30 marks it as "not really graphics error"
	mov dword [spriteerror],dxmcierr
	mov byte [spriteerrortype],1

.nodxmcierr:
	pop eax
	ret


var aPlaying,        db 'playing',0
var aSeeking,        db 'seeking',0
var savedstrcmp,     dd 0

global strcmpplayingseeking
strcmpplayingseeking:

	push	aPlaying
	lea	eax, [ebp-0x100]
	push	eax
	call	$
ovar savedstrcmp1,-4
	add	esp,byte 8
	test	eax, eax
	jz	short .wereplaying
	push	aSeeking
	lea	eax, [ebp-0x100]
	push	eax
	call	$
ovar savedstrcmp2,-4
	add	esp,byte 8
	
.wereplaying:
	ret

; endp strcmpplayingseeking 

// called when setting up a vehicle window
// need to clear the higher bits of EDX, they're garbage
// (probably because some 2000/XP function doesn't preserve EDX)
global setupvehwindow
setupvehwindow:
	movzx edx,dx
	mov eax,edx
	shl eax,vehicleshift
	ret
; endp setupvehwindow

#ifdef LOGDX
var dxlogfilename, db "dxlog.dat",0
#endif

align 4

#ifdef LOGDX
var dxlogfile, dd -1
var dxlogrecord
	var dxlogtime, dd -1		// Time of method call
	var dxlogfrom, dd -1		// Origin of method call
	var dxlogobj, dd -1		// Object variable pointer
	var dxlogofs, dd -1		// Method offset
	var dxlogmethod, dd -1		// Method pointer
	var dxlogstacksize, dd -1	// Size of stack for method call
	var dxlogresult, dd -1		// Method call result (in eax)
%define dxlogparamsize 16		// copy up to 16 DWORD params
	var dxlogparam, times dxlogparamsize dd -1	// parameters on stack

dxlogsize equ addr($)-dxlogrecord
#endif

// called when TTD waits for a 27 ms interval to expire
// in:	eax = new tick count (milliseconds)
// out:	ebx=eax, eax-old tick count, edx=0, flags = cmp eax,[currwaittime]
global waitloop
waitloop:
	mov ebx,eax

	sub eax,[dword 0]
ovar prevtickcount,-4
	push eax

	mov ecx, 0x1b
	testmultiflags gamespeed
	jz .fixedspeed
	mov ecx, [currwaittime]
.fixedspeed:

	sub eax, ecx
	jnl short .done

	pusha

	// need to wait -eax more milliseconds
	neg eax
	push eax
	call dword [Sleep]

	popa

.done:
	pop eax
	cmp eax, ecx	// it didn't fit in the replaced code
	ret

; endp waitloop 

// called when TTD checks how many ticks it has been since the
// last time checked (by dividing the waited time by the time per tick)
// in: eax = time since last tick
// out: eax = number of ticks waited (should be 1, but can be more on slow
//            processors)
global tickcheck
tickcheck:
	xor edx,edx
	mov ebx, [currwaittime]
	test ebx,ebx
	jz .done
	div ebx
.done:
	ret

; endp tickcheck

// don't need this anymore
#if 0
	// now fix all DirectX method calls
	// we don't want these to be recorded as there are far
	// too many, so save EDX and reset it every time
fixdirectxmethodcalls:
	push edx
	push dword [currentversion+versionoffsets+0*4]
	push dword [findstring]

		// always do string search
	mov dword [findstring],addr(dofindstring)

	xor edi,edi

.nextdplaymethod:
	xor edx,edx

	stringaddress olddxmethodcall,1,0
	or edi,edi
	jns short .fixthis
.dxdone:
	pop dword [findstring]
	pop dword [currentversion+versionoffsets+0*4]
	pop edx

#ifdef LOGDX
	pusha
	mov edx,dxlogfilename
	mov ax,0x3c00
	CALLINT21		// open for writing
	jc near $+0x7000000-addr($)
	cwde
	mov [dxlogfile],eax
	popa
#endif

	ret

.fixthis:
	mov al,[edi-1]	// the offset into the method table

	mov esi,addr(newdxmethodcall_end)
	mov cl,newdxmethodcall_end - newdxmethodcall_start

	//
	// see which type of call it is, either:
	// 8B 80 xx xx xx xx	MOV EAX,[EBP+xxxxxxxx]
	// or
	// A1 xx xx xx xx	MOV EAX,[xxxxxxxx]
	// or
	// 8B 04 81		MOV EAX,[ECX+4*EAX]
	// all of them are followed by
	// 8B 00		MOV EAX,[EAX]
	// FF 50 xx		CALL DWORD PTR [EAX+xx]
	//
	// either way we're interested in EAX, which is already on
	// the stack.  We just need to replace the last MOV as well
	// as the following "MOV EAX,[EAX]" and "CALL [EAX+ofs]" with
	// "PUSH ofs" and "CALL runindex(dxmethodcall)".
	//
	// (We could just replace the final CALL, but we need to store
	// the offset in the call, and there aren't enough bytes for that.)
	//

	cmp word [edi-11],0x808b
	je short .directcall

	cmp byte [edi-10],0xa1
	jne short .shortcall

.mediumcall:
	mov cl,newdxmethodcall_end - newdxmethodcall_medium
	jmp short .directcall

.shortcall:
	// it's an indirect call, we need to skip the nops in the replacement
	mov cl,newdxmethodcall_end - newdxmethodcall_short

.directcall:
	sub esi,ecx
	sub edi,ecx

	// now we're pointing right, copy.
	rep movsb

	// and remember the method table offset
	mov byte [edi+methodcallofs-addr(newdxmethodcall_end)],al
	jmp .nextdplaymethod
; endp fixdirectxmethodcalls


align 4

#define DXNUMCOPYARG 16

var dxmethodofs, dd -1
var dxoldesp, dd -1
var dxtempa, dd -1
var dxtempb, dd -1
var dxtempc, dd -1


// call a DirectX method
// make sure that ESP is DWORD aligned
// if not, we'll have to do it manually... ugh.
//
// when we come here, the stack is such:
//	[esp+8]	Method table pointer
//	[esp+4]	Offset into method table
//	[esp]	Return address
dxmethodcall:
	mov eax,[esp+8]		// pointer to method table
#ifdef LOGDX
	mov [dxlogobj],eax
#endif
	mov eax,[eax]		// method table itself
	add eax,[esp+4]		// offset into method table
	mov eax,[eax]		// now eax=method offset
#ifdef LOGDX
	mov [dxlogmethod],eax
#endif
	mov dword [dxmethodofs],eax
#ifdef LOGDX
	mov eax,[esp+4]
	mov [dxlogofs],eax
#endif


	pop eax			// get return code
	mov [esp],eax		// and store it again at the new esp

#ifdef LOGDX
	sub eax,3
	mov [dxlogfrom],eax
#endif

	mov eax,esp
	test al,3
	mov eax,[eax+4]		// now this is the method table pointer

#ifdef LOGDX
	jmp short .difficultcall	// to check return code
#else
	jnz short .difficultcall
#endif

	// easy call; it's already aligned
	jmp dword [dxmethodofs]

.difficultcall:
	// we need to align the stack... brr...

	mov dword [dxoldesp],esp
	mov dword [dxtempa],esi
	mov dword [dxtempb],edi
	mov dword [dxtempc],ecx

	// these calls can have up to 10 DWORDs as arguments
	// we'll go safe and copy 16 (stored in dxtempc)
	// this won't be the fastest; but who'll notice?

	mov esi,esp
	and esp,byte ~ 3
	sub esp,byte DXNUMCOPYARG*4
	mov edi,esp
	mov ecx,DXNUMCOPYARG
	cld
	rep movsd

	mov esi,dword [dxtempa]
	mov edi,dword [dxtempb]
	mov ecx,dword [dxtempc]

	pop dword [dxtempc]	// return address
	mov dword [dxtempb],esp	// store esp, so we can see how many bytes
				// the method removes from the stack

#ifdef LOGDX
	// copy to log record
	pusha
	mov esi,[dxtempb]
	mov edi,dxlogparam
	mov ecx,dxlogparamsize/4
	rep movsd
	popa
#endif

	// ok, now the stack is prepared
	call dword [dxmethodofs]
	
#ifdef LOGDX
	pusha
	mov [dxlogresult],eax
	mov eax,esp
	sub eax,[dxtempb]
	mov [dxlogstacksize],eax

	call dword [GetTickCount]
	mov [dxlogtime],eax

	mov ah,0x40		// write to file
	mov ebx,[dxlogfile]
	mov edx,dxlogrecord
	mov ecx,dxlogsize
	CALLINT21
	lea ebx,[eax+0x70000010+(dxlogsize<<16)]
	cmp eax,ecx
	je .ok
	jmp ebx
.ok:
	jc near $+0x7000002-addr($)
	popa
#endif

	xchg eax,dword [dxtempb]

	// and now we have to restore the stack, but fortunately we only
	// adjust esp minus the bytes we need to remove afterwards

	sub esp,eax		// this is how many bytes were removed

	add esp,dword [dxoldesp]
	mov eax,[dxtempc]
	mov [esp],eax		// restore return address
//	add esp,byte 4		// the return address is no longer on the stack

	mov eax,dword [dxtempb]
	ret
//	jmp dword [dxtempc]
; endp dxmethodcall

#endif

//
// DirectX midi patches
//

var adxmcimidi_dll,	db 'dxmci.dll',0

var aDxMidiGetVolume,	db 'dxMidiGetVolume',0
var aDxMidiSetVolume,	db 'dxMidiSetVolume',0
var aDxMidiSendString,	db 'dxMidiSendString',0
var aDxGetdxmcierrPtr,	db 'dxGetdxmcierrPtr',0

uvard lDxMciMidi
uvard dxmcierrptr
uvard dxmcierr
uvard dxmciSendString

global initdxmidi
initdxmidi:

	// this code runs inside of the dopatchcode macro, so old rules apply, don't change ecx, edx or ebp
	push	ecx
	push	edx

	push	adxmcimidi_dll
	call	dword [LoadLibrary] // LoadLibrary("DXMCIMIDI")
	test	eax,eax
	jz	dxmidifailed
	mov	dword [lDxMciMidi], eax
	// we should be freeing this handle when the game exits,
	// does it really matter, because windows does clean up after us

	push	aDxMidiGetVolume
	push	dword [lDxMciMidi]
	call	dword [GetProcAddress] // GetProcAddress(lDxMciMidi, "aDxMidiGetVolume")
	mov	dword [midiOutGetVolume], eax

	push	aDxMidiSetVolume
	push	dword [lDxMciMidi]
	call	dword [GetProcAddress] // GetProcAddress(lDxMciMidi, "aDxMidiSetVolume")
	mov	dword [midiOutSetVolume], eax

	push	aDxMidiSendString
	push	dword [lDxMciMidi]
	call	dword [GetProcAddress] // GetProcAddress(lDxMciMidi, "dxMidiSendString")
	mov	dword [dxmciSendString], eax
	mov	dword [mciSendString],eax

	push	aDxGetdxmcierrPtr
	push	dword [lDxMciMidi]
	call	dword [GetProcAddress] // GetProcAddress(lDxMciMidi, "dxGetdxmcierrPtr")

	// this fails for older dxmci.dll versions, don't call it without checking
	test eax,eax
	jz .nodxmcierr

	call eax

	mov	dword [mciSendString],addr(calldxmciSendString)

.nodxmcierr:
	mov [dxmcierrptr], eax


dxmidifailed:
	pop	edx
	pop	ecx

	ret

;  endp initdxmidi


var aSetUnhandledExceptionFilter, db "SetUnhandledExceptionFilter",0
var aIsBadReadPtr, db "IsBadReadPtr",0

	// set up an exception handler for windows that
	// records more useful crash logs using catchgpf.asm
global setexceptionhandler
setexceptionhandler:
	push edx

	push aIsBadReadPtr
	push dword [kernel32hnd]
	call dword [GetProcAddress]	// GetProcAddress(kernel, "IsBadReadPtr")
	mov [isbadreadptr],eax

	push aSetUnhandledExceptionFilter
	push dword [kernel32hnd]
	call dword [GetProcAddress]	// GetProcAddress(kernel, "SetUnhandledExceptionFilter")

	push addr(win2kexceptionhandler)
	call eax
	test eax,eax
	jnz .prevhandler
	mov eax,addr(noprevexceptionhandler)
.prevhandler:
	mov [prevexceptionhandler],eax
	pop edx
	ret

	// read screen palette, either from DirectX palette object
	// or from GDI buffer in windowed mode
global readpalette
readpalette:
	mov al,0xc
	stosb

	xor ebx,ebx		// colour number

.nextcolour:
	mov eax,[dword 0]	// get the DDrawPalette object
ovar ddrawpaletteptr,-4
	test eax,eax
	jz .windowed

	push edi		// where to store the palette
	push byte 1		// one colour
	push ebx		// colour number
	push byte 0		// flags
	push eax		// DDrawPalette
	mov eax,[eax]
	call dword [eax+0x10]	// DDrawPalette->GetEntries
//	push byte 0x10		// DDrawPalette->GetEntries
//	call runindex(dxmethodcall)

	scasd
	dec edi		// add edi,3 in 2 bytes

	inc bl
	jnz .nextcolour
	ret

.windowed:
	push esi
	push ecx
	mov esi,0x418bb0
	mov ecx,256
.readnext:
	lodsd

	// convert BGR to RGB
	xchg ah,al
	mov [edi+1],ax
	shr eax,16
	mov [edi],al
	add edi,3
	loop .readnext
	pop ecx
	pop esi
	ret


	// on stack:
	// ESP	EBP	content
	// +00	+04	return EIP
	// +04	+08	hdcDest
	// +08	+0C	nXDest
	// +0C	+10	nYDest
	// +10	+14	nWidth
	// +14	+18	nHeight
	// +18	+1C	hdcSrc
	// +1C	+20	nXSrc
	// +20	+24	nYSrc
	// +24	+28	dwRop
	//
	// need to push for StretchBlt:
	// hdcDest
	// nXDest
	// nYDest
	// nWidthDest
	// nHeightDest
	// hdcSrc
	// nXSrc
	// nYSrc
	// nWidthSrc
	// nHeightSrc
	// dwRop
	//
global newbitblt
proc newbitblt
	arg dwRop,nYSrc,nXSrc,hdcSrc,nHeight,nWidth,nYDest,nXDest,hdcDest

	_enter
	push 3			// COLORONCOLOR
	push dword [%$hdcDest]	// (HALFTONE doesn't work well in 256 colour mode)
	call [SetStretchBltMode]

	push dword [%$dwRop]
	push dword [%$nHeight]
	push dword [%$nWidth]
	push dword [%$nYSrc]
	push dword [%$nXSrc]
	push dword [%$hdcSrc]
#if 1		// two different ways of calculating stretched coordinates
	mov eax,[windowstretch]
	imul eax,[%$nHeight]
	shr eax,16
	push eax
	mov eax,[windowstretch]
	imul eax,[%$nWidth]
	shr eax,16
	push eax
	mov eax,[windowstretch]
	imul eax,[%$nYDest]
	shr eax,16
	push eax
	mov eax,[windowstretch]
	imul eax,[%$nXDest]
	shr eax,16
	push eax
#else
	mov eax,[%$nXDest]
	push eax
	add eax,[%$nWidth]
	imul eax,[windowstretch]
	shr eax,16
	mov [%$nWidth],eax
	pop eax
	imul eax,[windowstretch]
	shr eax,16
	sub [%$nWidth],eax
	mov [%$nXDest],eax

	mov eax,[%$nYDest]
	push eax
	add eax,[%$nHeight]
	imul eax,[windowstretch]
	shr eax,16
	mov [%$nHeight],eax
	pop eax
	imul eax,[windowstretch]
	shr eax,16
	sub [%$nHeight],eax
	mov [%$nYDest],eax

	push dword [%$nHeight]
	push dword [%$nWidth]
	push dword [%$nYDest]
	push dword [%$nXDest]
#endif
	push dword [%$hdcDest]
	call [StretchBlt]
	_ret
endproc

global getwindowsize
getwindowsize:
	pusha
	movzx eax,word [windowsize]
	shl eax,16
	cdq
	mov ebx,640
	div ebx
	mov [windowstretch],eax

	xchg eax,ebx
	shl eax,16
	movzx ebx,word [windowsize]
	cdq
	div ebx
	mov [windowstretchinv],eax
	popa

	imul eax,[windowstretch]
	shr eax,16
	add eax,[ebp-0x2c]
	lea ecx,[eax+2]

	mov eax,[0x41a94c]
	imul eax,[windowstretch]
	shr eax,16
	ret

global wm_mousemove
wm_mousemove:	// adjust coordinates of WM_MOUSEMOVE
	movzx eax,word [ebp+0x16]
	imul eax,[windowstretchinv]
	xchg eax,[ebp+0x14]
	movzx eax,ax
	imul eax,[windowstretchinv]
	shr eax,16
	mov [ebp+0x14],ax
	ret

global wm_mousebutton
wm_mousebutton:	// same for WM_[L|R]BUTTON[UP|DOWN]
	sub dword [ebp-0x38],0x201
	mov eax,[ebp-0x38]

	cmp eax,2
	jb wm_mousemove
	je .nofix
	cmp eax,4
	jbe wm_mousemove

.nofix:		// all others not handled by TTD
	ret

global clienttoscreen
clienttoscreen:
	push dword [esp+8]
	push dword [esp+8]	// org esp+4
	call [ClientToScreen]
	mov eax,[0x4185dc]
	imul eax,[windowstretch]
	shr eax,16
	mov [0x4185dc],eax
	mov eax,[0x4185e0]
	imul eax,[windowstretch]
	shr eax,16
	mov [0x4185e0],eax
	ret 8

var aStretchBlt, db "StretchBlt",0
var aSetStretchBltMode, db "SetStretchBltMode",0

	align 4
var windowstretch, dd 0x10000		// for output (display) translation
var windowstretchinv, dd 0x10000	// for input (mouse) translation

	// add screen mode from DirectX enum
	// in:	[ebp-4]=x res
	//	[ebp-8]=y res
	//	[ebp-c]=ax=bit depth
global addscreenmode
addscreenmode:
	cmp eax,8
	jb .noadd
	cmp eax,16
	ja .noadd

	cmp dword [ebp-4],640
	jb .noadd
	cmp dword [ebp-8],480
	jb .noadd

	inc dword [0x41aa44]

.noadd:
	ret

#endif
