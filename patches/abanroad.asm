// Make abandoned roads lose their owner
// A road is considered to be abandoned if no vehicles use it for a while
// This feature makes it possible to remove AI roads that aren't used anymore

#include <std.inc>
#include <veh.inc>
#include <town.inc>
#include <ptrvar.inc>

extern abanroadmode,directions,tunnelotherendfn

// It works this way:
// We store a timer in the new landscape6 array. Every passing vehicle
// increases this counter if it's driving on its own road. However,
// it decreases with time, and the tile loses its owner if it reaches
// zero. Additionally, if a vehicle drives on a road owned by nobody,
// it gets its ownership for a period of time, allowing other players to
// re-use roads abandoned by others.

// Convert game days to time units used here (1 unit=256 game ticks)
%define daystounits(x) ((x)*74/256)

// How much a vehicle adds to the expiry time of the tile
%assign VEHABANDONINCREASE daystounits(2*30)

// Maximum expiry time
%assign MAXABANDONTIME daystounits(2*365)

// Expiry time for newly built roads
global FIRSTBUILDABANDON
FIRSTBUILDABANDON equ daystounits(365)

// Auxiliary: get the owner of the road of a class 2 tile
// in:	ebx: tile XY
// out:	cl:owner
global getroadowner
getroadowner:
	test byte [landscape5(bx)],16
	jnz .crossing

	mov cl,[landscape1+ebx]
	ret

.crossing:
	mov cl,[landscape3+ebx*2]
	ret

// Auxiliary: set the owner of the road of a class 2 tile
// in:	ebx: tile XY
//	cl: new owner
global setroadowner
setroadowner:
	test byte [landscape5(bx)],16
	jnz .crossing

	mov [landscape1+ebx],cl
	ret

.crossing:
	mov [landscape3+ebx*2],cl
	ret

// Auxiliary: set the owner of a class 9 tile. For tunnel entrances and bridge heads, set both ends.
// in:	ebx: tile XY
//	cl: new owner
setclass9owner:
	pusha

	mov [landscape1+ebx],cl		// the current tile must be updated in all cases

	mov dl,[landscape5(bx)]		// is it a bridge
	test dl,0xf0
	jnz .claimbridge

	mov edi,ebx		// no, it's a tunnel - use TTD's internal function to find the other end
	mov ebx,edx
	and ebx,3
	shl ebx,1
	inc ebx
	mov edx,ecx
	mov esi,2
	call dword [tunnelotherendfn]
	movzx edi,di
	mov [landscape1+edi],dl		// update the other end
	jmp short .claimdone

.claimbridge:
	test dl,64			// if it's a mid-part, we are finished
	jnz .claimdone

	mov eax,2			// calculate the direction we must go
	test dl,1
	jz .xdir
	dec eax
.xdir:
	test dl,32
	jz .northern
	xor eax,2
.northern:
.bridgeloop:
	add bx,[directions+eax*2]	// the array is defined in manuconv.asm
	mov dl,[landscape4(bx)]		// is this a class 9 tile?
	and dl,0xf0
	cmp dl,0x90
	jne .claimdone			// nope (something must have gone wrong)
	test byte [landscape5(bx)],64	// if it's not an end, go to the next tile
	jnz .bridgeloop

	mov [landscape1+ebx],cl		// update the other bridge head

.claimdone:
	popa
	ret	

var roadadjacent, dw -0x100-1, -0x100, -0x100+1, -1, +1, +0x100-1, +0x100, +0x100+1

// Auxiliary function to decide wether a road is in a town
// in: ebx: XY of tile
// out: cl=0x10 and carry clear if there's no adjacent house
//	cl=town number+0x80 and carry set if there's a house next to the road tile
gettownofroad:
	push eax
	push ecx
	push edi

	xor ecx,ecx
	mov cl,8

.tileloop:
	mov edi,ebx
	add di,[roadadjacent+(ecx-1)*2]
	mov al,[landscape4(di)]
	and al,0xf0
	cmp al,0x30
	je .hashouse

	loop .tileloop

	clc
	pop edi
	pop ecx
	mov cl,0x10
	pop eax
	ret

.hashouse:
	push ebx
	push esi
	push ebp
	mov eax,edi
	mov ebp,[ophandler+(3*8)]
	xor ebx,ebx
	mov bl,1
	call dword [ebp+4]		// returns the nearest town ptr in EDI and distance in BP; scrambles BX,ESI
	mov eax,edi
	sub eax,townarray
	mov bl,town_size
	div bl
	pop ebp
	pop esi
	pop ebx
	pop edi
	pop ecx
	mov cl,al
	or cl,0x80
	pop eax
	stc
	ret

// Called when a vehicle leaves a road tile
// in:	ebx: XY of the road tile
//	dl=dh: landscape5 entry for the tile
//	edi -> vehicle

