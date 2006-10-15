#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>
#include <common.h>

patchproc fifoloading, patchcantfinddepot

begincodefragments

codefragment oldcantfinddepot
	mov word [esi+10], 100h
	mov bx, [esi+4]

codefragment_call newcantfinddepot,cantfinddepot,6

endcodefragments

patchcantfinddepot:
	multipatchcode cantfinddepot, 4
	ret
