//
// new sprites handlers
//

#include <std.inc>
#include <flags.inc>
#include <grf.inc>
#include <station.inc>
#include <veh.inc>
#include <vehtype.inc>
#include <industry.inc>
#include <ptrvar.inc>
#include <house.inc>

extern acttriggers,cachevehvar40x,canalfeatureids,cargoaction3,curcallback
extern curgrffile,curgrfsprite,curstationtile,curtriggers,ecxcargooffset
extern externalvars,extraindustilegraphdataarr
extern genericids,getaircraftinfo,getcargoenroutetime,getcargolastvehdata
extern getcargorating,getcargotimesincevisit,getcargowaiting,getconsistcargo
extern getcurveinfo,getexpandstate,gethouseage,gethouseanimframe
extern gethousebuildstate,gethousecount,gethouseterrain,gethousezone
extern getincargo,getindustileanimframe,getindustileconststate
extern getindustilelandslope,getindustilepos,getistownlarger,getmotioninfo
extern getotherhousecount,getothernewhousecount,getplatformdirinfo
extern getplatforminfo,getplatformmiddle,getplayerinfo
extern getstationacceptedcargos,getstationpbsstate,getstationsectioninfo
extern getstationsectionmiddle,getstationterrain,gettownnumber,gettrackcont
extern getvehiclecargo,getvehidcount,getvehnuminconsist,getvehnuminrow
extern industryaction3,numextvars,patchflags,septriggerbits
extern stationcargolots,stationcargowaitingmask,stationflags,stsetids
extern triggerbits,vehids
extern wagonoverride

uvard grffeature
uvard curgrffeature,1,s		// must be signed to indicate "no current feature"
uvard curgrfid,1,s		// same here
uvard curaction3info
uvard mostrecentspriteblock

uvard curstationcargo


// find action 3 and spriteblock for each feature
//
// in:	eax=vehicle (etc.) ID
// out:	eax->action 3
// 	on error eax=0

grfcalltable getaction3, dd addr(getaction3_table.generic)

.generic:
	mov eax,[genericids+(eax-0x100)*4]
	ret

.gettrains:
	cmp byte [wagonoverride+eax],1
	jb .nooverride

	// wagon override bit was set
	// see if the current engine has an override and if so,
	// use it instead of the current cargo ID
	test esi,esi
	jz .nooverride

	// if it's an articulated vehicle, we base the override not
	// on the engine but on the first vehicle of the artic
	movzx ebx,word [esi+veh.articheadidx]

	cmp byte [esi+veh.artictype],0xfd
	jae .artic

	movzx ebx,word [esi+veh.engineidx]

.artic:
	shl ebx,vehicleshift
	add ebx,[veharrayptr]
	movzx ebx,word [ebx+veh.vehtype]
	call checkoverride
	jc .badoverride
	ret

.getplanes:
	cmp byte [wagonoverride+eax],1
	jb .nooverride

	// override for helicopter rotor
	// get rotor graphics if esi has sign bit set
	// use regular engine graphics if esi is empty or an engine
.rotoroverride:
	btr esi,31
	jnc .nooverride

	mov ebx,eax
	sub al,AIRCRAFTBASE
	call checkoverride
	jc .badoverride
	ret

.badoverride:
	mov eax,[curgrfid]

.nooverride:
.getrvs:
.getships:
	mov eax,[vehids+eax*4]
	ret

.gethouses:
	mov eax,[extrahousegraphdataarr+eax*4] //8+housegraphdata.act3]
	ret
	
.getindustiles:
	mov eax,[extraindustilegraphdataarr+eax*4]
	ret

.getcanals:
	mov eax,[canalfeatureids+eax*4]
	ret

.getbridges:
	xor eax,eax	// no data
	ret

.getstations:
	or dword [curstationcargo],byte -1
	mov eax,[stsetids+eax*stsetid_size+stsetid.act3info]
	ret

.getindustries:
	mov eax,[industryaction3+eax*4]
	ret

.getcargos:
	mov eax,[cargoaction3+eax*4]
	ret

.getgeneric:
.getsounds:
	ud2

.invalidfeature:
	ud2	// another ud2 to distinguish it from the above by different address


// find right entry in action 3
//
// in:	ecx->action3info struct
// out:	eax->right cargo type

grfcalltable getaction3cargo

.gettrains:
.getrvs:
.getships:
.getplanes:
	or ebx,byte -1
	test esi,esi
	jz .getcargo

#if 0
	movzx ebx,byte [climate]
	imul ebx,32
	add bl,[esi+veh.cargotype]
	mov bl,[cargotypes+ebx]
#endif
	movzx ebx,byte [esi+veh.cargotype]

.getcargo:
	movzx eax,word [ecx+action3info.cargo+ebx*2]
	test eax,eax
	jnz .foundit

.getcanals:
.getbridges:
.gethouses:
.getindustiles:
.getindustries:
.getcargos:

.default:
	movzx eax,word [ecx+action3info.defcid]
.foundit:
	ret

.stationdefault:
	movzx eax,word [ecx+action3info.nodefcargoid]
	test eax,eax		// if cargo type FE defined, prevent the default from being used
	je .default
	ret

.getstations:
	or ebx,byte -1
	test esi,esi
	jz .getcargo	// use default cargo

	mov eax,ebx

.nextstationcargo:
	inc eax
	cmp eax,NUMCARGOS
	jae .stationdefault	// no defined cargo type has cargo

	xor ebx,ebx

	cmp word [ecx+action3info.cargo+eax*2],0
	je .nextstationcargo

	testflags newcargos
	jc .hasnewcargos

	// mov bl,[cargoid+eax]
	mov ebx,[esi+station.cargos+eax*8+stationcargo.amount]
	and ebx,0xfff
	jnz .gotcargo
	jmp .nextstationcargo

