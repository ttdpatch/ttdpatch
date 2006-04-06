//
// new vehicles sprite handlers
//

#include <std.inc>
#include <flags.inc>
#include <proc.inc>
#include <textdef.inc>
#include <vehtype.inc>
#include <veh.inc>
#include <station.inc>
#include <patchdata.inc>
#include <newvehdata.inc>
#include <grf.inc>
#include <ptrvar.inc>

extern cargoamountnnamesptr,cargoclass
extern cargotypes,deftwocolormaps,exscurfeature
extern exsdrawsprite,generatesoundeffect,getnewsprite,getrefitmask,grffeature
extern initrailvehsorttable,miscgrfvar,newvehdata,patchflags,randomtrigger
extern showvehinfo.callback,trainspritemove
extern trainuserbits,vehids,vehsorttable,vehvarhandler
extern wagonoverride,getvehiclecolors,getvehiclecolors_vehtype
extern isengine,checkoverride,newrefitvars,newcargounitweights

// called when TTD decides which sprite should be used for any
// particular type of orientation and spritenum of a ship
// in:	esi=vehicle
//	edi=sprite id
//	bx=direction
// out:	bx=sprite number
// safe:edi
global getshipsprite
getshipsprite:
	push 2		// feature 2=ships
	call getsprite1
	jnc .gotit

	add edi,[orgshipspritebase]
	add bx,[edi]
.gotit:
	pushf
	cmp esi, [esp+8]	// check if we had an esi=edi was the same, then a drawsprite call will follow
	jne .notadirectdrawingcall	
	mov byte [exsdrawsprite], 1
	mov byte [exscurfeature], 2
.notadirectdrawingcall:
	popf
	ret

// same but for trains
//
// out:	carry set if TTD needs to do the final three adjustments to bx
// safe:eax ebx; *not* edi
global gettrainsprite
gettrainsprite:
	xor edi,2		// swap fd and ff
	push edi
	push 0		// feature 0=trains
	call getsprite1
	jnc .gotit

	pop eax
	cmp edi,eax
	jne .dontxor		// if we had fd/ff and got a default sprite

	xor edi,2

.dontxor:
	// fake multiheads have an odd sprite number
	btr edi,0		// need bt not test to get bit value in carry flag
	sbb eax,eax		// now eax=0 if not fake multihead, or -1 if it is
	lea bx,[ebx+eax*4]	// now add 0 or -4 (which is the same as +4 here because of the "and" below)

	mov eax,[orgtrainspritebase]

	add bx,[eax+edi]	// flip multihead
	and bx,[eax+edi-0x94]	// mask symmetric engines

	stc
	ret

.gotit:
	pop edi
	xor edi,2
	pushf
	cmp esi, [esp+8]	// check if we had an esi=edi was the same, then a drawsprite call will follow
	jne .notadirectdrawingcall	
	mov byte [exsdrawsprite], 1
	mov byte [exscurfeature], 0
.notadirectdrawingcall:
	popf
	ret

// and the road vehicles
//
// out:	flags for "ja" if we have new sprites or veh. is full
global getrvsprite
getrvsprite:
	push 1		// feature 1=rvs
	call getsprite1
	ja .gotit

	mov eax,[orgrvspritebase]

	add bx,[eax+edi]

	mov ax,[esi+veh.capacity]
	shr ax,1
	cmp ax,[esi+veh.currentload]

.gotit:
	pushf
	cmp esi, [esp+8]	// check if we had an esi=edi was the same, then a drawsprite call will follow
	jne .notadirectdrawingcall	
	mov byte [exsdrawsprite], 1
	mov byte [exscurfeature], 1
.notadirectdrawingcall:
	popf
	ret


	// cannibalize some veh struct entries for the rotor
%define veh.rotorcycle veh.cargotype
%define veh.rotorbase veh.reliability

uvarb didupdateacsprite

// and planes
global getplanesprite
getplanesprite:
	mov byte [didupdateacsprite],1

	push 3		// feature 3=planes
	call getsprite1
	jc .default

	cmp byte [esi+veh.subclass],0
	jne .done

	// helicopter, get rotor sprite
	push eax
	mov al,[esi+veh.direction]
	push ebx
	push esi
	movzx esi,word [esi+veh.nextunitidx]
	cmp si,0-1
	je .notnew
	shl esi,7
	add esi,[veharrayptr]
	movzx esi,word [esi+veh.nextunitidx]
	cmp si,0-1
	je .notnew
	shl esi,7
	add esi,[veharrayptr]

	mov [esi+veh.direction],al
	call getrotorsprite

	cmp bx,[esi+veh.rotorbase]
	je .notnew
	xchg bx,[esi+veh.rotorbase]
	mov [esi+veh.rotorcycle],al

	neg bx
	jz .notnew

	add bx,[esi+veh.cursprite]
.again:
	cmp bl,al
	jb .ok
	sub bl,3
	jmp .again
.ok:
	add bx,[esi+veh.rotorbase]
	mov [esi+veh.cursprite],bx
.notnew:
	pop esi
	pop ebx
	pop eax

.done:
	pushf
	cmp esi, [esp+8]	// check if we had an esi=edi was the same, then a drawsprite call will follow
	jne .notadirectdrawingcall	
	mov byte [exsdrawsprite], 1
	mov byte [exscurfeature], 3
.notadirectdrawingcall:
	popf
	ret

.default:
	add edi,[orgplanespritebase]
	add bx,[edi]
	ret

global getshadowsprite
getshadowsprite:
	push esi
	mov esi,[esp+8]
	call getplanesprite
	pop esi
	ret

