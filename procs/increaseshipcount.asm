#include <defs.inc>
#include <frag_mac.inc>


extern newvehcount


global patchincreaseshipcount

begincodefragments

codefragment shipcountcode,2
	cmp dl,0x32


endcodefragments

patchincreaseshipcount:
	changeloadedvalue shipcountcode,1,1,b,newvehcount,3
	ret


	// set new service interval for all types of vehicles
