// sort vehicle lists
// The vehicle list windows will have two additional values:
// [esi+0x31]: number of sorting method
// [esi+0x32]: time until next reordering (in 7-tick units)

// [esi+0x33,2F]: used to provide more than 256 train support

#include <std.inc>
#include <textdef.inc>
#include <patchdata.inc>
#include <window.inc>
#include <veh.inc>
#include <misc.inc>
#include <station.inc>

extern FindWindow,GenerateDropDownMenu,invalidatehandle,sortfrequency

extern addr


// Called in a loop to count all vehicles to go in the train list
// We sort the vehicles here
global findlisttrains
findlisttrains:
	cmp al,[edi+veh.owner]	// overwritten
	jne .notours		// by the
	inc ebx			// runindex call
	cmp byte [esi+0x32],0
	jne .nosort
	xchg eax,ebx
	call sortloop	
	xchg eax,ebx
.notours:
	ret

.nosort:
// if a vehicle without sorting information is present (new vehicles),
// we must force a reorder
	push edi
	mov edi,[edi+veh.veh2ptr]
	cmp dword [edi+veh2.sortvar],0
	pop edi
	jne .ok

	mov byte [esi+0x32],0		// force sorting
	xor ebx,ebx			// reset vehicle count
	mov edi,[veharrayptr]		// force the loop to start over again
	add edi,-vehiclesize
.ok:
	ret

// the same for any other vehicle type (increase ax instead of ah)
global findlistvehs
findlistvehs:
	cmp bl,[edi+veh.owner]	// overwritten
	jne .notours		// by the
	inc ax			// runindex call
	cmp byte [esi+0x32],0
	jne .nosort
	call sortloop
.notours:
	ret

.nosort:
	push edi
	mov edi,[edi+veh.veh2ptr]
	cmp dword [edi+veh2.sortvar],0
	pop edi
	jne .ok

	mov byte [esi+0x32],0
	xor ax,ax
	mov edi,[veharrayptr]
	add edi,byte -vehiclesize
.ok:
	ret

// called after findlistvehs and loading the next vehicle in the veh.array to edi
// if the loop has ended, put the initial timer value back
global findlistvehs_next
findlistvehs_next:
	cmp edi,[veharrayendptr]	// overwritten
	jb .exit			// loop hasn't ended yet
	cmp byte [esi+0x32],0
	jne .exit			// there was no sorting at all
	push eax
	mov al,[sortfrequency]
	mov byte [esi+0x32],al
	pop eax
.exit:
	ret

// Do a loop from the actual sorting. We don't sort the vehicle entries themselves
// (this would confuse TTD), but put a pointer in the sortvar of every listed vehicle.
// TTD finds vehicles in the old way (in the order they are stored), but we make it
// to use the pointer instead the vehicle it found.
// In:	bl: owner
//	edi: vehicle to be inserted
// Usage of registers inside the procedure:
// eax: address of sorting method
// ebx: slot where the new element should be inserted
// ecx: can be freely used by sort functions
// edx: previous slot that is visible in the list
// esi: new element to be inserted
// edi: loops through slots backwards
// ebp: vehicle that should be compared against the new one
sortloop:
	pusha
	movzx eax,byte [esi+0x31]	// get sorting method
	mov eax,[sortfuncs+eax*4]	// get the address of the comparing method
	mov ebx,edi
	mov edx,edi
	mov esi,edi

.loop:
	add edi,0-vehiclesize
	cmp edi,[veharrayptr]
	jb .done
	movzx ecx,byte [esi+veh.class]
	call dword [wantvehicle+(ecx-0x10)*4]
	jnz .loop
	mov cl,[esi+veh.owner]
	cmp cl,[edi+veh.owner]
	jne .loop
	mov ebp,[edi+veh.veh2ptr]
	mov ebp,[ebp+veh2.sortvar]
	call eax
	jnc .done
	mov edx,[edx+veh.veh2ptr]
	mov [edx+veh2.sortvar],ebp
	mov edx,edi
	mov ebx,edi
	jmp short .loop

.done:
	mov ebx,[ebx+veh.veh2ptr]
	mov [ebx+veh2.sortvar],esi
	popa
	ret