.hasnewcargos:			//	eax	ebx	ecx	esi
				//	cargo#	---	org.ecx	station
	mov ebx,esi		//	cargo#	station	org.ecx	station
	mov esi,ecx		//	cargo#	station	org.ecx	org.ecx
	call ecxcargooffset	// in: eax=cargo# ebx->station; out: ecx=cargo ofs
				//	cargo#	station	offset	org.ecx
	xchg esi,ecx		//	cargo#	station	org.ecx	offset
	xchg ebx,esi		//	cargo#	offset	org.ecx	station

	cmp bl,0xff
	je .nextstationcargo

	movzx ebx,word [esi+station.cargos+ebx+stationcargo.amount]
	and ebx,[stationcargowaitingmask]
	jz .nextstationcargo

.gotcargo:
	mov [curstationcargo],ebx
	mov ax,[ecx+action3info.cargo+eax*2]
	ret

.getgeneric:
.getsounds:
	ud2

// process the final action 2 and return the sprite number
//
// in:	ebx->action 2 data
//	edx=direction to add to sprite
// out: eax=sprite number
//      ebx=adjusted direction to add to sprite (if necessary)
//	CF set if eax is not really a sprite number and should not be checked
//	   for being a callback result

grfcalltable getaction2spritenum

.getplanes:
	// see if direction is special (e.g. rotor)
	test dh,0x80
	jz .planesnotrotor

	// it's special, we only return the sprite base and the number of sprites
	//mov ax,[ebx+5]
	movzx eax, word [ebx+5]

	movzx cx,byte [ebx-1]

	lea bx,[ecx+1]
	// carry clear here
	ret

.gettrains:
.getrvs:
.getships:
.planesnotrotor:
	push edx

	movzx ecx,byte [ebx-1]
	push ecx	// store AND mask for later

	add ebx,3	// skip action, veh-type, and cargo-id(set-id)

	mov cl,[ebx]
	inc ebx

	test esi,esi
	jz .gotload

	movzx eax,word [esi+veh.engineidx]
	shl eax,vehicleshift
	add eax,[veharrayptr]
	cmp byte [eax+veh.totalorders],0
	je short .notloading

	mov al,byte [eax+veh.currorder]
	and al,0x1f

	cmp al,3
	jne short .notloading

	mov eax,ecx
	mov cl,[ebx]
	lea ebx,[ebx+2*eax]	// skip load states in motion

.notloading:
	movzx eax,word [esi+veh.currentload]
	mul ecx
	movzx ecx,word [esi+veh.capacity]
	inc ecx
	div ecx
	xchg eax,ecx

.gotload:		// if load info not available, use max. load
			// here, ebx points to <num-loadingtypes>
	lea ebx,[ebx+1+ecx*2]

.gotloadnum:
	movzx eax,word [ebx]
	pop ecx
	pop ebx
	and ebx,ecx	// apply AND mask for direction
	// carry clear here
	ret

.getstations:
	add ebx,3	// skip action, veh-type, and cargo-id

	movzx ecx,byte [ebx]
	inc ebx

	test esi,esi
	jz near .gotstatload

	mov eax,[curstationcargo]
	test eax,eax
	jns .notdefault

	// using default cargo (no cargo type match) -> add up total cargo waiting
	push ecx
	xor eax,eax
	xor edx,edx
.addnext:
	mov cx,[esi+station.cargos+edx*stationcargo_size+stationcargo.amount]
	and ecx,[stationcargowaitingmask]
	add eax,ecx
	cmp eax,0x0fff
	jb .notfull

	mov eax,0x0fff
	jmp short .arefull

.notfull:
	inc edx
	cmp edx,12
	jb .addnext
.arefull:
	pop ecx

.notdefault:
	mov edx,[curgrfid]
	test byte [stationflags+edx],2
	jz .notpertile

	push edx
	push ecx
	movzx ecx,byte [esi+station.platforms]
	mov edx,ecx	// XXX when stat var 40+x cached, use var 49 here
	and cl,0x87
	and dl,0x78
	shr dl, 3
	cmp cl, 80h
	jb .istoosmall
	sub cl, (80h - 8h)
.istoosmall:
	add ecx,edx
	xor edx,edx
	div ecx
	pop ecx
	pop edx

.notpertile:
	movzx edx,word [stationcargolots+edx*2]
	cmp eax,edx
	jb .notlots

	sub eax,edx
	neg edx
	add edx,4095

	push edx
	mov edx,ecx
	mov cl,[ebx]
	lea ebx,[ebx+2*edx]	// skip load states for little cargo
	pop edx

.notlots:
	xchg ecx,edx
	mul edx
	inc ecx
	div ecx
	xchg eax,ecx

.gotstatload:		// if load info not available, use max. load
			// here, ebx points to <num-loadingtypes>
	lea ebx,[ebx+1+ecx*2]
	movzx eax,word [ebx]
	clc
	ret

.getcanals:
.getcargos:
	movzx eax,word [ebx+5]
	mov ebx,edx
	add eax,ebx
	// carry clear here
	ret

.getbridges:
	mov ebx,edx
	ud2

.gethouses:
.getindustiles:
	//for houses and industry tiles, we return a pointer to the real data
	// in eax instead of a sprite number
	lea eax,[ebx+3]
	movzx ebx,byte [ebx-1]
	stc	// eax is not a sprite number
	ret

