
// New default service interval

#include <std.inc>
#include <proc.inc>
#include <flags.inc>
#include <textdef.inc>
#include <human.inc>
#include <veh.inc>
#include <vehtype.inc>
#include <player.inc>
#include <bitvars.inc>
#include <misc.inc>
#include <newvehdata.inc>
#include <ptrvar.inc>

extern actionhandler,addexpensestoplayerwithtype,cargotypes
extern checknewtrainisengine2,copyvehordersfn,curcallback,delveharrayentry
extern delvehschedule,forceextrahead,forcenewvehentry
extern getnewsprite,getrefitmask,getymd,grffeature,isengine,ishumanplayer
extern lastmovementstat,lastwagoncleartile,makerisingcost,miscgrfvar
extern miscmodsflags,newservint,noattachnewwagon,numheads,patchflags
extern randomtrigger,replaceage,replaceminreliab,savevehordersfn,tiledeltas
extern vehbase,vehiclecosttables,newvehdata




	// called to find out whether a vehicle needs maintenance
	// -> fix "Y2K" bug if maintenance beyond 16 bit date
	//
	// in:	esi=vehicle offset
	// out:	CF|ZF=0 (cc=A) if not yet, 1 (cc=NA) otherwise
	// safe: (e)ax
global needsmaintcheck,needsmaintcheck.always
needsmaintcheck:
	push ebx

	// see if there are any depots in the vehicle orders
	// if so, don't do maintenance otherwise

	mov ebx,dword [esi+veh.scheduleptr]
	mov ah,byte [esi+veh.totalorders]

	or ah,ah
	jz short .nocommands

.nextcommand:
	mov al,[ebx]
	and al,0x1f
	cmp al,2
	je short .itsadepot
	add ebx,byte 2
	dec ah
	jnz .nextcommand

.nocommands:

	call isittooold
	jna short .tooold

.normalcheck:
	movzx eax,word [esi+veh.lastmaintenance]
	movzx ebx,word [esi+veh.serviceinterval]
	add eax,ebx
	movzx ebx,word [currentdate]
	cmp eax,ebx

.done:
	pop ebx
	ret

.always:
	// always allow maintenance even if there's a depot in the orders
	push ebx
	jmp .nocommands

.itsadepot:
	cmp al,1
	pop ebx
	ret

.tooold:
	testflags forceautorenew
	jnc .normalcheck

	testmultiflags autoreplace
	jz .notreplace

	call getreplacevehicle
	sbb ah,ah	// ah=FF or 00
	or ah,al	// ah=FF if CF=1 or AL if not
	jmp short .replace

.notreplace:
	call isvehicleobsolete
	mov ah,0xff
	jna short .normalcheck	// engine is obsolete, send to depot only for maintenance

.replace:
	mov al,0
	push edx
	push edi
	call dorenewconsist	// check how much it's going to cost
	pop edi
	pop edx
	call getvehicleownersdata
	cmp dword [eax+player.cash],ebx
	jl short .normalcheck	// not enough money, send to depot only for maintenance

	// OK, so the vehicle can be sent to depot for autorenewal

	stc			// satisfy the NA condition
	jmp short .done
; endp needsmaintcheck 


	// find out the replacement vehicle ID
	//
	// in:	esi->vehicle
	// out:	CF=0: eax=vehicle ID
	//	CF=1: no better ID available
	// uses:eax
getreplacevehicle:
	push ebx
	push edx

	mov byte [curcallback],0x34

.next:
	mov al,[esi+veh.class]
	and eax,0xf
	mov ah,1	// generic callback
	mov [grffeature],al
	call getnewsprite
	jc .done

	movzx edx,byte [esi+veh.class]
	add al,[vehbase+edx-0x10]
	cmp al,[esi+veh.vehtype]
	cmc
	je .done	// abort with CF=1 if we get the same as the current type

	inc byte [miscgrfvar]	// try next one if this one isn't usable
	stc
	jz .done

	// available to the player?
	imul edx,eax,byte vehtype_size
	movzx ebx,byte [esi+veh.owner]
	bt [vehtypearray+edx+vehtype.playeravail],ebx
	jnc .next

	// high enough reliability?
	movzx ebx,byte [vehtypearray+edx+vehtype.reliab+1]	// get high byte
	imul ebx,100
	cmp bh,[replaceminreliab]
	jb .next

	// for non-train-engines, right refittability?
	cmp byte [esi+veh.class],0x10
	jne .notrainengine
	bt [isengine],eax
	jb .ok