// called when displaying a ship in the purchase list
// similar as above, but using ax instead of bx, and
// ebx instead of edi
//
// in:	ebx=spritenum
//	ebp=enginenum
//	ax=direction
//	cx,dx=screen X Y
// out:	ax=spritebase+direction
// safe:ebp
global displayship
displayship:
	push 2		// feature 2=ships
	call getsprite2
	jnc .gotit

	add ebx,[orgshipspritebase]
	add ax,[ebx]

.gotit:
	mov byte [exsdrawsprite], 1
	mov byte [exscurfeature], 2
	ret

global displayship_noplayer
displayship_noplayer:
	call displayship
	jmp getvehiclecolor_noplayer

// and the first train engine
global display1stengine
display1stengine:
	xor ebx,2		// swap fd and ff
	push ebx
	push 0		// feature 0=trains
	call getsprite2
	jnc .gotit

	cmp ebx,[esp]
	jne .dontxor		// if we had fd/ff and got a default sprite

	xor ebx,2
.dontxor:

	add ebx,[orgtrainspritebase]
	and ax,[ebx-0x94]
	add ax,[ebx+0x94]

.gotit:
	add dx,[trainspritemove]
	pop ebx
	xor ebx,2
	mov byte [exsdrawsprite], 1
	mov byte [exscurfeature], 0
	ret

global display1stengine_noplayer
display1stengine_noplayer:
	call display1stengine
	jmp getvehiclecolor_noplayer

// and the second train engine (if any)
global display2ndengine
display2ndengine:
	push ebx

	push 0		// feature 0=trains
	call getsprite2
	jnc .gotit

	add ebx,[orgtrainspritebase]
	add ax,[ebx+2]
	and ax,[ebx+2-0x94]
	add ax,[ebx+2+0x94]

.gotit:
	pop ebx
	mov byte [exsdrawsprite], 1
	mov byte [exscurfeature], 0
	ret

global display2ndengine_noplayer
display2ndengine_noplayer:
	call display2ndengine
	jmp getvehiclecolor_noplayer

// and road vehicles
global displayrv
displayrv:
	push 1		// feature 1=rvs
	call getsprite2
	jnc .gotit

	add ebx,[orgrvspritebase]
	add ax,[ebx]

.gotit:
	mov byte [exsdrawsprite], 1
	mov byte [exscurfeature], 1
	ret

global displayrv_noplayer
displayrv_noplayer:
	call displayrv
	jmp getvehiclecolor_noplayer

// and planes
global displayplane
displayplane:
	push 3		// feature 3=planes
	call getsprite2
	jnc .gotit

	add ebx,[orgplanespritebase]
	add ax,[ebx]

.gotit:
	mov byte [exsdrawsprite], 1
	mov byte [exscurfeature], 3
	ret

global displayplane_noplayer
displayplane_noplayer:
	call displayplane
	jmp getvehiclecolor_noplayer

// called by all vehicle sprite handlers
//
// in:	esi=vehicle
//	edi=sprite id
//	bx=direction
//
// out:	carry set: couldn't get new sprite, use old one
//	carry clear: use new sprite
//	if carry set, edi=new sprite id
//	if carry clear, bx=new sprite number
proc getsprite1
	arg feature

	_enter

	cmp edi,0xfd
	je short .newspritereversed
	ja short .newsprites
	_ret

.newspritereversed:
	xor bl,4

.newsprites:
	push eax

	mov al,[%$feature]
	mov [grffeature],al

	movzx eax,byte [esi+veh.vehtype]
	call getnewsprite
	jc short .badsprite

	add bx,ax
	pop eax
	_ret

	// uh oh, vehicle has sprite FD..FF but there are no new graphics...
.badsprite:
	pop eax
	movzx edi,word [esi+veh.vehtype]
	movzx edi,byte [defvehsprites+edi]

	// must have carry set here!
	_ret
endproc getsprite1

// same as getsprite1 but for the display handlers
//
// in:	ebx=spritenum
//	ebp=enginenum
//	ax=direction
// out:	ax=spritebase+direction
proc getsprite2
	arg feature

	_enter

	cmp bl,0xfd
	je .newspritereversed
	ja .newsprites
	_ret

.newspritereversed:
	xor al,4

.newsprites:
	push ebx
	push esi

	mov bl,[%$feature]
	mov [grffeature],bl

	mov ebx,eax		// direction
	mov eax,[ebp]	// veh.type
	xor esi,esi		// no vehicle

	call getnewsprite

	pop esi

	// now ax=sprite base, bx=new (or old) direction

	jc short .badsprite

	add ax,bx
	pop ebx
	_ret

.badsprite:
	mov eax,ebx
	pop ebx
	mov ebx,[ebp]
	movzx ebx,byte [defvehsprites+ebx]

	// must have carry set here!
	_ret
endproc getsprite2



// display rotor for heli in hangar and vehicle details
//
// in:	edi=rotor vehicle
// out:	bx=rotor sprite base
// safe:esi
global disprotor1
disprotor1:
	push ecx
	mov cl,6
	movzx esi,word [edi+veh.engineidx]
	shl esi,7
	add esi,[veharrayptr]
	xchg cl,[esi+veh.direction]
	xchg edi,esi
	call getrotorsprite
	sub dx,5
	xchg edi,esi
	xchg cl,[edi+veh.direction]
	pop ecx

	mov byte [exsdrawsprite], 1
	mov byte [exscurfeature], 3
	ret

// display rotor for heli in purchase list or new or exclusive vehicle message
//
// in:	ebp=vehtype
// out:	bx=rotor sprite base
global disprotor2
disprotor2:
	push esi
	xor esi,esi
	mov eax,ebp
	call getrotorsprite
	pop esi
	sub dx,5
	mov byte [exsdrawsprite], 1
	mov byte [exscurfeature], 3
	ret

