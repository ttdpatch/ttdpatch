
// Multi-headed engines

#include <std.inc>
#include <veh.inc>
#include <flags.inc>
#include <proc.inc>
#include <human.inc>
#include <ptrvar.inc>
#include <newvehdata.inc>

extern articulatedvehicle,callbackflags,cargounitweightsptr,checkoverride
extern ctrlkeystate,curplayerctrlkey,freightweightfactor,generatesoundeffect
extern isengine,isfreightmult,ishumanplayer,isrealhumanplayer,lastdetachedveh
extern miscgrfvar,moresteamsetting,mountaintypes,multihdspeedup,numheads
extern patchflags,randomfn,reversearticulatedloco
extern trainweight,veh2ptr,vehcallback,wagonoverride
extern wagonspeedlimitempty,newvehdata,sellcost
extern GetTrainCallbackSpeed.lmultihead




lastheadaddspower equ 4		// after this many heads, speed doesn't increase
addpowerbase equ (1 << (lastheadaddspower-1))-1

	// calculate the power and speed of a train,
	// allowing multi-head configs
	//
	// in:	esi=vehicle
	// out: (set esi+veh.realpower and esi+veh.maxspeed),eax=real power
	// safe:eax,ebx,edx must be
extern TrainPowerGeneric.leax, TrainPowerGeneric.lecx
global calcpowerandspeed
proc calcpowerandspeed
	local enginepower,newpower,newspeed,engines,speedlimit,curvehspeed

	_enter

	push edi
	mov edi,trainpower
	movzx eax,word [esi+veh.vehtype]
	call TrainPowerGeneric.leax
;	movzx eax,word [edi+eax*2]
	mov [%$enginepower],eax

	xor eax,eax
	mov [%$newpower],eax
	mov [%$engines],eax

	dec eax
	mov [%$newspeed],eax
	mov [%$speedlimit],eax

	// calculate by how much we need to adjust the speed of
	// normally dual-headed engines
	//
	// newspeed is lowest speed * 65536
	//

	mov eax,100*addpowerbase
	push eax

	movzx ebx,byte [multihdspeedup]
	lea ebx,[ebx*4+eax]
	xor edx,edx

	shl eax,16
	idiv ebx

	// now eax=fraction of 65536 that we for dual-headed engines

	push esi

.nextvehicle:
	movzx ebx,word [esi+veh.vehtype]

	call GetTrainCallbackSpeed.lmultihead
;	movzx ecx,word [trainspeeds+ebx*2]

	mov [%$curvehspeed],ecx

	call TrainPowerGeneric.lecx
;	movzx ecx,word [edi+ebx*2]
	or ecx,ecx
	jnz near .engine

	and byte [esi+veh.modflags],~(1<<MOD_POWERED)

	cmp dword [%$curvehspeed],0
	je .havespeedlimit

	cmp word [esi+veh.currentload],1
	sbb cl,cl	// 0 if full, -1 if empty
	and cl,[wagonspeedlimitempty]
	movzx ecx,cl

	add [%$curvehspeed],ecx

	testmultiflags wagonspeedlimits
	jnz .havespeedlimit

	and dword [%$curvehspeed],0

.havespeedlimit:
	// it might be a powered wagon if we have a graphics override for this engine
	cmp byte [wagonoverride+ebx],1
	jne .checklimit

	pop ebx		// first vehicle in consist
	push ebx
	movzx ebx,word [ebx+veh.vehtype]
	movzx ecx,word [trainwagonpower+ebx*2]

	push eax
	push ecx
	movzx eax,word [esi+veh.vehtype]
	call checkoverride
	jc .checklimitpop	// no override -> not powered, has speed limit

	// has override, so it has no speed limit, and might have power
	// so property 1B says it should be powered, however if prop. 22 or
	// callback 10 is 40, this particular wagon is not powered actually

	movzx ebx,word [esi+veh.vehtype]
	test byte [callbackflags+ebx],1
	jz .noeffectcallback

	mov eax,[esi+veh.veh2ptr]
	mov al,[eax+veh2.viseffect]
	jmp short .haveviseffect

.noeffectcallback:
	mov al,[trainviseffect+ebx]

.haveviseffect:
	test al,al
	pop ecx			// if we get here, the wagon has no speed limit
	pop eax			// check whether it has power or not
	js .nopower		// no power (bit 7 from prop 22/callback 10)
	jecxz .nopower		// no power (prob 1B is zero)
	jmp short .gotpower	// has power

.checklimitpop:
	pop ecx
	pop eax

