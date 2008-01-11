//
// Allow adding depots/hangars/shipyards to vehicle orders
//

#include <std.inc>
#include <vehtype.inc>
#include <flags.inc>
#include <textdef.inc>
#include <station.inc>
#include <human.inc>
#include <patchdata.inc>
#include <window.inc>
#include <veh.inc>
#include <town.inc>
#include <misc.inc>
#include <ptrvar.inc>
#include <refit.inc>
#include <bitvars.inc>

extern actionhandler,adjustcapacity,callbackflags,copyvehordersfn
extern ctrlkeystate,curplayerctrlkey,currefitlist,delvehschedule
extern depotbuildslopemap,findvehontile,getrefitmask
extern invalidatehandle,ishumanplayer,isrealhumanplayer,isscheduleshared
extern needsmaintcheck.always,numvehshared,orderhints,patchflags
extern redrawscreen,resetorders_actionnum,cargotypes
extern saverestorevehdata_actionnum,savevehordersfn,shareorders_actionnum
extern vehcallback,miscmodsflags,CreateTextInputWindow,getnumber,DropDownExListDisabled

varw newunloadptr1,0x8828
varw newnonstopptr1,0x8825

//in esi=veh, out ebx=depot struc or 0
uvard FindNearestTrainDepot





#define DEPOTORDER 0a2h		// 2 + 20 + 80

#define DEPOTIFSERVICE 40h


// check whether target tile is a valid "goto" target
// in:	edi=landscape index
// out:	carry if it's a depot (not a hangar!)
//	zero if it's a station (or a hangar)
//	if it's a depot, also:
//	ecx=0
//	dh=depot number (or station number for planes), dl=DEPOTORDER
//	edi=pointer into depot array
//	otherwise:
//	ecx=1
//	dl=1
global checkgotostation
checkgotostation:
	xor ecx,ecx
	testflags gotodepot
	jnc .nodepot
	mov al,[landscape4(di)]
	mov ah,[landscape5(di)]
	and al,0xf0
	cmp al,0x10
	jz near .train

	cmp al,0x20
	jz near .road

	cmp al,0x60
	jz near .water

	cmp al,0x50
	jz near .planeorstation

.nodepot:
	testmultiflags sharedorders	// skip vehicle check if feature isn't enabled
	jz .novehicle_nopop
	pusha
	call findvehontile	// is there a vehicle?
	jz .novehicle
	movzx ebx,word [esi+window.id]	// get the current vehicle from the window data
	shl ebx,vehicleshift
	add ebx,[veharrayptr]
	cmp byte [ebx+veh.totalorders],0	// only copy/share if list is empty now
	jne .novehicle
	cmp edi,ebx	// can't click to the vehicle itself
	je .novehicle
	mov dl,[edi+veh.class]	// only same class
	cmp dl,[ebx+veh.class]
	jne .novehicle
	mov dl,[edi+veh.owner]	// and same owner
	cmp dl,[ebx+veh.owner]
	jne .novehicle
	cmp byte [ebx+veh.class],0x11	// prevent bus/truck combination
	jne .rvcheckdone
	
	cmp byte [ebx+veh.cargotype],0
	setz dl
	cmp byte [edi+veh.cargotype],0
	setz dh
	cmp dl,dh
	je .rvcheckdone

.novehicle:
	popa
.novehicle_nopop:
	mov dl,1
	inc ecx
	cmp al,0x50
	clc
	ret


.rvcheckdone:
	mov byte [esi+window.selecteditem],0xff	// clear order selection in the orders window
	push byte CTRL_ANY + CTRL_MP		// we copy without Ctrl and share with it
	call ctrlkeystate
	jnz .copy

	mov edx,ebx
	xor ebx,ebx			// actually do it, not just check
	inc bl
	xor eax,eax			// no position assigned to this action
	xor ecx,ecx
	sub edx,[veharrayptr]
	sub edi,[veharrayptr]
	dopatchaction shareorders
	jmp short .continue


.copy:
	push ebx

	call makeordercopy

	pop edi				// call "reset orders" action
	pusha
	xor eax,eax
	xor ecx,ecx
	xor ebx,ebx
	inc bl
	mov dl,0			// don't allow ctrl to unshare
	sub edi,[veharrayptr]
	dopatchaction resetorders
	cmp ebx,0x80000000
	popa
	je .error

	call restoreordercopy

.error:
	call removeordercopy		// prevent newly bought vehicles getting this schedule

.continue:
	popa
	
	pop eax			// return to TTD code at a farther point than normally
	add eax,0xc7+8*WINTTDX
	jmp eax

.yep:
	mov dl,DEPOTORDER
	stc
	ret

.planeorstation:
// allow hangars only for planes - we can get here with other vehicle types as well
// if the station has other parts besides the airport
	push ebx
	movzx ebx,word [esi+window.id]	// get the current vehicle from the window data
	shl ebx,vehicleshift
	add ebx,[veharrayptr]
	cmp byte [ebx+veh.class],0x13
	pop ebx
	jne .nodepot

	cmp ah,0x41
	je short .hangar

	cmp ah,0x20
	jne .nodepot

.hangar:
	mov dl,DEPOTORDER
	inc ecx
	ret

.train:
	and ah,0xcc
	cmp ah,0xc0
	jne .nodepot
	jmp short .finddepot

.road:
	and ah,0x2c
	cmp ah,0x20
	jne .nodepot
	jmp short .finddepot

.water:
	cmp ah,0x80
	jb .nodepot
	je short .finddepot

	cmp ah,0x81
	je short .decedi

	cmp ah,0x83
	jb short .finddepot
	ja .nodepot

	// address to find is only one of the two squares of a shipyard,
	// so adjust edi by 100 or 1 accordingly
	sub di,0x100
	jmp short .finddepot

.decedi:
	dec edi

	// go through list of all depots to find out which one this is
.finddepot:
	push esi
	mov esi,depotarray
	inc ch

.nextdepot:
	cmp word [esi+depot.XY],di
	je short .foundit

	add esi,byte depot_size
	loop .nextdepot
	pop esi
	jmp .nodepot

.foundit:
	mov edi,esi
	pop esi
	mov dh,cl
	neg dh
	xor ecx,ecx
	jmp .yep
; endp checkgotostation

makeordercopy:
	mov esi,edi	// save the orders just like the source vehicle would be about to be sold
	mov edi,soldvehorderbuff
	mov byte [skipsharingcheck],1	// save shared orders normally
	call dword [savevehordersfn]
	mov byte [skipsharingcheck],0
	call clearadditionalsavedinfo	// don't restore anything but orders
	ret

restoreordercopy:
	mov esi,edi				// and copy the saved orders to the target
	mov edi,soldvehorderbuff
	call dword [copyvehordersfn]
	ret


// share orders between two vehicles
// in:	edi : offset of source vehicle
//	edx : offset of target vehicle
global shareorders
shareorders:
	test bl,1
	jz .exit
	pusha
	add edx,[veharrayptr]
	add edi,[veharrayptr]
	call dword [delvehschedule]
	mov ecx,[edi+veh.scheduleptr]
	mov [edx+veh.scheduleptr],ecx	
	mov cl,[edi+veh.totalorders]
	mov [edx+veh.totalorders],cl
	mov byte [edx+veh.currorderidx],0
	mov word [edx+veh.currorder],0x100
	mov al,0x40+0x10
	call dword [invalidatehandle]	// the window of the other veh. should be refreshed as well
	popa
.exit:
	xor ebx,ebx			// this costs nothing
	ret

// check whether a "goto" target has the right owner
// in:	=out from checkgotostation
// out:	ah=owner
//	cmp ah,10
global checkgotoowner
checkgotoowner:
	jecxz .depot

	mov ah,byte [edi+station.owner]

.gotit:
	cmp ah,0x10
	ret

.depot:
	push edi
	movzx edi,word [edi+depot.XY]
	mov ah,[landscape1+edi]
	pop edi
	jmp .gotit
; endp checkgotoowner 

