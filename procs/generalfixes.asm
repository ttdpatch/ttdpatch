#include <defs.inc>
#include <frag_mac.inc>
#include <textdef.inc>
#include <window.inc>
#include <bitvars.inc>
#include <player.inc>
#include <misc.inc>
#include <station.inc>
#include <town.inc>
#include <win32.inc>
#include <ptrvar.inc>

extern MsgWaitForMultipleObjects,ResetEvent,WaitForSingleObject
extern waitforkey.timeroffset,kernel32hnd,user32hnd
extern UpdateStationAcceptList,addexpenses,agevehicle.lostvehmessage
extern airportdimensions,class6periodicproc,deductvehruncost
extern fixremoveoilstation,fixremoveoilstation.delstation,floodtile
extern genericvehmsg,gettextandtableptrs,gettextintableptr
extern housespritetable,lorryhints,miscmodsflags
extern newdepotroutemaps,newrlesave.chunkptr,newtransmitaction
extern newtransmitaction.oldfn,patchflags
extern reloadenginesfn
extern reversetrain.cantreversemessage
extern vehnametextids
extern wait27ms_nogiveaway,backupvehnametexts
extern Class6FloodTile
extern Class6CoastSprites
extern newgraphicssetsenabled
extern waterbanksprites
extern CompanyVehiclesSummary
extern adddirectoryentrydir,firstnextlongfilename
extern drawtrainindepot, drawtrainwagonsindepot
extern floodbridgetile
ext_frag oldrecordlastactionxy

global patchgeneralfixes

begincodefragments

codefragment newtownmenu1
	call runindex(townmenu1)

codefragment oldtownmenu2
	mov bx,0x2046
	add bx,bp

codefragment newtownmenu2
	call runindex(townmenu2)
	setfragmentsize 7

codefragment oldtownmenu3
	add bx,0x204d

codefragment newtownmenu3
	call runindex(townmenu3)
	setfragmentsize 9

codefragment oldtownmenu4
	imul ebp,esi
	test bl,1

codefragment newtownmenu4
	call runindex(townmenu4)

codefragment oldtownselmax
	dec al
	cmp al,7
	db 0xf	// jae far...

codefragment newtownselmax
	cmp al,[esi+1]
	jae short $+2-14
	dec al
	js short $+2-40
	setfragmentsize 10

codefragment oldtownselfixidx,-7
	mov bh,[esi+0x22]

codefragment newtownselfixidx
	movzx ebx,byte [esi+0x22]
	// townselfixidx needs this value anyway - but in EBX, not BH
	call runindex(townselfixidx)

codefragment oldbuildhousegetdate,2
	push di
	db 0x66,0xa1	// mov ax,word ptr...

codefragment newbuildhousegetdate
	call runindex(buildhousegetdate)

codefragment oldamountinlitres,-7
	imul eax,byte 100
	push eax
	db 0xA1		// mov eax,...

codefragment newamountinlitres
	call runindex(amountinlitres)
	setfragmentsize 7

codefragment oldtownraiselowermaxcost
	mov esi,0x7e

codefragment newtownraiselowermaxcost
	call runindex(townraiselowermaxcost)
	setfragmentsize 8

codefragment oldgeneratezeppelin,6
	cmp byte [edi+station.airporttype],1

codefragment newgeneratezeppelin
	db 0

codefragment oldfindcompanygraphmax
	db 0x8b,4,0x2a	// mov eax,[ebp+edx] but force right order of operands

codefragment newfindcompanygraphmax
	call runindex(findcompanygraphmax)
	setfragmentsize 8

codefragment oldendofyear,-5
	jnz $+2+0x2e
	push dx

codefragment newendofyear
	setfragmentsize 5
	db 0xeb	// jnz -> jmp short

codefragment oldwaitforkey,4
	pop ax
	jb $+2+9

codefragment newwaitforkey
	call runindex(waitforkey)
	setfragmentsize 7

#if !WINTTDX
codefragment oldwait27ms
	cmp word [0x774d4],8

codefragment newwait27ms
	call runindex(wait27ms)
	setfragmentsize 10

codefragment oldwaittitle
	db 0x66, 0x36, 0x81, 0x3d, 0xd4, 0x74, 0x07, 0x00	// cmp [ss:0x774d4],??

codefragment newwaittitle
	call runindex(waittitle)
	db 0x66, 0x3d						// cmp ax, ??
#endif

codefragment oldrlesave1,-6
	cmp al,[edi]
	jz $+2+0x44

codefragment newrlesave1
	icall newrlesave
	setfragmentsize 8

codefragment oldrlesave2
	push ax
	db 0xfe,0x0d		// dec byte [...

codefragment oldcanvehiclebreakdown
	test word [esi+veh.vehstatus],2
	jnz near $+6+0x92

codefragment newcanvehiclebreakdown
	icall canvehiclebreakdown

codefragment oldtrainignoredepotsignal,-10
	cmp byte [esi+veh.ignoresignals],0
	jne $+2+0x2e

codefragment newtrainignoredepotsignal
	icall trainignoredepotsignal
	jc fragmentstart+153
	setfragmentsize 14

