#include <defs.inc>
#include <frag_mac.inc>


extern roadremovable.getroadowner


global patchmorethingsremovable
patchmorethingsremovable:
	patchcode oldroadremovable,newroadremovable,1,1
	// store the address of a temporary variable that holds the road's owner
	mov eax,[edi+7]
	mov dword [roadremovable.getroadowner],eax

	patchcode olddemolishroadcall,newdemolishroadcall,1,1
	add edi,byte 0x33+lastediadj
	storefragment newdemolishroadcall
	ret



begincodefragments

codefragment oldroadremovable
	cmp dl,1
	jbe $+2+0x19

codefragment newroadremovable
	call runindex(roadremovable)
	setfragmentsize 7

codefragment olddemolishroadcall,1
	push edi
	mov esi,0x10010

codefragment newdemolishroadcall
	call runindex(demolishroadcall)
	setfragmentsize 10


endcodefragments
