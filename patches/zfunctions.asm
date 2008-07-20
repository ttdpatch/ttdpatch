#include <std.inc>
#include <ptrvar.inc>
#include <flags.inc>
#include <bitvars.inc>
#include <veh.inc>

extern fixtunnelentry.enterz, patchflags, Class9RouteMapHandlerTunnel_intc_dir

uvard curtracertheightvar	//format potentially subject to change
//0=normal routing
//signed 16bit non-zero value, relative height to north corner of tile (unimplemented)
//0x10000=definitely on ground
//0x10001=on bridge
//0x2xxxx=absolute (potentially signed?) height/8 (unimplemented)


uvard trfs_pzac_retaddr

exported TraceRouteFirstStep_PushZAndCheck
	//int3
	pop eax				//discard ret
	pop eax
	push DWORD [curtracertheightvar]
	push eax			//di, bx
	testflags enhancetunnels
	jc .enh
	jmp [trfs_pzac_retaddr]
.enh:
	push DWORD [trfs_pzac_retaddr]
	mov eax, [esp+8+4]
	jmp fixtunnelentry.enterz

exported TraceRouteFirstStep_PopZ
	pop eax
	pop DWORD [curtracertheightvar]
	jnz .quit
	xor bl, 4
	push si
	jmp eax
.quit:
	ret
	
exported zfuncclass9bridgeroutemaphandler

	xor	si, si

	test	ah, 40h
	jz	cl9rtmpbridgehead

	cmp DWORD [curtracertheightvar], 0x10001
	je loc_578C70
				; CODE XREF: Class9RouteMapHandler+34j ...

	test	ah, 20h
	jnz	short loc_578C55
	and	ah, 18h
	cmp	ah, 8
	jnz	short loc_578C70
	and	ah, 0E7h
	or	ah, 30h

loc_578C55:				; CODE XREF: Class9RouteMapHandler+55j
	and	ah, 18h
	shr	ah, 2
	cmp	al, ah
	jnz	short loc_578C70
	xor	si, 2
	test	BYTE [landscape5(di)], 1
	jz	addnewdirs
	xor	si, 3

addnewdirs:
	xor si, [landscape3+edi*2+1]
	and si, 0x3F

loc_578C70:				; CODE XREF: Class9RouteMapHandler+50j ...


	cmp DWORD [curtracertheightvar], 0x10000
	je loc_578C37

cl9rtmpbridgehead:
	mov	ah, [landscape5(di)]
	and	ah, 6
	cmp	al, ah
	jnz	short loc_578C37
//	mov	si, 1
//	test	BYTE [landscape5(di)], 1
//	jz	short loc_578C37
//	mov	si, 2
	movzx eax, BYTE [landscape5(di)]
	and al, 1
	inc al
	or si, ax

loc_578C37:

	movzx	eax, si
	mov	ah, al



ret

uvarb zfuncdotraceroutehook_flags

//ecx=valid veh pointer, edi=tile coord
//trashable=none

exported zfuncdotraceroutehook
/*	push eax
	mov eax, 0x10000
	mov al, [ecx+veh.vehstatus+1]
	and al, 1
	mov [curtracertheightvar], eax
	pop eax
*/
	push eax
	mov al, [landscape4(di)]
	shr al, 4
	cmp al, 9
	jne .norm
	mov al, [landscape5(di)]
	test al, 0xC0
	jns .norm	//tunnel
	jpo .gnd	//bridge head

	test BYTE [zfuncdotraceroutehook_flags], 1
	jz .skipdircheck
	mov ah, [ecx+veh.direction]
	shr ah, 1
	jnc .gnd
	xor al, ah
	and al, 1
	jnz .gnd
.skipdircheck:

	//bridge middle part, this is where the work begins
	call quickgetminmaxtilegndheight
	shl ah, 3
	shl al, 3
	add ah, [landscape7+edi]
	add ah, 6
	add al, 6	//vehicle must be at least 6 height levels above max ground under bridge to classify as on bridge
	cmp [ecx+veh.zpos], ah
	jb .gnd
	cmp [ecx+veh.zpos], al
	jb .gnd
	//vehicle is on bridge
	pop eax
	mov DWORD [curtracertheightvar], 0x10001
	ret

.norm:
	pop eax
	ret
.gnd:
	pop eax
	mov DWORD [curtracertheightvar], 0x10000
	ret
	
