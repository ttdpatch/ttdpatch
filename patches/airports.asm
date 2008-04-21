#include <std.inc>
#include <airport.inc>
#include <textdef.inc>
#include <grf.inc>
#include <station.inc>
#include <veh.inc>
#include <window.inc>
#include <flags.inc>

// Support for new airports supplyed by GRFs

extern curgrfairportlist,curspriteblock
extern grffeature,curcallback,getnewsprite,callback_extrainfo
extern GenerateDropDownMenu,invalidatehandle,station2ofs_ptr
extern aircraftbboxtable,orgsetsprite, patchflags

uvard airportdataidtogameid, NUMAIRPORTS*2

struc airportgameid
	.grfid:		resd 1
	.setid:		resb 1
endstruc

uvard airportaction3, NUMAIRPORTS

uvarw airportsizes, NUMAIRPORTS

uvard airportlayoutptrs, NUMAIRPORTS

uvard airportmovementdataptrs, NUMAIRPORTS

uvarb airportmovementdatasizes, NUMAIRPORTS

uvarb airportspecialflags, NUMAIRPORTS

uvarb airportcallbackflags, NUMAIRPORTS

uvarw airporttypenames, NUMAIRPORTS

uvard airportmovementnodelistptrs, NUMAIRPORTS
uvarb airportmovementnodenums, NUMAIRPORTS

uvard airportmovementedgelistptrs, NUMAIRPORTS
uvarb airportmovementedgenums, NUMAIRPORTS

uvarb airportstarthangarnodes, NUMAIRPORTS

// how much airports "weigh" - i.e. how many of the allowed points they use up
varb airportweight
	db 2,3,1,0
	times NUMNEWAIRPORTS db 3
endvar

exported clearairportdataids
	pusha
	xor eax,eax
	mov edi,airportdataidtogameid+NUMOLDAIRPORTS*8
	mov ecx,NUMNEWAIRPORTS*2
	rep stosd
	popa
	ret

exported clearairportdata
	pusha
	xor eax,eax

	mov edi,airportsizes+NUMOLDAIRPORTS*2
	mov ecx,NUMNEWAIRPORTS
	rep stosw

	mov edi,airportlayoutptrs+NUMOLDAIRPORTS*4
	mov cl,NUMNEWAIRPORTS
	rep stosd

	mov edi,airportmovementdataptrs+NUMOLDAIRPORTS*4
	mov cl,NUMNEWAIRPORTS
	rep stosd

	xor eax,eax
	mov edi,airportmovementdatasizes+NUMOLDAIRPORTS
	mov cl,NUMNEWAIRPORTS
	rep stosb

	mov edi,airportspecialflags+NUMOLDAIRPORTS
	mov cl,NUMNEWAIRPORTS
	rep stosb

	mov edi,airportcallbackflags+NUMOLDAIRPORTS
	mov cl,NUMNEWAIRPORTS
	rep stosb

	mov edi,airportmovementnodelistptrs+NUMOLDAIRPORTS*4
	mov cl,NUMNEWAIRPORTS
	rep stosd

	mov edi,airportmovementnodenums+NUMOLDAIRPORTS
	mov cl,NUMNEWAIRPORTS
	rep stosb

	mov edi,airportmovementedgelistptrs+NUMOLDAIRPORTS*4
	mov cl,NUMNEWAIRPORTS
	rep stosd

	mov edi,airportmovementedgenums+NUMOLDAIRPORTS
	mov cl,NUMNEWAIRPORTS
	rep stosb

	mov edi,airporttypenames+NUMOLDAIRPORTS*2
	mov ax,ourtext(unnamedairporttype)
	mov cl,NUMNEWAIRPORTS
	rep stosw

	mov edi,airportstarthangarnodes+NUMOLDAIRPORTS
	mov al,-1
	mov cl,NUMNEWAIRPORTS
	rep stosb

	mov edi,airportweight+NUMOLDAIRPORTS
	mov al,3
	mov cl,NUMNEWAIRPORTS
	rep stosb

	mov byte [selectedairporttype], 0x0 // Reset the selected airport to stop errors
	popa
	ret

