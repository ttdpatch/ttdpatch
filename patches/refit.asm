
// Vehicle refitting

#include <std.inc>
#include <vehtype.inc>
#include <proc.inc>
#include <flags.inc>
#include <textdef.inc>
#include <refit.inc>
#include <window.inc>
#include <veh.inc>
#include <grf.inc>
#include <misc.inc>
#include <newvehdata.inc>
#include <ptrvar.inc>

extern cachevehvar40x,callbackflags
extern cargoamountnnamesptr,cargoclasscargos,cargoid
extern cargotypenamesptr,cargotypes,consistcallbacks,curmiscgrf,drawtextfn
extern invalidatehandle,isengine,mostrecentspriteblock
extern normaltrainwindowptr,oldrefitplane,scenariocargo
extern patchflags,postredrawhandle,specificpropertybase
extern trainwindowrefit,vehcallback,newvehdata,newrefitvars
extern vehids,traincargosize,traincargotype
extern vehtypecallback


	// go through all ships, figure out the valid cargo types, and if
	// there is more than one, make the ship refittable
global shipsrefittable
shipsrefittable:
	testflags newships
	jc .isnewships
	ret

.isnewships:
	pusha

	xor edi,edi
	mov esi,dword [specificpropertybase+2*4]
	add esi,byte NSHIPTYPES

	movzx edx,byte [climate]
	mov ebx,dword [scenariocargo+edx*4]
	imul edx,byte 32

.nextship:
	xor eax,eax

	cmp [esi+edi],al
	je .goodcargo	// not refittable

	mov ebp,dword [newshiprefit+edi*4]
	and ebp,ebx

	// count number of bits set
	lea ecx,[eax+32]

	push ebp
.nextbit:
	shr ebp,1
	adc al,0
	loop .nextbit

	pop ebp

	// if using callback 19, make it refittable even for a single cargo type
	bt dword [shipcallbackflags+edi],5
	adc al,0

	cmp al,1
	seta byte [esi+edi]

	mov al,byte [esi+edi+NSHIPTYPES*3]
	mov al,byte [cargotypes+edx+eax]
	bt ebp,eax

	jc .goodcargo

	// the default cargo is not available in this climate
	bsf eax,ebp
	mov al,byte [cargoid+eax]
	mov [esi+edi+NSHIPTYPES*3],al

.goodcargo:
	inc edi
	cmp edi,byte NSHIPTYPES
	jb .nextship

	popa
	ret


%define numrefitoptions 64
uvard currefitlist,((numrefitoptions+2)*refitinfo_size+3)/4	// refit options plus terminator plus temp entry
uvard currefitinfonum
uvard currefitinfoptr
uvard lastrefitmask

	// get refit mask including that from cargo classes
	// in:	on stack: xxcctttt; cc=veh.class, tttt=veh.vehtype
	// out:	on stack: refit mask (also in [lastrefitmask])
	// uses:---
global getrefitmask
getrefitmask:
	pusha
	movzx ecx,byte [esp+0x26]
	test ecx,ecx
	jz near .done	// vehicle deleted but refit window still open

	movzx edi,word [esp+0x24]
	mov ecx,[newrefitvars+(ecx-0x10)*4]
	mov ecx,[ecx+edi*4]	// refit list
	push ecx

	// now add the cargo types that fit the allowed classes
	xor eax,eax
	xor ecx,ecx
	mov ax,[vehnotcargoclasses+edi*2]
	shl eax,16
	mov ax,[vehcargoclasses+edi*2]

.nextclass:
	bsf esi,eax	// this finds the bits in al first, then those in ah
	jz .gotclasses
	btr eax,esi
	or ecx,[cargoclasscargos+esi*4]	// set the bits, in case we're adding
	cmp esi,16
	jb .nextclass
	xor ecx,[cargoclasscargos+esi*4]// else remove them again
	jmp .nextclass

