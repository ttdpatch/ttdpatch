// auto-signal code

#include <std.inc>

// called from patch action handler for signal gui
//
// in:	ax=tile X
//	bl=action handler flags
//	cx=tile Y
//	dl=track piece
//	dh=1
//	edx(16:23)=separation
// out:	ebx=cost
// safe:as in action handler
exported buildautosignals
	push eax
	push ecx

	movzx edi,ax
	and edi,byte ~0xf
	and ecx,byte ~0xf
	shr edi,4
	shl ecx,4
	or di,cx

	extern tilebitsclockwise

	bsf esi,edx
	push esi
	movzx ebp,byte [dirfrompiece+esi]
	shr ebp,1
	jc .gotdir1
	cmp dl,[tilebitsclockwise+1+ebp*2]
	je .gotdir1
	dec ebp
	and ebp,3
.gotdir1:
	lea ebp,[ebp*2+1]

	mov dh,[sigbitsonpiece+esi]
	and dh,[landscape3+edi*2]
	jz .fail
	or dh,2
	jpo .twoway		// bit 1 + two bits set -> two way signal

	and dh,0xf0
	shr esi,1
	test dh,[signaldirbitmask+(ebp-1)*2+esi]
	setz dh

.twoway:
	shl dh,4

	xor esi,esi
	push edi
	push edx
	call autosignals
	pop edx
	pop edi
	pop ebp

	movzx ebp,byte [dirfrompiece+ebp]
	xor ebp,4
	shr ebp,1
	jc .gotdir2
	cmp dl,[tilebitsclockwise+1+ebp*2]
	je .gotdir2
	dec ebp
	and ebp,3
.gotdir2:
	lea ebp,[ebp*2+1]
	cmp dh,32
	je .nototherway
	xor dh,16
.nototherway:
	call autosignals

	shr esi,1
	jc .done

.fail:
	mov esi,0x80000000

.done:
	mov ebx,esi
	pop ecx
	pop eax
	ret


// in:	esi=cost so far
//	 dl=track piece
//	 dh=signal direction, 0=forward, 16=backwards, 32=two-way
//	edx(16:23)=separation
//	edi=XY
//	ebp=direction
// out:	esi=cost
autosignals:
	mov ecx,edx
	shr ecx,8	// now ch=separation
	jmp short .havebits

	extern sigbitsonpiece,dirfrompiece,getnextdirandtile,piececonnections
	extern actionhandler

.nexttile:
	cmp cl,ch
	jb .nothere

	// build signals on this tile
	pusha
	mov eax,edi
	movzx ecx,ah
	movzx eax,al
	shl eax,4
	shl ecx,4
	mov esi,0x060008	// CreateAlterSignals
	call [actionhandler]
	mov [esp+0x1c],ebx	// eax after popa
	popa
	cmp eax,0x80000000
	je near .done

	lea esi,[esi+eax*2]
	or esi,1

	test bl,1
	jz .havebits

	cmp dh,32
	je .havebits

	bsf eax,edx
	shr eax,1
	add al,dh
	mov al,[signaldirbitmask+(ebp-1)*2+eax]
	and [landscape3+edi*2],al

.havebits:
	mov cl,0

.nothere:
	cmp dl,4
	adc cl,3	// add 3 for pieces 4 8 10 20 and 4 for pieces 1 2

	// go to following tile
	extern tiledeltas
	add di,[tiledeltas+ebp]

	mov al,[landscape4(di)]
	and al,0xf0
	cmp al,0x10
	jne .done

.goodtile:
	mov dl,[landscape5(di)]
	and dl,[piececonnections+ebp]
	jz .done

	bsf eax,edx
	add eax,8
	bts eax,eax
	cmp ah,dl
	mov ah,0
	jne .done		// if not equal it's a junction

	test byte [landscape5(di)],0xc0
	js .done		// depot
	jz .nosignals

	mov ah,[sigbitsonpiece+eax-8]
	test [landscape3+edi*2],ah
	jnz .done		// has signals

.nosignals:
	// now find new direction
	test dl,0x3c
	jz .straight

	inc ebp
	inc ebp
	and ebp,7

	cmp dl,[tilebitsclockwise+ebp]
	je .straight

	xor ebp,4

.straight:
	jmp .nexttile

.done:
	ret


varb signaldirbitmask
	// direction 1
	db ~40h,~40h,~10h,~0	// dir 1 (NE), pieces 01,04,20
	db ~40h,~10h,~20h,~0	// dir 3 (SE), pieces 02,08,20
	db ~80h,~20h,~80h,~0	// dir 5 (SW), pieces 01,08,10
	db ~80h,~80h,~40h,~0	// dir 7 (NW), pieces 02,04,10

	// direction 2
	db ~80h,~80h,~20h,~0	// dir 1 (NE), pieces 01,04,20
	db ~80h,~20h,~10h,~0	// dir 3 (SE), pieces 02,08,20
	db ~40h,~10h,~40h,~0	// dir 5 (SW), pieces 01,08,10
	db ~40h,~40h,~80h,~0	// dir 7 (NW), pieces 02,04,10
endvar

