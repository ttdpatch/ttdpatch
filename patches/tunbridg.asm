// Todolist

// fix foundation system
// add caternery -> connection between tiles are broken
// !!! fix PBS (for Josef)
// !! make switch depend on manual convert and on buildonslopes

#include <std.inc>
#include <ptrvar.inc>
#include <flags.inc>
#include <bitvars.inc>
#include <veh.inc>

extern istrackrighttype,istrackrighttype.tracktypeset
extern addsprite, redrawtile, gettileinfo
extern isrealhumanplayer
extern patchflags
extern expswitches

extern Class9LandPointer //added by steven hoefel for trams

extern dontdisplaywireattunnel
extern drawpylons, displaywires, geteffectivetracktype
extern wantedtracktypeofs
extern checkvehintheway

extern addlinkedsprite
extern addgroundsprite
extern addrelsprite
extern gettunnelspriteset

extern locationtoxy
extern cleartilefn

extern trackhascatenary_L7

uvard traceroutefnptr
uvard traceroutefnjmp

// in:	ebx=di=landscape XY
//	esi->vehicle
//	ebp=vehicle direction
// out:
exported enhancetunneltestrailwaytype
	mov al, [landscape5(di)]	
	or al, al
	jns .tunnel
	test al, 0x40	
	ret

.withbridge:
	and eax, 3
	add al, al
	inc al
	cmp eax, ebp	//same direction as tunnel entrance
	je .withoutbridge
/*
	test al, 1
	jz .otherdir
	cmp ebp, 1 // vehicle direction
	je .onbridge
	cmp ebp, 5
	je .onbridge
	jmp .withoutbridge
.otherdir:
	cmp ebp, 3
	je .onbridge
	cmp ebp, 7
	je .onbridge
	jmp .withoutbridge
*/

.onbridge:
	jne .ok		// only check track type for engine
	mov al, [landscape7+ebx]
	and al, 0x0F
	call istrackrighttype.tracktypeset
	jmp short .testvehicle

.tunnel:
	push eax
	mov ax,[esi+veh.idx]
	cmp ax,[esi+veh.engineidx]
	pop eax
	jne .ok		// only check track type and owner for engine

.ownertest:
	test byte [expswitches],EXP_COOPERATIVE
	jnz .noownertest
	cmp ah, [landscape1+ebx]
	jnz .wrong
.noownertest:
	test byte [landscape7+ebx], 0x80
	jnz .withbridge
.withoutbridge:
	call istrackrighttype	// reads landscape3
.testvehicle:
	cmp al, byte [esi+veh.tracktype]
	jz .ok
.wrong:
	add esp, 4
	pop ebx
	pop eax
	stc
	ret
.ok:
	add esp, 4
	pop ebx
	pop eax
	clc // ok to use
	ret



vard dTunnelSpriteBasesNew
	dd 2365, 2389
endvar 
uvard enhdrawbasetrack

// in EBX = XY index of the tile
//     SI = class of the tile * 8
//     DH = L5
//     DL = altitude of the lowest corne
//     DI = map of corners

exported Class9DrawLandTunnelExt
	mov dword [Class9LandPointer], ebx //add by steven hoefel for tram tunnels
	mov byte [dontdisplaywireattunnel], 0
	test byte [landscape7+ebx], 0x80
	jnz .withbridge
	mov bx,[landscape3+ebx*2]
	ret

.withbridge:
	pusha
	mov byte [dontdisplaywireattunnel], 1
	mov esi, ebx


	mov bx,[landscape3+ebx*2]
	
	push esi
	mov si, bx

	testflags electrifiedrail
	jnc .notelectrifiedtunnel
	call gettunnelspriteset	// will set
	jmp short .electrifiedtunnel
.notelectrifiedtunnel:

	and ebx, byte 0x0F
	imul bx, byte 8
.electrifiedtunnel:

	or si, si
	jns .nosnow
	add bx, 32
.nosnow:
	movzx esi, dh
	and esi, 0x0C
	add ebx, [dTunnelSpriteBasesNew+esi]
   	movzx esi, dh
	and si, 3
	shl si, 1
	add ebx, esi
	push ebx
   	call [addgroundsprite]
	pop ebx
	pop esi

	inc ebx
	
// helper sprite
	pusha
	add dl, 7
	mov di, 16
	mov si, di
	mov dh, 1
	mov ebx, 0x1322
	call [addsprite]
	test dh,dh
	popa
	jnz near .norelsprite

