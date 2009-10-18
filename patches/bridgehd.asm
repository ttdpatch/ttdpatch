
#include <std.inc>
#include <flags.inc>
#include <human.inc>
#include <ptrvar.inc>
#include <newvehdata.inc>
#include <veh.inc>

extern alwaysraiseland,buildtrackonbridgeortunnel.notdefault
extern displbasewithfoundation,gettileinfo,invalidatetile,ishumanplayer
extern isrealhumanplayer
extern patchflags

extern editTramMode, tramVehPtr, newvehdata, invalidateBridgeIfExists




uvard oldclass9routemaphandler,1,s
uvard oldclass9drawland2,1,s

var roadroutemap
	db 0, 0, 0, 10h, 0, 2, 8, 1Ah
	db 0, 4, 1, 15h, 20h, 26h, 29h, 3Fh
global class9routemaphandler
class9routemaphandler:
	push eax
	mov al, [landscape5(di)]
	and al, 0xC0
	cmp al, 0x80
	pop eax
	jne .origfunc
	test word [landscape3 +2*edi], 3 << 13
	jz .origfunc
	test byte [landscape5(di,1)], 6
	jz .railbridge
	jmp short .roadbridge

.origfunc:
	jmp [oldclass9routemaphandler]

.railbridge:
	cmp al, 0	// only new code for rails
	jne .origfunc
	movzx eax,word [landscape3 +2*edi]
	shr eax, 4
	and al, 3Fh

	mov ah, al

	// handle X crossings correctly for signal tracing code
	cmp al,3
	jne .notXcross
	or al,0x40
.notXcross:
	ret

.roadbridge:
	cmp ax, 2	// only roads
	jne .origfunc
	movzx eax, word [landscape3 +2*edi]
	shr ax, 4
				//Hacked in by steven
	testmultiflags trams
	jz	.dontshift4again
	cmp	dword [tramVehPtr], 0FFFFFFFFh
	je	.dontshift4again
	push	esi
	push	edx
	mov	esi, [tramVehPtr]
	movzx	edx, byte [esi+veh.vehtype]
	test	byte [vehmiscflags+edx], VEHMISCFLAG_RVISTRAM
	pop	edx
	pop	esi
	jz	.dontshift4again
	shr eax, 4
	and eax, 0Fh
	cmp eax, 0		//sometimes it thinks it's a custom bridge head but it's not, so just move road back in.
	jne .dontshift4again
	movzx eax, word [landscape3 +2*edi]
	shr ax, 4
.dontshift4again:
				//-----------------

	and ax, 0Fh
	mov al, [roadroutemap+eax]
	mov ah, al
	ret

global newclass9drawland
newclass9drawland:
	push eax
	mov al, [landscape5(bx)]
	and al, 0xC0
	cmp al, 0x80
	pop eax
	jne .old
	test word [landscape3 +2*ebx], 3 << 13
	jnz .bridgehead

.old:
	jmp [oldclass9drawland2]

.bridgehead:
	test word [landscape3 +2*ebx], 0FFh << 4  //had to change mask to encompass TRAM bits
	jz near .empty

	testmultiflags trams
	jz	.dontjumptotrams
	test byte [landscape5(bx,1)], 6
	jnz near .newtramtest
.dontjumptotrams:
	test byte [landscape5(bx,1)], 6
	jnz near .roadbridge

	movzx esi,word [landscape3+ebx*2]
	shr esi,4
	and esi,0x3f
	movzx ebp,byte [landscape5(bx,1)]
	and ebp,1
	inc ebp
	cmp ebp,esi
	je .old

	push word [landscape2 +ebx]
	push word [landscape5(bx)]
	mov byte [landscape2 +ebx], 1
	test word [landscape3+ebx*2], 8000h
	jz .nodesert
	mov byte [landscape2 +ebx], 0x0C
.nodesert:
	push eax
	mov al, dl
	mov dx,si
	mov byte [alwaysraiseland], 1
	mov dh, dl
	mov dl, al
	pop eax

	push ebx
	mov [landscape5(bx)], dh

	mov esi, ebx
	mov ebp,[ophandler+1*8]
	call dword [ebp+0x1c]                   // normal rail piece draw land

	mov byte [alwaysraiseland], 0

	pop ebx
	pop word [landscape5(bx)]
	pop word [landscape2 +ebx]
	ret