.getindustries:
	//industries can have a production data structure as a final action 2
	//return a pointer to it in eax
	lea eax,[ebx+4]
	stc
	ret

.getgeneric:
.getsounds:
	ud2

//
// get TTD sprite ID for new graphics
//
// in:	 al=vehtype for vehicles, station sprite set for stations
//	 ah=0 means regular feature sprite, ah=1 means generic feature callback
//	 bx=direction for vehicles
//	esi->vehicle/station struct or 0 if none available
//	[grffeature] must be set correctly
//
// out:	(for regular sprites)
//	ax=new sprite base
//	ebx&=dirmask for vehicles
//	all other registers preserved
// 	carry flag set and eax=0 on error (sprites not available, callback result)
//
//	(for callbacks)
//	eax=callback result, 0..7eff max
//	ebx preserved
//	carry flag set and eax=0 if callback failed (not a callback result)
//
//	(for houses)
//	eax-> building data
//	ebx=number of available sprites -1

global getnewsprite
getnewsprite:
#if !WINTTDX
	push es		// we need to set ES properly
	push ds
	pop es
#endif
	push edx
	push ecx
	push ebx
	mov [curgrfid],eax

#if MEASUREVAR40X
	or ecx,byte -1
	mov [tscvar],ecx
	call checktsc
#endif

	mov cl,0
	cmp cl,ah
	mov ecx,[grffeature]
	sbb edx,edx	// -1 for generic (-> ignore feature), 0 for regular
	mov [curgrffeature],ecx
	or edx,ecx
	call [getaction3+edx*4]
	test eax,eax
	jle .baddata

		// get spriteblock
.chain:
//	mov ecx,[eax-6]
	mov [curaction3info],eax
	mov edx,[eax+action3info.spriteblock]

		// record file and sprite number for the crash logger
	mov ebx,[edx+spriteblock.filenameptr]
	mov [curgrffile],ebx

	mov ebx,[eax+action3info.spritenum]
	mov [curgrfsprite],ebx

		// also record the spriteblock for code following the getnewsprite call
	mov [mostrecentspriteblock],edx

#if 0
		// skip numveh and vehids
	movzx ebx,byte [ecx+action3info.numveh]
	inc eax
	add eax,ebx
#endif

	// now eax-1 points to veh.ID=>cargo ID mapping
	// [eax]=number of cargo types
	// [eax+1+n*3]=cargo type	(n=0..num-1)
	// [eax+2+n*3]=cargo ID
	// [eax+1+num*3]=default ID
	//
#if 0
	movzx ecx,byte [eax]
	inc eax
	jecxz .gotcargo		// only the default; no others available
#endif
	xchg eax,ecx
	mov eax,[grffeature]
	call [getaction3cargo+eax*4]

//.gotcargo:
	xchg eax,ebx

	// now ebx = cargo ID sprite number
	//
	// follow randomized and variational cargo IDs until
	// we reach a real cargo ID
	//
.gotaction2:
	mov eax,[edx+spriteblock.spritelist]
	mov ebx,[eax+ebx*4]
	mov eax,[ebx-8]
	mov [curgrfsprite],eax

	mov al,[ebx+3]
	sub al,0x80
	jb .gotcargoid

	call getrandomorvariational
	test bh,bh			// got callback result?
	jns .gotaction2

.callbackresult:
	cmp byte [curcallback],0	// was it really a callback?
	je .baddata

	add bh,1
	adc bh,-1			// map ff -> 00 (old style result)

	// got valid callback result
	xchg eax,ebx
	pop ebx
	and eax,0x7fff
	jmp short .done

.baddatacallback:
	// if callback fails, try to pass request on to previously installed callback
	mov eax,[curaction3info]
	mov eax,[eax+action3info.prev]
	test eax,eax
	jg .chain

.baddata:
	xor eax,eax
	pop ebx
	stc
	jmp short .return

.gotcargoid:
#if 0
	// got a non-variational/random cargo id
	// this is bad if it was a callback
	cmp byte [curcallback],0
	jne .baddatacallback
#endif

	pop edx
	push edx	// put back on stack so it can be popped by the callback code if necessary

	mov eax,[grffeature]
	call [getaction2spritenum+eax*4]
	jc .notspritenum

	// make sure it's a callback result if and only if we are in a callback
	xchg eax,ebx

	test bh,bh
	js .callbackresult

	xchg eax,ebx

.notspritenum:
	cmp byte [curcallback],0
	jne .baddatacallback

	pop ecx		// dummy pop to adjust stack

.done:
	clc

.return:
#if MEASUREVAR40X
	pushf
	mov ecx,[grffeature]
	or dword [tscvar],byte -1
	call checktsc
	popf
#endif

	pop ecx
	pop edx
	mov dword [curgrffile],0	// for the crash logger (not AND to preserve carry flag)
	mov dword [curgrffeature],-1	// invalid feature, if not set will cause crash
#if !WINTTDX
	pop es
#endif
	ret
; endp getnewsprite


	// check whether a wagon has an override for this engine
	//
	// in:	eax=vehtype of wagon within class
	//	    (i.e. veh.vehtype-vehbase[class])
	//	ebx=vehtype of engine
	// out:	carry set if no override
	//	carry clear if override, then also eax->action3info struct
	// uses:ebx
	//
global checkoverride
checkoverride:
	mov ebx,[vehids+ebx*4]
	test ebx,ebx
	jle .nooverride		// engine has no special graphics

	mov ebx,[ebx+action3info.overrideptr]
	test ebx,ebx
	jle .nooverride

	mov eax,[ebx+eax*4]
	cmp eax,1
	ret

