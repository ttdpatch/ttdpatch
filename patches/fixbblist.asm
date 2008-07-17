#include <std.inc>
#include <ptrvar.inc>
#include <flags.inc>
#include <bitvars.inc>
#include <veh.inc>

extern vehicledatafactor, datasize

uvard UpdateBBlockVehicleLists
uvarw maxveh

exported UpdateBBlockVehicleLists_anticrash_proc
	mov bp, [edi+4]
	mov di, [edi+2]
	cmp di, [maxveh]
	jae .error
	ret
.error:
	pop ebp	//kill return address

	pop ebp
	pop edi
	pop dx
	pop cx
	pop ebx
	pop ax
	ret


