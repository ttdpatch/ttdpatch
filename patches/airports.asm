#include <std.inc>
#include <airport.inc>
#include <textdef.inc>
#include <grf.inc>
#include <station.inc>
#include <veh.inc>

// Support for new airports supplyed by GRFs

extern curgrfairportlist,curspriteblock
extern grffeature,curcallback,getnewsprite,callback_extrainfo

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

uvarw airportstartstatuses, NUMAIRPORTS

uvarb airportspecialflags, NUMAIRPORTS

uvarb airportcallbackflags, NUMAIRPORTS

exported clearairportdata
	pusha
	xor eax,eax
	mov edi,airportdataidtogameid+NUMOLDAIRPORTS*8
	mov ecx,NUMNEWAIRPORTS*2
	rep stosd

	mov edi,airportsizes+NUMOLDAIRPORTS*2
	mov cl,NUMNEWAIRPORTS
	rep stosw

	mov edi,airportlayoutptrs+NUMOLDAIRPORTS*4
	mov cl,NUMNEWAIRPORTS
	rep stosd

	mov edi,airportmovementdataptrs+NUMOLDAIRPORTS*4
	mov cl,NUMNEWAIRPORTS
	rep stosd

	mov edi,airportstartstatuses+NUMOLDAIRPORTS*2
	mov cl,NUMNEWAIRPORTS
	rep stosw

	mov edi,airportmovementdatasizes+NUMOLDAIRPORTS
	mov cl,NUMNEWAIRPORTS
	rep stosb

	mov edi,airportspecialflags+NUMOLDAIRPORTS
	mov cl,NUMNEWAIRPORTS
	rep stosb

	mov edi,airportcallbackflags+NUMOLDAIRPORTS
	mov cl,NUMNEWAIRPORTS
	rep stosb
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
	mov ax,[airportstartstatuses+1*2]
	mov [airportstartstatuses+edx*2],ax
	mov byte [airportspecialflags],0
	mov byte [airportcallbackflags],0

	inc ebx
	dec ecx
	jnz .next

	clc
	ret

exported setairportmovementdata
	xor eax,eax
	lodsb
	mov [airportmovementdatasizes+ebx],al
	lea eax,[eax*3]
	shl eax,1
	mov [airportmovementdataptrs+ebx*4],esi
	add esi,eax
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
	cmp eax,NUMOLDAIRPORTS
	jb .exit

	bt dword [airportcallbackflags+eax], 0
	cmc
	jc .exit

	mov al,[airportmovementdatasizes+eax]
	cmp [esi+veh.movementstat],al
	jae .nomove

	push ebx
	call [aircraftmovement]
	pop ebx
	jnc .exit

.nomove:
	call doaircraftmovementcallbacks

.exit:
	ret

vard airportspecialmovements
	dd recheckorder			// force re-checking of orders when coming out of depot
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

doaircraftmovementcallbacks:
	mov [currentaircraftptr],esi
	xchg ebx,esi

	mov byte [grffeature],0xd
	mov dword [curcallback],0x143
	movzx eax, byte [esi+station.airporttype]
	mov edx,eax

	call getnewsprite
	jc .error
	mov [callback_extrainfo],al
	mov [callback_extrainfo+2],ah

	mov eax,edx
	inc dword [curcallback]
	call getnewsprite
	jc .error
	mov [callback_extrainfo+1],al

	mov eax,edx
	inc dword [curcallback]
	call getnewsprite
	jc .error

	cmp byte [callback_extrainfo+2],0
	je .nospecial

	pusha
	movzx eax, byte [callback_extrainfo+2]
	xchg ebx,esi
	call [airportspecialmovements+(eax-1)*4]
	popa

.nospecial:
	mov [esi+station.airportstat],ax
	mov ax,[callback_extrainfo]
	mov [ebx+veh.movementstat],al
	mov [ebx+veh.aircraftop],ah

	clc

.error:
	xchg ebx,esi
	mov dword [curcallback],0
	mov dword [currentaircraftptr],0
	ret

exported aircraftyield_newop
	movzx ebx, byte [esi+veh.targetairport]
	imul ebx,station_size
	add ebx,[stationarrayptr]

	mov al,[ebx+station.airporttype]
	cmp al, NUMOLDAIRPORTS
	jae .newairport

	mov ax,0x1212
	cmp byte [esi+veh.subclass],0
	jne .gotit
	mov al,0x14
	jmp short .gotit

.newairport:
	mov ax,0xFFFF

.gotit:
	mov [esi+veh.movementstat],al
	mov [esi+veh.aircraftop],ah
	mov [callback_extrainfo],ax
	ret
