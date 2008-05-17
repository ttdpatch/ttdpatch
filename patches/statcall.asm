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

// Need for the callback finder
extern miscgrfvar, vehtypecallback, newvehdata

// This generates %1.makestruc, finishes the vehicle-struc initialization, calls the callback, and moves the return value into the veh struc
%macro MAKESTRUC 1-2 0	// Params: Global name, 1 if esi and edi are swapped after calling eax.
ovar %1.makestruc, $, 0
	pop eax
	push ebx
	call eax	// For planes, this swaps esi and edi.
	pop ebx
%if %2
	xchg esi,edi
%endif
	call %1
	mov [esi+veh.maxspeed], ax	// overwritten
%if %2
	xchg esi,edi
%endif
	pop cx				// overwritten
	jmp near $+5
ovar %1.oldfn,-4,$
%endmacro

// This generates %1.noesi, and calls the callback without a vehicle structure
%macro NOESI 1
ovar %1.noesi, $, 0
	push esi
	xor esi, esi
	call %1
	pop esi
	ret
%endmacro

// Train Codes
// Set the global subroutines
global GetTrainCallbackSpeed.lnews, GetTrainCallbackSpeed.doit
global GetTrainCallbackSpeed.lmultihead, GetTrainCallbackSpeed.lwagon

MAKESTRUC GetTrainCallbackSpeed
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
	mov ah, 0xB ; Get the speed value
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
	mov ah, 0x1F ; Get the speed value
	mov al, bl ; Set the system to vehicle id
	call GetCallback36 ; Get the actual value for the TE
	movzx eax, al ; Byte return from callback
	pop ecx

	mov ebx, eax
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

// Gets the speed from callback default if no callback
GetShipCallbackSpeed:
	push ecx
	movzx cx, byte [shipspeed-0xCC+ebx] ; Gets the default speed of the vehicle
	mov ah, 0xB ; Get the speed value
	mov al, bl ; Set the system to vehicle id
	call GetCallback36 ; Get the actual value for the speed
	movzx eax, al ; Byte return from callback
	pop ecx
	ret

MAKESTRUC GetShipCallbackSpeed
NOESI GetShipCallbackSpeed

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

MAKESTRUC GetPlaneCallbackSpeed, 1
NOESI GetPlaneCallbackSpeed

// Run callback 36 for vehicles based off the input value
// input: ah as the property to find (matches Action0 property)
// 	  al as the id to use for type
//	  cx as the default value to use if the callback fails
//	  esi as vehicle id if applable
// out:	eax=callback value
exported GetCallback36
	mov [miscgrfvar],ah
	mov ah, 0x36 ; Id for the callback
	call vehtypecallback ; Get the callback results
	jnc .lresults
	mov ax, cx ; Move default value into ax
.lresults:
	mov byte [miscgrfvar], 0 ; Set this to 0 to avoid errors
	ret