.checklimit:
	// check speed limit for wagons without graphics override
	mov ebx,[%$curvehspeed]
	test ebx,ebx
	jz .nopower

	cmp [%$speedlimit],ebx
	jbe .nopower

	mov [%$speedlimit],ebx
	jmp short .nopower

.engine:
	inc byte [%$engines]

	movzx edx,byte [esi+veh.tracktype]
	bts [%$engines+2],edx

	test byte [numheads+ebx],1
	mov ebx,[%$curvehspeed]

	mov edx,0x10000
	jz short .defaultonehead
	shr ecx,1	// has by two heads by default, adjust.

	// ebx is default speed, and by multihdspeedup*4/7 too high

	mov edx,eax

.defaultonehead:
	imul ebx,edx

	cmp [%$newspeed],ebx	// and find lowest speed
	jb .gotpower
	mov [%$newspeed],ebx

.gotpower:
	add [%$newpower],ecx	// add to power
	or byte [esi+veh.modflags],1<<MOD_POWERED
	jmp short .setpower

.nopower:
	xor ecx,ecx

.setpower:
	mov ebx,[esi+veh.veh2ptr]
	mov [ebx+veh2.power],cx

.getnextveh:
	movzx esi,word [esi+veh.nextunitidx]
	cmp si,byte -1
	je short .havetraininfo
	shl esi,byte vehicleshift
	add esi,[veharrayptr]

	cmp byte [esi+veh.artictype],0xfd	// articulated (can be all but first vehicle)
	jb .nextvehicle
	je .reversed
	jmp .getnextveh

.reversed:
	movzx ecx,word [esi+veh.nextunitidx]
	cmp cx,byte -1
	je .nextvehicle		// was the last articulated piece = the real engine
	shl ecx,7
	add ecx,[veharrayptr]
	cmp byte [ecx+veh.artictype],0xfd
	jb .nextvehicle		// same
	mov esi,ecx
	jmp .reversed

.havetraininfo:
	pop esi
	pop ecx

	// find out if train is mixed power train
	mov ah,[%$engines+2]
	mov al,0
.nexttype:
	shr ah,1
	adc al,0
	test ah,ah
	jnz .nexttype

.gottypes:
	cmp al,1
	seta al
	mov ebx,[esi+veh.veh2ptr]
	and byte [ebx+veh2.flags],~(1<<VEH2_MIXEDPOWERTRAIN)
	or [ebx+veh2.flags],al

	mov eax,[%$newspeed]	// Note: newspeed is *10000h

	testmultiflags multihead	// don't modify speed if multihead is off
	jz .nospeedadjust

	push ecx

	mov cl,lastheadaddspower
	sub cl,[%$engines]

	jnb short .good

	mov cl,0

.good:
		// edi = addpowerbase minus one bits for each engine not added
	mov edi,addpowerbase
	shr edi,cl
	shl edi,cl	// now edi=0, 4, 6, 7 for 1, 2, 3, 4 or more engines


	movzx edx,byte [multihdspeedup]
	imul edi,edx

	pop ecx		// =addpowerbase*100

	add edi,ecx	// now edi=addpowerbase*100%+(0..addpowerbase)*multihdspeedup

	imul edi	// i.e. edi=addpowerbase times the speed percentage

		// check for overflow
		// Augh, overflow happens if edx>ecx/2 b/o sign bit
	mov ebx,ecx
	shr ebx,1
	adc ebx,byte 0	// round up
	cmp edx,ebx
	jb short .nottoofast

	lea edx,[ebx-1]
	or eax,byte -1

.nottoofast:
	idiv ecx		// and divide by 700 to get the actual speed

.nospeedadjust:
	shr eax,16
	adc ax,0		// round up, but only 16 bits so that the right sign bit is checked
	jns short .nottoobig
	mov ax,0x7fff

.nottoobig:
	mov ebx,[%$speedlimit]
	cmp ax,bx
	jbe .nolimit

	mov ax,bx

.nolimit:
	mov [esi+veh.maxspeed],ax

	mov eax,[%$newpower]
	mov edi,[esi+veh.veh2ptr]
	mov [edi+veh2.realpower],eax
	pop edi
	_ret
endproc calcpowerandspeed

	// called to calculate the weight of one vehicle
	//
	// in:	esi->vehicle
	//	on stack: engine
	// out:	eax=weight (limited to 7fff)
	//	also sets veh2 stuff
	// uses:eax ebx