.newtramtest:
	movzx esi,word [landscape3+ebx*2]
	shr esi,8		//check for trams
	and esi,0x0f
	cmp esi,0
	je .roadbridge
	movzx esi,word [landscape3+ebx*2]
	shr esi,4
	and esi,0x0f
	cmp esi, 0
	jne .drawitnow
	movzx esi,word [landscape3+ebx*2]
	shr esi,8		//check for trams
	and esi,0x0f
	cmp esi,0
	jmp .drawitnow

.roadbridge:
	movzx esi,word [landscape3+ebx*2]
	shr esi,4
	and esi,0x0f
	movzx ebp,byte [landscape5(bx,1)]
	and ebp,1
	neg ebp
	lea ebp,[ebp*5+10]
	cmp ebp,esi
	je .old

.drawitnow:
	push word [landscape2 +ebx]
	mov byte [landscape2 +ebx], 1
	push eax
	mov al, dl
	mov dx,si
	mov byte [alwaysraiseland], 1
	mov dh, dl
	mov dl, al
	pop eax

	push ebx

	mov esi, ebx
	mov ebp, [ophandler+2*8]
	call dword [ebp+0x1c]

	mov byte [alwaysraiseland], 0

	pop ebx
	pop word [landscape2 +ebx]
	ret

.empty:
	mov ebx, 1022
	mov ebp, edi
	xor edi, edi
	add dl, 8
	call displbasewithfoundation
	ret

global removebridgetrack
removebridgetrack:
	push eax
	mov al, [landscape5(si)]
	and al, 0xC0
	cmp al, 0x80
	pop eax
	jne .notbridgeending
	test word [landscape3 +2*esi], 3 << 13
	jz .notbridgeending

	test byte [landscape5(si,1)], 6
	jnz .notbridgeending	// this isn't a railway bridge
	jmp  short .bridgeending

.notbridgeending:
	mov dl, dh
	and dl, 0F8h
	jns .tunnelquit
	testflags advzfunctions
	jc .advremovetrackbridgemiddle
.tunnelquit:
	cmp dl, 0E0h
	ret
	
.advremovetrackbridgemiddle:
	push eax
	mov dl, dh
	and dl, 1
	inc dl
	xor dl, 3
	mov al, dl
	xor dl, [landscape3+1+esi*2]

	test dl, bh
	jz .errorp	//requested track piece does not exist...

	xor dl, bh	//remove piece
	setz ah		//no pieces left
	dec ah		//ah=0 if no pieces left, -1 otherwise
	and al, ah
	xor dl, al	//flip default bit (not done if no pieces left)

	test bl, 1
	jz .dontdoitdave
	mov [landscape3+1+esi*2], dl
	or ah, ah
	jnz .dontdoitdave
			//no pieces left
	mov BYTE [landscape1+esi], 0x10
	and BYTE [landscape5(si)], ~0x38

.dontdoitdave:
	pop eax
	jmp .onlytesting

.bridgeending:
	mov dl, bl

	movzx bx, bh
	and bx, 3Fh 	// shouldn't be neccesairy
	shl bx, 4
	test [landscape3 +2*esi], bx
	jz .error
	
	test dl, 1
	jz .onlytesting

	not bx
	and [landscape3 +2*esi], bx

	call [invalidatetile]

.onlytesting:
	pop ebx
	movsx ebx, word [tracksale]
	ret

.errorp:
	pop eax
.error:
	pop ebx
	mov ebx, 0x80000000
	ret

global removebridgeroad
removebridgeroad:
	push eax
	mov al, [landscape5(si)]
	and al, 0xC0
	cmp al, 0x80
	pop eax
	jne .notbridgeending
	test word [landscape3 +2*esi], 3 << 13
	jz .notbridgeending

	test byte [landscape5(si,1)], 6
	jz .notbridgeending	// this is a railway bridge
	jmp short .bridgeending

.notbridgeending:
	mov dl, dh
	and dl, 0F9h
	cmp dl, 0E8h
	ret