global vehleaveroadtile
vehleaveroadtile:
	and dh,0xf0	// overwritten
	push eax
	push ecx

	test dh,32	// no depots
	jnz .exit

	cmp byte [edi+veh.class],0x11	// RVs only
	jne .exit

//	mov eax,[landscape6ptr]		// get the address of the L6 entry
//	add eax,ebx
	lea eax,[landscape6+ebx]

	call getroadowner

	cmp cl,0x10
	je .claimit			// if this road has no owner, get its ownership

	cmp cl,[edi+veh.owner]		// don't increase timer if the road is someone else's
	jne .exit

	movzx ecx,byte [eax]
	jmp short .timerok

.claimit:
	mov cl,[edi+veh.owner]	// get the ownership of the road
	call setroadowner

	xor ecx,ecx

.timerok:
	add ecx,VEHABANDONINCREASE	// increase timer, but don't allow it to be too much
	cmp ecx,MAXABANDONTIME
	jbe .nooverflow
	mov ecx,MAXABANDONTIME
.nooverflow:
	mov [eax],cl			// put timer back to L6
	
.exit:
	pop ecx
	pop eax
	cmp dh,0x10	// overwritten
	ret

// Called in every 256 ticks for road tiles
// in:	ebx: XY of the tile
//	???
// safe: (e)ax, (e)cx, ???
global periodicroadproc
periodicroadproc:
	test byte [landscape5(bx)],32	// no depots
	jnz .exit

	call getroadowner

	cmp cl,8	// only company-owned roads
	jae .exit

	cmp byte [abanroadmode],2	// in mode 2, towns always claim all roads near houses
	jne .notownclaim
	call gettownofroad
	jc .setowner

.notownclaim:
//	mov eax,[landscape6ptr]		// get the address of the L6 entry
//	add eax,ebx
	lea eax,[landscape6+ebx]
	mov cl,[eax]
	dec cl			// decrease timer
	mov [eax],cl			// put timer back
	jnz .notexpired

	mov cl,0x10
	cmp byte [abanroadmode],1	// in mode 1, expired roads near houses are claimed by the town
	jne .setowner
	call gettownofroad

.setowner:
	call setroadowner	// the ownership expired - make it owned by nobody

.notexpired:
.exit:
	cmp byte [climate],2	// overwritten
	ret

// Called when a road is built on an empty tile. Update landscape6 here.
// in:	esi: XY of the tile
//	???
global buildnewroad
buildnewroad:
	and byte [landscape4(si)],0xf	// overwritten
	or byte [landscape4(si)],0x20	// by the runindex call
	cmp byte [curplayer],8
	jae .exit
//	push eax
//	mov eax,[landscape6ptr]
	mov byte [landscape6+esi],FIRSTBUILDABANDON
//	pop eax
.exit:
	ret

// Called when a road is built on a railway tile. Update landscape6 here.
// in:	on stack: saved bx (proceed only if bit 0 is set)
//	si: XY of the tile
//	???
// safe: edi,???
global buildroadtorail
buildroadtorail:
	test byte [esp+4],1
	jmp short buildroadunderbridge.checkdone

// Called when a road is built under a bridge. Update landscape6 here.
// in:	bx bit 0 clear if checking cost only
//	???
// safe: edi
global buildroadunderbridge
buildroadunderbridge:
	test bl,1
.checkdone:
	jz .dontdoit

	cmp byte [curplayer],8
	jae .dontdoit

	movzx esi,si		// later code would do this anyway
//	mov edi,[landscape6ptr]
	mov byte [landscape6+esi],FIRSTBUILDABANDON

.dontdoit:
	mov edi,[roadbuildcost]
	ret

// Called when building a tunnel, once for both entries
// in:	bh: landscape5 entry
//	esi: tile XY
// safe: dl
global buildtunnel
buildtunnel:
	test bh,4	// not for railway tunnels
	jz .dontdoit

	cmp byte [curplayer],8
	jae .dontdoit

	mov dl,bh
	and dl,3

	or dl,dl	// only for southern entrances
	jz .doit	// the ownership of northern ends will always be the same as the southern one
	cmp dl,3
	jne .dontdoit

.doit:
//	push eax
//	mov eax,[landscape6ptr]
	mov byte [landscape6+esi],FIRSTBUILDABANDON
//	pop eax
.dontdoit:
	mov dl,[curplayer]	// overwritten
	ret

// Called when a vehicle enters, moves on or leaves a class 9 tile
// in:	dl: 0: entering or moving on tile; 1: leaving tile
//	edi-> vehicle
//	bx: tile XY
// safe: ebp,???

global vehenterleaveclass9
vehenterleaveclass9:
	test dl,dl
	jnz .leavetile		// the original handler simply returns here
