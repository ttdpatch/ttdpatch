// Busstops
// Copyright 2005 Oskar Eisemuth

#include <std.inc>
#include <station.inc>
#include <veh.inc>
#include <flags.inc>
#include <newvehdata.inc>
#include <pusha.inc>
#include <town.inc>
#include <callttd.inc>

extern DrawStationImageInSelWindow,generatesoundeffect,isrvbus,redrawscreen
extern editTramMode
extern patchflags
extern persgrfdata

// Custom roadside RV stop sprites.
uvarw roadsidervstops, 1, s
var	roadsidervstopsnum, dd 8

// Station layouts have been modified to support custom sprites
// defined by action 5 type 11.
var paStationbusstop1
	dd 1314
	db 0,0,0,16,3,16
.sprite1:
	dd 4079+0x8000
	db 0,13,0,16,3,16
.sprite2:
	dd 4079+0x8000
	db 0x80

var paStationbusstop1Default
	dd 1314
	db 8,14,0,1,2,16
	dd 1407
	db 8,1,0,1,2,16
	dd 1406
	db 9,14,7,2,2,3
	dd 4079
	db 8,1,7,2,2,3
	dd 4079
	db 0x80

var paStationbusstop2
	dd 1313
	db 13,0,0,3,16,16
.sprite1:
	dd 4079+0x8000
	db 0,0,0,3,16,16
.sprite2:
	dd 4079+0x8000
	db 0x80

var paStationbusstop2Default
	dd 1313
	db 1,8,0,2,1,16
	dd 1407
	db 14,8,0,2,1,16
	dd 1406
	db 1,8,7,2,2,3
	dd 4079
	db 14,9,7,2,2,3
	dd 4079
	db 0x80
	
var paStationtruckstop1
	dd 1314
	db 0,0,0,16,3,16
.sprite1:
	dd 4079+0x8000
	db 0,13,0,16,3,16
.sprite2:
	dd 4079+0x8000
	db 0x80

var paStationtruckstop2
	dd 1313
	db 13,0,0,3,16,16
.sprite1:
	dd 4079+0x8000
	db 0,0,0,3,16,16
.sprite2:
	dd 4079+0x8000
	db 0x80

	align 4
var dorvstationcolldet	// bit set = no collision detection for that movement stat
	dd 0			// 00-1F = regular roads
	dd 1100111111001111b	// 20..2F = station, no detection
				// except 24,25,2C,2D = bus stop, detection

uvard rvmovementscheme,1,z
uvarb rvmovementschemestops, 32

uvarb salorrystationguielements, 133	//steven hoefel: added space for two new station styles

varb roadbitstoroute
	db 0, 0, 0, 0x10, 0, 0x2, 0x8, 0x1A, 0, 0x4, 0x1, 0x15, 0x20, 0x26, 0x29, 0x3F
endvar

global NewClass5RouteMapHandler
NewClass5RouteMapHandler:
	cmp ax, 2
	jz .bus
	cmp ax, 4
	jz .ship
	xor eax, eax
	ret
.bus:
	xor eax, eax
	mov byte al, [landscape5(di)]
	cmp al, 0x53		//bus stop
	je .busstop1
	cmp al, 0x55		//truck stop has same movement
	je .busstop1
	cmp al, 0x57		//truck stop has same movement
	je .busstop1
	cmp al, 0x59		//tramfreight stop
	je .busstop1
	cmp al, 0x54		//bus stop
	je .busstop2
	cmp al, 0x56		//truck stop has same movement
	je .busstop2
	cmp al, 0x58		//truck stop has same movement
	je .busstop2
	cmp al, 0x5A		//tram freight stop
	je .busstop2
	cmp al, 0x07
	jbe .railstation
	xor eax, eax
	ret

#if 0
// Is this still needed Steven?
.doNotAllowEntry:
	xor eax, eax	//zero the 'tile route map'
	xor edi, edi	//ruin the landscape XY pointer so that the routemapper wont allow entry.
	ret
#endif

.railstation:
	extern newvehdata
	movzx esi, byte [landscape3+edi*2+1]
	and eax, 0xF
	mov al, byte [stationrventer+esi*8+eax]
	cmp al, 0
	jnz .railrvroute
.errorinstatdata:
	xor eax, eax
	ret
.railrvroute:
	and eax, 1111b
	mov al, byte [roadbitstoroute+eax]
	mov ah, al
	ret
#if 0
	mov ah,[stationrventer+esi*4]
	add al, 8
	bt ax, ax
	jc .railrvroute
	xor eax, eax
	ret
.railrvroute:
	bt ax, 0
	jc .railrvroute2
	mov eax, 0x0202
	ret
.railrvroute2:
	mov eax, 0x0101
	ret
