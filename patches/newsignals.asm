#include <std.inc>
#include <flags.inc>
#include <textdef.inc>
#include <bitvars.inc>
#include <signals.inc>
#include <grf.inc>

extern advvaraction2varbuff,getnewsprite,curcallback,grffeature,miscgrfvar,callback_extrainfo,newspriteyofs,gettileterrain
extern gettileinfoshort,mostrecentspriteblock,drawspritefn, setsignaloffsets, lastdrawnsignalnum

global newsignalson
uvarb newsignalson
uvard newsignalsfeaturebits
uvard AddSpriteToDisplay
uvard newsignalspritenum
uvard newsignalspritebase
uvard vnewsignalspritenum
uvard vnewsignalspritebase

uvard curtilecoord

//8 directions, 2 states, 4 presignal states, 2 PBS states, 2 semaphore states, 2 restricted states, 2 programmed states, 2 through states, 2 1-2 inv states
%define numsignalcombos 8*2*4*2*2*2*2*2*2 //1024

//bits of var 10:
//0:		Green
//1-3:		Front facing: 0=SW, 1=NE, 2=NW, 3=SE, 4=E, 5=W, 6=S, 7=N
//4-5:		Presignals: 0=norm, 1=entrance, 2=exit, 3=combo
//6:		Semaphore
//7:		PBS
//8:		Restricted
//9:		Programmed
//10:		Through
//11:		1-2 inversion

//bits of var 18:
//0-7:		L5 of signal tile
//			0: track in X
//			1: track in Y
//			2: track in N
//			3: track in S
//			4: track in W
//			5: track in E
//8-15:		Low half of L3 of tile, bits 4-7 bitmask of which signals present as shown below, bits 0-3: track type
//16-23:	Which signal is currently being drawn, bit index of L3 signal mask:
//	  	* For track in the X direction:
//		    6: 	signal in the SW direction
//		    7: 	signal in the NE direction
//		* For track in the Y direction:
//		    6: 	signal in the NW direction
//		    7: 	signal in the SE direction
//		* For tracks in the W-E direction:
//		    4:  signal in the W direction on the track in the S corner
//		    5: 	signal in the E direction on the track in the S corner
//		    6: 	signal in the W direction on the track in the N corner
//		    7: 	signal in the E direction on the track in the N corner
//		* For tracks in the N-S direction:
//		    4: 	signal in the S direction on the track in the E corner
//		    5: 	signal in the N direction on the track in the E corner
//		    6: 	signal in the S direction on the track in the W corner
//		    7: 	signal in the N direction on the track in the W corner
//24-27:	Land/Fence type
//28-31:	Terrain type: 0=normal, 1=desert, 2=rainforest, 4=snow


//callback return value:
//0:		use new sprites
//1-4:		num sprites, vars 0x20-2F
//5:		use recolour sprite specified in var 0x30
//6:		use ordinary signal sprite number: var 0x20, (this overrides all other bits)

//varact2var value
//0-12:		sprite number
//13:		add sprite yrel to Y correction for next sprite (sub from 3D Z), (yrel must fit in a signed byte)
//14-18:	sprite Y (-3D Z) correction for next sprite, (signed), (added to total)
//		Overall change to 3D Z, (-Y correction), must be positive, else risk of TTD crashing.
//19-23:	sprite Y (-3D Z) correction for this sprite only, (signed), (not added to total)
//24-27:	sprite X correction for next sprite << 1, (signed), (added to total)
//28-31:	sprite X correction for this sprite only << 1, (signed), (not added to total)

uvarb drawtype

//eax=Variable 10, ebx=sprite to use on fail, cx,dx = x,y on screen, edi=screen block, esi=Variable 18
exported newsignalsdrawsprite
	push DWORD .ret
	pushad
	mov BYTE [drawtype], 1
	mov [miscgrfvar], eax
	mov eax, esi
	xor esi, esi
	mov [curtilecoord], esi
	jmp newsignalsdraw.spritein
.ret:
	jc .err
	ret
.err:
	pusha
	call [drawspritefn]
	popa
	ret
	
varb signumtol3bit
db 0x40, 0x80, 0x10, 0x20, 0x80, 0x40
db 0x20, 0x10, 0x80, 0x40, 0x80, 0x40
endvar

