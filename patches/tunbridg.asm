// Todolist

// ! make enhancetunnels depend on landscape 7
// fix foundation system
// add caternery -> connection between tiles are broken
// !!! fix PBS (for Josef)
// add type of route check for on the bridge -> done
// see manual convert, add switch test -> done 
// !! make switch depend on manual convert and on buildonslopes
// alter overbuild code to allow track -> done

#include <std.inc>
#include <ptrvar.inc>
#include <flags.inc>
#include <bitvars.inc>
#include <exported.inc>

extern istrackrighttype,istrackrighttype.tracktypeset
extern addsprite, redrawtile, gettileinfo
extern isrealhumanplayer
extern patchflags
extern expswitches

extern dontdisplaywireattunnel
extern drawpylons, displaywires, geteffectivetracktype
extern wantedtracktypeofs
extern checkvehintheway

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
	mov al, [landscape7+ebx]
	and al, 0x0F
	call istrackrighttype.tracktypeset
	jmp short .testvehicle
.tunnel:
	testmultiflags experimentalfeatures
	jz .ownertest
	test byte [expswitches],EXP_COOPERATIVE
	jz .noownertest
.ownertest:
	cmp ah, [landscape1+ebx]
.noownertest:
	jnz .wrong
	test byte [landscape7+ebx], 0x80
	jnz near .withbridge
.withoutbridge:
	call istrackrighttype	// reads landscape3
.testvehicle:
	cmp al, byte [esi+0x66]
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


uvard Class9DrawLandTunneledx, 1
exported Class9DrawLandTunnelExt
	mov byte [dontdisplaywireattunnel], 0
	test byte [landscape7+ebx], 0x80
	jnz .withbridge
	mov bx,[landscape3+ebx*2]
	ret

.withbridge:
	mov byte [dontdisplaywireattunnel], 1
	pusha	
	mov esi, ebx

	testflags electrifiedrail
	jnc near .notelectrified

	test byte [landscape7+ebx], 1
	jz .notelectrified

	pusha
	add dl, 8
	mov di, 0
	test dh, 1
	mov dh, 1
	jnz .otherdirpylons
	mov dh, 2
.otherdirpylons:
	mov esi, ebx
	call drawpylons
	call displaywires
	popa
.notelectrified:

	xchg eax,ebx
	mov al,[landscape7+eax]
	and al, 0x0F
	call geteffectivetracktype
	xchg eax,ebx
	
	imul bx, 82
	add ebx, 1005
	test dh, 1
	jnz .otherdir
	inc ebx
.otherdir:
	add dl, 8
	mov di, 16
	mov si, di
	mov dh, 1
	call [addsprite]
	popa

//	test si,1
//	jz .nofuturepylon
//	mov dword [badpylondirs],(1<<3)+(1<<31)
//.nofuturepylon:
	mov bx,[landscape3+ebx*2]
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
	test bl,1
	jz .onlytesting
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
