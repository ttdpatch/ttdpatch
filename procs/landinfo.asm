#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchprocandor miscmods,NOTBIT(MISCMODS_DONTSHOWALTITUDE),,patchshowaltitude

extern variabletofind

begincodefragments

codefragment oldsizelandinfowindow1,4
	mov     cx, 42
	
codefragment newsizelandinfowindow1
	icall patchtotallandwindowsize
	setfragmentsize 9
	
codefragment oldsizelandinfowindow2,-13
	add cx, 8Ch
	add dx, 10h
	
codefragment newsizelandinfowindow2
	icall patchlandwindowboxsizes
	setfragmentsize 13
	
codefragment oldlandinfotextinsert,-2
	push    cx
	push    dx
	mov     bp, 276

codefragment newlandinfotextinsert
	ijmp	addlandinfoheightstring
	setfragmentsize 13
	
codefragment oldlandinfotextsplit, -5
	pop dx
	pop cx
	add dx, BYTE 11
	push dx
	db 0x8A, 0x15 // mov dl, ...
	
codefragment newlandinfotextsplit
	icall splitlandinfotext
	setfragmentsize 15

endcodefragments

ext_frag findvariableaccess

patchshowaltitude:
	patchcode oldsizelandinfowindow1,newsizelandinfowindow1,1,2
	patchcode oldsizelandinfowindow2,newsizelandinfowindow2,1,1
	patchcode oldlandinfotextinsert,newlandinfotextinsert,1,1
	patchcode oldlandinfotextsplit,newlandinfotextsplit,1,1
	ret