.nooverride:
	stc
	ret

#if 0
	movzx ecx,word [ebx+action3info.spritenum]
	mov edx,[ebx+action3info.spriteblock]
	mov bl,[ebx+action3info.numoverrides]
	xor bl,0x80
	js .nooverride		// no override for this engine

	// ok, so we have an override; the engine sprite number is
	// in ecx and the number of override action 3 entries is in bl

	push esi

	mov esi,[edx+spriteblock.spritelist]
	push edi
	push eax
	lea esi,[esi+ecx*4]
	mov edi,[esi]
	test edi,edi
	jle .isbad

	movzx edi,byte [edi+1]	// veh class
	sub al,[vehbase+edi]			// search for id in class

.trynextaction:
	add esi,4
	mov edi,[esi]
	test edi,edi
	jg .notbad

.isbad:
	pop eax
	pop edi
	pop esi

.nooverride:
	stc
	ret

.notbad:
	cmp byte [edi],3	// action 3?
	jne .trynextaction

	mov ecx,[edi-4]
	movzx ecx,byte [ecx+action3info.numveh]
	add edi,3

	repne scasb
	je .gotit

	dec bl
	jnz .trynextaction
	jmp .isbad

.gotit:
	pop eax
	mov eax,[esi]
	pop edi
	inc eax
	pop esi
	inc eax
	ret
#endif

uvarb isother			// 0 if the action refers to the vehicle/tile/whatever, 1 if to the "other thing"
uvarb nostructvars		// 1 if in a callback that must not use 40+x or type 82/83

badaction2var:
	ud2

// handle random and/or variational set IDs
//
// in:	al=type-80
//	ebx=current sprite data
// out:	ebx=new sprite number
// safe:eax ecx edx
getrandomorvariational:
	push esi

	test al,2
	setnz [isother]
	jz .notother

	test esi,esi
	jz .noother

	cmp byte [nostructvars],0
	jne badaction2var

	mov ecx,[grffeature]
	call [getother+ecx*4]

.noother:
	xor al,3		// change 2=>1, 3=>0, 6=>5

.notother:
	test al,1
	jnz near getvariational	// 81 or 82
	// jmp short getrandom	// 80 or 83

getrandom:	// random cargo ID
	push edx
	xor eax,eax
	test esi,esi
	jz .gotrandom

	movzx edx,byte [isother]

	mov cl,[ebx+5]

	// check which bits (if any) trigger from the current event
	mov al,[ebx+4]
	mov ah,al
	and al,[curtriggers]
	jz .nottriggeredyet	// no matching random triggers

	test ah,ah
	jns .anytrigger

	and ah,0x7f
	cmp ah,al
	jne .nottriggeredyet

.anytrigger:
	or [acttriggers],al
	movzx eax,byte [ebx+6]	// bit mask -> bits for this trigger
	shl eax,cl
	or [triggerbits],eax
	or [septriggerbits+4*edx],eax

.nottriggeredyet:
	mov eax,[grffeature]
	call [getrandombits+eax*4]
	shr eax,cl
	movzx eax,al
	and al,[ebx+6]
.gotrandom:
	movzx ebx,word [ebx+7+eax*2]
	pop edx
	pop esi
	ret


// get random bits
//
// in:	eax=0
//	ebx->action 2 data
//	ecx=grf feature
//	esi->feature struct
// out:	eax=random bits
// safe:ecx(8:31)
grfcalltable getrandombits

.gettrains:
.getrvs:
.getships:
.getplanes:
	mov al,[esi+veh.random]
	ret

.getstations:
	mov eax,[curstationtile]
//	add eax,[landscape6ptr]
	mov eax,[landscape6+eax]
	and eax,0x0f
	shl eax,16
	mov ax,[esi+station.random]
	ret

.getcanals:
.getbridges:
.getgeneric:
.getcargos:
.norandom:
.getsounds:
	ret

.gethouses:
	cmp byte [isother],0
	jnz .norandom
//	mov eax,[landscape6ptr]		// house random bits are in L6
	movzx eax,byte [landscape6+esi]
	ret

.getindustiles:
	cmp byte [isother],0
	jnz .industry
//	mov eax,[landscape6ptr]		// industry tile random bits are in L6
	movzx eax,byte [landscape6+esi]
	ret

.getindustries:
	cmp byte [isother],0
	jnz .norandom
.industry:
	movzx eax,word [esi+industry.random]
	ret

grfcalltable getrandomtriggers

.gettrains:
.getrvs:
.getships:
.getplanes:
	mov al,[esi+veh.newrandom]
	ret

.getstations:
	cmp byte [isother],0
	jnz .norandom
	mov al,[esi+station.newrandom]
	ret

.getcanals:
.getbridges:
.getgeneric:
.getindustries:
.getcargos:
.norandom:
.getsounds:
	ret

.gethouses:
	cmp byte [isother],0
	jnz .norandom
	mov al,[landscape3+esi*2]
	shr al,6
	ret

.getindustiles:
	cmp byte [isother],0
	jnz .norandom
	mov al,[landscape7+esi]
	ret

getvariationalvariable:
	movzx eax,byte [ebx]	// variable
	test al,0xc0
	js .structvar		// 80+x
	jz .externalvar		// x

	test al,0x20		// check for 0x6x variables
	jz .noparam
	inc ebx
	mov cl,byte [ebx]
.noparam:

	cmp al,0x7f
	je .paramvar		// 7F (check grf parameter) is always available

	test esi,esi
	jz .novar

	cmp byte [nostructvars],0
	jne badaction2var

	test al,0x20		// check for 0x6x variables
	jnz .paramvar

	call getspecialvar	// 40+x
	jmp short .gotval

