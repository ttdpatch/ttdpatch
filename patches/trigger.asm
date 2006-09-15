//
// Random action 2 trigger handling
//

#include <std.inc>
#include <flags.inc>
#include <station.inc>
#include <veh.inc>
#include <industry.inc>
#include <grf.inc>
#include <house.inc>

extern curcallback,curstationtile,getindustileid,getirrplatformlength
extern getnewsprite,grffeature,invalidatetile,irrgetrailxysouth
extern patchflags,randomfn,redrawtile,statcargotriggers
extern stationidgrfmap
extern updatestationgraphics,convertplatformsinecx


uvard triggerbits	// all bits which have triggered in this event
uvard curtriggers	// all triggers that occured in this event
global acttriggers
acttriggers equ (curtriggers+1)	// all triggers which need to be cleared again

uvard septriggerbits,2	// trigger bits for the "normal" and the "other" thing, separated
%define normaltriggerbits septriggerbits
%define othertriggerbits (septriggerbits+4)

// activate random trigger event for vehicle,
// and update random byte if so desired
//
// in:	 al=trigger bit(s)
//	esi=vehicle
// out:	-
// destroys eax
global randomtrigger
randomtrigger:
	call checkvehtriggerbits
	jz randomcalldone

	not eax
	and [esi+veh.random],al
	and [esi+veh.newrandom],ah

	call dword [randomfn]
	mov ah,[triggerbits]
	and al,ah
	or [esi+veh.random],al

randomcalldone:
	and dword [normaltriggerbits],0
	and dword [othertriggerbits],0
	and dword [triggerbits],0
	and dword [curtriggers],0
	ret

checkvehtriggerbits:
	or [esi+veh.newrandom],al

	mov al,[esi+veh.class]
	sub al,0x10
	mov [grffeature],al

	mov al,[esi+veh.newrandom]
	mov [curtriggers],al

	movzx eax,byte [esi+veh.vehtype]
	call checktriggerbits
	ret

checktriggerbits:
	mov byte [curcallback],1
	call getnewsprite
	mov byte [curcallback],0
	mov eax,[triggerbits]
	test eax,eax
	mov ah,[acttriggers]
	ret


// same as above, but apply trigger to all vehicles of consist, and if any
// vehicle has it, set random var to the same value for all vehicles
// with this trigger
global randomconsisttrigger
randomconsisttrigger:
	pusha

	push eax
	mov ch,0
	jmp short .checktriggers

.istriggered:
	call [randomfn]
	mov cl,al

.checktriggers:
	movzx esi,word [esi+veh.engineidx]

.donextveh:
	call randomcalldone		// reinitialize for next vehicle
	mov eax,[esp]
	shl esi,vehicleshift
	add esi,[veharrayptr]
	call checkvehtriggerbits
	jz .nottriggeredyet

	test ch,ch	// still checking for trigger?
	mov ch,1
	jz .istriggered	// yep, so start over and set the random var

	not eax
	and [esi+veh.random],al
	and [esi+veh.newrandom],ah

	not al
	and al,cl
	or [esi+veh.random],al

.nottriggeredyet:
	movzx esi,word [esi+veh.nextunitidx]
	cmp si,-1
	jne .donextveh

	pop eax
	popa
	jmp randomcalldone


// and now for stations
// in:	 al=trigger bit(s)
//	 ah=bits 0..3: platform number, bit 5: use ecx for platform number, bit 6: redraw, bit 7: all platforms
//	ebx->station
//	ecx=platform number if bit 5 of ah set
//	edx=bit mask of cargo types
//	[curstationtile] set if ah bit 7 clear
// destroys all registers
//
// first goes through all tiles to see if one triggers
// if one triggers, it starts over and goes through all tiles
// re-randomizing the tile random bits as needed
// and finally re-randomizes the station random bits
global randomstationtrigger
randomstationtrigger:
	test byte [ebx+station.facilities],1
	jnz .hasrailway
	ret

.startxy: dw 0
.numxy: dw 0
.tempplatnum: db 0

