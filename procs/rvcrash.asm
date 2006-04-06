#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc newrvcrash, patchrvcrash


extern rvcrashtype


patchrvcrash:
	mov bl,[rvcrashtype]

	stringaddress oldrvcrashcheck,1,1
	cmp bl,1
	jnz .nopatch1_1
	mov byte [edi+lastediadj],0x8b
	mov word [edi+lastediadj+6],0xff0b
	mov byte [edi+lastediadj+8],0x90
.nopatch1_1:
	patchcode oldcrashrv,newcrashrv,1,1,,{cmp bl,1},e
	patchcode oldcheckrvcrash,newcheckrvcrash,1,1,,{cmp bl,2},e
	ret



begincodefragments

codefragment oldrvcrashcheck,-7
	jz .end
	call $+5+0x5f
.end:
	ret

// replacement is created manually in patches.ah

codefragment oldcrashrv
	inc word [esi+0x68]
	or word [esi+veh.vehstatus],0x80

codefragment newcrashrv
	call runindex(crashrv)
	setfragmentsize 10
	
codefragment oldcheckrvcrash,1
	ret
	cmp byte [esi+veh.movementstat],-1

codefragment newcheckrvcrash
	ret
	

endcodefragments
