#include <defs.inc>
#include <frag_mac.inc>

ext_frag oldcontrolplanecrashes

global patchnoplanecrashes

begincodefragments

codefragment newcontrolplanecrashes
	call runindex(controlplanecrashes)
	setfragmentsize 8


endcodefragments

patchnoplanecrashes:
	patchcode oldcontrolplanecrashes,newcontrolplanecrashes,1,1
	ret
