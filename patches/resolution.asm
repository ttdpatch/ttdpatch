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

#endif // WINTTDX
