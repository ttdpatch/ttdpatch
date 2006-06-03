#include <defs.inc>
#include <frag_mac.inc>
#include <textdef.inc>
#include <ptrvar.inc>
#include <patchproc.inc>

patchproc canals, patchcanals
patchproc canals, higherbridges, patchcanalshigherbridges

extern oldclass6maphandler,Class6RouteMapHandler,Class6VehEnterLeave
extern oldclass6periodicproc,Class6PeriodicProc,Class6PeriodicProc
extern oldclass6drawlandfnc,Class6DrawLand,selectgroundforbridge
extern dockwinpurchaselandico,newgraphicssetsenabled,oldclass9drawlandfnc
extern oldclass5drawlandfnc,Class5DrawLand,actionmakewater_actionnum
extern class9drawland

begincodefragments

codefragment oldshipmovement80h
	cmp byte [esi+veh.movementstat], 80h
	jnz short $+2+0x0D
	mov ax, [esi+veh.xpos]
	mov cx, [esi+veh.ypos]

codefragment newshipmovement80h
	call runindex(SpecialShipMovement)
	jc short $+2+0x0B
//	setfragmentsize 14
// Better code welcome, or in other words, FIXME!
	mov bl, [esi+veh.direction]
	nop
	nop
	nop
	db 0xE9,0x54,0x01

codefragment olddocktoolpurchaseland, -11
	mov esi, 10050h

codefragment newdocktoolpurchaseland	
	mov bl, 3
	mov word [operrormsg1], ourtext(cantbuildcanalhere)
	mov esi, actionmakewater_actionnum

codefragment oldclass6cleartile
	cmp dh, 1
	jz $+2+0x06
	mov ebx, 80000000h
	ret

codefragment newclass6cleartile
	call runindex(Class6ClearTile)
	setfragmentsize 11

codefragment finddockwinpurchaselandico, 6
	dw 153, 14, 35, 4791

codefragment oldcanbuilddockhere,6
	cmp di, 6
	db 74h, 0Fh

codefragment newcanbuilddockhere
	icall canbuilddockhere
	jmp short .can
	setfragmentsize 9
.cant:		// TTD jumps here if LA rating is bad
	jmp $+259
	setfragmentsize 15
.can:

codefragment olddockconstrwinhandler, 6
	cmp di, 6
	db 74h, 44h

codefragment newdockconstrwinhandler
	ijmp dockconstrwinhandler

ext_frag oldselectgroundforbridge

codefragment_call newselectgroundforbridge,selectgroundforbridge,5

endcodefragments

patchcanals:
	// Disable next line for simple movement handler
	patchcode oldshipmovement80h, newshipmovement80h,2,2
	patchcode olddocktoolpurchaseland, newdocktoolpurchaseland,3+WINTTDX,4
	patchcode oldclass6cleartile, newclass6cleartile,1,1

	mov eax,[ophandler+0x06*8]
	mov dword [eax+0x24],addr(Class6RouteMapHandler)

	mov dword [eax+0x28],addr(Class6VehEnterLeave)

	mov ecx, [eax+0x20]
	mov [oldclass6periodicproc], ecx
	mov dword [eax+0x20],addr(Class6PeriodicProc)

	mov ecx, [eax+0x1C]
	mov [oldclass6drawlandfnc], ecx
	mov dword [eax+0x1C],addr(Class6DrawLand)

	storeaddress finddockwinpurchaselandico, 1, 1, dockwinpurchaselandico
	or byte [newgraphicssetsenabled+1],1 << (8-8)

	//patch flat docks
	patchcode oldcanbuilddockhere,newcanbuilddockhere,1,1
	patchcode olddockconstrwinhandler,newdockconstrwinhandler,1,1

	//and drawing of them+buoys with dikes
	mov eax,[ophandler+0x05*8]
	mov ecx, [eax+0x1C]
	mov [oldclass5drawlandfnc], ecx
	mov dword [eax+0x1C],addr(Class5DrawLand)

	ret

patchcanalshigherbridges:
	patchcode selectgroundforbridge
	
	//extra patching, to display coasts under bridges
	mov eax, [ophandler+0x09*8]
	mov ecx, [eax+0x1C]
	mov [oldclass9drawlandfnc], ecx
	mov dword [eax+0x1C],addr(class9drawland)
	ret
