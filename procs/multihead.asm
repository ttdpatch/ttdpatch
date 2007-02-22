#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc fastwagonsell,newtrains, patchwagonsell
patchproc newtrains, multihead, patchpower
patchproc newtrains, patchrunningcost

extern trainmaintcostarray,trainmaintbasecostarray

begincodefragments

codefragment newenginesellcost
	call runindex(enginesellcost)
	jc $+2+12	
	setfragmentsize 9

codefragment oldsellengine
	je near $+6+0x8c
	push edx

codefragment newsellengine
	call runindex(sellengine)

codefragment oldsellwagon
	jz $+2+0x7d
	cmp byte [edx+veh.subclass], 4

codefragment newsellwagon
	call runindex(sellwagon)
	jnz $+2+$1c
	mov bx,di
	setfragmentsize 12

codefragment newsellwagon2
	mov ax,di
	setfragmentsize 4

codefragment oldwagonsellcost
	mov ebx, [edx+veh.value]
	neg ebx
	pop cx

codefragment newwagonsellcost
	call runindex(wagonsellcost)
	setfragmentsize 7

codefragment oldshowpower
	mov ax,word [esi+veh.maxspeed]
	imul ax,byte 10
	shr ax,4

codefragment newshowpower
//	mov eax,dword [esi+veh.realpower]		//3
//	or eax,eax			//2
//	jnz short .good			//2
	call runindex(getoldpower)	//6 sum 13
	setfragmentsize 13,1
//.good:

codefragment oldwaggonvalue
#if WINTTDX
//	mov edx,[dsbase+4b94h]
	mov edx,[waggonbasevalue]
#else
	mov edx,[dword 0x4b94]
//	db 8bh,15h
//	dd 4b94h	 //	mov edx,[4b94h] (tasm makes a 16bit address!)
//	imul eax,edx
#endif

codefragment oldenginevalue
	mov edx,[enginebasevalue]
	sar edx,3

codefragment newenginevalue1
	call runindex(getrailvehiclebasevaluebothheadsifnotctrl)
	imul edx
	shrd eax,edx,8
	setfragmentsize 12	// need fragment in sizes 15 and 12
	setfragmentsize 15

reusecodefragment newwaggonvalue1,newenginevalue1,,12

codefragment newwaggonvalue2
	call runindex(getrailvehiclebasevalue)
	mov bl,[ebx+0x8fffffff]		// replaced by actual address of the table
	call runindex(imulebxedxshr8)

codefragment newenginevalue2
	call runindex(getrailvehiclebasevaluebothheads)
	movzx ebx,byte [ebx+0x8fffffff]	// replaced by actual address of the table
	xchg eax,ebx
	imul edx
	shrd eax,edx,8
	xchg ebx,eax
	ret				// code is just before a RET anyway

codefragment oldenginesellcost
	mov ebx,dword [edx+veh.value]
	neg ebx
	movzx esi, word [edx+veh.vehtype]

reusecodefragment oldengineselldualhead,oldenginesellcost,16

codefragment newengineselldualhead
	db 0xeb

codefragment oldtrainmaintcost,8
	test word [esi+veh.vehstatus],2
	jnz $+2+0x56

codefragment newtrainmaintcost
	call runindex(trainmaintcost)
	setfragmentsize 0x17,1

codefragment oldshowtrainmaintcost,-0x12
	imul eax,[ebx]
	shr eax,8

codefragment newshowtrainmaintcost
	push edx
	call runindex(trainmaintcost)
	shrd eax,edx,8
	pop edx
	setfragmentsize 0x18,1


endcodefragments

uvard vehiclecosttables,4,s

global traincosttable,roadvehcosttable,shipcosttable,aircraftcosttable
traincosttable equ	(vehiclecosttables+0*4)	// Table of cost multipliers of train engines and waggons
roadvehcosttable equ	(vehiclecosttables+1*4)	// Table of cost multipliers of road vehicles
shipcosttable equ	(vehiclecosttables+2*4)	// Table of cost multipliers of ships
aircraftcosttable equ	(vehiclecosttables+3*4)	// Table of cost multipliers of aircraft

patchpower:
	stringaddress oldshowpower,1,1
	add dword [edi+14],byte 2
	add edi,byte 18
	storefragment newshowpower
	ret

global patchmultihead
patchmultihead:
	patchcode oldwaggonvalue,newwaggonvalue1,1,2
	patchcode oldwaggonvalue,newwaggonvalue2,1,1,-6
	mov eax,dword [traincosttable]
	mov dword [edi-10],eax
	patchcode oldenginevalue,newenginevalue1,1,2
	patchcode oldenginevalue,newenginevalue2,1,1,-7
	mov eax,dword [traincosttable]
	mov dword [edi-13],eax
	patchcode oldengineselldualhead,newengineselldualhead,1,1
//	patchcode oldsecondenginevalue,newsecondenginevalue,1,1
//	patchcode oldbuysecondengine,newbuysecondengine,1,1
	ret

patchrunningcost:
	patchcode oldtrainmaintcost, newtrainmaintcost, 1+WINTTDX, 2
	patchcode oldshowtrainmaintcost, newshowtrainmaintcost, 1+WINTTDX, 2
	ret


// shares code fragments
patchwagonsell:
	patchcode oldenginesellcost,newenginesellcost,1,1
	patchcode oldsellengine,newsellengine,1,1

	patchcode oldsellwagon,newsellwagon,1,1
	add edi,lastediadj+63
	storefragment newsellwagon2
	patchcode oldwagonsellcost,newwagonsellcost,1,0
	ret
