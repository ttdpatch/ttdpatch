//
// Improved city growth algorithm
//

#include <std.inc>
#include <town.inc>
#include <flags.inc>

extern bigtownfreq,gettileinfo,patchflags,townminpopulationdesert
extern townminpopulationsnow
extern townsizelimit




var townzonefactors, db 144,100,72,64,36

var towngrowthrates, db 210,150,110,80,55	// <- straight from TTD, except the last one which is interpolated
	db 60,60,60,50,40,30			// <- used when town funding is active, the first is from TTD
						//    (6 values b/o possible index=0, which can't happen with no funding)

// Continue expanding town zones when number of buildings >= 88
// in:	ESI->town
//	EBX=number of buildings (town.buildingcount, zero-extended)
// out:	CF set: use TTD code, clear: done
// note:TTD code requires (EBX>>2)<23
// safe:EAX
global settownzones
settownzones:
	cmp ebx,byte 92
	jnb .calculate
	ret

.calculate:
	pusha
	push es
	push ds
	pop es
	lea edi,[esi+town.zones]
	mov esi,townzonefactors
	xor ecx,ecx
	mov cl,5
	shr ebx,2
	add ebx,byte 30				// the maximum value in EBX is 65535/4+30 = 16413 now

.calcloop:
	xor eax,eax
	lodsb
	imul ebx
	imul eax,65536/53			// max. result = 16413*144*(65536/53) = 0xAE1EC240 ==> no overflow possible
	shr eax,16
	stosw
	loop .calcloop

	pop es
	popa
	clc
	ret


// Auxiliary: check if a town is one of those supposed to be bigger
// in:	EAX=town index in bits 7:0, other bits can be garbage
// out:	CF clear if largertowns is enabled, set if disabled
//	ZF set if this is one of the larger towns, clear if not (always clear if CF=1)
// uses:EAX,BL
global istownbigger
istownbigger:
	and eax,byte 0x7F
	testflags largertowns
	jc .active
	sub al,-1				// guaranteed to set CF and clear ZF
	ret

.active:
	mov bl,[bigtownfreq]
	div bl
	or ah,ah				// is (town_index MOD bigtownfreq) zero?  (always clears CF)
	ret


// Set the value that determines for how many steps the town expansion algorithm can trace roads
// in:	ESI->town
//	AL=town index
// safe:EAX,EBX,EDI,EBP
global settowngrowthlimit
settowngrowthlimit:
	or al,0x80				// overwritten...
	mov [curplayer],al

	// if largertowns is disabled, use the new factor for all towns, otherwise only for selected towns
	call istownbigger
	ja .done				// skip new factor setting if CF=0 (enabled) and ZF=0 (not bigger)

	mov al,[townsizelimit]
	mov [dword -1],al
ovar .townsizefactorvarptr,-4,$,settowngrowthlimit

.done:
	ret


// Modify town expansion rate setting; also fix array index being out of bounds and other problems
// (also activated by generalfixes)
// in:	ESI->town
//	CH=number of active stations in the transport zone, up to 5 (never 0 if CL<>0)
//	ZF=0 if a town building funding is active (see patches.ah, fragment.ah)
// out:	CL=inverse growth rate (unit=70 ticks)
// safe:EAX,EBX,EDI,EBP
global settowngrowthrate
settowngrowthrate:
	movzx ecx,ch				// overwritten... (doesn't affect flags)
	jz .getrate
	add cl,6
.getrate:
	mov cl,[towngrowthrates-1+ecx]

	// double the actual rate for towns supposed to be bigger
	mov eax,esi
	sub eax,townarray
	mov bl,town_size
	div bl
	call istownbigger
	jnz .done
	shr cl,1

.done:
	ret


// Make towns always expand in sub-arctic if their population is too low to accept food reliably
// in:	ESI->town, AL=altitude of the central tile
// out:	CF set=town expansion possible even if no food transported last month
global gottownfood
gottownfood:
	cmp al,[snowline]			// overwritten by runindex call
	jb .done
	push eax
	movzx eax,byte [townminpopulationsnow]
	cmp [esi+town.population],ax
	pop eax
.done:
	ret

// ...and similar for sub-tropical
// in:	ESI->town
// out:	ZF set=no town expansion
global gottownfoodandwater
gottownfoodandwater:
	push eax
	movzx eax,byte [townminpopulationdesert]
	cmp [esi+town.population],ax
	pop eax
	jb .done				// implies NZ

	// the original (overwritten) checks
	cmp word [esi+town.foodlastmonth],0
	jz .done
	cmp word [esi+town.waterlastmonth],0
.done:
	ret


// Fix number of houses not being decremented if the removed building was under construction
global fixremovehouse
fixremovehouse:
	dec word [edi+town.buildingcount]	// always decrement
	and bl,0xC0				// and then do...
	cmp bl,0xC0				// ... the overwritten part
	ret


// Fix towns not building on waterbanks
// called just before TTD calls [actionhandler]
global buildnewtownhouseflags
buildnewtownhouseflags:
	mov esi,0x18				// overwritten
	jmp short buildnewtownthingflags

global expandtownstreetflags
expandtownstreetflags:
	mov esi,0x10				// overwritten

buildnewtownthingflags:
	mov bl,0xB				// also overwritten
	pusha
	call [gettileinfo]
	xor bl,0x30				// class=water? (CF=0)
	jne .nope
	xor dh,1				// waterbank? (CF=0)
	jne .nope

	// exclude waterways (i.e. only one bit set in DI)
	movzx edi,di
	bsf eax,edi
	btr edi,eax
	neg edi					// CF=(EDI<>0)

.nope:
	popa
	jnc .done
	mov bl,3				// enable building on water
.done:
	ret