exported setairportlayout
.next:
	xor edx,edx
	mov dl,[curgrfairportlist+ebx]
	test dl,dl
	jnz .alreadyhasoffset

	mov eax,[curspriteblock]
	mov eax,[eax+spriteblock.grfid]
	mov edx,NUMOLDAIRPORTS
.nextslot:
	cmp dword [airportdataidtogameid+edx*8+airportgameid.grfid],0
	je .emptyslot
	cmp [airportdataidtogameid+edx*8+airportgameid.grfid],eax
	jne .wrongslot
	cmp [airportdataidtogameid+edx*8+airportgameid.setid],bl
	je .foundslot
.wrongslot:
	inc edx
	cmp edx,NUMAIRPORTS
	jb .nextslot

	mov ax,ourtext(invalidsprite)
	stc
	ret

.emptyslot:
	mov [airportdataidtogameid+edx*8+airportgameid.grfid],eax
	mov [airportdataidtogameid+edx*8+airportgameid.setid],bl

.foundslot:
	mov [curgrfairportlist+ebx],dl

.alreadyhasoffset:
	xor eax,eax
	lodsw
	mov [airportsizes+edx*2],ax
	mov [airportlayoutptrs+edx*4],esi
	mul ah
	add esi,eax

	mov eax,[airportmovementdataptrs+1*4]
	mov [airportmovementdataptrs+edx*4],eax
	mov byte [airportmovementdatasizes+edx],0x1d

	inc ebx
	dec ecx
	jnz .next

	clc
	ret

exported setairportmovementdata
	xor eax,eax
	lodsb
	mov [airportmovementnodenums+ebx],al
	mov [airportmovementnodelistptrs+ebx*4],esi
	imul eax, airportmovementnode_size
	add esi,eax

	lodsb
	mov [airportmovementedgenums+ebx],al
	mov [airportmovementedgelistptrs+ebx*4],esi
	imul eax, airportmovementedge_size
	add esi, eax

	clc
	ret

noglobal uvard currentaircraftptr

exported getaircraftvehdata
	mov ecx,[currentaircraftptr]
	test ecx,ecx
	jz .returnzero
	movzx eax,ah
	mov eax,[ecx+eax]
	ret

.returnzero:
	xor eax,eax
	ret

exported getaircraftdestination
	mov ecx,[currentaircraftptr]
	test ecx,ecx
	jz getaircraftvehdata.returnzero

	mov ax,[ecx+veh.currorder]
	and al,0x1f
	test al,al
	jz .gotit
	cmp al,2
	ja .gotit

	cmp ah,[ecx+veh.targetairport]
	je .gotit
	mov al,5
.gotit:
	movzx eax,al
	ret
	
svard aircraftmovement

exported getnewaircraftop
	mov ax,[esi+veh.currorder]
	and al,0x1F
	cmp al,3
	jae .exit

	movzx ebx,byte [esi+veh.targetairport]
	imul ebx,station_size
	add ebx,[stationarrayptr]

	movzx eax, byte [ebx+station.airporttype]
	cmp dword [airportmovementedgelistptrs+eax*4],1		// set cf iff the pointer is zero
	jb .exit

	cmp byte [esi+veh.movementstat],0xFF
	je .nomove
	cmp byte [esi+veh.aircraftnode],0xFF
	je .nomove

	mov edi,[esi+veh.veh2ptr]
	add edi, 0+veh2.curraircraftact

	cmp dword [edi],AIRCRAFTACT_UNKNOWN
	jne .goodaction

	call refreshaircraftaction

.goodaction:
	push ebx
	call [aircraftmovement]
	pop ebx
	jc .movedone

	movzx edi,word [esi+veh.nextunitidx]
	shl edi,vehicleshift
	add edi,[veharrayptr]

	mov ax,0x202
	cmp byte [esi+veh.xsize],0x10
	jae .shadow

	mov al,byte [esi+veh.direction]
	and eax,byte 3
	mov eax,[aircraftbboxtable+eax*2]
	mov [esi+veh.xsize],ax

.shadow:
	mov [edi+veh.xsize],ax
	clc
	ret