// check whether a target is the right vehicle type
// in:	ah=bit in stationfacilities that must be set
// out:	zero flag = wrong type
//	not zero = right type
global checkgototype
checkgototype:
	jecxz .depot

	test byte [edi+station.facilities],ah
	ret

.depot:
	and eax,byte 0x13
	mov ah,byte [depottypes+eax-0x10]
	push edi
	movzx edi,word [edi+depot.XY]
	xor ah,[landscape5(di)]
	pop edi

	and ah,~ 3
	cmp ah,4
	jb short .isright
	and ah,0	// set zero
.isright:
	ret
; endp checkgototype 

var depottypes, db 0xc0,0x20,0x80,0x10

// show an order in the order list
// in:  ax=order
//	bp=order & 001Fh
//	esi=window
//	edi=vehicle
// out:	zf=1 if regular station, 0 if not
// safe:eax,esi,edi,ebp
global showorder
showorder:
	cmp bx, 0x8805
	ja .nochange
	push ecx
	and bl, ~1
	mov ecx, [esp+12]
	sub ecx, [edi+veh.scheduleptr]
	shr ecx, 1
	cmp cl, [edi+veh.currorderidx]
	jne .nocurselorder
	or bl, 1
.nocurselorder:
	pop ecx
.nochange:
	// Set up convenience registers for depot and special orders.
	mov esi,edi
	mov edi,textrefstack+1

	cmp bp,byte 2
	je short .depotorder
	cmp bp,byte 5
	je NEAR .special
	cmp bp,byte 1
	ret

.depotorder:
	movzx ebp,ah
	push ds
	pop es
	and eax,byte DEPOTIFSERVICE
	shr eax,6
	add ax,ourtext(gotodepot)
	stosw

	movzx eax,byte [esi+veh.class]
	push eax	// saved on stack: vehicle type
	push edi	// saved on stack: textrefstack+3
	inc edi
	inc edi

	cmp al,0x13
	jne short .noaircraft

	imul esi,ebp,station_size
	add esi,stationarray
	mov ax,word [esi+station.name]
	stosw
	mov ebp,dword [esi+station.townptr]
	movzx esi,word [esi+station.airportXY]
	jmp short .gotthecity

.noaircraft:
	lea eax, [ebp+1]
	imul esi,ebp,byte 6
	add esi,depotarray
	mov ebp,dword [esi+depot.townptr]
	movzx esi,word [esi+depot.XY]

	or esi,esi	// does the depot/airport actually exist?
	jnz short .gotthecity1
	inc esi			// clear ZF
	pop esi			// restored from stack: textrefstack+3
	mov word [esi-2],6	// empty string
	pop eax			// clear vehicle type from the stack
	ret

.gotthecity1:
	test byte [miscmodsflags+3],MISCMODS_NODEPOTNUMBERS>>24
	jnz .gotthecity
	mov WORD [edi-2], statictext(dpt_number)
	add edi, BYTE 2
	mov [edi+6], ax
	add DWORD [esp], 2
.gotthecity:
	mov ax,word [ebp+town.citynametype]
	stosw
	mov eax,dword [ebp+town.citynameparts]
	stosd
	pop esi		// restored from stack: textrefstack+3 (+2 if depot num)
	pop eax		// restored from stack: vehicle type
	add ax,ourtext(gototraindepot)-0x10
	mov [esi],ax

	// NOTE: our text indices are always nonzero, so the last ADD clears ZF
	ret

.special:
	movzx ebp, ah
	shr ebp, 4
	and ebp, BYTE 0xE
	add [esp+8], ebp

	and ah, 0x1F
	cmp ah, 2
	ja .specialfail
	testflags advorders
	jnc .specialfail
	cmp ah, 1
	ja .condloadskip
	movzx eax, ah
	add ax, ourtext(gotodepot)
	stosw
	movzx eax,byte [esi+veh.class]
	add eax,ourtext(gototraindepot)-0x10
	stosw
	mov WORD [edi], ourtext(advorder_findnearestdepottxt)
.specialfail:
	xor bp, bp
	test esp, esp
	ret
.condloadskip:
	mov ebp, [esp+8]
	movzx ebp, WORD [ebp]
	mov ax, ourtext(advorder_loadcondskiporderwintxt)
	stosw
	mov eax, ebp
	and eax, 0x7F
	mov WORD [edi+4], ax
	mov eax, ebp
	shr eax, 8
	and eax, 0x1F
	stosw
	mov eax, ebp
	shr eax, 13
	and eax, 0x7
	cmp al, 2
	jb .noteqorneq
	add eax, statictext(trdlg_lt)-2
	jmp .sclsprint
.noteqorneq:
	add eax, ourtext(trdlg_eq)
.sclsprint:
	stosw
	jmp .specialfail


; endp showorder 

// figure out whether a ship order has the right player and isn't too far
// in:	edi=vehicle
// out: cy or zf if not human, or human and not too far
//	nc and nz otherwise
global isshiporder
isshiporder:
	push edx
	mov dl,byte [edi+veh.owner]
	push byte PL_PLAYER
	mov [esp+1],dl
	call ishumanplayer
	je short .human

.done:
	stc
	pop edx
	ret

	// have to check that the station is not too far,
	// taking depots into account
.human:
	or bh,bh
	jz short .done

	pop edx

	movzx ebp,bh
	shl ebp,1
	add ebp,dword [edi+veh.scheduleptr]

	push eax
	mov eax,[ebp-2]
	and al,0x1f
	cmp al,1
	jb .done
	cmp al,2
	ja .done

	push eax
	mov byte [esp+3],0xe
	call getofsptr
	pop eax
	mov eax,[eax]

	push edx
	mov byte [esp+3],0xe
	call getofsptr
	pop ebp

	sub al,[ebp]
	jae short .notneg1
	neg al

.notneg1:
	sub ah,[ebp+1]
	jae short .notneg2
	neg ah

.notneg2:
	add al,ah
	setc ah
	cmp ax,0x82

	pop eax
	ret

; endp isshiporder 

// set order type.  For AI, set DL to 1, for humans leave it
// then store DX in [EBP]
global setordertype
setordertype:
	call isrealhumanplayer
	je short .ishuman
	mov dl,1
.ishuman:
	mov [ebp],dx
	ret
; endp setordertype 

// figure out target of a command
// in:	command on stack
//	high byte of dword is offset of facility is desired
// out:	ptr to target on stack
getofsptr:
	push eax
	mov eax,[esp+8]
	and al,0x1f
	cmp al,1
	je short .station
	jnb short .mightbedepot

.bad:
	and dword [esp+8],byte 0

.done:
	pop eax
	ret

.mightbedepot:
	cmp al,2
	jne .bad

	// depot
	movzx eax,ah
	imul eax,byte 6
	add eax,depotarray
	mov [esp+8],eax
	jmp .done

.station:
	movzx eax,ah
	imul eax,station_size
	add eax,stationarray
	xchg eax,[esp+8]
	sar eax,24
	add [esp+8],eax
	jmp .done
; endp getofsptr 

// called when a train arrives at a target and
// gets a new order ready
// in:	ax=new order
//	esi=vehicle
//	ebx=schedule ptr to new order
// out:	carry if depot
//	ax=bx=new target if depot
global newordertarget
newordertarget:
	mov word [esi+veh.target],-1
	and al,0x1f
	cmp al,2
	je short .todepot
	cmp al,5
	je NEAR .special
.notyet:
	clc
	ret

.todepot:
	// check whether we need maintenance...
	test byte [esi+veh.currorder],DEPOTIFSERVICE
	jz short .always
.maintcheck:
	push eax
	call needsmaintcheck.always
	pop eax
	jna short .always

.skiporder:
	// not yet, or target doesn't exist; advance order pointer
	call advanceorders
.skiporder2:
	mov word [esi+veh.currorder],0		// force to check commands again
	clc
	mov al,0
	ret