.paramvar:			// 60+x
	call getspecparamvar
	jmp short .gotval

.structvar:			// 80+x
	test esi,esi
	jz .novar

	movzx ecx,byte [grffeature]
	shl ecx,1
	add cl,[isother]
	add al,[featurevarofs+ecx]

	mov eax,[esi+eax]
	jmp short .gotval

.novar:
	movzx ecx,dl
	mov dh,[ebx+1]
	test dh,0xe0
	lea ebx,[ebx+ecx+1]		// skip shiftnum, bitmask
	jz .exit
	lea ebx,[ebx+2*ecx]		// skip add-val and div/mod-val
	//jmp .gotrange
.exit:
	stc
	ret

.externalvar:
	cmp eax,numextvars
	jae .gotval

	mov eax,[externalvars+eax*4]
	mov eax,[eax]

.gotval:
	mov cl,[ebx+1]		// shiftnum
	mov dh,cl
	and cl,0x1f
	shr eax,cl

	add ebx,2
	call getvariational.getvalue_zx	// bitmask, must be zero-extended
	and eax,ecx

	test dh,0xc0
	jz .gotvaladjust

	call getvariational.getvalue_sx	// add-value, signed
	add eax,ecx

// before dividing, we should simulate overflowing according to the current size,
// or negative numbers don't work correctly (GRFs will expect 0xF0+0x20 to be 0x10,
// not 0x110; a byte variable containing 0xe7 must expand to 0xFFFFFFe7)

	call getvariational.make_eax_signed

	push edx
	call getvariational.getvalue_sx	// divide-val
	cdq
	test ecx,ecx
	jz .nodiv
	idiv ecx
.nodiv:
	mov ecx,edx
	pop edx

	test dh,0x40
	jnz .gotvaladjust

	mov eax,ecx	// get remainder

.gotvaladjust:
	clc
	ret

getvariational:
	// find variational cargo ID from list
	// in:	ebx=variation cargo ID definition
	//	esi=struct or 0 if none
	// out:	ebx=new cargo ID sprite number
	// safe:eax ebx ecx

	push edx
	push ebp

// first find out which size we are working with, and save it to dl
	mov dl,1
	test byte [ebx+3],0xc
	jz .notwide

	mov dl,2

	test byte [ebx+3],0x8
	jz .notdword
	mov dl,4

.notdword:
.notwide:

// check variable
	add ebx,4

	call getvariationalvariable
	jc .errorinvar
	test dh,0x20
	jz .gotval

.nextvar:
	push eax
	movzx ebp,byte [ebx]
	inc ebx
	call getvariationalvariable
	mov ecx,eax
	pop eax
	jc .errorinvar
	call [addr(.operators)+ebp*4]
	test dh,0x20
	jnz .nextvar
	jmp short .gotval

.errorinvar:
	inc ebx
	inc ebx
	test dh,0x20
	jz .gotrange
	dec ebx
	mov dh,[ebx]
	and dh,0xe0
	cmp dh,0x60
	jne .notparam
	inc ebx
.notparam:
	movzx ecx,dl
	mov dh,[ebx+1]
	lea ebx,[ebx+ecx+1]
	test dh,0xc0
	jz .errorinvar
	lea ebx,[ebx+2*ecx]
	jmp short .errorinvar

.gotval:
// now, before comparing, we should simulate overflowing again, but with the high
// bits being zeroed, so for ex. 0xFFFFFFF8 becomes 0xF8 and can be compared to
// other bytes in an unsigned manner

	call .make_eax_unsigned

	mov [lastcalcresult],eax	// store for next var.action 2 in chain

	mov dh,[ebx]
	inc ebx

	test dh,dh
	jnz .normal
	movzx ebx,ax
	or bh,0x80
	jmp short .gotvalue
.normal:

.nextrange:
	add ebx,2		// skip cargoid
	call .getvalue_zx	// lower bound
	mov ebp,ecx
	call .getvalue_zx	// upper bound
	cmp eax,ebp
	jb .toolow
	cmp eax,ecx
	ja .toohigh

// we've got the right one, but ebx points past it
	movzx edx,dl
	neg edx
	lea ebx,[ebx-2+2*edx]
	jmp short .gotrange

.toolow:
.toohigh:
	dec dh
	jnz .nextrange

.gotrange:
	movzx ebx,word [ebx]
.gotvalue:
	pop ebp
	pop edx
	pop esi
	ret

.getvalue_zx:
	cmp dl,2
	je .getword_zx
	ja .getwidevalue

	movzx ecx,byte [ebx]
	inc ebx
	ret

.getword_zx:
	movzx ecx,word [ebx]
	inc ebx
	inc ebx
	ret

.getvalue_sx:
	cmp dl,2
	je .getword_sx
	ja .getwidevalue

	movsx ecx,byte [ebx]
	inc ebx
	ret

.getword_sx:
	movsx ecx,word [ebx]
	inc ebx
	inc ebx
	ret

.getwidevalue:
	mov ecx,[ebx]
	add ebx,4
	ret

.operators:
	dd addr(.add),addr(.sub),addr(.signed_min),addr(.signed_max),addr(.unsigned_min),addr(.unsigned_max)
	dd addr(.signed_divmod),addr(.signed_divmod),addr(.unsigned_divmod),addr(.unsigned_divmod)
	dd addr(.multiply),addr(.and),addr(.or),addr(.xor)

.add:
	add eax,ecx
	ret

.sub:
	sub eax,ecx
	ret

.and:
	and eax,ecx
	ret