.hasrailway:
	push eax
	mov [.tempplatnum], cl

	// setup .startxy and .numxy
	movzx esi,word [ebx+station.railXY]
	mov [.startxy],si

	testmultiflags irrstations
	jnz .getirrsize

	mov cl,[ebx+station.platforms]
	xchg ebx, esi
	call convertplatformsinecx
	xchg cl, ch
	//cl=length,ch=tracks
	xchg ebx, esi
	mov al,[landscape5(si,1)]
	xor al,1
	and eax,1		// orientation (0=y, 1=x)

	test byte [esp+1],0x80
	js .alltracks
	test byte [esp+1],0x20
	jz .norm1
	mov ch, [.tempplatnum]
	jmp .anorm1
	.norm1:
	mov ch,[esp+1]
	and ch,15
	.anorm1:
	add [.startxy+eax],ch
	mov ch,1
.alltracks:
	// now cl = length, ch = tracks
	test eax,eax
	jnz .notflip
	xchg ch,cl
.notflip:
	// now cl=numx ch=numy
	mov [.numxy],cx
	xor eax,eax
	jmp short .checktriggers

.getirrsize:
	mov esi,ebx
	push edx
	call irrgetrailxysouth
	sub dx,[ebx+station.railXY]
	lea ecx,[edx+0x0101]		// now ecx=XY size
	pop edx
	test ah,ah
	js .gotirrsize

	// only a single platform, need to work from curstationtile
	mov esi,[curstationtile]
	call getirrplatformlength
	mov [.startxy],si
	mov ch,1
	mov cl,al
	test byte [landscape5(si,1)],ch
	jz .gotirrsize
	xchg cl,ch
.gotirrsize:
	mov [.numxy],cx
	xor eax,eax
	jmp short .checktriggers

.istriggered:
	or eax,byte -1
	mov al,[esp]
	or [ebx+station.newrandom],al
	mov al,[ebx+station.newrandom]
	mov [curtriggers],al

.checktriggers:
	movzx esi,word [.startxy]
	mov ch,[.numxy+1]

.donextY:
	xchg eax,esi
	mov al,[.startxy]
	xchg eax,esi

	mov cl,[.numxy]

.donextX:
	movzx edi,byte [landscape4(si,1)]
	and edi,byte ~0x0f
	cmp edi,0x50
	jne near .nottriggered

	cmp byte [landscape5(si,1)],8
	jae near .nottriggered

	movzx edi,byte [landscape3+esi*2+1]
	movzx edi,byte [stationidgrfmap+edi*8+stationid.gameid]
	mov ebp,[statcargotriggers+edi*4]
	and ebp,edx
	jz near .nottriggered
	test edx,edx
	jns .rightcargo
	cmp ebp,[statcargotriggers+edi*4]
	jne .nottriggered

.rightcargo:
	test eax,eax
	jns .istriggered

	// has the right cargo that might trigger this tile

	mov byte [grffeature],4

	push eax
	mov eax,edi
	mov [curstationtile],esi
	xchg esi,ebx
	call checktriggerbits
	xchg esi,ebx
	pop eax
	jz .nottriggered

	mov al,[triggerbits+2]
	test al,al
	jz .nottriggered	// triggered, but no tile-random bits

	and al,0x0f
	not al
	mov ebp,landscape6
	and [esi+ebp],al

		// re-randomize tile random bits
	call [randomfn]
	mov ah,[triggerbits+2]
	and al,ah
	and al,0x0f
	or [esi+ebp],al
	or eax,byte -1

		// see if we need to update the graphics
	cmp byte [triggerbits],0
	jne .nottriggered	// will redraw whole station anyway
	test byte [esp+1],0x40
	jz .nottriggered	// we're not redrawing anyway

	pusha
	mov eax,esi
	movzx ecx,ah
	movzx eax,al
	shl ecx,4
	shl eax,4
	call [invalidatetile]
	popa


.nottriggered:
	inc esi
	dec cl
	jnz .donextX

	add si,0x100
	dec ch
	jnz .donextY

	test eax,eax
	jns .done

	mov al,[acttriggers]
	not al
	and [ebx+station.newrandom],al

	// and re-randomize the station random bits plus reset the triggers
	mov al,[triggerbits]
	test al,al
	jz .done

	not al
	and [ebx+station.random],al

	call [randomfn]
	mov ah,[triggerbits]
	and al,ah
	or [ebx+station.random],al

	// and force redrawing if desired
	test byte [esp+1],0x40
	jz .done

	mov esi,ebx
	call updatestationgraphics

