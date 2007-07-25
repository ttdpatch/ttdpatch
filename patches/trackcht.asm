
// CHT: Tracks

#include <std.inc>
#include <proc.inc>
#include <flags.inc>
#include <newvehdata.inc>
#include <veh.inc>
#include <misc.inc>
#include <player.inc>

extern checkcost,checkmoney,docost
extern getnumber,isengine,patchflags,redrawscreen
extern showcost

extern calctrackcostdifference,getvehiclecost,newvehdata

// checks old track type and changes if necessary
%macro checksetoldtrack 3-4 edi+esi // params: shift,offset,docounttracks[,landscapearray]

	mov cl,byte [%4+esi+%2]
	%if %1
		shr cl,%1
	%else
		and cl,0xf
	%endif

	cmp byte [%$fromtrack],-1
	je short %%anymatches

	cmp cl,[%$fromtrack]
	jne short %%nomatch
%%anymatches:

	cmp cl,dl
	je short %%nomatch	// already right type

	%if %3
		call counttracks
	%else
		push byte 1
		call gettrackcost
	%endif

	or dh,dh
	jz short %%nomatch	// check cost only

	%define reg dl
	%if %1
		%define reg cl
		mov reg,dl
		shl reg,%1
	%endif
	and byte [%4+esi+%2],0xf0 >> %1
	or byte [%4+esi+%2],reg
	%undef reg
%%nomatch:
%endmacro


// Set carry if companies are related.
// The first company checked depends on the entry point:
//	checkowner reads [landscape1+esi]
//	.ecx reads [landscape1+ecx]
//	.veh reads [esi+veh.owner]
//	.usestack pops a dword from the stack and uses the low byte
// All compare the above byte to [curplayer]
// .ecx will modify esi; all others leave everything except the flags untouched
/*exported checkowner.usestack
	xchg eax, [esp] // pick up return address, and store old eax
	xchg eax, [esp+4] // put ret addr below old eax, and pick up parameter
	jmp short checkowner.check*/
exported checkowner.veh
	push eax
	mov al, byte [esi+veh.owner]
	jmp short checkowner.check
/*exported checkowner.ecx
	mov esi,ecx*/
exported checkowner
	push eax
	mov al, byte [landscape1+esi]
.check:
	cmp al, 10h
	jae .ret	//Not a company, carry is clear
	movzx eax, al
	push ecx
	movzx ecx, byte [curplayer]
	extern relations
	bt [relations+eax],ecx
	pop ecx
.ret:
	pop eax
	ret
; endp checkowner

proc trackcheat
	local doit,trackopt

	_enter

	call getnumber		// first number: new tracks
	cmp edx,byte 2
	jg near .badparameters
	cmp edx,byte 0
	jl short .badparameters
	mov cl,dl		// store temporarily in safe register

	call getnumber		// then, optional, old track type
	cmp edx,byte 2
	jg short .badparameters
	cmp edx,byte -1
	jl short .badparameters
	mov ch,dl

	call checkcost
	mov [%$doit],dx		// now dl=doit?  dh=cost?

	or dh,dh

	mov [%$trackopt],cx
	mov dh,dl
	mov dl,cl

	jz short .nocost
	or dh,dh
	jz short .nocost

	// if things cost money, and we don't just check, make sure the
	// player has enough money

	pusha
	xor dh,dh
	call dothetrackthing

	push ebx
	mov cx,[%$trackopt]
	xor ah,ah
	call convertvehicles
	pop edi

	add ebx,edi
	call checkmoney

	popa
	jl short .badparameters

.nocost:
	call dothetrackthing

	mov ax,[%$doit]
	mov cl,expenses_construction
	call docost

	push ebx
	mov cx,[%$trackopt]
	mov ah,byte [%$doit]
	call convertvehicles
	pop edi

	mov ax,[%$doit]
	mov cl,expenses_newvehs
	call docost

	add ebx,edi
	call showcost

	clc
	_ret

.badparameters:
	stc
	_ret
endproc // trackcheat

	// in:	 bl=old track type or -1
	//	 dl=new track type
	//	 dh=operation type (see below)
	// out:	ebx=cost in pounds
	// modifies all but edx, ebp.
proc dothetrackthing
	local bridgedelta,fromtrack,cost

	_enter

	mov [%$fromtrack],ch

	xor esi,esi
	mov [%$cost],esi

	mov ecx,0xffff
	mov edi,landscape3

	// Register usage inside the loop:
	// al  : fs:[si], height and type*16;
	//		1=RR, 2=Road/RR Crossing, 5=Station, 9=Bridge/Tunnel
	// ah  : gs:[si], subtype
	// ebx (unused) // old : Pointer to ownership array
	// cl  : old track type in checksetoldtrack
	// ch  : (cl in players), 0 if player is affected, 1 otherwise
	// dl  : "to" track type
	// old : dh="from" track type
	// new : dh=check cost only if 0
	// esi : Index into landscape
	// edi : Pointer to track type array
	// ebp : Stack base pointer

.checksquare:
	push ecx
	mov al,[landscape4(si)]
	shr al,4
	mov ah,[landscape5(si)]
	call checkowner
	setnc ch			// checkowner no longer does this
	cmp al,9			// bridge has two owners and different check
	je short .isbridgeortunnel	// - for all others check ownership now
	or ch,ch
	jne short .nextsquare		// wrong owner
	cmp al,1
	je short .istrainsquare
	cmp al,2
	je short .isroadorcrossing
	cmp al,5
	je short .isstationsquare

