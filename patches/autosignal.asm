// auto-signal code

#include <std.inc>

// called from patch action handler for signal gui
//
// in:	ax=tile X
//	bl=action handler flags
//	cx=tile Y
//	dl=track piece
//	dh=1
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

	bsf ebp,edx
	mov dh,[sigbitsonpiece+ebp]
	and dh,[landscape3+edi*2]
	jz .fail
	jpe .twoway		// two bits set -> two way signal

	test dh,0x10+0x40
	setz dh
	inc dh
	jmp short .gotbits

.twoway:
	mov dh,3

	extern tilebitsclockwise

.gotbits:
	push ebp
	movzx ebp,byte [dirfrompiece+ebp]
	shr ebp,1
	jc .gotdir1
	cmp dl,[tilebitsclockwise+1+ebp*2]
	je .gotdir1
	dec ebp
	and ebp,3
.gotdir1:
	lea ebp,[ebp*2+1]
	xor esi,esi
	push edi
	call autosignals
	pop edi
	pop ebp
	cmp esi,0x80000000
	je .done

	movzx ebp,byte [dirfrompiece+ebp]
	shr ebp,1
	jc .gotdir2
	cmp dl,[tilebitsclockwise+1+ebp*2]
	jne .gotdir2
	dec ebp
	and ebp,3
.gotdir2:
	lea ebp,[ebp*2+1]
	cmp dh,3
	je .nototherway
	xor dh,3
.nototherway:
	call autosignals

	test esi,esi
	jle .fail

.done:
	mov ebx,esi
	pop ecx
	pop eax
	ret

.fail:
	mov esi,0x80000000
	jmp .done

// in:	esi=cost so far
//	 dl=track piece
//	 dh=signal direction, 1=forward, 2=backwards, 3 for two-way
//	edi=XY
//	ebp=direction
// out:	esi=cost
autosignals:
	mov cl,0

	extern sigbitsonpiece,dirfrompiece,getnextdirandtile,piececonnections
	extern actionhandler

.nexttile:
	cmp cl,3*4
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
	add [esp+4],ebx
	cmp ebx,0x80000000
	popa
	je .done

	cmp dh,3
	je .havebits

	bsf eax,edx

.havebits:
	mov cl,0

.nothere:
	cmp dl,4
	adc cl,3	// add 3 for pieces 4 8 10 20 and 4 for pieces 1 2

	// go to following tile
	call getnextdirandtile
	mov al,[landscape4(di)]
	and al,0xf0
	cmp al,0x10
	jne .done

.goodtile:
	mov dl,[landscape5(di)]
	test dl,0xc0
	js .done		// depot
	jnz .done		// signals

	and dl,[piececonnections+ebp]
	jz .done

	bsf eax,edx
	add eax,8
	bts eax,eax
	cmp ah,dl
	je .nexttile		// if equal, that was the only piece, else we have a junction

.done:
	ret

