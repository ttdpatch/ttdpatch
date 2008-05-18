
#include <var.inc>
#include <vehtype.inc>

ptrvardec ophandler		// Array of pointers to tables of various object handlers
#define opclass(n) ophandler+(n)*8

ptrvardec newhousedatablock
ptrvardec industrydatablock
ptrvardec player2ofs

// the standard comon vehicle properties for all vehicles as in the exe file (used for grf processing)
ptrvardec vehtypedata
ptrvarofs vehtypedata_rv,vehtypedata,vehtypeinfo_size*ROADVEHBASE
ptrvarofs vehtypedata_ship,vehtypedata,vehtypeinfo_size*SHIPBASE
ptrvarofs vehtypedata_plane,vehtypedata,vehtypeinfo_size*AIRCRAFTBASE

// the standard vehicle properties for each vehicle class

ptrvardec trainpower
ptrvarofs AIspecialflag,trainpower,-NTRAINTYPES*3	// offset to count from the train power array
							// to get a special flag that should be set for all
							// dual-headed engines and those with cargo capacity
							// (used by the AI; obsoleted by unifiedmaglev and newtrains) [b]
ptrvarofs trainspeeds,trainpower,-NTRAINTYPES*2		// ...and the maximum speed [w]
ptrvarofs trainrunningcost,trainpower,NTRAINTYPES*2	// ...and the running cost multiplier [b]
ptrvarofs trainrunningcostbase,trainpower,NTRAINTYPES*3	// ...and the pointer to the running cost base [d]
ptrvarofs trainsprite,trainpower,NTRAINTYPES*7		// ...and the index into rail vehicle sprite arrays [b]
ptrvarofs numheads,trainpower,NTRAINTYPES*8		// ...and default number of heads [b]
ptrvarofs traincargosize,trainpower,NTRAINTYPES*9	// ...and the cargo capacity [b]
ptrvarofs traincargotype,trainpower,NTRAINTYPES*10	// ...and the cargo type [b]
ptrvarofs trainweight,trainpower,NTRAINTYPES*11		// ...and the weight of one engine/waggon [b]
ptrvarofs traincost,trainpower,NTRAINTYPES*12		// ...and the cost multiplier [b]
ptrvarofs AIenginerank,trainpower,NTRAINTYPES*13	// ...and the AI's engine rank [b]

ptrvardec rvspeed
ptrvarofs rvruncostfactor,rvspeed,NROADVEHTYPES*1
ptrvarofs rvruncostbase,rvspeed,NROADVEHTYPES*2
ptrvarofs rvsprite,rvspeed,NROADVEHTYPES*6
ptrvarofs rvcapacity,rvspeed,NROADVEHTYPES*7
ptrvarofs rvcargotype,rvspeed,NROADVEHTYPES*8
ptrvarofs rvcostfactor,rvspeed,NROADVEHTYPES*9
ptrvarofs rvsoundeffect,rvspeed,NROADVEHTYPES*10

ptrvardec shipsprite
ptrvarofs shiprefittable,shipsprite,NSHIPTYPES*1
ptrvarofs shipcostfactor,shipsprite,NSHIPTYPES*2
ptrvarofs shipspeed,shipsprite,NSHIPTYPES*3
ptrvarofs shipcargotype,shipsprite,NSHIPTYPES*4
ptrvarofs shipcapacity,shipsprite,NSHIPTYPES*5
ptrvarofs shipruncostfactor,shipsprite,NSHIPTYPES*7
ptrvarofs shipsoundeffect,shipsprite,NSHIPTYPES*8

ptrvardec planesprite
ptrvarofs planeisheli,planesprite,NAIRCRAFTTYPES*1
ptrvarofs planeislarge,planesprite,NAIRCRAFTTYPES*2
ptrvarofs planecostfactor,planesprite,NAIRCRAFTTYPES*3
ptrvarofs planedefspeed,planesprite,NAIRCRAFTTYPES*4		// can't use "planespeed" because that's a switch name...
ptrvarofs planeaccel,planesprite,NAIRCRAFTTYPES*5
ptrvarofs planeruncostfactor,planesprite,NAIRCRAFTTYPES*6
ptrvarofs planepasscap,planesprite,NAIRCRAFTTYPES*7
ptrvarofs planemailcap,planesprite,NAIRCRAFTTYPES*9
ptrvarofs planesoundeffect,planesprite,NAIRCRAFTTYPES*10

