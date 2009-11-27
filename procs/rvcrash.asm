#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc newrvcrash, patchrvcrash


extern rvcrashtype

begincodefragments

codefragment oldrvcrashcheck,-7
	jz .end
	call $+5+0x5f
.end:
	ret

codefragment_call newrvcrashcheck, rvcrashcheck, 7

codefragment oldrvtraincollisionproc,1
	ret
	cmp byte [esi+veh.movementstat],-1

codefragment newrvtraincollisionproc
	ret
	

endcodefragments


patchrvcrash:
	mov bl,[rvcrashtype]

	stringaddress oldrvcrashcheck,1,1
	mov eax, [edi+2]
	extern rvcrashcheck.collidingRailVeh
	mov [rvcrashcheck.collidingRailVeh],eax

	cmp bl,1
	jnz .nopatch1_1
	storefragment newrvcrashcheck
.nopatch1_1:
	patchcode oldrvtraincollisionproc,newrvtraincollisionproc,1,1,,{cmp bl,2},e
	ret
