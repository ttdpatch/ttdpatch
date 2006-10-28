
// Functions to help the AI with buying new vehicles

#include <std.inc>
#include <grf.inc>
#include <veh.inc>
#include <vehtype.inc>
#include <town.inc>
#include <player.inc>
#include <industry.inc>
#include <refit.inc>
#include <misc.inc>
#include <ptrvar.inc>
#include <newvehdata.inc>

extern actionhandler,adjustcapacity,ai_buildrailvehicle_actionnum
extern callbackflags,cargotypes,curcallback
extern currefitlist,curselstationid,featurevarofs,getcapacallback
extern getnewsprite,getrailvehtypecargo,getrefitmask,grffeature,isengine
extern mostrecentspriteblock,newstationnum,nostructvars
extern specificpropertybase,stsetids,tracktypes
extern trainplanerefitcost,newvehdata



struc aiselectioninfo
	.cargotype:	resb 1	// 00h: cargo type (climate specific, 00..0B)
	.altcargotype:	resb 1	// 01h: cargo type (climate independent, 00..1B)
	.default:	resb 1	// 02h: default vehicle type/etc to pick
	.sourcetype:	resb 1	// 03h: source industry type
	.desttype:	resb 1	// 04h: destination industry type
	.distance:	resb 1	// 05h: distance between source and destination
	.type:		resb 1	// 06h: type to build (see below)
	.number:	resb 1	// 07h: current number of vehicle/station/etc
	.size:		resb 1	// 08h: station size (num*16 + length)
	.reserved:	resb 7	// guaranteed to be zero
endstruc

// types
// Trains (0x)
//	0=check rail engine
//	1=check electric engine
//	2=check monorail engine
//	3=check maglev engine
//	8=get rail wagon
//	9=get electric wagon
//	A=get monorail wagon
//	B=get maglev wagon
//	F=get rail type to build
// RVs (1x)
//	0=check road vehicle
//	1=get number of road vehicles to try
//	2=get first road vehicle to try
// Ships (2x)
//	0=check ship
//	1=get number of ships to try
//	2=get first ship to try
// Aircraft (3x)
//	0=check aircraft
//	1=check airport type
// Stations (4x)
//	0=get train station type

uvarb aiselectioninfovar, aiselectioninfo_size


// call ai selection callback
// in:	al=number
//	bl=callback type (see above) + feature<<4
//	bh=default selection
//	edx=cargo type
// out:	bh=new selection if CF=0, old selection if CF=1
// uses:eax ecx edi ebp
global getaiselectioncallback
getaiselectioncallback:
	push esi
	mov esi,aiselectioninfovar
	mov [esi+aiselectioninfo.cargotype],dl
	mov [esi+aiselectioninfo.default],bh
	mov [esi+aiselectioninfo.number],al
	mov al,bl
	and al,0x0f
	mov [esi+aiselectioninfo.type],al

	movzx ebp,byte [curplayer]
	imul ebp,player_size
	add ebp,[playerarrayptr]

	mov al,[ebp+0x328]
	shl al,4
	or al,[ebp+0x327]
	mov [esi+aiselectioninfo.size],al

	mov ax,[ebp+0x2c2]
	call findindustrytype
	mov [esi+aiselectioninfo.sourcetype],al

	mov ax,[ebp+0x2d6]
	call findindustrytype
	mov [esi+aiselectioninfo.desttype],al

	mov ax,[ebp+0x2d6]
	mov cx,[ebp+0x2c2]
	sub al,cl
	jns .notxneg
	neg al
.notxneg:
	sub ah,ch
	jns .notyneg
	neg ah
.notyneg:
	add al,ah
	rcr al,1
	mov [esi+aiselectioninfo.distance],al

	mov al,[cargotypes+edx]
	mov [esi+aiselectioninfo.altcargotype],al

	movzx eax,bl
	shr eax,4
	movsx edi,byte [featurevarofs+eax*2]
	sub edi,byte -0x80
	sub esi,edi
	mov ah,1
	mov byte [curcallback],0x18
	mov byte [nostructvars],2
	extern structvarcustomhnd
	mov dword [structvarcustomhnd],cb18_var40xhnd
	mov [grffeature],al

	call getnewsprite
	mov byte [curcallback],0
	mov byte [nostructvars],0
	jc .nonewchoice
	mov bh,al
.nonewchoice:
	pop esi
	ret