.notrainengine:
	push word [esi+veh.class]
	push ax
	call getrefitmask
	movzx ebx,byte [climate]
	shl ebx,5
	movzx edx,byte [esi+veh.cargotype]
	mov dl,[cargotypes+ebx+edx]
	pop ebx
	bt ebx,edx
	jnc .next

#if 0
	// can player afford it?
	call getvehiclecost
	movzx ebx,byte [esi+veh.owner]
	imul ebx,player_size
	add ebx,[playerarrayptr]
	cmp [ebx+player.cash],edx
	jl .next
#endif

.ok:
	clc

.done:
	pop edx
	pop ebx
	mov dword [miscgrfvar],0	// need to preserve CF
	mov byte [curcallback],0
	ret


	// called when last vehicle of train has entered the depot
	//
	// in:	edi->engine
	// out:	ax=date
	// safe:dx
global trainenterdepot
trainenterdepot:
	testflags pathbasedsignalling
	jnc .notpbs

	push ebp
	mov al,[edi+veh.direction]
	mov dl,al
	and al,2
	shr al,1
	inc al
	or al,0x80	// to clear both tiles of depot and the tile before it
	mov [lastmovementstat],al
	movzx ebp,dl
	mov ax,[edi+veh.XY]
	sub ax,[tiledeltas+ebp]
	mov bp,[edi+veh.XY]
	call lastwagoncleartile
	pop ebp

.notpbs:
	// fall through


	// automatically replace engines when they get too old
	//
	// called just before an engine receives maintenance
	// in:	EDI -> vehicle struct
	// out:	AX = current date
global autoreplacetrainorrv
autoreplacetrainorrv:
	xchg esi,edi
	call autoreplaceengine
	xchg esi,edi
	ret
; endp autoreplacetrainorrv 

	// in:	ESI -> vehicle struct
	// out:	AX = current date
global autoreplaceengine
autoreplaceengine:
	testflags autorenew
	jc .checkautorenew

	// just entered a depot, but without auto-renew
	// only update random sprites, and exit

	call .updaterandomsprite
	mov ax,[currentdate]
	ret

.checkautorenew:
	// check if manually sent to depot
	mov al,byte [esi+veh.currorder]
	and al,0x7f

	// want to skip age check with cf=zf=0 if al==42

	add al,(0x7f-0x42)
	add al,1		// will set OF if and only if AL was 42h after the AND above
	jo short .dontcheckage	// in this case AL==80h now, so CF=ZF=0

	call .updaterandomsprite
	call isittooold

.dontcheckage:
	mov ax,[currentdate]		// this is what this code replaces
	jna short .tooold
	ret

.updaterandomsprite:
	// update random triggers
	push esi
.updatenext:
	mov al,2
	call randomtrigger
	movzx esi,word [esi+veh.nextunitidx]
	cmp si,byte -1
	je .updatedone
	shl esi,vehicleshift
	add esi,[veharrayptr]
	jmp .updatenext

.updatedone:
	pop esi
	ret

.tooold:
	pusha

	call dword [getymd]
	mov cl,al

	testmultiflags autoreplace
	jz .notreplace

	call getreplacevehicle
	sbb ah,ah	// ah=FF or 00
	or ah,al	// ah=FF if CF=1 or AL if not
	jmp short .replace

.notreplace:
	call isvehicleobsolete
	mov ah,0xff
	jna short .nomoney

.replace:
	mov al,0	// check first
	call dorenewconsist

	push eax
	call getvehicleownersdata
	cmp dword [eax+player.cash],ebx
	pop eax
	jl short .nomoney	// not enough money

	push eax
	mov al,byte [esi+veh.owner]
	mov ah,expenses_newvehs
	call addexpensestoplayerwithtype
	pop eax

	mov al,1
	call dorenewconsist

	or ebx,ebx
	jz short .nomoney	// show no cost, it's zero anyway

	movzx eax,word [esi+veh.xpos]
	movzx ecx,word [esi+veh.ypos]
	call dword [makerisingcost]

