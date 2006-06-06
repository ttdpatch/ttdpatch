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

// Few things need to be taken from the patches file
extern TrainSpeedNewVehicleHandler, TrainSpeedBuyNewVehicle
extern GetShipCallBackSpeed, GetPlaneCallBackSpeed
extern TrainPowerGeneric

// Procedures
patchproc newtrains, patchtrainstat
patchproc newships, patchshipstat
patchproc newplanes, patchplanestat

begincodefragments
// Trains
	; These fragments are for finding the places where speed is used in ttd
	codefragment oldtrainspeednewwehiclehandler
		movzx eax, word [nosplit trainspeeds+ebx*2]
		imul ax, 10
		shr ax, 4
	codefragment oldtrainbuyvehiclespeed
		mov ax, [nosplit trainspeeds+ebx*2]
	; Replace Ment Fragments for speed usage
	codefragment newtrainspeednewwehiclehandler
		icall TrainSpeedNewVehicleHandler
		imul ax, 10
		shr ax, 4
		setfragmentsize 16
	codefragment newtrainbuyvehiclespeed
		icall TrainSpeedBuyNewVehicle
		setfragmentsize 8
	; These fragments are for power
	codefragment oldtrainpowergeneric
		mov ax, [nosplit trainpower+ebx*2]
	codefragment newtrainpowergeneric
		icall TrainPowerGeneric
		setfragmentsize 8

// Ships
	; These fragments are for finding the places where speed is used in ttd
	codefragment oldshipspeednewwehiclehandler
		movzx eax, byte [shipspeed-0xCC+ebx]
		imul ax, 10
		shr ax, 5
	codefragment oldshipspeedbuyvehiclespeed
		movzx ax, byte [shipspeed-0xCC+ebx]
	; Replace Ment Fragments for speed usage
	codefragment newshipspeednewwehiclehandler
		icall GetShipCallBackSpeed
		imul ax, 10
		shr ax, 5
		setfragmentsize 15
	codefragment newshipspeedbuyvehiclespeed
		icall GetShipCallBackSpeed
		setfragmentsize 8

// Planes
	; These fragments are for finding the places where speed is used in ttd
	codefragment oldplanespeednewwehiclehandler
		movzx ax, byte [planedefspeed-0xD7+ebx]
	; Replace Ment Fragments for speed usage
	codefragment newplanespeednewwehiclehandler
		icall GetPlaneCallBackSpeed
		setfragmentsize 8

endcodefragments

; These active the codefragments
patchtrainstat:
	; Speed Fragments
	patchcode oldtrainspeednewwehiclehandler, newtrainspeednewwehiclehandler, 1, 2
	patchcode oldtrainspeednewwehiclehandler, newtrainspeednewwehiclehandler, 1, 0
	patchcode oldtrainbuyvehiclespeed, newtrainbuyvehiclespeed

	; Power Fragments
	patchcode oldtrainpowergeneric, newtrainpowergeneric, 1, 2
	patchcode oldtrainpowergeneric, newtrainpowergeneric, 1, 0
	ret

patchshipstat:
	; Speed Fragments
	patchcode oldshipspeednewwehiclehandler, newshipspeednewwehiclehandler, 1, 2
	patchcode oldshipspeednewwehiclehandler, newshipspeednewwehiclehandler, 1, 0
	patchcode oldshipspeedbuyvehiclespeed, newshipspeedbuyvehiclespeed
	ret

patchplanestat:
	; Speed Fragments
	patchcode oldplanespeednewwehiclehandler, newplanespeednewwehiclehandler, 1, 3
	patchcode oldplanespeednewwehiclehandler, newplanespeednewwehiclehandler, 1, 0
	patchcode oldplanespeednewwehiclehandler, newplanespeednewwehiclehandler, 1, 0
	ret

