#include <defs.inc>
#include <frag_mac.inc>

extern isdisasteravailable.endyears

global patchdisastersmask
patchdisastersmask:
	stringaddress oldmakedisasterslist,1,1
	mov eax,[edi+3]				// copy the address of a table before it's overwritten
	mov dword [isdisasteravailable.endyears],eax
	storefragment newmakedisasterslist
	ret



begincodefragments

glob_frag oldgetdisasteryear
codefragment oldgetdisasteryear,-2
	mov al,[currentyear]
	add al,20

reusecodefragment oldmakedisasterslist,oldgetdisasteryear,16

codefragment newmakedisasterslist
	call runindex(isdisasteravailable)
	setfragmentsize 7


endcodefragments