codefragment oldinitpaymentrategraph
	mov word [ebp+graphdata.firstarg],10

codefragment newinitpaymentrategraph
	mov word [ebp+graphdata.firstarg],15
	mov word [ebp+graphdata.argstep],15

codefragment oilfieldaccepts,11
	movzx ebp,byte [esi+station.airporttype]

codefragment oldclearoilfield,-2
	cmp dh,0x4b
	je short $+2+0x27

codefragment newclearoilfield
	nop	// just kill the preceding JNZ
	nop

codefragment oldplanecrash,9
	movzx eax,byte [esi+0x63]

codefragment newplanecrash
	call runindex(freeterminaloncrash)

codefragment oldsendtohangar
	mov ah,byte [esi+veh.targetairport]
	db 0xf		// movzx edx,ah

codefragment newsendtohangar
	call runindex(gettargethangar)

codefragment oldgetrvmovementbyte1
	add bl,[roadtrafficside]

codefragment newgetrvmovementbyte1
	call runindex(getrvmovementbyte1)

codefragment oldgetrvmovementbyte2
	add dl,[roadtrafficside]

codefragment newgetrvmovementbyte2
	call runindex(getrvmovementbyte2)

codefragment oldvehiclelist,5
	cmp ah,byte [edi+veh.owner]
	jne $+2+4

codefragment newvehiclelist
	sub al,1
	db 0x72		// jb instead of js

codefragment oldinitbubble
	pop eax
	mov word [edi+veh.currentload],ax

codefragment newinitbubble
	jmp runindex(initbubble)

codefragment oldrememberzoomlevel,-2
	db 0x16
	mov ax,[esi+8]

codefragment newrememberzoomlevel
	call runindex(rememberzoomlevel)
	setfragmentsize 7

codefragment oldmakegiantscreenshot,40
	pop cx
	db 0x67,0xE2,0xE0-3*WINTTDX	// a16 loop $+3-32-3*WINTTDX
					// NASM 0.98.36 and earlier interpreted '$' differently with the a16 prefix

codefragment newmakegiantscreenshot
	call runindex(makegiantscreenshot)
	setfragmentsize 10

codefragment oldissubsidytotown1
	mov [textrefstack+6],ebx
	cmp al,5

codefragment newissubsidytotown1
	call runindex(issubsidytotown1)
	setfragmentsize 8

codefragment oldissubsidytotown2
	cmp ch,2
	jz short $+2+0x14

codefragment newissubsidytotown2
	call runindex(issubsidytotown2)
	setfragmentsize 8

codefragment oldchksubsidytotown
	cmp word [edi+town.population],900

codefragment newchksubsidytotown
	call runindex(chksubsidytotown)

codefragment olddisplsubsidyowner
	movzx eax,byte [eax+station.owner]

codefragment newdisplsubsidyowner
	call runindex(getsubsidyowner)
	jnb short $+3+25
	setfragmentsize 9

codefragment olddeletestationrefs,-6
	cmp byte [edi],0
	jz short $+2+0x43

codefragment newdeletestationrefs
	call runindex(deletestationrefs)

codefragment removeoilstation,37
	and byte [esi+0x80],0xE7	// esi+station.facilities
	db 0x66,0xc7,0x86,0x86		// mov word [esi+station.airportstat],0

codefragment_jmp newdeductvehruncost,dodeductvehruncost,5

codefragment newaddexpenses
	call runindex(doaddexpenses)
	jmp fragmentstart+32

codefragment oldcompanyvalue,-2
	add eax,[esi+player.cash]

codefragment newcompanyvalue
	jmp runindex(companyvalue)

codefragment oldshowcompanycash
	mov eax,[ebx+player.cash]
	db 0xa3		// mov [textrefstack],eax

codefragment newshowcompanycash
	icall showcompanycash
	mov bx,statictext(disp64bitcash_black)
	setfragmentsize 12

codefragment oldshowcompanynet
	mov eax,[ebx+player.cash]
	sub eax,[ebx+player.loan]

codefragment newshowcompanynet
	icall showcompanynet
	mov bx,statictext(disp64bitcash_black)
	setfragmentsize 15

codefragment oldshowstatuscash
	mov eax,[esi+player.cash]
	mov [textrefstack],eax

codefragment newshowstatuscash
	mov ebx,esi
	icall showcompanycash
	mov bx,statictext(disp64bitcash_white)
	setfragmentsize 12

codefragment olddeletecompany
	mov dword [esi+player.cash],100000000

codefragment newdeletecompany
	icall deletecompany
	setfragmentsize 7

codefragment oldstartnewcompany
	mov [esi+player.tracktypes],cl

codefragment_call newstartnewcompany,startnewcompany

codefragment oldaddmergermoney,-11
	add [ecx+player.cash],eax
	add [ecx+player.thisyearexpenses+expenses_other],eax

codefragment newaddmergermoney
	pusha
	mov ebx,eax
	mov eax,ecx
	neg ebx
	mov ah,expenses_other
	call runindex(addexpensestoplayerwithtype)
	popa
	setfragmentsize 17