// check if rotor slowing down is in right position to stop
//
// in:	esi=rotor vehicle
// out:	cmp esi+veh.cursprite,stop position
global checkrotor
checkrotor:
	movzx ax,byte [esi+veh.rotorcycle]
	mov bx,[esi+veh.rotorbase]
	add ax,bx
	dec ax
	cmp [esi+veh.cursprite],ax
	ret

// initialize sprite for newly bought vehicle
//
// in:	esi=rotor vehicle
// out:	bx=rotor sprite base
global initrotor
initrotor:
	push ebx
	call getrotorsprite
	mov [esi+veh.cursprite],bx
	mov [esi+veh.rotorbase],bx
	mov [esi+veh.rotorcycle],al
	pop ebx
	ret

// slowly stop rotor
// in, out: same
global stoprotor
stoprotor:
	mov bx,[esi+veh.rotorbase]
	cmp bx,[esi+veh.cursprite]
	ret

// and advance rotor to next sprite
// in, out: same
global advancerotor
advancerotor:
	call checkrotor
	jb .doinc

	inc bx
	ret

.doinc:
	mov bx,[esi+veh.cursprite]
	inc bx
	ret

// out:	ax=number of sprites in cycle
//	bx=rotor base sprite
getrotorsprite:
	test esi,esi
	jz .checkrotor

	push esi
	movzx esi,word [esi+veh.engineidx]
	shl esi,7
	add esi,[veharrayptr]
	movzx eax,byte [esi+veh.vehtype]
	pop esi

.checkrotor:
	cmp byte [wagonoverride+eax],0
	jne .isnewsprite

.regsprite:
	mov bx,0xf3d
	mov ax,4
	ret

.isnewsprite:
	bts esi,31
	mov bh,-1
	mov byte [grffeature],3		// planes
	call getnewsprite
	jc .regsprite
	xchg ax,bx
	ret


	// find ship top speed
	//
	// in:	esi->vehicle
	// out:	ax=curspeed+1
	//	bx=maxspeed
	// safe:ebx
global shiptopspeed
shiptopspeed:
	push eax
	movzx ebx,byte [esi+veh.vehtype]
	mov al,[esi+veh.zpos]
	cmp al,6
	jb .notcanal
	add ebx,byte canalspeedfract-oceanspeedfract
.notcanal:
	movzx eax,byte [oceanspeedfract+ebx-SHIPBASE]
	neg al
	dec al
	inc eax		// now eax=100 if fract 0, 01 if fract ff etc.
	movzx ebx,word [esi+veh.maxspeed]
	imul ebx,eax
	shr ebx,8
	pop eax
	mov ax,[esi+veh.speed]
	inc ax
	ret


	//
	// special functions to handle special vehicle properties
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


global shuffletrainveh
shuffletrainveh:	// shuffle vehicle
	test ecx,ecx
	jnz .shufflenext

	call initrailvehsorttable
	ret

.shufflenext:
	push ecx

	lodsb

	push esi

#if 0
	// this doesn't quite work yet
	// should consider each track type separately, also waggons and
	// engines separately
	// maybe I won't make this possible after all because it's so complicated
	cmp al,0xff
	jne .gotit

	push ebx

	// find place to insert from date of introduction (sort by date)
	imul ebx,vehtypeinfo_size
	mov esi,[vehtypedataptr]
	mov bx,[esi+ebx+vehtypeinfo.baseintrodate]	// bx=cur veh intro date
	mov cl,NTRAINTYPES
	mov ch,cl
	xor edx,edx

	// find smallest baseintrodate which is above bx

	or eax,byte -1
.checknext:
	bt [isengine],edx
	jnc .findnext		// skip waggons

	cmp [esi+vehtypeinfo.baseintrodate],bx
	jb .findnext

	cmp [esi+vehtypeinfo.baseintrodate],ax
	ja .findnext

	mov ax,[esi+vehtypeinfo.baseintrodate]
	mov ch,cl

.findnext:
	inc edx
	add esi,vehtypeinfo_size
	dec cl
	jnz .checknext

	xor eax,eax
	xchg al,ch

	pop ebx

.gotit:
#endif
	mov ah,al

	call doshufflevehicle

	pop esi
	pop ecx
	inc ebx
	loop .shufflenext
	clc	// no error
	ret

proc doshufflevehicle
	slocal tablecopy,byte,NTRAINTYPES

	_enter

	// make copy of sort table on stack to avoid problem of copy directions

	mov esi,vehsorttable
	push esi
	lea edi,[%$tablecopy]
	push edi

	mov cl,NTRAINTYPES
	rep movsb

	pop esi		// pop in reverse order
	pop edi

	// now bl=vehicle ID to move, ah=vehicle ID before which to insert
	//     esi=%$tablecopy, edi=vehsorttable

	mov cl,NTRAINTYPES

.shufflenextveh:
	lodsb

	cmp al,ah
	jne .notinsert

	mov [edi],bl		// insert vehicle here
	inc edi

.notinsert:
	cmp al,bl
	je .doremove		// remove from where it was

	stosb

.doremove:
	loop .shufflenextveh

	_ret
endproc


	// go through all vehicles, and for those with new graphics,
	// find the correct sprite number, also reset the callbacks if any
global resetnewsprites
resetnewsprites:
	pusha
	mov esi,[veharrayptr]
.nextveh:
	mov al,[esi+veh.class]
	cmp al,0x10
	jb .skipveh
	cmp al,0x13
	ja .skipveh

	call setvehcallbacks

	// find the right sprite number

	movzx eax,byte [esi+veh.class]
	movzx ebx,byte [esi+veh.direction]
	call [orgsetsprite+(eax-0x10)*4]

.skipveh:
	sub esi,byte -vehiclesize
	cmp esi,[veharrayendptr]
	jb .nextveh
	popa
	ret
; endp resetnewsprites