.nomoney:
	popa
	ret
; endp autoreplaceengine 


	// calculate cost and do the renewing
	// in:	esi -> engine
	//	al = 0 if checking cost, 1 if renewing
	//	ah = new engine vehid or FF if same one
	//	cl = current year (used only if al!=0)
	// out:	ebx,edi = cost
	// uses:edx
proc dorenewconsist
	local lastveh,newtype,classofs,x,y

	_enter

	push esi
	xor edi,edi	// cost
	mov [%$lastveh],edi

	mov bh,al
	mov bl,[esi+veh.owner]
	xchg bl,[curplayer]
	push ebx

	// so we need to replace this engine and the waggons too

.vehicleloop:
	and al,0x7f
	movzx ebx,byte [esi+veh.vehtype]
	bt [isengine],ebx
	jnc .gottype
	cmp ah,-1
	je .gottype
	mov bl,ah
	or al,0x80
.gottype:
	call getvehiclecost.byvehtype

	// now add to cost but subtract current value to get the difference
	add edi,edx
	sub edi,dword [esi+veh.value]

	test al,0x7f
	jz .nextvehicle		// just checking cost

	test al,0x80
	js .replaceveh

.renewonly:
	mov dword [esi+veh.value],edx
	mov word [esi+veh.age],0
	mov byte [esi+veh.yearbuilt],cl

	bt dword [isengine],ebx
	jnc short .nextvehicle

	// reset reliability decay speed (note, getvehiclecost sets ebx=enginetype)
	imul ebx,byte vehtype_size
	add ebx,vehtypearray
	mov bx,word [ebx+vehtype.reliabdecrease]
	mov word [esi+veh.reliabilityspeed],bx

	// reset breakdown counters
	mov byte [esi+veh.breakdownthreshold],0

	// reset depreciation counter
	mov byte [esi+veh.daycounter],0

.nextvehicle:
	mov [%$lastveh],esi
	// process waggons only if it's a train (duh)
	cmp byte [esi+veh.class],0x10
	jne short .done

	movzx esi,word [esi+veh.nextunitidx]
	cmp si,byte -1
	je short .done
	shl esi,vehicleshift
	add esi,[veharrayptr]
	jmp .vehicleloop

.done:
	pop ebx
	mov [curplayer],bl	// not sure if this is needed, but it won't hurt

	test bh,0x7f
	mov ebx,edi
	pop esi
	jz .dontstart
	and byte [esi+veh.vehstatus],~2
.dontstart:
	_ret

.cantreplace:
	popa
	jmp .renewonly

.replaceveh:
	pusha

	mov edi,esi
	xor ebx,ebx
	mov bh,ah
	mov [%$newtype],ebx
	mov ax,[esi+veh.xpos]
	and al,~0xf
	mov [%$x],eax
	mov cx,[esi+veh.ypos]
	and cl,~0xf
	mov [%$y],ecx
	mov bl,0
	movzx esi,byte [esi+veh.class]
	shl esi,3	// lea esi,[0x80+(esi-0x10)*8]	// Buy<class>Vehicle action
	mov [%$classofs],esi
	push ebp
	call [actionhandler]
	pop ebp
	cmp ebx,0x80000000
	je .cantreplace

	cmp dword [edi+veh.scheduleptr],byte -1
	adc byte [forceextrahead],-1
	jnz .notengine
	pusha
	mov edx,edi
	mov esi,edi
	mov ax,[edi+veh.XY]
	mov edi,soldvehorderbuff
	mov [soldvehorderxy],ax
	call [savevehordersfn]
	call [delvehschedule]
	popa
	mov [forcenewvehentry],edi	// next bought vehicle will use the same entry

.notengine:
	mov esi,edi
	cmp byte [esi+veh.class],0x10
	je .deltrainveh

	// RV, ship or aircraft: delete entire consist
.delveh:
	movzx eax,word [esi+veh.nextunitidx]
	or word [esi+veh.nextunitidx],byte -1
	call [delveharrayentry]
	cmp ax,byte -1
	je .buynew
	shl eax,7
	add eax,[veharrayptr]
	mov esi,eax
	jmp .delveh

	// trains: delete articulated vehicle set or single vehicle