extern TrainTEGeneric.lebx
global calcvehweight
calcvehweight:
	movzx eax,word [esi+veh.currentload]
	test eax,eax
	jz .nocargo

	movzx ebx,byte [esi+veh.cargotype]
	bt [isfreightmult],ebx
	jnc .notfreight

	push dword [esi+veh.owner-1]
	mov byte [esp],PL_PLAYER + PL_NOTTEMP
	call ishumanplayer
	jnz .notfreight

	mov bl,[freightweightfactor]
	imul eax,ebx
	mov bl,[esi+veh.cargotype]

.notfreight:
	add ebx,[cargounitweightsptr]
	movzx ebx,byte [ebx]

	imul eax,ebx
	shr eax,4

.nocargo:
	cmp byte [esi+veh.subclass],0
	je .notartic
	cmp byte [esi+veh.artictype],0xfe
	jb .notartic
	ret

.notartic:
	movzx ebx,byte [esi+veh.vehtype]

	test byte [esi+veh.modflags],1<<MOD_POWERED
	jz .notpoweredwagon

	bt [isengine],ebx
	jc .notpoweredwagon	// it's an actual engine, not a wagon

	// wagon is powered, find out how much weight this adds

	mov ebx,[esp+4]	// engine of the consist
	movzx ebx,byte [ebx+veh.vehtype]

	mov bl,[trainwagonpowerweight+ebx]
	add eax,ebx

	mov bl,[esi+veh.vehtype]

.notpoweredwagon:
//	add ebx,[enginepowerstable]
;	add al,[trainweight+ebx]
;	movzx ebx,byte [esi+veh.vehtype]
;	adc ah,[railvehhighwt+ebx]
	
	push ecx
extern TrainWeightGeneric
	call TrainWeightGeneric
	add eax, ecx
	pop ecx
	
	mov ebx, eax

	// calculate the tractive effort this vehicle provides
	test byte [esi+veh.modflags],1<<MOD_POWERED
	jnz .ispowered

	xor ebx,ebx
	jmp short .no_te

.ispowered:
	push ebx
;	mov [esp-4],ebx
	movzx ebx,byte [esi+veh.vehtype]
	call TrainTEGeneric.lebx
;	mov bl,[traintecoeff+ebx]
	imul ebx,10	// gravity
	imul ebx,[esp]
	shr ebx,8
	add esp,4

.no_te:
	push bx
	mov ebx,[esi+veh.veh2ptr]
	pop word [ebx+veh2.te]

	cmp eax,0x7fff
	jbe .nottooheavy

	mov eax,0x7fff

.nottooheavy:
	ret

	// calculate the weight of the consist
	// also stores individual vehicle weights, except for engine
	// if realistic acceleration is off
	//
	// in:	esi->engine
	// out: ebp=consist weight, limited to 7fff
	// safe:ebx esi
global calcconsistweight
calcconsistweight:
	push esi
	xor ebp,ebp
.nextwagon:
	movzx esi,word [esi+veh.nextunitidx]
	cmp si,byte -1
	je .doengine
	shl esi,7
	add esi,[veharrayptr]
	call calcvehweight
	add ebp,eax
	push esi
	mov esi,[esi+veh.veh2ptr]
	mov [esi+veh2.fullweight],ax
	pop esi
	jmp .nextwagon

.doengine:
	pop esi
	call calcvehweight
	add ebp,eax

	movzx ebx,byte [esi+veh.tracktype]
	cmp byte [mountaintypes+ebx],3
	jne .notrealistic

	mov ebx,[esi+veh.veh2ptr]
	mov [ebx+veh2.fullweight],ax

.notrealistic:
	cmp ebp,0x7fff
	jbe .nottooheavy

	mov ebp,0x7fff

.nottooheavy:
	ret

	// called to calculate the acceleration, depending on weight
	//
	// in:	esi=vehicle
	//	ebp=weight
	//
	// out:	(set esi.accel)
	// safe:eax,ebx,ebp
global calcaccel
calcaccel:
	call calcpowerandspeed

	movzx edx,byte [esi+veh.tracktype]
	cmp byte [mountaintypes+edx],3
	je .done

	xor edx,edx
	or ebp,ebp
	jz short .baddivision
	div ebp
	shl eax,2
	jnz short .goodaccel
	add eax,byte 1
.goodaccel:
	cmp eax,0xffff
	jb short .nottoolarge
	mov eax,0xffff
.nottoolarge:
	mov edx,[esi+veh.veh2ptr]
	mov word [edx+veh2.fullaccel],ax
	cmp ax,0xff
	jb short .nottoolargeforabyte
	mov ax,0xff
.nottoolargeforabyte:
	mov byte [esi+veh.acceleration],al