.nomove:
.movedone:
	call gotonextaircraftedge
	clc

.exit:
	ret

refreshaircraftaction:
	movzx edx,byte [esi+veh.aircraftnode]
	imul edx, airportmovementnode_size
	movzx ecx, byte [ebx+station.airporttype]
	add edx,[airportmovementnodelistptrs+ecx*4]

	mov eax,[edx+airportmovementnode.xpos]
	mov [edi],eax

	mov byte [edi+4],0
	test byte [edx+airportmovementnode.flags],AIRNODE_FORCEDIR
	jz .noforcedir

	or byte [edi+4],0x10
	mov al,[edx+airportmovementnode.flags]
	shr al,3
	and al,7
	mov [edi+5],al

.noforcedir:
	movzx edx, byte [esi+veh.movementstat]
	imul edx, airportmovementedge_size
	add edx, [airportmovementedgelistptrs+ecx*4]

	movzx eax, byte [edx+airportmovementedge.specaction]
	mov al, [.specorvals+eax]
	or [edi+4],al

	mov al, [edx+airportmovementedge.flags]
	test al,AIREDGE_NOTAXI
	jz .taxi
	or byte [edi+4],1
.taxi:
	test al,AIREDGE_NOSHARPTURN
	jz .sharpturns
	or byte [edi+4],4
.sharpturns:
	ret

noglobal varb .specorvals, 0, 0x40, 0x80, 8, 0x20, 0, 2

gotonextaircraftedge:
	movzx ebp,byte [ebx+station.airporttype]
	mov dl, [esi+veh.aircraftnode]

	mov ax, [esi+veh.currorder]
	mov dh,AIREDGE_NOTTOOTHERAIRPORT
	cmp ah, [esi+veh.targetairport]
	jne .gotdestination
	mov dh,AIREDGE_NOTTOTERMINAL
	and al,0x1f
	cmp al,1
	je .gotdestination
	mov dh,AIREDGE_NOTTOHANGAR
.gotdestination:

	cmp dl,0xff
	je .nohangar
	movzx eax, dl
	imul eax, airportmovementnode_size
	add eax, [airportmovementnodelistptrs+ebp*4]
	mov al, [eax+airportmovementnode.flags]

	test al,AIRNODE_TERMINAL
	jz .noterminal
	cmp dh,AIREDGE_NOTTOTERMINAL
	jne .noterminal

	call .refreshsprite
	jmp dword [airportspecialmovements+2*4]

.noterminal:
	test al,AIRNODE_HANGAR
	jz .nohangar
	cmp byte [esi+veh.aircraftop],0
	jne .enterhangar

	cmp dh, AIREDGE_NOTTOHANGAR
	jne .nohangar

	mov word [esi+veh.currorder],0
	ret

.enterhangar:
	movzx eax, byte [esi+veh.movementstat]
	cmp eax, 64
	jae .noresetbit_hangar
	btr [ebx+station2ofs+station2.airportbusyedges],eax

	mov byte [esi+veh.movementstat],0xFF
.noresetbit_hangar:
	mov edi,[esi+veh.veh2ptr]
	mov dword [edi+veh2.curraircraftact],AIRCRAFTACT_UNKNOWN
	mov byte [esi+veh.aircraftop],0
	jmp dword [airportspecialmovements+5*4]

.nohangar:

	mov al,AIREDGE_NOPLANES
	cmp byte [esi+veh.subclass],0
	jne .notheli
	mov al,AIREDGE_NOHELIS
.notheli:
	or dh,al

	add ebx,[station2ofs_ptr]
	mov cl,0
	mov ch,[airportmovementedgenums+ebp]
	mov edi,[airportmovementedgelistptrs+ebp*4]

.trynextedge:
	cmp dl, [edi+airportmovementedge.start]
	jne .notgood
	test [edi+airportmovementedge.flags],dh
	jnz .notgood
	mov eax,[ebx+station2.airportbusyedges]
	mov ebp,[ebx+station2.airportbusyedges+4]
	test [edi+airportmovementedge.and_mask],eax
	jnz .notgood
	test [edi+airportmovementedge.and_mask+4],ebp
	jnz .notgood
	cmp dword [edi+airportmovementedge.or_mask],0
	jne .haveormask
	cmp dword [edi+airportmovementedge.or_mask+4],0
	je .good