.gotclasses:
	mov eax,[vehids+edi*4]
	pop edi				// explicit refit mask
	test eax,eax
	jle .donetrans
	mov eax,[eax+action3info.spriteblock]
	mov esi,[eax+spriteblock.cargotransptr]
	mov eax,[esi+cargotrans.tableptr]
	test eax,eax
	jz .donetrans

	push edi
	push esi
	xor edi,edi

.transnext:
	bsf esi,[esp+4]
	jz .donetranspop
	btr [esp+4],esi

	mov esi,[eax+esi*4]
	xor ebx,ebx
.search:
	cmp [globalcargolabels+ebx*4],esi
	je .found
	inc ebx
	cmp ebx,NUMCARGOS
	jb .search
	jmp .transnext

.found:
	movzx esi,byte [climate]
	shl esi,5
	mov bl,[cargotypes+esi+ebx]
	bts edi,ebx
	jmp .transnext

.donetranspop:
	pop esi
//	and ecx,[esi+cargotrans.supported]
	pop eax

.donetrans:
	xor ecx,edi

	movzx eax,byte [climate]
	and ecx,[scenariocargo+eax*4]
.done:
	mov [lastrefitmask],ecx
	mov [esp+0x24],ecx
	popa
	ret


	// called when redrawing a refitting window
	// in:	esi=window handle; only uses [esi+window.id] = veh.
	// uses:---
proc initrefit
	local climatebits,refitbits,curtype,curcycle,numcycle

	_enter
	pusha

	mov edx,currefitlist
	mov byte [edx+refitinfo.type],-1	// mark as end of list

	movzx esi,word [esi+window.id]

	and dword [currefitinfonum],0

.nextveh:
	shl esi,7
	add esi,[veharrayptr]
	cmp word [esi+veh.capacity],0
	je .cargosdone

	mov al,[esi+veh.class]
	shl eax,16
	mov al,[esi+veh.vehtype]
	push eax
	call getrefitmask
	pop dword [%$refitbits]

	// get info about next refit option
.nextcargo:
	bsf eax,[%$refitbits]
	jnz .addtolist

.cargosdone:
	cmp byte [esi+veh.class],0x13	// don't check mail compartment/rotor
	je .done			// (it has vehtype=0)

	movzx esi,word [esi+veh.nextunitidx]
	cmp si,byte -1
	jne .nextveh

.done:
	mov byte [edx+refitinfo.type],-1
	mov byte [edx+refitinfo.ctype],-1
	popa
	_ret

.addtolist:
	btr [%$refitbits],eax

	mov [edx+refitinfo_size+refitinfo.type],al
	lea eax,[edx+refitinfo_size]
	call setuprefitinfofirst

	mov byte [%$numcycle],0

	// add cargo to list if it's not there
.addnext:
	mov edi,[eax+refitinfo.cycle]
	mov [%$curcycle],edi
	mov eax,[eax]
	mov [%$curtype],eax
	mov edi,currefitlist-refitinfo_size

.checknext:
	add edi,byte refitinfo_size
	cmp byte [edi+refitinfo.type],-1
	je .notfound

	cmp eax,[edi]
	jne .checknext

.nextcycle:
	mov eax,[%$curtype]
	mov [edx+refitinfo_size],eax
	mov eax,[%$curcycle]

	inc byte [%$numcycle]
	jz .nextcargo		// we've cycled all 256 but found no terminator

	mov [edx+refitinfo_size+refitinfo.cycle],eax
	lea eax,[edx+refitinfo_size]
	call setuprefitinfonext
	jc .addnext
	jmp .nextcargo

.notfound:
	cmp edx,currefitlist+refitinfo_size*numrefitoptions
	jae .done

	inc dword [currefitinfonum]

	mov eax,[edx+refitinfo_size]
	mov [edx],eax
	mov eax,[edx+refitinfo_size+4]
	mov [edx+4],eax
	mov al,[edx+refitinfo_size+8]
	mov [edx+8],al
	mov byte [edx+refitinfo_size+refitinfo.type],-1
	add edx,byte refitinfo_size
	jmp .nextcycle
