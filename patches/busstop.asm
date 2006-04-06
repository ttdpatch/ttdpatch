// Busstops
// Copyright 2005 Oskar Eisemuth

#include <std.inc>
#include <station.inc>
#include <veh.inc>
#include <flags.inc>

extern DrawStationImageInSelWindow,generatesoundeffect,isrvbus,redrawscreen
extern editTramMode
extern patchflags




uvarb paStationEntry1, 28

var paStationbusstop1
	dd 1314
	db 8,14,0,1,2,16
	dd 1407
	db 8,1,0,1,2,16
	dd 1406
	db 9,14,7,2,2,3
	dd 4079
	db 8,1,7,2,2,3
	dd 4079 //will be replaced, as much data already filled in
	db 0x80,0,0,1,2,16 //BLANK SPaCE FOR TRAM STOP Stuff
	dd 4079	//unknown		  //inserted on the fly!
	db 8,14,0,1,2,16
	dd 4079 //unknown
	db 8,14,0,1,2,16
	dd 4079 //unknown
	db 8,14,0,1,2,16
	dd 4079
	db 0x80

var paStationbusstop2
	dd 1313
	db 1,8,0,2,1,16
	dd 1407
	db 14,8,0,2,1,16
	dd 1406
	db 1,8,7,2,2,3
	dd 4079
	db 14,9,7,2,2,3
	dd 4079 //will be replaced, as much data already filled in
	db 0x80,0,0,1,2,16 //BLANK SPaCE FOR TRAM STOP Stuff
	dd 4079	//unknown		  //inserted on the fly!
	db 8,14,0,1,2,16
	dd 4079 //unknown
	db 8,14,0,1,2,16
	dd 4079 //unknown
	db 8,14,0,1,2,16
	dd 4079
	db 0x80

	align 4
var dorvstationcolldet	// bit set = no collision detection for that movement stat
	dd 0			// 00-1F = regular roads
	dd 1100111111001111b	// 20..2F = station, no detection
				// except 24,25,2C,2D = bus stop, detection

uvard rvmovementscheme,1,z
uvarb rvmovementschemestops, 32

uvarb salorrystationguielements, 109

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
	cmp al, 0x53
	je .busstop1
	cmp al, 0x54
	je .busstop2
//	cmp al, 0x07
//	jbe .railstation
	xor eax, eax
	ret

#if 0
.railstation:
	CALLINT3
	nop
	nop
	nop
	mov ax, 0x0101
	nop
	nop
	nop
	nop
	nop
	nop
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
	jne .done

	cmp al, 0x53
	je .busstop
	cmp al, 0x54
	je .busstop
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


uvard oldclass5createbusstation,1,z
global Class5CreateBusStationAction
Class5CreateBusStationAction:
	cmp bh, 4
	jb .done
	add bh, 8-2
.done:
	jmp [oldclass5createbusstation]


global Class5ClearTileBusStop
Class5ClearTileBusStop:
	cmp dh, 0x47
	jb .done
	cmp dh, 0x4B
	jb .removeit
	cmp dh, 0x53
	je .removeit
	cmp dh, 0x54
	je .removeit
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
	je .error
	cmp dh, 0x54
	je .error
	ret
.error:
	add esp, 4
	mov ebx, 0x80000000
	ret


global Class5QueryHandlerBusStop
Class5QueryHandlerBusStop:
	mov ax, 0x3062
	cmp cl, 0x53
	je .busstop
	cmp cl, 0x54
	je .busstop
	cmp cl, 0x4B
	ret
.busstop:
	stc
	ret


global RVMakeStationBusywhenleaving
RVMakeStationBusywhenleaving:
	movzx eax,word [esi+veh.XY]
	mov byte al, [landscape5(ax,1)]
	cmp al, 0x53
	je .busstop
	cmp al, 0x54
	je .busstop
	or byte [ebx+ebp], 0x80
.busstop:
	mov ax, [esi+veh.currorder]
	ret

// GUI
var newbusorienttooltips
	dw 0x18B, 0x18C, 0, 0x3051, 0x3051, 0x3051, 0x3051, 0x3065, 0x3064, 0x3051, 0x3051


global BusLorryStationDrawHandler
BusLorryStationDrawHandler:
	call [DrawStationImageInSelWindow]
	cmp bl, 0x43
	jnz .busstops
	ret
.busstops:
	pusha
	add cx, 0x44
	mov bl, 0x53
	xor al, al
	call [DrawStationImageInSelWindow]
	mov bl, 0x54
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

uvard oldclass5createlorrywinorient,1,z

global Class5CreateLorryWinOrient
Class5CreateLorryWinOrient:
	cmp byte [buslorrystationorientation], 4
	jb .done
	mov byte [buslorrystationorientation], 0
.done:
	jmp [oldclass5createlorrywinorient]