.haveormask:
	not eax
	not ebp
	test [edi+airportmovementedge.or_mask],eax
	jnz .good
	test [edi+airportmovementedge.or_mask+4],ebp
	jnz .good
.notgood:
	inc cl
	add edi,airportmovementedge_size
	dec ch
	jz .nonextstate
	jmp short .trynextedge

.nonextstate:
	ret

.good:
	cmp byte [esi+veh.aircraftop],0
	jne .noexithangar
	mov byte [esi+veh.aircraftop],3
	pusha
	call dword [airportspecialmovements+1*4]
	popa
.noexithangar:

	movzx eax, byte [esi+veh.movementstat]
	cmp eax, 64
	jae .noresetbit
	btr [ebx+station2.airportbusyedges],eax
.noresetbit:

	mov al,[edi+airportmovementedge.end]	
	mov [esi+veh.aircraftnode],al

	mov [esi+veh.movementstat],cl
	mov ch,cl
	dec ch
	mov [esi+veh.prevmovementstat],ch	// trick planebreakdownspeed in planemot.asm
						// to re-check speed

	cmp al,0xFF
	je .nosetbit
	movzx ecx,cl
	cmp ecx, 64
	jae .nosetbit
	bts [ebx+station2.airportbusyedges],ecx
.nosetbit:

	call .refreshsprite

	cmp al,0xFF
	jne .notyield
	jmp dword [airportspecialmovements+4*8]
.notyield:

	movzx eax, byte [edi+airportmovementedge.specaction]
	call dword [.speceffectfuncs+eax*4]

	mov edi,[esi+veh.veh2ptr]
	mov dword [edi+veh2.curraircraftact],AIRCRAFTACT_UNKNOWN

.nothing:
	ret

.refreshsprite:
	pusha
	mov eax,0x13
	movzx ebx,byte [esi+veh.direction]
	call [orgsetsprite+3*4]
	popa
	ret

noglobal vard .speceffectfuncs
	dd .nothing, .helitakeoff, .heliland, .nothing, .touchdown, .takeoffeffect, .takeoff
endvar

.helitakeoff:
.takeoff:
	mov byte [esi+veh.xsize],0x18
	mov byte [esi+veh.ysize],0x18
	mov byte [esi+veh.aircraftop],0x12
	ret

.heliland:
	mov byte [esi+veh.xsize],2
	mov byte [esi+veh.ysize],2
	mov byte [esi+veh.aircraftop],3
	ret

.touchdown:
	mov al, [esi+veh.movementstat]
	push eax
	call dword [airportspecialmovements+3*4]
	pop eax
	mov [esi+veh.movementstat],al
	mov byte [esi+veh.aircraftop],3
	ret

.takeoffeffect:
	jmp dword [airportspecialmovements+6*4]

vard airportspecialmovements
	dd recheckorder			// force re-checking of orders when coming out of hangar
	dd 0				// exit from hangar, become visible again and such
	dd 0				// start loading/unloading
	dd 0				// landing sound effect and chance of crashing
	dd shrinkaircraftextents	// make the notional box smaller
	dd 0				// enter hangar
	dd 0				// play take off sound effect
	dd growaircraftextents		// make the notional box larger
	dd 0				// yield control of aircraft to the next station
endvar

recheckorder:
	and word [esi+veh.currorder],0
	ret

shrinkaircraftextents:
	mov byte [esi+veh.xsize],2
	mov byte [esi+veh.ysize],2
	ret

growaircraftextents:
	mov byte [esi+veh.xsize],0x18
	mov byte [esi+veh.ysize],0x18
	ret

exported aircraftyield_newop
	movzx ebx, byte [esi+veh.targetairport]
	imul ebx,station_size
	add ebx,[stationarrayptr]

	movzx eax,byte [ebx+station.airporttype]
	cmp dword [airportmovementedgelistptrs+eax*4],0
	jnz .newairport

	mov ax,0x1212
	cmp byte [esi+veh.subclass],0
	jne .gotit
	mov al,0x14