// called when CB18 uses var 40+x or 60+x
//
// in:	eax=var
//	cl=parameter for 60+x
//	esi->80+x data or 0 if none
// out:	eax=var value
//	CF=0 var was ok
//	CF=1 invalid variable
// safe:ecx
cb18_var40xhnd:
	cmp eax,0x41
	cmc
	jc .done

	movzx eax,byte [aiselectioninfovar+aiselectioninfo.cargotype]
	mov ecx,[mostrecentspriteblock]
	mov ecx,[ecx+spriteblock.cargotransptr]
	mov al,[ecx+cargotrans.fromslot+eax]
.done:
	ret

// find industry type from XY coordinates in ax
//
// in:	ax=XY
// out:	al=industry type, or FF if town, or FE if unknown
//	carry set if unknown
// uses:ecx edi
//
findindustrytype:
	mov edi,[industryarrayptr]
	xor ecx,ecx
	mov cl,250

.nextind:
	cmp ax,[edi+industry.XY]
	je .gotind

	add edi,byte industry_size
	loop .nextind

	mov edi,townarray
	mov cl,70

.nexttown:
	cmp ax,[edi+town.XY]
	je .gottown

	add edi,byte town_size
	loop .nexttown

	mov al,0xfe
	stc
	ret

.gotind:
	mov al,[edi+industry.type]
	ret

.gottown:
	mov al,0xff
	ret


// action called when AI builds a rail wagon
//
// in:	ebx(8:23)=chosen vehicle type
//	ebx(24:31)=vehicle number
//	edx=cargo type
// out:	same
global ai_buildrailvehicle
ai_buildrailvehicle:
	test bl,2
	jnz .noidselection

	pusha

	movzx esi,byte [curplayer]
	imul esi,player_size
	add esi,[playerarrayptr]
	movzx eax,bh
	bt [isengine],eax
	mov al,[esi+0x39f]
	mov bl,[tracktypes+eax]
	jc .engine
	or bl,8
.engine:
	shld eax,ebx,8		// set al=ebx(24:31)
	call getaiselectioncallback
	mov [esp+0x11],bh	// bh from pusha

	popa

.noidselection:
	and ebx,0xffffff
	push edx
	push ebx
	mov esi,0x80		// buy rail vehicle
	and bl,~2
	call [actionhandler]
	mov ebp,ebx
	cmp ebx,0x80000000
	pop ebx
	pop edx

	push ebx
	jne .checkcargo

.fail:
	pop ebx
	mov ebx,0x80000000
	ret

.norefit:
	pop ebx
	mov ebx,ebp
	ret

.checkcargo:
	movzx ebx,bh
//	add ebx,[enginepowerstable]
	cmp [traincargotype+ebx],dl
	cmc
	je .norefit

	cmp byte [traincargosize+ebx],1
	jb .norefit

	pusha
	movzx eax,byte [esp+0x21]	// saved bh
	shl eax,16
	mov al,[traincargotype+ebx]
	push eax	// for getrailvehtypecargo

	and dword [trainplanerefitcost],0
	mov ebx,currefitlist
	mov [ebx+refitinfo.ctype],dl
	mov byte [ebx+refitinfo.cycle],0
	movzx eax,byte [cargotypes+edx]
	mov [ebx+refitinfo.type],al

	xor esi,esi
	test byte [esp+0x24],1
	jz .novehicle
	mov esi,edi
.novehicle:
	call getrailvehtypecargo
	call adjustcapacity
	pop eax		// refitted capacity, if refittable
	jz .notrefittable

	mov ebp,[trainplanerefitcost]
	sar ebp,7
	add ebp,[esp+8]
	test esp,esp	// clear ZF

.notrefittable:
	mov [esp+4],eax
	mov [esp+8],ebp
	popa

	jz .fail

	test byte [numheads+ebx],1
	jz .notdual
	mov ebx,[trainplanerefitcost]
	sar ebx,7
	add ebp,ebx
.notdual:
	pop ebx
	push ebx
	test bl,1
	jz .done

	mov [edi+veh.capacity],si
	mov [edi+veh.cargotype],dl

	movzx ebx,bh
	bt [isengine],ebx
	jnc .done

	mov ebx,edi

.nextveh:
	movzx ebx,word [ebx+veh.nextunitidx]
	cmp bx,byte -1
	je .done

	shl ebx,7
	add ebx,[veharrayptr]
	cmp word [ebx+veh.capacity],0
	je .nextveh

	mov [ebx+veh.capacity],si
	mov [ebx+veh.cargotype],dl
	jmp .nextveh

