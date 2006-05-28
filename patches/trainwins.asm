// Train Window Fixes
//
// Created by: Lakie
// Created on: May 20th 2006
//
// Houses the the code for Train window patches
// This is made with the purpose of making modifing such windows easier.
// (Enhancegui stuff has not been moved here).

#include <std.inc>
#include <flags.inc>
#include <textdef.inc>
#include <veh.inc>
#include <window.inc>

extern isengine
extern patchflags
extern getwagonlength

/************************************** Taken From Fixmisc ***************************************/

// Called to count how many rows are filled in the current depot
// in:	esi=>window
//	edi=>vehicle
//	bl=number of rows so far
//	cl=vehicle subclass (00 for train, 04 for wagon row)
// out:
// safe:cl,others?
global counttrainsindepot
counttrainsindepot:
	cmp ax,[edi+veh.XY]
	jne .done
	cmp byte [edi+veh.movementstat],0x80
	jne .done
	cmp cl,4
	je .done	// only count one row for wagon rows
	clc

	dec bl
	push edi
	push eax
.nextrow:
	call advancetonextrow
	inc bl		// doesn't touch CF
	jc .nextrow
	pop eax
	pop edi

	test al,0	// set ZF to add another row after returning

.done:
	ret
#if 0 //Now use CalcTrainDepotWidth instead of accessing this variable
var trainvehsperdepotrow, db 10	// Can be overwritten at any time by enhancegui!
#endif

// advance edi by as many vehicle as fit in a row
// returns CF and EDI=>next if train is not done, otherwise NC and ZF and DI=-1
advancetonextrow:
	pushf
	push	ecx
	mov	ecx,0x0
	cmp	byte [edi+veh.subclass],0
	je	.lnotplusrow
	mov	ecx,0x0101
.lnotplusrow:
	call CalcTrainDepotWidth
	pop ecx
	popf
	sbb al,0

.next:
	movzx edi,word [edi+veh.nextunitidx]
	cmp di,byte -1
	je .done

	shl edi,vehicleshift
	add edi,[veharrayptr]
	dec al
	jnz .next

	stc

.done:
	ret

// Called when starting next row in depot
// in:	esi=>window
//	edi=>vehicle
// out:	CF if edi is determined to start a new row
// safe:ax,others?
global checktrainindepot
checktrainindepot:
	push eax
	xor eax,eax
	xchg eax,[nextrowoftrainveh]
	test eax,eax
	jz .notcontinued

	xchg eax,edi
	cmp dword [nextvehtocheck],0
	stc
	jne .gotrow
	mov [nextvehtocheck],eax
	jmp short .gotrow

.notcontinued:
	xchg eax,[nextvehtocheck]
	test eax,eax
	jz .notafterrow

	xchg eax,edi

.notafterrow:
	cmp byte [edi+veh.class],0x10
	jne .done

	cmp byte [edi+veh.subclass],0
	jne .done

	mov ax,[esi+6]
	cmp ax,[edi+veh.XY]
	jne .done

	cmp byte [edi+veh.movementstat],0x80
	jne .done

.gotrow:
	push edi
	call advancetonextrow
	jnc .nocontinuation

	mov [nextrowoftrainveh],edi

.nocontinuation:
	pop edi
	pop eax
	stc
	ret

.done:
	pop eax
	clc
	ret

// Called when displaying one row of a train
//
// in:	esi=>window
//	edi=>vehicle
// 	cx=x pos
//	dx=y pos
// out:	adjust cx
//	al=max. number of wagons to show
// safe:?
global showtrain
showtrain:
	add cx,0x15
	push	ecx
	mov	ecx,0x0
	cmp	byte [edi+veh.subclass],0
	je	.lplusrow
	mov	ecx,0x0101
.lplusrow:
	call CalcTrainDepotWidth
	pop	ecx
	cmp byte [edi+veh.subclass],0
	je .regular

	add cx,29
	dec al

.regular:
	ret