endproc


uvard refitwindowstruc

	// called when creating the refit window listing all refit options
	//
	// in:	esi->window struct (.id not yet set!)
	// safe:edx
global openrefitwindow
openrefitwindow:
	mov edx,[refitwindowstruc]
	mov [esi+window.elemlistptr],edx
	mov dx,[esp+4]
	mov [esi+window.id],dx
	call initrefit
	mov dl,[currefitinfonum]
	mov [esi+window.itemstotal],dl
	mov byte [esi+window.itemsvisible],12
	mov byte [esi+window.itemsoffset],0
	ret


	// draw refit window
	//
	// in:	esi->window struct
global drawrefitwindow
drawrefitwindow:
	call initrefit
	movzx ebx,word [esi+window.selecteditem]
	mov word [esi+0x32],-1
	xor ebp,ebp
	mov ah,0
.next:
	mov al,[currefitlist+ebp*refitinfo_size+refitinfo.ctype]
	cmp al,-1
	jne .notdone
.done:
	ret
.notdone:

	pusha

	push eax

	movzx eax,al
	shl eax,1
	add eax,[cargotypenamesptr]
	mov ax,[eax]
	mov [textrefstack],ax

	cmp ebp,ebx
	lea ebx,[currefitlist+ebp*refitinfo_size]

	mov ax,[ebx+refitinfo.suffix]
	mov [textrefstack+2],ax
	mov eax,[ebx+refitinfo.block]
	mov [curmiscgrf],eax
	pop eax

	mov ah,16
	jne .notsel

	mov ah,0
	mov [currefitinfoptr],ebx
	mov word [esi+0x32],ax
	mov ah,12
.notsel:
	mov ebx,ebp
	cmp bl,[esi+window.itemsoffset]
	jb .notvisible
	cmp byte [esp+7*4+1],12
	jae .notvisible
	mov bx,statictext(ident2)
	mov al,ah
	call [drawtextfn]
	add word [esp+5*4],10	// old edx
	inc byte [esp+7*4+1]	// old ah
.notvisible:
	popa
	inc ebp
	jmp .next


	// clicked on item in refit list
	//
	// in:	al=item number from top of window
global chooserefit
chooserefit:
	mov ah,0
	add al,[esi+window.itemsoffset]
	adc ah,ah
	mov [esi+window.selecteditem],ax
	ret


	// called when displaying the refitted capacity
	// of road vehicles or ships
	// in:	ax=current capacity
	//	ebp->vehicle
	//	currefittinfoptr set
	// safe:eax ebx cx dx
global getrvshiprefitcap
getrvshiprefitcap:
	mov cx,ax

	mov eax,[currefitinfoptr]
	movzx ebx,byte [eax+refitinfo.ctype]
	shl ebx,1
	add ebx,[cargoamountnnamesptr]
	mov bx,[ebx]
	mov [textrefstack],bx		// was set incorrectly

	movzx ebx,byte [ebp+veh.vehtype]
	test byte [callbackflags+ebx],8
	jz .nocapacallback

	push esi
	mov esi,ebp
	call getcapacallback
	pop esi
	jc .nocapacallback

	mov cx,ax

.nocapacallback:
	mov [textrefstack+2],cx		// overwritten
	ret


	// prepare refitinfo struct
	//
	// in:	eax->refitinfo structure (needs only .type set)
	//	esi->vehicle
	// out:	carry flag clear if callback was used and valid (i.e. carry clear if structure not valid)
	// uses:---
setuprefitinfofirst:
	push ebx
	movzx ebx,byte [eax+refitinfo.type]
	mov bl,[cargoid+ebx]
	mov [eax+refitinfo.ctype],bl
	mov bh,[esi+veh.refitcycle]
	inc bh
	cmp bl,[esi+veh.cargotype]
	mov bl,0	// -> with a callback, start at cycle 0
	je .set
	mov bh,0
