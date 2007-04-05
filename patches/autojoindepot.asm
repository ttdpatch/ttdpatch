#include <std.inc>
#include <flags.inc>

extern patchflags, enhtnlconvtbl

// In:	al: L4 & 0xF0
//	ebx: depot orientation
//	(e)di: tile index of tile in front of depot
//	flags set from cmp al, 10h
// Out:
// If depot can be attached, zf set and al[5..0]: track mask, as from a track tile's (class 1's) L5
// Else: one of zf clear, al[5..0] == 0, or double-return

exported autojoinraildepotcheck
	jnz .nottrack
// Track; original code
	mov al, [landscape5(di)]
	test al, 0xC0
	ret // nz if depot or signal

.nottrack:
	cmp al, 0x90
	jnz .ret

//bridge or tunnel
	mov al, [landscape5(di)]
#if !WINTTDX
	movzx edi, di // high word of edi may contain junk in DOS; clear it
#endif
	test al, 0x80
	jnz .bridge

.tunnel:
	testflags enhancetunnels
	jnc fail
	
	test al, 0xC
	jnz .ret // not rail tunnel

	xor ecx, ecx
	mov cl, 3

	and al, cl
	cmp al, bl
	je fail	// tunnel faces depot

	mov dl, [landscape7+edi]
	test dl, 80h
	jz fail	// not enh tunnel

// generate regular track mask
	movzx esi, al
	xor edx, 0x10
	shl edx, cl
	xor eax, eax
.loop:
	bt edx, ecx
	jnc .next
	or al, [enhtnlconvtbl+ecx-1+esi*4]
.next:
	loop .loop
	jmp short .good

.bridge:
	testflags custombridgeheads
	jnc fail

	test al, 0x40 | 6
	jnz .ret // bridge middle | not rail bridge
	mov eax, [landscape3+edi*2]
	shr eax, 4
	// if head is sloped, al will be clear and later checks will prevent connections.
.good:
	cmp al, al // stz
.ret:
	ret

fail:	// return to caller's caller
	pop edi
	ret


// In:	ebx: depot or station orientation (6: Drive through X, 7: Drive through Y) 
//	(e)di: tile index of tile in front of depot/station for depots and normal stations.
//	al: L4 corresponding to (e)di
//	
// Out:
//	ret if depot/station can be attached
//	else, double-return

exported autojoinroaddepotcheck
	cmp ebx, 6
	jae .drivethrough

	and al, 0xF0
	cmp al, 0x20
	jnz .notroad
	ret

.notroad:
	cmp al, 0x90
	jnz fail

	testflags custombridgeheads
	jnc fail

	mov al, [landscape5(di)]
	xor al, 0x82
	test al, 0x80 | 0x40 | 6
	jnz fail // tunnel | bridge middle | not road
	ret

.drivethrough:
	pop eax
	sub eax, 17+5*WINTTDX	// subtract call (5), landscape load (4 in DOS, 6 in WIN), movzx (3, Win only),
				//	and di modification (8) from return address

	mov ecx, [eax+4]	// get waAutoJoinStationRoadXYOffsets's address
	sub di, [ecx+ebx*2]	// reverse the add at [eax]; di is now station's tile index

	sub ebx, 6

// fake a normal station facing direction 0 or 1
	pusha
	call eax
	popa

// repeat, with direction 2/3
	add ebx, 2
	jmp eax
