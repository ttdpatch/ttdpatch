
#include <grfdef.inc>
#include <vehtype.inc>

// new TTDPatch vehicle data, all in one chunk
// each array must have a length that is a multiple of four bytes
// do not change the order or position of entries because it will be
// saved as is and when loaded everything must match! This would change
// the property numbers in action 0 or the newgrf code too.
struc newvehdatastruc
	.traintractiontype:resb NTRAINTYPES		//   0..73

	.rvpowers:	resb NROADVEHTYPES		//  74..CB
	.rvweight:	resb NROADVEHTYPES		//  CC..123
	.rvhspeed:	resb NROADVEHTYPES		// 124..17B

		// .rvrefit and .shiprefit can both be accessed
		// via [.refit1+vehtype*4]
	.refit1 equ $-ROADVEHBASE*4
	.rvrefit:	resd NROADVEHTYPES		// 17C..2DB
	.shiprefit:	resd NSHIPTYPES			// 2DC..307

	.vehrandseed:	resd 2				// 308..30F
	.flags:		resd 1				// 310..313
%define newvehdata_flags_init 1		// initial value to set for the flags
	.oceanspeedfract:resb NSHIPTYPES		// 314..31E
	.unused0:	resb 1				// 31F unused (note, may not be zero!)
	.canalspeedfract:resb NSHIPTYPES		// 320..32A
	.unused1:	resb 7*NTRAINTYPES-$		// 32B unused

	.trainvehlength:resb NTRAINTYPES		// 32C..39F
	.loadamount:	resb 256			// 3A0..49F

		// .trainrefit and .planerefit can both be accessed
		// via [.refit2+vehtype*4]
	.refit2:					//(4A0..66F & 7FC..89F)
	.trainrefit:	resd NTRAINTYPES		// 4A0..66F
	.trainwagonpower:resw NTRAINTYPES		// 670..757
	.trainviseffect:resb NTRAINTYPES		// 758..7CB

	.unused2:	resb .trainrefit+AIRCRAFTBASE*4-$ // 7CC..7FB unused

	.planerefit:	resd NAIRCRAFTTYPES		// 7FC..89F
	.trainwagonpowerweight:resb NTRAINTYPES		// 8A0..913
	.trainrefitcost:resb NTRAINTYPES		// 914..987

	.tecoeff:	resb NTRAINTYPES+NROADVEHTYPES	// 988..A53
	.c2coeff:	resb NTRAINTYPES+NROADVEHTYPES	// A54..B1F

	.rvrefitcost:	resb NROADVEHTYPES		// B20..B77
	.shiprefitcost:	resb NSHIPTYPES			// B78..B82
	.planerefitcost:resb NAIRCRAFTTYPES		// B83..BAB

	.railvehhighwt:	resb NTRAINTYPES		// BAC..C1F
	.vehphase2dec:	resb 256			// C20..D1F
	.vehmiscflags:	resb 256			// D20..E1F
	.cargoclasses:	resw 256			// E20..101F
	.cargonotclasses:resw 256			// 1020..121F
	.cargolabels:	resd NUMCARGOS			// 1220..129F
endstruc

#define VEHMISCFLAG_TRAINTILT		1	// Trains: train is tilting and can run faster in curves
#define VEHMISCFLAG_RVISTRAM		1	// RVs: RV requires tram track
#define VEHMISCFLAG_TWOCOL		2	// All vehicle types: has 2nd company colour support
#define VEHMISCFLAG_MULTIPLEUNIT	4	// Trains: Vehicle is multiple unit (for colour selection)

// aliases for each of the entries
// can't use EQU or %assign because the variable hasn't actually
// been defined yet

%define vehmiscflags (newvehdata+newvehdatastruc.vehmiscflags)
%define vehcargoclasses (newvehdata+newvehdatastruc.cargoclasses)
%define vehnotcargoclasses (newvehdata+newvehdatastruc.cargonotclasses)

