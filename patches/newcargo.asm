

#include <std.inc>
#include <flags.inc>
#include <textdef.inc>
#include <station.inc>
#include <grf.inc>
#include <window.inc>
#include <veh.inc>
#include <industry.inc>
#include <misc.inc>
#include <newvehdata.inc>
#include <bitvars.inc>
#include <ptrvar.inc>

extern DrawGraph,DrawWindowElements,WindowClicked,calcprofitfn,cargoclass
extern cargoclasscargos,cargoid,curspriteblock,drawtextfn
extern fillrectangle,getnewsprite,getwincolorfromdoscolor
extern grffeature,invalidatehandle,isfreight,isfreightmult
extern malloc,patchflags,pdaTempStationPtrsInCatchArea,randomstationtrigger
extern cargobits,cargotypes,spriteblockptr,stationarray2ofst
extern updatestationgraphics,newvehdata,specificpropertybase
extern callback_extrainfo,curcallback,grfstage,grfresources
extern statanim_cargotype,stationanimtrigger


// In most places, the cargo type is stored in at least a byte, so it isn't too hard to
// modify the limit to 32.

// The difficult part is stations. Those have 12 cargo slots, each associated with a cargo
// type. We can't extend them to have 32 slots without breaking a lot of code. Instead, we
// uncouple the slots from cargo types, so every station can have up to 12 of the 32 cargo
// types. We use station2 to store the cargo type associated with each slot. Reserving a
// slot just to store acceptance of a cargo type would be a waste, so acceptance data is
// moved to station2.acceptedcargos, which is a dword bitmask of accepted cargoes. This
// frees up 4 bits in stationcargo.amount, so it can store up to 65,536 units now. To
// avoid display glitches (amounts printed as negative), we don't use the sign bit, so
// the maximum is 32,767 instead.

// There is some newcargos code in loadunl.asm as well.

//new arrays instead of the old 12-element-long ones. The bottom 12 are reserved for the 
//old data (it is copied over here), the remaining 20 slots are for the new data

uvarw newcargotypenames,32
uvarw newcargounitnames,32
uvarw newcargoamount1names,32
uvarw newcargoamountnnames,32
uvarw newcargoshortnames,32
uvarw newcargoicons,32
uvarb newcargounitweights,32
uvarb newcargodelaypenaltythresholds1,32
uvarb newcargodelaypenaltythresholds2,32
uvard newcargopricefactors,2*(32)
uvarb newcargocolors,32
uvarb newcargographcolors,32

global newcargodatasize
newcargodatasize equ 6*2*32+3*1*32+8*1*32+2*32

#if !WINTTDX
varb defcargocolors,  0x98, 0x06, 0x0F, 0xAE, 0xD0, 0xC2, 0xBF, 0x37, 0xB8, 0x0A, 0xBF, 0x30
varb defcargographcolors,  0x98, 0x06, 0x0F, 0xAE, 0xD0, 0xC2, 0xBF, 0x54, 0xB8, 0x0A, 0xCA, 0x01
#else
varb defcargocolors,  0x98, 0x20, 0x0F, 0xAE, 0xD0, 0xC2, 0xBF, 0x37, 0xB8, 0x0A, 0xBF, 0x30
varb defcargographcolors,  0x98, 0x20, 0x0F, 0xAE, 0xD0, 0xC2, 0xBF, 0x54, 0xB8, 0x0A, 0xCA, 0xD7
#endif

%macro copyarray 3
	mov ecx,%3*12
	mov esi,%1
	mov edi,%2
	rep movsb
%endmacro

	// this is called to initialize newcargo data for savegames that were saved
	// with "newcargos off", as well as when running with "newcargos off"
global copyorgcargodata
copyorgcargodata:
	pusha
	copyarray cargotypenames,newcargotypenames,2
	copyarray cargounitnames,newcargounitnames,2
	copyarray cargoamount1names,newcargoamount1names,2
	copyarray cargoamountnnames,newcargoamountnnames,2
	copyarray cargoshortnames,newcargoshortnames,2
	copyarray cargoicons,newcargoicons,2
	copyarray cargounitweights,newcargounitweights,1
	copyarray cargodelaypenaltythresholds1,newcargodelaypenaltythresholds1,1
	copyarray cargodelaypenaltythresholds2,newcargodelaypenaltythresholds2,1
	copyarray cargopricefactors,newcargopricefactors,8
	popa
	ret

%undef copyarray

// Newcargos is off, and we're loading a savegame that was saved with newcargos on
// To prevent complete mess-up caused by the different format, clear all cargo data
// from all stations in the game.
global clearstationcargodata
clearstationcargodata:
	pusha
	mov esi,stationarray+station.cargos
	mov ecx,numstations
.loop:
	xor edx,edx
.nextslot:
	mov dword [esi+edx*8],0xAF000000	//amount/accept=0, timesincevisit=0, rating=175
	mov dword [esi+edx*8+4],0xFF0000FF	//enroutefrom=FF, enroutetime=0, lastspeed=0, lastage=FF
	inc edx
	cmp edx,12
	jb .nextslot

	add esi,station_size
	loop .loop

	popa
	ret

// Called from the cargo distribution code to add a given cargo amount to the station
// in:	esi->station
//	dl=source station idx
//	ebx=cargo offset (cargo number * 8)
//	ah=amount to add
global addcargotostation_2
addcargotostation_2:
	// find cargo slot for this type
	push ebx
	mov ecx, ebx
	shr ecx, 3
	movzx eax, ah

	add esi, [stationarray2ofst]
	// ESI->Station2

// now we need to find the right slot
	xor ebx, ebx
.loop:
	cmp [esi+station2.cargos+ebx+stationcargo2.type], cl
	je .found
	add ebx, stationcargo2_size
	cmp ebx, 12*stationcargo2_size
	jb .loop

