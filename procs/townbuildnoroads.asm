#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc townbuildnoroads, patchtownbuildnoroads

begincodefragments

codefragment oldcantownextendroadhere,3
	push ebx
	push di
	push ebx
	push di

codefragment newcantownextendroadhere
	icall cantownextendroadhere


endcodefragments

patchtownbuildnoroads:
	patchcode oldcantownextendroadhere,newcantownextendroadhere,1,1
	ret