global resetplanesprite
resetplanesprite:
	mov al,[esi+veh.subclass]
	cmp al,6
	je .done	// don't set rotor, setting the main heli sprite handles that

	cmp al,0
	jne .notheli

	movzx eax,word [esi+veh.nextunitidx]
	cmp ax,-1
	je .notheli

	shl eax,7
	add eax,[veharrayptr]

	movzx eax,word [eax+veh.nextunitidx]
	cmp ax,-1
	je .notheli

	shl eax,7
	add eax,[veharrayptr]

	mov byte [eax+veh.rotorcycle],0
	jmp short .isheli

.notheli:
	xor eax,eax
.isheli:
	call $+5
ovar .oldfn,-4,$,resetplanesprite

	test eax,eax
	jz .done

	mov word [eax+veh.capacity],0	// to fix stupid a42 bug

	// make sure rotor is set properly
	cmp byte [eax+veh.rotorcycle],0
	jne .done

	mov esi,eax
	call initrotor

.done:
	ret

// set cargo type of a new plane
// it's passengers/mail if passengers are allowed, else the first allowed cargo type
//
// in:	ebx=vehtype
//	esi->plane (passenger compartment)
//	edi->shadow (mail compartment)
// safe:eax edx
global setplanecargotype
setplanecargotype:
	mov byte [esi+veh.cargotype],0
	mov byte [edi+veh.cargotype],2
	mov al,[esi+veh.class]
	shl eax,16
	mov al,[esi+veh.vehtype]
	push eax
	call getrefitmask
	pop eax
	test al,1
	jnz .passok
	bsf eax,eax
	mov [esi+veh.cargotype],al
	mov word [edi+veh.capacity],0
.passok:
	ret

// show plane stats in news message or new vehicle announcement
//
// in:	eax=runcost<<8
//	ebx=vehtype
// out:	store cost in textrefstack
// safe:eax ebx esi
global shownewplaneinfo
shownewplaneinfo:
	// textrefstack is:
	// +0 cost, +4 speed, +6 pass, +8 mail, (+A runcost)
	//
	// want:
	// +0 cost, +4 speed, +6 captype, +8 cargo1, +A cap1, +C cargo2, +E cap2, +10 runcost

	mov esi,textrefstack
	shr eax,8
	mov [esi+0x10],eax

.rest:
	mov ax,[esi+6]
	mov [esi+0xa],ax
	mov ax,[esi+8]
	mov [esi+0xe],ax
	lea eax,[0x130000+ebx]
	push eax
	call getrefitmask
	pop eax
	bsf eax,eax
	mov ebx,[cargoamountnnamesptr]
	cmp eax,1
	mov ax,[ebx+eax*2]
	mov [esi+8],ax
	mov ax,[ebx+2*2]
	mov [esi+0xc],ax
	mov ax,statictext(onecargotype)
	adc ax,0
	mov [esi+6],ax
	ret

// show plane stats in depot window
//
// in:	ebx=vehtype*vehtype_size
// out:	bx=text ID
// safe:eax ebx edi ebp
global showplanestats
showplanestats:
	// textrefstack is:
	// +0 cost, +4 speed, +6 pass, +8 mail, +A runcost, +E year, +10 life, +12 reliab
	// want same as above plus +14 year, +16 life, +17 reliab

	push esi
	xchg eax,ebx
	mov bl,vehtype_size
	div bl
	xchg eax,ebx

	mov esi,textrefstack
	mov [esi+0x11],ah
	mov eax,[esi+0xE]
	mov [esi+0x14],eax
	mov eax,[esi+0xA]
	mov [esi+0x10],eax
	push ebx
	call shownewplaneinfo.rest
	pop eax
	pop esi
	mov bx,0xa007
	jmp showvehinfo.callback

uvard tempvehcolor
uvard tempvehcols

global getvehiclecolor
getvehiclecolor:
	mov eax,[esi+veh.veh2ptr]
	mov eax,[eax+veh2.colormap]
	test eax,eax
	jz .getmap
	nop
	ret

.getmap:
	push esi

	// for wagons with override use colours of engine
	movzx eax,byte [esi+veh.vehtype]
	bt [isengine],eax
	jc .nooverride

	cmp byte [wagonoverride+eax],1
	jb .nooverride

	push ebx
	movzx ebx,word [esi+veh.engineidx]
	cmp bx,[esi+veh.idx]
	je .nooverridepop
	shl ebx,7
	add ebx,[veharrayptr]
	movzx ebx,byte [ebx+veh.vehtype]
	call checkoverride
	jc .nooverridepop
	movzx ebx,word [esi+veh.engineidx]
	shl ebx,7
	add ebx,[veharrayptr]
	mov [esp+4],ebx
.nooverridepop:
	pop ebx
.nooverride:
	call getvehiclecolors

	mov word [tempvehcolor],775
	movzx eax,word [esi+veh.vehtype]
	test byte [callbackflags+eax],0x40
	movzx edi,byte [trainmiscflags+eax]
	mov al,0
	jz .nocallback
	mov al,0x2d
	call vehcallback
	jc .nocallback
	btr eax,14
	jnc .done
	mov [tempvehcolor],eax
.nocallback:
	and edi,VEHMISCFLAG_TWOCOL
	jz .normalcolor
	test eax,eax
	jnz .notdefault
	mov eax,[deftwocolormaps]
	test ax,ax
	jle .normalcolor
	mov [tempvehcolor],eax
.notdefault:
	mov al,[tempvehcols+1]
	shl al,4
	or [tempvehcols],al
.normalcolor:
	movzx eax,byte [tempvehcols]
	add eax,[tempvehcolor]
.done:
	mov edi,[esi+veh.veh2ptr]
	mov [edi+veh2.colormap],eax
	ret