// the caller must already have created the slot for us, so something went very wrong if we get here
	ud2

.found:
	sub esi, [stationarray2ofst]
	// ESI->station

// add the amount to the station, but be careful not to exceed the limit ( 7FFFh )
	add [esi+station.cargos+ebx+stationcargo.amount],ax
	jns .nooverflow
	mov word [esi+station.cargos+ebx+stationcargo.amount],0x7FFF
.nooverflow:

// update en-route time and cargo source
	mov byte [esi+station.cargos+ebx+stationcargo.enroutetime], 0
	mov [esi+station.cargos+ebx+stationcargo.enroutefrom], dl

// we've overridden some newstations code, so reproduce it here
// activate the "new cargo arrived" trigger and redraw the station
	testflags newstations
	jnc .nostationtrigger

	pusha
	mov eax,ebx
	mov ebx,esi
	add esi, [stationarray2ofst]
	movzx eax,byte [esi+station2.cargos+eax+stationcargo2.type]

	mov esi,ebx
	mov [statanim_cargotype],al
	mov edx,1
	call stationanimtrigger

	xor edx,edx
	bts edx,eax
	mov al,1
	mov ah,0x80
	call randomstationtrigger
	popa
	call updatestationgraphics

.nostationtrigger:
// redraw the station window
	movzx ebx, dl
	mov al, 11h
	call [invalidatehandle]
	pop ebx
	ret

// called to find the cargo icon associated with the cargo of a station slot
// IN:	ebx = slot#
//	esi->cargo slot
// OUT:	bx = spriteid
// safe:eax
global movbxcargoicons
movbxcargoicons:
	push esi
	add esi, [stationarray2ofst]
	movzx eax,byte [esi+station2.cargos+stationcargo2.type]
	mov bx, [newcargoicons+eax*2]
	cmp bx,-1
	jne .done

// The GRF wants to have its own icon, so call it to get the sprite to be used

	xor ebx,ebx
	xor esi, esi
	mov byte [grffeature],11
	call getnewsprite
	mov ebx,eax
	jnc .done
	mov ebx,4302	//goods icon, will do as a general icon if no graphics are available
.done:
	pop esi
	ret

// Called to get the textID to display in the station window, according to singular/plural
// The old code simply added 20h to get the plural textID from the singular one, but
// this assumption is no longer correct
// in:	ebx=slot#
//	esi->cargo slot
//	ax=amount
// out:	bx=textid
// safe: eax
global movbxcargoamountnames
movbxcargoamountnames:
	push esi
	add esi, [stationarray2ofst]
	movzx ebx,byte [esi+station2.cargos+stationcargo2.type]
	push cx
	mov cx, [newcargoamount1names+ebx*2]
	dec ax
	jz .done
	mov cx, [newcargoamountnnames+ebx*2]
.done:
	mov bx, cx
	pop cx
	pop esi
	ret

// The same as above, but called when displaying the amount of cargo carried by a
// vehicle, in the details window. That code has the same false assumption as the
// previous one.
// in:	ax=cargo amount
//	ebx=cargo type
// out:	bx=textid
// safe: eax
global movbxcargoamountname2
movbxcargoamountname2:
	dec ax
	jz .singular
	mov bx,[newcargoamountnnames+2*ebx]
	ret

.singular:
	mov bx,[newcargoamount1names+2*ebx]
	ret

// Still the same, but now for the industry window, when displaying the production
// of last month
// in:	eax=cargotype
//	bx=amount
// out: ax=textid
// safe: none
global movaxcargoamountnames
movaxcargoamountnames:
	cmp bx, 1
	jz .singular
	mov ax, [newcargoamountnnames+eax*2]
	ret

.singular:
	mov ax, [newcargoamount1names+eax*2]
	ret

// Called to get the textID for the name of the cargo in the current slot
// (for the ratings list)
// in:	eax=slot#
//	esi->cargo slot
// out: ax=textid
global movaxcargotypenames
movaxcargotypenames:
	push esi
	add esi, [stationarray2ofst]
	movzx eax,byte [esi+station2.cargos+stationcargo2.type]
	mov ax, [newcargotypenames+eax*2]
	pop esi
	ret

// Called in the station list window handler to get the short cargo name
// textID for the current slot
// in:	ebp=slot#
//	esi->station
// out:	bx=textid
global movbxcargoshortnames
movbxcargoshortnames:
	push esi
	add esi, [stationarray2ofst]
	movzx ebx,byte [esi+8*ebp+station2.cargos+stationcargo2.type]
	mov bx, [newcargoshortnames+ebx*2]
	pop esi
	ret

// Auxiliary: Get cargo slot offset (slot# * 8) on a given station for the
// given cargo type. Returns FFh if there's no slot for this cargo.
// in:	al=cargo#
//	ebx->station
// out:	ecx=cargo offset
global ecxcargooffset
ecxcargooffset:
	add ebx, [stationarray2ofst]
	xor ecx,ecx
	
.loop:
	cmp [ebx+station2.cargos+ecx+stationcargo2.type], al
	je .found
	add ecx, stationcargo2_size
	cmp ecx,12*stationcargo2_size
	jb .loop

	mov cl,0xff

.found:
	sub ebx, [stationarray2ofst]
	ret

// Auxiliary: Try introducing a new cargo type to an empty slot, or
// a used slot that seems to be unused. This can still fail, returning
// FFh as result, so you need to have fallback code to handle this.
// NOTE: should be called only if the nonforced version gives 0xff
// in:	al=cargo#
//	ebx->station
// out:	ecx=cargo offset
// uses: ah, edx
global ecxcargooffset_force
ecxcargooffset_force:

// first, look for any empty slots
	xor ecx, ecx
	mov edx, ebx
	add edx, [stationarray2ofst]

