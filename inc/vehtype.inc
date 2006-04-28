#ifndef __VEHTYPE_INC__
#define __VEHTYPE_INC__

// first vehicle type number of each class
%assign TRAINBASE	0
%assign ROADVEHBASE	116
%assign SHIPBASE	204
%assign AIRCRAFTBASE	215
%assign totalvehtypes 0x100	// Total number of vehicletypes in the game


// number of vehicle types in each class
%assign NTRAINTYPES	ROADVEHBASE-0
%assign NROADVEHTYPES	SHIPBASE-ROADVEHBASE
%assign NSHIPTYPES	AIRCRAFTBASE-SHIPBASE
%assign NAIRCRAFTTYPES	256-AIRCRAFTBASE

// at 0x751a2
struc vehtype
	.playeravail: 	resw 1	// 00h:Bitmask of which players can buy this
	.introduced: 	resw 1	// 02h:Date of the introduction
	.engineage: 	resw 1	// 04h:Age (since intro) in months
	.reliab: 	resw 1	// 06h:Reliability (65535=100%)
	.reliabdecrease:resw 1	// 08h:How fast reliability decreases w/o maint
	.reliabstart: 	resw 1	// 0ah:initial reliability
	.reliabmax: 	resw 1	// 0ch:maximum rel.
	.reliabend: 	resw 1	// 0eh:final rel.
	.durphase1: 	resw 1	// 10h:duration of phase one (months)
	.durphase2: 	resw 1	// 12h:dur/phase two
	.durphase3: 	resw 1	// 14h:dur/phase three
	.enginelife: 	resb 1	// 16h:life in years
	.flags: 	resb 1	// 17h:bit coded flags, see below
	.availinfo: 	resb 1	// 18h:0=not offered, 1..254=attempts to offer exclusively, 255=no more exclusive offers
	.excldaysleft:	resb 1	// 19h:number of days left to accept exclusive offer
	.enginetraintype:resb 1	// 1ah:Train type of the engine
			resb 1	// 1bh:??
endstruc

// Phase 1:  Reliability increases from initial to maximum
// Phase 2:  Reliability stays at maximum
// Phase 3:  Reliability decays from maximum to final value
// Then engine disappears from the list
// PersitentEngines keeps engines in phase 2 while they exist
//
// Flags:	1=Available, or was available if playeravail=0
// 		2=Exclusively available to one player
//		4=Some company received an offer to test it exclusively
//
// Randomized values:
//
// .introduced	vehtypeinfo.baseintrodate + (0 to 511 days)
//
// .reliabstart	48% to 73%
// .reliabmax	75% to 100%
// .reliabend	25% to 50%
//
// .durphase1	7 to 38 months
// .durphase2	(vehtypeinfo.basedurphase2) + (0 to 15 months) - 8 years
// .durphase3	10 years to 20.5 years
//

// Engineinfo as stored in the .exe file
struc vehtypeinfo
	.baseintrodate: resw 1	// 00h:Base[*] date of introduction
	.reliabdecrease:resb 1	// 02h:(goes word extended into engine[08h])
	.lifespan: 	resb 1	// 03h:life in years
	.basedurphase2: resb 1	// 04h:Base[*] duration of phase 2
	.traintype:	resb 1	// 05h:(goes into engine[1ah])
	.climates:	resb 1	// 06h:bit-mask of climates where available
endstruc
// [*] In the actual games, a random number from 0 to 511 is added to this

#endif // __VEHTYPE_INC__
