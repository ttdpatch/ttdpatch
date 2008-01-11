#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

global patchgotodepot
extern FindNearestTrainDepot

patchproc advorders, advorderspatchproc

begincodefragments

ext_frag findtracerestrict_FindNearestTrainDepot1

codefragment oldinsertorder
	mov dl,1
	mov [ebp],dx

codefragment newinsertorder
	call runindex(setordertype)

codefragment oldshoworder
	cmp bp,byte 0
	jz $+2+0x50

codefragment newshoworder
	call runindex(showorder)
	setfragmentsize 10

codefragment oldisshiporder,-23
	movzx ebp,bh
	dec bp

codefragment newisshiporder
	call runindex(isshiporder)
	jbe short $+0x76
	jmp short $+0x65

codefragment newisshiporder2
	push eax
	mov al,[ebp]
	and al,0x1f
	cmp al,1
	pop eax
	setfragmentsize 9

codefragment oldnewordertarget,-12
	cmp ah,byte [esi+veh.laststation]
	jne $+2+4

codefragment newnewordertarget
	call runindex(newordertarget)
	jc short $+2
newordertargetjc equ $-1

codefragment oldnextplaneorder
	add ah,9
	cmp al,1

codefragment newnextplaneorder
	call runindex(nextplaneorder)
	nop

codefragment newnextplaneorder0
	call runindex(nextplaneorder0)

codefragment oldisgoingtohangar,-6
	cmp al,2
	jnb $+2+0x57

codefragment newisgoingtohangar
	call runindex(isgoingtohangar)

codefragment oldnewaircrafttarget,-10
	cmp byte [esi+veh.aircraftop],0x12

codefragment newnewaircrafttarget
	call runindex(newaircrafttarget)
	setfragmentsize 8

codefragment oldarriveatdepot,-4
oldarriveatdepotvar equ $+2
	or word [edi+veh.vehstatus],byte 2

codefragment newarriveatdepot
newarriveatdepotvar:
	push edi
	call runindex(arriveatdepot)
	jz $+0x31
newarriveatdepotjmp equ $-1
	setfragmentsize 9

codefragment oldremovedepotfromarray
	add esi,byte 6
	cmp di,[esi]

codefragment newremovedepotfromarray
	push byte 0x11			// Note: this is vehicle type *minus one*, see removedepotfromarray()
newremovedepotfromarrayarg equ $-1
	call runindex(removedepotfromarray)

codefragment oldfindunuseddepot,-4
	jz short $+2+0x19
	add esi,byte 6

codefragment newfindunuseddepot
	call runindex(findnewdepotsslot)
	jz short $+2+0x17
	setfragmentsize 17,1

codefragment oldisdelstationorder,3
	add ebp,byte 2
	and dl,0x1f

codefragment newisdelstationorder
	call runindex(isdelstationorder)

codefragment oldleavehangar,-4
	and al,0x1f
	cmp al,2
	jz $+2-17

codefragment newleavehangar
	call runindex(leavehangar)
	nop
	nop
	db 0x72	// turn jz into jc

codefragment oldskipbutton, -5
	cmp dl,byte [edi+veh.totalorders]
	jb $+2+2

codefragment_call newskipbutton, skipbutton, 5+7+3

codefragment oldfullloadbutton,-26
	pop ax
	or dl,dl
	db 0x75	// jnz

codefragment newfullloadbutton
	call runindex(fullloadbutton)

codefragment oldcanceldepot
	mov word [esi+veh.currorder],0x100
	push ax

codefragment newcanceldepot
	call runindex(canceldepot)

codefragment VehOrdersWindowHandlerHookJmp1,-18
	js $+6+0x3C3
	cmp cl, 0
	db 0x0F, 0x84
	
//codefragment vehorderwinclicktoselhook
//	icall vehorderwinclicktoselhook_hook
	
codefragment vehorderwinSelItemToOrderIdxhook
	ijmp VehOrders@@SelItemToOrderIdx
	
