#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc windowsnap, patchwindowsnap

patchwindowsnap:
	patchcode oldbeginwindowdrag,newbeginwindowdrag,1,1
	patchcode oldhandlewindowdrag,newhandlewindowdrag,1,1
	ret


begincodefragments

codefragment oldbeginwindowdrag
	push cx
	push dx
	mov cl, 3Fh

codefragment newbeginwindowdrag
	icall beginwindowdrag

codefragment oldhandlewindowdrag
	mov cx, ax
	or cx, bx

codefragment newhandlewindowdrag
	icall handlewindowdrag
	setfragmentsize 6


endcodefragments