.nextsquare:
	inc esi
	pop ecx
	loop .checksquare
	jmp .conversiondone

.istrainsquareowner:			// it's a train square, but have to test ownership
	or ch,ch
	jnz .nextsquare
.istrainsquare:
	checksetoldtrack 0,0,1
	jmp .nextsquare

.isstationsquare:
	cmp ah,8
	jb .istrainsquare
	jmp .nextsquare

.isroadorcrossing:
	test ah,0x10
	jz .nextsquare			// just a normal road - no crossing
	checksetoldtrack 0,1,0
	jmp .nextsquare

.isbridgeortunnel:
	cmp ah,4
	jb near .istraintunnel			// it's a train tunnel
//	cmp ah,8
//	jb @@nextsquare			// it's a road tunnel - next cmp catches this
	cmp ah,0x80
	jb .nextsquare			// don't know what it is

	cmp ah,0x84			// anything above 82h is taken care
	ja .nextsquare			// of by processing the bridge

	// it's the start of a bridge. Follow it till the end
	push edi
	push esi

	mov dword [%$bridgedelta],1
	test ah,2
	jz short .israilroadbridge
	mov ch,1			// it's a road bridge - don't change it
.israilroadbridge:
	test ah,1
	jz short .checkbridgesquare
	mov dword [%$bridgedelta],256	// in the y direction

.checkbridgesquare:
	mov al,[landscape5(si)]
	mov ah,al
	and ax,0xff0 & ~ 0x300

	// al: 80=start// a0=end// c0=nothing below// e0=something below
	// if al=e0, ah: 0=railroad// 8=road
	test al,0x40
	jz short .changestartend	// end or start
	cmp al,0xe0
	jne short .notourrailroadbelow	// nothing below

	or ah,ah
	jnz short .notourrailroadbelow	// road below
	call checkowner
	jnc short .notourrailroadbelow	// another company's railroad
	jmp short .checklowertrack

.changestartend:
	or ch,ch
	jnz short .nextbridgesquare
	jmp short .changelowertrack

.checklowertrack:
	call checkowner
	jnc short .testuppertrack
.changelowertrack:
	checksetoldtrack 0,0,0
.testuppertrack:
	test al,0x40
	jz short .nextbridgesquare	// nothing above

.notourrailroadbelow:			// if it's our bridge, change it
	or ch,ch
	jnz short .nextbridgesquare

.changeuppertrack:
	checksetoldtrack 4,0,0

.nextbridgesquare:
	add esi,[%$bridgedelta]
	cmp al,0xa0
	jne .checkbridgesquare		// stop at the end

	pop esi
	pop edi

	jmp .nextsquare

.istraintunnel:			// it's a train tunnel square, but have to test ownership
	or ch,ch
	jnz .nextsquare
	testflags enhancetunnels
	jnc .istrainsquare
	checksetoldtrack 0,0,0,landscape7
	jmp .istrainsquare

.conversiondone:
	// done with the track conversion; force redraw of screen
	call redrawscreen
	mov ebx,[%$cost]
	_ret

// fake procedure in same stack frame to access cost variable

// in:	cl=from type
//	dl=to type
//	on stack: number of tracks
gettrackcost:
	push eax
	mov eax,[trackcost]
	mov ebx,[tracksale]	// tracksale value is negative

	testflags tracktypecostdiff
	jnc short .allcostthesame

	call calctrackcostdifference	// take cost * costfactor(new)

	xchg eax,ebx
	xchg dl,cl
	call calctrackcostdifference	// take sale * costfactor(old)
	xchg dl,cl

.allcostthesame:
	add ebx,eax
	pop eax
	imul ebx,dword [esp+4]
	add [%$cost],ebx
	_ret 4

endproc dothetrackthing



	// convert all vehicles so they don't blow up
	// in: ch=from,  cl=to,  ah=1 if do it, 0 if check cost
convertvehicles:

	mov esi,[veharrayptr]
	xor edi,edi	// cost

.checknextvehicle:
	cmp byte [esi+veh.class],0x10
	jne short .changenextvehicle
	call checkowner.veh
	jnc short .changenextvehicle
	cmp ch,-1
	je short .righttype
	cmp [esi+veh.tracktype],ch
	jne short .changenextvehicle

	// don't convert steam or diesel engines to electric
	testflags electrifiedrail
	jnc .righttype

	cmp cl,1
	jne .righttype

	movzx edx,byte [esi+veh.vehtype]
	bt [isengine],edx
	jnc .changenextvehicle

	cmp byte [traintractiontype+edx],0x28
	jb .changenextvehicle

.righttype:
	cmp [esi+veh.tracktype],cl
	je short .changenextvehicle	// already right type

	call getvehiclecost	// add 12.5% of new price to value
	shr edx,3		// now edx=engine value new / 8

	// now add to cost
	add edi,edx

	or ah,ah
	jz short .changenextvehicle	// check cost only

	mov [esi+veh.tracktype],cl
//	add [esi.value],edx	// actually, don't add the 12.5% to the
//		value; they're supposed to represent the cost of conversion
//		of the undercarriage; that doesn't actually add to the value

.changenextvehicle:
	sub esi,byte -vehiclesize	//add esi,vehiclesize
	cmp esi,[veharrayendptr]
	jb short .checknextvehicle

	mov ebx,edi
	ret
; endp convertvehicles

counttracks:
	xor ebx,ebx
	mov bh,[landscape5(si)]

.morebits:
	shr bh,1
	adc bl,0

	or bh,bh
	jnz .morebits

	push ebx
	call gettrackcost
	ret
; endp counttracks
