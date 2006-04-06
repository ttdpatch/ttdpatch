
// in units of 1/8
// for regular, monorail, maglev, unused; regular, electric, monorail/maglev, unused

#include <std.inc>
#include <flags.inc>

extern curtooltracktypeptr,isrealhumanplayer,locationtoxy,patchflags
extern trackcostadjust




var costrailmuldefault, db 8, 16, 24, 0, 8, 13, 16, 0

uvarb costrailmul,4

// in: dl tracktype, (0,1,2) more will break
//	eax = cost
// out:
//	eax = new cost
global calctrackcostdifference
calctrackcostdifference:
	call isrealhumanplayer
	je .ishuman
	ret

.ishuman:
	push edx

	movzx edx, dl
	mov dl,[costrailmul+edx]
	imul edx
	clc
	sar eax, 3	// on some processors sar shifts in the carry flag??

.done:
	pop edx
	ret
; endp calctrackcostdifference:

// Called at the very end of the track-laying handler, if no error was found.
// Also used by manualconvert
global addbuildtrackcost
addbuildtrackcost:
	testflags manualconvert
	jnc .noconversion

	mov ebx,[trackcostadjust]
	add edi,ebx	// the track-laying caused conversion of other tracks - add this cost to edi

.noconversion:
	push eax
	push ecx
	
	mov ecx,[curtooltracktypeptr]
	mov dl,byte [ecx]
	and dl,0x0f

	mov eax,[trackcost]
	testflags tracktypecostdiff
	jnc .normalcost

	call calctrackcostdifference
.normalcost:
	add edi, eax
	
	pop ecx
	pop eax
	ret
; endp addbuildtrackcost

global movremovetrackcost
movremovetrackcost:
	push eax
	push ecx

	call locationtoxy

	mov dh,[landscape4(si)]
	shr dh,4			// get tile type
	
	cmp dh,2			// is it a roadcrossing?
	jne short .normal		// no it isn't
	mov dl,[landscape3+esi*2+1] // What tracktype we have?
	jmp short .masktype

.normal:
	mov dl,[landscape3+esi*2]	// What tracktype we have?
	
.masktype:
 	and dl,0x0f

	mov eax,[tracksale]
	call calctrackcostdifference

	mov ebx, eax
	
	pop ecx
	pop eax
	ret
; endp movremovetrackcost

global addremovetrackcost
addremovetrackcost: // Builderdash remove
	push eax
	push ecx

	push esi
	call locationtoxy
	mov dl,[landscape3+esi*2]	// What tracktype we have?
	and dl,0x0f
	
	mov eax,[tracksale]
	call calctrackcostdifference
	
	pop esi
	add esi, eax

	pop ecx
	pop eax
	ret
; endp addremovetrackcost