.gotit:
	mov [esi+veh.movementstat],al
	mov [esi+veh.aircraftop],ah
	ret

.newairport:
	mov byte [esi+veh.movementstat],0xFF
	mov byte [esi+veh.aircraftnode],0xFF
	mov byte [esi+veh.aircraftop],0x12
	ret

noglobal uvarb menuairporttypes, 19

exported airportseltypeclick
	xor ebx,ebx
	xor ecx,ecx
	mov dx,-1
	xor ebp,ebp

.nexttype:

	cmp cl,[selectedairporttype]
	jne .notselected
	mov edx,ebp
.notselected:

	cmp cl,3
	je .skiptype
	cmp dword [airportlayoutptrs+ecx*4],0
	je .skiptype
	mov [menuairporttypes+ebp],cl
	mov ax,[airporttypenames+ecx*2]
	mov [tempvar+ebp*2],ax
	inc ebp

.skiptype:
	inc ecx
	cmp ebp,19
	je .full
	cmp ecx,NUMAIRPORTS
	jb .nexttype

.full:
	mov cl,4
	mov word [tempvar+ebp*2],-1
	mov al,[airporttypeavailmask]
	not al
	and al,7
	testmultiflags keepsmallairports
	jz .nokeepsmallairports
	and al, 0x6 // Small airport always avalible
.nokeepsmallairports:
	or bl,al
	jmp dword [GenerateDropDownMenu]

// Fix the problem of it not accounting for 'keepsmallairports'
global drawairportselwindow
drawairportselwindow:
	movzx eax, byte [selectedairporttype]
	cmp al, NUMOLDAIRPORTS
	jae .good
	bt [airporttypeavailmask],eax
	jc .good
	mov al,0
	testmultiflags keepsmallairports
	jnz .good
	test byte [airporttypeavailmask],1
	jnz .good_new
	mov al,1
.good_new:
	mov [selectedairporttype],al
.good:
	mov ax, [airporttypenames+eax*2]
	mov [textrefstack],ax
	mov ebx,[esi+window.activebuttons]
	and bl,0x3f
	ret

exported airportsel_eventhandler
	jz .click
	cmp dl, cWinEventDropDownItemSelect
	jz .dropdown
	ret

.click:
	sub dword [esp],0x32c
	ret

.dropdown:
	add dword [esp],5	// now it points to a ret
	movzx eax,al
	mov al,[menuairporttypes+eax]
	mov [selectedairporttype],al
	mov al,[esi+window.type]		// redraw the whole window
	mov bx,[esi+window.id]
	jmp dword [invalidatehandle]

exported newaircraftorder
	movzx ebx, byte [esi+veh.targetairport]
	imul ebx, station_size
	add ebx, [stationarrayptr]

	movzx edi, byte [ebx+station.airporttype]
	cmp dword [airportmovementedgelistptrs+edi*4],0
	jne .newairport

	cmp byte [esi+veh.aircraftop],0x12
	je .interrupt

.nointerrupt:
	ret

.newairport:
	movzx ecx,byte [esi+veh.movementstat]
	cmp cl,0xFF
	je .nointerrupt

	imul edx, ecx,airportmovementedge_size
	add edx, [airportmovementedgelistptrs+edi*4]
	test byte [edx+airportmovementedge.flags],AIREDGE_INTERRUPTIBLE
	jz .nointerrupt

	cmp ecx, 64
	jae .noreset
	btr [ebx+station2ofs+station2.airportbusyedges],ecx
.noreset:
.interrupt:

	mov [esi+veh.targetairport],ah
	jmp aircraftyield_newop

exported stopaircraft_isinflight
	push edi

	movzx edi, byte [edx+veh.targetairport]
	imul edi, station_size
	add edi, [stationarrayptr]
	movzx edi, byte [edi+station.airporttype]
	mov edi, [airportmovementedgelistptrs+edi*4]
	test edi,edi
	jnz .newairport

	cmp byte [edx+veh.aircraftop],4
	jb .gotflags
	cmp byte [edx+veh.movementstat],0xd
