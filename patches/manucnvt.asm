// Manual converting of track types

#include <std.inc>
#include <flags.inc>
#include <textdef.inc>
#include <veh.inc>

extern calctrackcostdifference,curmiscgrf,invalidatetile,isrealhumanplayer
extern mostrecentspriteblock,patchflags,specialerrtext1,texthandler
extern vehtypecallback
extern wantedtracktypeofs

extern enhancetunneladdtrack



uvard trackcostadjust
// Despite its name, this variable may also contain the final cost temporarily
// See also addbuildtrackcost in railcost.asm

// First some helper functions

// Redraw a tile given in si
global redrawtile
redrawtile:
	pusha
	mov ax,si	// convert coordinates (si: 1234h -> ax: 0340h cx: 0120h)
	mov cx,si
	shl ax,4
	shr cx,4
	and ah,0x0f
	and cl,0xf0
	call [invalidatetile]
	popa
	ret

// Check if there is a vehicle on the tile given in esi
// If there is, it sets operrormsg2 accordingly
// zf clear -> vehicle in the way
global checkvehintheway
checkvehintheway:
	push di
	mov di,si
	call $
ovar fncheckvehintheway, -4
	pop di
	ret
	
// Calculates the cost of converting one track piece
// In: dl: the type to convert from
//
// Out: dl: the type to convert to
//	edi: cost of conversion
//		OR
//	zf set if the source and destination types are the same

getconvertcost:
	push ebx
	mov ebx,[wantedtracktypeofs]
	mov bh,[ebx]	// bh contains what type the user wants
	cmp bh,dl
	je .error	// don't convert to the same type
	mov bl,dl
	mov dl,bh	// now  dl , bh = type to convert to
			//	bl = type to convert from
	
	testflags tracktypecostdiff
	jnc short .allcostthesame

	push eax
	mov eax,[trackcost]
	call calctrackcostdifference
	mov edi, eax
	mov dl,bl
	mov eax,[tracksale]
	call calctrackcostdifference
	add edi, eax
	mov dl, bh
	pop eax

	jmp short .end

.allcostthesame:
	mov edi,[trackcost]	// default cost is the difference of laying and removing a track
	add edi,[tracksale]

	testflags electrifiedrail
	jnc .defaultcost
	cmp bx,0x0100	// putting pylons on a normal railway
	je .putpylons
	cmp bx,0x0001	// removing pylons from railway
	je .removepylons
	cmp bx,0x0201	// converting electrified to maglev
	je .electomaglev
	cmp bx,0x0102	// converting maglev to electrified
	je .maglevtoelec
	jmp short .defaultcost

.removepylons:	// the income of removing pylons is the half of normal converting
.maglevtoelec:
	shr edi,1
	neg edi
	jmp short .end

.putpylons:	// same for the cost of pylons
.electomaglev:
	shr edi,1
	jmp short .end

.defaultcost:
.end:
	or edi,edi	// clear zero flag
.error:
	pop ebx
	ret

// Constants that should be added to a coordinate to move to the given direction
varw directions, -1,256,1,-256	// NE,SE,SW,NW

// Note: returning 0x1007 ("Already built") in operrormsg2 has the side effect of
// not interrupting laying tracks when doing it by dragging the mouse. All other
// error messages stop the process, so next tracks won't be built.

// Called after checking for vehicles in the given tile
// If zf clear, there is a vehicle in the way
// We've owerwritten the near jump that checks for that, so we report error manually if zf is clear,
// except for depots, where we allow the operation anyway, to allow the player to change the locomotive
// without selling the whole consist.
// Since building tracks on a station is never allowed in normal TTD, it doesn't have a special case,
// so we need to handle it here, too.
//
// in:  di: coordinates of the tile to build on
//	bh: direction of track to build (for values, see possible bits of landscape5 for rails)
//	bl: bit 0 is clear if checking cost only
//
// out: returning normally means allow continuing building
//	ebx should be set if exiting handler
//
// safe: if returning normally: edx, esi
//	 if exiting the handler: ebx, edx, esi, edi

global trackbuildcheckvehs
trackbuildcheckvehs:
	mov dword [trackcostadjust],0	// this is the first modification in the handler, reset trackcostadjust here
	movzx edi,di	// the upper word of edi isn't used in the handler anyway
	je .checkforstation

