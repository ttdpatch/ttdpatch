#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc BIT(EXP_INCVEHCONSIST), patchincvehconsists

begincodefragments

codefragment oldcalctrainconnumber, -8	//SetupNewTrain, 005760D9, BuyRailVehicle, _CS:001640CC
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
	
codefragment oldcalcshipconnumber, -8	//BuyShip, _CS:0016A45A
	cmp byte [edi+veh.class], 0x12
	jnz $+2+0x10
	mov dh, [edi+veh.owner]
codefragment newcalcshipconnumber
	icall calcshipconsistnumber
	jc .ok
	mov ebx, 0x80000000
	ret
.ok:
	setfragmentsize 48
	
codefragment oldcalcrvconnumber, -8	//BuyRoadVehicle, _CS:00167B28
	cmp byte [edi+veh.class], 0x11
	jnz $+2+0x10
	mov dh, [edi+veh.owner]
codefragment newcalcrvconnumber
	icall calcrvconsistnumber
	jc .ok
	mov ebx, 0x80000000
	ret
.ok:
	setfragmentsize 48

codefragment oldcalcairconnumber, -8	//BuyAircraft, _CS:0016E758
	cmp byte [edi+veh.class], 0x13
	jnz $+2+0x16
	cmp byte [edi+veh.subclass], 2
	ja $+2+0x10
	mov dh, [edi+veh.owner]
codefragment newcalcairconnumber
	icall calcairconsistnumber
	jc .ok
	mov ebx, 0x80000000
	ret
.ok:
	setfragmentsize 54
	
endcodefragments

patchincvehconsists:
	patchcode calctrainconnumber
	patchcode calcshipconnumber
	patchcode calcrvconnumber
	patchcode calcairconnumber
	ret