.gotflags:
	pop edi
	ret

.newairport:
	cmp byte [edx+veh.aircraftop],0x12
	je .gotflags		// if it's equal, cf must be clear

	push ecx
	movzx ecx, byte [edx+veh.movementstat]
	imul ecx, airportmovementedge_size

	cmp byte [edi+ecx+airportmovementedge.specaction],1
// cf is set only if specop was 0
	pop ecx
	pop edi
	ret

exported buynewaircraft
	mov al,[landscape2+ebp]

	movzx edx,al
	imul edx, station_size
	add edx, [stationarrayptr]
	movzx edx, byte [edx+station.airporttype]
	mov dl, [airportstarthangarnodes+edx]

	cmp dl,0xFF
	je .leavealone

	mov [esi+veh.aircraftnode],dl
	mov byte [esi+veh.movementstat],0xFF

.leavealone:
	mov edx, [esi+veh.veh2ptr]
	mov dword [edx+veh2.curraircraftact],AIRCRAFTACT_UNKNOWN
	ret

exported initairportstate
	and dword [esi+station2ofs+station2.airportbusyedges],0
	and dword [esi+station2ofs+station2.airportbusyedges+4],0
	cmp al,3
	jae .zerostate
	mov ax,[.startstates+eax*2]
	ret

.zerostate:
	xor eax,eax
	ret

noglobal varw .startstates, 4, 0x100, 0x40

// Tries to change the way the airport highlight area is done
uvarb AirportWindow

// Activates and deactivates the code below
global AirportHighligtDeactivate
AirportHighligtDeactivate:
	cmp ebx, 2724
	push eax
	mov al, 0
	jne .notpointer
	add al, 1
.notpointer:
	mov byte [AirportWindow], al
	pop eax

	cmp al, 4	
	jnz .same
	mov al, 0
	ret

.same:
	add dword [esp], 0x9
	ret

// Input:	ax = x
//		cx = y
// Output:	(nothing, just different backto point)
global CheckAirportTile
CheckAirportTile:
	// Is it Airport highlighting
	cmp byte [AirportWindow], 0x1
	je .Airport
	ret

.Airport:
	push ecx // Store the registors
	push eax

	sub ax, [landscapemarkerorigx] // Remove the tiles before the interested area
	sub cx, [landscapemarkerorigy]

	cmp ax, [highlightareainnerxsize] // should not be higher or equal to maxium size
	jae .notvalid			  // Negitives count as higher so they will get excluded
	cmp cx, [highlightareainnerysize]
	jae .notvalid

	shr ax, 4 // Make these usable in 8 bit form
	shr cx, 4

	push edx
	movzx edx, byte [selectedairporttype] // Get the selected Airport type
	mov bx, [airportsizes+edx*2] // Get the airport size
	mul bh // Multiply ax by the number of tiles in a row
	add ax, cx // Add the two together

	movzx ecx, ax // Use this as an offset
	mov ebx, [airportlayoutptrs+edx*4] // Get the offset for the layout
	pop edx
	mov bl, [ebx+ecx] // Get the sprite layout for the tile being tested
	pop eax // Restore the registors
	pop ecx

	cmp bl, 0x0 // If it is 0 then do not highlight
	jne .highlight

	pop ebx // Temparly here until a better solution can be found
	pop ebx

.highlight:
	ret

.notvalid:
	pop eax // Restore the registors
	pop ecx
	ret

// Used to check if the tile should be skipped when checking to see if airport constructable
// Input:	edi - Tile Y,X
//		dx - Current count (Y, X)
// Output:	?

#if 0
// Due to bugs causing airports to be built where they should not, this code
// has been removed and the corresponding patchproc has been modified not to
// icall this function.		-- DaleStan
// See http://zapotek.paivola.fi/~terom/logs/tycoon/view/2007-11-13~859#goto
// and http://www.tt-forums.net/viewtopic.php?p=641178#p641178

