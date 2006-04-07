#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc locomotiongui,enhancegui, patchlandscapemarkers

begincodefragments

codefragment oldcollectlandscapemarkers,6
	pop dx
	pop si
	pop di
	db 66h

codefragment newcollectlandscapemarkers
	icall collectlandscapemarkers
	setfragmentsize 9

codefragment oldresetmarkedtiles,5
	pop dx
	pop ebx
	pop ax
	db 0x66, 0xC7

codefragment newresetmarkedtiles
	icall resetmarkedtiles
	setfragmentsize 9


endcodefragments

patchlandscapemarkers:
	patchcode oldcollectlandscapemarkers,newcollectlandscapemarkers,1,1
	patchcode oldresetmarkedtiles,newresetmarkedtiles,1,1
	ret
