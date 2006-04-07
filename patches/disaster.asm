//
// Mask out specific disasters
// 

#include <std.inc>

extern disastermask



// Called in a loop to create a list of currently available disasters
// In:	AL=current year minus 1900 (not 1920!)
//	EBX=disaster (0..7)
// Out:	CF=0 if disaster is to be skipped
// Safe:EAX{8:31},ECX,EDI
global isdisasteravailable
isdisasteravailable:
	cmp	al,[nosplit ebx*2-1]	// overwritten by the call
ovar .endyears,-4,$,isdisasteravailable	// address of a table will be stored here
	jae	short .done
	bt	dword [disastermask],ebx
.done:
	ret
; endp isdisasteravailable 
