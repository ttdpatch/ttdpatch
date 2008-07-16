#if WINTTDX
//
// Higher resolution
//

#include <std.inc>

var reserrorstring, dw 'R','e','s',' ','E','r','r',0

uvarb screenblocksx
uvarb screenblocksy
uvarw screenblocks

extern resheight,reswidth

// when TTD updates a rectangular area, it can end up refreshing off-screen areas
// when drawing off-screen, it tries to read beyond the supplied buffer, which
// can cause a GPF. Fix this by trimming the off-screen parts of the refresh area.
//
// in:	on stack:
//	[ebp-0x10]: bottom edge of the refresh area, exclusive
//	[ebp-0x20]: the same, the original code simply copied the value here
//	[ebp-0x24]: rigth edge of the refresh area, exclusive
// safe: all except ebp
exported calcupdateblockrect
	mov eax,[ebp-0x10]	// overwritten
	cmp ax,[resheight]
	jbe .height_ok
	movzx eax,word [resheight]
.height_ok:
	mov [ebp-0x20],eax	// ditto

	mov eax,[ebp-0x24]
	cmp ax,[reswidth]
	jbe .width_ok
	movzx eax,word [reswidth]
	mov [ebp-0x24],eax
.width_ok:

	ret

exported drawminimap
	mov ebx, 0
ovar edxmaskptr
	cmp byte [ebx+3],0xFF
	je .dword
	cmp byte [ebx+2],0xFF
	je .3byte
	cmp byte [ebx+1],0xFF
	je .word
	cmp byte [ebx],0xFF
	jne .ret
	or [es:esi],dl
.ret:
	ret

.3byte:
	or [es:esi],dx
	shr edx,16
	or [es:esi+2],dl
	ret

.word:
	o16
.dword:
	or [es:esi],edx
	ret

#endif // WINTTDX
