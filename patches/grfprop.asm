#include <std.inc>
#include <vehtype.inc>
#include <newvehdata.inc>
#include <ptrvar.inc>
#include <grf.inc>

#include <house.inc>
#include <airport.inc>
#include <industry.inc>

extern newvehdata
extern callbackflags

// Action 0 Properties for all features

%push defaction0data
%define %$d_U 0		// unused/undefined/invalid
%define %$d_B 1		// a byte
%define %$d_W 2		// a word
%define %$d_T 0x82	// a text id
%define %$d_D 4		// a dword
%define %$d_P 0x84	// a pointer, relative to the data segment (for WINTTDX)

%define %$d_F 0x80	// call special handler function
%define %$d_H 0x40	// call special handler function with untranslated offset (for features like newstations and newhouses that translate offsets)

%define %$s_U 1
%define %$s_B 1
%define %$s_W 2
%define %$s_T 2
%define %$s_D 4
%define %$s_P 4
%define %$s_F 1
%define %$s_H 1


%macro action0props 2-3.nolist 0	// params: name,maxids, [idtranslationtable]
	%ifid %3
		extern %3
	%endif
	vard %1
	
istruc action0prophead
	at action0prophead.numids, dw %2
	at action0prophead.numprops, db (%1.end-%1.properties)/8
	at action0prophead.idtranstable, dd %3
iend
	.properties:
	%assign action0datanum 0x00
%endmacro

%macro endaction0props 0.nolist
	.end:
	endvar
%endmacro

%macro prop 3-*.nolist	// params: propnum,type,ptr,[sizeofentry]...
%if %1<>action0datanum
	%error "property action0datanum missing"
%endif
	db %$d_%2 
%if %0>3
	db %4	// offset for non contigues data, like vehtypedata
%else
	db %$d_%2 & 7	// or normal size of entry
%endif
	dw 0
	dd %3
	%assign action0datanum action0datanum+1
%endmacro

%macro propex 3-*.nolist
	extern %3
	prop %1, %2, %3, %4
%endmacro


// Train Properties
action0props trainproperties,NTRAINTYPES
	prop 0x00,W, vehtypedata+vehtypeinfo.baseintrodate,vehtypeinfo_size
	prop 0x01,U, 0
	prop 0x02,B, vehtypedata+vehtypeinfo.reliabdecrease,vehtypeinfo_size
	prop 0x03,B, vehtypedata+vehtypeinfo.lifespan,vehtypeinfo_size
	prop 0x04,B, vehtypedata+vehtypeinfo.basedurphase2,vehtypeinfo_size
	prop 0x05,B, vehtypedata+vehtypeinfo.traintype,vehtypeinfo_size
	prop 0x06,B, vehtypedata+vehtypeinfo.climates,vehtypeinfo_size
	prop 0x07,B, loadamount
// --- defvehdata spectraindata, B,W,W,B,P,B,B,B,B,B,B,B	// 08..18
	prop 0x08,B, AIspecialflag
	prop 0x09,W, trainspeeds
	prop 0x0A,U, 0
	prop 0x0B,W, trainpower
	prop 0x0C,U, 0
	prop 0x0D,B, trainrunningcost
	prop 0x0E,P, trainrunningcostbase
	prop 0x0F,U, 0
	prop 0x10,U, 0
	prop 0x11,U, 0
	prop 0x12,B, trainsprite
	prop 0x13,B, numheads
	prop 0x14,B, traincargosize
	prop 0x15,B, traincargotype
	prop 0x16,B, trainweight
	prop 0x17,B, traincost
	prop 0x18,B, AIenginerank
// --- defvehdata spcltraindata, B,F,w,B,d,B,B,B,B,B,B,B,B,B,B,w,w,F	// 19..2A
	prop 0x19,B, traintractiontype
	propex 0x1A,F, shuffletrainveh
	prop 0x1B,W, trainwagonpower
	prop 0x1C,B, trainrefitcost
	prop 0x1D,D, newtrainrefit
	prop 0x1E,B, traincallbackflags
	prop 0x1F,B, traintecoeff
	prop 0x20,B, trainc2coeff
	prop 0x21,B, trainvehlength
	prop 0x22,B, trainviseffect
	prop 0x23,B, trainwagonpowerweight
	prop 0x24,B, railvehhighwt
	propex 0x25,B, trainuserbits
	prop 0x26,B, trainphase2dec
	prop 0x27,B, trainmiscflags
	prop 0x28,W, traincargoclasses
	prop 0x29,W, trainnotcargoclasses
	propex 0x2A,F, longintrodate
endaction0props