.loop1:
	cmp byte [edx+station2.cargos+ecx+stationcargo2.type], 0xff
	je .foundit
	add ecx, stationcargo2_size
	cmp ecx,12*stationcargo2_size
	jb .loop1

// second, try finding a cargo slot that was never loaded from
	xor ecx, ecx

.loop2:
	cmp byte [ebx+station.cargos+ecx+stationcargo.lastspeed], 0
	je .foundit
	add ecx, stationcargo2_size
	cmp ecx,12*stationcargo2_size
	jb .loop2

// if that didn't work, select the one that was waiting for the longest time
	xor ecx, ecx
	xor ah,ah

.loop3:
	cmp ah, [ebx+station.cargos+ecx+stationcargo.timesincevisit]
	ja .better
	mov edx, ecx
	mov ah, [ebx+station.cargos+ecx+stationcargo.timesincevisit]
.better:
	cmp ecx,12*stationcargo2_size
	jb .loop3

// if there's no slot waiting for more than 30 days, don't kick out anything,
// but fail instead

	mov cl,0xff
	cmp ah, 30
	jbe .done

	mov ecx,edx

.foundit:
// reset this slot so the new cargo can start from defaults
	and word [ebx+station.cargos+ecx+stationcargo.amount], 0
	mov byte [ebx+station.cargos+ecx+stationcargo.timesincevisit], 0
	mov byte [ebx+station.cargos+ecx+stationcargo.enroutefrom], 0xFF
	mov byte [ebx+station.cargos+ecx+stationcargo.rating], 175
	mov byte [ebx+station.cargos+ecx+stationcargo.lastspeed], 0
	mov byte [ebx+station.cargos+ecx+stationcargo.lastage], -1

	mov edx, ebx
	add edx, [stationarray2ofst]

	or word [edx+station2.cargos+ecx+stationcargo2.curveh],-1
	mov [edx+station2.cargos+ecx+stationcargo2.type],al

.done:
	ret

// check if station accepts cargo type
//
// in:	edx=cargo type
//	esi->station
// out:	ZF=1 yes, accepts
//	ZF=0 no, does not accept
// uses:ebx
checkacceptcargo:
	mov bl,[esi+station.facilities]
	test bl,11111101b	// ignore truck station
	jnz .nonontruck

	// only has truck station, so only accept if it's not in cargo class 0 (passengers)
.onlynonpass:
	test byte [cargoclass+edx*2],1
	ret

.nonontruck:
	test bl,11111011b	// ignore bus station
	jz .onlybus

	test al,0		// has something else (not only truck station),
	ret			// i.e. accept everything

.onlybus:
	// only has bus station
	// for regular bus station, allow cargo class 0
	// for bus stop, allow only actual passengers
	movzx ebx,word [esi+station.busXY]
	mov bl,[landscape5(bx,1)]
	cmp bl,0x53
	je .isstop
	cmp bl,0x54
	je .isstop

	// regular bus station, allow cargo class 0
	mov bl,[cargoclass+edx*2]
	xor bl,1
	test bl,1	// Now ZF=1 if cargo class 0, ZF=0 otherwise
	ret

.isstop:
	// bus stop, only passengers
	test edx,edx
	ret


// called to update the acceptance list of the station
//
// in:	ax=amount of 1/8ths of acceptance
//	edx=cargo type
//	esi->station
// safe:eax ebx edx
global updatestationacceptlist
updatestationacceptlist:
	call checkacceptcargo
	jz .ok
	xor eax,eax
.ok:
	mov ebx, esi
	add ebx, [stationarray2ofst]

	btr dword [ebx+station2.acceptedcargos],edx
	movzx eax,ax
	shr eax,15		// eax=1 if cargo is accepted
	mov cl,dl
	shl eax,cl		// eax= accepts ? (bitmask) : 0
	or dword [ebx+station2.acceptedcargos],eax

// step loop variables here so we can loop 32 times instead of 12
	add ebp, 2
	inc edx
	cmp dl, 32
	ret

// called when displaying the acceptance list while building a bus/truck station
//
// in:	bx=cargo type
//	esi->window
//	ZF=0 CF=1 building non-rv station
//	ZF=0 CF=0 building truck station
//	ZF=1 CF=0 building bus station
//	[ebp]=acceptance units (word)
// out:	ZF=0 not accepted
//	ZF=1 accepted
// safe:eax
global displayconstacceptlist
displayconstacceptlist:
	jnb .rv

	test al,0	// set ZF
	ret

.rv:
	movzx eax,bx
	je .bus

	// building truck station, so only accept if it's not in cargo class 0 (passengers)
	test byte [cargoclass+eax*2],1
	ret

.bus:
	// building bus station
	// for regular bus station, allow cargo class 0
	// for bus stop, allow only actual passengers
	cmp byte [buslorrystationorientation],4
	jae .busstop

	// regular bus station, allow cargo class 0
	mov al,[cargoclass+eax*2]
	xor al,1
	test al,1
	ret

.busstop:
	// bus stop, only passengers
	test eax,eax
	ret


// check whether road vehicle is a bus (carrying cargo class 0) or not
//
// in:	esi->vehicle
// out:	ZF=1 is bus, ZF=0 is not bus
// uses:---
global isrvbus
isrvbus:
	push eax
	movzx eax,byte [esi+veh.cargotype]
.checkcargo:
	mov al,[cargoclass+eax*2]
	xor al,1
	test al,1
	pop eax
	ret

// same as above, but in eax=vehtype
global isrvtypebus
isrvtypebus:
	push eax
	movzx eax,byte [rvcargotype+eax]
	jmp isrvbus.checkcargo

// insert road vehicle order
global insrvorder
insrvorder:
	mov ah,4	// overwritten
	test byte [edi+station.flags],1<<6
	jz isrvbus

	// allow busses and trucks to go to non-stop bus stops
	mov ah,6
	test al,0	// set ZF
	ret