#endif

.busstop1:
	mov ax, 0x0101
	ret
.busstop2:
	mov ax, 0x0202
	ret
.ship:
	mov byte al, [landscape5(di)]
	cmp al, 0x52
	jz .shipgood
	xor eax, eax
	ret
.shipgood:
	mov ax, 0x3F3F
	ret

global Class5VehEnterLeaveBusStop
Class5VehEnterLeaveBusStop:
.justDoNormal:
	cmp	word [edi+veh.nextunitidx], 0xFFFF
	je	.notArticulated
	movzx	ebx, bx
	mov	byte al, [landscape5(bx)]
	cmp	al, 0x53
	jge	.notArticulated
	mov	byte [edi+0x6A], 180 	//UTURN!
	//mov	byte [esi+0x6A], 180 	//UTURN!	<-- JGR: as far as I can tell this is invalid and therefore a bug
	or	ebx, 0x80000000
	jmp	.quit

.notArticulated:
	cmp byte [edi+veh.targetairport], 0
	jz .teststation
.quit:
	add esp, 4
	ret
.teststation:
	movzx ebx, bx
//	cmp byte [edi+veh.cargotype], 0
//	jne .done
	mov byte al, [landscape1+ebx]
	cmp byte [edi+veh.owner], al
	jne .done

	mov byte al, [landscape5(bx)]
	cmp al, 0x07
	jbe .quit

	xchg esi,edi
	call isrvbus
	xchg esi,edi
	// cmp byte [edi+veh.cargotype], 0
	jne .truck

	cmp al, 0x53
	jl .done
	cmp al, 0x56
	jle .busstop
	jmp .done
.truck:
	cmp al, 0x57
	jl .done
	cmp al, 0x5A
	jle .busstop
.done:
	ret

.busstop:
	mov dx, [edi+veh.currorder]
	mov ax, dx

	and dl,0x1f
	cmp dl,1	// order = station
	jne .busstopdone


//	or al, al	// nonstop
	//js .stopalwaysflag

	mov dl, byte [landscape2+ebx]
	cmp dl, dh
	jne .busstopdone
.stopalwaysflag:

	//waypoint
	movzx eax, dl
	mov ah,station_size
	mul ah
	add eax,[stationarrayptr]
	test byte [eax+station.flags],1<<6	// waypoint?
	jnz .nonstop

	mov ah, [edi+veh.movementstat]
	add ah, 0x20
	add ah, 4
	mov byte [edi+veh.movementstat], ah
.busstopdone:
	add esp, 4
	ret


.nonstop:
	inc byte [edi+veh.currorderidx]	// switch to next command
	mov word [edi+veh.currorder],0	// clear current next station
	and word [edi+veh.traveltime],0	// record that the vehicle isn't lost
	jmp .busstopdone


global Class5CreateBusStationAction
Class5CreateBusStationAction:
	cmp bh, 4
	jb .done
	bt ebx, 7
	jnc .dontAddTramStopOffset
	add bh, 2					//set it to be a tram stop
.dontAddTramStopOffset:
	add bh, 6					//set it to be a bus stop
.done:
	jmpttd Class5CreateBusStationAction

uvard oldclass5createtruckstation,1,z
global Class5CreateTruckStationAction
Class5CreateTruckStationAction:
	cmp bh, 4
	jb .done
	bt ebx, 7
	jnc .dontAddTramFreightStopOffset
	add bh, 2
.dontAddTramFreightStopOffset:
	add bh, 0x0E
.done:
	jmp [oldclass5createtruckstation]

// in:	Return from DoAction RemoveEverythingOnTile
//	on stack: di, dx, bx
//		bh: direction
//
// out:	ebx: price
//	zf set for cmp ebx, 80000000h
extern gettileinfo
exported Class5CreateStationCheckRemove
	cmp ebx, 80000000h
	jne short .done
	pusha
	mov bh, [esp+20h+4+4+1]
	cmp bh, 3			// Building old-style stations.
	jbe .nogood
	push ebx
	call [gettileinfo]
	cmp bx, 2*8
	pop ebx
	jne .nogood

// Overbuilding a road tile

	test dh, 0F0h
	jnz .nogood

// Not a depot or crossing.

	mov al, [esi+landscape1]
	test al, 80h
	jnz .ownerOK
	
	cmp al, [curplayer]
	jne .nogood
	
.ownerOK:
	mov dl, [esi*2+landscape3]	// dx is ????ROAD????TRAM
	mov cl, bh
	and cl, 1			// cl == 1 if station in X dir
	shl edx, cl			// Now, for a valid tile, no bits in dh/dl other than 1 and 3 may be set
	
	// Check road pieces.
	test dx, ~0A0Ah
	jnz .nogood

	test bh, 2
	jnz .roadlayoutok

	// this is a road station; don't remove tram tracks
	test dl, dl
	jnz short .nogood

