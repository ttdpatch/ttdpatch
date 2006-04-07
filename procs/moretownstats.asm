#include <defs.inc>
#include <frag_mac.inc>

ext_frag oldenddisplaytownstats

global patchmoretownstats

begincodefragments

codefragment newenddisplaytownstats
	call runindex(displayexttownstats)

codefragment oldcreatetownwindow
	mov dx,0x18
	mov ebp,5

codefragment newcreatetownwindow
	call runindex(settownwindowsize)
	setfragmentsize 9


endcodefragments

patchmoretownstats:
	patchcode oldenddisplaytownstats,newenddisplaytownstats,1,1
	multipatchcode oldcreatetownwindow,newcreatetownwindow,2
	ret
