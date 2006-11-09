// Busstops
// Copyright 2005 Oskar Eisemuth

#include <std.inc>
#include <station.inc>
#include <veh.inc>
#include <flags.inc>
#include <newvehdata.inc>

extern DrawStationImageInSelWindow,generatesoundeffect,isrvbus,redrawscreen
extern editTramMode
extern patchflags
extern persgrfdata
extern adjflags


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
	dd 4079
	db 0x80

var paStationtruckstop1
	dd 1314
	db 8,14,0,1,2,16
	dd 1407
	db 6,14,10,1,2,8
	dd 4300
	db 14,14,10,1,2,8
	dd 4302
	db 0x80

var paStationtruckstop2
	dd 1313
	db 2,4,0,2,1,16
	dd 1407
	db 0,8,4,1,2,8
	dd 4300
	db 0,4,4,1,2,8
	dd 4302
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
	mov	byte [esi+0x6A], 180 	//UTURN!
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


uvard oldclass5createbusstation,1,z
global Class5CreateBusStationAction
Class5CreateBusStationAction:
	cmp DWORD [adjflags], 0
	jne .done
	cmp bh, 4
	jb .done
	testmultiflags trams				//trams enabled?
	jz .dontAddTramStopOffset
	cmp byte [editTramMode], 1			//currently adding trams?
	jnz .dontAddTramStopOffset
	add bh, 8					//set it to be a standard bus stop
	jmp short .done
.dontAddTramStopOffset:
	add bh, 8-2					//set it to be a tram stop
.done:
	jmp [oldclass5createbusstation]

uvard oldclass5createtruckstation,1,z
global Class5CreateTruckStationAction
Class5CreateTruckStationAction:
	cmp DWORD [adjflags], 0
	jne .done
	cmp bh, 4
	jb .done
	testmultiflags trams
	jz .dontAddTramFreightStopOffset
	cmp byte [editTramMode], 1
	jnz .dontAddTramFreightStopOffset
	add bh, 0x10
	jmp short .done
.dontAddTramFreightStopOffset:
	add bh, 0x0E
.done:
	jmp [oldclass5createtruckstation]

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