//in: edi=tile, out al=max height (L4 format), ah=min height
//trashes eax
exported quickgetminmaxtilegndheight
	push ebx
	mov ax, [landscape4(di)]
	//mov ah, [landscape4(di)+1]
	and eax, 0x0F0F
					//al=a, ah=b
	mov bh, al
	sub al, ah			//al=a-b, carry is 1 if b>a
	cmc				//carry is now 1 if a>=b
	sbb bl, bl			//bl=-1 if a>=b, 0 otherwise
	and al, bl			//al=a-b if a>=b, 0 otherwise
	sub bh, al			//bh=a-(a-b)=b if a>b, else a-0=a
	add al, ah			//al=b+a-b=a if a>=b, else b+0=b
	mov ah, bh
	//al=max of top two corners, ah=min
	shl eax, 16

	mov ax, [landscape4(di)+0x100]
	//mov ah, [landscape4(di)+0x101]
	and ax, 0x0F0F
					//al=a, ah=b
	mov bh, al
	sub al, ah			//al=a-b, carry is 1 if b>a
	cmc				//carry is now 1 if a>=b
	sbb bl, bl			//bl=-1 if a>=b, 0 otherwise
	and al, bl			//al=a-b if a>=b, 0 otherwise
	sub bh, al			//bh=a-(a-b)=b if a>=b, else a-0=a
	add ah, al			//ah=b+a-b=a if a>=b, else b+0=b
	mov al, bh
	//al=min of bottom two corners, ah=max
	
	//eax=min,max,max,min
	
	ror eax, 8

	sub al, ah			//al=a-b, carry is 1 if b>a
	cmc				//carry is now 1 if a>=b
	sbb bl, bl			//bl=-1 if a>=b, 0 otherwise
	and bl, al			//bl=a-b if a>=b, 0 otherwise
	add bl, ah			//bl=b+a-b=a if a>=b, else b+0=b
	
	//bl=overall max

	shr eax, 16
	sub al, ah			//al=a-b, carry is 1 if b>a
	sbb bh, bh			//bh=-1 if b>a, 0 otherwise
	and al, bh			//al=a-b if b>a, 0 otherwise
	add ah, al			//ah=b+a-b=a if b>a, else b+0=b

	//ah=overall min

	mov al, bl
	pop ebx
	ret

varw dirtoxyoffset
dw 0FFFFh, 100h, 1, 0FF00h
endvar


exported trrtstepadjustxycoordfromdir	//eax is fair game
	mov al, [landscape4(di)]
	shr al, 4
	cmp al, 9
	jne .justdoit
	mov al, [landscape5(di)]
	mov ah, al
	and al, 0xC0
	jns .justdoit

	add di, [dirtoxyoffset+ebx-1]

	push ecx
	mov cl, [landscape4(di)]
	shr cl, 4
	cmp cl, 9
	jne .exit
	mov cl, [landscape5(di)]
	mov ch, cl
	and cl, 0xC0
	jns .exit
	cmp cl, al
	je .exit	//either both are heads or both are middle sections of bridges, or in different bridge directions

	//ah=original l5, ch=new l5
	mov cl, bl
	shr cl, 1	//correct l5 x/y bridge direction bit in bit 0
	xor cl, ah
	test cl, 1
	jnz .exit	//wrong direction
	
	xor ah, ch
	test ah, 1
	jnz .exit	//different directions
	
	shr ecx, 14
	and ecx, 1	//1 if moving onto bridge middle, 0 if moving off
	add ecx, 0x10000
	mov DWORD [curtracertheightvar], ecx

.exit:
	pop ecx
ret
.justdoit:
	add di, [dirtoxyoffset+ebx-1]
	mov DWORD [curtracertheightvar], 0x10000
ret

exported isnexttileconnectedgetroutemaphook
	mov al, [esp+4]	//direction
	or al, 0x80		//to make it obvious that it is valid
	mov [Class9RouteMapHandlerTunnel_intc_dir], al
	
	testflags advzfunctions
	jnc .justdoit
	xchg ecx, esi
	movzx edi, di
	call zfuncdotraceroutehook
	xchg ecx, esi
.justdoit:
	xor eax, eax
	call $
	ovar .oldfn, -4, $,isnexttileconnectedgetroutemaphook
	mov DWORD [curtracertheightvar], 0
	mov BYTE [Class9RouteMapHandlerTunnel_intc_dir], 0
	ret
	
exported createbridgecheckrailtile
	setz dl
	test dh, 0xC0
	jnz .exit
	inc dl
	xor dh, dl
	mov [landscape3+esi*2+1], dh
	mov dh, 1