// top sprite
	pusha
	mov ax, 31
	mov cx, 37
	call [addrelsprite]
	popa

// route top sprite
	pusha
	xor eax, eax
	mov al,[landscape7+esi]
	and al, 0x0F

	testflags electrifiedrail
	jnc .notelectrifiedtop

	call geteffectivetracktype
.notelectrifiedtop:

	xchg eax,ebx
	
	cmp bl, 2	//Maglev
	jne .nomaglev1
	mov ebx, 2589
	mov cx, 2
	push DWORD 1
	mov al, 1
	test dh, 1
	jnz .othermaglevdir
	mov al, 2
	inc ebx
.othermaglevdir:
	jmp .drawtrackdoit

.nomaglev1:
	push DWORD 3
	imul bx, 82
	add ebx, 1005
	mov [enhdrawbasetrack], ebx
.loop1:
	mov ecx, [esp]
	movzx eax, BYTE [landscape7+esi]
	xor al, 0x10
	shr al, 3
	bt eax, ecx
	jnc .loopend
	movzx eax, dh
	and al, 3
	movzx ebx, BYTE [enhtnlconvtbl+16+ecx-1+eax*4]
	movzx ecx, BYTE [enhtnlconvtbl+ecx-1+eax*4]
	//for some reason sprites for directions 4 and 5 seem to be in wrong order
	mov eax, ebx
	shr eax, 2
	and al, 1
	xor ebx, eax

	add ebx, [enhdrawbasetrack]
	mov eax, ecx
	mov ecx, -1

.drawtrackdoit:
	testflags pathbasedsignalling
	jnc .nopathsig
	test byte [pbssettings],PBS_SHOWRESERVEDPATH|PBS_SHOWNONJUNCTIONPATH
	jz .nopathsig	// neither setting active
	jpo .nopathsig	// not both settings active
	test [landscape6+esi],al
	jz .nopathsig
	or ebx,0x3248000
.nopathsig:
	mov ax, 31
	pusha
	call [addrelsprite]
	popa

.loopend:
	dec DWORD [esp]
	jnz .loop1

	add esp, 4
	popa

// caternary top
	testflags electrifiedrail
	jnc near .notelectrified

	call trackhascatenary_L7
	jz .notelectrified
	pusha
	add dl, 8
// 	test dh, 1
// 	mov dh, 1
// 	jnz .otherdirpylons
// 	mov dh, 2
// .otherdirpylons:
	movzx ebx, dh
	movzx di, BYTE [landscape7+esi]
	and bl, 3
	xor dh, dh
	test di, 0x10
	jnz .nostraightcat
	or dh, [enhtnlconvtbl+ebx*4]
.nostraightcat:
	test di, 0x20
	jz .nodiag1cat
	or dh, [enhtnlconvtbl+ebx*4+1]
.nodiag1cat:
	test di, 0x40
	jz .nodiag2cat
	or dh, [enhtnlconvtbl+ebx*4+2]
.nodiag2cat:
	mov di, 0
	call drawpylons
	call displaywires
	popa
.notelectrified:

.norelsprite:
	popa
	add esp, 4
	ret


// ax,cx = tunnelend
// di = tunnelend
exported enhancetunnelremovetunnel
	jnz .vehicle
	pusha
	call locationtoxy
	// esi
	call checkvehintheway
	popa
	jnz .vehicle
	pusha
	mov esi, edi
	call checkvehintheway
	popa
	jnz .vehicle
	ret
.vehicle:
	mov ebx, 0x80000000
	add esp, 4
	ret

varb enhtnlconvtbl
db 2,32,4,1
db 1,8,32,2
db 2,8,16,1
db 1,4,16,2

db 1,5,2,0
db 0,3,5,0
db 1,3,4,0
db 0,2,4,0
endvar

// in esi = coordinate
// 	dh = L5
//	bl = buildflags
//	bh = direction of the track to build
exported enhancetunnelremovetrack
	mov BYTE [trnum], 0
	test byte [landscape7+esi], 0x80
	jz .notbridge
	test dh, 1	// odd numbers (1 and 3) mean NESW orientation
	jz .neswtun
	cmp bh, 1
	je .remove
.in1:
	push eax
	call calctrnum
	or al, al
	jns .diagremfine
	pop eax
	ret
.diagremfine:
	mov [trnum], al
	pop eax
	jmp .remove