// check if rv is bus, and skip next four bytes if not
global checkrvtype1
checkrvtype1:
	call isrvbus
	jz .done
	add dword [esp],4
.done:
	ret

// check if rv is bus, and skip next four bytes if yes
global checkrvtype2
checkrvtype2:
	call isrvbus
	jnz .done
	add dword [esp],4
.done:
	ret

// check if rv is bus, and skip next 0x27 bytes if yes
global checkrvstation
checkrvstation:
	call isrvbus
	jnz .done
	add dword [esp],0x27
.done:
	ret

// check if station can accept the cargo we're distributing
// in:	al=cargo type
//	ebp->station
// out:	ZF=1 yes can accept
//	ZF=0 no, can't
// safe:dl ebp
global checkdistcargo
checkdistcargo:
	push ebx
	push edx
	push esi
	movzx edx,al
	mov esi,ebp
	call checkacceptcargo
	pop esi
	pop edx
	pop ebx
	ret

// the following array supplements those used by DistributeProducedCargo
// it contains the cargo offset of the current cargo on the stations found
// it contains junk for unused entries
uvarb TempCargoOffsetsInCatchmentArea,8

// Called during DistributeProducedCargo to decide if the station accepts cargo
// (i.e. it's not a waypoint)
// in:	al=cargo type
//	ebp->station
//	ebx=number of stations found so far
// out: zf set to allow cargo
global distribcargo_foundstation
distribcargo_foundstation:
	test byte [ebp+station.flags],0x40	//overwritten, check for waypoint flag
	jnz .exit

	push edx
	push edi

// first try looking for the cargo slot
	mov edi,ebp
	add edi,[stationarray2ofst]
	xor edx,edx
.loop:
	cmp [edi+station2.cargos+edx+stationcargo2.type], al
	je .found
	add edx, stationcargo2_size
	cmp edx,12*stationcargo2_size
	jb .loop

// no slot found
// this means no vehicles have tried loading the cargo yet, so we shouldn't allow the cargo
// if selectgoods is on
	testflags selectstationgoods
	jc .disallow

// try introducing a new slot - if we fail, we disallow the station since it has no slot for the cargo
	xchg ebx,ebp
	push eax
	push ecx
	call ecxcargooffset_force
	mov dl,cl
	pop ecx
	pop eax
	xchg ebx,ebp

	or dl,dl
	js .disallow

.found:
// if we're successful, store the offset so we don't have to look it up again
// please note that at this point, the station won't surely be added to the list
// we don't have to worry about this, though; the later code won't read unused fields
	mov [TempCargoOffsetsInCatchmentArea+ebx],dl
	pop edi
	pop edx

	cmp eax,eax	// set zf
.exit:
	ret

.disallow:
	or ebp, ebp
	pop edi
	pop edx
	ret

// Called when only one feasible station is found, to decide how much cargo to
// actually add there. We must use the correct cargo offset instead of cargonum*8
// in:	ah=amount of distributable cargo
//	ebx=cargo number*8
//	dl=station id
//	esi->station
// out:	ax= ah * (rating for cargo)
global distribcargo_1station
distribcargo_1station:
	push ebx
	movzx ebx,byte [TempCargoOffsetsInCatchmentArea+0]

	mov al,ah
	mul byte [esi+station.cargos+ebx+stationcargo.rating]

	pop ebx
	ret

// distance between daTempStationPtrsInCatchArea and baTempStationIdxsInCatchArea
// with this, we can reference both through a single register
%define idxoffset 4*8

// Called when more than one feasible station is found. We must select two of them
// (with the two best ratings) to distribute cargo between them. The logic is the
// same as for the old code, but we can't use it because it assumes the cargo data
// has the same offset on every station.
// in:	ah=amount of cargo
//	ebx=cargonum*8
//	ebp=0
// out:	dh, dl = ID and rating for the best station
//	ch, cl = ID and rating for the second station
// safe: edi,ebp
global distribcargo_2stations
distribcargo_2stations:
	push eax
	push ebx

	mov eax,[pdaTempStationPtrsInCatchArea]

// during the loop dl will contain the rating of the best station, and dh will hold its ID

// init all those registers with the data of the first station, then loop from
// the second entry
	mov edi, [eax]
	movzx ebx,byte [TempCargoOffsetsInCatchmentArea]
	mov dl, [ebx+edi+station.cargos+stationcargo.rating]
	mov dh, [eax+idxoffset]
	inc ebp

.nextstation:
	cmp byte [eax+idxoffset+ebp], -1	// end of valid entries - we're done with the loop
	jz .done1
	mov edi, [eax+ebp*4]			// get the pointer of the station
	movzx ebx,byte [TempCargoOffsetsInCatchmentArea+ebp]
	cmp dl, [ebx+edi+station.cargos+stationcargo.rating]	// check rating
	ja .worserating
	mov dl, [ebx+edi+station.cargos+stationcargo.rating]	// update dl and dh
	mov dh, [eax+idxoffset+ebp]
.worserating:
	inc ebp
	cmp ebp, 8				// are we at the end of the array?
	jb .nextstation
.done1:

// now the second loop: finding the second station. We'll use cl and ch.

// the init is a bit trickier - we must init with the first entry, except if it's
// the best, so we use the second one
	xor ebp, ebp
	mov edi, [eax]
	mov ch, [eax+idxoffset]
	movzx ebx,byte [TempCargoOffsetsInCatchmentArea]
	cmp ch, dh
	jnz .notequal
	mov edi, [eax+4]
	mov ch, [eax+idxoffset+1]
	movzx ebx,byte [TempCargoOffsetsInCatchmentArea+1]
.notequal:
	mov cl, [ebx+edi+station.cargos+stationcargo.rating]