.baddivision:

.done:
	ret

	//
	// called when buying new rr vehicle. checks if
	// vehicle type is bought as an engine
	//
	// in:	eax=class
	//	 bx=engine type
	// out:	cf if waggon
	// safe:eax,ecx
global checknewtrainisengine
checknewtrainisengine:
	bt [isengine],bx
	jnc .isgood

	cmp byte [forceextrahead],1
	jae .isextrahead

	// so in theory it's an engine. check ctrl
	// why doesn't this check [curplayerctrlkey]?
	push byte CTRL_ANY+CTRL_MP	// this is a window handler, we know we're the human player 1
	call ctrlkeystate
	stc
	jnz short .isgood

	// ok, so ctrl is pressed -> treat it as a waggon
	testflags multihead	// but only if the multihead option is on (see patches.ah)
.isextrahead:
	cmc
.isgood:
	ret

uvarb forceextrahead
uvarb forcenoextrahead
; endp checknewtrainisengine

	// called when attaching a waggon
	// check if current vehicle is the second head of a train engine
	// (which it can only be if multihead is off)
	//
	// in:	esi=sprite type
	//	edi=vehicle
	// out:	zero flag if not second head
	// safe:eax esi edi
	//
global attachwaggon
attachwaggon:
	cmp byte [edi+veh.artictype],0xfd
	ja .done
	cmc
	je .done

	xchg eax,esi
	cmp al,0xfd	// fd=first head, fe="reversed" head, ff=second head
	jnb .gotit

	cmp word [dword eax+1],0
ovar railvehspriteofs, -5

.gotit:
	jz .notsecondhead

	// looks like a second head
	call isrealhumanplayer
	jnz .notsecondhead		// AIs never buy the second head separately

	// is multihead on?
	testflags multihead

	// now if carry we set zero; otherwise we clear zero
	cmc
.done:
	sbb al,al

.notsecondhead:
	ret
; endp attachwaggon


uvard enginesalestage

	// called when detaching wagons from engine that is to be sold
	// everything that isn't detached will be sold with the engine
	//
	// in:	eax=veh idx<<7
	// out:	eax->veh
	//	dx=nextunitidx
	//	carry flag if vehicle should be sold instead of detached
	// safe:bl cx esi
global detachfromsoldengine
detachfromsoldengine:
	xor esi,esi
	xchg esi,[lastdetachedveh]
	test esi,esi
	jz .nolastveh

	mov eax,esi
	jmp short .isadded

.nolastveh:
	add eax,[veharrayptr]
.isadded:
	mov di,[eax+veh.idx]
	mov dx,[eax+veh.nextunitidx]

	cmp byte [eax+veh.artictype],0xfd
	je .newartichead	// counts as engine even if it isn't one
	jb .notarticpiece

	// sell articulated pieces belonging to the first loco
	// and, if it's multiheaded, any possible second loco
	cmp byte [enginesalestage],0
	jne .notsold
	jmp short .sold

.newartichead:
	mov byte [enginesalestage],1
	jmp short .engine

.notarticpiece:
	movzx esi,byte [eax+veh.vehtype]
	bt [isengine],esi
	jnc .notsold

.engine:
	movzx ecx,word [eax+veh.engineidx]
	shl ecx,7
	add ecx,[veharrayptr]
	movzx esi,byte [ecx+veh.vehtype]

	cmp byte [eax+veh.artictype],0xfd
	je .rightengine

	cmp si,[eax+veh.vehtype]
	jne .notsold

.rightengine:
	inc byte [enginesalestage+1]
	mov cl,[enginesalestage+1]

//	add esi,[enginepowerstable]
	mov ch,[numheads+esi]
	and ch,1
	cmp cl,ch
	ja .notsold

	mov byte [enginesalestage],0

.sold:
	mov esi,[eax+veh.value]
	add [sellcost],esi
	mov bl,-1
	jmp short .done

.notsold:
	mov bl,0

.done:
	cmp dx,byte -1
	jne .notlast

	and dword [enginesalestage],0

.notlast:
	add bl,1
	ret


	//
	// called when buying new rr vehicle, checks whether
	// it's a waggon or an engine (in the action handler)
	//
	// in:	edx=engine type
	// out:	zr if waggon
	// safe:-
global checknewtrainisengine2
checknewtrainisengine2:
	bt [isengine],edx
	jc .isengine

	// it's a waggon
.wagon:
	cmp eax,eax		// force zf=1
	ret