codefragment oldcheckzeppelincrasharea1
	cmp al,8
	jb $+2+0x38-3*WINTTDX
	cmp al,0x43

codefragment newcheckzeppelincrasharea
	call runindex(checkzeppelincrasharea)

codefragment oldcheckzeppelincrasharea2
	cmp al,8
	jb $+2+0x72-3*WINTTDX
	cmp al,0x43

codefragment oldcantbuildbridgepopup,4
	mov bx,0x5015		// "Can't build bridge here..."
	db 0x66,0x8b,0x15	// mov dx,[...]

codefragment newcantbuildbridgepopup
	mov dx,di
	setfragmentsize 7

codefragment oldturnbackship
	xor bl,4
	mov [esi+veh.direction],bl

codefragment newturnbackship
	call runindex(turnbackship)

codefragment oldtownmenu1
	mov [esi+0x2a],ecx
	mov [esi+1],bl

reusecodefragment oldtownactionthreshold,oldtownmenu1,-0x29

codefragment newtownactionthreshold
	call runindex(townactionthreshold)

codefragment newrecordlastactionxy
	call runindex(chkrecordactionxy)

codefragment oldcanplacebuoy,-9
	cmp dx,0x30

codefragment newcanplacebuoy
	call runindex(canplacebuoy)
	jz $+21+2*WINTTDX
	setfragmentsize 9

codefragment oldroadsellout,4,6
#if WINTTDX
	mov dl,[landscape5(bx)]
#else
	db 0x67,0x65,0x8a,0x17		// mov dl, [gs:bx] with different order of prefixes
#endif
	and dl,0xf0
	cmp dl,0x10
	pop dx
//	je somewhere

codefragment newroadsellout
	call runindex(roadsellout)
	pop dx
	setfragmentsize 10

codefragment oldtownclaimroad,2
	add al,0x80
	mov [landscape1+ebx],al

codefragment newtownclaimroad
	call runindex(townclaimroad)

// Several GUI related functions
codefragment olddeletetown,2
	push edi
	push esi
	mov bl,1

codefragment newdeletetown
	call runindex(deletetown)

codefragment oldmakedropdownmenu1
	mov ax,[ebp+windowbox.y2]
	add ax,2

codefragment newmakedropdownmenu1
	mov ax,[ebp-0xc+windowbox.y2]
	inc ax
	setfragmentsize 8

codefragment oldmakedropdownmenu2
	mov cx,0x3f
	mov dx,-1

codefragment newmakedropdownmenu2
	call runindex (makedropdownmenu)
	setfragmentsize 8

codefragment oldwaterroutehandler
	or si,si
	jnz $+2+0xf
	cmp ax,4
	jnz $+2+6

codefragment newwaterroutehandler
	cmp ax,4
	jnz $+2+0xb
	or si,si
	jnz $+2+9

codefragment findlorryhints,29
	movzx ebx,cx
	db 0x81, 0x7e, 0x24	// cmp [esi+window.elemlistptr],...

codefragment oldcheckforrocks,-4,-6
	and al,0x1c
	cmp al,8

codefragment newcheckforrocks
	call runindex(checkforrocks)
	setfragmentsize 6+2*WINTTDX

codefragment oldupdatehedges1
	test word [nosplit landscape3+2*ebx],0xe000

codefragment newupdatehedges1
	call runindex(updatehedges1)
	setfragmentsize 10

codefragment oldupdatehedges2
	test word [nosplit landscape3+2*ebx],0x1c00

codefragment newupdatehedges2
	call runindex(updatehedges2)
	setfragmentsize 10

codefragment oldcalciconstodraw,4
	add ax,5
	mov dl,10

codefragment newcalciconstodraw
	call runindex(calciconstodraw)
	setfragmentsize 14

codefragment olddepotroutehandler,8
	cmp ah,0xc0
	jnz $+2+0x0f

codefragment newdepotroutehandler
	mov ax,[newdepotroutemaps+esi*2]
	setfragmentsize 8

codefragment oldcrashplane
	or word [esi+veh.vehstatus],0x80
	mov word [esi+0x64],0

codefragment newcrashplane
	call runindex(crashplane)

codefragment oldcrashzeppelin
	mov word [esi+veh.age],0
	movzx edi, byte [landscape2+ebx]

codefragment newcrashzeppelin
	call runindex(crashzeppelin)

codefragment oldwhatvehicleintheway
	mov word [operrormsg2],0x980e

codefragment newwhatvehicleintheway
	call runindex(whatvehicleintheway)
	setfragmentsize 9

codefragment oldgenvehmessage,-1
	mov [textrefstack],eax
	mov ebx,0x50a00

codefragment newgenvehmessage
	call runindex(genvehmessage)

codefragment newgenvehmessageedi
	xchg esi,edi
	call runindex(genvehmessage)
	xchg esi,edi
	setfragmentsize 11

codefragment oldintrocheckkey,-6
	add cl,9

codefragment newintrocheckkey
	nop
	db 0xe9		// turn jcc near into jmp near

codefragment oldsubtractruncosts
	shr ebx,8
	sub [esi+veh.profit],ebx

codefragment newsubtractruncosts
	icall subtractruncosts

