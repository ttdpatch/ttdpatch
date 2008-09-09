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
	
	; These fragments as for capacity
	codefragment oldtraincapacity
		movzx ax, byte [traincargosize+ebx]
	codefragment_call newtraincapacity, GetTrainCapacityGeneric.noesi, 8
	codefragment_call newtraincapacitybuy, GetTrainCapacityGeneric.makestruc, 12
	codefragment_call newwagoncapacitybuy, GetWagonCapacityGeneric.makestruc, 12

// Ships
	; These fragments are for finding the places where speed is used in ttd
	codefragment oldshipspeednewwehiclehandler
		movzx eax, byte [shipspeed-0xCC+ebx]
		db 66h, 6Bh	//imul r16, ...
	reusecodefragment oldshipspeedbuyvehiclespeed, oldshipspeednewwehiclehandler, -1, 7
		// movzx ax, byte [shipspeed-0xCC+ebx]
	; Replacement Fragments for speed usage
	codefragment_call newshipspeednewwehiclehandler, GetShipCallbackSpeed.noesi, 7
	codefragment_call newshipspeedbuyvehiclespeed, GetShipCallbackSpeed, 8

	; Places that Ship's value mainly buy menu
	codefragment oldshipvalue
		movzx eax, byte [shipcostfactor+ebx-0xCC]
	codefragment oldshipvaluereturn
		movzx ebx, byte [shipcostfactor+ebx-0xCC]

	; Our replacements for these places in TTD  (all no esi)
	codefragment_call newshipvalue, GetShipValue.noesi, 7
	codefragment_call newshipvaluereturn, GetShipValueEbx.noesi, 7

	; Places in TTD where ship capacity it feteched
	codefragment oldshipcapacity
		mov ax, word [nosplit shipcapacity-0x198+ebx*2]

	; Our replacements for this.
	codefragment_call newshipcapacity, GetShipCapacity.noesi, 8
	codefragment_call newshipcapacitybuild, GetShipCapacity.makestruc, 12

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

codefragment initsecondhead, -7
	movzx ebx, word [edi+veh.vehtype]

endcodefragments

; These active the codefragments
patchtrainstat:
	; Power Fragments
	multipatchcode trainpowergeneric, 2

	; Speed Fragments
	multipatchcode trainspeednewwehiclehandler, 2
	patchcode trainbuyvehiclespeed

	; Capacity fragmenets
	patchcode traincapacity, 1, 5
	patchcode traincapacity, 1, 4
	patchcode traincapacity, 3, 3

	; The fun part?
	patchcode oldtraincapacity, newwagoncapacitybuy, 1, 2
	extern GetWagonCapacityGeneric.oldfn
	mov ebx, GetWagonCapacityGeneric.oldfn
	call patchendstrucinit
	
	patchcode oldtraincapacity, newtraincapacitybuy, 1, 1
	extern GetTrainCapacityGeneric.oldfn
	mov ebx, GetTrainCapacityGeneric.oldfn

	stringaddress initsecondhead, 1, 0
	call patchendstrucinit.gotedi
	dec dword [ebx]
	ret

patchshipstat:
	; Value fragments (all no edi), (GGBG)
	multipatchcode shipvalue, 3
	patchcode shipvaluereturn

	; Speed Fragments
	multipatchcode shipspeednewwehiclehandler, 2
	patchcode shipspeedbuyvehiclespeed

	; Capacity hooks, 2 noesi, one build, (GBG)
	patchcode shipcapacity, 1, 3
	patchcode shipcapacity, 2, 2
	patchcode oldshipcapacity, newshipcapacitybuild, 1, 1
	extern GetShipCapacity.oldfn
	mov ebx, GetShipCapacity.oldfn

// fallthrough

patchendstrucinit:
	stringaddress endstrucinit, 1, 0
.gotedi:
	mov byte [edi], 0xC3
	storerelative ebx, edi+2
	ret

patchplanestat:
	; Speed Fragments
	patchcode planespeednewwehiclehandler, 2, 3
	extern GetPlaneCallbackSpeed.oldfn
	mov ebx, GetPlaneCallbackSpeed.oldfn
	call patchendstrucinit
	multipatchcode oldplanespeednewwehiclehandler, newplanespeednewwehiclehandler2, 2
	ret


