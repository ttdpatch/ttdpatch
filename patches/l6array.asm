// Various functions needed to handle the landscape6 array

#include <std.inc>
#include <flags.inc>
#include <loadsave.inc>
#include <house.inc>

extern l6switches,patchflags,randomfn
extern resetpathsignalling,FIRSTBUILDABANDON

//
// Use of L6
//
// Class	Usage
// (in L4)
// 10		Path based signalling; bits 3..7 for track with signals, bits 0..5 for plain track
// 20		Abandoned roads; time until being abandoned
// 30		New houses; random bits
// 50		New stations; random bits and layout of individually built pieces
// 80		New industries; random tile bits
// 90/road	Abandoned roads; time until being abandoned
// 90/rail	Path based signalling; like class 10
//

// Called if landscape6 is enabled but it wasn't present in the savegame
// Clear landscape6 and l6switches so the initialization can proceed
global landscape6clear
landscape6clear:
	pusha
	mov edi,landscape6		// first, fill it with zeroes
	xor eax,eax
	mov ecx,0x10000/4
	rep stosd
	and dword [l6switches],0
	popa
	ret

// Fill landscape6 entries with default values and/or values derived from existing arrays
// if the given feature wasn't active at save time
// l6switches contains the bitmap of which L6 switches were active at save time
global landscape6init
landscape6init:
	pusha
	mov eax,landscape6
	xor ecx,ecx

// if abandonedroads is on, but it wasn't at save time, reset the abandon
// time-out for every road tile
	testflags abandonedroads
	jnc near .noabandon

	test dword [l6switches],L6_ABANROAD
	jnz near .abanpresent

.tileloop:
	mov bl,[landscape4(cx,1)]
	shr bl,4

	cmp bl,2
	je .class2

	cmp bl,9
	je .class9

	jmp short .nexttile

.class2:
	mov bl,[landscape5(cx,1)]
	test bl,0xf0
	jnz .notnormal
	cmp byte [landscape1+ecx],8
	jae .nexttile
	jmp short .newroad

.notnormal:
	test bl,0xe0		// no depots
	jnz .nexttile
	cmp byte [landscape3+ecx*2],8
	jae .nexttile
	jmp short .newroad

.class9:
	cmp byte [landscape1+ecx],8
	jae .nexttile
	mov bl,[landscape5(cx,1)]
	test bl,0x80
	jnz .bridge
	test bl,4		// no road tunnels
	jz .nexttile
	and bl,3
	or bl,bl		// southern entrances only
	jz .newroad
	cmp bl,3
	je .newroad
	jmp short .nexttile

.bridge:
	test bl,64
	jnz .midpart
	test bl,32		// northern endings only
	jnz .nexttile
	test bl,2		// road bridges only
	jz .nexttile
	jmp short .newroad

.midpart:
	test bl,32		// is there anything under the bridge?
	jz .nexttile
	test bl,8		// is it a road?
	jz .nexttile
.newroad:
	mov ebx,FIRSTBUILDABANDON
	mov [eax+ecx],bl
//	jmp short .nexttile

.nexttile:
	inc ecx
	cmp ecx,0x10000
	jb .tileloop

.noabandon:
.abanpresent:
// if newhouses is on, but it wasn't at save time, re-randomize
// all house random bits
// we can't just randomize every tile separately because multi-
// tile buildings should have the same random bits in all tiles
	testflags newhouses
	jnc .nonewhouses

	test dword [l6switches],L6_NEWHOUSES
	jnz .newhousepresent

	mov ebx,landscape6
	xor ecx,ecx

.tileloop2:
	mov dl,[landscape4(cx,1)]
	shr dl,4

	cmp dl,3
	jne .nexttile2

	movzx edx,byte [landscape2+ecx]		// can't use gethouseid - grfs aren't activated yet
						// the size shouldn't differ between the house type and subst. type anyway
	mov dl,[newhousepartflags+edx]
	call [randomfn]
	test dl,8
	jz .notmainpart
	mov [ebx+ecx],al
.notmainpart:
	test dl,4
	jz .noparty
	mov [ebx+ecx+100h],al
.noparty:
	test dl,2
	jz .nopartx
	mov [ebx+ecx+1],al
.nopartx:
	test dl,1
	jz .nopartxy
	mov [ebx+ecx+101h],al
.nopartxy:
.nexttile2:
	inc ecx
	cmp ecx,0x10000
	jb .tileloop2

.nonewhouses:
.newhousepresent:

	testflags pathbasedsignalling
	jnc .pathsigok
	test byte [l6switches],L6_PATHSIG
	jnz .pathsigok
	call resetpathsignalling	// in pathsig.asm
.pathsigok:

// if newindustries is on, but it wasn't at save time,
// re-randomize random bits

	testflags newindustries
	jnc .nonewindus
	
	test dword [l6switches],L6_NEWINDUSTRIES
	jnz .industilespresent
//	mov ebx,[landscape6ptr]
	xor ecx,ecx

.tileloop3:
	mov dl,[landscape4(cx,1)]
	shr dl,4

	cmp dl,8
	jne .nexttile3

	call [randomfn]
	mov byte [landscape6+ecx],al

.nexttile3:
	inc ecx
	cmp ecx,0x10000
	jb .tileloop3

.nonewindus:
.industilespresent:
	popa
	ret
