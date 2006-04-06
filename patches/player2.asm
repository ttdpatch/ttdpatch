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
	mov eax,[esp+12]
	movzx ebx,byte [eax+veh.owner]
	movzx eax,byte [eax+veh.vehtype]
.getcolor:
	// here eax=vehtype ebx=player
	mov ah,[companycolors+ebx]
	mov [tempvehcols+0],ah
	imul ebx,0+player2_size
	add ebx,[player2array]
	mov ah,cColorSchemeDarkGreen	// default 2nd col to use (maps green->green)
	test byte [ebx+player2.colschemes],1<<COLSCHEME_HAS2CC
	jz .no2ndcol
	mov ah,[ebx+player2.col2]
.no2ndcol:
	mov [tempvehcols+1],ah
	mov ah,0

	// now to check vehicle type here
	cmp al,ROADVEHBASE
	jb .train

	cmp al,SHIPBASE
	jb .rv

	cmp al,AIRCRAFTBASE
	jb .ship

.aircraft:
	mov al,COLSCHEME_AIRCRAFT
	jmp short .special

.train:
	bt [isengine],eax
	jnc .wagon

	mov ah,[traintractiontype+eax]
	cmp ah,0x32
	jae .monorailmaglev
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
.monorailmaglev:
	mov al,COLSCHEME_MR_MAGLEV
	jmp short .special

.wagon:
	mov al,[traincargotype+eax]
	bt dword [isfreight],eax

	mov al,COLSCHEME_PASS
	adc al,0
	jmp short .special

.rv:
	call isrvtypebus
	setnz al
	add al,COLSCHEME_BUS
	jmp short .special

.ship:
	mov al,COLSCHEME_SHIP

.special:
	movzx eax,al
	bt [ebx+player2.colschemes],eax
	jnc .done

	mov ax,[ebx+player2.specialcol+(eax-COLSCHEME_SPECIAL)*2]
	mov [tempvehcols],ax

.done:
	pop ebx
	pop eax
	ret 4

// same as above, but with vehtype on stack and using human1 as player
global getvehiclecolors_vehtype
getvehiclecolors_vehtype:
	push eax
	push ebx
	mov eax,[esp+12]
	movzx ebx,byte [human1]
	jmp getvehiclecolors.getcolor