.loop2:
	cmp byte [eax+idxoffset+ebp], -1	// end of valid entries - we're done with the loop
	jz .done2
	cmp dh, [eax+idxoffset+ebp]		// skip the entry of the best one
	jz .skip
	mov esi, [eax+ebp*4]
	movzx ebx,byte [TempCargoOffsetsInCatchmentArea+ebp]
	cmp cl, [ebx+esi+station.cargos+stationcargo.rating]	// check rating
	ja .better
	mov cl, [ebx+esi+station.cargos+stationcargo.rating]	// update cl and ch
	mov ch, [eax+idxoffset+ebp]
.better:
.skip:
	inc ebp
	cmp ebp, 8				// are we at the end of the array?
	jb .loop2
.done2:
	pop ebx
	pop eax
	ret
%undef idxoffset

// Called when setting up a new station struc. Init our new fields in
// station2. (all slots unused; accepted cargos=none)
global setupstation2
setupstation2:
	mov byte [esi+station.exclusive],0	// overwritten
.overwrittendone:
	mov edi,esi
	add edi,[stationarray2ofst]
	and dword [edi+station2.acceptedcargos],0
	push ecx
	xor ecx,ecx
.nextcargo:
	mov byte [edi+station2.cargos+ecx+stationcargo2.type],0xff
	add ecx,stationcargo2_size
	cmp ecx,12*stationcargo2_size
	jb .nextcargo
	pop ecx
	ret

// The same, but called when setting up an oilfield station.
global setupoilfield
setupoilfield:
	mov byte [esi+station.facilities],0x18
	jmp short setupstation2.overwrittendone

// Called to assemble the list of accepted cargos for the station
// window. We need to overwrite this because the accepted cargoes
// are stored differently with newcargos. We need to fill a buffer
// with a comma-separated list that displazs the actual cargo names
// via control char 0x81.
// in:	esi->station
//	ebp->buffer
// out:	buffer filled (an extra separating comma is expected)
//	ebp->first unused byte in buffer
// safe: eax,ebx,???
global collectacceptedcargos
collectacceptedcargos:
	xor ebx,ebx
	add esi,[stationarray2ofst]
	mov esi,[esi+station2.acceptedcargos]

// now esi=mask of accepted cargos
.nextcargo:
	bt esi,ebx
	jnc .doesntaccept

// cargo number ebx is accepted - put it in the list
	mov ax,[newcargotypenames+ebx*2]
	shl eax,8
	mov al,0x81
	mov [ebp],eax
	mov word [ebp+3],', '
	add ebp,5
.doesntaccept:
	inc ebx
	cmp bl,32
	jb .nextcargo

	ret

// Called to put the cargo unit name ID into AX in the subsidy message handler
// The old code assumed unitname=typename+20h, this assumption is no longer true
// in:	ebx=cargo number
// out:	ax=unit name if SF=0, leave alone otherwise
global getcargounitnames
getcargounitnames:
	js .leavealone
	mov ax, [newcargounitnames+2*ebx]
.leavealone:
	ret

// Called while initializing cargo price factors. This is the only array that needs
// to be initialized in both the old and the new place. The old entries are initialized
// with the default values just like the new ones, but aren't touched later, except for
// applying inflation on them. This way, we can use the old passenger cost slot to adjust
// new costs to the inflation when they are set
// in:	eax=cost factor
//	edi->old slot to be filled
// out:	fill new slot (old is already filled)
global initcargoprices
initcargoprices:
	and dword [edi+4], 0	//overwritten
	push edi
	sub edi, cargopricefactors
	add edi, newcargopricefactors
	mov dword [edi],eax
	and dword [edi+4],0
	pop edi
	ret

// Called periodically to inflate prices. We need to inflate both the old and the new
// costs - the old ones must be inflated so we always have a reference cost.
// in:	ebx=inflation factor
//	ecx=12
//	esi->beginning of old price factors
// safe: eax,edx,ebp
global inflatecargoprices
inflatecargoprices:
.origloop:
	call .doinflateprice
	loop .origloop,cx

	mov esi,newcargopricefactors
	mov ecx,32
.newloop:
	call .doinflateprice
	loop .newloop
	ret

.doinflateprice:
// old TTD code to inflate a price slot
	mov eax, [esi]
	imul ebx
	mov ebp, eax
	shr ebp, 10h
	shl edx, 10h
	mov dx, bp
	add [esi+4], ax
	adc [esi], edx
	add esi, 8
	ret

// Called to get the color to be drawn for the cargo slot in the station list window
// in:	esi->station
//	ebp=slot#
// out:	ebp=color to be used
global getcargocolor
getcargocolor:
	add esi,[stationarray2ofst]
	movzx ebp,byte [esi+station2.cargos+ebp*8+stationcargo2.type]
	sub esi,[stationarray2ofst]
	movzx ebp,byte [newcargocolors+ebp]
	ret

// Called while initializing cargo data. Initialize our two new tables, newcargocolors
// and newcargographcolors as well, so the first 12 cargoes work like before.
// out:	esi=climate
// safe: eax,ecx,edi,???
global initcargodata
initcargodata:
#if !WINTTDX
	push es
	push ds
	pop es
#endif
	mov esi, defcargocolors
	mov edi, newcargocolors
	times 3 movsd
	mov esi, defcargographcolors
	mov edi, newcargographcolors
	times 3 movsd
	movzx esi, byte [climate]	// overwritten
#if !WINTTDX
	pop es
#endif
	ret

	//
	// special functions to handle special cargo properties
	//
	// in:	eax=special prop-num
	//	ebx=offset
	//	ecx=num-info
	//	edx->feature specific data offset
	//	esi=>data
	// out:	esi=>after data
	//	carry clear if successful
	//	carry set if error, then ax=error message
	// safe:eax ebx ecx edx edi

