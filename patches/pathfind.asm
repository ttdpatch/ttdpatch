// New and hopefully better pathfinding algorithm via A*
// (c) 2006 eis_os
//
// This code is far from working and only show some ideas

#include <std.inc>
#include <human.inc>
#include <station.inc>
#include <veh.inc>
#include <bitvars.inc>
#include <signals.inc>
#include <ptrvar.inc>

extern getroutemap

struc pf_anode
	.parent:	resd 1
	.cost:	resd 1
	.estimate 	resd 1
	.key		resd 1
	.opennext	resd 1
	.closednext resd 1
	.xy:		resw 1
	.z		resb 1
endstruc_32

%define cRoute_Rail 	0
%define cRoute_Road	2
%define cRoute_Ship	4
%define cRoute_Aircraft	6
%define cRoute_Water			800h
%define cRoute_NoLocalRouteMap	1000h
%define cRoute_NoReverse		2000h
%define cRoute_WithPostTraceFn	4000h
%define cRoute_SignalBlock		8000h

uvard pf_lastnodeptr,1,z
uvard pf_lastnodeendptr,1,z

varw pfTraceDirRoutesHigh
	dw 0, 0x10, 0x5, 0x2A
endvar

uvarw pfXYDest,1,z
uvarb pfXYNoDest,1,z
uvard pfClosedList,1,z
uvard pfOpenList,1,z
uvard pfBestNode,1,z

uvard pfttdstepfn,1,z


// out: 	ebp=best node or 0
getBestNodeOpen:
	mov ebp, [pfOpenList]
	ret

// in:		ebp=node
addNodeOpen:
	pusha
	mov ecx,[ebp+pf_anode.estimate]

	mov edi, pfOpenList-pf_anode.opennext	// let edi point so [edi+pf_anode.opennext] = [pfOpenList]
.insertsearchnext:
	mov esi, edi
	mov edi, [esi+pf_anode.opennext]
	cmp edi, 0
	je .insert
	cmp [edi+pf_anode.estimate], ecx
	jb .insertsearchnext

.insert:
	mov [ebp+pf_anode.opennext], edi
	mov [esi+pf_anode.opennext], ebp

	popa
	ret

// in:		ebp=node
remNodeOpen:
	pusha
	mov edi, pfOpenList-pf_anode.opennext	// let edi point so [edi+pf_anode.opennext] = [pfOpenList]
.removesearchnext:
	mov esi, edi
	mov edi, [esi+pf_anode.opennext]
	cmp edi, 0
	je .listend

	cmp edi, ebp
	jne .removesearchnext
	mov edi, [edi+pf_anode.opennext]
	mov [esi+pf_anode.opennext], edi
.listend:
	popa
	ret

// in:		eax=key
// out:		ebp=node or 0
isNodeInOpen:
	mov ebp, 0 
	push edi
	mov edi, pfOpenList-pf_anode.opennext	// let edi point so [edi+pf_anode.opennext] = [pfOpenList]

.next:
	mov edi, [edi+pf_anode.opennext]
	cmp edi, 0
	je .none
	cmp [edi+pf_anode.key], eax
	jne .next
	mov ebp, edi
.none:
	pop edi
	ret

// in:		eax=key
// out:		ebp=node or 0
isNodeInClosed:
	mov ebp, 0 
	push edi
	mov edi, pfClosedList-pf_anode.closednext 	// let edi point so [edi+pf_anode.closednext] = [pfClosedList]

.next:
	mov edi, [edi+pf_anode.closednext]
	cmp edi, 0
	je .none
	cmp [edi+pf_anode.key], eax
	jne .next
	mov ebp, edi
.none:
	pop edi
	ret


// in:		ebp = new node
pfAddNewNode:
	mov esi, ebp
	call pfCalc

	// should check now if it's dest, so call TTDs stepfn function
	pusha
	mov di, [ebp+pf_anode.xy]

	// todo: set sTraceRouteState.distance,
	// sTraceRouteState.lastrt and co
	call [pfttdstepfn]
	popa
	jnb .nottdroutefound

	cmp dword [pfBestNode], 0
	je .nooldbestnode
	mov eax, [pfBestNode]
	mov eax, [eax+pf_anode.estimate]
	cmp [esi+pf_anode.estimate], eax
	jnb .nottdroutefound	// new one isn't better
.nooldbestnode:
	mov [pfBestNode], esi