.isengine:
	// check whether it's the second piece of an articulated engine
	cmp dword [articulatedvehicle],0
	jne .wagon

	cmp byte [forceextrahead],1
	jae .wagon

	testflags multihead
	jc .checkctrl

	// multihead not enabled, must be an engine
	cmp edx,byte -1		// can't be equal -> NZ
	ret

.checkctrl:
	cmp byte [curplayerctrlkey],1
	ret
; endp checknewtrainisengine2

	// called when trying to sell a vehicle
	//
	// in:	edx->vehicle
	//	bp=vehtype
	// out:	carry set if can't sell it (an engine) or clear if can sell (wagon)
	// safe:al esi edi
global selliswagon
selliswagon:
	testflags multihead
	sbb al,al
	jnc .cantsellarticdualhead

	cmp byte [edx+veh.artictype],0xfd
	je .done			// is second head of articulated engine

.cantsellarticdualhead:
	cmp byte [edx+veh.subclass],4
	je .done	// can always sell first wagon on a row, no matter what (as safety net)

	cmp byte [edx+veh.artictype],0xf0
	cmc
	jc .done			// is engine -> can't sell

	sub al,1			// now carry clear if multihead is on
	jnc .done			// is "wagon" -> can sell

	bt [isengine],bp

.done:
	ret

	// called when AI picks next vehicle to sell
	//
	// in:	esi->list of veh IDs
	// out:	dx=veh ID to sell
	//	zf if done
	// safe:edx
global aisellnextwagon
aisellnextwagon:
	movzx edx,word [esi]
	cmp dx,byte -1
	je .done

	shl edx,7
	add edx,[veharrayptr]
	cmp byte [edx+veh.class],0	// sold already (dual head)?
	je .done

	mov dx,[edx+veh.idx]

.done:
	ret

	// called when waggons are reordered, attaching veh in edi after veh idx dx
	// in:	edi=vehicle idx<<7
	//	 dx=veh idx to be attached after edi
	// out:	return regularly if it's a waggon, otherwise do a special jmp
	// safe:eax edx
global movedcheckiswaggon
movedcheckiswaggon:
	add edi,[veharrayptr]
	push ebx

.trynext2:
	movzx eax,dx
	cmp ax,byte -1
	je .notarticulated
	shl eax,7
	add eax,[veharrayptr]

	// are we trying to attach after articulated dual head piece?
	cmp byte [eax+veh.artictype],0xfd
	jb .trynext	// no, not part of an articulated engine
	cmp byte [eax+veh.artictype],0xfe
	ja .trynext	// no, not a dual head piece

	// attach after vehicle before it instead
	mov bx,[eax+veh.idx]
	movzx eax,word [eax+veh.engineidx]
.findbefore:
	mov dx,ax
	shl eax,7
	add eax,[veharrayptr]
	cmp [eax+veh.nextunitidx],bx
	je .trynext2
	movzx eax,word [eax+veh.nextunitidx]
	jmp .findbefore

	// can't add after this vehicle (idx in dx) if part of an articulated
	// engine follows it either (can't break it up)
.trynext:
	movzx eax,word [eax+veh.nextunitidx]
	cmp ax,byte -1
	je .notarticulated
	shl eax,7
	add eax,[veharrayptr]

	cmp byte [eax+veh.artictype],0xff
	jb .notarticulated

	mov dx,[eax+veh.idx]
	jmp .trynext

	// nor can the current vehicle (in edi) be moved if it is part
	// of an articulated engine
.notarticulated:
	cmp byte [edi+veh.artictype],0xfd
	jb .stillnotartic

	// try moving the first engine piece instead
	mov bx,[edi+veh.idx]
	movzx eax,word [edi+veh.engineidx]
	xor edi,edi

.checknext:
	shl eax,7
	add eax,[veharrayptr]

	cmp byte [eax+veh.artictype],0xfe
	jae .cantmovethis

	mov edi,eax

.cantmovethis:
	movzx eax,word [eax+veh.nextunitidx]
	cmp ax,byte -1
	je near .reallyisengine	// couldn't find a piece to move

	cmp ax,bx
	jne .checknext

	test edi,edi
	jz near .reallyisengine

.stillnotartic:
	movzx eax,word [edi+veh.vehtype]
	bt [isengine],eax
	jc .isengine

.iswaggon:
	mov ebx,edi
.next:
	cmp dx,[ebx+veh.idx]		// moving vehicle after itself?
	je near .reallyisengine
	movzx ebx,word [ebx+veh.nextunitidx]
	cmp bx,byte -1
	je .done
	shl ebx,7
	add ebx,[veharrayptr]
	cmp byte [ebx+veh.artictype],0xfe
	jae .next