// compare functions for the vehicle list sorting
// all of them are called for every listed vehicle.
// in:	ebp, esi -> vehicles to check
// out:	cf set if the vehicle in esi is "better"
// A vehicle is "better" if it should appear before the other
// vehicle in the list.
// ecx can be used for temporary storage (it isn't reset between calls).

var sortfuncs
	dd addr(sort_nosort)
	dd addr(sort_consistnum)
	dd addr(sort_profit)
	dd addr(sort_lastprofit)
	dd addr(sort_age)
	dd addr(sort_maxspeed)
	dd addr(sort_reliability)
	dd addr(sort_cargo)
	dd sort_destination

%ifndef PREPROCESSONLY
%assign SORTCOUNT (addr($)-sortfuncs)/4
%endif


sort_nosort:
	clc
	ret

sort_consistnum:
	mov cl,[esi+veh.consistnum]
	cmp cl,[ebp+veh.consistnum]
	ret

sort_profit:
	mov ecx,[esi+veh.profit]
	cmp ecx,[ebp+veh.profit]
	jl .lower
	clc
	ret

.lower:
	stc
	ret

sort_lastprofit:
	mov ecx,[esi+veh.previousprofit]
	cmp ecx,[ebp+veh.previousprofit]
	jl .lower
	clc
	ret

.lower:
	stc
	ret

sort_age:
	mov cx,[esi+veh.age]
	cmp cx,[ebp+veh.age]
	ret

sort_maxspeed:
	mov cx,[esi+veh.maxspeed]
	cmp cx,[ebp+veh.maxspeed]
	ret

sort_reliability:
	mov cx,[esi+veh.reliability]
	cmp cx,[ebp+veh.reliability]
	ret

sort_cargo:
	push esi
	call get_cargo_types
	pop ecx
	push ebp
	call get_cargo_types
	cmp cx,[esp]
	pop ecx
	ret

sort_destination:
	push eax
	call getdestination
	mov ecx,eax
	push esi
	mov esi,ebp
	call getdestination
	pop esi
	cmp ecx,eax
	pop eax
	ret


uvard tempcargocount,9
%define tempcargo1 tempcargocount+32
%define tempnumcargo1 tempcargocount+33
%define tempcargo2 tempcargocount+34
%define tempnumcargo2 tempcargocount+35

get_cargo_types:
	push eax
	push edi

	xor eax,eax
	mov edi,tempcargocount
	times 9 stosd		// clear tempcargocount

	dec byte [tempcargo1]	// set "no cargo at all" => end of list
	mov edi,[esp+12]

.nextveh:
	cmp word [edi+veh.capacity],0
	je .getnextveh

	movzx eax,byte [edi+veh.cargotype]
	inc byte [tempcargocount+eax]
	mov ah,[tempcargocount+eax]
	cmp al,[tempcargo1]
	je .updcargo1

	cmp ah,[tempnumcargo1]
	jb .notcargo1
	ja .newcargo1
	// equal: sort by type
	cmp al,[tempcargo1]
	jnb .notcargo1

.newcargo1:
	xchg ax,[tempcargo1]
	mov [tempcargo2],ax
	jmp .getnextveh

.updcargo1:
	mov [tempnumcargo1],ah
	jmp .getnextveh

.notcargo1:
	cmp ah,[tempnumcargo2]
	jb .getnextveh
	ja .newcargo2
	cmp al,[tempcargo2]
	jnb .getnextveh

.newcargo2:
	mov [tempcargo2],ax

.getnextveh:
	movzx edi,word [edi+veh.nextunitidx]
	cmp di,-1
	je .done
	shl edi, vehicleshift
	add edi,[veharrayptr]
	jmp .nextveh
.done:
	mov ah,[tempcargo1]
	mov al,[tempcargo2]
	cmp al,0xff
	cmc
	adc al,0		// change ff to 0 (consists with only one cargo type at top)
	mov [esp+12],ax
	pop edi
	pop eax
	ret

getdestination:
	push ebx
	cmp byte [esi+veh.totalorders],1
	jbe .noorders
	mov eax,[esi+veh.scheduleptr]
	mov ebx,[eax]
	and bl,0x1f
	jz .noorders
	cmp bl,2
	movzx ebx,bh
	jb .station
	ja .noorders
.depot:
	add ebx,ebx
	lea eax,[depotarray+ebx*3]
	jmp short .getxy