.always:
	movzx ebx,ah
	imul ebx,byte 6
	mov eax,[depotarray+ebx]
	or ax,ax
	jz short .skiporder

	mov ebx,eax
	mov byte [esi+veh.laststation],-1
	stc
	ret
.special:
	mov al, ah
	shr al, 5
	add [esi+veh.currorderidx], al		//correction for special orders >2 bytes
	and ah, 0x1F
	cmp ah, 2
	ja .skiporder
	testflags advorders
	jnc .skiporder
	cmp ah, 1
	ja NEAR .loadorderskip
	or ah, ah
	je .alwaysfinddepot
	call needsmaintcheck.always
	ja .skiporder
.alwaysfinddepot:
	pushad
	call [FindNearestTrainDepot]
	or ebx, ebx
	jz .failfinddepot
	cmp WORD [ebx], 0
	je .failfinddepot
	xor edx, edx
	mov eax, ebx
	sub eax, depotarray
	mov ecx, 6
	div ecx
	mov ah, al
	mov al, 0x22
	mov [esp+28], eax	//eax and ebx in pushad/popad stack
	mov [esp+16], ebx
	popad
				//eax=depot id in ah, 2 in al, ebx=depot struc
	mov word [esi+veh.currorder], ax
	mov bx, [ebx]		//depot xy
	mov ax, bx
	mov byte [esi+veh.laststation],-1
	stc
	ret
.failfinddepot:
	popad
	jmp .skiporder

.loadorderskip:
	pushad
	xor eax, eax
	xor ecx, ecx
	push esi
.loop:
	movzx edx, WORD [esi+veh.capacity]
	add ecx, edx
	movzx edx, WORD [esi+veh.currentload]
	add eax, edx
	movzx esi, WORD [esi+veh.nextunitidx]
	cmp si, -1
	je .endloop
	cvivp
	jmp .loop
.endloop:
	pop esi
	//ecx=total capacity
	//eax=current load
	lea eax, [eax+eax*4]
	lea eax, [eax+eax*4]
	shl eax, 2
	//eax=current load * 100
	xor edx, edx
	div ecx
	//eax=percentage load (rounded down to integer)
	movzx ecx, WORD [ebx+2]	//parameter
	mov edx, ecx
	shr edx, 13
	movzx ebx, ch
	and ecx, 0x7F
.eq:
	dec edx
	jns .neq
	cmp eax, ecx
	jne .skip
	je .multiskip
.neq:
	dec edx
	jns .l
	cmp eax, ecx
	je .skip
	jne .multiskip
.l:
	dec edx
	jns .g
	cmp eax, ecx
	jnb .skip
	jb .multiskip
.g:
	dec edx
	jns .le
	cmp eax, ecx
	jna .skip
	ja .multiskip
.le:
	dec edx
	jns .ge
	cmp eax, ecx
	jnbe .skip
	jbe .multiskip
.ge:
	dec edx
	jns .skip
	cmp eax, ecx
	jnae .skip
	jae .multiskip
	
.skip:
	popad
	jmp .skiporder
.multiskip:
	call advanceorders
	//orders now pointing at beginning of next
	and ebx, 0x1F
	mov ecx, ebx
	call multiadvanceorders
	popad
	jmp .skiporder2

; endp newordertarget

// called when a train arrives at a depot
// check whether it's a manual automatic or by order
// in:	on stack=vehicle
//	al=order type
//	ah=destination
// out:	zf if not manual
//	nz if manual
global arriveatdepot
arriveatdepot:
	push esi
	mov esi,[esp+8]
	test al,0x20
	jnz short .byorder
	test al,0x40
	jz short .done

	or word [esi+veh.vehstatus],byte 2
	jmp short .manual

.done:
	test al,0	// make sure zf is set (if coming from jnz below)
.manual:
	pop esi
	ret 4

.byorder:
	// is this the right depot?
	cmp byte [esi+veh.class],0x13
	je .airport

	movzx eax,ah
	imul eax,byte depot_size
	mov ax,[depotarray+eax+depot.XY]
	sub ax,[esi+veh.XY]
	jnz .done
	jmp short .goodloc

.airport:
	cmp ah,[esi+veh.targetairport]
	jne .done

.goodloc:
	testmultiflags losttrains,lostrvs,lostships,lostaircraft
	jz .noreset
	and word [esi+veh.traveltime],0
.noreset:
	call advanceorders
	xor al,al	// clear zero
	jmp .done
; endp arriveatdepot

//ecx=count, esi=veh
multiadvanceorders:
	or ecx, ecx
	jz .end
	pushad
.start:
	movzx eax, BYTE [esi+veh.currorderidx]
	mov edi, [esi+veh.scheduleptr]
	movzx edx, BYTE [esi+veh.totalorders]
.loop:
	movzx ebx, WORD [edi+eax*2]
	and bl, 0x1F
	cmp bl, 5
	jne .nombchk
	shr ebx, 13
	add eax, ebx
.nombchk:
	inc eax
	cmp eax, edx
	jb .good
	xor eax, eax
.good:
	loop .loop
	mov [esi+veh.currorderidx], al
	popad
.end:
	ret

	// advance order pointer
advanceorders:
	pusha
	xor ecx,ecx
	inc ecx
	jmp short multiadvanceorders.start

; endp advanceorders 

// called when the skip button is pressed
// make sure the vehicle doesn't insist on
// going to the same depot
// in:	dl=new command (check if <=totalcommands)
//	edi=vehicle
// out:	dl=new command
global skipbutton
skipbutton:
	mov esi, edi
	extcall removeconsistfromqueue // No-op if consist is not queued or if fifo is off.
	cmp dl,byte [edi+veh.totalorders]
	jb short .nottoolarge
	mov dl,0

.nottoolarge:
	mov bl,[edi+veh.currorder]		// are we going to a depot?
	and bl,0x1f
	testflags gradualloading
	jnc .nogradload
	cmp bl,3
	jne .nogradload
	and byte [edi+veh.modflags], ~(1 << MOD_NOTDONEYET)	// forced abortion of gradual loading
.nogradload:
	cmp bl,2
	jne .notdepot
	mov word [edi+veh.currorder],0		// force to check commands again
.notdepot:
	ret
; endp skipbutton 

// called when an order is selected in the order list
// don't disable "full load" for depots -- we use it for "only if service"
// also enable "Delete" for the "End of orders" entry (or if nothing is selected - we can't tell at this point)
// in:	[ebx]=new order type
// out:	zf if regular order, ie. don't reset any buttons
//	nz otherwise
//	eax=8 for non-depot orders
//	eax=9 for depot orders
//	where eax=bit number of button to disable, as well as 9 and 6 (non-stop and unload)
//
//	[esi+31h] controls tooltips and dropdown behaviour:
//	0 - station order, 1 - depot order, 2 - End-of-orders (or nothing selected)
//	3 - conditional skip
global selectorder
selectorder:
	bt DWORD [esi+window.activebuttons], 8
	jnc .noremparamspecddl
	cmp BYTE [esi+0x31], 3
	je .noremparamspecddl
	pusha
	mov ecx, 8
	call GenerateDropDownExPrepare
	popa
.noremparamspecddl:
	mov dword [textrefstack+4], 0x88278824
	mov byte [esi+0x31],0
	movzx eax,byte [ebx]
	and al,0x1f
	cmp al,1
	je short .ok
	cmp al, 5
	je .special

	testmultiflags sharedorders
	jz .notend
	cmp word [ebx],0	// is it the terminating zero in the order list?
	jne .notend
	and byte [esi+window.disabledbuttons],~0x20	// Enable Delete button
	mov word [textrefstack+4], ourtext(resetorders)
	mov byte [esi+0x31],2

.notend:
	cmp al,2
	jne short .ok

	add al,7	// set to 9, and clear zero flag
	mov word [textrefstack+6], ourtext(toggleservice)
	mov byte [esi+0x31],1
	ret

.ok:
	mov al,8
	ret
	
