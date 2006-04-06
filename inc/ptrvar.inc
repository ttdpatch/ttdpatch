
#include <var.inc>
#include <vehtype.inc>

ptrvardec ophandler		// Array of pointers to tables of various object handlers

ptrvardec newhousedatablock

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

