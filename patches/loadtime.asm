
// New loadtime calculation

#include <std.inc>
#include <flags.inc>
#include <station.inc>
#include <veh.inc>
#include <bitvars.inc>
#include <newvehdata.inc>

extern callbackflags,cargotypes,miscmodsflags,patchflags
extern randomconsisttrigger,randomstationtrigger,randomtrigger
extern stationarray2ofst,stationcargowaitingmask
extern stationplatformtrigger,newvehdata

// called when a vehicle's loading/unloading time is modified
//
// in:	esi=vehicle
//	ah=special commands (full load/unload etc.)
// out:	nz if time not done yet
//	zero+carry if loading/unloading done
//	zero+nc if load/unload more cargo

global loadtimedone
loadtimedone:
	dec word [esi+veh.loadtime]
	jnz short .haveit

	// load time expired, see if we need to unload/load more cargo
	test byte [esi+veh.modflags],1 << MOD_NOTDONEYET
	jnz short .haveitz

	// not done if full load is set
	test ah,0x40
	stc
	jnz .haveitz

	pushf
	push edx
	or edx,byte -1
	push 8
	call stationplatformtrigger
	pop edx
	popf
	ret

.haveitz:
	test al,0	// set zero flag and clear carry

.haveit:
	ret
; endp loadtimedone


uvarw totalloadamount		// how much cargo to load/unload at a time for gradualloading
uvarb numvehstillunloading	// number of vehicles not yet done with unloading
uvarb numvehloadable		// number of vehicles that can be process in this round
uvarb consistempty
uvard cargotypesloading

// loading/unloading speed by vehicle type
var loadwaittime, db 8,4,2,4

// in:	esi=>vehicle
// out:	ebx=load amount
global getloadamountcallback
getloadamountcallback:
	movzx ebx,byte [esi+veh.vehtype]
	test byte [callbackflags+ebx],4
	jz .noloadamountcallback

	mov ebx,[esi+veh.veh2ptr]
	movzx ebx,byte [ebx+veh2.loadamount]
	test ebx,ebx
	jnz .gotloadamount

	mov bl,[esi+veh.vehtype]

.noloadamountcallback:
	mov bl,[loadamount+ebx]

.gotloadamount:
	ret

// called to find out the maximum amount that can be loaded/unloaded now
//
// in:	esi=vehicle
//	ax=amount available in vehicle
// out: ax=max. load amount
// uses:--
global maxloadamount
maxloadamount:
	cmp byte [numvehloadable],0
	jnz .stillloading

	xor ax,ax
	ret

.stillloading:
	push ebx
	test byte [miscmodsflags],MISCMODS_GRADUALLOADBYWAGON
	jnz .notbywagon

	call getloadamountcallback
	cmp bx,[totalloadamount]
	jbe .nottoomuch

.notbywagon:
	mov bx,[totalloadamount]

.nottoomuch:
	cmp ax,bx
	jbe .stillnottoomuch

	mov ax,bx

.stillnottoomuch:
	pop ebx
	ret

global checkrandomcargotrigger
checkrandomcargotrigger:
	cmp word [esi+veh.currentload],0
	jne .notnewload

	// update random graphics if vehicle was empty and gets cargo
	push eax
	mov al,1
	call randomtrigger

	mov al,8
	call randomconsisttrigger
	pop eax

.notnewload:
	and word [esi+veh.traveltime],0		// and reset traveltime
	ret

	// one cargo type of a station had the last cargo removed
	// check if we need to trigger re-randomizing
	//
	// in:	 ax=amount of cargo loaded
	//	ebx->station
	//	esi->vehicle loading cargo
global checkstationcargoemptytrigger
checkstationcargoemptytrigger:
	pusha
	or edx,byte -1		// cargo types that are empty
	xor ecx,ecx
.nextcargotype:
	push ecx
	mov ax,[ebx+station.cargos+ecx*stationcargo_size+stationcargo.amount]
	and ax,[stationcargowaitingmask]
	jz .empty

	testflags newcargos
	jnc .nonewcargos

	add ebx,[stationarray2ofst]
	mov cl,[ebx+station2.cargos+ecx*stationcargo2_size+stationcargo2.type]
	sub ebx,[stationarray2ofst]
	cmp cl,0xff
	je .empty

.nonewcargos:
	cmp cl,[esi+veh.cargotype]
	jne .notthis

	sub ax,[esp+0x1c]
	jz .empty

.notthis:
	// not empty, clear appropriate bit
	btr edx,ecx

.empty:
	pop ecx
	inc ecx
	cmp ecx,12
	jb .nextcargotype

	// now edx is a bit mask of cargo types that are empty
	// see if have a tile which triggers on this set of empty cargos
	mov al,2
	mov ah,0x80
	call randomstationtrigger

	popa
	ret


// same as above, but only used to randomize the graphics for a new load
newloadrandomize:
	cmp ax,dx
	jbe short .enough
	mov ax,dx
.enough:
	or ax,ax
	jz short .nothing

	cmp ax,dx
	jne .notempty

	call checkstationcargoemptytrigger
	mov ax,dx

.notempty:
	call checkrandomcargotrigger

.nothing:
	ret