codefragment oldcheckstationindustrydist
	cmp bp, 10h
	db 0x77, 0x14 // ja ..

codefragment newcheckstationindustrydist
	icall checkstationindustrydist

codefragment oldcalccatchment
	add ch,4
	jnc .nooverflow
	mov ch,0xff
.nooverflow:
	sub cx,bx

	push bx
	push cx
	push bx
	push cx

codefragment newcalccatchment
	icall calccatchment
	setfragmentsize 7

codefragment findUpdateStationAcceptList,-0x1b
	mov bx,0xffff
	xor cx,cx

codefragment oldoldvehiclenews
	mov cl, [esi+veh.owner]
	db 0x3a, 0x0d // mov cl, []

codefragment newoldvehiclenews
	ret

codefragment oldgetindustryslot
	mov esi,[industryarrayptr]
	xor al,al

codefragment newgetindustryslot
	ijmp getindustryslot


#if WINTTDX
codefragment olddemolish6x6,4
	push bx
	mov ch,6
	push bx

#endif

#if WINTTDX
codefragment oldcreatesenderplayer
	push 0
	lea eax,[ebp-0x1c]
	push eax
	lea eax,[ebp-8]

codefragment newcreatesenderplayer
	call runindex(createsenderplayer)

codefragment oldcreatereceiverplayer
	push 0
	lea eax,[ebp-0x20]
	push eax
	lea eax,[ebp-0xc]

codefragment newcreatereceiverplayer
	call runindex(createreceiverplayer)

codefragment oldrecbuffer
	push 1
	lea eax,[ebp-4]
	push eax

codefragment newrecbuffer
	call runindex(recbuffer)

codefragment oldwaitforconnection1,4
	lea eax,[ebp-0x78]
	push eax
	call dword [PeekMessage]

codefragment newwaitforconnection1
	call runindex(waitforconnection1)
#endif

#if WINTTDX
codefragment oldflashcrossing
	mov [ebp],dl
	mov word [ebp+1],0

codefragment newflashcrossing
	movzx edx,dl
	shl edx,18
	mov [ebp],edx

codefragment oldpalanim
	cmp dword [0x41a914],0xec

codefragment newpalanim
	mov dword [0x41e8b0],1
	jmp short $+39

codefragment oldcomparefilenames
	mov al,[ebx]
	cmp al,[esi]
	jnz $+2+0x2d

codefragment newcomparefilenames
	call runindex(comparefilenames)
#endif

// long filename support
#if WINTTDX
codefragment oldadddirectoryentrydir,4
	mov al, 2
	push ss
	pop es

codefragment oldfindfirstnextfile
	mov al, [ebp-0x140]

codefragment newfindfirstnextfile
	icall firstnextlongfilename
#endif

codefragment oldgetsnowyheight
	cmp dl,[snowline]
	db 0x76		// jbe ...

codefragment_call newgetsnowyheight,getsnowyheight

codefragment oldgetsnowyheight_fine
	mov bh,[snowline]
	sub bh,8

codefragment_call newgetsnowyheight_fine,getsnowyheight_fine

codefragment oldcalcboxz
	add si,cx
	add dh,dl

codefragment_call newcalcboxz,calcboxz,5

codefragment oldfindtilestorefresh,3
	add dx,0xf1

codefragment newfindtilestorefresh
	dw (8<<5) + 0x1f

#if WINTTDX
codefragment oldfloodtile,-32
#else
codefragment oldfloodtile,-20
#endif
	mov dh, [landscape4(bp, 1)+ebx]
	and dx, 0x0F0F

codefragment newfloodtile
	icall Class6FloodTile
	ret

codefragment oldcoastsprites
	mov bx, [dword 0+edi]
noglobal ovar oldcoastsprites.ptr, -4

codefragment newcoastsprites
	icall Class6CoastSprites
	setfragmentsize 7

codefragment oldcompanyvehiclessummary
	add cx, 70
	mov ax, [esi+window.id]
	
codefragment newcompanyvehiclessummary
	ijmp CompanyVehiclesSummary
	setfragmentsize 8

codefragment olddrawtrainindepot
	add cx, 21
	mov al, 10

codefragment newdrawtrainindepot
	icall drawtrainindepot

codefragment olddrawtrainwagonsindepot
	add cx, 50
	mov al, 9

codefragment newdrawtrainwagonsindepot
	icall drawtrainwagonsindepot

codefragment olddisplaytrainindepot
	add cx,0x1d
	mov di,[edi+veh.nextunitidx]

codefragment newdisplaytrainindepot
	call runindex(displaytrainindepot)
	setfragmentsize 8

codefragment oldchoosetrainvehindepot
	dec al
	js $+2+0x1a

codefragment newchoosetrainvehindepot
	jmp runindex(choosetrainvehindepot)

codefragment olddisplaytraininfosprite,-3
	db 14
	add dx,6
	db 0xbf		// mov edi,imm32

codefragment newshowactivetrainveh
	call runindex(showactivetrainveh)
	setfragmentsize 9

codefragment oldfloodbridgetile
	and dh, 0xC7
	or dh, 8