global newsignalsdraw
//sets carry on failure
newsignalsdraw:
	pushad

	mov BYTE [drawtype], 0
	movzx ebx, bx
	// ebx-4fbh=org signal state, esi*8=(type of signal)*16
	lea edi,[ebx-0x4fb+esi*8]
	
	mov ebx, [esp+32+4]	//addr in drawsignal code
	mov esi, [ebx+4]
	lea esi, [esi+ebx+8]
	mov [AddSpriteToDisplay], esi

	mov esi, [esp+4+4+32]		// landscape offset

	test BYTE [landscape6+esi], 4
	jz .nothrough
	movzx ebx, BYTE [lastdrawnsignalnum]
	xor bl, 1
	mov bl, [signumtol3bit+ebx]
	test BYTE [landscape3+esi+esi], bl
	jnz .nothrough
	pushad
	movzx ebx, BYTE [lastdrawnsignalnum]
	xor bl, 1
	and al, 0xF0
	and cl, 0xF0
	call setsignaloffsets
	mov ebx, [esp+16]	//from pushad
	mov edi, [esp]
	xor edi, 2		//change direction
	or edi, 0x400
	push DWORD .donethrough
	pushad
	jmp .nothrough		//recursively call opposite direction, for through signal indicator, display nothing if new-signals fails
.donethrough:
	popad
.nothrough:

	mov DWORD [miscgrfvar], edi

	mov ebx, eax
	mov [curtilecoord], esi
	call gettileterrain
	shl eax, 4
	movzx esi, BYTE [landscape2+esi]
	and esi, BYTE 0xF
	or eax, esi
	mov esi, [esp+12+4+32]
	movzx esi, BYTE [esi-6]
	cmp esi, 0x90		// (or a NOP, which we change to 80h)
	jne .notnop
	mov esi, 0x80
.notnop:
	bsf esi, esi
	shl esi, 8
	or eax, esi

	//bswap eax
	xchg al, ah
	shl eax, 16

	mov esi, [curtilecoord]
	mov ah, [landscape3+esi*2]
	mov al, [landscape5(si)]
.spritein:
	mov DWORD [curcallback],0x146
	mov BYTE [grffeature],0xE
	mov DWORD [callback_extrainfo], eax
	mov eax, 0x10E
	xor esi, esi
	call getnewsprite
	xor esi, esi
	mov [miscgrfvar], esi
	mov [curcallback], esi
	mov [callback_extrainfo], esi
	mov [cursigdataflags], esi
	test eax, 0x40
	jnz NEAR .gotsignumret
	test eax, 1
	jz NEAR .fret
	shr eax, 1
	mov edi, [mostrecentspriteblock]
	mov esi, [edi+spriteblock.nsigact5data+4]
	mov edi, [edi+spriteblock.nsigact5data]
	or edi, edi
	jnz .notplainact5
	mov edi, [newsignalspritebase]
	mov esi, [newsignalspritenum]
.notplainact5:
	mov [vnewsignalspritebase], edi
	mov [vnewsignalspritenum], esi
	xor esi, esi
	or edi, edi
	jz NEAR .fret
	cmp edi, 0xFFFF
	je NEAR .fret
	btr eax, 4
	jnc .norecolour
	mov esi, [advvaraction2varbuff+0x30*4]
	cmp esi, [vnewsignalspritenum]
	jae NEAR .fret
	add esi, edi
	shl esi, 16
	or esi, 0x8000
.norecolour:
	add esi, edi
	and eax, 0xF
	jz NEAR .fret
	lea edi, [eax-1]
	mov eax, ebx
	shl edi, 16
	push esi			//this value picked up off stack, = sprite base, flags&recolour sprite
.loop:
	push edi			//loop counter, down in high, up in low
	and edi, BYTE 0xF
	mov ebx, [advvaraction2varbuff+0x20*4+edi*4]
	mov edi, ebx
	and edi, 0x1FFF
	mov esi, edi
	shl edi, 16
	
	btr ebx, 13
	jnc .noaddrel
	add esi, [vnewsignalspritebase]
	add esi, esi
	add esi, [newspriteyofs]
	mov di, [esi]
.noaddrel:

	//at this point:
	//ebx=current varaction2var 0x20-0x2F value, edi=high:sprite offset,low:y correction for next sprite
	//if normal: ax=landscape x, cx=landscape y, dl=height
	//if screen: cx=x, dx=y
	
	test BYTE [drawtype], 1
	jnz .scdraw

	shr ebx, 11
	sar bl, 3
	neg bl
	add bl, dl		//14-18, add - Y-correction for next sprite to height

	movzx esi, bl
	sub si, di		//subtract y-rel correction from this
	
				//si is now height to put next sprite

	shr ebx, 5
	sar bl, 3
	sub dl, bl		//subtract y-correction for this sprite from this sprite's height
	
	shr ebx, 4		//sprite x-correction for next sprite
	sar bl, 4
	movsx di, bl
	add si, di		//gets added once to next Z
	shl esi, 16		//Z goes high
	add di, cx		//gets added once to next Y
	mov si, di		//Y gets packed in esi:low with Z
	push esi

	shr ebx, 4		//sprite x-correction for this sprite only
	sar bl, 4
	movsx di, bl
	add dl, bl		//add to height
	add cx, di		//add to Y

	mov ebx, edi		//pull sprite-offset from edi:high
	shr ebx, 16
	cmp ebx, [vnewsignalspritenum]
	jae .dontdraw
	add ebx, [esp+8]
	mov di, 1
	mov si, di
	mov dh, 0x10
	call [AddSpriteToDisplay]	// EBX = sprite number & flags (bit 14: transparent, bit 15: recolor)
					// AX,CX,DL = landscape X,Y,Z base coordinates (preserved by the call)
					// DI,SI,DH = landscape X,Y,Z extents
					// Return: DH = 0=added, 1=not added
