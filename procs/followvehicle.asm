#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc followvehicle, patchfollowvehicle


extern tooltiptextlocPlane,tooltiptextlocRV,tooltiptextlocShip
extern tooltiptextlocTrain
extern variabletofind

begincodefragments

codefragment findtrnwindowtooltips
 	db 0x8B,0x01,0x8C,0x01,0x00,0x00,0x00,0x00,0x46,0x88
 	
codefragment newfollowvehicle
 	ijmp followvehiclefunc
 	
codefragment findrvwindowtooltips
 	db 0x8B,0x01,0x8C,0x01,0x00,0x00,0x00,0x00,0x1C,0x90
 
codefragment findshipwindowtooltips
 	db 0x8B,0x01,0x8C,0x01,0x00,0x00,0x00,0x00,0x27,0x98
 	
codefragment findplanewindowtooltips
 	db 0x8B,0x01,0x8C,0x01,0x00,0x00,0x00,0x00,0x27,0xA0
 	
codefragment oldmainviewrightclick
	shl ax,cl
	shl bx,cl

codefragment newmainviewrightclick
	ijmp cancelfollowvehicle
	setfragmentsize 6

codefragment oldsetmainviewxy
	xor		dh,dh
	mov		bx,cx
	mov		cx,dx

codefragment newsetmainviewxy
	icall	cancelfollowonsetxy
	setfragmentsize 8

endcodefragments


ext_frag findvariableaccess

patchfollowvehicle:
 	stringaddress findtrnwindowtooltips
 	mov [variabletofind],edi
 	mov [tooltiptextlocTrain],edi
	stringaddress findvariableaccess
 	sub edi,0x19
	storefragment newfollowvehicle
 	
 	stringaddress findrvwindowtooltips
 	mov [variabletofind],edi
 	mov [tooltiptextlocRV],edi
 	stringaddress findvariableaccess
 	sub edi,0x19
	storefragment newfollowvehicle
 	
 	stringaddress findshipwindowtooltips
 	mov [variabletofind],edi
 	mov [tooltiptextlocShip],edi
 	stringaddress findvariableaccess
 	sub edi,0x19
 	storefragment newfollowvehicle	
 
 	stringaddress findplanewindowtooltips
 	mov [variabletofind],edi
 	mov [tooltiptextlocPlane],edi
 	stringaddress findvariableaccess
 	sub edi,0x19
 	storefragment newfollowvehicle

	//code in the right/left clicks
	
	patchcode oldmainviewrightclick,newmainviewrightclick,2,7
 	
	patchcode oldsetmainviewxy,newsetmainviewxy,2,2
 	
 	ret
