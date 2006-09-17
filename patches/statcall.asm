// Created By Lakie, January 2006
//
// This houses the code for allowing callbacks to change vehicle statistics
// Currently only Trains and Ships supportted

// Requires the following things
#include <std.inc> // Must be inclided first
#include <misc.inc>
#include <flags.inc>
#include <ptrvar.inc>
#include <textdef.inc>
#include <newvehdata.inc>

// Need for the callback finder
extern miscgrfvar, vehtypecallback, newvehdata

// Train Codes
// Set the global subroutines
global TrainSpeedNewVehicleHandler, TrainSpeedNewVehicleHandler.lnews
global TrainSpeedBuyNewVehicle, TrainSpeedBuyNewVehicle.lmultihead, TrainSpeedBuyNewVehicle.lwagon

// Buy Train Window Changer
TrainSpeedNewVehicleHandler:
	push esi
	xor esi, esi
	xor eax, eax ; Blank the whole of eax
	call GetTrainCallBackSpeed ; Get the New Speed
	pop esi
	ret

.lnews:
	push esi
	xor esi, esi
	push eax
	call GetTrainCallBackSpeed ; Get the New Speed
	mov ebx, eax
	pop eax
	pop esi
	ret

TrainSpeedBuyNewVehicle:
	push esi
	xor esi, esi
	xor eax, eax ; Blank eax
	call GetTrainCallBackSpeed
	pop esi
	ret

.lmultihead:
	push eax
	call GetTrainCallBackSpeed
	movzx ecx, ax
	pop eax
	ret

.lwagon:
	push esi
	xor esi, esi
	push eax
	call GetTrainCallBackSpeed
	mov bx, ax
	pop eax
	imul bx, 10
	pop esi
	ret

// Gets the speed from callback default if no callback
GetTrainCallBackSpeed:
	push ecx
	mov cx, [trainspeeds+ebx*2] ; Gets the default speed of the vehicle
	mov ah, 0x9 ; Get the speed value
	mov al, bl ; Set the system to vehicle id
	call GetCallBack36 ; Get the actual value for the speed
	pop ecx
	ret

// Used as a generic code replacer for powers
global TrainPowerGeneric, TrainPowerGeneric.lecx, TrainPowerGeneric.leax
TrainPowerGeneric:
	push ecx
	push ebx
	push esi
	xor esi, esi
.lstart:
	movzx ecx, word [trainpower+ebx*2] ; Gets the default speed of the vehicle
	mov ah, 0xB ; Get the speed value
	mov al, bl ; Set the system to vehicle id
	call GetCallBack36 ; Get the actual value for the speed
	pop esi
	pop ebx
	pop ecx
	ret

.leax:
	push ecx
	push ebx
	push esi
	mov ebx, eax
	jmp TrainPowerGeneric.lstart ; Jump to top of subroutine

.lecx:
	push eax
	xor eax, eax
	movzx ecx, word [trainpower+ebx*2] ; Gets the default speed of the vehicle
	mov ah, 0xB ; Get the speed value
	mov al, bl ; Set the system to vehicle id
	call GetCallBack36 ; Get the actual value for the speed
	mov ecx, eax
	pop eax
	ret

// Used as a generic code to replace the te coffient
global TrainTEGeneric, TrainTEGeneric.lebx
TrainTEGeneric:
	push ecx
	push esi
	xor esi, esi
	movzx ecx, byte [traintecoeff+ebx] ; Get the orginal TE coffient
	mov ah, 0x1F ; Get the speed value
	mov al, bl ; Set the system to vehicle id
	call GetCallBack36 ; Get the actual value for the TE
	and eax, 0xFF ; Byte return from callback
	pop esi
	pop ecx
	ret

.lebx:
	push eax
	push ecx
	movzx ecx, byte [traintecoeff+ebx] ; Get the orginal TE coffient
	mov ah, 0x1F ; Get the speed value
	mov al, bl ; Set the system to vehicle id
	call GetCallBack36 ; Get the actual value for the TE
	and eax, 0xFF ; Byte return from callback
	mov ebx, eax
	pop ecx
	pop eax
	ret

// Boats Codes
// Sets the globals up
global GetShipCallBackSpeed

// Gets the speed from callback default if no callback
GetShipCallBackSpeed:
	push ecx
	push esi
	xor esi, esi
	movzx cx, byte [shipspeed-0xCC+ebx] ; Gets the default speed of the vehicle
	mov ah, 0xB ; Get the speed value
	mov al, bl ; Set the system to vehicle id
	call GetCallBack36 ; Get the actual value for the speed
	and eax, 0xFF ; Byte return from callback
	pop esi
	pop ecx
	ret

// Plane Codes
// Sets the globals up
global GetPlaneCallBackSpeed

// Gets the speed from callback default if no callback
GetPlaneCallBackSpeed:
	push ecx
	push esi
	xor esi, esi
	movzx cx, byte [planedefspeed-0xD7+ebx] ; Gets the default speed of the vehicle
	mov ah, 0xC ; Get the speed value
	mov al, bl ; Set the system to vehicle id
	call GetCallBack36 ; Get the actual value for the speed
	and eax, 0xFF ; Byte return from callback
	pop esi
	pop ecx
	ret

// Run callback 36 for vehicles based off the input value
// input: ah as the property to find (matches Action0 property)
// 	  al as the id to use for type
//	  cx as the default value to use if the callback fails
//	  esi as vehicle id if applable
// out:	eax=callback value
exported GetCallBack36
	mov [miscgrfvar], ah
	mov ah, 0x36 ; Id for the callback
	call vehtypecallback ; Get the callback results
	jnc .lresults
	mov ax, cx ; Move default value into ax
.lresults:
	mov byte [miscgrfvar], 0 ; Set this to 0 to avoid errors
	ret