#if WINTTDX
	push ebx
	movzx ebx,bx
#endif
	test byte [landscape5(bx)],0xf0	// overwritten
#if WINTTDX
	pop ebx
#endif
	ret

.leavetile:
	pusha

	cmp byte [edi+veh.class],0x11
	jne near .exit

	movzx ebx,bx
	mov dl, byte [landscape5(bx)]
	test dl,0xf0
	jnz .bridge

	test dl,4		// no railway tunnels
	jz near .exit

	mov al,dl
	and al,3

// for some reason, more leave events are generated after entering a tunnel.
// to avoid increasing the timer too many times, consider leaving tunnels only
	mov ah,[edi+veh.direction]
	shr ah,1
	cmp ah,al
	je .exit

	or al,al		// southern entrances are OK
	jz .inctimer
	cmp al,3
	jz .inctimer
// for northern entrances, find the other end and use that
	push edi
	mov edi,ebx
	movzx ebx,al
	shl ebx,1
	inc ebx
	mov si,2
	call dword [tunnelotherendfn]
	movzx ebx,di
	pop edi
	jmp short .inctimer

.bridge:
	test dl,64
	jz .bridgehead

	mov dl,[landscape4(bx)]	// only vehicles under the bridge count, those going on the bridge don't
	and dl,0x0f
	shl dl,3
	cmp dl,[edi+veh.zpos]
	je .inctimer
	jmp short .exit

.bridgehead:
	test dl,2		// no railway bridges
	jz .exit
	test dl,32		// northern bridge heads only - southern heads will have the same owner
	jnz .exit

.inctimer:
	lea eax,[landscape6+ebx]	// get the address of the landscape6 entry

	mov cl,byte [landscape1+ebx]	// claim it if necessary
	cmp cl,0x10
	je .claimit

	cmp cl,[edi+veh.owner]		// only the owner's vehicles
	jne .exit

	movzx ecx,byte [eax]		// get the timer
	jmp short .timerok

.claimit:
	mov cl,[edi+veh.owner]		// get the ownership of the road
	call setclass9owner

	xor ecx,ecx

.timerok:
	add ecx,VEHABANDONINCREASE	// increase timer, but don't allow it to be too much
	cmp ecx,MAXABANDONTIME
	jbe .nooverflow
	mov ecx,MAXABANDONTIME
.nooverflow:
	mov [eax],cl			// put timer back to L6

.exit:
	popa
	pop ebp				// return to the caller's caller
	ret
	
// Called in every 256 ticks for class 9 tiles
// in:	ebx: XY of the tile
//	???
// safe: (e)ax, (e)cx, ???
global periodicclass9proc
periodicclass9proc:
	cmp byte [landscape1+ebx],8	// only company-owned bridges and tunnels
	jae .exit

	mov al,[landscape5(bx)]
	test al,0xf0
	jnz .bridge

	test al,4		// no railway tunnels
	jz .exit

	and al,3

	or al,al		// southern entrances only
	jz .dectimer
	cmp al,3
	jz .dectimer
	jmp short .exit

.bridge:
	test al,64
	jnz .midpart
	test al,2		// no railway bridges
	jz .exit
	test al,32		// northern bridge heads only - southern heads will have the same owner
	jnz .exit
	jmp short .dectimer

.midpart:
	test al,32		// only if street is under the bridge
	jz .exit
	test al,8
	jz .exit

.dectimer:
	cmp byte [abanroadmode],2	// in mode 2, towns always claim all roads near houses
	jne .notownclaim
	call gettownofroad
	jc .setowner

.notownclaim:
//	mov eax,[landscape6ptr]	// get the address of the landscape6 entry
//	add eax,ebx
	lea eax,[landscape6+ebx]
	mov cl,[eax]
	dec cl			// decrease timer
	mov [eax],cl			// put timer back
	jnz .notexpired

	mov cl,0x10
	cmp byte [abanroadmode],1	// in mode 1, expired roads near houses are claimed by the town
	jne .setowner
	call gettownofroad

.setowner:
	call setclass9owner

.notexpired:
.exit:
	cmp byte [climate],2	// overwritten
	ret

// Called when building the northern head of a bridge. Update landscape6 here.
// in:	(e)si: tile XY
//	dl: landscape5 entry
// safe: dl,???
global buildbridgenorthhead
buildbridgenorthhead:
#if !WINTTDX
	movzx esi,si
#endif
	mov [landscape5(si)],dl		// overwritten

	test dl,2			// no railway bridges
	jz .exit

	cmp byte [curplayer],8
	jae .exit

//	push eax
//	mov eax,[landscape6ptr]
	mov byte [landscape6+esi],FIRSTBUILDABANDON
//	pop eax
.exit:
	ret