.set:
	mov [eax+refitinfo.cycle],bh
	mov word [eax+refitinfo.suffix],6	// empty text id
	or dword [eax+refitinfo.block],byte -1
	mov [eax+refitinfo.block],bl

	movzx ebx,byte [esi+veh.vehtype]
	test byte [callbackflags+ebx],0x20
	jz .nosuffix

		// with a callback, ignore current vehicle refitcycle
	mov bl,[eax+refitinfo.block]
	mov [eax+refitinfo.cycle],bl

	mov ebx,eax

	call getcargosuffixcallback
	cmc
	jnc .nocallback

	cmp al,0xff	// carry unless al=ff
	je .nocallback

	mov ah,0xd4
	mov word [ebx+refitinfo.suffix],ax
	mov eax,[mostrecentspriteblock]
	mov [ebx+refitinfo.block],eax

.nocallback:
	mov eax,ebx

.nosuffix:
	pop ebx
	ret

	// same but for increased refit cycles of the same cargo type
	// needs only [esi+veh.vehtype], no other vehicle variables
setuprefitinfonext:
	push ebx
	movzx ebx,byte [eax+refitinfo.type]
	mov bl,[cargoid+ebx]
	mov [eax+refitinfo.ctype],bl
	mov bh,[eax+refitinfo.cycle]
	inc bh
	mov bl,bh
	jmp setuprefitinfofirst.set



	// prepare the veh struct for a capacity callback and then call it
	//
	// in:	eax->refitinfo structure
	//	esi->vehicle
	// out:	ax=new capacity if CF=0, else callback failed
	// uses:---
global getcapacallback
getcapacallback:
	push 0x15
	// fall through

getgencapacallback:
	xchg ebx,[esp]
	push ebx
	mov bl,[eax+refitinfo.ctype]
	xchg bl,[esi+veh.cargotype]
	mov bh,[eax+refitinfo.cycle]
	xchg bh,[esi+veh.refitcycle]
	pop eax
	mov byte [cachevehvar40x],cachevehvar40x_def & ~4	// don't use the cached var 42 value
	call vehcallback
	mov byte [cachevehvar40x],cachevehvar40x_def
	xchg bl,[esi+veh.cargotype]
	xchg bh,[esi+veh.refitcycle]
	pop ebx
	ret

getcargosuffixcallback:
	push 0x19
	jmp getgencapacallback

// called to check if there should be a suffix after the cargo type
// (e.g. "5 crates of goods (cars)")
//
// in:	eax=vehtype
//	esi->vehicle or zero
// out:	ax=text ID for suffix
//	carry flag set if there is no suffix
// uses:---
global checkcargotextcallback
checkcargotextcallback:
	test byte [traincallbackflags+eax],0x20
	jnz .havecallback

.nosuffix:
	mov ax,6	// empty string text ID
	stc
	ret

.havecallback:
	mov ah,0x19
	call vehtypecallback
	jc .nosuffix

	push eax
	mov eax,[mostrecentspriteblock]
	mov [curmiscgrf],eax
	pop eax

	mov ah,0xd4
	ret

	// called when setting up the aircraft window, checks whether refittable
	// in:	esi->window
	//	edi->vehicle
	// out:	set edx,bp; CF=1 if no refit button
	// safe:eax
global isplanerefittable
isplanerefittable:
	movzx edx,byte [edi+veh.vehtype]
	movzx eax,byte [climate]
	mov edx,[newplanerefit+(edx-AIRCRAFTBASE)*4]
	and edx,[scenariocargo+eax*4]
	setnz al
	sub al,1

	mov edx,0x80		// replace code
	mov bp,[edi+veh.XY]
	ret


// called when creating the train window
//
// in:	esi->window (id not yet set)
//	on stack: veh idx
// out:	eax->old window struct
// safe:eax ebx edx
global setuptrainwindow
setuptrainwindow:
	// find out if any of the vehicles are refittable
	mov ax,[esp+4]
	mov [esi+window.id],ax