.deltrainveh:
	movzx eax,word [esi+veh.nextunitidx]
	or word [esi+veh.nextunitidx],byte -1
	call [delveharrayentry]
	cmp ax,byte -1
	je .buynew
	shl eax,7
	add eax,[veharrayptr]
	cmp byte [eax+veh.currorderidx],0xfd
	mov esi,eax
	jae .deltrainveh
	mov ax,[eax+veh.idx]

.buynew:
	push ax
	mov eax,[%$x]
	mov ecx,[%$y]
	mov ebx,[%$newtype]
	inc ebx
	mov esi,[%$classofs]
	push ebp
	inc byte [actionnestlevel]
	inc byte [noattachnewwagon]
	call [actionhandler]
	dec byte [noattachnewwagon]
	dec byte [actionnestlevel]
	pop ebp
	cmp ebx,0x80000000	// if this fails, we're in big trouble
	je .die

	call .skipartics
	pop word [esi+veh.nextunitidx]	// use esi so that if two heads, always operate on second one
	mov byte [forceextrahead],0
	cmp byte [edi+veh.class],0x10
	jne .notnewrow
	cmp byte [edi+veh.subclass],4	// multiheads were put on a separate row
	jne .notnewrow
	mov byte [edi+veh.subclass],2	// make them regular "wagons"
.notnewrow:

	mov edx,[%$lastveh]
	test edx,edx
	jz .isfirst

	mov ax,[edi+veh.idx]
	mov [edx+veh.nextunitidx],ax
	jmp short .notfirst

.isfirst:
	push esi
	mov esi,edi
	mov edi,soldvehorderbuff
	call [copyvehordersfn]
	mov word [soldvehorderxy],-1
	pop esi
.notfirst:
	mov [esp+4],esi
	popa
	jmp .nextvehicle

.skipartics:
	push eax
	mov eax,esi
.nextartic:
	mov esi,eax
	movzx eax,word [eax+veh.nextunitidx]
	cmp ax,byte -1
	je .articdone
	shl eax,7
	add eax,[veharrayptr]
	cmp byte [eax+veh.currorderidx],0xfd
	jnb .nextartic
.articdone:
	pop eax
	_ret 0

.die:
	ud2
endproc dorenewconsist 


	// determines whether an engines is too old and needs to
	// be replaced automatically
	// in:	esi=vehicle pointer
	// out:	CF=ZF=0(cc=A):not too old; cc=NA:too old
	// uses:ax
isittooold:
	testflags autorenew
	// !! testflags expands to BT, which leaves ZF undefined !!
	jc short .checkage
	or al,1		// CF=ZF=0
	ret

.checkage:
	mov al,byte [replaceage]
	mov ah,30	// 30 days per month
	imul ah
	add ax,word [esi+veh.maxage]
	cmp ax,word [esi+veh.age]
	ret
; endp isittooold 


	// determines whether an engine is getting (or already has got) obsolete
	// (in which case it's not a good idea to renew it automatically)
	// in:	ESI -> vehicle pointer
	// out:	CF|ZF=1 (cc=NA) if obsolete, cc=A otherwise
	// uses:AX,EBX
isvehicleobsolete:
	cmp byte [currentyear],2049-1920
	jae .gotit	// nothing is obsolete after 2049 since vehtypes won't be updated

	movzx ebx,word [esi+veh.vehtype]
	mov al,[vehphase2dec+ebx]
	mov ah,-12
	imul ah
	imul ebx,byte vehtype_size
	add ebx,vehtypearray
	add ax,word [ebx+vehtype.durphase1]
	add ax,word [ebx+vehtype.durphase2]
	sub ax,12		// max. 1 year before phase 3
	cmp ax,word [ebx+vehtype.engineage]
.gotit:
	ret
; endp isvehicleobsolete

	// shows regular "getting old" message, or shows that vehicle is obsolete
	//
	// in:	ax=veh.idx
	//	esi->vehicle
	// out:	---
	// safe:must preserve regs for GenerateNewsMessage
global getoldmsg
getoldmsg:
	push ebx
	call isvehicleobsolete
	pop ebx
	ja .notobsolete

	push dword [textrefstack]
	pop dword [textrefstack+2]
	mov [textrefstack],dx
	mov dx,newstext(vehobsolete)