.or:
	or eax,ecx
	ret

.xor:
	xor eax,ecx
	ret

.multiply:
// we can get away with a single imul without size checks becouse of two things:
// -	when multiplying two n-bit numbers, the lowest n bits of the result will be the
//	same for signed and unsigned multiplication
// -	when multiplying numbers xxxxa and yyyyb, the lowest digit of the result will
//	be a*b if it fits in a single digit

	imul eax,ecx
	ret

.make_eax_signed:
	cmp dl,2
	je .make_eax_word_signed
	ja .exit

	movsx eax,al
.exit:
	ret

.make_eax_word_signed:
	movsx eax,ax
	ret

.make_eax_unsigned:
	cmp dl,2
	je .make_eax_word_unsigned
	ja .exit

	movzx eax,al
	ret

.make_eax_word_unsigned:
	movzx eax,ax
	ret

.make_eax_ecx_signed:
	xchg ecx,eax
	call .make_eax_signed
	xchg ecx,eax
	jmp short .make_eax_signed
	
.make_eax_ecx_unsigned:
	xchg ecx,eax
	call .make_eax_unsigned
	xchg ecx,eax
	jmp short .make_eax_unsigned

.signed_min:
	call .make_eax_ecx_signed

	cmp eax,ecx
	jl .exit
	mov eax,ecx
	ret

.signed_max:
	call .make_eax_ecx_signed

	cmp eax,ecx
	jg .exit
	mov eax,ecx
	ret

.unsigned_min:
	call .make_eax_ecx_unsigned

	cmp eax,ecx
	jb .exit
	mov eax,ecx
	ret

.unsigned_max:
	call .make_eax_ecx_unsigned

	cmp eax,ecx
	ja .exit
	mov eax,ecx
	ret

.signed_divmod:
	call .make_eax_ecx_signed

	push edx
	cdq
	or ecx,ecx
	jz .no_signed_divmod
	idiv ecx
.no_signed_divmod:

	cmp ebp,6
	je .notsmod

	mov eax,edx
.notsmod:
	pop edx
	ret

.unsigned_divmod:
	call .make_eax_ecx_unsigned

	push edx
	xor edx,edx
	or ecx,ecx
	jz .no_unsigned_divmod
	div ecx
.no_unsigned_divmod:

	cmp ebp,8
	je .notunsmod

	mov eax,edx
.notunsmod:
	pop edx
	ret

uvard lastcalcresult

// get the "other" variable for random 83 or variational 82
// in:	esi=vehicle/station
//	ecx=grf feature
// out:	esi=other variable
// safe:ecx edx
grfcalltable getother

.gettrains:
.getrvs:
.getships:
.getplanes:
	movzx esi,word [esi+veh.engineidx]
	shl esi,vehicleshift
	add esi,[veharrayptr]
	ret

.getstations:
	mov esi,[esi+station.townptr]
	ret

.getcanals:
.getbridges:
.getgeneric:
.getcargos:
.getsounds:
	ret

.gethouses:
	pusha
	mov ebp,[ophandler+(3*8)]
	xor ebx,ebx
	mov bl,1
	mov eax,esi
	call dword [ebp+4]
	mov [esp+4],edi		// will be popped to esi
	popa
	ret

.getindustiles:
	movzx esi,byte [landscape2+esi]
	imul esi,industry_size
	add esi,[industryarrayptr]
	ret

.getindustries:
	mov esi,[esi+industry.townptr]
	ret

#if MEASUREVAR40X
	// this measures the number of CPU ticks spent for calculating
	// each feature's 40+x in total, compared to the rest of the game
uvard tscvalid
uvard lasttsc,2
uvard tscvar

uvard tscdatabegin,0

#define NUMCALLBACKS 0x34
uvard numtscfeat
uvard numtsccb
uvard numticks,((NUMFEATURES+1)*2)*2
uvard numcalls,(NUMFEATURES+1)*2
uvard cbticks,NUMCALLBACKS*2
uvard varticks,NUMFEATURES*0x40*2
uvard numcb,NUMCALLBACKS
uvard numvar,NUMFEATURES*0x40

uvard tscdataend,0

checktsc:
	push eax
	push ebx
	push edx

	cpu 586
	rdtsc
	cpu 386

	bts dword [tscvalid],0
	jc .wasvalid

	mov [lasttsc],eax
	mov [lasttsc+4],edx

.wasvalid:
	xchg eax,[lasttsc]
	xchg edx,[lasttsc+4]

	sub eax,[lasttsc]
	sbb edx,[lasttsc+4]

	cmp dword [tscvar],0
	jns .isvar

	sub [numticks+(ecx+1)*8],eax
	sbb [numticks+(ecx+1)*8+4],edx

	inc dword [numcalls+(ecx+1)*4]

	test ecx,ecx
	js .done

	movzx ebx,byte [curcallback]

	sub [cbticks+ebx*8],eax
	sbb [cbticks+4+ebx*8],edx
	inc dword [numcb+ebx*4]
	jmp short .done

.isvar:
	shrd ebx,ecx,32-5
	js .done

	and ebx,byte ~0x3f	// ebx = ecx/2 * 0x40
	add ebx,[tscvar]

	sub [varticks+ebx*8],eax
	sbb [varticks+ebx*8+4],edx
	inc dword [numvar+ebx*4]

.done:
	pop edx
	pop ebx
	pop eax
	ret

var tscname, db "tsc_####.dat",0
uvard tscdumpnum

savevar40x:
	pusha
	cmp dword [tscvalid],0
	je near .fail
	mov dword [numtscfeat],NUMFEATURES
	mov dword [numtsccb],NUMCALLBACKS