// Property 8 - set cargo bit
global setcargobit
setcargobit:
	xor eax,eax
	mov edx,[curspriteblock]
.next:
	// clear previous cargo bit, if any
	mov al,[cargotypes+ebx]
	cmp al,0xff
	je .nooldbit
	btr [cargobits], eax
	or dword [globalcargolabels+ebx*4],byte -1
.nooldbit:
	lodsb
	cmp al,0xff		// FFh means clearing the bit only
	je .nonewbit

	test byte [expswitches],EXP_MANDATORYGRM
	jz .notmandatory
	cmp byte [grfstage],0
	je .notmandatory
.checknextres:
	cmp [grfresources+(GRM_CARGOBITS+eax)*4],edx
	jne .unresid
.notmandatory:
	bts [cargobits], eax
	mov [cargoid+eax],bl

	// provide default cargo label (otherwise the default translation table won't work)
	mov [globalcargolabels+ebx*4],esi	// that should be a pretty unlikely but unique label
.nonewbit:
	mov [cargotypes+ebx], al
	inc ebx
	loop .next
	clc
	ret

.unresid:
	mov eax,(INVSP_UNRESID<<16)+ourtext(invalidsprite)
	stc
	ret
	

// Set price factor of a cargo. The tricky part is that we need to set the cargo
// price as if it inflated constantly during the game. To solve this, we keep
// inflating all old cargo prices, so we can use the old passenger cost to
// find out the inflation factor.
global setcargopricefactors
setcargopricefactors:

// First, calculate the inflation multiplier, since this will be the same for
// all cargoes being set. The cost is stored as 32 bits of integer part and
// 16 bits of fraction, and we calculate the multiplier as 32 bits of integer
// part and 32 bits of fraction.
// (we can use IDIV because the divisor is positive)

	mov eax,[cargopricefactors]	//integer part of old passenger cost
	cdq
	mov edi, 3185			// default base cost of passengers
	idiv edi			// eax=integer part of multiplier
	push eax
	mov eax,[cargopricefactors+4]
	shl eax,16			//fraction of old passenger cost

	// edx still contains the remainder of the previous division,
	// no need to CDQ here

	idiv edi			// eax=fraction part of multiplier
	push eax
.next:
	lodsd
// multiply the 32-bit base cost and the 32.32 bit mutliplier to get the
// cost, but truncate the fraction of the result to 16 bits
	mov edi,eax
	imul edi,dword [esp+4]
	mov [newcargopricefactors+ebx*8], edi
	imul dword [esp]
	add [newcargopricefactors+ebx*8], edx
	shr eax,16
	mov [newcargopricefactors+ebx*8+4], eax
	inc ebx
	loop .next

	add esp,8
	clc
	ret

// Set cargo colors in the station list and in the cargo payment window.
// These two need a handler only to translate color index in the Win verson.

global setcargocolors
setcargocolors:
.next:
	xor eax,eax
	lodsb
#if WINTTDX
	call getwincolorfromdoscolor
#endif
	mov [newcargocolors+ebx],al
	inc ebx
	loop .next

	clc
	ret

global setcargographcolors
setcargographcolors:
.next:
	xor eax,eax
	lodsb
#if WINTTDX
	call getwincolorfromdoscolor
#endif
	mov [newcargographcolors+ebx],al
	inc ebx
	loop .next

	clc
	ret

global setfreighttrainsbit
setfreighttrainsbit:
	testflags freighttrains
	sbb ah,ah
.next:
	btr dword [isfreight],ebx
	btr dword [isfreightmult],ebx
	lodsb
	test al,al
	jz .notset
	bts dword [isfreight],ebx
	and al,ah
	jz .notset
	bts dword [isfreightmult],ebx
.notset:
	inc ebx
	loop .next
.done:
	clc
	ret

global setcargoclasses
setcargoclasses:
.next:
	xor eax,eax
	lodsw
	mov [cargoclass+ebx*2],ax
.nextclass:
	bsf edi,eax
	jz .gotclasses
	btr eax,edi
	// now edi=cargo class, ebx=cargo ID
	movzx edx, byte [cargotypes+ebx]		// edx=cargo bit
	bts [cargoclasscargos+edi*4],edx	// set cargo bit in given class
	jmp .nextclass

.gotclasses:
	inc ebx
	loop .next
	clc
	ret

	// handler for feature 08 prop 09
global setcargotranstbl
setcargotranstbl:
	mov edx,[curspriteblock]
	mov eax,[edx+spriteblock.cargotransptr]
	cmp eax,defcargotrans
	jne .hastable

	push 0+cargotrans_size
	call malloc
	pop eax
	mov [edx+spriteblock.cargotransptr],eax

.hastable:
	mov [eax+cargotrans.numtrans],cl
	mov [eax+cargotrans.tableptr],esi
	lea esi,[esi+4*ecx]
	ret

	// End of action 0 property handlers


uvard defcargotranstable,NUMCARGOS

varb defcargotrans
	istruc cargotrans
		at cargotrans.tableptr, dd defcargotranstable
		at cargotrans.numtrans, db NUMCARGOS
	iend
endvar

// Resolve cargo translation table
global resolvecargotranslations
resolvecargotranslations:
	// construct default translation table
	mov edi,defcargotranstable
	mov ecx,NUMCARGOS
	or eax,byte -1
	push edi
	rep stosd
	pop edi

	mov cl,NUMCARGOS
.addnext:
	movzx eax,byte [cargotypes+ecx-1]
	cmp al,0xff
	je .empty

	mov edx,[globalcargolabels+(ecx-1)*4]
	mov [edi+eax*4],edx

.empty:
	loop .addnext

	mov edx,[spriteblockptr]
	mov ebx,defcargotrans
	jmp short .havelist	// skip check for defcargotrans (to translate it exactly once)