codefragment newfloodbridgetile
	icall floodbridgetile
	jc fragmentstart+73+8*WINTTDX
#if WINTTDX
	setfragmentsize 12
#else
	setfragmentsize 10
#endif

codefragment oldDistributeIndustryCargo_recession
	jg .norecession
	inc ah
	shr ah,1
.norecession:
	movzx cx,ah

// the above code gives 0 instead of 80h when ah=FFh, that needs to be fixed
codefragment newDistributeIndustryCargo_recession
	// cx=ah when we reach this point, so we can calculate with cx instead of ah
	// cx<=FFh, so the inc can't overflow
	jg .norecession
	inc cx
	shr cx,1
	mov ah,cl
	setfragmentsize 10
.norecession:

endcodefragments

patchgeneralfixes:
#if WINTTDX
	// add long filename support
	stringaddress oldadddirectoryentrydir
	storefunctioncall adddirectoryentrydir
	multipatchcode findfirstnextfile,2
#endif

#if WINTTDX
	stringaddress olddemolish6x6,1,1
	mov byte [edi],0x90		// PUSH BX -> PUSH EBX
	mov byte [edi+11],0x90		// POP BX -> POP EBX
#endif

	// fix custom vehtype names not deallocated if Play Scenario used
	mov edi,[reloadenginesfn]
	add edi,[edi-4]			// follow a call
	mov word [edi],0x13EB		// jmp short $+2+0x13

	patchcode oldbuildhousegetdate,newbuildhousegetdate,1,1

	mov ebx,[miscmodsflags]
	patchcode oldamountinlitres,newamountinlitres,1,1,,{test bl,MISCMODS_DONTFIXLITRES},z
	patchcode oldtownraiselowermaxcost,newtownraiselowermaxcost,1,1,,{test bl,MISCMODS_OLDTOWNTERRMODLIMIT},z
	test bl,MISCMODS_DONTFIXHOUSESPRITES
	jnz .shopsspritesdone
	mov eax,[housespritetable]
	mov byte [eax+0x4c2f],0xe1	// 31C8000h+4579 -> 31C8000h+4577

.shopsspritesdone:
	patchcode oldfindcompanygraphmax,newfindcompanygraphmax,1,1,,{test BH,MISCMODS_NORESCALECOMPANYGRAPH>>8},z
	patchcode oldendofyear,newendofyear,1,1,,{test bh,MISCMODS_NOYEARLYFINANCES>>8},nz

// Giving time slices away is done differently for the DOS and Windows versions
#if WINTTDX
	stringaddress oldwaitforkey,1,1
	test bh,MISCMODS_NOTIMEGIVEAWAY>>8
	jnz .nokeywaitpatch
	mov eax,[edi+3]
	mov [waitforkey.timeroffset],eax
	storefragment newwaitforkey
.nokeywaitpatch:

	// Waitloop moved to patchwaitloop (Sander)

	patchcode oldcreatesenderplayer,newcreatesenderplayer,1,1,,{test bh,MISCMODS_NOTIMEGIVEAWAY>>8},z
	patchcode oldcreatereceiverplayer,newcreatereceiverplayer,1,1,,{test bh,MISCMODS_NOTIMEGIVEAWAY>>8},z
	patchcode oldrecbuffer,newrecbuffer,1,1,,{test bh,MISCMODS_NOTIMEGIVEAWAY>>8},z
	patchcode oldwaitforconnection1,newwaitforconnection1,1,1,,{test bh,MISCMODS_NOTIMEGIVEAWAY>>8},z
	test bh,MISCMODS_NOTIMEGIVEAWAY>>8
	jnz .giveawaydone
	pusha
	push aWaitForSingleObject
	push dword [kernel32hnd]
	call dword [GetProcAddress]	// GetProcAddress(kernel, "WaitForSingleObject")
	mov [WaitForSingleObject],eax
	push aResetEvent
	push dword [kernel32hnd]
	call dword [GetProcAddress]	// GetProcAddress(kernel, "ResetEvent")
	mov [ResetEvent],eax

	push aMsgWaitForMultipleObjects
	push dword [user32hnd]
	call dword [GetProcAddress]	// GetProcAddress(user32, "MsgWaitForMultipleObjects")
	mov [MsgWaitForMultipleObjects],eax
	popa
.giveawaydone:
#else
// try to give away a timeslice to check if it's supported
	mov ax,0x1680
	test bh,MISCMODS_NOTIMEGIVEAWAY>>8	// make it automatically fail if disabled
	jnz .al_ok
	int 0x2f	// call the interrupt
// The interrupt returns with al=0 if the call is supported.
// Install the patches only in this case (otherwise they have no use).
.al_ok:
	movzx ebp,al
	stringaddress oldwait27ms,1,1
	test ebp,ebp
	jz .dogiveaway
	testflags gamespeed
	jnc .nogiveaway

	// gamespeed is on, but we can't (or shouldn't) give away time slices
	mov dword [wait27ms_indirect],addr(wait27ms_nogiveaway)
.dogiveaway:
	storefragment newwait27ms