.checkrefit:
	call initrefit
	mov eax,currefitlist
	cmp byte [eax+refitinfo.type],-1
	je .notindepot	// not refittable at all

	movzx eax,word [esi+window.id]
	shl eax,7
	add eax,[veharrayptr]
	cmp byte [eax+veh.movementstat],0x80
	jne .notindepot

	test byte [eax+veh.vehstatus],2
	jz .notindepot

		// train with cargo engines is in a depot, use refit button
	mov eax,trainwindowrefit
	jmp short .setwindow

.notindepot:
	mov eax,[normaltrainwindowptr]
.setwindow:
	xchg eax,[esi+window.elemlistptr]
	ret


	// called when redrawing a train window
	// also check whether we have to reset the refit/reverse button
	//
	// in:	esi->window struc
	// out:	edi->vehicle
	// safe:eax ebx ecx edx
global trainwindowfunc
trainwindowfunc:
	call setuptrainwindow.checkrefit

	cmp eax,[esi+window.elemlistptr]
	je .noredrawnecessary

	// button has changed, redraw it
	mov al,[esi+window.type]
	or al,0x80
	mov ah,8	// refit/reverse button
	mov bx,[esi+window.id]
	call postredrawhandle	// can't use invalidatehandle in window func

.noredrawnecessary:
	movzx edi,word [esi+window.id]
	shl edi,7
	add edi,[veharrayptr]
	ret


// in:	vehicle type and default cargotype on stack
//	ebx->refitinfo
// out:	cargo capacity on stack
//	ZF=0 if refittable, ZF=1 and capacity=0 if not refittable
//	also adds refit cost to [trainplanerefitcost]
global getrailvehtypecargo
getrailvehtypecargo:
	pusha
	mov edx,0x100000
	mov dl,[esp+0x26]
	jmp short getenginecargo.checkrefit

// in:	vehicle index on stack
// rest as above
getenginecargo:
	pusha

	mov esi,[esp+0x24]

	mov dl,[esi+veh.class]
	shl edx,16
	mov dl,[esi+veh.vehtype]
	movzx edi,byte [esi+veh.cargotype]
	mov [esp+0x24],edi

.checkrefit:
	movzx eax,byte [ebx+refitinfo.type]
	push edx
	call getrefitmask
	pop edi
	bt edi,eax
	jc .isrefittable

.nocargo:
	xor ebx,ebx
.setcargo:
	mov [esp+0x24],ebx
	popa
	ret

.isrefittable:
	movzx edx,dx
	test byte [callbackflags+edx],0x20
	jz .isvalid

	test esi,esi
	jz .isvalid

	// is this cycle valid for this vehicle?
	mov eax,ebx
	call getcargosuffixcallback
	jc .isvalid		// cargo type with no callback
//	cmp al,0xff
//	je .nocargo
	cmp al,[ebx+refitinfo.suffix]
	jne .nocargo

.isvalid:
	mov al,[trainrefitcost+edx]

	mov ah,[esp+0x24]
	cmp ah,[ebx+refitinfo.ctype]
	jne .notsame
	mov al,0
.notsame:
	movzx eax,al
	bt [isengine],edx
	jc .engine
	imul eax,[wagonpurchasecostbase]
	jmp short .gotcost
.engine:
	imul eax,[trainpurchasecostbase]
.gotcost:
	sar eax,2
	push eax

	test byte [traincallbackflags+edx],8
	jz .nocapacallback

	test esi,esi
	jz .nocapacallback

	mov eax,ebx
	call getcapacallback
	jc .nocapacallback

	xchg eax,ebx		// ebx=new capacity
	mov ah,[eax+refitinfo.ctype]
	jmp short .gotamount

.nocapacallback:
//	mov eax,[enginepowerstable]
//	add eax,edx
	movzx ebx,byte [traincargosize+edx]

	// adjust for cargo types (e.g. 250 livestock = 1000 passengers)
	mov ah,[traincargotype+edx]