.resolve:
	mov ebx,[edx+spriteblock.cargotransptr]
	cmp ebx,defcargotrans
	je .next

.havelist:
	push edx

	lea edi,[ebx+cargotrans.fromslot]
	mov ecx,NUMCARGOS*2/4
	or eax,byte -1
	rep stosd
	inc eax
	stosd		// clear bit mask

	mov esi,[ebx+cargotrans.tableptr]
	xor ecx,ecx

.donext:
	mov eax,[esi+ecx*4]
	xor edx,edx
.search:
	cmp eax,[globalcargolabels+edx*4]
	je .found
	inc edx
	cmp edx,NUMCARGOS
	jb .search
	jmp short .findnext	// not found, leave at -1

.found:
	// eax=label ebx->cargotrans ecx=translation edx=slot
	movzx eax,byte [cargotypes+edx]	// now eax=bit
	cmp eax,NUMCARGOS
	jae .findnext

	mov [ebx+cargotrans.fromslot+edx],cl
	mov [ebx+cargotrans.frombit+eax],cl
	bts [ebx+cargotrans.supported],eax

.findnext:
	inc ecx
	cmp cl,[ebx+cargotrans.numtrans]
	jb .donext

	pop edx

.next:
	mov edx,[edx+spriteblock.next]
	test edx,edx
	jg .resolve
	ret

// The cargo payment window needs some modifications - having 32 buttons with most of them being
// blank would look bad, not to mention unusable. We replace the 12 old buttons with a scrollable
// list and we fill the cargo names dynamically.

// When initializing the window, we need to count the available cargo types to set window.itemstotal
// in:	esi->window
// safe: eax,ebx,ecx,edx,ebp
global initpaymentwindow
initpaymentwindow:
	mov dword [esi+window.data],1		// overwritten
	mov byte [esi+window.itemsvisible],12

// now count all cargoes available on the current climate
	mov ecx,31
.nextslot:
	movzx eax,byte [cargotypes+ecx]
	cmp al, 0xff
	je .skip			// cargo undefined
	bt [cargobits],eax
	adc byte [esi+window.itemstotal],0
.skip:
	dec ecx
	jns .nextslot
	ret

// Called when the player clicks on the cargo list. To find out which element is under the
// cursor, iterate through cargos with the same logic as while drawing.
// in:	ax, bx = screen X,Y
//	esi->window
// safe: all but esi
global paymentwindow_listclick
paymentwindow_listclick:
// get the element index from the Y coord
	sub bx, [esi+window.y]
	movzx ebx,bx
	sub ebx, 24
	shr ebx, 3	// luckily enough, the height of one element is exactly 8 pixels
	add bl, [esi+window.itemsoffset]

// try finding the cargo associated with the index
	xor eax,eax
.loop:
	movzx edx,byte [cargotypes+eax]
	cmp dl,0xff
	je .skip			// cargo undefined
	bt [cargobits],edx
	sbb ebx,0
	js .gotit
.skip:
	inc eax
	cmp eax,32
	jb .loop
	ret

.gotit:
// there's a valid entry under the cursor - enable it on the graph
	btc [esi+window.data],eax
	ret

// Called instead of the window redraw code. We need to replace most of that code
// because the graph drawer routine supports 16 graphs only, so we can't just give
// all cargo data to it and disable some graphs. We need to give it the selected
// cargoes only, so the user can select up to 16 cargoes from the 32.
// in:	esi->window
// safe: ???
global drawpaymentwindow
drawpaymentwindow:
	call [DrawWindowElements]	// Draw the static parts
	// now edi points to the screen update block descriptor

	pusha

// draw the cargo type names to the listbox, respecting the scroll position
	mov cx,[esi+window.x]
	mov dx,[esi+window.y]
	add cx,495
	add dx,25
	push esi
	movzx ebp,byte [esi+window.itemsoffset]
	xor esi,esi
.namesloop:
	movzx eax,byte [cargotypes+esi]
	cmp al, 0xff
	je .skipname			// cargo undefined
	bt [cargobits],eax
	jnc .skipname			// cargo isn't enabled for this climate
	dec ebp
	jns .skipname			// this cargo is above the visible part
	cmp ebp,-12
	jl .namesdone			// we reached the bottom of the list, draw no more
	mov eax,[esp]
	mov eax,[eax+window.data]

	pusha

	// draw the edge of the color rectangle in black if unselected and white if selected
	xor ebp,ebp
	bt eax,esi
	jnc .notselected1
	mov ebp,15
.notselected1:

	// draw edge...
	mov eax,ecx
	lea ebx,[ecx+8]
	mov ecx,edx
	add edx,5
	call [fillrectangle]
	// ...and the rectangle itself
	inc eax
	dec ebx
	inc ecx
	dec edx
	movzx ebp,byte [newcargographcolors+esi]
	call [fillrectangle]

	popa
	pusha

	// now draw the name itself
	mov ebx,[newcargotypenames+esi*2]
	mov [textrefstack],ebx
	add ecx, 14
	mov bx,statictext(microtext)	// print a string from the text ref. stack in micro letters

	// black text if unselected, white if selected
	bt eax,esi
	mov al,0x10			// black text
	jnc .notselected2
	mov al,0x0c			// white text
.notselected2:
	call [drawtextfn]

	popa
	add edx,8
.skipname:
	inc esi
	cmp esi,32
	jb .namesloop
.namesdone:
	pop esi

// fill the graphdata struc needed by the graph drawer routine
// we make ebp point past the actual data, so all helper fields can be reached with a byte offset
	sub esp,graphdata_size
	lea ebp,[esp+graphdata.colors]