.vehintheway:
	call isrealhumanplayer
	jnz .notallow	// don't allow AI players to convert anything

	mov dl,[landscape4(di)]	// is it a rail tile?
	and dl,0xf0
	cmp dl,0x10
	jne .notallow

	mov dl,[landscape5(di)]	// is it a depot?
	and dl,0xc0
	cmp dl,0xc0
	je .end	// it's a depot - allow continuing

.notallow:
	mov ebx,0x80000000	// ebx will indicate an error
	add esp,4	// drop our return address and..
	ret		// return to the caller's caller (exit handler)

.checkforstation:
	mov dh, [landscape4(di)]	// is it a station?
	and dh,0xf0
	cmp dh,0x50
	je .station
.end:
	ret

.station:
// if we got here, then returning normally will cause an error ("Must remove station first"), so we have to
// exit the handler if everything is OK. If there's an error, though, we can return normally to show this
// message.

	mov dh,[landscape5(di)]		// is it a railway station?
	cmp dh,8
	jae .end

	mov word [operrormsg2],0x1024	// ...area is owned by another company
					// we will override this anyway if we allow continuing
	mov dl,[landscape1+edi]	// check owner
	cmp dl,[curplayer]
	jne .notallow	// exit the handler in order to preserve our operrormsg2

	test dh,1	// odd numbers in landscape5 means NESW orientation
	jz .nesw
	
	cmp bh,2	// allow only with the right rail direction
	jne .end
	jmp short .checktype

.nesw:
	cmp bh,1	// ditto
	jne .end

.checktype:

	mov word [operrormsg2],0x1007	// ...already built
	mov esi,edi	// get convert cost
	mov dl,[landscape3+esi*2]
	call getconvertcost
	je .notallow	// show a more accurate error message

	test bl,1
	jz .dontdoit
	mov [landscape3+esi*2],dl	// change the type
	call redrawtile

.dontdoit:
	mov ebx,edi
	add esp,4
	ret	// exit the handler
	
// Called after learning that the tile we want to build on has the type 9 (bridge or tunnel)
// Handle building on bridge ends and tunnel entrances here
// Converting under bridges is done in the error handler, so we must return an error if
// something is under  the bridge.
//
// In:  si: coordinates of the tile to build on
//	bh: direction of the track to build
//	bl: bit 0 clear if checking cost only
//	dh: landscape5 byte for the given tile
//
// Out: zf set -> tile under the bridge is clear, do normal building under bridge
// 	zf clear -> jump to error handler (and buildtrackunderbridge)
//			if dl<>0xe0, "Must remove xxx first" appears without calling buildtrackunderbridge
//			(can be used to exit with an error)
//
// safe: if returning normally: none
//	 if exiting the handler: ebx, edx, esi, edi
	 
global buildtrackonbridgeortunnel,buildtrackonbridgeortunnel.notdefault
buildtrackonbridgeortunnel:
	mov dl,dh	// overwritten
	and dl,0xf8	// by the runindex
	cmp dl,0xc0	// call
	jne near .notdefault
.end:
	ret

.tunnelwrongdirection:
	testflags enhancetunnels
	jc near enhancetunneladdtrack
	// jmp enhancetunneladdtrack
	ret

.gotoerror:
	or esi,esi
	ret

.tunnel:
	test dh,4	// don't convert road tunnels
	jnz .end

//	mov dl,[landscape3+esi*2]	// get convert cost
//	call getconvertcost
//	je .gotoerror

	test dh,1	// odd numbers (1 and 3) mean NESW orientation
	jz .neswtun
	cmp bh,2	// allow only with the right rail direction
	jne .tunnelwrongdirection
	jmp short .doconverttunnel

.neswtun:
	cmp bh,1	// same as above
	jne .tunnelwrongdirection
	
.doconverttunnel:
	mov dl,[landscape3+esi*2]	// get convert cost
	call getconvertcost
	je .gotoerror

	push eax
	push ecx
	mov ecx,edi	// ecx will store the final cost
	test bl,1
	jz .noconverttun1
	mov [landscape3+esi*2],dl	// convert the entrance the player clicked on
	call redrawtile
.noconverttun1:
	mov bh,[landscape4(si)]	// get the landscape4 byte for the entrance
				// the other end will have the same byte with one height difference
	movzx eax,dh	// put direction of entrance in eax
	and al,3
	xor dh,2	// toggle bit 1 in dh, so it becomes the landscape5 value of the other end
	dec bh		// by default, decrease the height to find
	or al,al	// this is the correct modification for NE
	jz .tunnloop
	cmp al,3	// and NW
	jz .tunnloop
	add bh,2	// in the other two cases, we should've increased it, so add 2