.nogiveaway:
	multipatchcode oldwaittitle,newwaittitle,3,,{or ebp,ebp},z
	patchcode oldwaitforkey,newwaitforkey,1,1,,{or ebp,ebp},z
#endif

// apply a little tweak on the RLE compression algorithm (see details in fixmisc.asm at newrlesave)

	stringaddress oldrlesave1
	test ebx,MISCMODS_NOENHANCEDCOMP
	jnz .norle1
	mov eax,[edi+2]
	mov [newrlesave.chunkptr],eax
	storefragment newrlesave1

.norle1:
	stringaddress oldrlesave2
	test ebx,MISCMODS_NOENHANCEDCOMP
	jnz .norle2

	// old code:
	//	push ax
	//	dec byte [bBytesInRLEChunk]
	//
	// new code:
	//	push eax	// to save one byte
	//	sub byte [bBytesInRLEChunk],2

	mov eax,[edi+4]
	mov dword [edi],0x002d8050
	mov [edi+3],eax
	mov byte [edi+7],2

	// pop ax -> pop eax (because of modifying the push above)
	mov byte [edi+41],0x90

	// mov byte [bBytesInRLEChunk],2 -> mov byte [bBytesInRLEChunk],3
	mov byte [edi+61],3

.norle2:
	// fix trains breaking down while waiting on a red signal
	patchcode oldcanvehiclebreakdown,newcanvehiclebreakdown,1,1,,{test ebx,MISCMODS_BREAKDOWNATSIGNAL},z

	patchcode trainignoredepotsignal

	patchcode oldinitpaymentrategraph,newinitpaymentrategraph,1,1,,{test ebx,MISCMODS_DONTFIXPAYMENTGRAPH},z

	stringaddress oilfieldaccepts,1,1
	mov dword [edi],airportdimensions
	patchcode oldclearoilfield,newclearoilfield,1,1
	patchcode oldplanecrash,newplanecrash,1,1
	multipatchcode oldsendtohangar,newsendtohangar,2
	multipatchcode oldgetrvmovementbyte1,newgetrvmovementbyte1,2
	multipatchcode oldgetrvmovementbyte2,newgetrvmovementbyte2,2
	multipatchcode oldvehiclelist,newvehiclelist,4
	patchcode oldinitbubble,newinitbubble,1,1
	patchcode oldrememberzoomlevel,newrememberzoomlevel,1,1
	patchcode oldmakegiantscreenshot,newmakegiantscreenshot,1,1
	patchcode oldissubsidytotown1,newissubsidytotown1,1,1
	patchcode oldissubsidytotown2,newissubsidytotown2,1,1
	patchcode oldchksubsidytotown,newchksubsidytotown,1,1
	patchcode olddisplsubsidyowner,newdisplsubsidyowner,1,1
	patchcode olddeletestationrefs,newdeletestationrefs,1,1

	// when a player owns the station of the oilfield and then the 
	// oilfield is removed, the station is screwed...
	// this will fix this oil station behavior ...
	stringaddress removeoilstation,1,1
	copyrelative fixremoveoilstation.delstation
	changereltarget 0,addr(fixremoveoilstation)

	mov eax,[deductvehruncost]
	lea edi,[eax+30]
	storefragment newdeductvehruncost
	mov eax,[addexpenses]
	lea edi,[eax+26]
	storefragment newaddexpenses
	patchcode oldcompanyvalue,newcompanyvalue,1,1
	patchcode oldaddmergermoney,newaddmergermoney
	patchcode showcompanycash
	patchcode showcompanynet
	patchcode showstatuscash
	patchcode startnewcompany
	patchcode deletecompany

	patchcode oldgeneratezeppelin,newgeneratezeppelin,1,1,,{test word [miscmodsflags],MISCMODS_NOZEPPELINONLARGEAP},nz
	multipatchcode oldcheckzeppelincrasharea1,newcheckzeppelincrasharea,2
	patchcode oldcheckzeppelincrasharea2,newcheckzeppelincrasharea,1,1

	multipatchcode oldcantbuildbridgepopup,newcantbuildbridgepopup,2
	patchcode oldturnbackship,newturnbackship,1,1
	patchcode oldtownactionthreshold,newtownactionthreshold,1,1

	patchcode oldrecordlastactionxy,newrecordlastactionxy,1,1
	chainfunction newtransmitaction,.oldfn,lastediadj-5
	patchcode oldcanplacebuoy,newcanplacebuoy,1,1

	patchcode oldroadsellout,newroadsellout,1,1
	patchcode oldtownclaimroad,newtownclaimroad,1,1

	patchcode olddeletetown,newdeletetown,1,1

	patchcode oldmakedropdownmenu1,newmakedropdownmenu1,1,1
	patchcode oldmakedropdownmenu2,newmakedropdownmenu2,1,1

	// Fix trains and RVs on water bug
	patchcode oldwaterroutehandler,newwaterroutehandler,1,1

#if WINTTDX
	multipatchcode oldflashcrossing,newflashcrossing,2
	patchcode oldpalanim,newpalanim,1,1