.roadlayoutok:
	popa
	extern stationbuildcostptr
	mov edi, [stationbuildcostptr]
	sub [edi], ebx
	test esp,esp			// clz
.done:
	ret
	
.nogood:
	popa
	cmp esp, esp			// stz
	ret

exported Class5CreateStation
	and word [landscape3+edi*2], 0
	test bh, 2
	jz .notTramStop
	or byte [landscape3+edi*2], 1<<4
.notTramStop:
	mov al, [landscape4(di,1)]	// overwritten
	cmp al, 20h
	jb .notoverbuilding
	test byte [landscape1+edi], 80h
	jz .notoverbuilding
	or byte [landscape3+edi*2], 1<<7
.notoverbuilding:
#if !WINTTDX
	and al, 0Fh			// overwritten
#endif
	ret

exported Class5RemoveDriveThrough
	test bl, 1
	jz short .ret
	pusha
	call [gettileinfo]
	lea edi, [landscape3+esi*2]
	test byte [edi], 80h
	jz short .notOverbuilt

	xor eax,eax
	mov [landscape2+esi], al
	mov [edi], ax


	mov al, [landscape4(si,1)]
	and al, 0Fh
	or al, 20h
	mov [landscape4(si,1)], al

	mov al, 0Ah
	test dh,1 
	jnz .ok
	mov al, 5
.ok:
	mov byte [landscape5(si,1)],al
	test dh, 3
	jp .notrams
	mov [edi], al
.notrams:

	xchg eax, esi
	extcall findnearesttown
	xchg eax, esi

	// Get town index
	sub edi, townarray
	xor eax, eax
	mov al, town_size
	xchg eax, edi
	cdq			// edx:eax is array offset, edi is town_size
	div edi
	or al, 80h
	mov [landscape1+esi], al
	popa

.ret:
	ret
	
.notOverbuilt:
	popa
	chainjmp Class5RemoveDriveThrough


global Class5ClearTileBusStop
Class5ClearTileBusStop:
	cmp dh, 0x47
	jb .done
	cmp dh, 0x4B
	jb .removeit
	cmp dh, 0x53
	jl .done
	cmp dh, 0x56
	jle .removeit
.done:
	clc
	ret
.removeit:
	stc
	ret

global Class5ClearTileTruckStop
Class5ClearTileTruckStop:
	cmp dh, 0x43
	jb .done
	cmp dh, 0x47
	jb .removeit
	cmp dh, 0x57
	jl .done
	cmp dh, 0x5A
	jle .removeit
.done:
	clc
	ret
.removeit:
	stc
	ret

global Class5ClearTileBusStopError
Class5ClearTileBusStopError:
	cmp dh, 0x4B
	jb .error
	cmp dh, 0x53
	jl .noerror
	cmp dh, 0x56
	jle .error
.noerror:
	ret
.error:
	add esp, 4
	mov ebx, 0x80000000
	ret

global Class5ClearTileTruckStopError
Class5ClearTileTruckStopError:
	cmp dh, 0x47
	jb .error
	cmp dh, 0x57
	jl .noerror
	cmp dh, 0x5A
	jle .error
.noerror:
	ret
.error:
	add esp, 4
	mov ebx, 0x80000000
	ret


global Class5QueryHandlerBusStop
Class5QueryHandlerBusStop:
	mov ax, 0x3062
	cmp cl, 0x53
	jl .doNormal
	cmp cl, 0x56
	jle .busstop
.doNormal:
	cmp cl, 0x4B
	ret
.busstop:
	stc
	ret

global Class5QueryHandlerTruckStop
Class5QueryHandlerTruckStop:
	mov ax, 0x3061
	cmp cl, 0x57
	jl .doNormal
	cmp cl, 0x5A
	jle .truckstop
.doNormal:
	cmp cl, 0x47
	ret
.truckstop:
	stc
	ret


global RVMakeStationBusywhenleaving
RVMakeStationBusywhenleaving:
	movzx eax,word [esi+veh.XY]
	mov byte al, [landscape5(ax,1)]
	pushad
	call isrvbus
	popad
	jne .truck
	cmp al, 0x53
	jl .done
	cmp al, 0x56
	jle .busstop
	jmp short .done
.truck:
	cmp al, 0x57
	jl .done
	cmp al, 0x5A
	jle .busstop
.done:
	or byte [ebx+ebp], 0x80
.busstop:
	mov ax, [esi+veh.currorder]
	ret

// GUI
var newbusorienttooltips
	dw 0x18B, 0x18C, 0, 0x3051, 0x3051, 0x3051, 0x3051, 0x3065, 0x3064, 0x3051, 0x3051