.tunnloop:
// now bh is the landscape4 byte to find
	add si,[directions+eax*2]	// step in the given direction
	add ecx,edi	// increase the cost for every new tile (there are underground rails there)
	cmp byte [landscape4(si)],bh 	// is it the other end?
	jne .tunnloop			// nope (wrong L4)
	cmp byte [landscape5(si)],dh
	jne .tunnloop			// nope (wrong L5)

	test bl,1
	jz .noconverttun2
	mov [landscape3+esi*2],dl	// convert the other end of the tunnel
	call redrawtile
.noconverttun2:
	mov ebx,ecx	// put the final cost in ebx
	call checkvehintheway	// refuse conversion if there's a train on the end piece
				// Problem: the conversion will still take place if there's a train in the tunnel
				// but didn't stick out at all
	je .noveh
	mov ebx,0x80000000	// report error before exiting

.noveh:
	pop ecx
	pop eax
	add esp,4
	ret	// exit handler
	
.notdefault:
	call isrealhumanplayer	// don't allow AI players to convert anything
	jnz .end

	cmp dl,0xe0
	jz .gotoerror	// it's a middle part of the bridge, and something is under it - call error handler

	movzx esi,si
	mov dl,[landscape1+esi]	// check owner
	cmp dl,[curplayer]
	jz .goodowner
	mov word [operrormsg2],0x1024	// ...area is owned by another company
	mov ebx,0x80000000	// report an error
	add esp,4
	ret	// exit handler

.goodowner:
	test dh,0x80	// is it a tunnel?
	jz .tunnel

	test dh,0x42	// don't convert road bridges and middle pieces
	jnz .end

	mov dl,[landscape3+esi*2]	// get convert cost
	and dl,0x0f
	call getconvertcost
	je .gotoerror

	test dh,1	// landscape5 bit 0 is clear if the bridge is in NESW direction
	jz .nesw

	cmp bh,2	// allow only NWSE railroad for converting
	jne .end
	mov bh,1	// if it's a north end, we should go to SE
	jmp short .startconversion

.nesw:
	cmp bh,1	// allow only NESW railroad for converting
	jne .end
	mov bh,2	// if it's a north ending, we should go to SW

.startconversion:
	test bl,1
	jz .noconv1
	and byte [landscape3+esi*2],0xf0	// convert the end tile the player clicked on
	or [landscape3+esi*2],dl
	call redrawtile
.noconv1:
	push eax
	push ecx
	mov al,dh
	shr al,4

	and al,2
	xor bh,al	// if it's a south ending, change bh to the opposite direction
	movzx eax,bh	// put this direction in eax
	mov ecx,edi	// ecx will contain the final cost
	shl dl,4	// the bridge type should be put in the upper nibble for middle pieces
.loop:
	add si,[directions+eax*2]	// move to the given direction
	call checkvehintheway	// if vehicle is here, abort the process
	je .continueloop

	mov ebx,0x80000000
	jmp short .exitbridge

.continueloop:
	add ecx,edi	// add the cost for converting this piece
	mov dh,[landscape5(si)]
	test dh,0x40	// is it the other end?
	jz .ending
	test bl,1	// if checking cost only, continue the loop without actually converting anything
	jz .loop
	and byte [landscape3+esi*2],0x0f	// put new type in the upper nibble
	or [landscape3+esi*2],dl
	call redrawtile
	jmp short .loop

.ending:
	shr dl,4	// type should go into the lower nibble again
	test bl,1
	jz .noconvert
	and byte [landscape3+esi*2],0xf0	// convert the other end
	or [landscape3+esi*2],dl
	call redrawtile
.noconvert:
	mov ebx,ecx	// move final cost to ebx
.exitbridge:
	pop ecx
	pop eax
	add esp,4
	ret	// exit handler	

// Called in the error handler of the above process, if there is something under the bridge.
// Since the original code only decides what error message to show, we must exit the handler to
// indicate success.
//
// In:  si: coordinates of the tile to build on
//	bh: direction of the track to build
//	bl: bit 0 clear if checking cost only
//	dh: landscape5 byte for the given tile
//
// Out: zf set -> current operrormsg2 ("already built" by default)
//	zf clear -> "must remove xxx first"
//
// safe: if returning normally with zf clear: bh, edx, esi, edi
//	 if returning normally with zf set or exiting the handler: ebx, edx, esi, edi