.gotamount:
	cmp ah,0
	je .adjustdone
	shl ebx,1
	cmp ah,2
	je .adjustdone
	cmp ah,5
	je .adjustdone
	shl ebx,1

.adjustdone:
	pop eax
	test ebx,ebx
	jz .nocargo

	add [trainplanerefitcost],eax
	or al,1
	jmp .setcargo


// same as above but counts cargo capacity of all engines in the train
// after popping e.g. ebx, returns the total amount of this cargo in the train
//
// in:	ebx->refitinfo
//	edx->vehicle
// out:	eax=capacity
// uses:---
gettrainrefitcap:
	push edx
	push 0	// capacity

.nextvehicle:
	push edx
	call getenginecargo
	pop eax		// get cargo size from stack
	add [esp],eax
	movzx edx,word [edx+veh.nextunitidx]
	cmp dx,byte -1
	je .done

	shl edx,vehicleshift
	add edx,[veharrayptr]
	jmp .nextvehicle

.done:
	pop eax		// total cargo
	pop edx
	ret


global checkinhangar
checkinhangar:
	mov al,[landscape4(bp)]
	and al,0xf0
	cmp al,0x50
	jnz .checktraindepot
	mov ah,0
	cmp byte [landscape5(bp)],0x20
	jz .hangarchecked
	cmp byte [landscape5(bp)],0x41
	jmp short .hangarchecked

.checktraindepot:
	mov ah,1
	cmp al,0x10
	jnz .hangarchecked
	mov al,[landscape5(bp)]
	cmp al,0xc0
	jl .isnotindepot
	cmp al,0xc4
	jnl .isnotindepot

.isindepot:
	xor al,al		// to set ZF
	jmp short .hangarchecked

.isnotindepot:
	or al,1			// to reset ZF

.hangarchecked:		// what really matters is the state of the zero flag
	movzx ebp,ah
	ret


global trainreverse
trainreverse:
	push eax
	mov al,cl
	shl al,1
	add al,cl
	shl al,2
	movzx eax,al
	add eax,[esi+0x24]
	cmp word [eax+0xa],0x2b4
	pop eax
	jne .donotrefit

		// refit not reverse
.dorefit:
	add esp,byte 4
	jmp dword [oldrefitplane]

.donotrefit: 	// reverse
	bts word [esi+0x1e],8
	or word [esi+4],byte 5
	ret


// adjust capacity for cargo type
// in:	on stack: original capacity
//	ebx->refitinfo
// out:	on stack: adjusted capacity
global adjustcapacity
adjustcapacity:
	xchg eax,dword [esp+4]
	test eax,eax
	pushf		// need to store whether it *was* zero
	cmp byte [ebx+refitinfo.ctype],0
	je .adjustdone
	shr eax,1
	cmp byte [ebx+refitinfo.ctype],2
	je .adjustdone
	cmp byte [ebx+refitinfo.ctype],5
	je .adjustdone
	shr eax,1
.adjustdone:
	popf		// might be zero now, if it was less than 2 or 4
	xchg eax,dword [esp+4]
	ret


// calculate refitted capacity
//
// in:	ax=aircraft passenger capacity
//	bh=new cargo type
//	edx->vehicle
// out:	ax=capacity to display in refit window
// safe:?
global calcplanetrainrefitcap
calcplanetrainrefitcap:
	and dword [trainplanerefitcost],0
	push ebx

	push esi
	lea esi,[edx+veh.idx-window.id]
	call initrefit
	pop esi
	shr ebx,16
	lea ebx,[currefitlist+ebx*refitinfo_size]
	mov [currefitinfoptr],ebx

	cmp byte [edx+veh.class],0x10
	jne .isplanerefit

	call gettrainrefitcap
	mov byte [currentexpensetype],expenses_trainruncosts
	jmp .done