.done:
	pop ebx
	clc
	ret

.isengine:
	// it's an engine
	cmp dword [articulatedvehicle],0
	jne .iswaggon

	testflags multihead
	jnc .reallyisengine


	// first check if it is to be turned
	push esi
	movzx esi,word [edi+veh.vehtype]
//	add esi,dword [enginepowerstable]

	// Ctrl determines which way the engine faces
	mov al,[curplayerctrlkey]
	xor al,1
	mov ah,[trainsprite+esi]

	// if engine normally has two heads (or is a new sprite),
	// add 2 to sprite number
	// otherwise add 1 (always only if Ctrl key was pressed)
	cmp ah,0xfd
	jae .hasotherengine

	test byte [numheads+esi],1
	jz short .hasnootherengine

.hasotherengine:
	add al,al

.hasnootherengine:
	add ah,al
	cmp ah,[edi+veh.spritetype]
	je .sameorient

	movzx esi,word [edi+veh.nextunitidx]
	cmp si,byte -1
	je .simple
	shl esi,7
	add esi,[veharrayptr]
	cmp byte [esi+veh.artictype],0xfe
	jb .simple

	call reversearticulatedloco
	jmp short .sameorient

.simple:
	mov [edi+veh.spritetype],ah

.sameorient:
	pop esi

	cmp dword [edi+veh.scheduleptr],byte -1
	je .iswaggon

	// it's really an engine, can't be moved
.reallyisengine:
	pop ebx
	stc
	ret

; endp movedcheckiswaggon

	//
	// called when displaying the train info window
	//
	// in:	esi=engine
	// out:	eax=power
	// safe:-
global getoldpower
getoldpower:
	mov eax,[esi+veh.veh2ptr]
	mov eax,[eax+veh2.realpower]
	or eax,eax
	jnz .good

	movzx eax,word [esi+veh.vehtype]
//	shl eax,1
//	add eax,dword [enginepowerstable]
	call TrainPowerGeneric.leax
;	movzx eax,word [trainpower+eax*2]
.good:
	ret
; endp getoldpower


// Note: getrailvehiclebasevalue is a part of getvehiclebasevalue in servint.asm

// multiply EBX by EDX and shift the result to the right by 8 bits, overflow-safe
// destroys EDX
global imulebxedxshr8
imulebxedxshr8:
	xchg eax,ebx
	imul edx
	shrd eax,edx,8
	xchg ebx,eax
	ret
; endp imulebxedxshr8



// calculate train maintenance cost, allowing for multiple engines
// in:	esi=first engine
// out:	edx:eax=cost
global trainmaintcost
proc trainmaintcost
	local cost1,cost2

	_enter

	push esi
	and dword [%$cost1],byte 0
	and dword [%$cost2],byte 0
//	mov edi,dword [enginepowerstable]

.nextvehicle:
	cmp byte [esi+veh.subclass],0
	je .notwagon

	// articulated engine pieces don't cause extra running costs
	cmp byte [esi+veh.artictype],0xfe
	jae .notengine

.notwagon:
	movzx ebx,word [esi+veh.vehtype]
	bt dword [isengine],ebx
	jnc short .notengine

	push ecx
	movzx ecx, byte [trainrunningcost+ebx]

	mov al, cl		// Is variable running costs enabled?
	testflags vruncosts	// No so fall back on this value
	jnc .novruncosts

	mov al, bl
	mov ah, 0xD
	extcall GetCallback36

.novruncosts:
	movzx eax, al
	pop ecx

	mov dl,[numheads+ebx]

	mov ebx, [trainrunningcostbase+ebx*4]

	imul eax,dword [ebx]

	test dl,1
	jz short .onehead

	// two-heads have double the cost stored
	shr eax,1

.onehead:

	add [%$cost1],eax
	adc dword [%$cost2],byte 0

.notengine:
	movzx esi,word [esi+veh.nextunitidx]
	cmp si,byte -1
	je short .done
	shl esi,vehicleshift
	add esi,[veharrayptr]
	jmp .nextvehicle

.done:
	mov eax,[%$cost1]
	mov edx,[%$cost2]

	pop esi
	_ret
endproc // trainmaintcost

	// called when TTD decides what sound effect to play
	//
	// in:	esi=vehicle
	// out:	---
	// safe:eax ebx ecx edx edi ebp