%define base (ebp-graphdata.colors)
	or dword [base+graphdata.serieshidden],byte -1		// hide all series

	// set positon of the graph
	mov eax,[esi+window.x]
	add eax,2
	mov [base+graphdata.X],ax
	mov eax,[esi+window.y]
	add eax,24
	mov [base+graphdata.Y],ax

	// set various other constant parameters
	mov word [base+graphdata.height],104
	mov byte [base+graphdata.hasnegvalues],0
	mov word [base+graphdata.vlabelstext],0x7023
	mov word [base+graphdata.labelcolor],0x10
	mov word [base+graphdata.gridline0colorscheme],1
	mov word [base+graphdata.gridlinescolorscheme],0x0e
	mov byte [base+graphdata.nseries],16
	mov byte [base+graphdata.maxpoints],20
	mov byte [base+graphdata.vgridlines],20
	mov byte [base+graphdata.startmonth],-1
	mov word [base+graphdata.firstarg],15
	mov word [base+graphdata.argstep],15

	mov eax,[esi+window.data]
	push esi
	lea esi,[esp+4]

// now esi points to the beginning of the data part of the graph struc
// eax is the bitmask of selected cargoes
// cl will contain the next usable slot number
// ch will loop through the cargo types

	xor ecx,ecx
.typeloop:
	movzx ebx,ch
	bt eax,ebx
	jnc .skiptype					// type not selected
	shl word [base+graphdata.serieshidden],1	// enable a new graph
	jnc .skiptype					// if a zero bit exited on the left,
							// the list is already full
	mov dl,[newcargographcolors+ebx]		// set the color
	movzx ebx,cl
	mov byte [base+graphdata.colors+ebx],dl

// now calculate the payment for the different travel times
// dl will contain the current time (stepping by 6, which equals roughly 15 days)
// esi will point to the next dword to fill

	mov dl,6
	push eax
	push ecx
.timeloop:
	push edx
	mov ax,20
	mov cl,10
	call [calcprofitfn]	// calculate profit (cost, actually so it will be negative)
	neg eax
	mov [esi],eax		// store it
	add esi,4
	pop edx
	add dl,6
	cmp dl,21*6
	jb .timeloop

	add esi,4*4	// a series uses 24 slots, we filled 20 only

	pop ecx
	pop eax
	inc cl		// we've filled a slot, increase index
.skiptype:
	inc ch
	cmp ch,32
	jb .typeloop

	push edi
// fill the rest of the data with zero so the scaling code doesn't go berserk
	mov edi,esi
	lea ecx,[base+graphdata.colors]
	sub ecx,edi
	xor al,al
	rep stosb

%undef base

// draw the graph
	lea ebp,[esp+8]
	call [DrawGraph]
	pop edi
	pop esi

// free the data from the stack, but leave the parameters so we can position the labels
	add esp,graphdata.colors

// from now, we'll access the remaining struc directly via esp
%define base (esp-graphdata.colors)

	// label for the X axis
	mov ecx,[base+graphdata.X]
	mov edx,[base+graphdata.Y]
	add ecx,46
	add dx,[base+graphdata.height]
	add edx,7
	mov bx,0x7062		// "Days in transit"
	call [drawtextfn]

	// label for the Y axis
	mov ecx,[base+graphdata.X]
	mov edx,[base+graphdata.Y]
	add ecx,84
	sub edx,9
	mov bx,0x7063		// "Payment for delivering..."
	call [drawtextfn]

	// free the rest of the struc
	add esp,graphdata_size-graphdata.colors
%undef base
	popa
	ret

// Called in the payment window event handler. Now that we have a scrollbar in the
// window, we must make sure the scrollbar arrows are released shortly after being pressed
// in:	dl=event ID
//	esi->window
// safe: ???
global paymentwindoweventhandler
paymentwindoweventhandler:
	mov ebx,ecx	// overwritten
	mov esi,edi	// ditto
	cmp dl,cWinEventUITick
	jnz .dontreset

	push edx
	push esi
	mov ax,0x8000
	call [WindowClicked]	// release up/down scroll arrows
	pop esi
	pop edx

.dontreset:
	cmp dl,cWinEventRedraw	// overwritten
	ret

uvarb cargotowngrowthtype,32
uvarw cargotowngrowthmulti,32

// Callback flags
// bit	meaning
//   0	callback for transportation income
uvarb cargocallbackflags,32

global resetcargodata
resetcargodata:
	mov ecx,32
	mov edi,cargotowngrowthtype
	mov al,0xff
	rep stosb

	mov byte [cargotowngrowthtype+0],0
	mov byte [cargotowngrowthtype+2],2
	mov byte [cargotowngrowthtype+5],5
	mov byte [cargotowngrowthtype+9],9
	mov byte [cargotowngrowthtype+11],11

	mov ecx,32
	mov edi,cargotowngrowthmulti
	mov ax,0x100
	rep stosw

	mov ecx,32
	mov edi,cargocallbackflags
	xor eax,eax
	rep stosb
	ret

// called to calculate income for transporting a cargo
// in:	ax: distance
//	ch: cargo type
//	cl: amount
//	dl: transit time
// out: (if returning normally) ax: adjusted distance
//	(if returning further to the caller) eax: cost multiplier
// safe: ebx
global calcprofit
calcprofit:
// reproduce overwritten code
	movzx ebx,ch
	mov dh,0xff
	test byte [cargocallbackflags+ebx],1
	jnz .special
	ret

.special:
	mov [callback_extrainfo],ax
	mov [callback_extrainfo+2],cl
	mov [callback_extrainfo+3],dl

	push esi
	xor esi, esi
	mov byte [grffeature],11
	mov byte [curcallback],0x39
	xchg eax,ebx
	call getnewsprite
	xchg eax,ebx
	mov byte [curcallback],0
	pop esi
	jc .error

	shl bx,1
	movsx ebx,bx
	sar ebx,1

	movzx eax,cl
	imul eax,ebx
	movzx ebx,ch
	add dword [esp],48

.error:
	ret
