
// Fix handling of RV speeds > 127 km/h
// and make RV's have "realistic" power and acceleration

#include <std.inc>
#include <flags.inc>
#include <window.inc>
#include <veh.inc>
#include <vehtype.inc>
#include <misc.inc>
#include <newvehdata.inc>

extern cargounitweightsptr,getrefitmask,postredrawhandle
extern rvwindowrefit,newvehdata





var rvpowerinit
//	db 20,30,40,67,20,35,62		// 7 busses
	db  9,12,15,25, 9,15,25		// 7 busses
//	db 22,42,75			// will be the 27 sets of three trucks
	db 12,22,45			// will be the 27 sets of three trucks
	db 0x80

var rvweightinit
	db 42,60,70,100,42,60,90	// 7 busses
	db 38,48,69			// 27 sets of three trucks
	db 0



// adjust road vehicle position in smaller steps but many of them
// to get more precision
global dorvmovement
dorvmovement:
	mov byte [.numcycle],1 << maxrvspeedshift

	// Changed here as it wouldn't be effient to do it for every loop
extern patchflags
testmultiflags articulatedrvs
	jnz .nextcycleartic
	
.nextcycle:
	test byte [esi+veh.vehstatus],2
	jnz .done

	call .calloriginal

	dec byte [.numcycle]
	jnz .nextcycle
.done:
	ret

// Basically the same as above but does the extra artic steps
.nextcycleartic:
	test byte [esi+veh.vehstatus],2
	jnz .done
	
	push ebp	// Find and get our movement for this 'slot'
	push edx
	mov ebp, 0
extern updateTrailerPosAfterRVProc.clock
	call updateTrailerPosAfterRVProc.clock
	mov dword [.ebp], ebp
	mov byte [.dl], dl
	pop edx
	pop ebp

	call .calloriginal

	push ebp	// Now move the trailers based off the results from above
	push edx
	mov ebp, dword [.ebp]
	mov dl, byte [.dl]
extern updateTrailerPosAfterRVProc.trailers
	call updateTrailerPosAfterRVProc.trailers
	pop edx
	pop ebp

	dec byte [.numcycle]
	jnz .nextcycleartic
	ret

// This needs to be assesable to both the normal and artic variants
.calloriginal:
	mov ax,[esi+veh.currorder]
	and al,0x1f
	cmp al,4
	call $+5
ovar advanceroadvehicle,-4
	ret

.numcycle: db 0

// Used to store the trailers key information
// (required otherwise it'll crash when any rv enters a depot)
.ebp: dd 0
.dl: db 0

; endp dorvmovement


// calculate road vehicle weight and power
//
// in:	esi=vehicle
// out:	eax=power in 10hp
//	ebx=loaded weight in 1/16 tons
//	edx=empty weight in 1/16 tons
//
// for ...andpower2:
// in:	eax=current load
//	ebx=cargo type
//	edx=engine id
// out:	same
//
getrvweightandpower:
	movzx eax,word [esi+veh.currentload]
	movzx ebx,byte [esi+veh.cargotype]
	movzx edx,word [esi+veh.vehtype]

getrvweightandpower2:
	add ebx,[cargounitweightsptr]
	movzx ebx,byte [ebx]

	// now ebx=weight factor

	imul ebx,eax

	// now ebx=weight of cargo

	movzx eax,byte [rvpowers+edx-ROADVEHBASE]
	movzx edx,byte [rvweight+edx-ROADVEHBASE]

	// now eax=power, ebx=weight of cargo, edx=weight of vehicle/4

	shl edx,2
	add ebx,edx
	ret
; endp getrvweightandpower

// stores the weight and power in veh2 and veh struct
// uses eax,ebx
global setrvweightandpower
setrvweightandpower:
	push edx
	call getrvweightandpower
	// now eax=power in 10hp, ebx=total weight in 1/16 tons

	mov edx,[esi+veh.veh2ptr]
	mov [edx+veh2.realpower],eax
	imul eax,10		// power was in 10hp
	mov [edx+veh2.power],ax

	movzx eax,byte [esi+veh.vehtype]
	mov al,[rvtecoeff+eax-ROADVEHBASE]
	imul eax,10		// gravity
	imul eax,ebx
	shr eax,8+4		// weight was in 1/16 tons
	mov [edx+veh2.te],ax

	shr ebx,4
	mov edx,[esi+veh.veh2ptr]
	mov [edx+veh2.fullweight],bx
	pop edx
	ret



