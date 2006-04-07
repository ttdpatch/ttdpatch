#include <defs.inc>
#include <frag_mac.inc>

global patchautorenew

begincodefragments

glob_frag oldautoreplace12
codefragment oldautoreplace12,-6	// trains, road vehicles
	mov [edi+0x12],ax
	db 0xc6		// mov byte ptr [edi+4ah],0

codefragment newautoreplace12
	call runindex(autoreplacetrainorrv)

codefragment oldautoreplace3,-6		// ships
	mov [esi+0x12],ax
	db 0xc6		// mov byte ptr [esi+4ah],0

codefragment newautoreplace34
	call runindex(autoreplaceengine)

codefragment oldautoreplace4,-6		// aircraft
	mov [esi+0x12],ax
	db 0xf		// movzx ebx,word ptr [esi+46]

codefragment oldgetoldmsg,30
	mov ax,0x19f

codefragment newgetoldmsg
	call runindex(getoldmsg)


endcodefragments

patchautorenew:
	patchcode oldautoreplace12,newautoreplace12,2-WINTTDX,2
	patchcode oldautoreplace3,newautoreplace34,1,1
	patchcode oldautoreplace4,newautoreplace34,1,1
	patchcode oldgetoldmsg,newgetoldmsg,1,1
	ret