.dontdraw:
	pop edx
	mov cx, dx
	shr edx, 16
.donedrawing:
	pop edi
	add edi, 1-0x10000
	jns .loop
	add esp, 4

	popad
	clc
ret
.scdraw:
	shr ebx, 3
	sar bx, 11
	add di, bx		//di=next Y
	add di, dx

	shr ebx, 5
	sar bx, 11
	add dx, bx		//add Y correction to Y
	
	shr ebx, 4		//sprite x-correction for next sprite
	sar bx, 12
	add bx, bx
	mov si, bx		//si=next x
	add si, cx
	
	shr ebx, 4		//sprite x-correction for this sprite only
	sar bx, 12
	add bx, bx
	add cx, bx

	pushad
	mov ebx, edi		//pull sprite-offset from edi:high
	shr ebx, 16
	cmp ebx, [vnewsignalspritenum]
	jae .dontdraw2
	add ebx, [esp+4+32]
	mov edi, [esp+8+32]	//edi is last on stack from previous pushad
	call [drawspritefn]
.dontdraw2:
	popad
	mov dx, di
	mov cx, si

	jmp .donedrawing
.fret:
	popad
	stc
ret
.gotsignumret:
	popad
	mov ebx, [advvaraction2varbuff+0x20*4]
	mov esi, ebx
	and ebx, BYTE 0xF
	xor esi, ebx
	shr esi, 3
	stc
ret


//parameterised var 60
//ah=param
//returns: eax=:
//0-7:		L5
//8-15:		L3 low
//16-20:	Altitude of tile<<3
//21-25:	Slope map of tile
//26:		tile has same owner
//27:		semaphores
//28:		tile has same track bits
//29:		tile has same slope and altitude
//30:		tile has signals
//31:		tile is a track tile
//return value cached in varaction2var 10

uvarb cursigl5
uvarb cursigslope
uvarb cursigalt
uvard cursigdataflags //1=got curtilecoord height,L5 data cached

global getsigtiledata
getsigtiledata:
	pusha
	mov esi, [curtilecoord]
	or esi, esi
	jz NEAR .megafail
	bts DWORD [cursigdataflags], 0
	jc .nosetcache
	call [gettileinfoshort]		// in SI=XY, out ESI=XY, DL=Z, DH=L5[ESI], BX=class<<3, DI=map of corners above DL
	and dh, 0x3F
	mov [cursigl5], dh
	mov [cursigalt], dl
	mov dx, di
	mov [cursigslope], dl
.nosetcache:
	//coordinate offseting
	mov ebp, esi
	movzx edx, ah
	shl dl, 4
	sar dl, 4
	mov dh, ah
	sar dh, 4
	add esi, edx

	call [gettileinfoshort]
	mov ax, di
	mov ah, dl

	//track tile, signals
	movzx ecx, dh //BYTE [landscape5(si)]
	mov dh, bl
	movzx ebx, WORD [landscape3+esi*2]
	mov ch, bl
	//mov dh, [landscape4(si)]
	shr dh, 4
	dec dh
	jnz .nottrack
	mov dl, cl
	and dl, 0xC0
	xor dl, 0x40
	setz dl
	shl edx, 30
	lea ecx, [ecx+edx+(1<<31)]

	//track bits
	mov dl, cl
	and dl, 0x3F
	cmp dl, [cursigl5]
	setz dl
	shl edx, 28
	or ecx, edx

	//owner
	mov dl, [landscape2+esi]
	cmp dl, [landscape2+ebp]
	setz dl
	shl edx, 26
	or ecx, edx

	//semaphore
	bt ecx, 30
	jnc .nottrack
	mov edx, ebx
	shl edx, 16
	and edx, 1<<27
	or ecx, edx

	.nottrack:
	
	//slope, altitude
	cmp [cursigalt], ah
	sete dl
	cmp [cursigslope], al
	sete dh
	and dl, dh
	and edx, BYTE 1
	or ecx, edx
	movzx edx, al
	shl edx, 21
	or ecx, edx
	movzx edx, ah
	shr edx, 3
	shl edx, 16
	or ecx, edx

	mov [advvaraction2varbuff+0x10*4], ecx
	mov [esp+28], ecx
	popa
ret
.megafail:
	mov DWORD [esp+28], 0
	popa
	ret