// Road Vehicle Properties
action0props rvproperties,NROADVEHTYPES
	prop 0x00,W, vehtypedata_rv+vehtypeinfo.baseintrodate,vehtypeinfo_size
	prop 0x01,U, 0
	prop 0x02,B, vehtypedata_rv+vehtypeinfo.reliabdecrease,vehtypeinfo_size
	prop 0x03,B, vehtypedata_rv+vehtypeinfo.lifespan,vehtypeinfo_size
	prop 0x04,B, vehtypedata_rv+vehtypeinfo.basedurphase2,vehtypeinfo_size
	prop 0x05,B, vehtypedata_rv+vehtypeinfo.traintype,vehtypeinfo_size
	prop 0x06,B, vehtypedata_rv+vehtypeinfo.climates,vehtypeinfo_size
	prop 0x07,B, loadamount+ROADVEHBASE
// --- defvehdata specrvdata, B,B,P,B,B,B,B,B			// 08..12
	prop 0x08,B, rvspeed
	prop 0x09,B, rvruncostfactor
	prop 0x0A,P, rvruncostbase
	prop 0x0B,U, 0
	prop 0x0C,U, 0
	prop 0x0D,U, 0
	prop 0x0E,B, rvsprite
	prop 0x0F,B, rvcapacity
	prop 0x10,B, rvcargotype
	prop 0x11,B, rvcostfactor
	prop 0x12,B, rvsoundeffect
// -- defvehdata spclrvdata, B,B,B,d,B,B,B,B,B,B,w,w,F	// 13..1F
	prop 0x13,B, rvpowers
	prop 0x14,B, rvweight
	prop 0x15,B, rvhspeed
	prop 0x16,D, newrvrefit
	prop 0x17,B, rvcallbackflags
	prop 0x18,B, rvtecoeff
	prop 0x19,B, rvc2coeff
	prop 0x1A,B, rvrefitcost
	prop 0x1B,B, rvphase2dec
	prop 0x1C,B, rvmiscflags
	prop 0x1D,W, rvcargoclasses
	prop 0x1E,W, rvnotcargoclasses
	prop 0x1F,F, longintrodate
endaction0props


// Ship Properties
action0props shipproperties,NSHIPTYPES
	prop 0x00,W, vehtypedata_ship+vehtypeinfo.baseintrodate,vehtypeinfo_size
	prop 0x01,U,0
	prop 0x02,B, vehtypedata_ship+vehtypeinfo.reliabdecrease,vehtypeinfo_size
	prop 0x03,B, vehtypedata_ship+vehtypeinfo.lifespan,vehtypeinfo_size
	prop 0x04,B, vehtypedata_ship+vehtypeinfo.basedurphase2,vehtypeinfo_size
	prop 0x05,B, vehtypedata_ship+vehtypeinfo.traintype,vehtypeinfo_size
	prop 0x06,B, vehtypedata_ship+vehtypeinfo.climates,vehtypeinfo_size
	prop 0x07,B,(loadamount+SHIPBASE)
// --- defvehdata specshipdata, B,B,B,B,B,W,B,B		// 08..10
	prop 0x08,B, shipsprite
	prop 0x09,B, shiprefittable
	prop 0x0A,B, shipcostfactor
	prop 0x0B,B, shipspeed
	prop 0x0C,B, shipcargotype
	prop 0x0D,W, shipcapacity
	prop 0x0E,U,0
	prop 0x0F,B, shipruncostfactor
	prop 0x10,B, shipsoundeffect
// --- defvehdata spclshipdata, d,B,B,B,B,B,B,w,w,F		// 11..1A
	prop 0x11,B, newshiprefit
	prop 0x12,B, shipcallbackflags
	prop 0x13,B, shiprefitcost
	prop 0x14,B, oceanspeedfract
	prop 0x15,B, canalspeedfract
	prop 0x16,B, shipphase2dec
	prop 0x17,B, shipmiscflags
	prop 0x18,B, shipcargoclasses
	prop 0x19,B, shipnotcargoclasses
	prop 0x1A,F, longintrodate
endaction0props 


// Plane Properties
action0props planeproperties,NAIRCRAFTTYPES
	prop 0x00,W, vehtypedata_plane+vehtypeinfo.baseintrodate,vehtypeinfo_size
	prop 0x01,U, 0
	prop 0x02,B, vehtypedata_plane+vehtypeinfo.reliabdecrease,vehtypeinfo_size
	prop 0x03,B, vehtypedata_plane+vehtypeinfo.lifespan,vehtypeinfo_size
	prop 0x04,B, vehtypedata_plane+vehtypeinfo.basedurphase2,vehtypeinfo_size
	prop 0x05,B, vehtypedata_plane+vehtypeinfo.traintype,vehtypeinfo_size
	prop 0x06,B, vehtypedata_plane+vehtypeinfo.climates,vehtypeinfo_size
	prop 0x07,B, (loadamount+AIRCRAFTBASE)
