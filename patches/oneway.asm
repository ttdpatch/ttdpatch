// One Way Roads
// Copyright 2005 Oskar Eisemuth
// TODO:
// Check Owner of road
// Fix displaying code (refresh tile)

#include <std.inc>
#include <veh.inc>
#include <newvehdata.inc>

extern addsprite,curplayerctrlkey,getroutemap,invalidatetile

//needed by StevenHs Tram Check!---------
extern tramVehPtr,tramMovement,newvehdata
//---------------------------------------



uvarw newonewayarrows,1,s
var numonewayarrows, dd 6

uvarb ignoreonewayroads,1
global GetClass2RouteMap
GetClass2RouteMap:
//------------------INSERTED BY STEVEN HOEFEL TO MAKE TRAMS DRIVE ON TRACKS---------------
	cmp dword [tramVehPtr], 0
	jle .normalRoadVehicleMovement
	push esi
	push edx
	mov esi, [tramVehPtr]
	movzx edx, byte [esi+veh.vehtype]
	test byte [vehmiscflags+edx], VEHMISCFLAG_RVISTRAM
	pop edx
	pop esi
	jz .normalRoadVehicleMovement
	mov al, byte [tramMovement+eax]
	mov ah, al
	retn
.normalRoadVehicleMovement:
//----------------------------------------------------------------------------------------
	mov al, byte [eax+0x10000]
ovar roadroutetable,-4
	mov ah, al
	cmp byte [ignoreonewayroads], 1
	je .ignore
//	mov esi,[landscape7ptr]
//	or esi,esi
//	jz .no_l7
	push ebx
	xor ebx, ebx
	mov bl, byte [landscape7+edi]
	and bl, 0xF	
	bt bx, 0
	jnc .leave_swneX
	btr ax, 0
.leave_swneX:
	bt bx, 1
	jnc .leave_neswX
	btr ax, 8
.leave_neswX:

	bt bx, 2
	jnc .leave_nwseY
	btr ax, 1
.leave_nwseY:

	bt bx, 3
	jnc .leave_senwY
	btr ax, 9
.leave_senwY:

	pop ebx
.no_l7:
	ret
.ignore:
	mov byte [ignoreonewayroads], 0
	ret

global RVGetRouteOvertakeing
RVGetRouteOvertakeing:
	mov byte [ignoreonewayroads], 1
	jmp [getroutemap]
	
	


global Class2DrawLandOneWay
Class2DrawLandOneWay:
	call near $
ovar .origfn, -4, $, Class2DrawLandOneWay

#if 0
	cmp byte [curmousetooltype], 1
	je .checkcurmousetoolwintype
	ret
.checkcurmousetoolwintype:
	cmp byte [curmousetoolwintype], 3
	je .buildmode
	ret
.buildmode:
#endif

	pusha

	mov bl,[landscape4(si)]
	shr bl, 4
	cmp bl, 0x2
	jnz .nooneway	// no road tile
 
//	mov edi,[landscape7ptr]
//	or edi,edi
//	jz .no_l7

	mov bx, word [newonewayarrows]
	or bh,bh
	js .nosprites

	xor ebx, ebx
	// display something usefull
	mov bl, byte [landscape7+esi]
	and bl, 0xF
	cmp bl, 0
	je .nooneway
	

	mov edi, ebx
	and ebx, 3

	cmp ebx, 0
	je .testotherbits
	dec ebx
	call .showarrowsprite

.testotherbits:
	mov ebx, edi
	shr ebx, 2
	and ebx, 3
	
	cmp ebx, 0
	je .nomorelayers

	add ebx, 2
	call .showarrowsprite

#if 0
	xor edi, edi
	bt bx, 0
	jnc .notbit0
	call .showarrow
.notbit0:

	inc edi
	bt bx, 1
	jnc .notbit1
	call .showarrow
.notbit1:
	
	inc edi
	bt bx, 2
	jnc .notbit2
	call .showarrow
.notbit2:
	
	inc edi
	bt bx, 3
	jnc .notbit3
	call .showarrow
.notbit3:
	
#endif

.nomorelayers:
.nooneway:
.no_l7:
.nosprites:
	popa
	ret


.showarrowsprite:
	pusha
	add bx, word [newonewayarrows]
	or al, 8
	or cl, 8
	mov si, 4
	mov di, 4
	mov dh, 1
	call [addsprite]
	popa
	ret


#if 0
.showarrow:
	pusha
	movzx ebx, word [newonewayarrows]
	add ebx, edi
	or al, 8
	or cl, 8
	mov si, 4
	mov di, 4
	mov dh, 1
	call [addsprite]
	popa
	ret
#endif

global FailIsRoadPieceBuild
FailIsRoadPieceBuild:
	// in dl = road piece to be build
	// mov ebx, 0x80000000
	test bl, 1
	jz .done
	
	// road laying somehow fires up the code
	cmp byte [curplayerctrlkey],1
	jnz .done

//	mov edi,[landscape7ptr]
//	or edi,edi
//	jz .done
	xor ebx, ebx
	mov bl, byte [landscape7+esi]

	cmp dl, 2
	jnz .leave_swneX
	btc bx, 0
.leave_swneX:

	cmp dl, 8
	jnz .leave_neswX
	btc bx, 1
.leave_neswX:

	cmp dl, 1
	jnz .leave_nwseY
	btc bx, 2
.leave_nwseY:

	cmp dl, 4
	jnz .leave_senwY
	btc bx, 3
.leave_senwY:
	mov byte [landscape7+esi], bl
.done:
	pusha
	call [invalidatetile]
	popa
	mov ebx, 0
	ret
