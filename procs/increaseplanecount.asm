#include <defs.inc>
#include <frag_mac.inc>


extern newvehcount


global patchincreaseplanecount
patchincreaseplanecount:
	changeloadedvalue planecountcode,1,1,b,newvehcount,2
	ret



begincodefragments

codefragment planecountcode,2
	cmp dl,0x28


endcodefragments