// -- defvehdata specplanedata, B,B,B,B,B,B,B,W,B,B		// 08..12
	prop 0x08,B, planesprite
	prop 0x09,B, planeisheli
	prop 0x0A,B, planeislarge
	prop 0x0B,B, planecostfactor
	prop 0x0C,B, planedefspeed
	prop 0x0D,B, planeaccel
	prop 0x0E,B, planeruncostfactor
	prop 0x0F,W, planepasscap
	prop 0x10,U, 0
	prop 0x11,B, planemailcap
	prop 0x12,B, planesoundeffect
// -- defvehdata spclplanedata, d,B,B,B,B,w,w,F
	prop 0x13,D, newplanerefit
	prop 0x14,B, planecallbackflags
	prop 0x15,B, planerefitcost
	prop 0x16,B, planephase2dec
	prop 0x17,B, planemiscflags
	prop 0x18,W, planecargoclasses
	prop 0x19,W, planenotcargoclasses
	prop 0x1A,F, longintrodate
endaction0props


// Station Properties
action0props stationproperties,255,curgrfstationlist
	prop 0x00,U,0
	prop 0x01,U,0
	prop 0x02,U,0
	prop 0x03,U,0
	prop 0x04,U,0
	prop 0x05,U,0
	prop 0x06,U,0
	prop 0x07,U,0
// -- defvehdata specstationdata
// -- defvehdata spclstationdata, F,H,F,B,B,B,F,F,w,B,F,B,B,B,w,B,w,F	// 08..19
	propex 0x08,F, setstationclass
	propex 0x09,H, setstationspritelayout
	propex 0x0A,F, copystationspritelayout
	propex 0x0B,B, stationcallbackflags
	propex 0x0C,B, disallowedplatforms
	propex 0x0D,B, disallowedlengths
	propex 0x0E,F, setstationlayout
	propex 0x0F,F, copystationlayout
	propex 0x10,W, stationcargolots
	propex 0x11,B, stationpylons
	propex 0x12,F, setstatcargotriggers
	propex 0x13,B, stationflags
	propex 0x14,B, stationnowires
	propex 0x15,B, cantrainenterstattile
	propex 0x16,W, stationanimdata
	propex 0x17,B, stationanimspeeds
	propex 0x18,W, stationanimtriggers
	propex 0x19,F, setrailstationrvrouteing
endaction0props


action0props canalsproperties,7
	prop 0x00,U,0
	prop 0x01,U,0
	prop 0x02,U,0
	prop 0x03,U,0
	prop 0x04,U,0
	prop 0x05,U,0
	prop 0x06,U,0
	prop 0x07,U,0
	propex 0x08,B, canalscallbackflags
	propex 0x09,B, canalsgraphicflags
endaction0props


// Bridge Properties (Unfinished)
action0props bridgeproperties, NNEWBRIDGES
	prop 0x00,U,0
	prop 0x01,U,0
	prop 0x02,U,0
	prop 0x03,U,0
	prop 0x04,U,0
	prop 0x05,U,0
	prop 0x06,U,0
	prop 0x07,U,0
// -- defvehdata specbridgedata, B,B,B,B		// 08..0B
	propex 0x08,B, bridgeintrodate
	propex 0x09,B, bridgeminlength
	propex 0x0A,B, bridgemaxlength
	propex 0x0B,B, bridgecostfactor
// -- defvehdata spclbridgedata, w,F,B,F,t,t,t		// 0C..12
	propex 0x0C,W, bridgemaxspeed // should be set via patches.ah ?
	propex 0x0D,F, alterbridgespritetable
	propex 0x0E,B, bridgeflags
	propex 0x0F,F, longintrodatebridges
	propex 0x10,T, bridgenames
	propex 0x11,T, bridgerailnames
	propex 0x12,T, bridgeroadnames
endaction0props


action0props houseproperties,255,curgrfhouselist
	prop 0x00,U,0
	prop 0x01,U,0
	prop 0x02,U,0
	prop 0x03,U,0
	prop 0x04,U,0
	prop 0x05,U,0
	prop 0x06,U,0
	prop 0x07,U,0