.done:
	pop eax
	jmp randomcalldone

//uvarb currhousetrigger

checkhousetriggerbits:
	and al,~0xc0
//	mov [currhousetrigger],al
	or byte [landscape3+2*esi],al
	mov byte [grffeature],7
	mov al,byte [landscape3+2*esi]
	and al,~0xc0
	mov [curtriggers],al
	mov eax,ebp
	call checktriggerbits
//	jz .exit
//	test ah,[currhousetrigger]
//.exit:
	ret

// The same for a house tile
global randomhouseparttrigger
randomhouseparttrigger:
	pusha
	mov esi,ebx
	call checkhousetriggerbits
	jz .done

	not eax
	mov ebp,landscape6
	and [ebp+esi],al
	or ah,0xc0
	and byte [landscape3+2*esi],ah

	call dword [randomfn]
	mov ah,[triggerbits]
	and al,ah
	or [ebp+esi],al
	call redrawtile
.done:
	popa
	jmp randomcalldone

var housepartoffsets, dw 0,0x100,1,0x101

// The same for a whole house (doesn't do anything if it's not the north tile of the house,
// but if it is, it activates the trigger for the other part as well, and every matching
// tile gets the same random bits)
global randomhousetrigger
randomhousetrigger:
	pusha
	push eax
	xor ch,ch
	mov edx,ebx
	jmp short .startsearch

.restartsearch:
	call [randomfn]
	mov ch,1
	mov cl,al

.startsearch:
	mov edi,housepartoffsets
	mov bl,8

.loop:
	test [newhousepartflags+ebp+128],bl
	jz .next

	call randomcalldone
	mov eax,[esp]
	mov esi,edx
	add si,[edi]
	call checkhousetriggerbits
	jz .next

	or ch,ch
	jz .restartsearch

	not eax
	or ah,0xc0
	and byte [landscape3+2*esi],ah
	call redrawtile
	add esi,landscape6
	and [esi],al

	not al
	and al,cl
	or [esi],al

.next:
	inc edi
	inc edi
	shr bl,1
	jnz .loop

	pop eax
	popa
	jmp randomcalldone

checkindustiletriggerbits:
	mov ebp,landscape7
	or byte [ebp+esi],cl
	mov byte [grffeature],9
	mov cl,byte [ebp+esi]
	mov [curtriggers],cl
	movzx eax,al
	call checktriggerbits
	ret

// And now for something completely different: industry tiles
industileprocrandom:
	pusha
	mov esi,ebx
	call checkindustiletriggerbits
	jz .done

	mov al,[normaltriggerbits]
	not eax
	mov ebp,landscape6
	and [ebp+esi],al
	mov edx,landscape7
	and [edx+esi],ah

	call dword [randomfn]
	mov ah,[normaltriggerbits]
	and al,ah
	or [ebp+esi],al
	call redrawtile
.done:
	popa
	ret

global randomindustiletrigger
randomindustiletrigger:
	call industileprocrandom
	jmp randomcalldone

global randomindustrytrigger
randomindustrytrigger:
	pusha
	movzx ebx,word [esi+industry.XY]
	movzx ecx,byte [esi+industry.dimensions]

.yloop:
	push ebx
	push ecx

	movzx ecx,byte [esi+industry.dimensions+1]
.xloop:
	mov dl,[landscape4(bx)]
	and dl,0xf0
	cmp dl,0x80
	jne .dontneed

	movzx edx,byte [landscape2+ebx]
	imul edx,industry_size
	add edx,[industryarrayptr]
	cmp edx,esi
	jne .dontneed

	call getindustileid
	jnc .dontneed
	xchg ecx,edi
	call industileprocrandom
	xchg ecx,edi

	mov edx,[othertriggerbits]
	call randomcalldone
	mov [othertriggerbits],edx

.dontneed:
	inc bl
	loop .xloop

	pop ecx
	pop ebx
	inc bh
	loop .yloop

	mov edx,[othertriggerbits]
	push edx
	not edx
	and [esi+industry.random],dx

	call [randomfn]
	pop edx
	and eax,edx
	or [esi+industry.random],ax

	popa
	jmp randomcalldone