global buildtrackunderbridge
buildtrackunderbridge:
	call isrealhumanplayer	// don't allow AI players to convert anything
	jnz .end

	movzx esi,si
	mov dl,[curplayer]	// owner check
	cmp dl,[landscape1+esi]
	je .goodowner
	mov word [operrormsg2],0x1024	// ...area is owned by another company
	cmp eax,eax	// set zf
.end:
	ret

.goodowner:
	test dh,1	// landscape5 bit 0 is set if the bridge is in NWSE direction
	jnz .nwse

	cmp bh,2	// allow only NWSE (perpendicular) rail
	jne .end
	jmp short .convert

.nwse:
	cmp bh,1	// allow only NESW (perpendicular) rail
	jne .end

.convert:
	mov dl,[landscape3+esi*2]
	mov dh,dl
	and dx,0xf00f	// now dh = bridge type, dl = track type
	call getconvertcost	// get convert cost
	je .end

	test bl,1
	jz .done

	or dh,dl	// dh will be the new landscape3 lower byte
	mov [landscape3+esi*2],dh
	call redrawtile

.done:
	mov ebx,edi	// put the cost in ebx
	add esp,4
	ret	// exit handler
	
// Called when trying to build on a road/railroad crossing
// Again, the original code only decides the error message to show, we should exit the handler to
// indicate success.
//
// In:  si: coordinates of the tile to build on
//	bh: direction of the track to build
//	bl: bit 0 clear if checking cost only
//	dh: landscape5 byte for the given tile
//
// Out: zf set -> current operrormsg2 ("already built" by default)
// 	zf clear -> "must remove xxx first"
//
// safe: if returning normally with zf clear: bh, edx, esi, edi
//	 if returning normally with zf set or exiting the handler: ebx, edx, esi, edi

global buildtrackoncrossing
buildtrackoncrossing:
	call isrealhumanplayer	// don't allow AI players to convert anything
	jnz .end

	movzx esi,si
	mov dl,[landscape1+esi]	// owner check of the rail part
	cmp dl,[curplayer]
	je .checkdirection
	mov word [operrormsg2],0x1024	// ...area is owned by another company
	cmp eax,eax	// set zf
	ret

.checkdirection:
	test dh,8	// landscape5 bit 3 is set - the road is in NWSE
	jne .nwse

	cmp bh,2	// allow only NWSE (perpendicular) rail
	jne .end
	jmp short .checktype

.nwse:
	cmp bh,1	// allow only NESW (perpendicular) rail
	jne .end

.checktype:
	mov dl,[landscape3+esi*2+1]	// get convert cost
	call getconvertcost
	je .end

	test bl,1
	jz .done

	and byte [landscape2+esi],0	// remove the grass/sidewalks from the tile
	mov [landscape3+esi*2+1],dl	// change track type
	call redrawtile

.done:
	mov ebx,edi	// put final cost in ebx
	add esp,4	// drop our return address from the stack
.end:
	ret

// Called when checking if the type of the new rail is the same as the type already there.
// Owner checking had been already done by the time we get here.
// We should convert manually if the requested track is already on the tile but is the wrong type,
// to avoid "Already built" error. If the requested track isn't there, we should allow the handler
// to continue, tough, to check if land is sloped in the right direction and the track won't cross
// signals.
//
// In:  si: coordinates of the tile to build on
//	bh: direction of the track to build
//	bl: bit 0 clear if checking cost only
//	dh: landscape5 byte for the given tile
//
// out: zf set: continue building
//	zf clear: "Must remove xxx first"
//
// safe: if returning normally with zf set: dl, esi
//	 if returning normally with zf clear: bh, edx, esi, edi
//	 if exiting the handler: ebx, edx, esi, edi

global checktracktype
checktracktype:
	pusha
	movzx esi,si
	mov dl,[landscape3+esi*2]	// get convert cost
	and dl,0x0f
	call getconvertcost
	jne .needsconversion
.end:
	popa	// same type - allow normal operation
	ret

.needsconversion:
	call isrealhumanplayer	// don't allow AI players to convert anything
	jnz .end

	mov cl,dh
	and cl,0xc0	// is it a depot?
	cmp cl,0xc0
	jnz .notdepot

	mov [trackcostadjust],edi	// we'll do depots manually, so save the cost before proceeding
	test dh,1	// odd depot directions (1 and 3) mean NWSE orientation
	jnz .nwse

	cmp bh,1	// allow only NESW rail to convert
	jne .notallow
	jmp short .doitourselves

