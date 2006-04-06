#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc tracktypecostdiff, patchtracktypecostdiff

begincodefragments

codefragment oldaddremovetrackcost
	add esi,[tracksale]

codefragment newaddremovetrackcost
	call runindex(addremovetrackcost)

codefragment oldmovremovetrackcost
	mov ebx,[tracksale]

codefragment newmovremovetrackcost
	call runindex(movremovetrackcost)


endcodefragments

patchtracktypecostdiff:
	patchcode oldaddremovetrackcost,newaddremovetrackcost,1,1
	patchcode oldmovremovetrackcost, newmovremovetrackcost,1,1
	ret