.bridgeending:
	mov dl, bl
	pop ebx
	pop bx

	and bx, 0F80h
	btr ebx, 7
	jc .istram
	shr bx, 4
.istram:
	test [landscape3 +2*esi], bx
	jz .error

.continueaftertestingtramtrack:
	test dl, 1
	jz .onlytesting

	not bx

	and word [landscape3 +2*esi], bx

.continueaftertramhack:
	call [invalidatetile]

	call invalidateBridgeIfExists

.onlytesting:
	movsx ebx, word [roadremovecost]
	ret

.error:
	mov ebx, 0x80000000
	ret

global buildbridgeroad
buildbridgeroad:
	push eax
	mov al, [landscape5(si)]
	and al, 0xC0
	cmp al, 0x80
	pop eax
	jne .notbridgeending
	test byte [landscape5(si,1)], 6
	jz .notbridgeending	// rail bridge
	jmp short .bridgeending

.notbridgeending:
	mov dl, dh
	and dl, 0F9h
	cmp dl, 0E8h
	ret

.bridgeending:
	mov dl, bl
	pop ebx
	pop bx
	
	push ecx
	xor ecx,ecx
	mov cl, 8

	and bx, 0F80h
	btr ebx, 7
	jc .istram
	mov cl, 4
	shr bx, cl
.istram:
	test [landscape3 +2*esi], bx
	jnz short .error
	
	// see if this can be build with this slope
	push ebx
	push edx
	shr ebx, cl		// Shift route bits into low 4 bits -- shr 8 if trams, shr 4 if roads
	mov dl, bl
	push edi
	and edi, 0x0F
	mov dh, byte [bh_slopedirmask + edi]
	pop edi
	test byte [landscape5(si,1)], 1
	jnz .xdir
	or dh, 1010b
	jmp short .havedir
.xdir:
	or dh, 0101b
.havedir:

	mov bh, dh
	not bh		// bh contains bits not in dh
	and dl, bh
	pop edx
	pop ebx
	jnz .wrongslope
	pop ecx

	test dl, 1
	jz .onlytesting
	

	or word [landscape3 +2*esi], bx

	call [invalidatetile]

	call invalidateBridgeIfExists

.onlytesting:
	movzx ebx, word [roadbuildcost]
	ret

.wrongslope:
	mov word [operrormsg2], 1000h
	
.error:
	pop ecx
	mov ebx, 0x80000000
	ret
	
var bh_raildirmask
	db 1010b, 0101b, 1001b, 0110b, 0011b, 1100b
var bh_slopedirmask
	db 1111b, 0011b, 0110b, 1111b
	db 1100b, 1111b, 1111b, 1111b
	db 1001b, 1111b, 1111b, 1111b
	db 1111b, 1111b, 1111b, 1111b
uvard temptracktypeptr,1,s
global buildbridgetrack
buildbridgetrack:
	test byte [landscape5(si)], 0xF0
	jz .tunnel
	test byte [landscape5(si)], 80h
	jz .notbridgeending
	test byte [landscape5(si)], 40h
	jnz .notbridgeending
	push ebx
	mov bx, [landscape3 +2*esi]
	and bl, 0fh
	push edi
	mov edi, [temptracktypeptr]
	cmp bl, [edi]
	pop edi
	pop ebx
	jz .noconvertbridge
	mov dl, dh
	and dl, 0F8h
	testmultiflags manualconvert
	jz .noconvertbridge
	jmp buildtrackonbridgeortunnel.notdefault

.tunnel:
	jmp buildtrackonbridgeortunnel.notdefault

.noconvertbridge:
	test word [landscape3 +2*esi], 3 << 13
	jz .notbridgeending
	test byte [landscape5(si,1)], 6
	jnz .notbridgeending	// this isn't a railway bridge
	jmp short .bridgeending

.notbridgeending:
	mov dl, dh
	and dl, 0F8h
	call isrealhumanplayer
	jnz .nonhumanplayerperponly
	testflags advzfunctions
	jc .allownonperpundertrackbuild
.nonhumanplayerperponly:
	cmp dl, 0C0h
	ret
.allownonperpundertrackbuild:
	or dl, 20h
	//clear zf
	ret
	