//defvehdata spclhousedata, F,F,w,B,B,B,B,B,w,B,t,w,B,F,F,d,B,B,B,B,F,B,d,B,F
	propex 0x08,F, setsubstbuilding
	propex 0x09,F, sethouseflags
	prop 0x0A,W, newhouseyears+2*128
	prop 0x0B,B, newhousepopulations+128
	prop 0x0C,B, newhousemailprods+128
	prop 0x0D,B, newhousepassaccept+128
	prop 0x0E,B, newhousemailaccept+128
	prop 0x0F,B, newhousefoodorgoodsaccept+128
	prop 0x10,W, newhouseremoveratings+2*128
	prop 0x11,B, newhouseremovemultipliers+128
	prop 0x12,T, newhousenames+2*128
	prop 0x13,W, newhouseavailmasks+2*128
	prop 0x14,B, housecallbackflags
	propex 0x15,F, sethouseoverride
	propex 0x16,F, sethouseprocessinterval
	prop 0x17,D, housecolors
	prop 0x18,B, houseprobabs
	prop 0x19,B, houseextraflags
	prop 0x1A,B, houseanimframes
	prop 0x1B,B, houseanimspeeds
	propex 0x1C,F, sethouseclass
	prop 0x1D,B, housecallbackflags2
	prop 0x1E,D, houseaccepttypes
	prop 0x1F,B, houseminlifespans
	propex 0x20,F, sethousewatchlist
endaction0props

action0props globalproperties,255
	prop 0x00,U,0
	prop 0x01,U,0
	prop 0x02,U,0
	prop 0x03,U,0
	prop 0x04,U,0
	prop 0x05,U,0
	prop 0x06,U,0
	prop 0x07,U,0
// defvehdata spclglobaldata, B,F,t,d,w,d,d,w,F		// 08..10
	propex 0x08,B, basecostmult
	propex 0x09,F, setcargotranstbl
	propex 0x0A,T, currtextlist
	propex 0x0B,D, currmultis
	propex 0x0C,W, curropts
	propex 0x0D,D, currsymsbefore
	propex 0x0E,D, currsymsafter
	propex 0x0F,W, eurointr
	propex 0x10,F, setsnowlinetable
	prop 0x11,U, 0	// GRF ID overrides for engines	
endaction0props


action0props industileproperties,255,curgrfindustilelist
	prop 0x00,U,0
	prop 0x01,U,0
	prop 0x02,U,0
	prop 0x03,U,0
	prop 0x04,U,0
	prop 0x05,U,0
	prop 0x06,U,0
	prop 0x07,U,0
// defvehdata spclindustiledata, F,F,F,F,F,B,B,w,B,B,B	// 08..12
	propex 0x08,F, setsubstindustile
	propex 0x09,F, setindustileoverride
	propex 0x0A,F, setindustileaccepts
	propex 0x0B,F, setindustileaccepts
	propex 0x0C,F, setindustileaccepts
	propex 0x0D,B, industilelandshapeflags
	propex 0x0E,B, industilecallbackflags
	propex 0x0F,W, industileanimframes
	propex 0x10,B, industileanimspeeds
	propex 0x11,B, industileanimtriggers
	propex 0x12,B, industilespecflags
endaction0props 


// can't be used with propex
extern initialindustryprobs, ingameindustryprobs
extern industryspecialflags, industrycreationmsgs
extern industryinputmultipliers
extern industrynames, fundchances
extern industrycallbackflags, industrycallbackflags2
extern industrydestroymultis, industrystationname

action0props industryproperties,NINDUSTRYTYPES,curgrfindustrylist
	prop 0x00,U,0
	prop 0x01,U,0
	prop 0x02,U,0
	prop 0x03,U,0
	prop 0x04,U,0
	prop 0x05,U,0
	prop 0x06,U,0
	prop 0x07,U,0
