//
// L7 usage
//
// Class	Usage
// (in L4)
// 20		One-way roads
// 30		Year of construction
// 50		Station tile flags (L7STAT_*)
// 80		Industry tile triggers
// 90/bridge	Higher bridges, height

#include <std.inc>
#include <flags.inc>
#include <loadsave.inc>

extern l7switches,patchflags

global landscape7clear
landscape7clear:
	pusha
	mov edi,landscape7
	xor eax,eax
	mov ecx,0x10000/4
	rep stosd
	and dword [l7switches],0
	popa
	ret

global landscape7init
landscape7init:
	pusha
// if newhouses is on, but it wasn't at save time, init building year
// of all houses with the current year
	testflags newhouses
	jnc .nonewhouses

	test dword [l7switches],L7_NEWHOUSES
	jnz .hasnewhouses

//	mov eax,[landscape7ptr]
	xor ecx,ecx
	mov dl,[currentyear]

.loop:
	mov bl,[landscape4(cx,1)]
	shr bl,4

	cmp bl,3
	jne .next

	mov [landscape7+ecx],dl

.next:
	inc ecx
	cmp ecx,0x10000
	jb .loop

.nonewhouses:
.hasnewhouses:

// the same with new industries, but they have the random triggers in L7
	testflags newindustries
	jnc .nonewindus
	
	test dword [l7switches],L7_NEWINDUSTRIES
	jnz .industilespresent

//	mov edx,[landscape7ptr]
	xor ecx,ecx

.loop2:
	mov bl,[landscape4(cx,1)]
	shr bl,4

	cmp bl,8
	jne .next2

	mov byte [landscape7+ecx],0

.next2:
	inc ecx
	cmp ecx,0x10000
	jb .loop2

.nonewindus:
.industilespresent:


	test dword [l7switches],L7_ONEWAYROADS
	jnz .hasonewayroads

//	mov edx,[landscape7ptr]
	xor ecx,ecx

.looproad:
	mov bl,[landscape4(cx,1)]
	shr bl,4

	cmp bl,2
	jne .nextroad

	mov byte [landscape7+ecx],0

.nextroad:
	inc ecx
	cmp ecx,0x10000
	jb .looproad


.hasonewayroads:
	popa
	ret