.special:
	mov al, [ebx+1]
	and al, 1Fh
	cmp al, 2
	jne .ok
	mov word [textrefstack+6], ourtext(advorder_ordercondskiploadparamddltxt)
	mov byte [esi+0x31],3
	mov al, 9
	or esp, esp
	ret
; endp selectorder

// called when any of the order buttons is pressed (full load, unload, nonstop)
// allow "full load" for depot orders too
// in:	dh=order type
//	dl=button type (0 for full load)
//	edi=veh ptr
// out:	zf if it's ok
//	nz if it's not possible to set the option
//	dh="and" mask: not 20h if full load, ff if depot
global fullloadbutton
fullloadbutton:
	and dh,0x1f
	cmp dh,1
	je short .regular

	cmp dh,2
	jne short .notok

	or dl,dl
	jnz short .notok

	mov dh,0xff	// otherwise don't clear any bits

.notok:
	ret

.regular:
	mov dh,~ 0x20	// for regular full load, clear "unload" bit
	ret
; endp fullloadbutton 


// called when an aircraft leaves a hangar
// in:	esi=vehicle
// out:	ah=[vehicle+b]
//	al=[vehicle+a]&1fh
//	carry flag if it's a depot not on the order list
//	al=1 if it's a depot on the order list
global leavehangar
leavehangar:
	mov ax,word [esi+veh.currorder]
	and al,0x1f
	cmp al,1
	jne short .notregularstation

	ret

.notregularstation:
	cmp al,2
	je short .depot

	clc
	ret

.depot:
	test byte [esi+veh.currorder],0x20
	jnz short .onlist

	stc
	ret

.onlist:
	mov al,1
	ret
; endp leavehangar 


// called before checking if an aircraft has a new order ready,
// to exclude service orders
// in:	ESI->vehicle
// out:	AL=current order & 1fh, check will be skipped if AL>=2
// safe:EBX
global isgoingtohangar
isgoingtohangar:
	mov ax,word [esi+veh.currorder]	// overwritten by...
	and al,0x1f			// ... the runindex call
	cmp al,2
	jne short .continue

	test byte [esi+veh.currorder],0x20	// scheduled?
	jz short .continue
	mov al,1		// con TTD's routine into thinking it's a regular order

	// Note: after the CMP AL,2 (see codefragment oldisgoingtohangar),
	// the value in AL is not used again

.continue:
	ret
; endp isgoingtohangar 


// called when an aircraft gets a new order ready
// in:	esi=vehicle
//	ax=new order
//	ebx->new order
// out:	word[esi+0ah]=new order
//	ZF=1:if in flight, set new flight target to AH
// safe:al,ebx
global newaircrafttarget
newaircrafttarget:
	mov bx,ax
	and al,0x1f
	cmp al,2
	jne short .isstation

	test bl,DEPOTIFSERVICE
	jz short .isOK

	call needsmaintcheck.always	// ** destroys AH, but saves EBX
	mov al,1			// make sure we leave with ZF set
	jna short .restoretarget

	call advanceorders
	xor bx,bx		// force to check commands again
	mov al,0		// and never set the flight target

.restoretarget:
	mov ah,bh
.isstation:
	cmp al,1
.isOK:
	mov word [esi+veh.currorder],bx
	ret
; endp newaircrafttarget 


// called when an aircraft decides whether to taxi or fly to the next
// destination
// in:	ESI=vehicle, AL=byte[ESI+0Ah]&1Fh, AH=DL=byte[ESI+66h], EBX=station
//	(note: AL<3 and AL<>0 here)
// out:	AH+=9, AL=7, ZF=1 if target is at a different airport
global nextplaneorder
nextplaneorder:
	add ah,9

	mov al,byte [esi+veh.currorder+1]
	xor al,byte [esi+veh.targetairport]
	// now AL=0 if the same airport, nonzero otherwise;  reverse the test
	sub al,1
	sbb al,al

	mov al,7
	ret
; endp nextplaneorder 


// if heading for depot, don't mess with the 'out' way status
// in:	same as nextplaneorder
// out:	ZF=0 if the aircraft will use the 'out' way
// safe:CX
global nextplaneorder0
nextplaneorder0:
	cmp byte [esi+veh.subclass],0	// overwritten
	jz .done

	mov cl,byte [esi+veh.currorder+1]
	cmp cl,byte [esi+veh.targetairport]

.done:
	ret
; endp nextplaneorder0


// called when a station is deleted,
// to invalidate the associated orders in vehicles' schedules
// in:	DX=current order
//	EBP->next order
//	EDI->current vehicle
//	AL=number of station being deleted
// out:	ZF set if it's a station order, clear otherwise
// safe:AH,BX,DL
global isdelstationorder
isdelstationorder:
	and dl,0x1f		// overwritten by...
	cmp dl,1		// ... the runindex call
	je short .done

	cmp dl,2
	jne short .done

	cmp byte [edi+veh.class],0x13

.done:
	ret
; endp isdelstationorder 


// called when a depot is being removed, to find that depot in the depot array
// in:	ESI = depotofs-6
//	DI = coord of depot being removed
//	stack: depot vehicle type minus 1 (see codefragment newremovedepotfromarray and init.ah)
// out: ESI -> this depot in the array
// safe:none
global removedepotfromarray
removedepotfromarray:
	push ecx
	mov ch,[esp+8]
	mov cl,-1
.loop:
	inc ecx			// note: will increment CH the first time
	add esi,byte 6		// these 3 instructions...
	cmp di,[esi]		// ... are overwritten by...
	jnz short .loop		// ... the new codefragment

	pusha
	mov esi,[veharrayptr]

.vehloop:
	cmp byte [esi+veh.class],ch
	jne short .nextvehicle

	call resetvehorderifdepot
	mov bx,word [esi+veh.idx]
	mov al,0x10
	call dword [invalidatehandle]

.nextvehicle:
	sub esi,byte -vehiclesize
	cmp esi,[veharrayendptr]
	jb short .vehloop

	call isrealhumanplayer
	popa
	jnz short .done

	call invalidatelastremoveddepot
	mov [landscape3+ttdpatchdata.lastremoveddepotnumber],cx
	mov [landscape3+ttdpatchdata.lastremoveddepotcoord],di
.done:
	pop ecx
	ret 4
; endp removedepotfromarray 


// Auxiliary procedure: force vehicle to re-check its orders if it's heading for the removed depot
// in:	esi->vehicle; cl=depot number
// uses:eax
resetvehorderifdepot:
	// check vehicle's current order
	mov eax,dword [esi+veh.currorder]
	and al,0x1f
	cmp al,2
	jne short .done
	cmp ah,cl
	jne short .done

	// current order no longer valid, force re-check
	mov word [esi+veh.currorder],0

.done:
	ret
; endp resetvehorderifdepot 


// lastremoveddepot* no longer valid, clear all vehicle orders that refer to it
invalidatelastremoveddepot:
	pusha
	xor ecx,ecx
	xchg ecx,[landscape3+ttdpatchdata.lastremoveddepotnumber]	// number in CL, type in CH
	or ch,ch
	jz short .done

	mov esi,[veharrayptr]

	// check all vehicles
.vehloop:
	cmp [esi+veh.class],ch
	jne short .nextvehicle
	mov edx,dword [esi+veh.scheduleptr]
	cmp edx,byte -1
	je short .checkcurrent

	// check vehicle's schedule
.nextorder:
	mov eax,[edx]
	or ax,ax
	jz short .checkcurrent
	inc edx
	inc edx
	and al,0x1f
	cmp al,2
	jne short .nextorder
	cmp ah,cl
	jne short .nextorder

	mov word [edx-2],0x100	// turn into an empty order
	mov bx,word [esi+veh.idx]
	mov al,0x10
	call dword [invalidatehandle]
	jmp short .nextorder

.checkcurrent:
	call resetvehorderifdepot

.nextvehicle:
	sub esi,byte -vehiclesize
	cmp esi,[veharrayendptr]
	jb short .vehloop

.done:
	popa
	ret
; endp invalidatelastremoveddepot


uvarb newlyplaceddepottype