global decidesound
decidesound:
	push eax
	movzx eax,word [esi+veh.vehtype]
	mov ah,[traintractiontype+eax]
	mov al,0

	cmp ah,8
	adc al,0
	cmp ah,0x32
	adc al,0
	cmp ah,0x38
	adc al,0

	mov ah,0
	// now eax=0 (Maglev), 1 (Monorail), 2 (Diesel/Electric), 3 (Steam)
	mov al,[deftrainstartsound+eax]
	mov byte [miscgrfvar],1
	call checksoundcallback
	pop eax
	ret

var deftrainstartsound, db 0x41,0x47,8,2

	// called when a train vehicle enters a tunnel
	// steam engines should blow their whistle
	//
	// in:	edi=vehicle
	// safe:?
global tunnelsound
tunnelsound:
	push eax
	push esi
	mov esi,edi
	movzx eax,word [esi+veh.vehtype]
	cmp byte [traintractiontype+eax],8
	sbb al,al
	and al,3	// steam: 3, other: 0 (none)
	mov byte [miscgrfvar],2
	call checksoundcallback
	pop esi
	pop eax
	ret


	// same for rvs
global rventertunnel
rventertunnel:
	mov byte [miscgrfvar],2
	push esi
	mov esi,edi
	xor eax,eax		// no default sound
	call checksoundcallback
	pop esi
	or ebx,0x40000000	// overwritten
	ret

	// play default or callback sound
	// in:	eax=default sound (0 if none)
	// 	esi->vehicle
	//	[grfmiscvar] set to sound event
	// uses:---	
checksoundcallback:
	push eax
	testmultiflags newsounds
	jz .nosoundcallback

	movzx eax,byte [esi+veh.vehtype]
	test byte [callbackflags+eax],0x80
	mov al,0x33
	jnz .dosoundcallback

.nosoundcallback:
	mov al, 2	// still have to set mostrecentspriteblock
.dosoundcallback:
	push esi
	call vehcallback
	pop esi
	jnc .gotsoundcallback

	mov eax,[esp]

.gotsoundcallback:
	test eax,eax
	jz .none

	push esi
	call [generatesoundeffect]
	pop esi

.none:
	mov byte [miscgrfvar],0
	pop eax
	ret


	// called when playing sound effect while a train is breaking down
	//
	// in:	esi->vehicle
	// out:	---
	// safe:ax ebx cx dl di ebp
global breakdownsound
breakdownsound:
	push eax
	movzx eax,byte [esi+veh.class]
	mov ax,[defbreakdownsounds+(eax-0x10)*2]
	cmp byte [climate],3
	jne .nottoyland
	mov al,ah
.nottoyland:
	mov ah,0
	mov byte [miscgrfvar],3
	call checksoundcallback
	pop eax
	ret

var defbreakdownsounds
	db 14,0x3a	// trains normal, trains toyland
	db 13,0x35	// rvs
	db 0,0		// nothing for planes
	db 14,0x3a	// ships

	// RV starting sound
	// in:	eax=default sound effect
	//	esi->vehicle
	// out:	(play sound effect)
	// safe:eax
global vehstartsound
vehstartsound:
	mov byte [miscgrfvar],1
	jmp checksoundcallback

global touchdownsound
touchdownsound:
	mov eax,0x15
	mov byte [miscgrfvar],5
	jmp checksoundcallback

exported helitakeoffsound
	mov eax,0x16
	mov byte [miscgrfvar],1
	jmp checksoundcallback

	// called when TTD is about to create a visual effect
	//
	// in:	esi->veh
	//	di=type (2=steam, 4=diesel, 6=electric)
	//	other regs as for class 14 function 4
	// out:	ebp=[ppOpClass14]
	// safe:ebx
global gentrainviseffect
gentrainviseffect:
	push eax
	xor eax,eax
	mov byte [miscgrfvar],6
	call checksoundcallback
	pop eax
	mov ebp,[ophandler+0x14*8]
	ret


	// called when TTD decides whether a train should
	// show steam, smoke or sparks
	//
	// in:	esi=first vehicle in consist
	// out:	esi
	//	carry must be set
	// safe:eax,ebx,(esi)
global decidesmoke
decidesmoke:
	bt word [esi+veh.vehstatus],4		// overwritten
	jnc .ok
	pop eax
	ret

.ok:
	push esi
	push edi
	mov edi,esi

.again:
	movzx ebx,word [esi+veh.vehtype]
	test byte [callbackflags+ebx],1
	jz .noeffectcallback

	mov eax,[esi+veh.veh2ptr]
	mov al,[eax+veh2.viseffect]
	jmp short .haveviseffect

