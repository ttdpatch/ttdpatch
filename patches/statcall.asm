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
#include <veh.inc>

#include "statcall.ah"

// Need for the callback finder
extern miscgrfvar, vehtypecallback, newvehdata

// Train Codes
// Set the global subroutines
global GetTrainCallbackSpeed.lnews, GetTrainCallbackSpeed.doit
global GetTrainCallbackSpeed.lmultihead, GetTrainCallbackSpeed.lwagon

MAKESTRUC_WORD GetTrainCallbackSpeed, maxspeed
NOESI GetTrainCallbackSpeed

// Buy Train Window Changer
GetTrainCallbackSpeed:
	xor eax, eax ; Blank the whole of eax
.doit:
	push ecx
	mov cx, [trainspeeds+ebx*2] ; Gets the default speed of the vehicle
	mov ah, 0x9 ; Get the speed value
	mov al, bl ; Set the system to vehicle id
	call GetCallback36 ; Get the actual value for the speed
	pop ecx
	ret

.lnews:
	push eax
	call .noesi ; Get the New Speed
	mov ebx, eax
	pop eax
	ret

.lmultihead:
	push eax
	call .doit
	movzx ecx, ax
	pop eax
	ret

.lwagon:
	push eax
	call .noesi
	imul bx, ax, 10
	pop eax
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
	call GetCallback36 ; Get the actual value for the speed
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
	movzx ecx, word [trainpower+ebx*2] ; Gets the default speed of the vehicle
	movzx eax, bl ; Set the system to vehicle id
	mov ah, 0xB ; Get the power value
	call GetCallback36 ; Get the actual value for the speed
	mov ecx, eax
	pop eax
	ret

// Used as a generic code to replace the te coffient
global TrainTEGeneric, TrainTEGeneric.lebx
TrainTEGeneric:
	push esi
	xor esi, esi
	push ebx
	call .lebx
	mov eax, ebx
	pop ebx
	pop esi
	ret

.lebx:
	push eax

	push ecx
	movzx ecx, byte [traintecoeff+ebx] ; Get the orginal TE coffient
	mov ah, 0x1F ; Get the te value
	mov al, bl ; Set the system to vehicle id
	call GetCallback36 ; Get the actual value for the TE
	movzx eax, al ; Byte return from callback
	pop ecx

	mov ebx, eax
	pop eax
	ret

FIRST MAKESTRUC_WORD GetTrainCapacityGeneric, capacity, CallbackBeforeSecond
FIRST MAKESTRUC_WORD GetWagonCapacityGeneric, capacity
NOESI GetTrainCapacityGeneric

global GetTrainCapacityGeneric, GetTrainCapacityGeneric.esi
global GetTrainCapacityGeneric.edx, GetWagonCapacityGeneric
GetWagonCapacityGeneric:
GetTrainCapacityGeneric:
	push ecx
	movzx ecx, byte [traincargosize+ebx]
	mov ah, 0x14 ; Get the capacity
	mov al, bl
	call GetCallback36
	movzx eax, ax
	pop ecx
	ret

.esi:
	push esi
	push ecx
	movzx ecx, byte [traincargosize+esi]
	mov eax, esi
	mov ah, 0x14 ; Get the capacity
	xor esi, esi
	call GetCallback36
	movzx esi, ax
	pop ecx
	pop esi
	ret

.edx:
	push eax
	push ecx
	movzx ecx, byte [traincargosize+edx]
	mov ah, 0x14 ; Get the capacity
	mov al, dl
	call GetCallback36
	movzx ebx, ax
	pop ecx
	pop eax
	ret

global GetTrainCapacityNoDefault
GetTrainCapacityNoDefault:
	push eax
	push ecx
	push dword [miscgrfvar] ; Due to "articulatedvehicle" being the same var we need to preserve it
	
	movzx ecx, byte [traincargosize+edx]
	mov al, dl
	mov byte [miscgrfvar], 0x14 ; Get the capacity
	mov ah, 0x36 ; Id for the callback
	call vehtypecallback ; Get the callback results
	jc .lnoresults
	movzx ebx, ax

.lnoresults:
	pop dword [miscgrfvar] ; Restore the old value of "articulatedvehicle"
	pop ecx
	pop eax
	ret

