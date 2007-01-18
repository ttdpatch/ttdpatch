// Designed to hold patches which can be applied for all vehicle classes (stops messes later)
#include <std.inc>
#include <veh.inc>
#include <vehtype.inc>
#include <textdef.inc>

// Adds the testing phase bit to veh.modflags
// Applied for all vehicle classes so this code is generic 
global AddTestingPhaseBit
AddTestingPhaseBit:
;	int3 ; Was for testing purposes
	mov byte [esi+veh.breakdowncountdown], 0
	mov byte [esi+veh.breakdowns], 0

	push eax
	movzx eax, word [esi+veh.vehtype]
	imul eax, vehtype_size
	add eax, vehtypearray
	and word [edi+veh.modflags], 1<<MOD_PROTOTYPE // Since TTD won't clear this bit itself
	test byte [eax+vehtype.flags], 2
	jz .nottest
	bts word [edi+veh.modflags], MOD_PROTOTYPE
.nottest:
	pop eax
	ret