global getvehiclecolor_nostruc
getvehiclecolor_nostruc:
	push ebp
	call getvehiclecolors_vehtype

	xor ebx,ebx
	mov word [tempvehcolor],775
	test byte [callbackflags+ebp],0x40
	jz .nocallback
	xor esi,esi
	mov ebx,eax
	mov eax,ebp
	mov ah,0x2d
	call vehtypecallback
	xchg ebx,eax
	jc .nocallback
	btr ebx,14
	jnc .done
	mov [tempvehcolor],ebx
.nocallback:
	test byte [vehmiscflags+ebp],VEHMISCFLAG_TWOCOL
	jz .normalcolor
	test ebx,ebx
	jnz .notdefault
	mov ebx,[deftwocolormaps]
	test bx,bx
	jle .normalcolor
	mov [tempvehcolor],ebx
.notdefault:
	mov bl,[tempvehcols+1]
	shl bl,4
	or [tempvehcols],bl
.normalcolor:
	movzx ebx,byte [tempvehcols]
	add ebx,[tempvehcolor]
.done:
	ret

getvehiclecolor_noplayer:
	movzx ebx,ax
	test byte [callbackflags+ebp],0x40
	jz .normalcolor
	xor esi,esi
	mov eax,ebp
	mov ah,0x2d
	call vehtypecallback
	jc .normalcolor
	btr eax,14
	shl eax,16
	or ebx,eax
	or bh,0x80
.normalcolor:
	ret

// called for every vehicle every tick
//
// in:	si=class<<3
//	edi->vehicle
// safe:all but edi
global vehtickproc
vehtickproc:
	cmp byte [edi+veh.subclass],0
	jne near .notengine

.isengine:
	test byte [edi+veh.vehstatus],2
	jnz .stopped

	// calculate the motion counter
	mov edx,[edi+veh.veh2ptr]
	movzx eax,word [edi+veh.speed]
	test byte [edi+veh.direction],1		// diagonal motion is at 3/4 speed
	jnz .notdiagonal

	lea eax,[eax*3]
	shr eax,2

.notdiagonal:
	movzx ebx,byte [edx+veh2.motion]
	add [edx+veh2.motion],eax
	add ebx,eax	// to check for overflow -> actual vehicle motion

.stopped:
	testmultiflags newsounds
	jz .nosoundcallback

	movzx edx,byte [edi+veh.vehtype]
	test byte [callbackflags+edx],0x80
	jz .nosoundcallback

	push esi

	test bh,bh
	jz .nomotion

	test byte [edi+veh.vehstatus],3
	jnz .nomotion	// no sounds in tunnel or while stopped

	cmp word [edi+veh.loadtime],0
	jne .nomotion	// no sounds while waiting at signal

	mov byte [miscgrfvar],4
	mov al,0x33
	mov esi,edi
	call vehcallback
	jc .nomotion

	call [generatesoundeffect]

.nomotion:
	test byte [edi+veh.cycle],15
	jnz .nocyclesound

	cmp word [edi+veh.loadtime],1
	mov al,8
	sbb al,0
	mov [miscgrfvar],al
	mov al,0x33
	mov esi,edi
	call vehcallback
	jc .nocyclesound

	call [generatesoundeffect]

.nocyclesound:

	pop esi
	mov byte [miscgrfvar],0

.nosoundcallback:

.notengine:
	movzx esi,si
	shr esi,1
	jmp [.oldhandlers+esi-0x10*4]

global vehtickproc.oldrail,vehtickproc.oldrv,vehtickproc.oldships,vehtickproc.oldaircraft
	align 4
.oldhandlers:
	.oldrail: dd 0
	.oldrv: dd 0
	.oldships: dd 0
	.oldaircraft: dd 0

global vehtickproc_aircraft
vehtickproc_aircraft:
	cmp byte [edi+veh.subclass],2	// plane or helicopter
	jbe vehtickproc.isengine
	jmp vehtickproc.notengine

// called once per day for every vehicle
//
// in:	si=class<<3
//	edi->vehicle
// safe:all but edi
global dailyvehproc
dailyvehproc:
	test byte [edi+veh.daycounter],31
	jnz .nocallback
	mov al,0x32
	mov esi,edi
	call vehcallback
	jc .nocallback
	test al,1
	jz .notrigger
	// trigger vehicle trigger 10
	push eax
	mov al,0x10
	call randomtrigger
	pop eax
.notrigger:
	test al,2
	jz .nocolormap
	mov ebx,[edi+veh.veh2ptr]
	and dword [ebx+veh2.colormap],0
.nocolormap:

.nocallback:
	movzx esi,byte [edi+veh.class]
	mov al,[.notenginebase+esi-0x10]
	cmp al,[edi+veh.subclass]

	// maintain veh.age for non-engine vehicles too
	adc word [edi+veh.age],0

	jmp [.oldhandlers+esi*4-0x10*4]

global dailyvehproc.oldrail,dailyvehproc.oldrv,dailyvehproc.oldships,dailyvehproc.oldaircraft
	align 4
.oldhandlers:
	.oldrail: dd 0
	.oldrv: dd 0
	.oldships: dd 0
	.oldaircraft: dd 0

.notenginebase:
	db 1,1,1,3	// train/rv/ship: engine has subclass 0, aircraft 0 or 2

struc callbackinfo	// for lists of cached callbacks
	.bit:	resb 1	// bit in vehicle properties, must be first byte here
	.num:	resb 1	// number in action 2
	.ofs:	resb 1	// offset into veh2 struct for cache
	.defvar:resd 1	// pointer to variable with vehtype defaults (0x80000000 if none)
endstruc_32

	// reset callbacks for one vehicle
	// in:	esi=vehicle
	// out:	---
	// uses:eax ebx ecx
setvehcallbacks:
	movzx eax,word [esi+veh.vehtype]
	mov cl,[callbackflags+eax]
	movzx ebx,byte [esi+veh.class]
