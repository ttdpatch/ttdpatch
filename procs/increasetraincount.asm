#include <defs.inc>
#include <frag_mac.inc>


extern newvehcount


global patchincreasetraincount
patchincreasetraincount:
	changeloadedvalue traincountcode,1,1,b,newvehcount
	ret



begincodefragments

codefragment traincountcode,2
	cmp dl,0x50
	db 0x77,0xb6	// jg somewhere


endcodefragments
