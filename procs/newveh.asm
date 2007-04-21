// Designed to hold patches which can be applied for all vehicle classes (stops messes later)
#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>
#include <ptrvar.inc>

patchproc newrvs, newships, newplanes, patchvehtypes

begincodefragments

codefragment oldbuyaddtestbit
	mov byte [esi+veh.breakdowncountdown], 0
	mov byte [esi+veh.breakdowns], 0
	mov byte [esi+veh.breakdownthreshold], 0

codefragment newbuyaddtestbit
extern AddTestingPhaseBsit
	icall AddTestingPhaseBit
	setfragmentsize 8

endcodefragments

patchvehtypes:
	patchcode oldbuyaddtestbit, newbuyaddtestbit, 2-WINTTDX, 4
	patchcode oldbuyaddtestbit, newbuyaddtestbit, 3-WINTTDX*2, 3
	patchcode oldbuyaddtestbit, newbuyaddtestbit, 2, 2
	ret