//	and cl,[validvehcallbacks+ebx-0x10]
	cmp ebx,0x10
	jb .done
	cmp ebx,0x13
	ja .done
	mov ebx,[cachedvehcallbacks+(ebx-0x10)*4]
	jmp short .checkcallback

.nextcallback:
	add ebx,byte callbackinfo_size

.checkcallback:
	movzx eax,byte [ebx+callbackinfo.bit]
	cmp al,0xff
	je .done

	bt ecx,eax
	jnc .nextcallback

	mov al,[ebx+callbackinfo.num]
	call vehcallback
	jnc .ok

	// callback failed, use default
	movzx eax,word [esi+veh.vehtype]
	add eax,[ebx+callbackinfo.defvar]
	js .nextcallback	// no variable available
	mov al,[eax]

.ok:
	mov ch,al
	movzx eax,byte [ebx+callbackinfo.ofs]
	add eax,[esi+veh.veh2ptr]
	mov [eax],ch
	jmp .nextcallback

.done:
	ret


	// same but for the entire consist
	// in:	esi=vehicle in consist
	// out:	---
	// uses:---
global consistcallbacks
consistcallbacks:
	pusha
	movzx esi,word [esi+veh.engineidx]

.nextveh:
	shl esi,7
	add esi,[veharrayptr]
	call setveh2cache
	call setvehcallbacks
	movzx esi,word [esi+veh.nextunitidx]
	cmp si,byte -1
	jne .nextveh
	popa
	ret


	// set variables cached in veh2 struct
	// in:	esi=vehicle
	// out:	---
	// uses:eax ebx ecx edx
setveh2cache:
	mov al,[esi+veh.owner]
	xchg al,[curplayer]
	push eax
	mov ebx,[esi+veh.veh2ptr]
	xor edx,edx
	mov [ebx+veh2.colormap],edx
.nextvar:
	mov eax,edx
	call [vehvarhandler+eax*4]
	mov [ebx+veh2.var40x+edx*4],eax
	inc edx
	cmp edx,0+numvehvar40x
	jb .nextvar
	pop eax
	mov [curplayer],al
	ret



	// --------------------------------------
	// var.action 2 40+x variable definitions
	// --------------------------------------
	// in:	esi=struct or 0 if none
	// out:	eax=variable content
	// safe:ecx

	// 40: find vehicle number within consist for action 2 variational ids (cached)
	// out:	00nnbbff; nn=total number, bb=from back, ff=from front
global getvehnuminconsist
getvehnuminconsist:
	xor eax,eax
	movzx ecx,word [esi+veh.engineidx]
	jmp short .startcounting

.countfromfront:
	add eax,0x010001
	movzx ecx,word [ecx+veh.nextunitidx]

.startcounting:
	cmp cx,byte -1
	je .gotit

	shl ecx,7
	add ecx,[veharrayptr]

	cmp ecx,esi
	jne .countfromfront

.counttoback:
	movzx ecx,word [ecx+veh.nextunitidx]
	cmp cx,byte -1
	je .gotit

	shl ecx,7
	add ecx,[veharrayptr]
	add eax,0x010100
	jmp .counttoback

.gotit:
	ret

	// 41: same as above, but only counting consecutive vehicles of same ID (cached)
global getvehnuminrow
getvehnuminrow:
	push edx
	mov dh,0
	mov dl,[esi+veh.vehtype]
	movzx ecx,word [esi+veh.engineidx]

.newrun:
	test dh,dh	// found right vehicle yet?
	jz .keepcounting

.gotit:
	pop edx
	ret

.keepcounting:
	mov eax,0x010000
	jmp short .startcounting

.countfromfront:
	add eax,0x010001
	cmp dl,[ecx+veh.vehtype]
	movzx ecx,word [ecx+veh.nextunitidx]
	jne .newrun

.startcounting:
	cmp cx,byte -1
	je .gotit

	shl ecx,7
	add ecx,[veharrayptr]

	cmp ecx,esi
	jne .countfromfront

	mov dh,1
	movzx ecx,word [ecx+veh.nextunitidx]

.counttoback:
	cmp cx,byte -1
	je .gotit

	shl ecx,7
	add ecx,[veharrayptr]

	cmp dl,[ecx+veh.vehtype]
	movzx ecx,word [ecx+veh.nextunitidx]
	jne .gotit

	add eax,0x010100
	jmp .counttoback


	// 42: find cargo type(s) transported by consist (cached)
	// out:	uuiicctt
	//	tt = bitcoded, bit0=pass, 1=mail, 2=goods/food/candy, 3=val
	//		4=bulk, 5=piece, 6=liquid
	//	cc = most common cargo type [NOT translated]
	//	ii = most common refit cycle of cc
	//	uu = userbits
global getconsistcargo
getconsistcargo:
	pusha
	enter 256+NUMCARGOS,0

	xor eax,eax
	mov edi,esp
	lea ecx,[eax+(256+NUMCARGOS)/4]
	rep stosd

	mov edi,esi

	// count occurence of all cargo types, and set tt and uu bits
.next:
	cmp word [esi+veh.capacity],0
	je .nocargo

	mov cl,[esi+veh.cargotype]
	inc byte [esp+ecx]
	or al,[cargoclass+ecx*2]	// discards higher 8 bits, sadly

.nocargo:
	mov cl,[esi+veh.vehtype]
	mov dl,[trainuserbits+ecx]
	shl edx,24
	or eax,edx

	movzx esi,word [esi+veh.nextunitidx]
	cmp si,byte -1
	je .gotall
	shl esi,7
	add esi,[veharrayptr]
	jmp .next

	// find most common cargo type
.gotall:
	xor edx,edx
	xor ecx,ecx
	or eax,0x00ffff00

.checkmax:
	cmp [esp+ecx],dl
	jbe .notmax
	mov ah,[cargotypes+ecx]
	mov dl,[esp+ecx]