// show weight and power in the vehicle info window
//
// in:	ax=speed (must be stored)
//	esi=vehicle
// out:	-
// safe:ebx edi
//
global showrvweight
showrvweight:
	mov edi,textrefstack
	mov [edi+7],ax
	mov word [edi+5],0x900e

	push edx
	call getrvweightandpower

	// now eax=power in 10hp, ebx=weight in 1/16 tons

	mov [edi+3],al

	xchg eax,ebx
	mov bl,10

	imul ebx	// rest of ebx was zero, edx is now zero
	shr eax,4
	adc eax,edx	// to round up .5 and above

	div ebx
	mov [edi],ax
	mov [edi+2],dl
	pop edx

	mov al,[edi+3]
	mul bl
	mov [edi+3],ax
	ret
; showrvweight endp

// similar as above but for purchase window
//
// in:	ah=max. reliability
//	ebx=vehicle type*engine_size
// out:	-
// safe:eax edi
//
global showrvweightpurchase
showrvweightpurchase:
	push ebx
	mov edi,textrefstack

	// make space for the new window params
	//      CostSpd RCstPow Wght Capa Desi Life Reli
	// Old: +0  +4  +6  ..  ..   +10  +14  +16  +18  (total 19)
	// New: +0  +4  +6  +10 +12  +14  +18  +20  +22  (total 23)
	// Move:                     +4

	mov [edi+22],ah

	mov eax,[edi+14]
	mov [edi+18],eax

	mov eax,[edi+10]
	mov [edi+14],eax

	push edx

	// divide ebx by engine_size
	xchg eax,ebx
	mov bl,vehtype_size
	div bl
	xchg eax,edx

	movzx eax,byte [rvhspeed+edx-ROADVEHBASE]
	test eax,eax
	jz .keepregularspeed

	// must do eax*4 * 10 shr 5
	lea eax,[eax+eax*4]
	shr eax,2
	mov [edi+4],ax

.keepregularspeed:
	movzx eax,word [edi+18]
	movzx ebx,byte [edi+16]
	sub ebx,0x6f

	call getrvweightandpower2

	// now eax=power in 10hp, ebx=loaded weight in 1/16 tons,
	//     edx=empty weight in 1/16 tons

#if 1
	xchg eax,edx

	mov ebx,10
	imul eax,ebx

	shr eax,4
	adc eax,0	// to round up .5 and above

	div bl
	mov [edi+12],ax

	imul edx,ebx

	mov [edi+10],dx

#else
	// to show loaded weight too
	// currently there aren't enough bytes available in the
	// text params, but maybe I'll just show whole tons, no decimals
	push ebx
	mov ebx,10

	imul eax,ebx
	mov [edi+10],eax

	pop eax
	imul eax,ebx

	shr eax,4
	adc eax,0	// to round up .5 and above

	div bl
	shl eax,16

	mov ax,dx
	imul ax,bx
	shr ax,4
	div bl

	mov [edi+12],eax
#endif

	pop edx
	pop ebx
	ret
; showrvweightpurchase endp


// called when showing new road vehicle announcement
//
// in:	ax=regular speed in mph*3.2
//	ebx=vehtype
// out:	ax in mph (*10/32)
// safe:esi
global rvnewvehinfo
rvnewvehinfo:
	movzx esi,byte [rvhspeed+ebx-ROADVEHBASE]
	test esi,esi
	jz .keepregularspeed

	shl esi,2
	xchg eax,esi

.keepregularspeed:

	// must do eax * 10 shr 5
	lea eax,[eax+eax*4]
	shr eax,4
	ret




// called when setting the max speed of a new road vehicle
// in:	 ax=regular top speed
//	ebx=vehicle type
//	esi=vehicle
global setrvspeed
setrvspeed:
	cmp byte [rvhspeed+ebx-ROADVEHBASE],0
	je .keepregularspeed

	movzx eax,byte [rvhspeed+ebx-ROADVEHBASE]
	shl eax,2

.keepregularspeed:
	mov [esi+veh.maxspeed],ax
	mov [esi+veh.vehtype],bx
	ret


