//
// Player 2 array
//

#include <std.inc>
#include <player.inc>
#include <window.inc>
#include <veh.inc>
#include <newvehdata.inc>
#include <ptrvar.inc>

extern tempvehcols,isengine,isfreight,isrvtypebus,newvehdata
extern cargoclass,getdefvehcargotype

uvard player2array

// reset player 2 array
global player2clear
player2clear:
	pusha
	mov edi,[player2array]
	mov ecx,8*player2_size/4
	xor eax,eax
	rep stosd
	popa
	ret

// calculate vehicle colours depending on vehicle type
//
// in:	on stack: veh ptr
// out:	sets [tempvehcols+0]=primary col, [tempvehcols+1]=secondary col
// uses:---
global getvehiclecolors
getvehiclecolors:
	push eax
	push ebx
	push edx
	mov eax,[esp+16]
	movzx ebx,byte [eax+veh.owner]
	movzx edx,byte [eax+veh.cargotype]
	movzx eax,byte [eax+veh.vehtype]
.getcolor:
	// here eax=vehtype ebx=player edx=cargotype
	mov ah,[companycolors+ebx]
	mov [tempvehcols+0],ah
	imul ebx,0+player2_size
	add ebx,[player2array]
	test byte [ebx+player2.colschemes],1<<COLSCHEME_HAS2CC
	jz .no2ndcol			// if no secondary colour set, use primary instead
	mov ah,[ebx+player2.col2]
.no2ndcol:
	mov [tempvehcols+1],ah
	mov ah,0

	// now to check vehicle type here
	cmp al,ROADVEHBASE
	jb .train

	cmp al,SHIPBASE
	jb near .rv

	cmp al,AIRCRAFTBASE
	jb near .ship

.aircraft:
	test byte [cargoclass+edx*2],1
	jz near .freightplane

	cmp byte [planeisheli+(eax-AIRCRAFTBASE)],2
	jb .heli

	cmp byte [planeislarge+(eax-AIRCRAFTBASE)],1
	sbb al,al			// -1 if small, 0 if large
	add al,COLSCHEME_LAPLANE	// _LAPLANE if large, _SAPLANE if not
	jmp .special

.heli:
	mov al,COLSCHEME_HELI
	jmp .special

.freightplane:
	mov al,COLSCHEME_FRPLANE
	jmp .special

.train:
	bt [isengine],eax
	jnc .wagon

	test byte [vehmiscflags+eax],VEHMISCFLAG_MULTIPLEUNIT
	mov ah,[traintractiontype+eax]
	jnz .ismu

	cmp ah,0x38
	jae .maglev
	cmp ah,0x32
	jae .monorail
	cmp ah,0x28
	jae .electric
	cmp ah,0x08
	jae .diesel
.steam:
	mov al,COLSCHEME_STEAM
	jmp short .special
.diesel:
	mov al,COLSCHEME_DIESEL
	jmp short .special
.electric:
	mov al,COLSCHEME_ELECTRIC
	jmp short .special
.monorail:
	mov al,COLSCHEME_MONORAIL
	jmp short .special
.maglev:
	mov al,COLSCHEME_MAGLEV
	jmp short .special

.ismu:	
	cmp ah,0x28
	sbb al,al		// -1 for DMU, 0 for EMU
	add al,COLSCHEME_EMU

	movzx eax, al		 // Move the bit to test to whole of eax
	bt [ebx+player2.colschemes], eax	// Is the emu bit active
	jc .special				// If it is jump this
	sub al, COLSCHEME_DMU-COLSCHEME_DIESEL	// Go to the Type of Vehicle
	jmp short .special

.wagon:
	mov al,[traincargotype+eax]
	bt dword [isfreight],eax

	mov al,COLSCHEME_PASS
	adc al,0
	jmp short .special

.rv:
	test byte [vehmiscflags+eax],VEHMISCFLAG_RVISTRAM
	jnz .tram
	sub al,ROADVEHBASE
	call isrvtypebus
	setnz al
	add al,al
	add al,COLSCHEME_BUS
	jmp short .special

.tram:
	mov al,COLSCHEME_TRAM
	jmp short .special

.ship:
	test byte [cargoclass+edx*2],1
	jz .freightship

	mov al,COLSCHEME_PASHIP
	jmp short .special

.freightship:
	mov al,COLSCHEME_FRSHIP

.special:
	movzx eax,al
	bt [ebx+player2.colschemes],eax
	jnc .done

	mov ax,[ebx+player2.specialcol+(eax-COLSCHEME_SPECIAL)*2]
	mov [tempvehcols],ax

.done:
	pop edx
	pop ebx
	pop eax
	ret 4

// same as above, but with vehtype on stack and using human1 as player
global getvehiclecolors_vehtype
getvehiclecolors_vehtype:
	push eax
	push ebx
	push edx
	mov eax,[esp+16]
	movzx ebx,byte [human1]

	push eax
	call getdefvehcargotype
	pop edx
	jmp getvehiclecolors.getcolor