codefragment vehorderwinitemoffsetshiftcorrectorhook
	icall vehorderwinitemoffsetshiftcorrectorhook_hook
	setfragmentsize 7
	
codefragment vehorderwinitemcounthook
	icall vehorderwinitemcounthook_hook
	setfragmentsize 13
endcodefragments

patchgotodepot:
	patchcode oldinsertorder,newinsertorder,1,1
	patchcode oldshoworder,newshoworder,1,1
	patchcode oldisshiporder,newisshiporder,1,1
	mov word [edi+lastediadj+17],0x9090
	add edi,byte lastediadj+33
	storefragment newisshiporder2

	mov byte [newordertargetjc],30+10*WINTTDX
	patchcode oldnewordertarget,newnewordertarget,1,3
	mov byte [newordertargetjc],40-10*WINTTDX
	patchcode oldnewordertarget,newnewordertarget,2,3
	mov byte [newordertargetjc],48+5*WINTTDX
	patchcode oldnewordertarget,newnewordertarget,3,3

	patchcode oldnextplaneorder,newnextplaneorder,1,1
	add edi,byte lastediadj-57
	storefragment newnextplaneorder0
	patchcode oldisgoingtohangar,newisgoingtohangar,1,1
	patchcode oldnewaircrafttarget,newnewaircrafttarget,1,1

	patchcode oldarriveatdepot,newarriveatdepot,1,2
	patchcode oldarriveatdepot,newarriveatdepot,1,1

	dec byte [oldarriveatdepotvar]
	dec byte [newarriveatdepotvar]

#if WINTTDX
	patchcode oldarriveatdepot,newarriveatdepot,1,2
	mov byte [newarriveatdepotjmp],0x2d
	patchcode oldarriveatdepot,newarriveatdepot,1,1

	patchcode oldremovedepotfromarray,newremovedepotfromarray,3,3	// ship
	dec byte [newremovedepotfromarrayarg]
	patchcode oldremovedepotfromarray,newremovedepotfromarray,1,2	// road
	dec byte [newremovedepotfromarrayarg]
	patchcode oldremovedepotfromarray,newremovedepotfromarray,1,1	// rail
#else
	patchcode oldarriveatdepot,newarriveatdepot,2,2
	mov byte [newarriveatdepotjmp],0x2d
	patchcode oldarriveatdepot,newarriveatdepot,1,1

	patchcode oldremovedepotfromarray,newremovedepotfromarray,1,3	// ship
	dec byte [newremovedepotfromarrayarg]
	patchcode oldremovedepotfromarray,newremovedepotfromarray,2,2	// road
	dec byte [newremovedepotfromarrayarg]
	patchcode oldremovedepotfromarray,newremovedepotfromarray,1,1	// rail
#endif

	patchcode oldfindunuseddepot,newfindunuseddepot,1,1
	patchcode oldisdelstationorder,newisdelstationorder,1,1

	patchcode oldleavehangar,newleavehangar,1,1

	patchcode oldfullloadbutton,newfullloadbutton,1,1
	mov dword [edi+lastediadj+36],0x90007520

	multipatchcode oldcanceldepot,newcanceldepot,4
	ret

exported patchskipbutton
	patchcode oldskipbutton,newskipbutton,1,1
	ret

extern vehorderwinhandlerhook,vehorderwinhandlerhook.oldfn
advorderspatchproc:
	stringaddress findtracerestrict_FindNearestTrainDepot1
	sub edi, 0x83+WINTTDX*0xE
	mov [FindNearestTrainDepot], edi
	stringaddress VehOrdersWindowHandlerHookJmp1
	chainfunction vehorderwinhandlerhook
	add edi, 0xC6
	//storefragment vehorderwinclicktoselhook
	add edi, 0x3DC-0xC6+lastediadj
	storefragment vehorderwinSelItemToOrderIdxhook	//5755A0,1635AF
	add edi, 0x112+lastediadj
	storefragment vehorderwinitemoffsetshiftcorrectorhook	//5756B2,1636C1
	add edi, lastediadj-0xBE
	storefragment vehorderwinitemcounthook	//5755F4,163603
	ret
