#include <defs.inc>
#include <frag_mac.inc>


extern newvehcount


global patchincreaservcount

begincodefragments

codefragment rvcountcode,2
	cmp dl,0x50
	db 0x77,0xbc	// jg somewhere


endcodefragments

patchincreaservcount:
	changeloadedvalue rvcountcode,1,1,b,newvehcount,1
	ret