.station:
	imul eax,ebx,station_size
	add eax,[stationarrayptr]

.getxy:
	// get XY of first destination, and calculate (X+Y)*100h+X-Y
	movzx eax,word [eax]
	mov bl,al
	sub bl,ah
	sbb bh,bh
	movsx ebx,bx	// ebx=X-Y
	add al,ah
	mov ah,0
	adc ah,ah
	shl eax,8	// eax=(X+Y)*100h
	add eax,ebx
	pop ebx
	ret

.noorders:
	or eax,byte -1
	pop ebx
	ret



// Functions to decide whether a vehicle entry is valid for the list
// The owner will be checked later
// in:	edi -> vehicle to check
// out:	zf set if valid

var wantvehicle
	dd addr(realtrain)
	dd addr(realrv)
	dd addr(realship)
	dd addr(realaircraft)

global realtrain
realtrain:
	cmp byte [edi+veh.class],0x10
	jne .exit
	cmp byte [edi+veh.subclass],0
.exit:
	ret

realrv:
	cmp byte [edi+veh.class],0x11
	ret

realship:
	cmp byte [edi+veh.class],0x12
	ret

realaircraft:
	cmp byte [edi+veh.class],0x13
	jne .exit
	cmp byte [edi+veh.subclass],0
	je .exit
	cmp byte [edi+veh.subclass],2
.exit:
	ret

// Called when clicking on a vehicle list window
// Detect pressing our new ordering buttons, and prevent
// pressing the "New vehicles" button if it's disabled.
// in:	cx: number of element clicked on
//	esi -> window
//	sf set if not valid click
// out: exit the caller function if there's no valid click
// safe: eax,???
global clicklistwindow
clicklistwindow:
	js .exitparent
	bt word [esi+window.disabledbuttons],cx	// don't allow pushing disabled buttons
	jc .exitparent
	cmp cl,5
	je .ourbutton
	cmp cl,6
	je .ourbutton
.exit:
	ret

.ourbutton:
	mov cl,6		// pretend pressing button 6 for button 5 as well
	xor eax,eax		// fill the menu with the options
	mov bx,ourtext(nosort)
.loop:
	mov [tempvar+2*eax],bx
	inc bx
	inc eax
	cmp eax,SORTCOUNT
	jb .loop

	mov word [tempvar+2*eax],-1	// terminate it
	xor ebx,ebx			// nothing is disabled
	movzx dx,[esi+0x31]		// current selection
	jmp dword [GenerateDropDownMenu]	// show it

.exitparent:
	pop eax
	ret

// Called when the GUI timer of a veh. list window reaches zero.
// Old TTD code releases the "New vehicles" button here.
// We decrease the sorting timer here.
// Also detect selecting a dropdown menu entry here since the old handler
// doesn't react to this.
// in:	esi -> window
//	dl: window message
//	flags from cmp dl,5
global listguitimer
listguitimer:
	jnz .notguitick
	or byte [esi+window.flags],7	// restart GUI timer from the highest value available
	cmp byte [esi+0x32],0	// a forced reordering (the redrawing should be already
	je .notimeout		// requested), or a timing setting of 0 (the window
				// is always reordered on redrawing, s don't force it)
	dec byte [esi+0x32]	// decrease our timer
	jnz .notimeout
	mov al,[esi+window.type]		// redraw the whole window (veh. order should be changed)
	mov bx,[esi+window.id]
	call [invalidatehandle]
.notimeout:
	btr dword [esi+window.activebuttons],4	// overwritten
	jc .normalexit
.exitparent:
	pop eax
.normalexit:
	ret

.notguitick:
	cmp dl,0x10		// is it a menu selection?
	jne .exitparent

	mov [esi+0x31],al	// store the selected method
	mov [landscape3+ttdpatchdata.lastsort],al	// and store it in the savegame
	mov byte [esi+0x32],0	// force re-ordering
	mov al,[esi+window.type]		// redraw the whole window (veh. order has also changed)
	mov bx,[esi+window.id]
	pop edx
	jmp dword [invalidatehandle]

// Called when filling textrefstack for a vehicle list window
// Put the sorting method text here so our new button can
// display it.
// in:	esi -> vehicle
global setvehlisttext
setvehlisttext:
	mov [textrefstack],ax	// overwritten
	movzx ax,[esi+0x31]
	add ax,ourtext(nosort)
	mov [textrefstack+6],ax
	ret