.nextnum:
	mov eax,[tscdumpnum]
	inc dword [tscdumpnum]
	cmp eax,0xffff
	ja .fail

	mov ecx,eax
	and ecx,0x0f0f
	shr eax,4
	and eax,0x0f0f

	mov edx,tscname
	mov ebx,hexdigits
	xlatb
	mov [edx+4+2],al
	mov al,ah
	xlatb
	mov [edx+4+0],al
	mov al,cl
	xlatb
	mov [edx+4+3],al
	mov al,ch
	xlatb
	mov [edx+4+1],al

	mov ax,0x3c00
	xor ecx,ecx
	CALLINT21
	jc .nextnum

	mov ebx,eax
	mov ax,0x4000
	mov edx,tscdatabegin
	mov cx,tscdataend - tscdatabegin
	CALLINT21

	mov ax,0x3e00
	CALLINT21

.fail:
	mov edi,tscvalid
	mov ecx,(tscdataend-tscvalid)/4
	xor eax,eax
	rep stosd
	popa
	ret
#endif

// get special variable for variational sprites
//
// in:	eax=special variable (+0x40)
//	esi=struct or 0 if none
// out:	eax=variable content
// safe:ecx
getspecialvar:
	sub eax,0x40
	movzx ecx,byte [grffeature]
	cmp al,0x1f
	je .getrandomtriggers

	shl ecx,1
	add cl,[isother]
	cmp al,[specialvars+ecx]
	jae .done

#if MEASUREVAR40X
	push ecx
	or ecx,byte -1
	mov [tscvar],eax
	call checktsc
	mov ecx,[esp]
#else
	cmp cl,4*2
	jb .specialvehvar	// special case because veh vars are cached
//	je .specialstatvar	// so are station variables (soon)
#endif

	mov ecx,[specialvarhandlertable+ecx*4]
	call [ecx+eax*4]

#if MEASUREVAR40X
	pop ecx
	call checktsc
#endif

.done:
	ret

.specialvehvar:
	bt [cachevehvar40x],eax
	jc .cachedvar
	call [vehvarhandler+eax*4]
	ret

.cachedvar:
	mov ecx,[esi+veh.veh2ptr]
	mov eax,[ecx+veh2.var40x+eax*4]
	ret

.getrandomtriggers:
	jmp [getrandombits+ecx*4]

// get special parametrized variable for variational sprites
//
// in:	eax=special variable
//	cl=parameter
//	esi->struct
// out:	eax=variable content
// safe: ecx
getspecparamvar:
	sub eax,0x60
	cmp al,0x1f
	je .grfparam

	mov ah,cl
	movzx ecx,byte [grffeature]
	shl ecx,1
	add cl,[isother]
	cmp al,[specialparamvars+ecx]
	jae .done

	push eax
	movzx eax,al

#if MEASUREVAR40X
	push ecx
	lea ecx,[eax+020]
	mov [tscvar],ecx
	or ecx,byte -1
	call checktsc
	mov ecx,[esp]
#endif
	mov ecx,[specialparamvarhandlertable+ecx*4]
	mov ecx,[ecx+eax*4]
	pop eax
	call ecx
#if MEASUREVAR40X
	pop ecx
	call checktsc
#endif

.done:
	ret

.grfparam:
	movzx ecx,cl
	mov eax,[mostrecentspriteblock]
	cmp cl,[eax+spriteblock.numparam]
	jae .noparam
	mov eax,[eax+spriteblock.paramptr]
	mov eax,[eax+ecx*4]
	ret

.noparam:
	xor eax,eax
	ret


// The following tables have two entries per feature, the first for the default thing, the second for "the other"

	// offsets into the base struc ptr to the place where the
	// variational variables start, for each feature
var featurevarofs
	db -0x80, -0x80		// four vehicle types; the "other thing" is a vehicle as well
	db -0x80, -0x80
	db -0x80, -0x80
	db -0x80, -0x80
	db -0x80+0x10, -0x80	// stations: skip up to .platforms for the station structure; don't do this with the town struc
	db -0x80, 0		// canals don't have "other things"
	db 0, 0			// bridges don't use action 2 at all
	db 0, -0x80		// houses; they don't have a normal struc, but have a town struc for "the other thing"
	db 0, 0			// generic callbacks don't use action 2
	db 0, -0x80		// industry tiles are like houses, but "the other thing" is an industry struc
	db -0x80, -0x80		// industry struc; town struc
	db 0, 0			// cargos don't have structures
	db 0, 0			// sounds neither

	align 4

	// list of handlers for each variable
var vehvarhandler
	dd addr(getvehnuminconsist)
	dd addr(getvehnuminrow)
	dd addr(getconsistcargo)
	dd addr(getplayerinfo)
	dd addr(getaircraftinfo)
	dd addr(getcurveinfo)
	dd addr(getmotioninfo)
	dd addr(getvehiclecargo)
%ifndef PREPROCESSONLY
%assign n_vehvarhandler (addr($)-vehvarhandler)/4
%endif

var vehparamvarhandler
	dd addr(getvehidcount)
%ifndef PREPROCESSONLY
%assign n_vehparamvarhandler (addr($)-vehparamvarhandler)/4
%endif


var stationvarhandler
	dd addr(getplatforminfo)
	dd addr(getstationsectioninfo)
	dd addr(getstationterrain)
	dd addr(getplayerinfo)
	dd addr(getstationpbsstate)
	dd addr(gettrackcont)
	dd addr(getplatformmiddle)
	dd addr(getstationsectionmiddle)
	dd addr(getstationacceptedcargos)
	dd addr(getplatformdirinfo)