.notmax:
	inc ecx
	cmp ecx,NUMCARGOS
	jb .checkmax

	// count occurence of refit cycles of this cargo type
	mov esi,edi
.nextcycle:
	cmp word [esi+veh.capacity],0
	je .wrongtype

	cmp byte [esi+veh.cargotype],ah
	jne .wrongtype

	mov cl,[esi+veh.refitcycle]
	inc byte [esp+NUMCARGOS+ecx]

.wrongtype:
	movzx esi,word [esi+veh.nextunitidx]
	cmp si,byte -1
	je .gotcycles
	shl esi,7
	add esi,[veharrayptr]
	jmp .nextcycle

	// find most common refit cycle
.gotcycles:
	xor ecx,ecx
	xor edx,edx

.checkmaxcycle:
	cmp [esp+NUMCARGOS+ecx],dl
	jbe .notmaxcycle

	rol eax,16
	mov al,cl
	rol eax,16
	mov dl,[esp+NUMCARGOS+ecx]

.notmaxcycle:
	inc cl
	jnz .checkmaxcycle

	leave
	mov [esp+0x1c],eax
	popa
	ret

	// 43: get current player info
	// out:	0cttmmnn
	//	nn=curplayer, mm=multiplayer, tt=type, c=player colour
global getplayerinfo
getplayerinfo:
	movzx eax,byte [curplayer]
	mov ah,[companycolors+eax]
	shl eax,8

	mov al,ah	// curplayer
	mov ecx,[landscape3+ttdpatchdata.orgpl1]

	cmp al,[human1]
	je .gothuman1
	cmp al,[human2]
	je .gothuman2

	mov ah,1	// AI company
	cmp al,cl
	je .isorg
	cmp al,ch
	jne .donetype
.isorg:
	mov ah,3	// Player's original company now managed by AI
	jmp short .donetype

.gothuman1:
	cmp al,cl
	je .donetype

	mov ah,2	// Player managing AI company
	jmp short .donetype

.gothuman2:
	cmp al,ch
	je .donetype

	mov ah,2	// Player managing AI company

.donetype:
	// now eax=000cttnn
	rol eax,8

	cmp byte [numplayers],2
	jb .notmulti

	mov al,[mpcomputer]
	xor al,1

.notmulti:
	xchg al,ah
	ret


	// 44: get aircraft info
	// out:	xxxxhhtt (or 0 for non-aircraft vehicles)
	// 	hh=height above ground (0=on ground)
	//	tt=airport type, 0=small, 1=large, 2=heliport, 3=oil rig
global getaircraftinfo
getaircraftinfo:
	xor eax,eax
	cmp byte [esi+veh.class],0x13
	jne .done

	mov ah,[esi+veh.zpos]
	movzx ecx,word [esi+veh.nextunitidx]
	jecxz .noshadow
	shl ecx,7
	add ecx,[veharrayptr]
	stc
	sbb ah,[ecx+veh.zpos]	// shadow is on ground; subtract carry so that ground is 0 not 1

.noshadow:
	movzx ecx,byte [esi+veh.targetairport]
	imul ecx,station_size
	add ecx,[stationarrayptr]
	mov al,[ecx+station.airporttype]

.done:
	ret

	// 45:	get curve info
	// out:	xxxTxBxF
	// 	F/B/T are curvatures of front pair, back pair and triplet
global getcurveinfo
getcurveinfo:
	mov ax,[esi+veh.idx]
	movzx ecx,word [esi+veh.engineidx]
.nextbefore:
	shl ecx,7
	add ecx,[veharrayptr]
	cmp ax,[ecx+veh.idx]
	je .gotbefore		// current wagon is engine?
	cmp ax,[ecx+veh.nextunitidx]
	je .gotbefore		// current wagon follows?
	movzx ecx,word [ecx+veh.nextunitidx]
	jmp .nextbefore

.gotbefore:
	mov al,[ecx+veh.direction]
	mov ah,[esi+veh.direction]	// in case current wagon is last
	movzx ecx,word [esi+veh.nextunitidx]
	cmp cx,byte -1
	je .gotafter
	shl ecx,7
	add ecx,[veharrayptr]
	mov ah,[ecx+veh.direction]
.gotafter:
	// now al=direction of car in front, ah=direction of car behind
	mov ch,[esi+veh.direction]

	sub al,ch
	sub ch,ah

	// al=front-middle, ch=middle-back
	and al,7	// now we can have 6 (-2), 7 (-1), 0, 1, 2 as values
	and ch,7

	mov cl,al	// now ecx=xxxx0B0F

	// sign extend ch, cl for easier addition
	shl ecx,5
	sar ch,5
	sar cl,5
	mov eax,ecx	// now eax=xxxxBBFF (can have FE/-2, FF/-1, 0, 1, 2)

	add cl,ch
	shl ecx,16
	or eax,ecx
	and eax,0xf0f0f	// eax=000T0B0F
	ret

	// 46: motion info
	// out:	motion counter
global getmotioninfo
getmotioninfo:
	mov eax,[esi+veh.veh2ptr]
	mov eax,[eax+veh2.motion]
	lea eax,[eax+esi*2]	// to make it a little more random
	ret

	// 47: vehicle cargo
	// out: ccccwwtt
	//	tt=cargo type; translated if table exists
	//	ww=cargo unit weight
	//	cccc=cargo class
global getvehiclecargo
getvehiclecargo:
	movzx eax,byte [esi+veh.cargotype]
	movzx ecx,byte [esi+veh.vehtype]
	mov ecx,[vehids+ecx*4]
	mov ecx,[ecx+action3info.spriteblock]
	mov ecx,[ecx+spriteblock.cargotransptr]
	mov cl,[ecx+cargotrans.fromslot+eax]
	mov ch,[newcargounitweights+eax]
	mov eax,[cargoclass+eax*2-2]	// set eax(16:31)=cargo class
	mov ax,cx
	ret

	// 48: vehtype flags
	// out: xxxxxxff
	//	xxxxxx = undefined
	//	ff = flags such as 'is aviable to all companies'
