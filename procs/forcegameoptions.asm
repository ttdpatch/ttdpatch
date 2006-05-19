#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc forcegameoptions, patchforcegameoptions

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
	mov al, byte [autosavesetting]
	mov ebx, dword [forcegameoptionssettings]
	
	test ebx, forcegameoptions_autosavedisabled
	jz .no_disabled
	mov al, 0
.no_disabled:
	test ebx, forcegameoptions_autosave3months
	jz .no_3months
	mov al, 1
.no_3months:
	test ebx, forcegameoptions_autosave6months
	jz .no_6months
	mov al, 2
.no_6months:
	test ebx, forcegameoptions_autosave12months
	jz .no_12months
	mov al, 3
.no_12months:
	mov byte [autosavesetting], al

	multipatchcode oldsetnewroadtrafficside,newsetnewroadtrafficside,2
	multipatchcode oldsetnewtownnamestyle,newsetnewtownnamestyle,2

	ret
