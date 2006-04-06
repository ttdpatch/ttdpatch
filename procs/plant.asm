#include <defs.inc>
#include <frag_mac.inc>
#include <bitvars.inc>
#include <patchproc.inc>

patchproc plantmanytrees, patchplant

extern treeplantfn
extern treeplantmode

begincodefragments

codefragment newplanttree
	call runindex(planttree1)
	setfragmentsize 7

codefragment oldmultitree
	cmp byte [gamemode],2

codefragment newmultitree
	call runindex(checkmultitree)
	setfragmentsize 7


endcodefragments


patchplant:
	mov bl,[treeplantmode]
	mov edi,[treeplantfn]

	add edi,byte 24
	storefragment newplanttree

	patchcode oldmultitree,newmultitree,1,0,,{test bl,plantmanytrees_morethanonepersquare},nz
	ret