.neswtun:
	cmp bh, 2
	je .remove
	jmp .in1
.notbridge:
	cmp dl, 0xE0
	jnz .wrong
	ret
.wrongpop:
	pop eax
.wrong:
	mov ebx,0x80000000
	add esp, 4
	ret
.remove:
	call checkvehintheway
	jnz .wrong
	push eax
	mov bh, [landscape7+esi]
	xor bh, 0x10

	movzx eax, BYTE [trnum]
	add eax, 12
	btr ebx, eax
	jnc .wrongpop	//bit not previously set, track not present

	test bh, 0x70
	jnz .notblank
	mov bh, 0x10
.notblank:
	xor bh, 0x10
	test bl,1
	jz .onlytesting
	mov byte [landscape7+esi], bh
	mov eax, [esp]
	call redrawtile
.onlytesting:
	pop eax
	movsx ebx, word [tracksale]
	add esp, 4
	ret

uvarb trnum

//bh = direction of the track to build
//dh = L5
//trashes: eax
calctrnum:
	//tunnel pointing in towards: 0 = NE, 1 = SE, 2 = SW, 3 = NW
	//valid dirs: bits (bh) = 0-2,5 1-3,5 2-3,4 3-2,4
	//translated to:	  0-2,1 1-1,2 2-1,2 3-1,2
	movzx eax, bh
	bsf eax, eax
	cmp eax, 1
	jle .bad
	test dh, 3
	jz .case0
	jp .case3
	test dh, 1
	jnz .case1
.case2:
	test bh, 0x24
	jnz .bad
	sub al, 2
	ret
.case0:
	test bh, 0x18
	jnz .bad
	and al, 3
	ret
.case3:
	test bh, 0x28
	jnz .bad
	shr al, 1
	ret
.case1:
	test bh, 0x14
	jnz .bad
	dec al
	shr al, 1
	ret
.bad:
	or al, -1
	ret

// in si = coordinate
// 	dl = old type!
// 	dh = landscape5
//	bl = buildflags
//	bh = direction of the track to build

exported enhancetunneladdtrack
	test bh, 3
	jnz .nodiag
	push eax
	call calctrnum
	or al, al
	js .badpop
	jmp .convpop
.nodiag:
	mov BYTE [trnum], 0
	test dh,1	// odd numbers (1 and 3) mean NESW orientation
	jz .neswtun
	cmp bh, 1
	je .convert
.ret1:
	ret
.badpop:
	pop eax
	ret
.neswtun:
	cmp bh, 2
	je .convert
.done:
.alreadybuild:
	ret
.wrongowner:
	pop eax
	mov word [operrormsg2],0x1024	// ...area is owned by another company
	mov ebx,0x80000000		// report an error
	add esp,4
	ret
.convpop:
	mov [trnum], al
	pop eax
.convert:
	movzx esi,si
//	test byte [landscape7+esi], 0x80
//	jnz .alreadybuild
	call isrealhumanplayer	// don't allow AI players to convert anything
	jnz .done

	push eax
	mov ah, byte [landscape1+esi]	// check owner
	cmp ah, byte [curplayer]
	jnz .wrongowner
	
	push ecx
	call checkvehintheway
	je .noveh
.error:
	mov ebx,0x80000000
	pop ecx
	pop eax
	add esp,4
	ret

.noveh:

	push ebx
	mov ebx,[wantedtracktypeofs]
	mov ah, byte [ebx]	// ah contains what type the user wants
	pop ebx
	testflags manualconvert
	mov al, byte [landscape7+esi]
	jc .ok
	test al, al
	jns .ok
	mov dl, al
	and dl, 0xF
	cmp ah, dl
	jne .error
.ok:
	//mov ah, dl
	and ah, 3
	mov bh, al
	and al,0xF8
	or al, ah
	or al, 0x80

	mov ah, [trnum]
	sub ah, 1
	inc ah
	adc ah, ah	//0,1,2-->1,2,4
	shl ah, 4

	cmp bh, al
	jne .notthesame
	or bh, bh
	jns .notthesame

	xor al, 0x10

	test al, ah	//track part already exists
	jz .notthesame2

	mov word [operrormsg2],0x1007		// already build
	mov ebx,0x80000000
	pop ecx
	pop eax
	add esp,4
	ret
.notthesame:
	xor al, 0x10
.notthesame2:
	or bh, bh
	js .alreadytrack
	and al, 0x8F
	//or al, 0x10
