#include <defs.inc>
#include <frag_mac.inc>
#include <industry.inc>
#include <patchproc.inc>

patchproc stableindustry, patchstableindustry

patchstableindustry:
	patchcode oldindustryclosedown,newindustryclosedown,1,1
	ret



begincodefragments

glob_frag oldindustryclosedown
codefragment oldindustryclosedown
	mov byte [esi+industry.prodmultiplier],0

codefragment newindustryclosedown
	call runindex(industryclosedown)
	setfragmentsize 8


endcodefragments