// Called whe creating a vehicle list window.
// Apply the last selected sorting method, force reordering and
// disable the "New vehicles" button if necessary.
// in:	esi -> window
// The initialization here that is specific to sortvehlist is
// safe/harmless when that switch is off:
// -- The GUI timer goes off once, and has no handler, so expires
// -- The sort is stored, but the sort functions are never called
global createlistwindow
createlistwindow:
	mov [esi+window.id],dx		// overwritten
	mov [esi+window.company],dl	// ditto
	cmp dl,[human1]
	je .nodisable
	or byte [esi+window.disabledbuttons],0x10
.nodisable:
	push edx
	mov dl,[landscape3+ttdpatchdata.lastsort]
	cmp dl,SORTCOUNT
	jb .correct
	xor dl,dl
.correct:
	mov al, [esi+window.itemsvisible]
	mov BYTE [esi+0x2F], al	// for default size only
	mov [esi+0x31],dl
	mov WORD [esi+0x32],0	// the first reordering will be a forced one, clear shift factor
	or byte [esi+window.flags],7	// start the GUI timer
	pop edx
	ret

// A part of the old code replicated here, so we can do other things in
// the codefragment (pushing edi in a procedure would be hard...)
global vehiclevalid
vehiclevalid:
	movzx eax,al
	call dword [wantvehicle+(eax-0x10)*4]
	jnz .exit
	mov ax,[esi+window.id]
	cmp al,[edi+veh.owner]
	jnz .exit
	mov edi,[edi+veh.veh2ptr]
	mov edi,[edi+veh2.sortvar]
.exit:
	ret

// The same when clicking on an entry
global clicklist_next
clicklist_next:
	call dword [wantvehicle+(edx-0x10)*4]
	jnz .exit
	cmp ah,[edi+veh.owner]
	jnz .exit
	sub al,1
	jnc .exit
	mov edi,[edi+veh.veh2ptr]
	mov edi,[edi+veh2.sortvar]	// this is the only part that isn't present in the old code
					// after finding the correct vehicle entry, use its pointer
					// instead of the vehicle itself
	stc
	ret
.exit:
	clc
	ret
	
// The same when clicking on an entry, for trains only, modified for more than 256 trains in window by JGR
global clicklist_next_train
clicklist_next_train:
	call dword [wantvehicle]
.in:
	jnz .exit
	cmp ah,[edi+veh.owner]
	jnz .exit
	sub edx,1
	jnc .exit
	mov edi,[edi+veh.veh2ptr]
	mov edi,[edi+veh2.sortvar]	// this is the only part that isn't present in the old code
					// after finding the correct vehicle entry, use its pointer
					// instead of the vehicle itself
	stc
	ret
.exit:
	clc
	ret

global clicklist_next_rv
clicklist_next_rv:
	push DWORD clicklist_next_train.in
	jmp DWORD [wantvehicle+4]
	
global clicklist_next_ship
clicklist_next_ship:
	push DWORD clicklist_next_train.in
	jmp DWORD [wantvehicle+8]
global clicklist_next_aircraft
clicklist_next_aircraft:
	push DWORD clicklist_next_train.in
	jmp DWORD [wantvehicle+12]

// called when a vehicle array entry is deleted
// force reordering the according veh. list window if visible
global delveharrayentry_sort
delveharrayentry_sort:
	pusha
	mov cl,[esi+veh.class]
	cmp cl,0x13		// no special objects
	ja .done
	sub cl,0x10-9		// get window class from vehicle class
	movzx dx,byte [esi+veh.owner]	// the ID is the owner
	call dword [FindWindow]
	jz .done
	mov byte [esi+0x32],0	// force reordering
	mov al,cl		// and redraw
	mov bx,dx
	call dword [invalidatehandle]
.done:
	popa
	mov ebx,1		// overwritten
	jmp dword [ebp+4]	// ditto

// called when preparing a new vehicle entry.
// class and owner aren't set yet, so we don't know which window we must reorder.
// We clear sortvar, though, and this can be detected by the ordering code.
global newveharrayentry_sort
newveharrayentry_sort:
	push esi
	mov esi,[esi+veh.veh2ptr]
	and dword [esi+veh2.sortvar],0
	pop esi
	mov word [esi+0x2a],0x8000	// overwritten
	ret

