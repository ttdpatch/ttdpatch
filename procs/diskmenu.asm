#include <defs.inc>
#include <frag_mac.inc>

global patchdiskmenu
patchdiskmenu:
	patchcode olddiskmenu,newdiskmenu,1,1
	ret



begincodefragments

codefragment olddiskmenu
	jz $+2+7
	or dx,dx

codefragment newdiskmenu
	call runindex(diskmenuselection)
	jc $+2+0x25
	setfragmentsize 9


endcodefragments