// called when opening a rv window
//
// in:	esi=window ptr
//	eax=vehicle ptr
//	dx=vehicle index
// out: set [edi+0x24]
// safe:ebx
global creatervwindow
creatervwindow:
	mov bl,[eax+veh.class]
	shl ebx,16
	mov bl,[eax+veh.vehtype]
	push ebx
	call getrefitmask
	pop ebx
	test ebx,ebx

	mov ebx,0
ovar normalrvwindowptr,-4
	je .norefit

	cmp byte [eax+veh.movementstat],0xfe
	jne .norefit

	test byte [eax+veh.vehstatus],2
	jz .norefit

	mov ebx,rvwindowrefit

.norefit:
	xchg ebx,[esi+window.elemlistptr]
	ret

	// called when redrawing a rv window
	// also check whether we have to reset the refit/reverse button
	//
	// in:	esi->window struc
	// out:	edi->vehicle
	// safe:eax ebx ecx edx
global rvwindowfunc
rvwindowfunc:
	movzx edi,word [esi+window.id]
	shl edi,7
	add edi,[veharrayptr]
	mov eax,edi
	call creatervwindow

	test byte [esi+window.flags+1], 1<<(11-8)
	jnz .haveelemcopy

	cmp ebx,[esi+window.elemlistptr]
	je .noredrawnecessary

.doredraw:
	// button has changed, redraw it
	mov al,[esi+window.type]
	or al,0x80
	mov ah,7	// refit/reverse button
	mov bx,[esi+window.id]
	jmp postredrawhandle	// can't use invalidatehandle in window func

.haveelemcopy:
	mov eax,ebx				// eax is copied ptr. "Type" at eax+5Eh
	xchg ebx,[esi+window.elemlistptr]	// ebx is compiled-in data, restore copied ptr.
	mov bx, [ebx+5Eh]			// bx is window's new type
	xchg bx, [eax+5Eh]
	cmp bx, [eax+5Eh]
	jne .doredraw

.noredrawnecessary:
	ret


// called when rv reverse button is clicked
//
// in:	edx=vehicle
// out:	carry if really refitting
//	NZ if can't reverse
// safe:?
global rvreverse
rvreverse:
	push esi
	movzx esi,word [edx+veh.vehtype]
	movzx esi,byte [edx+veh.class]
	shl esi,16
	mov si,[edx+veh.vehtype]
	push esi
	call getrefitmask
	pop esi
	test esi,esi
	pop esi
	je .norefit

	cmp byte [edx+veh.movementstat],0xfe
	jne .norefit

	test byte [edx+veh.vehstatus],2
	jnz .isrefit

.norefit:
	// regular reverse button
	test byte [edx+veh.vehstatus],3
	jnz .fail

	cmp word [edx+0x68],0
	// carry is clear now
.fail:
	ret

.isrefit:
	test bl,1
	jz .checkonly	// check only, or shift-click

	// open refit window
	pusha
	mov dx,[edx+veh.idx]
	call $+5
ovar callrefitship, -4
	popa

.checkonly:
	stc
	ret

// called when checking whether ship/rv can be refitted
//
// in:	edx=vehicle
//	 bp=landscape index
// out:  al=landscape5(bp)
//	carry if road vehicle refit ok
//	nz if ship vehicle refit not ok
global checkindock
checkindock:
	and al,0xf0
	cmp al,0x20
	je .road

	cmp al,0x60
	jne .gotit

	mov al,[landscape5(bp)]
	and al,0xfd
	cmp al,0x80
.gotit:
	clc
	ret

.road:
	mov al,[landscape5(bp)]
	and al,0xfc
	cmp al,0x20
	jne .gotit

	test byte [edx+veh.vehstatus],2
	jz .gotit	// will fail later after returning

	cmp byte [edx+veh.movementstat],0xfe
	jnz .gotit

	// ok, we can refit
	stc
	ret


// called after a road vehicle has changed is load
//
// in:	esi->vehicle
// out:
// safe:eax ebx edx edi ebp
global refreshrv
refreshrv:
	call setrvweightandpower	// uses eax,ebx,edx
	// replaced code
	mov ax,[esi+veh.box_coord+0]
	mov bx,[esi+veh.box_coord+4]
	ret


// called after setting up the veh struct of a new road vehicle
//
// in:	esi->vehicle
// out:
// safe:eax ebx ecx edx ebp
global setupnewrv
setupnewrv:
	call setrvweightandpower
	mov word [esi+veh.cursprite],3093	// replaced code
	ret