extern CheckForVehiclesInTheWay
global CreateAirportCheck
CreateAirportCheck:
	pusha // Preserve these registors

	neg dx // Due to the layouts being the other way round
	movzx ebx, byte [selectedairporttype] // Get the selected Airport type
	mov cx, [airportsizes+ebx*2] // Get the airport size
	add dx, cx // Fix the values to be possitive
	movzx ax, dl // Move these for full registors for later
	movzx dx, dh
	imul ch // Multiple the x by the number of y
	movzx cx, cl // Must move this into a bigger value to stop errors on the next steps
	add ax, dx // Add the together for an offset

	movzx eax, ax // Change it to be used as an offset
	mov ebx, [airportlayoutptrs+ebx*4] // Get the offset for the layout
	mov bl, [ebx+eax] // Get the sprite layout for the tile being tested

	cmp bl, 0x0 // Is this tile layout 0
	popa // Restore Registors
	je .skiptile // Skip the tile

	call [CheckForVehiclesInTheWay] // Check if the tile is occupied
	jnz .vehicleontile // If theres a vehicle on the tile, it will invalid

	ret // Valid so continue

// Jumps back to different code lines
.skiptile: // Jumps to the loop to next tile code
	add dword [esp], 0x4C
	ret

.vehicleontile: // Jumps to the invalid tile present so can't build
	add dword [esp], 0x76
	ret

#endif

// Used to stop construction on a certain tile (if tile layout is 00) 1,6
// Input:	[ebp] - planned tile type
// Output:	?
global CreateAirportTiles
CreateAirportTiles:
	cmp byte [ebp], 0x0 // Should this tile be made?
	je .skiptile

	mov al, [landscape4(di, 1)] // original code
	and al, 0x0F
	or al, 0x50
	ret

.skiptile:
	add dword [esp], 0x59+6*WINTTDX
	ret

// Used to store the station number
uvarb AirportStatNum

// Get the Station Number
global FetchAirportStationNumber
FetchAirportStationNumber:
	push eax
	mov al, [landscape2+esi]
	mov byte [AirportStatNum], al
	movzx esi, al
	pop eax
	ret

// Used to stop removal of non airport tiles
// Input:	edi - Tile
// Output:	?
global RemoveAirportCheck
RemoveAirportCheck:
	rol cx, 8 // Original code
	mov di, cx
	rol cx, 8
	or di, ax
	ror di, 4

	push ecx
	push edi
	and edi, 0xFFFF // Only the last word is usable for offsets
	mov ch, [landscape4(di, 1)] // Get Tile Class
	and ch, 0xF0 // Only want the Class part
	cmp ch, 0x50 // Is this a Class5 Tile
	jne .skiptile // Not a Class5 Tile so don't remove
	mov cl, [landscape2+edi] // Get the tile's station id
	cmp cl, [AirportStatNum] // Is the station id the same
	jne .skiptile // Not the same station so skip
	mov cl, [landscape5(di, 1)] // Get the type of Class5 tile
	cmp cl, 0x8 // Low bound of Airport Tile Types
	jb .skiptile // Tile class is a Rail station tile
	cmp cl, 0x42 // High bound of Airport Tile Types
	ja .skiptile
	pop edi

// Calculates the cost, for selling Irregular Airport Layouts (does it tile by tile)
	mov ecx, [costs+0xD8] // Get the cost per tile
	add [esp+0x0C], ecx // increase the total cost (using stack because it's pop'ed out at the end of the sub)
	pop ecx

	ret // Return to original function

.skiptile: // Skips the removal and checking of the tile
	pop edi
	pop ecx
	add dword [esp], 0x2D
	ret

// Used to store the tempary station cost location
uvard TempStationCost 

// Calculates the cost, for buying Irregular Airport Layouts (does it tile by tile)
global CalcAirportBuyCost
CalcAirportBuyCost:
	push edi
	push ecx
	mov edi, [TempStationCost] // Get the place to store the values
	add [edi], ebx
	mov ecx, [costs+0x42] // Get the cost value
	add [edi], ecx // Add the cost of the tile
	pop ecx
	pop edi
	cmp ebx, 0x80000000
	ret