.nottdroutefound:

	mov eax, [esi+pf_anode.key]
	call isNodeInOpen
	cmp ebp, 0
	je .notinopen
	// esi = new one, ebp old one
	mov ecx, [esi+pf_anode.estimate]

	// if ecx < ebp
	cmp ecx, [ebp+pf_anode.estimate]
	jb .newonebetterthanopen
	// don't need to do something
	ret
.newonebetterthanopen:
	call remNodeOpen
	mov ebp, esi
	call addNodeOpen
	ret

.notinopen:
	mov eax, [esi+pf_anode.key]
	call isNodeInClosed
	cmp ebp, 0
	je .notinclose
#if DEBUG
	mov ecx, [esi+pf_anode.estimate]
	cmp ecx, [ebp+pf_anode.estimate]
	jb .newnodeisbetter
	ret
.newnodeisbetter:
	// the output of costs is to small or the output of estimate is to large.
	CALLINT3
#endif
	ret

.notinclose:
	mov ebp, esi
	call addNodeOpen
	ret




// in:		ebp = node
pfCalc:
	pusha
	// should calc moveing cost and estimate
	mov esi, [ebp+pf_anode.parent]

	// cost to move
	mov eax, 10
	add eax, dword [esi+pf_anode.cost]
	mov dword [edi+pf_anode.cost], eax
	

	// estimate cost to target (manhatten)

	mov eax, 1
	cmp byte [pfXYNoDest], 0
	je .nodest

	mov dx, word [pfXYDest]
	xor eax, eax
	mov ax, [ebp+pf_anode.xy]

	sub al,dl
	jnc .x
	neg al
.x:
	sub ah,dh
	jnc .y
	neg ah
.y:
	add al,ah
	mov ah,0
	adc ah,ah
	and eax, 0xFFFF

.nodest:
	add eax, dword [edi+pf_anode.cost]
	mov dword [edi+pf_anode.estimate], eax
	popa
	ret
	
	
pfFollowTrack:
	// handle tunnels?
	push esi
	mov ax, si
	call [getroutemap]	// in EDI=XY, AX=0/2/4 for rail/road/water; out EAX=bitcoded
	pop esi
	

	// in:	ax = new route bits
	//		bx = current route tracks
	// add for each possible route bit a new child
.nextone:
	bsf dx, ax
	jz short .done
	btr ax, dx
	xor ecx, ecx
	bts cx, dx
	mov ch, cl
	mov cl, dl
	test byte [pfTraceDirRoutesHigh+ebx], ch
	jz .nothigh
	or cl, 8
.nothigh:
	call pfAddChild
	jc .done	// no more room...
	jmp .nextone
.done:
	ret

	
//	in:		edi = tilexy
//	 		cl =  piece bit number (e.g. 5)
//			ch =  piece (e.g. 20h)
//			ebp = current node
//	out:	carry flag set if no more room
pfAddChild:
	push ebp
	call pfCreateNewNode
	jc .nomorespace

	call pfAddNewNode
	clc
.nomorespace:
	pop ebp
	ret

//	in:		edi = tilexy
//			ebp = parent node
//			cl =  piece bit number 
//	out:		ebp = newnode
//			carry flag set if no more room, ebp not useable
pfCreateNewNode:
	push esi
	push eax
	mov esi, ebp
	mov ebp, dword [pf_lastnodeptr]
	add dword [pf_lastnodeptr], pf_anode_size	
// Important, add error if out of space!
	mov eax, dword [pf_lastnodeptr]
	cmp eax, dword [pf_lastnodeendptr]
	jb .ok
	pop eax
	pop esi
	stc
	ret
.ok:
	mov word [ebp+pf_anode], di
	mov dword [ebp+pf_anode.parent], esi
	mov word [ebp+pf_anode.xy], di
	xor eax, eax
	mov ax, di
	shl eax, 8
	mov al, cl
	mov dword [ebp+pf_anode.key], eax
	pop eax
	pop esi
	clc
	ret

// in:	si=flags, 
//		eax=posttracefn if bit E set
//		edx=stepfn
//	    di=start tile
//		bx=dir of first step (0=N, 1=NE, 2=E, 3=SE, 4=S, 5=SW, 6=W, 7=NW)
// stepfn:
// in:	di=tilexy
//		cl=??direction (0..15)??
// out:	carry flag set to stop tracing this route

exported DoTraceRouteNew
	
	ret