// Called to display the train number in the depot
//
// in:	esi=>window
//	edi=>vehicle
// out:	bx=text index, CF if continuation
// safe:bx,bp
global showtrainnum
showtrainnum:
	mov bx, statictext(continuedtrain)
	cmp byte [edi+veh.subclass],0
	stc
	jne .continued

	mov bx,0xe2
	mov bp,[edi+veh.maxage]
	clc

.continued:
	ret

// Called to display the red/green flag
//
// in:	esi=>window
//	edi=>vehicle
// out:	bx=sprite for flag
// safe:bx
global showtrainflag
showtrainflag:
//	mov bx,13	// 13 for "+", 774 for a white dot in the wrong place...
	cmp byte [edi+veh.subclass],0
	stc
	jne .continued

	mov bx,3090
	test byte [edi+veh.vehstatus],2

.continued:
	ret

// Called when click in train depot window
//
// in:	esi=>window
//	edi=>vehicle
//	al=rows remaining
// out:	adjust al
// safe:?
global depotclick
depotclick:
	cmp byte [edi+veh.movementstat],0x80
	jne .nope

	dec al		// is it this row?
	js .gotit

	push edi
	push ebx

	dec bl		// first slot on following rows is empty
	inc al		// counteract following dec

.nextrow:
	dec al
	jns .trynextrow

	// yep, right train
	add esp,8
.gotit:
	test al,al	// restore sign flag
	ret

.trynextrow:
	push eax
	call advancetonextrow
	pop eax
	jc .nextrow

	// that wasn't the right train
	pop ebx
	pop edi
.nope:
	test al,0	// clear sign flag
	ret

uvard nextrowoftrainveh
uvard nextvehtocheck

/************************************* Taken From Multihead **************************************/

	//
	// called when a rr vehicle is moved inside a depot window
	// in:	edx->last vehicle in consist
	//	flags from cmp [edx+veh.subclass],0
	// out:	cf set if edx->second engine
	// safe:eax,ebx,ecx,ebp
global movedcheckiswaggonui
movedcheckiswaggonui:
	jz .done		// after a cmp, if zf=1 then cf=0

	testmultiflags multihead
	jnz .done

	movzx eax,word [edx+veh.vehtype]
	bt [isengine],eax

.done:
	ret

/********************************* Replaces the winsize.asm one **********************************/
// Calculates the number of vehicles which will fit in the depot window.
// This is for when the depot window changes length. (enchancedgui)
//
// Input:  edi - vehicle id
//	   ch  - number of vehicles to add (Before returning value)
//	   cl  - number of vehicles to subtrack (Before calculating total length avaible)
//
// Output: al  - number of vehicles which can fit
//
// Used:   eax,ebx,ecx,edi,esp
// Safe:   ?
//
// Notes:  Changed to work with Shortened vehicles (.l* labels)
global CalcTrainDepotWidth
CalcTrainDepotWidth:
	mov ax, [esi+window.width]
	sub ax, 59
	push bx
	mov bl, 29
	div bl
	pop bx

.lstart:
	push	edi // Backup registers to be used
	push	ebx
	mov	bh,ch // Move the number of ids to add
	mov	ch,0
	sub	ax,cx // Remove the number of vehicles before
	shl	ax,3 // 8 * numvehs
	mov	bl,0 // Reset counter to avoid spilage

.lgetlen:
	push	edi // Vehicle shortened by values not stored yet, so use getwagonlength
	call	getwagonlength
	mov	cl,[esp]
	add	esp,4
	and	cl,0x7F
	neg	cl
	add	cl,0x8

.ldepotlen:
	sub	ax,cx // Get length remaining
	jb	.ldone // If less than 0 then jump to end
	inc	bl

.lgetveh:
	movzx	edi,word [edi+veh.nextunitidx] // Get next vehicle id in consist
	cmp	di,-1
	je	.ldone	// Jump to end if no id

	shl	edi,vehicleshift
	add	edi,[veharrayptr]
	jmp	.lgetlen
	
.ldone:
	mov	al,bl // Return number of vehicles
	add	al,bh // Add number of vehicles from the offset
	pop	ebx // Restore Registers
	pop	edi

	ret