// defvehdata spclindustrydata, F,H,F,B,t,t,t,B, F,F,B,B,B,F,F,B, B,F,d,t,d,d,d,t, d,B,B,d,t		// 08..24
	propex 0x08,F, setsubstindustry
	propex 0x09,H, setindustryoverride
	propex 0x0A,F, setindustrylayout
	prop 0x0B,B, industryproductionflags-1
	prop 0x0C,T, industryclosuremsgs-2
	prop 0x0D,T, industryprodincmsgs-2
	prop 0x0E,T, industryproddecmsgs-2
	prop 0x0F,B, industryfundcostmultis-1
	propex 0x10,F, setinduproducedcargos
	propex 0x11,F, setindustryacceptedcargos
	prop 0x12,B, industryprod1rates-1
	prop 0x13,B, industryprod2rates-1
	prop 0x14,B, industrymindistramounts-1
	propex 0x15,F, setindustrysoundeffects
	propex 0x16,F, setconflindustry
	prop 0x17,B, initialindustryprobs-1
	prop 0x18,B, ingameindustryprobs-1
	propex 0x19,F, setindustrymapcolors
	prop 0x1A,D, industryspecialflags-4
	prop 0x1B,T, industrycreationmsgs-2
	prop 0x1C,D, industryinputmultipliers-4
	prop 0x1D,D, (industryinputmultipliers+NINDUSTRYTYPES*4)-4
	prop 0x1E,D, (industryinputmultipliers+2*NINDUSTRYTYPES*4)-4
	prop 0x1F,T, industrynames-2
	prop 0x20,D, fundchances-4
	prop 0x21,B, industrycallbackflags-1
	prop 0x22,B, industrycallbackflags2-1
	prop 0x23,D, industrydestroymultis-4
	prop 0x24,T, industrystationname-2
endaction0props

action0props cargoproperties,32
	prop 0x00,U,0
	prop 0x01,U,0
	prop 0x02,U,0
	prop 0x03,U,0
	prop 0x04,U,0
	prop 0x05,U,0
	prop 0x06,U,0
	prop 0x07,U,0
// defvehdata spclcargodata, F,t,t,t,t,t,w,B,B,B,F,F,F,F,F,d,B,w,B	// 08..1a
	propex 0x08,F, setcargobit
	propex 0x09,T, newcargotypenames
	propex 0x0A,T, newcargounitnames
	propex 0x0B,T, newcargoamount1names
	propex 0x0C,T, newcargoamountnnames
	propex 0x0D,T, newcargoshortnames
	propex 0x0E,W, newcargoicons
	propex 0x0F,B, newcargounitweights
	propex 0x10,B, newcargodelaypenaltythresholds1
	propex 0x11,B, newcargodelaypenaltythresholds2
	propex 0x12,F, setcargopricefactors
	propex 0x13,F, setcargocolors
	propex 0x14,F, setcargographcolors
	propex 0x15,F, setfreighttrainsbit
	propex 0x16,F, setcargoclasses
	prop 0x17,D, globalcargolabels
	propex 0x18,B, cargotowngrowthtype
	propex 0x19,W, cargotowngrowthmulti
	propex 0x1A,B, cargocallbackflags
endaction0props

action0props sounddataproperties,-1
	prop 0x00,U,0
	prop 0x01,U,0
	prop 0x02,U,0
	prop 0x03,U,0
	prop 0x04,U,0
	prop 0x05,U,0
	prop 0x06,U,0
	prop 0x07,U,0
// defvehdata spclsounddata, F,F,F				// 08..0A
	propex 0x08,F, setsoundvolume
	propex 0x09,F, setsoundpriority
	propex 0x0A,F, overrideoldsound
endaction0props

action0props airportproperties,NUMNEWAIRPORTS,curgrfairportlist
	prop 0x00,U,0
	prop 0x01,U,0
	prop 0x02,U,0
	prop 0x03,U,0
	prop 0x04,U,0
	prop 0x05,U,0
	prop 0x06,U,0
	prop 0x07,U,0
// defvehdata spclairportdata, F,F,B,B,B,B,t			// 08..0d	
	propex 0x08,F, setairportlayout
	propex 0x09,F, setairportmovementdata
	propex 0x0A,B, airportstarthangarnodes
	propex 0x0B,B, airportcallbackflags
	propex 0x0C,B, airportspecialflags
	propex 0x0D,B, airportweight
	propex 0x0E,T, airporttypenames
endaction0props

action0props signalproperties,0
	// none
endaction0props

action0props objectproperties,255,curgrfobjectgameids
	prop 0x00,U,0
	prop 0x01,U,0
	prop 0x02,U,0
	prop 0x03,U,0
	prop 0x04,U,0
	prop 0x05,U,0
	prop 0x06,U,0
	prop 0x07,U,0
// defvehdata spclobjectdata, F,F,T
	propex 0x08,F, setobjectclass
	propex 0x09,F, setobjectclasstexid
	propex 0x0A,T, objectnames
endaction0props

%pop

var action0properties
	dd trainproperties
	dd rvproperties
	dd shipproperties
	dd planeproperties
	dd stationproperties
	dd canalsproperties
	dd bridgeproperties
	dd houseproperties
	dd globalproperties
	dd industileproperties
	dd industryproperties
	dd cargoproperties
	dd sounddataproperties
	dd airportproperties
	dd signalproperties
	dd objectproperties
checkfeaturesize action0properties, 4
