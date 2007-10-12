// Created By Lakie, January 2006
//
// This houses form fragments for allowing callbacks to change vehicle statistics
// Currently only Trains and Ships supportted


// Needed for the fragments and replacement code
#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>
#include <ptrvar.inc>
#include <textdef.inc>

// Procedures
patchproc newtrains, patchtrainstat
patchproc newships, patchshipstat
patchproc newplanes, patchplanestat

begincodefragments
// Trains
	; These fragments are for finding the places where speed is used in ttd
	codefragment oldtrainspeednewwehiclehandler
		movzx eax, word [nosplit trainspeeds+ebx*2]
	codefragment oldtrainbuyvehiclespeed
		mov ax, [nosplit trainspeeds+ebx*2]

	; Replacement Fragments for speed usage
	codefragment_call newtrainspeednewwehiclehandler, GetTrainCallbackSpeed.noesi, 8
	codefragment_call newtrainbuyvehiclespeed, GetTrainCallbackSpeed.makestruc, 12

	; These fragments are for power
	codefragment oldtrainpowergeneric
		mov ax, [nosplit trainpower+ebx*2]
	codefragment_call newtrainpowergeneric, TrainPowerGeneric, 8

// Ships
	; These fragments are for finding the places where speed is used in ttd
	codefragment oldshipspeednewwehiclehandler
		movzx eax, byte [shipspeed-0xCC+ebx]
		db 66h, 6Bh	//imul r16, ...
	reusecodefragment oldshipspeedbuyvehiclespeed, oldshipspeednewwehiclehandler, -1, 7
		// movzx ax, byte [shipspeed-0xCC+ebx]
	; Replacement Fragments for speed usage
	codefragment_call newshipspeednewwehiclehandler, GetShipCallbackSpeed.noesi, 7
	codefragment_call newshipspeedbuyvehiclespeed, GetShipCallbackSpeed.makestruc, 12

// Planes
	; These fragments are for finding the places where speed is used in ttd
	codefragment oldplanespeednewwehiclehandler
		movzx ax, byte [planedefspeed-0xD7+ebx]

	; Replacement Fragments for speed usage
	codefragment_call newplanespeednewwehiclehandler, GetPlaneCallbackSpeed.makestruc, 12

	; Replace it with a special menu one (for no vehicle)
	codefragment_call newplanespeednewwehiclehandler2, GetPlaneCallbackSpeed.noesi, 8

	codefragment endstrucinit
		pop cx
		pop ebx

endcodefragments

; These active the codefragments
patchtrainstat:
	; Power Fragments
	multipatchcode trainpowergeneric, 2

	; Speed Fragments
	multipatchcode trainspeednewwehiclehandler, 2
	patchcode trainbuyvehiclespeed
	extern GetTrainCallbackSpeed.oldfn
	mov ebx, GetTrainCallbackSpeed.oldfn

// fallthrough

patchendstrucinit:
	stringaddress endstrucinit, 1, 0
	mov byte [edi], 0xC3
	storerelative ebx, edi+2
	ret

patchshipstat:
	; Speed Fragments
	multipatchcode shipspeednewwehiclehandler, 2
	patchcode shipspeedbuyvehiclespeed
	extern GetShipCallbackSpeed.oldfn
	mov ebx, GetShipCallbackSpeed.oldfn
	jmp patchendstrucinit

patchplanestat:
	; Speed Fragments
	patchcode planespeednewwehiclehandler, 2, 3
	extern GetPlaneCallbackSpeed.oldfn
	mov ebx, GetPlaneCallbackSpeed.oldfn
	call patchendstrucinit
	multipatchcode oldplanespeednewwehiclehandler, newplanespeednewwehiclehandler2, 2
	ret