#endif
	stringaddress findlorryhints,2,2
	mov dword [edi],lorryhints

	patchcode oldcheckforrocks,newcheckforrocks,1,1

	patchcode oldupdatehedges1,newupdatehedges1,1,1
	patchcode oldupdatehedges2,newupdatehedges2,1,1

	patchcode oldcalciconstodraw,newcalciconstodraw,1,1

	patchcode olddepotroutehandler,newdepotroutehandler,1,1

	patchcode oldcrashplane,newcrashplane,1,1
	patchcode oldcrashzeppelin,newcrashzeppelin,1,1
	patchcode oldwhatvehicleintheway,newwhatvehicleintheway,1,1

// Best applied even if noedgeflood
	patchcode oldfloodbridgetile, newfloodbridgetile

	mov ebx,[miscmodsflags]

	// make edges of the world flood too
	mov eax,[ophandler+0x30]// class 6
	mov edi,[eax+0x20]	// class 6 periodic proc handler

	push eax
	storefunctiontarget 40,floodtile

#if WINTTDX
	// fix Fish UK not knowing the difference between signed short and unsigned short
	mov byte [eax+1],0xbf	// change movzx to movsx in Windows version
	mov byte [eax+23],0xbf	// (otherwise it uses the wrong offset)
	inc ah
	mov byte [eax-158],0x90
	mov byte [eax-151],0x90
	mov byte [eax-148],0x90
#endif

	pop eax	

	xor ebp,ebp

	test bh,MISCMODS_NOWORLDEDGEFLOODING>>8
	jnz near .noedgeflood

	mov edi,addr(class6periodicproc)
	xchg edi,[eax+0x20]	// class 6 periodic proc handler

	mov ebp,1

.noedgeflood:
	// Only run the following fragements if diagonal flooding is enabled

	bt ebx, MISCMODS_NODIAGONALFLOODING_NUM
	cmc
	adc ebp,0

	// now ebp=2 if and only if both edge flooding and diagonal flooding are enabled

	// Loads the new flood subroutine which allows diagonal flooding.
	patchcode oldfloodtile,newfloodtile,1,1,,{cmp ebp,2},e

//	cmp ebp,2
//	jnz near .nodiagonalflooding

	// Populate bad array entries
	// Note: Higherbridges will use them aswell, so they need to be always patched!
	mov edi,[waterbanksprites]
	mov word [edi+0x00], 3997 // Steep
	mov word [edi+0x0A], 3998 // Steep
	mov word [edi+0x0E], 3988
	mov word [edi+0x14], 3996 // Steep
	mov word [edi+0x16], 3992
	mov word [edi+0x1A], 3994
	mov word [edi+0x1C], 3995
	mov word [edi+0x1E], 3999 // Steep

	cmp ebp,2
	jnz .nodiagonalflooding

	// Allow the action5 graphics to be loaded
	or dword [newgraphicssetsenabled], 1<<0x0D
.nodiagonalflooding:

//	see ChangeCoastSpriteTable
	mov edi,[waterbanksprites]
	mov [oldcoastsprites.ptr],edi
	patchcode oldcoastsprites,newcoastsprites,1,1,,{cmp ebp,2},e // patch the place where it is used in TTD

	// ------- change vehicle messages to show vehicle name --------

	// fragments use ESI EDI EDI ESI ESI in that order
	patchcode oldgenvehmessage,newgenvehmessage,1,5,,{test bh,MISCMODS_USEVEHNNUMBERNOTNAME>>8},z
	scasd		// otherwise below finds same place again
	patchcode oldgenvehmessage,newgenvehmessageedi,1,0,,{test bh,MISCMODS_USEVEHNNUMBERNOTNAME>>8},z
	scasd
	patchcode oldgenvehmessage,newgenvehmessageedi,1,0,,{test bh,MISCMODS_USEVEHNNUMBERNOTNAME>>8},z
	scasd
	patchcode oldgenvehmessage,newgenvehmessage,1,0,,{test bh,MISCMODS_USEVEHNNUMBERNOTNAME>>8},z
	scasd
	patchcode oldgenvehmessage,newgenvehmessage,1,0,,{test bh,MISCMODS_USEVEHNNUMBERNOTNAME>>8},z

	// patch the lost vehicles code too
	test bh,MISCMODS_USEVEHNNUMBERNOTNAME>>8
	jnz near .notwithname

	mov edi,addr(agevehicle.lostvehmessage)
	storefragment newgenvehmessage

	mov edi,addr(reversetrain.cantreversemessage)
	storefragment newgenvehmessage

	mov esi,vehnametextids

.fixnextmsg:
	lodsw
	test ax,ax
	jz near .donefixing

// First check if the user specified an explicit replacement in custom texts
	push eax
	mov eax,esi
	sub eax,vehnametextids
	shr eax,2
	add eax,ourtext(newtrainindepot)	// not newstext, we want the actual string data
	call gettextandtableptrs
	cmp byte [edi],0
	je .defaultchange	// do it automatically if the replacement string is empty

// we have a replacement - replace the original pointer with a pointer to it
	mov ebx,edi
	lodsw
	call gettextintableptr
	jnc .nosubtract
	sub ebx,eax
.nosubtract:
	mov [eax+edi*4],ebx
	pop edi
	jmp short .fixnextmsg	