.alreadytrack:
	or al, ah
	xor al, 0x10
	test bl,1
	jz .onlytesting
	mov byte [landscape7+esi], al
	call redrawtile
.onlytesting:
	movsx ebx, word [trackcost]
	pop ecx
	pop eax
	add esp,4
	ret

uvarb tnlrtmppbsflag
uvarb Class9RouteMapHandlerTunnel_intc_dir

exported Class9RouteMapHandlerTunnel
	and ah, 0x0C
	shr ah, 1
	cmp al, ah
	jz .typeok
	xor eax, eax
	ret
.typeok:
	cmp al, 0
	jnz .nootherroute
	mov al, [landscape7+edi]
//	test al, 0x80	//enable enhanced tunnel checking for non-enhanced tunnel entrances to alleviate routefinding/signal propagation/train movement bugs, from track above a normal tunnel entrance to that below it.
	jmp .newroute	//was jnz
.nootherroute:
	mov eax, 0x101
	test byte [landscape5(di)], 1
	jz .done
	mov ax, 0x202
.done:
	shr BYTE [tunnelgetclass9routemapflags], 1
.exit:
	ret
.newroute:
	push ecx
	movzx ecx, BYTE [landscape5(di)]
	and cl, 3
	or al, al
	js .enhanced1
	//ordinary tunnel
	or al, 0x10
	and al, ~0x60
.enhanced1:

	mov ah, [enhtnlconvtbl+ecx*4+3]

	clc
	rcr BYTE [tunnelgetclass9routemapflags], 1
	jc NEAR .nodiag2rt
	cmp BYTE [tnlrtmppbsflag], 1
	je .testok			//pbs trace route

	//this function should only be called by (within TTD): dotraceroute and derivatives (bx=direction)
	//AI functions should never get this far as they don't build enhanced tunnels
	//movetrain->isnexttileconnected (bx=coordinates, always >8), train movement (bx=direction)


/*
	//exception: test for call by IsNextTileConnected and if so use direction from [esp+8+4] (was ebp)
	cmp DWORD [esp+8+4], 8
	jae .notintc
	push eax
	mov eax, [esp+4+8]
	cmp DWORD [eax], 0xD08B665D
	jne .popintc
	cmp DWORD [eax+4], 0x6610E8C1
	jne .popintc
	mov ch, [esp+8+8]
	pop eax
	jmp .gotdirin1
.popintc:
	pop eax
.notintc:
*/
	//IsNextTileConnected has now been properly hooked, no need for perambulating upstack checks
	mov ch, [Class9RouteMapHandlerTunnel_intc_dir]
	btr ecx, 15
	jc .gotdirin1

	cmp bx, 8
	jae .nodir
	//assume bx = direction (1=NE, 3=SE, 5=SW, 7=NW)
	//assume that all directions except for that heading directly into tunnel are at above level

	push eax
	//check that call really is from traceroute or derivatives

	mov eax, [esp+4+8]
	sub eax, [traceroutefnptr]
	sub eax, 0x350
	pop eax
	ja .nodir
.testok:
	mov ch, bl
.gotdirin1:
	mov bh, cl
	and bh, 3
	dec ch
	shr ch, 1
	cmp ch, bh
	mov ch, 0
	mov bh, 0
	je .nodiag2rt

	xor ah, ah
.nodir:
	test al, 0x10
	jnz .nostraightrt
	or ah, [enhtnlconvtbl+ecx*4]
.nostraightrt:
	test al, 0x20
	jz .nodiag1rt
	or ah, [enhtnlconvtbl+ecx*4+1]
.nodiag1rt:
	test al, 0x40
	jz .nodiag2rt
	or ah, [enhtnlconvtbl+ecx*4+2]
.nodiag2rt:

	mov al, ah
	pop ecx
	ret

//called from _CS:00154D0F
exported Class9VehEnterLeaveTunnelJump
/*	cmp dl, 2
	ja .test
	ret
.test:
	mov dh, cl
 	mov dl, al
	and dx, 0F0Fh
	cmp dl, 0x0
	je .edge
	cmp dl, 0x0F
	je .edge
	cmp dh, 0x0
	je .edge
	cmp dh, 0x0F
	je .edge
	ret
.edge:
	or ebx, 0x80000000
	add esp, 4*/
	ret

