#if WINTTDX

#include <defs.inc>
#include <frag_mac.inc>
#include <win32.inc>
#include <patchproc.inc>

patchproc stretchwindow, patchstretchwindow

extern aStretchBlt, gdi32hnd
extern StretchBlt, aSetStretchBltMode, gdi32hnd
extern SetStretchBltMode,newbitblt,clienttoscreen

def_indirect newbitblt
def_indirect clienttoscreen

patchstretchwindow:
	mov dword [0x40d84c],newbitblt_indirect
	pusha	// the API calls destroy ECX and EDX
	push aStretchBlt
	push dword [gdi32hnd]
	call dword [GetProcAddress]	// GetProcAddress(GDI32, "StretchBlt")
	mov [StretchBlt],eax
	push aSetStretchBltMode
	push dword [gdi32hnd]
	call dword [GetProcAddress]	// GetProcAddress(GDI32, "SetStretchBltMode")
	mov [SetStretchBltMode],eax
	popa

	mov edi,0x404b32
	storefragment newgetwindowsize

	mov edi,0x40e35a
	storefragment newwm_mousemove

	mov edi,0x40e5ee
	storefragment newwm_mousebutton

	mov dword [0x40e7cf],clienttoscreen_indirect
	ret


begincodefragments

codefragment newgetwindowsize
	call runindex(getwindowsize)
	push ecx
	setfragmentsize 12

codefragment newwm_mousemove
	call runindex(wm_mousemove)
	setfragmentsize 8

codefragment newwm_mousebutton
	call runindex(wm_mousebutton)
	setfragmentsize 7

endcodefragments

#endif

