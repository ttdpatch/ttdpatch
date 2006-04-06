#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc manualconvert,tracktypecostdiff, patchbuildtrackcost

begincodefragments

codefragment oldaddbuildtrackcost
	add edi,[trackcost]

codefragment newaddbuildtrackcost
	call runindex(addbuildtrackcost)


endcodefragments

patchbuildtrackcost:
	patchcode oldaddbuildtrackcost,newaddbuildtrackcost,1,1
	ret