global getvehtypeflags
getvehtypeflags:
	movzx eax, byte [esi+veh.vehtype] ; Get the vehicle type id
	imul eax, vehtype_size ; Multiple by the size of each entry
	add eax, vehtypearray ; Move to veh type array
	movzx eax, byte [eax+vehtype.flags] ; Get the flags
	ret ; Return eax to be tested in action2

	// 60: count occurence of vehicle ID in consist
	// in:	ah=ID
	//	esi->first vehicle
	// out:	xxxxxxNN
global getvehidcount
getvehidcount:
	mov al,0
.next:
	cmp [esi+veh.vehtype],ah
	sete cl
	add al,cl
	movzx esi,word [esi+veh.nextunitidx]
	cmp si,byte -1
	je .done
	shl esi,7
	add esi,[veharrayptr]
	jmp .next

.done:
	ret



	// do vehicle callback
	// in:	al=callback ID
	//	esi=vehicle
	// out:	eax=callback result
	//	carry set on error
	// uses:---
global vehcallback
vehcallback:
	mov [curcallback],al
	mov al,[esi+veh.class]
	sub al,0x10
	jb .invalid
	mov [grffeature],al
	movzx eax,word [esi+veh.vehtype]
	call getnewsprite
.invalid:
	mov byte [curcallback],0
	ret

	// same as above, but not necessarily with a vehicle struct
	// in:	ah=callback ID
	//	al=vehtype
	//	esi->vehicle or zero
	// out:	eax=callback result
	// uses:---
global vehtypecallback
vehtypecallback:
	mov [curcallback],ah
	mov ah,3
	cmp al,ROADVEHBASE
	sbb ah,0
	cmp al,SHIPBASE
	sbb ah,0
	cmp al,AIRCRAFTBASE
	sbb ah,0
	mov [grffeature],ah
	movzx eax,al
	call getnewsprite
	mov byte [curcallback],0
	ret

// get default cargo type from vehicle type
//
// in:	on stack: vehtype
// out:	on stack: cargo type
// uses:---
global getdefvehcargotype
getdefvehcargotype:
	push eax
	mov eax,[esp+8]

	cmp al,AIRCRAFTBASE
	jb .notplane

.plane:
	shl eax,2
	add eax,[newrefitvars+3*4]
	bsf eax,[eax]	// get first refittable cargo type
	jmp short .done

.notplane:
	push ebx
	movzx ebx,byte [vehtypeclass+eax]
	add eax,[vehclasscargotype+ebx*4]
	movzx eax,byte [eax]
	pop ebx

.done:
	mov [esp+8],eax
	pop eax
	ret

	align 4

var orgsetspriteofs, db -7, -7, -5, -5
var orgsetsprite, times 4 dd -1

	// vehicle classes are in different order in TTD/Win and TTD/DOS
#if WINTTDX
var orgspritebases
	var orgplanespritebase, dd -1
	var orgrvspritebase, dd -1
	var orgtrainspritebase, dd -1
	var orgshipspritebase, dd -1

var vehclassorder, db 3,1,0,2	// planes, roadvehs, trains, ships
#else
var orgspritebases
	var orgtrainspritebase, dd -1
	var orgrvspritebase, dd -1
	var orgshipspritebase, dd -1
	var orgplanespritebase, dd -1
#endif

	// variable that holds cargo type
vard vehclasscargotype, traincargotype,rvcargotype-ROADVEHBASE,shipcargotype-SHIPBASE,-1

	// get class from vehtype
varb vehtypeclass
	times NTRAINTYPES db 0
	times NROADVEHTYPES db 1
	times NSHIPTYPES db 2
	times NAIRCRAFTTYPES db 3
endvar

	// sprites used if vehicle has sprite FF but no new graphics available
uvarb defvehsprites,256

	// callback stuff
uvard curcallback
uvard callbackflags,256/4

#if 0	// now in veh2 struct
uvard trainpowercacheptr
uvard loadamountcacheptr

var validvehcallbacks, db 15,4,4,4	// valid callback bits for the four classes
#endif

var cachedvehcallbacks			// lists of callbacks that must be
	dd traincachedcallbacks		// reset when loading game or moving
	dd rvcachedcallbacks		// vehicle in depot
	dd shipcachedcallbacks
	dd planecachedcallbacks

%macro cachedcallback 4.nolist	// params: bit,number,cacheptr
	istruc callbackinfo
		at callbackinfo.bit, db %1
		at callbackinfo.num, db %2
		at callbackinfo.ofs, db %3
		at callbackinfo.defvar, dd %4
	iend
%endmacro

var traincachedcallbacks
	cachedcallback 0,0x10,veh2.viseffect,trainviseffect
	cachedcallback 2,0x12,veh2.loadamount,loadamount
	db 0xff

var rvcachedcallbacks
	cachedcallback 2,0x12,veh2.loadamount,loadamount
	db 0xff

var shipcachedcallbacks
	cachedcallback 2,0x12,veh2.loadamount,loadamount
	db 0xff

var planecachedcallbacks
	cachedcallback 2,0x12,veh2.loadamount,loadamount
	db 0xff

global oldshiprefitlist,oldplanerefitlist
oldshiprefitlist equ 0x1FFEFFF6	// TTD default for all refittable ship types
				// (now also with paper for temp + undef type
				//  for arctic; those won't actually be available
				//  unless moreindustriesperclimate is on)

oldplanerefitlist equ 0x1FFEFFF7// same but for planes (no oil, rubber; added mail)