.nwse:
	cmp bh,2	// allow only NWSE rail to convert
	jne .notallow
	jmp short .doitourselves

.notallow:
	popa
	or esi,esi	// clear zf
	ret

.notdepot:
	xor eax,eax
	mov cl,0x20	// test every bit of dh from bit 5 down
.costloop:
	test dh,cl
	jz .noadd
	add eax,edi	// increase cost if this track part is present
.noadd:
	shr cl,1
	jnz .costloop

	mov [trackcostadjust],eax	// so much is the converting cost

	test dh,bh
	jnz .doitourselves	// The track the player wanted to put is already there, so (s)he wanted
				// converting only. There is no additional cost, convert the track manually.

	popa	// The player wants to put a new track to the tile after converting the ones already there.
		// Allow the handler to continue, it will change the track type to the right one.
	ret

.doitourselves:
	test bl,1
	jz .conversiondone

	mov ah,[landscape3+esi*2]	// change the track type
	and ah,0xf0
	or ah,dl
	mov [landscape3+esi*2],ah
	and byte [landscape2+esi],0xf0	// remove grass and fences from the tile
	call redrawtile

.conversiondone:
	popa
	add esp,4	// we are to exit the handler
	mov ebx,[trackcostadjust]	// but first load the stored cost
	ret

// Called before TTD decides whether a train would be too long with a new waggon added
// We check for compatibility of track types here
// Exit with a special jump to show our error message
// in:	[tempvar   ]-> vehicle to be moved
//	[tempvar+ 4]-> the above vehicle should be moved after this one 
//		      (if it's zero, the vehicle should be detached from the current consist)
//	[tempvar+ 8]-> first vehicle of source consist
//	[tempvar+12]-> first vehicle of destination consist or 0 if none
// 	al=train length
// out:	cmp al,maxlen: CF=1 or ZF=1 to disallow (train too long)
// safe:eax(8:31) esi edi
uvarb ForceAttachmentOfUnit // for clonetrain to stop grf authors breaking it
global traintoolong
traintoolong:
	push eax
	mov esi,[tempvar]			// vehicle to be moved
	mov edi,[tempvar+12]			// destination engine
	or edi,edi
	jz .good				// detaching is always possible

	cmp byte [ForceAttachmentOfUnit], 1	// Allows the bypassing of checking the grf's attachment
	je .good				// restrictions and the other checks

	push word [esi+veh.engineidx]
	mov ax,[edi+veh.engineidx]
	mov [esi+veh.engineidx],ax		// make var.action type 82 use the destination consist
	mov ah,0x1D				// whereas type 81 still uses the vehicle to be moved
	mov al,[edi+veh.vehtype]
	call vehtypecallback
	pop word [esi+veh.engineidx]
	jc .standard

	cmp al,0xfd
	jb .grferror
	je .bad

	cmp al,0xfe
	je .good

	// else standard

.standard:
	mov al,[edi+veh.tracktype]		// bl=source rail type
	mov ah,[esi+veh.tracktype]		// bh=destination rail type

	testflags electrifiedrail
	jnc .noelec

	shr al,1				// map 0,1->0, 2->1 so that
	shr ah,1				// electric and diesel are compatible

.noelec:
	testflags unifiedmaglev
	jnc .comptypes

	add ax,0x0101
	and ax,0x0202				// map 0->0, 1,2->2

.comptypes:
	cmp al,ah				// in other cases, only identical types are compatible
	jne .bad
.good:
	mov word [operrormsg2],0x8819		// overwritten ("Train too long")
	cmp al,al
	pop eax
	ret

.bad:
	mov word [operrormsg2],ourtext(wrongrailtype)
	or al,0xff
	pop eax
	ret

.grferror:
	mov ah,0
	call setmiscgrferror
	or al,0xff
	pop eax
	ret

// sets operrormsg2 to show miscgrftext error message in ax
global setmiscgrferror
setmiscgrferror:
	pusha
	mov esi,[mostrecentspriteblock]
	mov [curmiscgrf],esi
	or ah,0xd4
	call texthandler
	mov [specialerrtext1],esi
	mov word [operrormsg2],statictext(specialerr1)
	popa
	ret
