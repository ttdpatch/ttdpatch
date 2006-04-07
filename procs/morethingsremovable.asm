#include <defs.inc>
#include <frag_mac.inc>


extern roadremovable.getroadowner


global patchmorethingsremovable

begincodefragments

codefragment oldroadremovable
	cmp dl,1
	jbe $+2+0x19

codefragment newroadremovable
	call runindex(roadremovable)
	setfragmentsize 7

endcodefragments

patchmorethingsremovable:
	patchcode oldroadremovable,newroadremovable,1,1
	// store the address of a temporary variable that holds the road's owner
	mov eax,[edi+7]
	mov dword [roadremovable.getroadowner],eax
	ret