.noeffectcallback:
	mov al,[trainviseffect+ebx]

.haveviseffect:
	and al,0x7f
	bt dword [isengine],ebx
	jc .haveeffect

	// for wagons, 00..0F counts as 40 (no effect) here
	cmp al,0x10
	jb .noeffect

.haveeffect:
	cmp al,0x40	// short-circuit this case
	jae .noeffect

	movzx ebx,word [esi+veh.engineidx]
	imul ebx,veh2_size
	add ebx,[veh2ptr]
	test byte [ebx+veh2.flags],1<<VEH2_MIXEDPOWERTRAIN
	jz .notmixed

	test byte [esi+veh.modflags],1<<MOD_NOTELECTRICHERE
	jnz .noeffect	// electric engine on non-electric track

.notmixed:

#if 0
	mov ah,[edi+veh.modflags]
	and ah,1<<MOD_SHOWSMOKE		// 1<<MOD_SHOWSMOKE is 16
	xor ah,(1<<(MOD_SHOWSMOKE+1))-1	// now 15 (under pressure) or 31 (normal)
	inc ah
	shl ah,7-MOD_SHOWSMOKE
	dec ah				// so that ah is either 63 (pressure) or 127 (normal)
#else
	// for now, always same amount of smoke, not doubled under pressure
	mov ah,(1<<7)-1
#endif

	push ecx
	mov cl,[moresteamsetting]	// x1=>31, x2=>15, x3=>7 etc.
	and cl,0x0f
	shr ah,cl
	pop ecx

	// is a train engine; show appropriate effect
	push edi
	call $+5
ovar showsteamsmoke,-4
	pop edi

.noeffect:
	movzx esi,word [esi+veh.nextunitidx]
	cmp si,byte -1
	je short .done

	shl esi,7
	add esi,[veharrayptr]
	jmp .again

.done:
	pop edi
	pop esi
	and byte [esi+veh.modflags],~(1<<MOD_SHOWSMOKE)
	stc
	ret
; endp steamsmoke


	// calculate position of steam plume
	//
	// in:	ax=x position of engine
	//	ebx=direction
	//	cx=y position of engine
	//	esi=>vehicle
	// out:	adjust ax,cx
	// safe:ebx dl di ebp
	//
global steamposition
steamposition:
	add ax,[traindiroffsets+ebx*4]
	add cx,[traindiroffsets+ebx*4+2]

	mov ebx,[trainvisoffsets+ebx*4]

	movzx ebp,word [esi+veh.vehtype]
	test byte [callbackflags+ebp],1
	jz .noeffectcallback

	mov ebp,[esi+veh.veh2ptr]
	movzx ebp,byte [ebp+veh2.viseffect]
	jmp short .haveviseffect

.noeffectcallback:
	movzx ebp,word [esi+veh.vehtype]
	movzx ebp,byte [trainviseffect+ebp]

.haveviseffect:
	and ebp,15
	sub ebp,4
	imul bx,bp
	sar bx,2
	add ax,bx
	shr ebx,16
	imul bx,bp
	sar bx,2
	add cx,bx
	ret

	align 4
var traindiroffsets
	dw 0,0,-4,0,-2,2, 0,4,  2,2,  4,0, 2,-2,0,0
var trainvisoffsets
	dw 3,3, 4,0, 3,-3,0,-4,-1,-1,-4,0,-3,3, 0,2


	// find out whether we should show diesel smoke
	//
	// in:	esi=vehicle
	//	edi=engine
	// out:	carry=do not smoke
global doesdieselsmoke
doesdieselsmoke:
	bt dword [edi+veh.modflags],MOD_SHOWSMOKE
	jc .gotit

	cmp word [edi+veh.speed],41
.gotit:
	cmc
	ret


	// calculate probability that an electric spark is emitted
	//
	// in:	same as above
	// out:	carry=do emit spark
global sparkprobab
sparkprobab:
	call [randomfn]
	test byte [edi+veh.modflags],1<<MOD_SHOWSMOKE
	jz .heavyduty

	cmp ax,0x5b0	// 2.22 % (regular)
	ret

.heavyduty:
	cmp ax,0x1c70	// 11.1 % (engine uses much power)
	ret


#if 0
// make the AI buy both heads of dual-headed engines
// but humans only the first head
// in:	EDI -> first head
//	EBX = vehicle type
// out:	ZF set = don't buy second engine
// safe:ESI
buysecondengine:
	call isrealhumanplayer
	jz .done

//	mov esi,[enginepowerstable]
	test byte [numheads+ebx],1

.done:
	ret
#endif
