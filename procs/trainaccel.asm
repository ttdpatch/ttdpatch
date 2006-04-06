#include <defs.inc>
#include <frag_mac.inc>

global patchtrainaccel
patchtrainaccel:
	patchcode oldcalcaccel,newcalcaccel,1,1
	add edi,lastediadj+50
	storefragment newcalcconsistweight
	patchcode oldcalcspeed,newcalcspeed,1+WINTTDX,2
	ret



begincodefragments

codefragment oldcalcaccel
	movzx ebx,word [esi+veh.vehtype]
	db 0x66,0x8b

codefragment newcalcaccel
	jmp runindex(calcaccel)

codefragment newcalcconsistweight
	jmp runindex(calcconsistweight)

codefragment oldcalcspeed
	movzx ax,byte [esi+veh.acceleration]

codefragment newcalcspeed
	call runindex(calcspeed)
	setfragmentsize 0x24,1


endcodefragments
