#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc newbridges, patchnewbridges

begincodefragments

codefragment oldvehonbridge
	and esi,0xf0

codefragment newvehonbridge
	icall vehonbridge
	setfragmentsize 9

endcodefragments

patchnewbridges:
	patchcode vehonbridge
	ret