%define traintractiontype (newvehdata+newvehdatastruc.traintractiontype)
%define trainvehlength (newvehdata+newvehdatastruc.trainvehlength)
%define newtrainrefit (newvehdata+newvehdatastruc.trainrefit)
%define trainwagonpower (newvehdata+newvehdatastruc.trainwagonpower)
%define trainwagonpowerweight (newvehdata+newvehdatastruc.trainwagonpowerweight)
%define trainviseffect (newvehdata+newvehdatastruc.trainviseffect)
%define traintecoeff (newvehdata+newvehdatastruc.tecoeff)
%define trainc2coeff (newvehdata+newvehdatastruc.c2coeff)
%define trainmiscflags (newvehdata+newvehdatastruc.vehmiscflags)
%define traincargoclasses (newvehdata+newvehdatastruc.cargoclasses)
%define trainnotcargoclasses (newvehdata+newvehdatastruc.cargonotclasses)
%define rvpowers (newvehdata+newvehdatastruc.rvpowers)
%define rvweight (newvehdata+newvehdatastruc.rvweight)
%define rvhspeed (newvehdata+newvehdatastruc.rvhspeed)
%define rvtecoeff (newvehdata+newvehdatastruc.tecoeff+ROADVEHBASE)
%define rvc2coeff (newvehdata+newvehdatastruc.c2coeff+ROADVEHBASE)
%define rvmiscflags (newvehdata+newvehdatastruc.vehmiscflags+ROADVEHBASE)
%define rvcargoclasses (newvehdata+newvehdatastruc.cargoclasses+ROADVEHBASE*2)
%define rvnotcargoclasses (newvehdata+newvehdatastruc.cargonotclasses+ROADVEHBASE*2)
%define newrvrefit (newvehdata+newvehdatastruc.rvrefit)
%define newshiprefit (newvehdata+newvehdatastruc.shiprefit)
%define newplanerefit (newvehdata+newvehdatastruc.planerefit)
%define loadamount (newvehdata+newvehdatastruc.loadamount)
%define trainrefitcost (newvehdata+newvehdatastruc.trainrefitcost)
%define rvrefitcost (newvehdata+newvehdatastruc.rvrefitcost)
%define shiprefitcost (newvehdata+newvehdatastruc.shiprefitcost)
%define shipmiscflags (newvehdata+newvehdatastruc.vehmiscflags+SHIPBASE)
%define shipcargoclasses (newvehdata+newvehdatastruc.cargoclasses+SHIPBASE*2)
%define shipnotcargoclasses (newvehdata+newvehdatastruc.cargonotclasses+SHIPBASE*2)
%define planerefitcost (newvehdata+newvehdatastruc.planerefitcost)
%define planemiscflags (newvehdata+newvehdatastruc.vehmiscflags+AIRCRAFTBASE)
%define planecargoclasses (newvehdata+newvehdatastruc.cargoclasses+AIRCRAFTBASE*2)
%define planenotcargoclasses (newvehdata+newvehdatastruc.cargonotclasses+AIRCRAFTBASE*2)
%define vehrandseed (newvehdata+newvehdatastruc.vehrandseed)
%define railvehhighwt (newvehdata+newvehdatastruc.railvehhighwt)
%define oceanspeedfract (newvehdata+newvehdatastruc.oceanspeedfract)
%define canalspeedfract (newvehdata+newvehdatastruc.canalspeedfract)
%define vehphase2dec (newvehdata+newvehdatastruc.vehphase2dec)
%define trainphase2dec (newvehdata+newvehdatastruc.vehphase2dec)
%define rvphase2dec (newvehdata+newvehdatastruc.vehphase2dec+ROADVEHBASE)
%define shipphase2dec (newvehdata+newvehdatastruc.vehphase2dec+SHIPBASE)
%define planephase2dec (newvehdata+newvehdatastruc.vehphase2dec+AIRCRAFTBASE)
%define globalcargolabels (newvehdata+newvehdatastruc.cargolabels)

// related variable (also set by action 0) but not stored in newvehdata
%define traincallbackflags (callbackflags)
%define rvcallbackflags (traincallbackflags+NTRAINTYPES)
%define shipcallbackflags (rvcallbackflags+NROADVEHTYPES)
%define planecallbackflags (shipcallbackflags+NSHIPTYPES)
