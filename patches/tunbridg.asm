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
	
	imul bx, 82
	add ebx, 1005
	mov al, 1
	test dh, 1
	jnz .otherdir
	mov al, 2
	inc ebx
.otherdir:

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
	mov cx, -1
	call [addrelsprite]
	popa

// caternary top
	testflags electrifiedrail
	jnc near .notelectrified

	test byte [landscape7+esi], 1
	jz .notelectrified
	pusha
	add dl, 8
	mov di, 0
	test dh, 1
	mov dh, 1
	jnz .otherdirpylons
	mov dh, 2
.otherdirpylons:
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

// in esi = coordinate
// 	dh = L5
//	bl = buildflags
//	bh = direction of the track to build
exported enhancetunnelremovetrack
	test byte [landscape7+esi], 0x80
	jz .bridge
	test dh, 1	// odd numbers (1 and 3) mean NESW orientation
	jz .neswtun
	cmp bh, 1
	je .remove
	ret
.neswtun:
	cmp bh, 2
	je .remove
.bridge:	
	cmp dl, 0xE0
	jnz .wrong
	ret
.wrong:
	mov ebx,0x80000000
	add esp, 4
	ret
.remove:
	call checkvehintheway
	jnz .wrong

	test bl,1
	jz .onlytesting
	mov byte [landscape7+esi], 0
	call redrawtile
.onlytesting:
	movsx ebx, word [tracksale]
	add esp, 4
	ret

// in si = coordinate
// 	dl = old type!
// 	dh = landscape5
//	bl = buildflags
//	bh = direction of the track to build

exported enhancetunneladdtrack
	test dh,1	// odd numbers (1 and 3) mean NESW orientation
	jz .neswtun
	cmp bh, 1
	je .convert
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
	mov ebx,0x80000000
	pop ecx
	pop eax
	add esp,4
	ret

.noveh:

	push ebx
	mov ebx,[wantedtracktypeofs]
	mov ah, byte [ebx]	// bh contains what type the user wants
	pop ebx
	//mov ah, dl
	and ah, 3
	mov al, byte [landscape7+esi]
	and al,0xF8
	or al, ah
	or al, 0x80
	
	cmp byte [landscape7+esi], al
	jne .notthesame

	mov word [operrormsg2],0x1007		// already build
	mov ebx,0x80000000
	pop ecx
	pop eax
	add esp,4
	ret
.notthesame:
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


exported Class9RouteMapHandlerTunnel
	and ah, 0x0C
	shr ah, 1
	cmp al, ah
	jz .typeok
	xor eax, eax
.typeok:
	cmp al, 0
	jnz .nootherroute
	test byte [landscape7+edi], 0x80
	jnz .newroute
.nootherroute:
	mov eax, 0x101
	test byte [landscape5(di)], 1
	jz .done
	mov ax, 0x202
.done:
	ret
.newroute:
	mov eax, 0x303
	ret

exported Class9VehEnterLeaveTunnelJump
	cmp dl, 2
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
	add esp, 4
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

var enhancetunnelshelpersprite
	incbin "embedded/t_helper.dat"