// mark type of depot a player tries to place
// also adjust cost if on a slope (see slopebld.asm)
// in:	stack: depot vehicle type
//	EBP = cost
// safe:ESI?
global marknewdepottype
marknewdepottype:
	push eax
	mov al,[esp+8]
	mov byte [newlyplaceddepottype],al

	cmp al,0x12
	jae .adjusted
	cmp ebp,0x80000000		// don't adjust the cost if action not possible
	jz .adjusted
	cmp byte [depotbuildslopemap],0
	jz .adjusted
	add ebp,[raiselowercost]

.adjusted:
	mov bx,[esp+12]			// simulated POP BX
	cmp ebp,0x80000000		// overwritten by runindex call
	pop eax
	ret 6
; endp marknewdepottype 


// find either the last removed depot or an unused slot
// in:	ESI -> depot array
//	CX:word[esp+4] = coords
//	BL&1 zero if just checking, nonzero otherwise
// out:	ZF=1 if found
//	ESI -> slot if ZF=1
// safe:(E)AX
global findnewdepotsslot
findnewdepotsslot:
	mov ah,[landscape3+ttdpatchdata.lastremoveddepotnumber]
	call isrealhumanplayer
	jnz short .newdepot

	mov al,byte [newlyplaceddepottype]
	cmp al,[landscape3+ttdpatchdata.lastremoveddepottype]
	jne short .newhumandepot

	mov ax,[esp+4]
	push edx

	// convert coordinates in CX:AX to one byte in DX
	shrd edx,ecx,24
	or dx,ax
	shr edx,4

	// check if the new depot is within 5 squares of the last removed one
	mov ax,[landscape3+ttdpatchdata.lastremoveddepotcoord]
	sub al,dl
	jnc short .lpos
	neg al
.lpos:
	sub ah,dh
	jnc short .hpos
	neg ah
.hpos:
	pop edx
	add al,ah
	jc short .newhumandepot
	cmp al,5
	ja short .newhumandepot

	// OK, the depot is being placed back

	movzx eax,byte [landscape3+ttdpatchdata.lastremoveddepotnumber]
	imul eax,byte 6
	cmp word [esi+eax],byte 0	// safety check -- is the slot still empty?
	jnz short .newhumandepot

	add esi,eax
	test bl,1
	jz short .done

	// Notify all vehicles that use this depot

	call refreshdepotschedules

	// done, mark last removed depot info as invalid and return

	mov byte [landscape3+ttdpatchdata.lastremoveddepottype],0	// depot is restored
	jmp short .checkslot		// will immediately set ZF and abort

	// Depot is not a replacement

.newhumandepot:
	mov ah,-1			// ignore the last removed depot, we're going to invalidate it anyway
	test bl,1
	jz short .newdepot
	call invalidatelastremoveddepot

.newdepot:
	// search for an unused slot -- replicate the overwritten TTD code
	// but in a slightly different way, with AL as a counter
	// also skip the last removed depot (in AH) so that AI doesn't build over it
	mov al,1
	inc ah

.depotloop:
	cmp al,ah
	je short .nextdepot
.checkslot:
	cmp word [esi+depot.XY],byte 0
	jz short .done
.nextdepot:
	add esi,byte 6
	add al,1
	jnc short .depotloop
	or al,1			// guaranteed to clear ZF
.done:
	ret
; endp findnewdepotsslot 


// notify all vehicles that use the replaced depot in their schedules
refreshdepotschedules:
	pusha
	mov ecx,[landscape3+ttdpatchdata.lastremoveddepotnumber]	// number in CL, type in CH
	mov esi,[veharrayptr]

.vehloop:
	cmp byte [esi+veh.class],ch
	jne short .nextvehicle
	mov edi,dword [esi+veh.scheduleptr]
	cmp edi,byte -1
	je short .nextvehicle

	// check vehicle's schedule
.nextorder:
	mov eax,[edi]
	or ax,ax
	jz short .nextvehicle
	inc edi
	inc edi
	and al,0x1f
	cmp al,2
	jne short .nextorder
	cmp ah,cl
	jne short .nextorder

	mov bx,word [esi+veh.idx]
	mov al,0x10
	call dword [invalidatehandle]
	jmp short .nextorder

.nextvehicle:
	sub esi,byte -vehiclesize
	cmp esi,[veharrayendptr]
	jb short .vehloop

	popa
	ret
; endp refreshdepotschedules 


// called when an order is copied from a sold vehicle to a recently bought one
// the order might be a special one indicating shared orders (see format at savevehorders)
// in:	dx, ax = order
// out:	dx=order to set
//	al=special bits to set (e.g. 40=full load)
//	zero flag if order is ok to add
//	nz if not
global copyoldorder
copyoldorder:
	testmultiflags sharedorders
	jz .nosharedcheck
	cmp dx,-1	// is it a special command?
	je .dosharedorders

.nosharedcheck:
	and dl,0x1f
	cmp dl,1
	je short .done

	testflags gotodepot
	jc .mightbedepot
	cmp dl,1
	ret

.mightbedepot:
	cmp dl,2
	je short .isdepot
.done:
	ret

.isdepot:
	mov dl,DEPOTORDER
	and al,~ DEPOTORDER
	test al,0	// set zero flag
	ret

.dosharedorders:
	add edi,2	// skip two bytes - this order is two bytes longer than other commands
	pusha
	movzx edi,word [edi]	// find the source vehicle
	shl edi,vehicleshift
	add edi,[veharrayptr]
	cmp byte [edi+veh.class],0	// is it still valid?
	je .exit
	
	mov edx,esi
	xor eax,eax
	xor ecx,ecx
	xor ebx,ebx
	inc bl
	sub edx,[veharrayptr]
	sub edi,[veharrayptr]
	dopatchaction shareorders
	call redrawscreen

.exit:
	popa
	or dl,dl
	ret
	
; endp copyoldorder 

// called when clicking on the depot button if the target is already a depot
// if currorder is set to 0x100, it will be changed to the current entry in the orders list
// in: esi -> vehicle
// out: currorder updated
// safe:???
global canceldepot
canceldepot:
	test byte [esi+veh.currorder],0x20	// is currorder a "go to depot" order?
	jz .nodepotorder
	push eax	// yes, skip it to allow manual sending with the next click
	mov al,[esi+veh.currorderidx]
	inc al
	cmp al,[esi+veh.totalorders]
	jb .nowrap
	xor al,al
.nowrap:
	mov [esi+veh.currorderidx],al
	pop eax

.nodepotorder:
	mov word [esi+veh.currorder],0x100	// overridden by the call
	ret

// Delete the schedule of the vehicle
// The new version checks for shared schedules
global delvehicleschedule
delvehicleschedule:
	mov ebp,[edx+veh.scheduleptr]	// overwritten
	call isscheduleshared
	jc .abort
	movzx esi,byte [edx+veh.totalorders]	// overwritten
	ret

.abort:
	pop ebx	// remove our return address (ebx would have been overwritten anyway)
	ret	// return to the caller's caller

// selects text to show in orders window
// in:	ax: order entry
//	edi -> vehicle
// out:	zf clear to show default text
//	zf set to show our text
//	bx: text ID if using own text
// safe: ebp,esi,edi,???
global showendoforders
showendoforders:
	or ax,ax
	jnz .exit
	mov bx,0x882a	// - - End of orders - -
	mov ebp,[edi+veh.scheduleptr]
	call isscheduleshared
	jnc .exit
	mov bx,[numvehshared]
	mov [textrefstack+2],bx
	mov bx,ourtext(endofsharedorders)
	cmp al,al
.exit:
	ret

// called in the schedule-adjusting loop when an order is inserted or deleted
// we notify the other vehicles that use the same schedule about the change
// in:	edi -> vehicle whose orders are being changed
//	esi -> vehicle entry to adjust if needed
//	ebp -> order being inserted/deleted
// out: nz if veh. entry is valid (valid class and scheduleptr)
// safe: ax,cx,edx