.bridgeending:
	mov dl, bl
	
	movzx bx, bh
	and bx, 3Fh 	// shouldn't be neccesairy
	shl bx, 4
	test [landscape3 +2*esi], bx
	jnz .error

	// see if this can be build with this slope
	// first set dl bit 0..3 == use edge 0..3 (0 == NE)
	push ebx
	push edx
	shr bx, 4

	xor edx, edx
.loop:
	shr bx, 1
	jz .done
	inc edx
	jmp .loop
.done:
	mov dl, byte [bh_raildirmask + edx]
	// now set dh bit 0..3 == can use edge 0..3 (0 == NE)
	push edi
	and edi, 0x0F
	mov dh, byte [bh_slopedirmask + edi]
	pop edi
	test byte [landscape5(si,1)], 1
	jnz .xdir
	or dh, 1010b
	jmp short .havedir
.xdir:
	or dh, 0101b
.havedir:

	mov bh, dh
	not bh		// bh contains bits not in dh
	and dl, bh
	jnz .wrongslope
	
	pop edx
	pop ebx
	
	test dl, 1
	jz .onlytesting

	or [landscape3 +2*esi], bx

	call [invalidatetile]

.onlytesting:
	pop ebx
	movsx ebx, word [trackcost]
	ret

.wrongslope:
	pop edx
	pop ebx
	mov word [operrormsg2], 1000h
	
.error:
	pop ebx
	mov ebx, 0x80000000
	ret

var isflathead
//temporary use another array, until the create-track is fixed to not allow all tracks to be built when on an inclined foundation (so we won't connect tracks that are on different levels)
	db 0, 1, 1, 1
	db 1, 1, 1, 0
	db 1, 1, 1, 0
	db 1, 0, 0, 0

	// called when constructing the bridge head of a new bridge
	//
	// in:	ax=X
	//	cx=Y
	//	dl=L3 value
	//	esi=XY
	// out:
	// safe:bx dx di ebp
global buildbridgehead
buildbridgehead:
	xor bx,bx

	push edi
	and edi, 0fh
	cmp byte [isflathead+edi], 0	// is it a 'flat' bridgehead
	pop edi
	je .gotpieces

	// now add the default (straight) rail/road pieces

	mov bl,[landscape5(si,1)]
	test bl,6	// is it a rail bridge
	je .rail

.road:
	and bl,1
	neg bx
	lea bx,[ebx*5+10]	// higher bits of ebx will be discarded
	jmp short .custom

.rail:
	and bl,1
	inc bl

.custom:
	shl bx,4
	or bx, 1 << 14

.gotpieces:
	or bl,dl
	mov [landscape3 +2*esi], bx
	ret

global convertbridgeheads
convertbridgeheads:
	//loop over the entire map, converting all bridge heads if possible
	push esi
	push ebp

	mov ebp, [gettileinfo]
	add ebp,41

	xor esi, esi
.loop:
	mov al, [landscape4(si,1)]
	shr al, 4
	cmp al, 9
	jne near .next	// not a bridge
	test byte [landscape5(si,1)], 0xF0
	jz near .next	// a tunnel
	test byte [landscape5(si,1)], 0x40
	jnz near .next	// not bridge head
	test word [landscape3 +2*esi], 3 << 13
	jnz .next	// already converted

	call ebp
	and edi, 0fh
	cmp byte [isflathead+edi], 0	// is it a 'flat' bridgehead
	je .next

	or word [landscape3 +2*esi], 1 << 14
	
	test byte [landscape5(si,1)], 6
	jnz .roadbridge
	mov al, [landscape5(si,1)]
	and al, 1
	movzx bx, al
	shl bx, 1
	not ax
	and ax, 1
	or bx, ax
	shl bx, 4
	or word [landscape3 +2*esi], bx
	jmp short .next

.roadbridge:
	mov al, [landscape5(si,1)]
	not al
	and al, 1
	movzx bx, al
	shl bx, 1
	not ax
	and ax, 1
	or bx, ax
	mov bh, bl
	shl bl, 2
	or bl, bh
	xor bh, bh
	shl bx, 4
	or word [landscape3 +2*esi], bx
	
.next:
	inc esi
	cmp esi, 10000h
	jb .loop
	pop esi
	pop ebp
	ret