// called when right clicking on a vehicle list window
// The extra button doesn't have a hint, so pretend it's the previous button
global listwindowhint
listwindowhint:
	js .exitparent
	cmp cx,5
	jbe .ok
	mov cx,5
.ok:
	ret

.exitparent:
	pop ebx
	ret

//JGR more than 256 trains in list:

global TrainListDrawHandlerCountDec,TrainListDrawHandlerCountTrains,TrainListClickHandlerAddOffset,TrainListDrawHandlerCountDec.skip

TrainListDrawHandlerCountDec:

	dec DWORD [trainlistoffset]
	//cmp bl, 0
	jns .jmp

	.dec:
	dec bl
	jns .reinc
	ret
	.reinc:
	inc bl
	ret
	
	.jmp:
	xor bl, bl
	add esp, 4
	jmp near $
	ovar .skip, -4, $,TrainListDrawHandlerCountDec

uvard trainlistoffset
TrainListDrawHandlerCountTrains:
	xor edx, edx
	jmp .shrtest
.shr1:
	inc ebx
	shr ebx, 1
	inc edx
.shrtest:
	test ebx, 0xffffff00
	jnz .shr1

	mov [esi+window.itemstotal], bl
	mov dh, [esi+0x33]
	cmp dh, dl
	je .itemsoffset_good
	mov [esi+0x33], dl
	push ecx
	push ebx
	movzx ebx, BYTE [esi+window.itemsoffset]
	mov cl, dh
	shl ebx, cl
	mov cl, dl
	shr ebx, cl
	mov [esi+window.itemsoffset], bl
	movzx ebx, BYTE [esi+0x2F]
	shr ebx, cl
	mov [esi+window.itemsvisible], bl
	pop ebx
	pop ecx
	.itemsoffset_good:
	push ecx
	mov cl, dh
	mov ah, bl
	movzx ebx, BYTE [esi+window.itemsoffset]
	shl ebx, cl
	mov [trainlistoffset], ebx
	xor bl, bl
	sub ah, [esi+window.itemsvisible]
	pop ecx
ret

TrainListClickHandlerAddOffset:

	movzx edx, al
	movzx eax, BYTE [esi+window.itemsoffset]
	mov cl, [esi+0x33]
	shl eax, cl
	add edx, eax
	mov edi, [veharrayptr]
ret

//JGR more than 256 road vehicles in list

global RVListDrawHandlerCountDec,RVListDrawHandlerCountDec, RVListDrawHandlerCountVehs

RVListDrawHandlerCountDec:

	dec DWORD [trainlistoffset]
	//cmp bl, 0
	jns .jmp

	.dec:
	dec bl
	jns .reinc
	ret
	.reinc:
	inc bl
	ret
	
	.jmp:
	xor bl, bl
	add esp, 4
	jmp near $
	ovar .skip, -4, $,RVListDrawHandlerCountDec

RVListDrawHandlerCountVehs:
	movzx ebx, ax
	call TrainListDrawHandlerCountTrains
	//don't modify flags
	mov al, ah
	ret

//JGR more than 256 ships in list

global ShipListDrawHandlerCountDec,ShipListDrawHandlerCountDec.skip

ShipListDrawHandlerCountDec:

	dec DWORD [trainlistoffset]
	//cmp bl, 0
	jns .jmp

	.dec:
	dec bl
	jns .reinc
	ret
	.reinc:
	inc bl
	ret
	
	.jmp:
	xor bl, bl
	add esp, 4
	jmp near $
	ovar .skip, -4, $,ShipListDrawHandlerCountDec
	
global AircraftListDrawHandlerCountDec,AircraftListDrawHandlerCountDec.skip
AircraftListDrawHandlerCountDec:
	dec DWORD [trainlistoffset]
	//cmp bl, 0
	jns .jmp

	.dec:
	dec bl
	jns .reinc
	ret
	.reinc:
	inc bl
	ret
	
	.jmp:
	xor bl, bl
	add esp, 4
	jmp near $
	ovar .skip, -4, $,AircraftListDrawHandlerCountDec