.isplanerefit:
	mov bp,ax
	movzx eax,byte [edx+veh.vehtype]
	test byte [planecallbackflags+eax-AIRCRAFTBASE],8
	jz .nocapacallback

	push esi
	mov esi,edx
	mov eax,ebx
	call getcapacallback
	pop esi
	jc .nocapacallback

	mov bp,ax
	xor eax,eax
	cmp byte [ebx+refitinfo.ctype],0
	je .gotamount
	shl bp,1
	cmp byte [ebx+refitinfo.ctype],2
	je .gotamount
	cmp byte [ebx+refitinfo.ctype],5
	je .gotamount
	shl bp,1
	jmp short .gotamount

.nocapacallback:
	cmp byte [ebx+refitinfo.ctype],0
	je .pass

	// refitting to just one cargo type, so add mail cap. too
	movzx eax,byte [edx+veh.vehtype]
	add eax,9*NAIRCRAFTTYPES-AIRCRAFTBASE
	add eax,[specificpropertybase+3*4]
	movzx eax,byte [eax]
	add eax,eax		// 1 mail = 2 pass
.gotamount:
	add bp,ax

.pass:
	mov al,[ebx+refitinfo.ctype]
	cmp al,[edx+veh.cargotype]
	mov ax,bp
	je .done

	push eax
	movzx eax,byte [edx+veh.vehtype]
	mov al,[planerefitcost+eax-AIRCRAFTBASE]
	test al,al
	jnz .gotcost

	mov al,32

.gotcost:
	imul eax,[planepurchasecostbase]
	shr eax,5
	mov [trainplanerefitcost],eax		// make it cost if the type changes
	pop eax

.done:
	push eax
	call adjustcapacity
	pop eax
	mov bp,word [edx+veh.XY]
	pop ebx
	ret


// called to store the new capacity
// in:	edx->vehicle
//	ax=new capacity
// out:	ax=[edx.nextwaggon]
global refitstorecap
refitstorecap:
	pusha
	mov ebx,[currefitinfoptr]

	cmp byte [edx+veh.class],0x10
	jne .gotcapacity

	// need to calculate the capacity of this engine only
	push edx
	call getenginecargo
	call adjustcapacity
	pop eax
	jnz .gotcapacity

	mov al,[edx+veh.cargotype]
	mov [esp+16],al
	jmp short .norefit

.gotcapacity:
	mov word [edx+veh.capacity],ax

.norefit:
	// redraw depot window
	mov al,0x12
	mov bx,[edx+veh.XY]
	call [invalidatehandle]
	popa
	mov ax,word [edx+veh.nextunitidx]
	ret


uvard trainplanerefitcost

// called after storing the new cargo type and capacity of the first engine
// in:	eax=this vehicle
//	bh=new cargo type
//	edx=first vehicle (engine)
// out:	cx=capacity of this vehicle
global refitsecondengine
refitsecondengine:
	cmp byte [edx+veh.class],0x10	// is it a train?
	je .train

	cmp bh,0			// planes only get mail if the first
	je .hasmail			// type is passengers
	xor cx,cx
.hasmail:
	mov word [eax+veh.capacity],cx
	mov word [eax+veh.currentload],0
	ret

.train:
	pusha
	mov ebx,[currefitinfoptr]
	mov eax,edx
	and dword [trainplanerefitcost],0

.nextvehicle:
	push eax
	call getenginecargo
	call adjustcapacity
	pop ecx
	jz .skipvehicle		// not refittable

	mov dl,[ebx+refitinfo.ctype]
	mov dh,[ebx+refitinfo.cycle]

	cmp dl,[eax+veh.cargotype]
	jne .diff

	cmp dh,[eax+veh.refitcycle]
	je .same

.diff:
	mov word [eax+veh.currentload],0
.same:
	mov [eax+veh.cargotype],dl
	mov [eax+veh.refitcycle],dh
	mov word [eax+veh.capacity],cx		// set third and following engines

