#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc maprefresh,enhancegui, patchmaprefresh


extern maprefreshfrequency
extern patchflags

begincodefragments

codefragment oldupdatemap1
	test al,0x1f
	jnz $+2+0x62

codefragment newupdatemap1
	setfragmentsize 8

codefragment newupdatemap4
	icall updatemappos

codefragment newupdatemap5
	icall CheckMapPosition
	setfragmentsize 8

codefragment newupdatemap2
	call runindex(updatemap)

codefragment oldupdatemap3
	shr bp,1

codefragment newupdatemap3
	setfragmentsize 3


endcodefragments


patchmaprefresh:
	mov bl,[maprefreshfrequency]
	stringaddress oldupdatemap1,1,1
	testflags maprefresh
	jnc .nomaprefresh
	cmp bl,1
	jne .notconstant
	testflags enhancegui
	jc .withenhancegui
	
	storefragment newupdatemap1
	jmp short .firstdone

.nomaprefresh:
	storefragment newupdatemap4
	ret

.withenhancegui:
	storefragment newupdatemap5
	jmp short .firstdone

.notconstant:
	storefragment newupdatemap2
.firstdone:

	stringaddress oldupdatemap3,1,0
	cmp bl,1
	jne .seconddone
	storefragment newupdatemap3
.seconddone:
	ret