.notobsolete:
	mov ax,[esi+veh.idx]
	mov [newsitemparam],ax	// replaced
	ret



var vehiclebasevaluepointers
	dd roadvehbasevalue
	dd shipbasevalue
	dd aircraftbasevalue

// get base value of a vehicle
// in:	 esi -> vehicle
//	 ebx = word [esi+46h]  (enginetype)
// out:  edx = base value
// 	 eax = [esi.vehicletype]
getvehiclebasevalue:
	movzx eax,byte [esi+veh.class]

// use this entry point if EAX aready set
// does not need ESI
getvehiclebasevalueentry2:
	cmp al,0x10
	jne short getrailvehiclebasevalue.notrailvehicle

// railway vehicle, determine whether it's engine or waggon
// does not need EAX either
global getrailvehiclebasevaluebothheads
getrailvehiclebasevaluebothheads:
	bt dword [isengine],ebx
	mov edx,[waggonbasevalue]
	jnc .gotit
	mov edx,[enginebasevalue]
.gotit:
	ret

global getrailvehiclebasevaluebothheadsifnotctrl
getrailvehiclebasevaluebothheadsifnotctrl:
	bt [isengine],ebx
	jnc getrailvehiclebasevalue.iswaggon

	// engine, check if it's two-headed
//	mov edx,dword [enginepowerstable]
	test byte [numheads+ebx],1
	jz getrailvehiclebasevalue.singlehead

	mov edx,ebx
	call checknewtrainisengine2
	mov edx,[enginebasevalue]
	jnz .dualhead		// ZF if Ctrl-bought multi-head

	sar edx,1

.dualhead:
	ret

global getrailvehiclebasevalue
getrailvehiclebasevalue:
	bt dword [isengine],ebx
	jnc short .iswaggon

	// engine, check if it's two-headed
//	mov edx,dword [enginepowerstable]
	test byte [numheads+ebx],1
.singlehead:
	mov edx,[enginebasevalue]
	jnz short .twoheaded
	ret
.twoheaded:
	sar edx,1
	ret

.iswaggon:
	mov edx,[waggonbasevalue]
	ret

.notrailvehicle:
	mov edx,dword [vehiclebasevaluepointers+(eax-0x11)*4]
	mov edx,[edx]
	ret
; endp getvehiclebasevalue 


// get cost multiplier of a vehicle
// in:	 eax = vehicle type
//	 ebx = engine type
// out:  eax = cost multiplier
// note: final cost = (base value)*(multiplier)/256
getvehiclecostmult:
	mov eax,dword [vehiclecosttables+(eax-0x10)*4]
	movzx eax,byte [ebx+eax]
	ret
; endp getvehiclecostmult 


// get cost of a vehicle
// in:	 esi -> vehicle
// out:	 edx = cost
//	 ebx = [esi.enginetype]
// Note: does not check vehicle type, do not use on special vehicles like plane's mail compartment
global getvehiclecost
getvehiclecost:
	movzx ebx,word [esi+veh.vehtype]
.byvehtype:
	push eax
	call getvehiclebasevalue
	call getvehiclecostmult
	imul edx
	shrd eax,edx,8
	mov edx,eax
	pop eax
	ret
; endp getvehiclecost 


// get pointer to the vehicle owner's structure
// in:	esi -> vehicle
// out:	eax -> player struct
// uses:-
getvehicleownersdata:
	movzx eax,byte [esi+veh.owner]
	imul eax,player_size
	add eax,[playerarrayptr]
	ret
; endp getvehicleownersdata 


// set service interval of new vehicle to servint value if it's a human player
// in:	esi->vehicle
// out:	-
// safe:?
global setservint
setservint:
	push eax

	movzx eax,byte [esi+veh.class]
	mov ax,[defservint+(eax-0x10)*2]

	test byte [miscmodsflags],MISCMODS_SERVINTONLYHUMAN
	jz .allplayers

	push PL_DEFAULT
	call ishumanplayer
	jnz .nothuman

.allplayers:
	mov ax,[newservint]

.nothuman:
	mov [esi+veh.serviceinterval],ax
	pop eax
	ret

// default TTD service interval for the four vehicle classes
var defservint, dw 150, 150, 360, 100