global adjustorders
adjustorders:
	cmp byte [esi+veh.class],0	//overwritten by the
	je .exit
	cmp dword [esi+veh.scheduleptr],byte -1	// runindex call
	je .exit
	cmp esi,edi	// the source vehicle will be notified later
	je .exit
	mov edx,[edi+veh.scheduleptr]
	cmp edx,[esi+veh.scheduleptr]
	je .shared
	test ebp,ebp	// clear zf
.exit:
	ret

.shared:
	mov al,[edi+veh.totalorders]	// adjust totalorders
	cmp al,[esi+veh.totalorders]
	mov [esi+veh.totalorders],al
	ja .nodequeue			// we're adding orders, not deleting them.
	sub edx,ebp
	shr edx,1
	// dl is now the arithmetic inverse of [ebp]'s order index
	add dl,[esi+veh.currorderidx]
	jnz .nodequeue
	extcall removeconsistfromqueue
.nodequeue:
	pop edx				// get our return address
	push edx
	pusha
// Here comes a nasty, but small solution: we call the remainder of the parent function from here,
// instead of reproducing its behaviour for other vehicles.
// The problem is, that it pops 4 bytes from the stack before returning, so it would pop
// the return address and return to the wrong place. Because of this, we put an extra return address
// to the stack, so the function will pop the return address placed by the call and return to the
// second, manually placed return address.
	mov edi,esi	// make the function believe that the current vehicle was the modified one
	add edx,0x1c
	push addr(.return)
	call edx
.return:
	popa
	ret	// zf doesn't matter - this vehicle won't be adjusted anyway (scheduleptr<=ebp)

// Called when Delete is pressed in the orders window
// Make deleting the end marker possible, doing this will reset orders
// (This will work if nothing is selected as well)
// in:	edi -> vehicle (after the first overwritten instruction)
//	al: order number
// out: cf set if order number is ok
// safe: eax,ecx,bl
global deletepressed
deletepressed:
	add edi,[veharrayptr]		// overwritten
	cmp al,[edi+veh.totalorders]	// normal orders may require some extra bookkeeping.
	jne .fifo
	or byte [esi+window.activebuttons],0x20		// make "Delete" pushed
	or byte [esi+window.flags],5		// but make it release after the click
	cmp dword [scheduleheapfree],scheduleheapend-2	// don't do it if there's not enough heap
	ja .deny					// for the new terminator order

	pusha
	xor eax,eax		// no position can be assigned to this action
	xor ecx,ecx
	xor ebx,ebx		// actually do it, not just test
	inc bl
	mov dl,1		// allow Ctrl to unshare
	sub edi,[veharrayptr]
	dopatchaction resetorders // call our "reset orders" action
	popa

.deny:
	clc
	ret

.fifo:
	// dequeue/unreserve if current order was deleted
	cmp al,[edi+veh.currorderidx]
	jne .advanced
	xchg esi, edi
	call removeconsistfromqueue
	xchg esi, edi

.advanced:
	// properly delete multi-entry orders
	mov ecx, [edi+veh.scheduleptr]
	movzx eax, al
	movzx ecx, word [ecx+eax*2]
	cmp cl, 5
	jne .done
	shr ecx, 5+8
	jz .done
.adv_moredelete:		// Multi-entry order
	pusha
	stc
	call [esp+20h]		// Delete first (remaining) part of the order
	popa
	loop .adv_moredelete
	// Now delete the final part of the order

.done:
	stc
	ret

uvarb skipsharingcheck	// if nonzero, shared orders are saved like non-shared ones (new veh. won't be shared)

// Reset orders of a vehicle (clear it, but don't hurt others sharing the schedule)
// edi: offset to vehicle
global resetorders
resetorders:
	test bl,1
	jz NEAR .justtest
	pusha
	add edi,[veharrayptr]
	test dl,[curplayerctrlkey]
	jz .notunshare

	// ctrl-reset just unshares, i.e. removes shared orders, then re-adds them unshared
	pusha
	call makeordercopy
	popa
	
	jmp short .nodequeue

.notunshare:
	mov esi, edi
	call removeconsistfromqueue

.nodequeue:
	mov edx,edi
	call dword [delvehschedule]	// delete old orders (the function handles shared orders properly)
	mov ebx,[scheduleheapfree]	// create the terminator order
	and word [ebx],0
	mov [edi+veh.scheduleptr],ebx	// and assign it to the vehicle
	add dword [scheduleheapfree],2
	mov byte [edi+veh.totalorders],0	// set vehicle fields accordingly
	mov byte [edi+veh.currorderidx],0
	mov word [edi+veh.currorder],0x100
	mov al,0x40+0x10
	call dword [invalidatehandle]	// order windows might have changed ("End of shared orders" -> "End of orders")
	popa
	test dl,[curplayerctrlkey]
	jz .exit

	// ctrl-reset just unshares, i.e. removes shared orders, then re-adds them unshared
	pusha
	add edi,[veharrayptr]
	call restoreordercopy
	call removeordercopy
	popa
.exit:
	xor ebx,ebx
	ret

// instead of checking cost, decide if we have enough shedule space to actually do it
.justtest:
	cmp dword [scheduleheapfree],scheduleheapend-2	// we need at least two bytes for a terminator
	jbe .exit
	mov word [operrormsg2],0x8831	// No more space for orders
	mov ebx,0x80000000
	ret

// patch action for schedule data (multiplayer-safe)
//
// in:	bl=1 to do action, 0 to check cost
//	bh=function,
//		0=restore orders and other vehicle info[*]
//		1=save orders and other vehicle info
//		2=clear other vehicle info
//		[*] cargo type, refit cycle, service interval etc. that
//		    should be kept between selling and buying a vehicle
// out:	ebx=cost
global saverestorevehdata
saverestorevehdata:
	test bl,bl
	jnz .forreal

	xor ebx,ebx	// this action costs nothing
	ret

.forreal:
	mov esi,edx
	add esi,[veharrayptr]

	mov dl,bh
	shr ebx,16
	test dl,dl
	jz dosavevehorders

	cmp dl,2
	je .clearadditionalsavedinfo
	ja .removeordercopy
	jmp dorestorevehorders

.clearadditionalsavedinfo:
	mov al,0
	mov [savedvehclass],al
	mov [savedorderindex],al
	ret

.removeordercopy:
	and word [soldvehorderbuff],0		// prevent newly bought vehicles getting this schedule
	ret


global savevehorders
savevehorders:
	pusha
	mov bh,0
	jmp short restorevehorders.callaction

clearadditionalsavedinfo:
	pusha
	mov bh,2
	jmp short restorevehorders.callaction

removeordercopy:
	pusha
	mov bh,3
	jmp short restorevehorders.callaction

global restorevehorders
restorevehorders:
	pusha
	shl ebx,16
	mov bh,1

.callaction:
	mov bl,1
	mov eax,[esi+veh.XY]
	movzx ecx,ah
	movzx eax,al
	shl eax,4
	shl ecx,4

	mov edx,esi
	sub edx,[veharrayptr]
	dopatchaction saverestorevehdata
	mov [esp+0x1c],eax
	popa
	test ax,ax
	ret

// saves the orders of a vehicle to a buffer
// for shared orders, it saves a special sequence (-1, other veh. number, 0) that can be recognized
// by the restore procedure
// (now wrapped in an action handler for multiplayer compatibility)
// in:	esi -> vehicle
//	edi -> buffer
// safe: ebp,eax
dosavevehorders:
	mov ebp,[esi+veh.scheduleptr]	// overwritten
	cmp byte [skipsharingcheck],0
	jne .normal
	mov eax,[veharrayptr]

.checkveh:
	cmp byte [eax+veh.class],0	// is it valid?
	jz .nextveh
	cmp ebp,[eax+veh.scheduleptr]	// does it share its orders with our vehicle?
	jnz .nextveh
	cmp esi,eax			// don't check itself
	je .nextveh

	mov word [edi],-1	// found another vehicle sharing this schedule - save a -1 prefix and its number...
	mov ax,[eax+veh.idx]
	mov [edi+2],ax
	and word [edi+4],0	// ... and a terminator
	jmp short .copyvehname

