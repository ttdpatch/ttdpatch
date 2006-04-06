#include <defs.inc>
#include <frag_mac.inc>
#include <textdef.inc>

extern advanceroadvehicle

global patchrvpower

begincodefragments

codefragment oldsetrvspeed
	mov [esi+veh.maxspeed],ax

codefragment newsetrvspeed
	call runindex(setrvspeed)
	setfragmentsize 8

codefragment oldadvanceroadvehicle,-4
	and al,0x1f
	cmp al,4
	je $+2+8

codefragment newadvanceroadvehicle
	call runindex(dorvmovement)
	ret
	setfragmentsize 8

codefragment oldrvaccelerate,3
	mov eax,[esi+veh.speed]
	inc ax
	db 0x80		// cmp byte ptr [esi+0x66],0

codefragment newrvaccelerate
	call runindex(rvaccelerate)
	db 0xeb		// jmp short

codefragment newadvancervposition
	shr eax,2
	clc
	jz short .nospeed
	stc
	sbb [esi+38h],al	// subtract al+1
.nospeed:
	ret
	setfragmentsize 14

codefragment oldrvinfowindow,-6
	mov bx,0x900e
	db 0xbf		// mov edi,...

codefragment newrvinfowindow
	call runindex(showrvweight)
	mov bx,ourtext(rvweightinfo)

codefragment oldrvnewvehinfo,-73
	mov bx,0x902a

codefragment newrvnewvehinfo
	call runindex(rvnewvehinfo)
	setfragmentsize 8

codefragment oldrefreshrv,11
	push ebp
	movzx bx,byte [esi+veh.direction]

codefragment newrefreshrv
	call runindex(refreshrv)
	setfragmentsize 8

codefragment oldsetupnewrv
	mov word [esi+veh.cursprite],3093

codefragment newsetupnewrv
	call runindex(setupnewrv)


endcodefragments

patchrvpower:
	patchcode oldsetrvspeed,newsetrvspeed,2,4

	patchcode oldadvanceroadvehicle,newadvanceroadvehicle,1,2
	storerelative advanceroadvehicle,edi

	patchcode oldrvaccelerate,newrvaccelerate,1,1
	add edi,lastediadj+45
	storefragment newadvancervposition

	patchcode oldrvinfowindow,newrvinfowindow,1,1

	patchcode oldrvnewvehinfo,newrvnewvehinfo,1,1
	patchcode oldrefreshrv,newrefreshrv,1,2
	patchcode oldsetupnewrv,newsetupnewrv,1,1
	ret
