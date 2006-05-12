#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc forcegameoptions, patchforcegameoptions

extern newroadtrafficside
begincodefragments

codefragment oldsetnewroadtrafficside
	mov byte [newroadtrafficside], al

codefragment_call newsetnewroadtrafficside,setnewroadtrafficside,5
	
codefragment oldsetnewtownnamestyle
	mov byte [newtownnamestyle], al

codefragment_call newsetnewtownnamestyle,setnewtownnamestyle,5

endcodefragments

patchforcegameoptions:
	mov eax, dword [forcegameoptionssettings]
	test eax, forcegameoptions_imperial
	jz .noimperial
	mov byte [measuresys], 0
 .noimperial:
 	test eax, forcegameoptions_metric
	jz .nometric
	mov byte [measuresys], 1
.nometric:

	multipatchcode oldsetnewroadtrafficside,newsetnewroadtrafficside,2
	multipatchcode oldsetnewtownnamestyle,newsetnewtownnamestyle,2

	ret
