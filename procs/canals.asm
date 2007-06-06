#include <defs.inc>
#include <frag_mac.inc>
#include <textdef.inc>
#include <ptrvar.inc>
#include <patchproc.inc>

patchproc canals, patchcanals
patchproc canals, higherbridges, patchcanalshigherbridges

extern oldclass6maphandler,Class6RouteMapHandler,Class6VehEnterLeave
extern oldclass6drawlandfnc,Class6DrawLand,selectgroundforbridge
extern dockwinpurchaselandico,newgraphicssetsenabled,oldclass9drawlandfnc
extern oldclass5drawlandfnc,Class5DrawLand,actionmakewater_actionnum
extern class9drawland,Class9Query,oldclass9queryfnc, newgraphicssetsenabled

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

codefragment oldbuildbouy
	mov byte [landscape2+edi], al
	mov word [nosplit landscape3+edi*2], 0
	rol di, 4

codefragment newbuildbouy
	mov byte [landscape2+edi], al
	and word [nosplit landscape3+edi*2], 0x0003
	rol di, 4
	setfragmentsize 20
	
codefragment oldremovebouy
	mov byte [landscape1+esi], 11h
	mov byte [landscape2+esi], 0
	mov word [nosplit landscape3+esi*2], 0

codefragment newremovebouy
	mov byte [landscape1+esi], 11h
	mov byte [landscape2+esi], 0
	and word [nosplit landscape3+esi*2], 0x003
	setfragmentsize 24

codefragment newaquaductmiddlespritebaseget
	icall aquaductmiddlespritebaseget
	setfragmentsize 7

codefragment newaquaductendspritebaseget
	icall aquaductendspritebaseget
	setfragmentsize 6
	
codefragment oldclass9drawendspritebaseget,21	//27
                //mov     esi, [esi+0x18]	//overwritten by slopebld.asm:isbridgeendingramp
                //or      di, di
                jnz     short loc_153A9F
                add     esi, BYTE 10h

loc_153A9F:                                     ; CODE XREF: Class9DrawLand+EA.j
                test    dh, 20h
                jz      short loc_153AA7
                add     esi, BYTE 8

loc_153AA7:                                     ; CODE XREF: Class9DrawLand+F2.j
                test    bl, 2
                jz      short loc_153AAF
                add     esi, BYTE 4

loc_153AAF:                                     ; CODE XREF: Class9DrawLand+FA.j
                and     ebx, BYTE 0Ch
                mov     ebx, [esi+ebx*8]

endcodefragments

patchcanals:
	// Disable next line for simple movement handler
	patchcode oldshipmovement80h, newshipmovement80h,2,2
	patchcode oldclass6cleartile, newclass6cleartile,1,1

	mov eax,[ophandler+0x06*8]
	mov dword [eax+0x24],addr(Class6RouteMapHandler)

	mov dword [eax+0x28],addr(Class6VehEnterLeave)

	mov ecx, [eax+0x1C]
	mov [oldclass6drawlandfnc], ecx
	mov dword [eax+0x1C],addr(Class6DrawLand)

	storeaddress finddockwinpurchaselandico, 1, 1, dockwinpurchaselandico
	or DWORD [newgraphicssetsenabled],1 << 8 | 1<<0x12

	//patch flat docks
	patchcode oldcanbuilddockhere,newcanbuilddockhere,1,1
	patchcode olddockconstrwinhandler,newdockconstrwinhandler,1,1

	//and drawing of them+buoys with dikes
	mov eax,[ophandler+0x05*8]
	mov ecx, [eax+0x1C]
	mov [oldclass5drawlandfnc], ecx
	mov dword [eax+0x1C],addr(Class5DrawLand)
	
	//aquaduct query handler
	mov eax,[ophandler+0x09*8]
	mov ecx, [eax+0x34]
	mov [oldclass9queryfnc], ecx
	mov dword [eax+0x34],addr(Class9Query)
	
	//patch aquaduct draw handler
	stringaddress oldclass9drawendspritebaseget
	mov eax, edi
	storefragment newaquaductendspritebaseget
	lea edi, [eax+316]
	storefragment newaquaductmiddlespritebaseget

	// patches the bouys
	patchcode oldbuildbouy, newbuildbouy, 1, 3
	patchcode oldremovebouy, newremovebouy
	
	// patch new gui for water, we don't need to search because we know exactly where the stuff is
	extern CreateDockWaterConstrWindow,OldDockWaterConstr_WindowHandler,DockWaterConstr_WindowHandler,OldDockWaterConstr_ClickProcs,OldDockWaterConstr_ToolClickProcs
	mov eax, [ophandler+0x12*8]
	mov eax, [eax+1*4]	// = Class12FunctionHandler
	mov edi, [eax+3]	// = Get the Handler Table
	mov dword [edi], addr(CreateDockWaterConstrWindow)
	mov eax, [edi+1*4]
	mov [OldDockWaterConstr_WindowHandler], eax
	mov eax, [eax+40]
	mov [OldDockWaterConstr_ClickProcs], eax
	mov dword [edi+1*4], addr(DockWaterConstr_WindowHandler)
	lea eax, [edi+76]
	mov [OldDockWaterConstr_ToolClickProcs], eax
	ret

patchcanalshigherbridges:
	patchcode selectgroundforbridge
	
	//extra patching, to display coasts under bridges
	mov eax, [ophandler+0x09*8]
	mov ecx, [eax+0x1C]
	mov [oldclass9drawlandfnc], ecx
	mov dword [eax+0x1C],addr(class9drawland)
	ret