var newtruckorienttooltips
	dw 0x18B, 0x18C, 0, 0x3052, 0x3052, 0x3052, 0x3052, 0x3065, 0x3064, 0x3052, 0x3052

global BusLorryStationDrawHandler
BusLorryStationDrawHandler:
	call [DrawStationImageInSelWindow]
;	cmp bl, 0x43				removed the bus stop check, we want this working
;	jnz .busstops				with trucks now... and have added the truck stop
;	ret					pointers below
;.busstops:
	cmp byte [editTramMode], 1
	jz .drawTramStops
	pusha
	add cx, 0x44
	cmp bl, 0x43
	jnz .firstBusStop
	mov bl, 0x57		//move in truck stop
	jmp .firstStopSet
.firstBusStop:
	mov bl, 0x53		//move in bus stop
.firstStopSet:
	xor al, al
	call [DrawStationImageInSelWindow]
	cmp bl, 0x57
	jnz .secondBusStop
	mov bl, 0x58		//move in truck stop
	jmp .secondStopSet
.secondBusStop:
	mov bl, 0x54		//move in bus stop
.secondStopSet:
	add dx, 0x34
	xor al, al
	call [DrawStationImageInSelWindow]
	popa
	ret
.drawTramStops:
	pusha
	add cx, 0x44
	cmp bl, 0x43
	jnz .firstTramStop
	mov bl, 0x59		//move in truck stop
	jmp .firstTramStopSet
.firstTramStop:
	mov bl, 0x55
.firstTramStopSet:
	xor al, al
	call [DrawStationImageInSelWindow]
	cmp bl, 0x59
	jnz .secondTramStop
	mov bl, 0x5A		//move in truck stop
	jmp .secondTramStopSet
.secondTramStop:
	mov bl, 0x56		//move in bus stop
.secondTramStopSet:
	add dx, 0x34
	xor al, al
	call [DrawStationImageInSelWindow]
	popa
	ret


global BusLorryStationWindowClickHandler
BusLorryStationWindowClickHandler:
	cmp cl, 7
	jb .changeorient
	cmp cl, 8
	ja .changeorient
	ret

.changeorient:
	pusha
	mov esi, 0
	mov eax, 0x13
	call [generatesoundeffect]
	popa
	pop esi			// Return from caller. ESI because it is popped again after we return.
	sub cl, 3
.done:
	testmultiflags trams
	jz .dontDefaultToDriveThrough
	cmp byte [editTramMode], 1
	jnz .dontDefaultToDriveThrough
	cmp cl, 3
	jg .dontDefaultToDriveThrough
	mov cl, 6
.dontDefaultToDriveThrough:
	mov byte [buslorrystationorientation], cl
	jmp redrawscreen

// Inspired by steven's tram station code.
// Updates sprite numbers in station layouts to use custom sprites
// defined by action 5 type 11.
//
// Complete rewrite by eis_os:
// - support company colors,
// - failback for busstops to default spritelayout
// - code optimize

extern ttdpatchstationspritelayout
exported updateRVStopSpriteLayout
	push ecx
	cmp word [roadsidervstops], -1
	jne .newsprites
	mov ecx, [ttdpatchstationspritelayout]
	add ecx, 0x53*4
	mov dword [ecx],paStationbusstop1Default
	mov dword [ecx+4],paStationbusstop2Default
	pop ecx
	ret
	
.newsprites:
	mov ecx, [ttdpatchstationspritelayout]
	add ecx, 0x53*4
	mov dword [ecx], paStationbusstop1
	mov dword [ecx+4],paStationbusstop2
	
	// Update bus stop sprites
	movzx ecx, word [roadsidervstops]
	or ecx, 0x8000	// enable company colors
	// offset 0x00
	mov dword [paStationbusstop2.sprite1], ecx
	inc ecx	// offset now 0x01
	mov dword [paStationbusstop2.sprite2], ecx
	
	inc ecx	// offset now 0x02
	mov dword [paStationbusstop1.sprite1], ecx
	inc ecx	// offset now 0x03
	mov dword [paStationbusstop1.sprite2], ecx
	
	// Update truck stop sprites
	movzx ecx, word [roadsidervstops]
	add cx, 04h
	or ecx, 0x8000	// company colors
	mov dword [paStationtruckstop2.sprite1], ecx
	
	inc ecx	// offset now 0x05
	mov dword [paStationtruckstop2.sprite2], ecx
	
	inc ecx	// offset now 0x06
	mov dword [paStationtruckstop1.sprite1], ecx
	
	inc ecx	// offset now 0x07
	mov dword [paStationtruckstop1.sprite2], ecx
	pop ecx
	ret