%ifndef PREPROCESSONLY
%assign n_stationvarhandler (addr($)-stationvarhandler)/4
%endif

var stationparamvarhandler
	dd addr(getcargowaiting)
	dd addr(getcargotimesincevisit)
	dd addr(getcargorating)
	dd addr(getcargoenroutetime)
	dd addr(getcargolastvehdata)
%ifndef PREPROCESSONLY
%assign n_stationparamvarhandler (addr($)-stationparamvarhandler)/4
%endif

var canalsvarhandler
%ifndef PREPROCESSONLY
%assign n_canalsvarhandler (addr($)-canalsvarhandler)/4
%endif

var canalsparamvarhandler
%ifndef PREPROCESSONLY
%assign n_canalsparamvarhandler (addr($)-canalsparamvarhandler)/4
%endif

var housesvarhandler
	dd addr(gethousebuildstate)
	dd addr(gethouseage)
	dd addr(gethousezone)
	dd addr(gethouseterrain)
	dd addr(gethousecount)
	dd addr(getexpandstate)
	dd addr(gethouseanimframe)
%ifndef PREPROCESSONLY
%assign n_housesvarhandler (addr($)-housesvarhandler)/4
%endif

var housesparamvarhandler
	dd addr(getotherhousecount)
	dd addr(getothernewhousecount)
%ifndef PREPROCESSONLY
%assign n_housesparamvarhandler (addr($)-housesparamvarhandler)/4
%endif

var industilesvarhandler
	dd addr(getindustileconststate)
	dd addr(gethouseterrain)
	dd addr(gethousezone)
	dd addr(getindustilepos)
	dd addr(getindustileanimframe)
%ifndef PREPROCESSONLY
%assign n_industilesvarhandler (addr($)-industilesvarhandler)/4
%endif

var industilesparamvarhandler
	dd addr(getindustilelandslope)
%ifndef PREPROCESSONLY
%assign n_industilesparamvarhandler (addr($)-industilesparamvarhandler)/4
%endif

var townvarhandler
	dd addr(getistownlarger)	// in newhouse.asm
	dd addr(gettownnumber)		// in newhouse.asm
%ifndef PREPROCESSONLY
%assign n_townvarhandler (addr($)-townvarhandler)/4
%endif

var townparamvarhandler
%ifndef PREPROCESSONLY
%assign n_townparamvarhandler (addr($)-townparamvarhandler)/4
%endif

var industryvarhandler
	dd addr(getincargo)
	dd addr(getincargo)
	dd addr(getincargo)
%ifndef PREPROCESSONLY
%assign n_industryvarhandler (addr($)-industryvarhandler)/4
%endif

var industryparamvarhandler
%ifndef PREPROCESSONLY
%assign n_industryparamvarhandler (addr($)-industryparamvarhandler)/4
%endif

var specialvarhandlertable
	dd vehvarhandler,vehvarhandler
	dd vehvarhandler,vehvarhandler
	dd vehvarhandler,vehvarhandler
	dd vehvarhandler,vehvarhandler
	dd stationvarhandler,townvarhandler
	dd canalsvarhandler,0
	dd 0,0
	dd housesvarhandler, townvarhandler
	dd 0,0
	dd industilesvarhandler, industryvarhandler
	dd industryvarhandler,townvarhandler
	dd 0,0
	dd 0,0

checkfeaturesize specialvarhandlertable, (4*2)

	// number of special variables defined in each feature class
var specialvars
%ifndef PREPROCESSONLY
	db n_vehvarhandler,n_vehvarhandler
	db n_vehvarhandler,n_vehvarhandler
	db n_vehvarhandler,n_vehvarhandler
	db n_vehvarhandler,n_vehvarhandler
	db n_stationvarhandler,n_townvarhandler
	db n_canalsvarhandler,0
	db 0,0
	db n_housesvarhandler,n_townvarhandler
	db 0,0
	db n_industilesvarhandler,n_industryvarhandler
	db n_industryvarhandler,n_townvarhandler
	db 0,0
	db 0,0
%endif

checkfeaturesize specialvars, (1*2)

var specialparamvarhandlertable
	dd vehparamvarhandler,vehparamvarhandler
	dd vehparamvarhandler,vehparamvarhandler
	dd vehparamvarhandler,vehparamvarhandler
	dd vehparamvarhandler,vehparamvarhandler
	dd stationparamvarhandler,townparamvarhandler
	dd canalsparamvarhandler,0
	dd 0,0
	dd housesparamvarhandler, townparamvarhandler
	dd 0,0
	dd industilesparamvarhandler, industryparamvarhandler
	dd industryparamvarhandler,townparamvarhandler
	dd 0,0
	dd 0,0

checkfeaturesize specialparamvarhandlertable, (4*2)

	// number of special variables defined in each feature class
var specialparamvars
%ifndef PREPROCESSONLY
	db n_vehparamvarhandler,n_vehparamvarhandler
	db n_vehparamvarhandler,n_vehparamvarhandler
	db n_vehparamvarhandler,n_vehparamvarhandler
	db n_vehparamvarhandler,n_vehparamvarhandler
	db n_stationparamvarhandler,n_townparamvarhandler
	db n_canalsparamvarhandler,0
	db 0,0
	db n_housesparamvarhandler,n_townparamvarhandler
	db 0,0
	db n_industilesparamvarhandler,n_industryparamvarhandler
	db n_industryparamvarhandler,n_townparamvarhandler
	db 0,0
	db 0,0
%endif

checkfeaturesize specialparamvars, (1*2)