exported Class9GroundAltCorrectionTunnel
	shr dh, 1
	mov dh, cl
	mov bl, al
 	jnb .testcl
	mov dh, al
	mov bl, cl	
.testcl:
	and dh, 0x0F
	cmp dh, 5
	jb .edge
	cmp dh, 10
	jbe short .testslopedirection
.edge:
	push edi
	push esi
	push ecx
	push eax
 	and ax, 0FF0h
	and cx, 0FF0h
	call [gettileinfo]
	pop eax
	pop ecx
	pop esi
	pop edi
	and dl, 0xF8
	add dl, 8
	xor dh, dh
	ret

.testslopedirection:
	cmp di, 0110b
	jz .needschange
	cmp di, 1100b
	jz .needschange
	and dl, 0xF8
	mov dh, 1
	ret
.needschange:
	dec dl
	and dl, 0xF8
	mov dh, 1
	ret

uvarb tunnelgetclass9routemapflags
uvard tunnelgetotherendretaddr
varw tunneloffsets
dw -1, 0x100, 1, -0x100
endvar
uvarb gettunnelotherendprocnocheckflag

exported gettunnelotherendproc
	clc
	rcr BYTE [gettunnelotherendprocnocheckflag], 1
	jnc .doit
	rol di, 4
	mov ax, di
	ret
.doit:
	or si, si
	jnz NEAR .notgood		//absolutely no road tunnels
	movzx edi, di
	test BYTE [landscape5(di)], 12
	jnz NEAR .notgood		//absolutely no road tunnels


//	mov eax, [esp+8]
/*	mov ecx, eax
	sub ecx, [traceroutefnptr]
	cmp ecx, 0x350
	ja .notgood		//not from trace route (probably town expansion), abort if ever get this far
*/
	mov eax, [traceroutefnptr]
	mov eax, [eax+12]	//bTraceRouteSpecialRouteMap
	cmp BYTE [eax], 0x43
	jne .notsignal

	mov eax, [esp+8]
	//signal change propagation trace route through a tunnel
	mov [tunnelgetotherendretaddr], eax
	rol di, 4
	mov ax, di
	mov BYTE [tunnelgetclass9routemapflags], 0
	mov DWORD [esp+8], gettunnelotherendproc.fixdir
//	testflags advzfunctions
//	jc .changestack
	mov WORD [esp+14], 0	//stop reverse check on tunnel entrance (triggers over the top track detection), and would normally find nothing new anyway.
ret
//.changestack:
//	mov WORD [esp+14+4], 0	//see above
//ret

.fixdir:
	push edx
	inc ax
	and ebx, 0xFFFF
	mov ecx, [tunnelgetotherendretaddr]
	mov edx, [ecx+3]	//sTraceRouteState.distance
	add [edx], ax
	add ecx, 0x14		//skip route map tunnel through addition
	mov edx, [ecx-6]	//rel to AddToLocalRouteMap
	lea eax, [edx+ecx-2]
	pop edx
	push ecx
	push ebx
	mov cx, 4000h
	call eax		//AddToLocalRouteMap
	pop ebx
	add di, [tunneloffsets+ebx-1]
	xor ecx, ecx		//in case other code doesn't bother to set higher bits to zero where needed...
	ret

.notsignal:
	mov BYTE [tunnelgetclass9routemapflags], 1
.notgood:
	rol di, 4
	mov ax, di
	ret


global fixtunnelentry.enterz

exported fixtunnelentry
	mov eax, [esp+8]
.enterz:
	sub eax, [traceroutefnptr]
	cmp eax, 0x350
	ja .fret	//never let this through
	cmp eax, 0xE2
	jb .tret	//first step
	//cl = old direction, as step rather than first step function called

	//if direction is *not* 0,1,8 or 9, gratuitously deny any attempts to pass *through* the tunnel itself
	mov al, cl
	and al, ~9
	jz .fret	// is 0,1,8 or 9
.tret:
	xor eax, eax	//not a tunnel, treat as normal tile
	ret
.fret:
	mov al, [landscape4(di)]
	and al, 0xF0
	ret

exported tunnelsteamcheck
	test byte [landscape5(bx)], 80h
	jnz .notatunnel

	mov al, [landscape5(bx)]
	and al, 1
	shl al, 1
	add al, 1

	mov ah, [esi+veh.direction]
	and ah, 3

	cmp al, ah
.notatunnel:
	ret

var enhancetunnelshelpersprite
	incbin "embedded/t_helper.dat"
