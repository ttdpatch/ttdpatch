#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc BIT(EXP_INCVEHCONSIST), patchincvehconsists

begincodefragments

codefragment oldcalctrainconnumber, -8
	cmp byte [edi+veh.class], 0x10
	jnz $+2+0x16
	cmp byte [edi+veh.subclass], 0
	jnz $+2+0x10
	mov dh, [edi+veh.owner]
codefragment newcalctrainconnumber
	icall calctrainconsistnumber
	jc .ok
	mov ebx, 0x80000000
	ret
.ok:
	setfragmentsize 54

endcodefragments

patchincvehconsists:
	patchcode calctrainconnumber
	ret

