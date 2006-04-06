#include <defs.inc>
#include <frag_mac.inc>
#include <ptrvar.inc>

extern NewClass5RouteMapHandler,dorvstationcolldet


global patchbusstopmovement

begincodefragments

codefragment oldrvmakestationbusywhenleaving
	or byte [ebx+ebp], 0x80
	mov ax, [esi+veh.currorder]

codefragment newrvmakestationbusywhenleaving
	icall RVMakeStationBusywhenleaving
	setfragmentsize 8

codefragment oldrvstationcolldet
	mov bl,[esi+veh.movementstat]
	cmp bl,0x20

codefragment newrvstationcolldet
	movzx ebx,byte [esi+veh.movementstat]
	bt [dorvstationcolldet],ebx
	setfragmentsize 11

codefragment_call newclass5routemaphandler,NewClass5RouteMapHandler,5

endcodefragments

patchbusstopmovement:
	mov eax,[ophandler+0x05*8]
	mov edi, dword [eax+0x24]
	add edi, 6
	storefragment newclass5routemaphandler

	patchcode oldrvmakestationbusywhenleaving, newrvmakestationbusywhenleaving,1,1

	patchcode rvstationcolldet
	ret
