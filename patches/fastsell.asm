// Faster selling of trains

#include <defs.inc>
#include <flags.inc>
#include <veh.inc>
#include <ttdvar.inc>
#include <ptrvar.inc>

extern curplayerctrlkey,delveharrayentry,detachfromsoldengine,isengine
extern patchflags

uvard sellcost

// Called when selling a train engine
// in:	ax,cx: coordinates
//	edx points to the engine to be sold
//	bit 0 of bl is clear if checking cost only
// safe: ax,cx,di,esi
global sellengine
sellengine:
	// We've owerwritten a je near +0x8c, adjust return address manually
	jne .noadjust
	add dword [esp],0x8c
.noadjust:
	and dword [sellcost],0

	testflags fastwagonsell
	jnc .normalsell

	cmp byte [curplayerctrlkey],0
	jz .normalsell

	pusha
	mov esi,edx
	mov eax,[veharrayptr]
.loop:
	movzx esi,word [esi+veh.nextunitidx]
	cmp si,-1
	jz .done

	shl esi,vehicleshift
	add esi, eax
	mov ecx, [esi+veh.value]
	add [sellcost],ecx
	test bl,1
	jz .loop

	call dword [delveharrayentry]
	jmp short .loop
.done:
	popa
	test bl,1
	jz .dontmodifyengine
	or word [edx+veh.nextunitidx],-1
.dontmodifyengine:
	ret

.normalsell:
	// if vehicle is multiheaded, up to two heads will be sold
	// count them here
	movzx esi,byte [edx+veh.vehtype]
//	add esi,[enginepowerstable]
	test byte [numheads+esi],1
	jz .notmulti
	pusha
	movzx eax,word [edx+veh.nextunitidx]
	cmp ax,byte -1
	je .multidone
	shl eax,7
.nextmulticheck:
	call detachfromsoldengine	// sets [sellcost], nothing else
	cmp dx,byte -1
	je .multidone
	movzx eax,dx
	shl eax,7
	jmp .nextmulticheck
.multidone:
	popa
.notmulti:
	ret


// Called to decide the cost of selling an engine (should be a negative value)
// in:	ax,cx: coordinates
//	edx points to the engine to be sold
//	bit 0 of bl is clear if checking cost only
// out:	ebx: selling cost
//	esi: engine type for dualhead-checking
//	carry flag set to skip dualhead-checking
// safe: ax, ebx, cx, edx, di, esi
global enginesellcost
enginesellcost:
	mov ebx,[edx+veh.value]
	neg ebx
	sub ebx,dword [sellcost]
	stc
	ret

// Called when selling a train engine
// in:	edx->wagon to be sold
//	esi->engine
//	bit 0 of bl is clear if checking cost only
// out:	di=index of following vehicle (or -1)
// safe: ax,ebx,cx
global sellwagon
sellwagon:
	jnz .notzero
	add dword [esp],0x7d-4
	jmp short .start
.notzero:
	cmp byte [edx+veh.subclass],4
.start:
	pushf
	and dword [sellcost],0

	// for now, following vehicle is what follows the wagon being sold
	mov di,[edx+veh.nextunitidx]

	testflags fastwagonsell
	jnc near .normalsell

	cmp byte [curplayerctrlkey],0
	jz near .normalsell

	and bl,~2		// bit 2 set when selling an articulated engine multihead

.fastsell:
	pusha
	mov eax,[veharrayptr]
	mov esi,edx
.loop:
	mov cx,[esi+veh.nextunitidx]
	test bl,1
	jz .nodetach
	mov word [esi+veh.nextunitidx],-1
.nodetach:
	cmp cx,byte -1
	je .done
	movzx esi,cx
	shl esi,vehicleshift
	add esi,eax
	cmp byte [esi+veh.artictype],0xfe
	jae .sellit

.notarticulated:
	test bl,2
	jnz .doneusecx	// we have all articulated pieces

	testflags multihead
	jc .sellit	// Don't treat engines specially if multihead on.

	mov cx,[esi+veh.vehtype]
	bt [isengine],cx
	jc .engine

.sellit:
	// we're selling a wagon; this means it'll be removed from the
	// consist and the new following wagon will be the one that followed
	// this one
	// i.e.  ... wagon-being-sold this-wagon following-wagon ...
	// becomes ... wagon-being-sold following-wagon ...
	// (wagon-being-sold is the one the user ctrl-clicked on; it'll actually
	// be sold later by TTD, that's why we need to make sure the consist is ok)

	cmp di,byte -1	// but we don't sell it if there was an engine in-between
	je .nochain
	mov di,[esi+veh.nextunitidx]
	mov [esp],di	// edi on stack from pusha
.nochain:
	mov ecx,[esi+veh.value]
	add dword [sellcost],ecx
	test bl,1
	jz .loop

	call dword [delveharrayentry]
	jmp .loop

.engine:
	mov di,-1	// it's an engine, and won't be sold, stop updating the follower-wagon

	test bl,1
	jz .loop

	mov cx,[esi+veh.idx]
	mov [edx+veh.nextunitidx],cx
	mov edx,esi
	jmp .loop

.doneusecx:
	mov [esp],cx

.done:
	popa
	jmp short .reallydone

.normalsell:
	cmp byte [edx+veh.artictype],0xfd
	je .isarticengine

	mov al,bl
	movzx ebx,word [edx+veh.nextunitidx]
	cmp bx,byte -1
	je .reallydone
	shl ebx,7
	add ebx,[veharrayptr]
	cmp byte [ebx+veh.artictype],0xfe
	jb .reallydone

	// it's an articulated engine multihead, sell all pieces
.isarticengine:
	or al,2
	mov bl,al
	jmp .fastsell

.reallydone:
	popf
	ret

global wagonsellcost
wagonsellcost:
	mov ebx, [edx+veh.value]
	neg ebx
	sub ebx,dword [sellcost]
	mov cx,[esp+4]
	ret 2