.done:
	pop ebx
	mov ebx,ebp
	ret

// action called when AI builds a road vehicle
//
// in:	ebx(8:31)=chosen vehicle type
//	edx=cargo type
// out:	same
global ai_buildroadvehicle
ai_buildroadvehicle:
	push ebx
	mov esi,0x88		// buy road vehicle
	call [actionhandler]
	mov ebp,ebx
	cmp ebx,0x80000000
	pop ebx

	push ebx
	jne .checkcargo

.fail:
	pop ebx
	mov ebx,0x80000000
	ret

.checkcargo:
	movzx edx,byte [currefitlist+refitinfo.ctype]
	movzx ebx,bh
	add ebx,[specificpropertybase+1*4]
	cmp [ebx-ROADVEHBASE+8*NROADVEHTYPES],dl	// cargo type
	je .norefit

	pusha
	movzx ecx,byte [esp+0x21]	// saved bh

	lea esi,[0x110000+ecx]
	push esi
	call getrefitmask
	pop esi
	mov dl,[currefitlist+refitinfo.type]

	bt esi,edx
	jnc .notrefittable

	test byte [esp+0x20],1
	jz .nocapacallback		// no vehicle for callback

	mov [edi+veh.cargotype],dl

	test byte [callbackflags+ecx],8
	jz .nocapacallback

	mov esi,edi
	mov eax,currefitlist
	call getcapacallback
	jc .nocapacallback

	mov [edi+veh.capacity],ax

.nocapacallback:
	movzx ebp,byte [rvrefitcost+ecx-ROADVEHBASE]
	test ebp,ebp
	jnz .gotit
	add ebp,14
.gotit:
	imul ebp,[roadvehbasevalue]
	sar ebp,9
	add [esp+8],ebp

	stc

.notrefittable:
	popa
	jnc .fail

.norefit:
	pop ebx
	mov ebx,ebp
	ret

// AI: build rail wagon (calls above action)
//
// in:	ebp=wagon number
//	(other register as for action call)
global aibuildrailwagon
aibuildrailwagon:
	and ebp,byte ~1
	shl ebp,23
	or ebx,ebp
	dopatchaction ai_buildrailvehicle
	ret

// AI: call action to build new engine when replacing
//
global aibuyrailengine
aibuyrailengine:
	movzx edx,byte [esi+0x326]
	or bl,2
	dopatchaction ai_buildrailvehicle
	ret

// AI: get cost of rail engine
global aigetrailenginecost
aigetrailenginecost:
	movzx edx,cl
	or bl,2
	dopatchaction ai_buildrailvehicle
	ret

// AI: call action to build new engine when replacing
//
// in:	esi->current engine (sold)
global aireplacerailengine
aireplacerailengine:
	movzx edx,byte [esi+veh.cargotype]	// cargo type still valid
	or bl,2
	dopatchaction ai_buildrailvehicle
	ret

// AI: select track type to use for next rail route
//
// in:	esi->company
// safe:eax ebx ecx edx others?
global aichoosetracktype
aichoosetracktype:
	cmp byte [esi+player.aiaction],6
	je .haverailroute
	ret

.haverailroute:
	pusha
	movzx eax,byte [esi+player.tracktypes]
	dec eax
	mov bh,[tracktypes+eax]
	mov bl,0xF
	mov dl,[esi+0x2cd]
	and edx,0x7f
	call getaiselectioncallback
	cmp bh,3
	jb .ok
	mov bh,3
.ok:
	movzx eax,bh
	mov al,[realtracktypes+eax]
	mov [esi+0x39f],al
	popa
	ret

var realtracktypes, db 0,0,1,2


// AI: sell wagons that don't fit because of extra engine heads
//
// in:	esi->company
//	edi->engine
// safe:edx ebp
global aisellextrawagons
aisellextrawagons:
	movzx ebp,byte [esi+0x327]
	add ebp,ebp
	push edi
.sellnext:
	cmp word [edi+veh.nextunitidx],byte -1
	je .done
	mov dx,-1
	xchg dx,[esi+0x338+ebp*2]
	mov bl,1
	pusha
	mov esi,0x20080		// sell rail wagon
	call [actionhandler]
	popa
	dec ebp
	movzx edi,word [edi+veh.nextunitidx]
	shl edi,7
	add edi,[veharrayptr]
	jmp .sellnext
.done:
	pop edi
	ret



uvard aicurconstructionobject

