#include <defs.inc>
#include <frag_mac.inc>
#include <var.inc>
#include <patchproc.inc>

patchproc newtownnames,newhouses, patchgameinit

begincodefragments

codefragment oldrandomgame1,58
	dec dx
	jns fragmentstart-5

codefragment newrandomgame1
	call runindex(randomgame1)

reusecodefragment oldrandomgame2,oldrandomgame1

codefragment newrandomgame2
	setfragmentsize 3


endcodefragments

patchgameinit:
	patchcode randomgame1
	stringaddress oldrandomgame2
	add edi,181
	storefragment newrandomgame2
	ret