.nextveh:
	sub eax,byte -vehiclesize
	cmp eax,[veharrayendptr]
	jb .checkveh

.normal:
	mov ax,[ebp]	// here comes the old code - the runindex call didn't fit outside the loop,
	cmp ax,0x100	// so I used a jump instead and copied the remaining code here
	je .dontsave
	mov [edi],ax
	add edi,2

.dontsave:
	add ebp,2
	or ax,ax
	jnz .normal

.copyvehname:
	// copy the service interval, cargotype, and current destination index
	mov ax,[esi+veh.serviceinterval]
	mov [savedserviceinterval],ax

	mov al,[esi+veh.cargotype]
	mov ah,[esi+veh.refitcycle]
	mov [savedcargoinfo],ax

	mov al,[esi+veh.currorderidx]
	mov [savedorderindex],al

	mov al,[esi+veh.class]
	mov [savedvehclass],al

	// copy the custom name, if any
	mov edi,savedvehname
	mov byte [edi],0

	mov al,[esi+veh.name+1]
	and al,-8
	cmp al,0x78
	jne .notcustom

	imul esi,[esi+veh.name],32
	and esi,0x1ff*32
	add esi,customstringarray

	mov ecx,32
	rep movsb

.notcustom:
	ret

uvarb savedvehclass
uvarb savedvehname,32
uvarw savedcargoinfo
uvarw savedserviceinterval
uvarb savedorderindex

// called when restoring vehicle orders after buying a new vehicle
// (this is called again for each entry)
// (now wrapped in an action handler for multiplayer compatibility)
//
// in:	 bh=current order number
//	esi->new vehicle
//	edi->buffer to read copied orders from
// out:
// safe:
dorestorevehorders:
	// not the first order, see if we have enough to set the destination index
	mov al,[savedorderindex]
	cmp bh,al
	jne .notenough

	mov [esi+veh.currorderidx],al

.notenough:
	test bh,bh
	jz .restore

.done:
	mov ax,[edi]	// overwritten
	ret

.restore:
	mov al,0
	xchg al,[savedvehclass]
	cmp al,[esi+veh.class]
	jne .done

	// first set service interval and cargo type again
	mov ax,[savedserviceinterval]
	mov [esi+veh.serviceinterval],ax

	mov ax,[savedcargoinfo]
	cmp al,[esi+veh.cargotype]
	je near .nocapaadjust

	// refittable to this cargo?
	movzx ecx,al
	mov cl,[cargotypes+ecx]

	mov dl,[esi+veh.class]
	shl edx,16
	mov dl,[esi+veh.vehtype]
	push edx
	call getrefitmask
	pop edx
	bt edx,ecx
	jnc near .nocapaadjust

	mov [esi+veh.cargotype],al
	mov [esi+veh.refitcycle],ah
	mov bh,al

	// adjust capacity if necessary

	movzx eax,byte [esi+veh.vehtype]
	test byte [callbackflags+eax],8
	jz .nocapacallback

	mov al,0x15
	call vehcallback
	jc .nocapacallback

	mov [esi+veh.capacity],ax

	// remove mail capacity for non-passenger planes
	cmp byte [esi+veh.class],0x13
	jne .nocapaadjust
	cmp byte [esi+veh.cargotype],0
	je .nocapaadjust
	movzx eax,word [esi+veh.nextunitidx]
	shl eax,7
	add eax,[veharrayptr]
	mov word [eax+veh.capacity],0
	jmp short .nocapaadjust

.nocapacallback:
	cmp byte [esi+veh.class],0x10
	je .needsadjust		// trains need adjustment
	jnp .nocapaadjust	// rvs and ships need no adjustment

	// planes need to add mail capacity unless it's carrying passengers+mail
	test bh,bh
	jz .needsadjust

	// one cargo type only
	movzx eax,byte [esi+veh.vehtype]
	movzx eax,byte [planemailcap+eax-AIRCRAFTBASE]
	add eax,eax			// 1 mail = 2 pass
	add [esi+veh.capacity],ax
	movzx eax,word [esi+veh.nextunitidx]
	cmp ax,byte -1
	je .needsadjust 	// no mail compartment??
	shl eax,7
	add eax,[veharrayptr]
	and word [eax+veh.capacity],0

.needsadjust:
	push ebx
	mov ebx,currefitlist
	mov al,[esi+veh.cargotype]
	mov [ebx+refitinfo.ctype],al

	movzx eax,word [esi+veh.capacity]
	push eax
	call adjustcapacity
	pop eax
	mov [esi+veh.capacity],ax
	pop ebx

.nocapaadjust:
	pusha
	// now restore the vehicle name (if any)
	mov edi,savedvehname	// new name
	cmp byte [edi],0
	je .failed		// no saved name

	mov ebp,[ophandler+0xE*8]	// opClassE
	xor ebx,ebx		// new custom name
	mov cl,2		// skips 2 bytes on textrefstack
	push esi
	call [ebp+4]		// ClassEfunctionhandler
	pop esi
	test ax,ax
	jz .failed
	mov [esi+veh.name],ax

.failed:
	popa
	jmp .done

// Called when selecting text ID of the hint to show in the orders window
// In:	cx: index of GUI element clicked on
// Out:	ax: text ID to show
// Safe: ebx, ???
global showorderhint
showorderhint:
	mov al,[esi+0x31]
	cmp cx,5
	jne .noreset
	cmp al,2
	jne .noreset
	mov ax,ourtext(resethint)
	ret

.noreset:
	cmp cx,8
	jne .noservice
	cmp al,1
	jne .tryparams
	mov ax,ourtext(servicehint)
	ret

.tryparams:
	cmp al,3
	jne .noservice
	mov ax, ourtext(advorder_orderparamtooltip)
	ret

.noservice:
	push ecx
	movzx ecx,cx
	mov ebx,[orderhints]
	mov ax,[ebx+ecx*2]
	pop ecx
	ret

uvarb savedinsertvehorderpos
uvard curvehorderselitemorderidxvehptr

//esi=veh, dx=order, al=pos
insertvehorderhere_gotveh:
	pusha
	mov ebx, esi
	call VehOrders@@SelItemToOrderIdx.in
	mov ebx, esi
	jmp insertvehorderhere.in
//esi=window, dx=order
insertvehorderhere:
	pusha
	call VehOrders@@SelItemToOrderIdx
	mov esi, [curvehorderselitemorderidxvehptr]
.in:
	mov [savedinsertvehorderpos], al
	mov bh, al
	mov bl, 1
	mov ax, [esi+veh.xpos]
	mov cx, [esi+veh.ypos]
	mov di, [esi+veh.idx]
	mov WORD [operrormsg1], 0x8833
	mov esi, 0x50080
	call [actionhandler]
	cmp ebx, 0x80000000
	je .ret
	cmp BYTE [esi+0x22], -1
	je .ret
	inc BYTE [esi+0x22]
.ret:
	popa
ret

//  In: esi->order window
// Out: ax: real order index
//	ebx->selected order
exported VehOrders@@SelItemToOrderIdx
	mov     al, [esi+window.selecteditem]
	movzx   ebx, WORD [esi+window.id]
	shl     ebx, 7
	add     ebx, [veharrayptr]
	mov [curvehorderselitemorderidxvehptr], ebx
.in:
	push edx
	mov     ebx, [ebx+veh.scheduleptr]
	or      al, al
	jz      short locret_1635DA
	mov     ah, al
	xor     al, al
loc_1635CA:                                     ; CODE XREF: VehOrders@@SelItemToOrderIdx+29j
	mov dx, [ebx]
	or dx, dx
	jz      short locret_1635DA
	add     ebx, 2                   ; !Note: potentially dangerous code
	inc     al

	and dl, 0x1F
	cmp dl, 5
	jne .notest
	shr dh, 5
	movzx edx, dh
	add ebx, edx
	add ebx, edx
	add al, dl