// called when AI tries to build a railway station
// in:	esi->company
// out:
// safe:
global aibuildrailstation
aibuildrailstation:
	// replaced code
	add di,[ebp+2]
	mov bh,ah

	pusha
	movzx edi,byte [curplayer]
	imul esi,edi,player_size
	add esi,[playerarrayptr]
	mov eax,[aicurconstructionobject]
	mov ebx,eax
	mov cl,20
	div cl

	cmp byte [esi+ebx+0x2c7],0xff

	mov bl,0x40
	mov bh,0
	movzx edx,byte [esi+0x326]
	call getaiselectioncallback
	jc .default

	xor eax,eax
	mov edx,[mostrecentspriteblock]

.findgameid:
	cmp bh,[stsetids+eax*stsetid_size+stsetid.setid]
	jne .nextid

	mov ecx,[stsetids+eax*stsetid_size+stsetid.act3info]
	jecxz .nextid

	// mov ecx,[ecx-6]
	cmp edx,[ecx+action3info.spriteblock]
	je .gotit

.nextid:
	inc eax
	cmp eax,[newstationnum]
	jbe .findgameid

.default:
	xor al,al
.gotit:
	movzx edi,byte [curplayer]
	mov [curselstationid+edi],al

	popa

	ret

	// called to record which station we're building (source or dest)
global aipickconstructionobject
aipickconstructionobject:
	mov [aicurconstructionobject],edi
	cmp byte [edi+esi+0x2c7],0xff
	ret



	// called when the ai checks whether a road vehicle is appropriate]
	// for the current service
	//
	// in:	edx->vehinfo
	// out:	CF=1 when allowed to build (will still check availability and reliability)
	// safe:ax ebp edi
global canaibuyrv
canaibuyrv:
	pusha
	mov al,0	// maybe change this for additional vehicles in same service?
	mov bl,0x10
	mov bh,-ROADVEHBASE

canaibuyveh:
	xchg eax,edx
	sub eax,vehtypearray	// nasm doesn't like lea eax,[edx-vehtypearray]
	mov dh,vehtype_size
	div dh
	add bh,al
	mov al,dl
	movzx edx,byte [curplayer]
	imul edx,player_size
	add edx,[playerarrayptr]
	movzx edx,byte [edx+0x326]
	call getaiselectioncallback
	jc .avail
	mov bl,0
	cmp bl,bh	// set carry if bh>0
.avail:
	popa

	movzx ebp,byte [curplayer]	// overwritten
	ret

global canaibuyship
canaibuyship:
	pusha
	mov al,0
	mov bl,0x20
	mov bh,-SHIPBASE
	jmp canaibuyveh

global canaibuyplane
canaibuyplane:
	pusha
	mov al,0
	mov bl,0x30
	mov bh,-AIRCRAFTBASE
	jmp canaibuyveh

	// called to get the list of vehicle to try
	//
	// in:	edx=cargo type
	// out:	bl=number of consecutive vehicles to try
	//	dx=first vehicle ID to try
	// safe:ebx edx ebp
global aigetrvlist
aigetrvlist:
	mov ebp,edx
	mov bl,[aicargovehicletable+aicargovehicle.roadnum+edx]
	mov dl,[aicargovehicletable+aicargovehicle.road+edx*2]
	mov bh,0x10
	mov dh,ROADVEHBASE

aigetvehlist:
	pusha
	mov edx,ebp
	mov ebp,currefitlist
	mov [ebp+refitinfo.ctype],dl
	mov byte [ebp+refitinfo.cycle],0
	movzx eax,byte [cargotypes+edx]
	mov [ebp+refitinfo.type],al

	mov al,0
	xchg bh,bl
	or bl,1
	call getaiselectioncallback
	jc .nonewnumber
	mov [esp+0x10],bh	// bl from pusha
.nonewnumber:
	mov al,0
	inc bl
	mov bh,[esp+0x14]	// dl from pusha
	sub bh,[esp+0x15]
	call getaiselectioncallback
	jc .nonewid
	add bh,[esp+0x15]
	mov [esp+0x14],bh
.nonewid:
	popa
	mov dh,0
	ret


global aigetshiplist
aigetshiplist:
	mov ebp,edx
	mov bl,[aicargovehicletable+aicargovehicle.shipnum+edx]
	mov dl,[aicargovehicletable+aicargovehicle.ship+edx*2]
	mov bh,0x20
	mov dh,SHIPBASE
	jmp aigetvehlist
