#include <std.inc>
#include <flags.inc>

extern patchflags, enhtnlconvtbl

// In:	al: L4 & 0xF0
//	ebx: depot orientation
//	(e)di: tile index of tile in front of depot
//	flags set from cmp al, 10h
// Out:
// If depot can be attached, zf set and al[5..0]: track mask, as from a track tile's (class 1's) L5
// Else, zf clear or al[5..0] == 0

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
	jnc .clzret
	
	test al, 0xC
	jnz .ret // not rail tunnel

	xor ecx, ecx
	mov cl, 3

	and al, cl
	cmp al, bl
	je .clzret

	mov dl, [landscape7+edi]
	test dl, 80h
	jz .clzret	// not enh tunnel

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
	jmp short .stzret

.bridge:
	testflags custombridgeheads
	jnc .clzret

	test al, 0x40 | 6
	jnz .ret // bridge middle | not rail bridge
	mov eax, [landscape3+edi*2]
	shr eax, 4
	// if head is sloped, al will be clear and later checks will prevent connections.
.stzret:
	cmp al, al // stz
.ret:
	ret

.clzret:
	test esp, esp //clz
	ret