// Used to fetch the weight of a railvehicle
// Output: ecx - weight (low + high bytes)
// (Note that output is in ecx and not eax because of multihd.asm)
global TrainWeightGeneric, TrainWeightGeneric.lshowengine
global TrainWeightGeneric.lshowwagon
TrainWeightGeneric:
	push eax
	movzx ecx, byte [trainweight+ebx] ; Build up the vehicles weight from its two properties
	add ch, byte [railvehhighwt+ebx]

	mov ah, 0x16 ; Fetch the weight value (warning return is 15 bits as we do not check both parts)
	mov al, bl
	call GetCallback36
	movzx ecx, ax ; We have a word return for this value
	pop eax
	ret

// Variants for the show vehicle info hooks
// Input: edi - text stack pointer (-6 word) is the weight
//		  ebx - vehicle type
.lshowengine:
	push esi
	push ecx
	xor esi, esi
	call TrainWeightGeneric ; Get our new weight and finally store it
	test byte [numheads+ebx], 1
	jz .notdualheaded
	shl cx, 1
	
.notdualheaded:
	mov word [edi + 4], cx
	pop ecx
	pop esi
	ret

.lshowwagon:
	push esi
	push ecx
	xor esi, esi
	call TrainWeightGeneric ; Get our new weight and finally store it
	mov word [ebp + 4], cx
	pop ecx
	pop esi
	ret

// Boats Codes

// Gets the value from the callback / default
GetShipValue:
	push ecx
	movzx ecx, byte [shipcostfactor+ebx-0xCC]
	mov ah, 0xA
	mov al, bl
	call GetCallback36
	movzx eax, al
	pop ecx
	ret

GetShipValueEbx:
	push eax
	call GetShipValue
	mov ebx, eax
	pop eax
	ret

NOESI GetShipValue
NOESI GetShipValueEbx

// Gets the speed from callback default if no callback
global GetShipCallbackSpeed
GetShipCallbackSpeed:
	push ecx
	movzx cx, byte [shipspeed-0xCC+ebx] ; Gets the default speed of the vehicle
	mov ah, 0xB ; Get the speed value
	mov al, bl ; Set the system to vehicle id
	call GetCallback36 ; Get the actual value for the speed
	movzx eax, al ; Byte return from callback
	pop ecx
	ret

NOESI GetShipCallbackSpeed

// Gets the capacity for the gui and buyShip routine
GetShipCapacity:
	push ecx
	mov cx, word [nosplit shipcapacity-0x198+ebx*2]
	mov ah, 0xD
	mov al, bl
	call GetCallback36
	movzx eax, ax ; Capacity can be upto a word
	pop ecx
	ret

FIRST MAKESTRUC_WORD GetShipCapacity, capacity
NOESI GetShipCapacity

// Plane Codes

// Gets the speed from callback default if no callback
GetPlaneCallbackSpeed:
	push ecx
	movzx cx, byte [planedefspeed-0xD7+ebx] ; Gets the default speed of the vehicle
	mov ah, 0xC ; Get the speed value
	mov al, bl ; Set the system to vehicle id
	call GetCallback36 ; Get the actual value for the speed
	movzx eax, al ; Byte return from callback
	pop ecx
	ret

FIRST MAKESTRUC_WORD GetPlaneCallbackSpeed, maxspeed, CallbackAfterSecond
NOESI GetPlaneCallbackSpeed

// Run callback 36 for vehicles based off the input value
// input: ah as the property to find (matches Action0 property)
// 	  al as the id to use for type
//	  cx as the default value to use if the callback fails
//	  esi as vehicle id if applable
// out:	eax=callback value
exported GetCallback36
	push dword [miscgrfvar] ; Due to "articulatedvehicle" being the same var we need to preserve it
	mov [miscgrfvar],ah
	mov ah, 0x36 ; Id for the callback
	call vehtypecallback ; Get the callback results
	jnc .lresults
	mov ax, cx ; Move default value into ax
.lresults:
	pop dword [miscgrfvar] ; Restore the old value of "articulatedvehicle"
//	mov byte [miscgrfvar], 0 ; Set this to 0 to avoid errors
	ret