.notest:

	dec     ah
	jnz     short loc_1635CA
locret_1635DA:
	pop edx
ret


uvarb advorderskipcondloadtxtinputwintmpidval
extern GenerateDropDownExPrepare,DropDownExList,GenerateDropDownEx,WindowClicked,RefreshWindows

exported vehorderwinhandlerhook
	pushad
	mov esi, edi
	mov bx, cx
	cmp dl, cWinEventTextUpdate
	jz NEAR .textwindowchangehandler
	cmp dl, cWinEventClick
	jne NEAR .notclick
	call dword [WindowClicked]
	js NEAR .end
	cmp byte [rmbclicked],0 // Was it the right mouse button
	jne NEAR .end
	cmp cl, 8
	je NEAR .fullloadparams
	cmp cl, 7
	jne NEAR .end
	bt DWORD [esi+window.activebuttons], 7
	jc .buttonalreadydown
	push byte CTRL_ANY + CTRL_MP
	call ctrlkeystate
	je .doddl
	jmp .end
.buttonalreadydown:
	btr DWORD [esi+window.activebuttons], 31
	jnc NEAR .end
.doddl:
	mov ecx, 7
	call GenerateDropDownExPrepare
	jc NEAR vehorderwinhandlerhook_cancel
	bts DWORD [esi+window.activebuttons], 31
	mov DWORD [DropDownExList], ourtext(advorder_gotonearestdepotddltxt)
	mov DWORD [DropDownExList+4], ourtext(advorder_servicenearestdepotddltxt)
	mov DWORD [DropDownExList+8], ourtext(advorder_loadcondskipddltxt)
	mov DWORD [DropDownExList+12], -1
	mov ecx, 7
	or edx, BYTE -1
	call GenerateDropDownEx
	jmp vehorderwinhandlerhook_cancel
.notclick:
	cmp dl, cWinEventDropDownItemSelect
	jne NEAR .notddlsel
	cmp cl, 8
	je NEAR .specparamddlitemsel
	cmp cl, 7
	jne NEAR vehorderwinhandlerhook_cancel
	cmp al, 2
	je .dbl
	mov dh, al
	mov dl, 5
	call insertvehorderhere
	jmp vehorderwinhandlerhook_cancel
.dbl:
	mov edi, esi
	movzx esi, WORD [esi+window.id]
	shl esi, 7
	add esi, [veharrayptr]
	mov dh, al
	or dh, 0x20
	mov dl, 5
	mov al, [edi+100010b]
	call insertvehorderhere_gotveh
	mov al, [savedinsertvehorderpos]
	inc al
	mov dx, 0x80
	push DWORD vehorderwinhandlerhook_cancel
	pusha
	jmp insertvehorderhere.in

.fullloadparams:
	cmp BYTE [esi+0x31], 3
	jne NEAR .end
	mov ecx, 8
	call GenerateDropDownExPrepare
	jc NEAR vehorderwinhandlerhook_cancel
	mov DWORD [DropDownExList], ourtext(advorder_orderskipcountguibtntxt)
	mov DWORD [DropDownExList+4], ourtext(advorder_orderloadpercentguibtntxt)
	mov DWORD [DropDownExList+8], statictext(empty)
	mov DWORD [DropDownExList+12], ourtext(tr_optxt)
	mov DWORD [DropDownExList+16], ourtext(trdlg_eq)
	mov DWORD [DropDownExList+20], ourtext(trdlg_neq)
	mov DWORD [DropDownExList+24], statictext(trdlg_lt)
	mov DWORD [DropDownExList+28], statictext(trdlg_gt)
	mov DWORD [DropDownExList+32], statictext(trdlg_lte)
	mov DWORD [DropDownExList+36], statictext(trdlg_gte)
	mov DWORD [DropDownExList+40], -1
	mov DWORD [DropDownExListDisabled], 12
	mov ecx, 8
	or edx, BYTE -1
	call GenerateDropDownEx
	jmp vehorderwinhandlerhook_cancel

.specparamddlitemsel:
	cmp al, 2
	ja .specparamopsel
	dec al
	and al, 8
	mov cl, al
	call VehOrders@@SelItemToOrderIdx
	movzx eax, WORD [ebx+2]
	and ah, 0x1F
	shr eax, cl
	mov [advorderskipcondloadtxtinputwintmpidval], cl
	and eax, BYTE 0x7F
	mov [textrefstack], eax
	mov ax, statictext(printdword)
	mov bl, 0xFF
	mov ch, 3
	mov cl, [esi+window.type]
	mov dx, [esi+window.id]
	mov bp, ourtext(tr_enternumber)
	call [CreateTextInputWindow]
	jmp vehorderwinhandlerhook_cancel

.specparamopsel:
	mov cl, al
	sub cl, 4
	call VehOrders@@SelItemToOrderIdx
	and BYTE [ebx+3], 0x1F
	shl cl, 5
	or [ebx+3], cl
	jmp vehorderwinhandlerhook_cancel

.textwindowchangehandler:
	push esi
	mov ebx, 0
	mov esi, baTextInputBuffer
	call getnumber
	pop esi
	jc vehorderwinhandlerhook_cancel
	cmp edx, -1
	je vehorderwinhandlerhook_cancel
	mov cl, [advorderskipcondloadtxtinputwintmpidval]
	or cl, cl
	jnz .countn
	or edx, edx
	jns .next1
	xor edx, edx
.next1:
	cmp edx, 100
	jna .chkdone
	mov edx, 100
	jmp .chkdone
.countn:
	and edx, 0x1F
.chkdone:
	shl edx, cl
	mov ebp, ~0x7F
	rol ebp, cl
	or ebp, ~0x1F7F
	and edx, 0x1F7F
	mov ecx, edx
	call VehOrders@@SelItemToOrderIdx
	and [ebx+2], bp
	or [ebx+2], cx
	jmp vehorderwinhandlerhook_cancel
.notddlsel:
.end:
	popad
	jmp near $
	ovar vehorderwinhandlerhook.oldfn,-4

vehorderwinhandlerhook_cancel:
	popad
	pushad
	mov esi, edi
	mov al, [esi+window.type]
	mov bx, [esi+window.id]
	call [RefreshWindows]
	popad
	ret

/*
exported vehorderwinclicktoselhook_hook
	push ebp
	push edx
	push ebx
	add al, [esi+window.itemsoffset]
	//al is now order id based on window position

	movzx ebp, WORD [esi+window.id]
	shl ebp, 7
	add ebp, [veharrayptr]
	mov edx, [ebp+veh.scheduleptr]
.loop:
	or al, al
	jz .end
	mov bx, [edx]
	or bx, bx
	jz .end
	and bl, 0x1F
	cmp bl, 5
	jne .notest
	shr bh, 5
	movzx ebx, bh
	add edx, ebx
	add edx, ebx
.notest:
	dec al
	add edx, 2
	jmp .loop
.end:
	sub edx, [ebp+veh.scheduleptr]
	shr edx, 1
	mov al, dl
	cmp al, [esi+window.selecteditem]
	pop ebx
	pop edx
	pop ebp
	ret
*/

exported vehorderwinitemoffsetshiftcorrectorhook_hook
	dec al
	sub al, [esi+window.itemsoffset]
	cmp al, 6
	jnb .next
	ret
.next:				//blatantly assume that the last extra word is not 0...
	mov ax, [ebp]
	and al, 0x1F
	cmp al, 5
	jne .faile
	shr ah, 5
	movzx eax, ah
	add ebp, eax
	add ebp, eax
.faile:
	cmp esp, esp
	ret
	
exported vehorderwinitemcounthook_hook
.loop:
	mov bx, [edi]
	or bx, bx
	je .ret
	inc al
	add edi, BYTE 2
	and bl, 0x1F
	cmp bl, 5
	jne .loop
	shr bx, 12
	and ebx, BYTE 14
	add edi, ebx
	jmp .loop
.ret:
	ret