.exit:
	ret
	
exported removebridgerestoreroutetile
	//or eax, eax
	jz .correct
	and dl, 1
	shl dl, 1
	or al, dl
	ret
.correct:
	xchg al, [landscape3+edi*2+1]
	and al, 0x3F
	and dl, 1
	xor dl, 1
	inc dl
	xor dl, al
	mov dh, 0x10
	add DWORD [esp], 8
	ret

uvard ztemplocalroutemaphash, 0x200	//old array stores 0x800 records, initialise to -1
uvard ztemplocalroutemap, 0x1200*4	//a new templocalroutemap which includes z-ness, make it bigger to account for height disparities, make it also wider so more stuff can get fit in
uvard ztemplocalroutemapleft		//initialise to 0x1200
uvard ztemplocalroutemapnextnum		//initialise to 0
uvard ppTempLocalRouteMap

/*
exported addsignaltoblockhook
	mov eax, [curtracertheightvar]
	movzx edi, di
	mov al, [landscape4(di)]
	and al, 0xF0
	ret
*/

exported addtolocalroutemaphook

	call newaddtolocalroutemap

	pop ebx	//get return address
	push ax
	movzx ax, ch
	jmp ebx

exported newaddtolocalroutemap		//to reduce clashes use lower bits
	cmp DWORD [ztemplocalroutemapleft], 0
	jle NEAR .ret
	pushad
	mov edx, [curtracertheightvar]
	movzx ax, ch
	test cl, 8
	jz .noswap
	xchg al, ah
.noswap:
	mov bx, di
	shl bl, 3
	shr bx, 2
	and ebx, 0x1FF8>>2
	mov ebp, [ztemplocalroutemapnextnum]
	movzx ecx, WORD [ztemplocalroutemaphash+ebx]
	or cx, cx
	js .stashdata_blank
.test_existing:
	movsx ecx, cx
	shl ecx, 4
	js .new
	lea ebx, [ztemplocalroutemap+ecx]
	mov cx, [ebx+8]
	cmp [ebx], di
	jne .test_existing
	cmp [ebx+4], edx
	jne .test_existing
	//add route bits to existing
	or [ebx+2], ax
	jmp .quit
.new:
	mov [ebx+8], bp
	jmp .stashdata
.stashdata_blank:
	mov [ztemplocalroutemaphash+ebx], bp
.stashdata:
	dec DWORD [ztemplocalroutemapleft]
	inc DWORD [ztemplocalroutemapnextnum]
	shl ebp, 4
	lea ebp, [ztemplocalroutemap+ebp]
	mov [ebp], di
	mov [ebp+2], ax
	mov [ebp+4], edx
	mov WORD [ebp+8], 0xFFFF
.quit:
	popad
.ret:
	stc
	ret

exported addsignaltoblockhook3
	movsx ebp, WORD [ztemplocalroutemaphash+ebx]
.next:
	shl ebp, 4
	js .fret
	lea ebx, [ebp+ztemplocalroutemap]
	movsx ebp, WORD [ebx+8]
	cmp [ebx], di
	jne .next
	mov ecx, [ebx+4]
	or ecx, ecx
	jnz .tricky
.norm:
	mov cl, [esi+veh.movementstat]
	mov ch, cl
	test [ebx+2], cx
	jz .next
	ret
.fret:
	cmp esp, esp
.ret:
	ret
.normp:
	pop eax
	jmp .norm

.tricky:
	test ecx, 0x10000
	jz .norm
	//quick check that this is a bridge
	push eax
	mov al, [landscape4(di)]
	shr al, 4
	cmp al, 9
	jne .normp
	test BYTE [landscape5(di)], 0xC0
	jz .normp
	jpo .normp
	call quickgetminmaxtilegndheight
	shl ah, 3
	add ah, [landscape7+edi]
	add ah, 8
	cmp [esi+veh.zpos], ah
	setb al				//al=1 if below bridge
	xor al, cl	//al now=0 if incorrect height
	pop eax
	jz .next
	mov cl, [esi+veh.movementstat]
	mov ch, cl
	test [ebx+2], cx
	jz .next
	ret

exported dotraceroutehook
	pushad
	cld
	mov edi, ztemplocalroutemaphash
	or eax, byte -1
	mov ecx, 0x200
	rep stosd
	mov DWORD [ztemplocalroutemapnextnum], 0
	mov DWORD [ztemplocalroutemapleft], 0x1200
	popad
	xor eax, eax
	mov ecx, 0x200
	ret