.defaultchange:
	pop eax

	mov edi,genericvehmsg
	mov ebp,0xffffff00	// mask for which bytes count when cmp'ing

	cmp ax,byte -1
	je .fixmsg	// got edi=genericvehmsg already

	call gettextandtableptrs
	or ebp,byte -1
.fixmsg:
	mov al,0	// now edi=>what the vehicle type+number looks like
	or ecx,byte -1	// e.g. "Train ",7c
	repne scasb	// find string terminator
	mov ebx,[edi-5]

	lodsw
	call gettextandtableptrs
	push esi
	mov esi,edi

	// now ecx = length of text we're searching for
	// ebx = last four bytes of text, esi=edi=>text to change

.nextbyte:
	mov eax,[edi]
	and eax,ebp
	cmp eax,ebx
	je .foundit
	inc edi
	cmp al,0x7c
	je .badfix
	cmp al,0
	jne .nextbyte
.fail:
	mov dword [esi],0x003F3F80	// show only "name??" for safety reasons
	jmp short .done

.badfix:	// didn't find entire message, only change 7c to 80
		// so it'll say "Train Train 50", oh well...
	mov byte [edi-1],0x80
	jmp short .done

.foundit:
	// remove part without the 7c

	lea esi,[edi+4]
	lea edi,[esi+ecx+2]

	mov al,0x80
	stosb

	// now edi=>text to remove, esi=>last byte, ecx=num bytes to remove
.copynext:
	lodsb
	stosb
	test al,al
	jnz .copynext

.done:
	pop esi
	jmp .fixnextmsg

.donefixing:

	call backupvehnametexts

.notwithname:

	// -----------------------------------------------------

	patchcode oldintrocheckkey,newintrocheckkey,1,3+WINTTDX,,{test byte [miscmodsflags+2],MISCMODS_DOSHOWINTRO>>16},z
#if WINTTDX
	patchcode oldcomparefilenames,newcomparefilenames,1,1
//	stringaddress oldsoundeffectvolume,1,1
//	mov eax,[edi+3]
//	mov [soundeffectvolume.relvolume],eax
//	storefragment newsoundeffectvolume
#endif

	multipatchcode subtractruncosts,4
	
	// extend the allowed distance between station sign and industry
	patchcode oldcheckstationindustrydist,newcheckstationindustrydist,1,1,,{test dword [miscmodsflags],MISCMODS_NOEXTENDSTATIONRANGE},z
	patchcode oldcalccatchment,newcalccatchment,1,4,,{test dword [miscmodsflags],MISCMODS_NOEXTENDSTATIONRANGE},z
	storeaddress findUpdateStationAcceptList,1,1,UpdateStationAcceptList
	// disable news messages for old vehicles
	patchcode oldoldvehiclenews,newoldvehiclenews,1,1,,{test dword [miscmodsflags],MISCMODS_NOOLDVEHICLENEWS},nz

	// better error message when placing industry fails because of too many
	patchcode getindustryslot

	multipatchcode oldgetsnowyheight,newgetsnowyheight,3,,{test dword [miscmodsflags],MISCMODS_DONTCHANGESNOW},z
	multipatchcode oldgetsnowyheight_fine,newgetsnowyheight_fine,2,,{test dword [miscmodsflags],MISCMODS_DONTCHANGESNOW},z

	patchcode calcboxz
	patchcode findtilestorefresh

	patchcode companyvehiclessummary

	// Couple of fragments taken from other code to try and keep depot window fixes without dependences
	patchcode olddrawtrainindepot,newdrawtrainindepot,1,1 // Failsafe from winsize.asm
	patchcode olddrawtrainwagonsindepot,newdrawtrainwagonsindepot//,1,1

	stringaddress olddisplaytraininfosprite // More complex for patching this
	add edi, 44
	storefragment newshowactivetrainveh

	patchcode olddisplaytrainindepot,newdisplaytrainindepot,1,1
	patchcode oldchoosetrainvehindepot,newchoosetrainvehindepot,1,1
	mov word [edi+lastediadj-18],0xc38b	// mov eax,ebx instead of mov al,bl

	multipatchcode DistributeIndustryCargo_recession,2

	// fix wrong color code for text ID 22D
	mov ax,0x22d
	call gettextandtableptrs
	cmp byte [edi],0x98
	jne .notwrongcode
	mov byte [edi],0x90
.notwrongcode:
	ret

// shares some code fragments
global patchbribe
patchbribe:
	patchcode oldtownmenu1,newtownmenu1,1,1
	patchcode oldtownmenu2,newtownmenu2,1,1
	mov byte [edi+0x23+lastediadj],8
	patchcode oldtownmenu3,newtownmenu3,1,1
	patchcode oldtownmenu4,newtownmenu4,1,1
	patchcode oldtownselmax,newtownselmax,1,1
	patchcode oldtownselfixidx,newtownselfixidx,1,1
	ret

#if WINTTDX
aWaitForSingleObject: db "WaitForSingleObject",0
aResetEvent: db "ResetEvent",0

aMsgWaitForMultipleObjects:db "MsgWaitForMultipleObjects",0
#endif