.skipvehicle:
	movzx eax,word [eax+veh.nextunitidx]
	cmp ax,byte -1
	je .done

	shl eax,vehicleshift
	add eax,[veharrayptr]
	jmp .nextvehicle

.done:
	mov esi,[esp+0x14]
	call consistcallbacks
	popa
	mov bh,[edx+veh.cargotype]	// don't refit the engine again
	ret


// called after setting the new cargo type of road vehicles and ships
// in:	edx=vehicle
//	bh=old cargo
// out:	set [edx+veh.currentload]=0
// safe:bl, others?
global setnewcargo
setnewcargo:
	pusha

	push esi
	lea esi,[edx+veh.idx-window.id]
	call initrefit
	pop esi
	mov eax,ebx
	shr eax,16
	lea eax,[currefitlist+eax*refitinfo_size]
	mov [currefitinfoptr],eax

	movzx eax,byte [edx+veh.vehtype]
	test byte [callbackflags+eax],8
	jz .nocapacallback

	push esi
	mov esi,edx
	xchg bh,[esi+veh.cargotype]	// need to xchg, because bh is old type!
	mov eax,[currefitinfoptr]	// and getcapacallback does xchg again!
	call getcapacallback
	xchg bh,[esi+veh.cargotype]
	pop esi
	jc .nocapacallback

	mov [edx+veh.capacity],ax

.nocapacallback:
	mov eax,[currefitinfoptr]
	mov bl,[eax+refitinfo.cycle]
	cmp bh,[edx+veh.cargotype]
	jne .diff

	cmp bl,[edx+veh.refitcycle]
	je .same

.diff:
	mov word [edx+veh.currentload],0
.same:
	mov [edx+veh.refitcycle],bl

	cmp byte [edx+veh.class],0x11
	jne .notrv

	mov byte [currentexpensetype],expenses_rvruncosts

.notrv:
	mov esi,edx
	call consistcallbacks

	// redraw depot window
	mov al,0x12
	mov bx,[edx+veh.XY]
	call [invalidatehandle]
	popa
	ret

// calculate refit cost
// in:	same as above
// out:	ebx=cost
// safe:?
global rvshiprefitcost
rvshiprefitcost:
	cmp bh,[edx+veh.cargotype]
	jne .havecost

	xor ebx,ebx
	ret

.havecost:
	movzx ebx,byte [edx+veh.vehtype]
	mov bl,[rvrefitcost+ebx-ROADVEHBASE]	// also works for ships
	cmp byte [edx+veh.class],0x11
	je .rv

	test bl,bl
	jnz .gotcost
	mov bl,32
.gotcost:
	imul ebx,[shipbasevalue]
	sar ebx,7+5
	ret

.rv:
	test bl,bl
	jnz .gotit
	mov bl,14
.gotit:
	imul ebx,[roadvehbasevalue]
	sar ebx,9
	ret


// called to update vehicle window after attaching/detaching vehicle
//
// in:	edi->vehicle
// out:	(as replaced code)
// safe:?
global updatevehwnd
updatevehwnd:
	mov al,13
	mov bx,[edi+veh.idx]
	call [invalidatehandle]
	mov al,14
	mov bx,[edi+veh.idx]
	ret


// called when calling actionhandler to check new capacity
//
// in:	bl=new cargo type
//	ebp->vehicle
//	esi->window
// out:	al=owner
//	bl=0
//	bh=new cargo type
//	ebx(16:31)=sub type info
// safe:?
global refitcheck
refitcheck:
	mov bh,bl
	mov bl,0
	ror ebx,16
	mov bx,[esi+window.selecteditem]
	ror ebx,16
	mov al,[ebp+veh.owner]
	ret

// same as above but replaces different code
global refitdoact
refitdoact:
	mov bl,1
	ror ebx,16
	mov bx,[esi+window.selecteditem]
	ror ebx,16
	mov ax,[ebp+veh.xpos]
	ret
