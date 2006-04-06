
// Bribe option

#include <std.inc>
#include <proc.inc>
#include <textdef.inc>
#include <station.inc>
#include <player.inc>
#include <town.inc>

extern errorpopup,invalidatehandle,randomfn,townarray2ofst





// Calculate the bribe cost
//
// in:	eax=cityofs rel. to city array
// out:	eax=bribe cost
bribecost:
	push ebx
	push ecx
	push edx

	add eax,townarray
	mov ebx,eax

	movzx eax,byte [human1]
	cmp word [ebx+town.ratings+eax*2],600
	jng short .canbribe	// can't bribe if already excellent

	xor eax,eax

.done:
	pop edx
	pop ecx
	pop ebx
	ret

.canbribe:

	// factor one: city's population divided by 32
	movzx ecx,word [ebx+town.population]
	shr ecx,4

	// factor two: 25% of last quarter's income, or
	//	 5% of cash whichever is more
	movzx edx,byte [human1]
	imul edx,player_size
	add edx,[playerarrayptr]	// now edx=player struct
	mov eax,dword [edx+player.cash]
	shr eax,5

	mov edx,dword [edx+player.lastquarterincome]
	neg edx
	shr edx,2

	cmp eax,edx
	jg short .cashismore
	mov eax,edx
.cashismore:
	cmp eax,byte 0
	jg short .itspositive
	xor eax,eax
.itspositive:

	// scale this amount appropriately
	shr eax,12	// divide by 8192

	// and add prior amounts
	add ecx,eax

	// factor three: half of this is waived if 100% pass+mail were transported
	movzx eax,byte [ebx+town.passtranspfr]
	movzx edx,byte [ebx+town.mailtranspfr]
	add eax,edx
	mul ecx		// now EAX = cost so far * (actual/max passengers + actual/max mail)*255
	shr eax,10	// now EAX = cost so far * (actual/max passengers + actual/max mail)/2 / 2
	sub ecx,eax	// subtract this from the cost

	xchg eax,ecx	// and return that
	mov ecx,175
	cmp eax,ecx	// maximum 1.5 times the cost for a monopoly
	jbe .done

	xchg eax,ecx
	jmp .done
; endp bribecost 

// Fix index of the option selected in the LA menu
// in:	ebx=option index, from 0 up
//	dword[esi+2a]=bit mask of options
// out:	ebx=fixed option index
fixtownoptionindex:
	bt [esi+0x2a],ebx
	jc short .done
	mov bl,7	// currently it can be only the bribe option
.done:
	ret
; endp fixtownoptionindex 

// Part 1 : Modify the Local Authority Menu (aka "The Hard Part")

// Set a mask of options available to the player
//
// in:	ecx=bit mask of options
//	edx=money available
//	bl=number of highest option
//	ebp=cost factor
// out:	[esi+2a]=ecx
//	[esi+1]=bl
// safe:eax
global townmenu1
townmenu1:
	push edi
	movzx eax,word [esi+6]
	lea edi,[eax+townarray]
	call bribecost
	imul eax,ebp
	jz short .nobribeoption

	cmp eax,edx
	jg short .nobribeoption

	or cl,0x80
	inc bl

.nobribeoption:

	// see if the player can do anything else or if he is "unwanted"
	movzx eax,byte [human1]
	add edi,[townarray2ofst]
	cmp byte [edi+town2.companiesunwanted+eax],0
	jz .notunwanted

	// player has no options in this city
	xor ecx,ecx
	mov bl,1

.notunwanted:
	mov [esi+0x2a],ecx
	mov [esi+1],bl
	pop edi
	ret
; endp townmenu1 

// Set the text to display for a menu entry
//
// in:	BP=number of entry
// out:	BX=text index
// safe:
global townmenu2
townmenu2:
	cmp bp,byte 7
	jae short .myopt
	mov bx,0x2046
	add bx,bp
	ret

.myopt:
	mov bx,ourtext(bribetext)
	ret
; endp townmenu2 

// Set the description when the option is selected
//
// in:	ebx=option index
// out:	bx=text index (204d+option, or ourtext)
//	bp=139h

global townmenu3
townmenu3:
	push eax
	lea eax,[ebx+1]
	cmp al,[esi+1]
	jae short .notvalid
	call fixtownoptionindex
	cmp bl,7
	jae short .myopt
	add bx,0x204d

.done:
	mov bp,0x139
	pop eax
	ret

.notvalid:
	mov word [esi+0x22],0xffff	// deselect
	mov bx,0x204d+7
	jmp short .done

.myopt:
	// We need to modify three things:
	// * cost  -> [774DC]
	// * name of option -> [774DA]
	// * description -> BX
	mov ebx,ebp
	mov ebp,[esp+4]
	movzx eax,word [esi+6]
	call bribecost
	imul eax,ebx
	jz short .notvalid

	mov ebx,[ebp-0x17]
	mov [ebx],eax
	mov eax,[ebp-10]
	mov word [eax],ourtext(bribetext)
	mov bx,ourtext(bribedesc)
	jmp short .done

; endp townmenu3 


// Fix option index before doing the action
// (can't be done in townmenu4 because ESI is no longer valid there)
// in:	ebx=option index (see fragment.ah)
// out:	bl=1
//	bh=fixed option index
global townselfixidx
townselfixidx:
	and cx,0xff0	// overwritten by the call
	call fixtownoptionindex
	mov bh,bl
	mov bl,1
	ret
; endp townselfixidx 

// Actually do the action
//
// in:	bh=option index (fixed)
//	bl=1 if we really do it, 0 if only checking price
// out:	ebp=cost
global townmenu4
townmenu4:
	cmp bh,7
	jae short dobribe

	imul ebp,esi
	test bl,1
	ret
; endp townmenu4

proc dobribe
	local thiscity,chance,cost	// cost must be last

	_enter

	pusha
	movzx eax,dl
	imul eax,byte town_size

	mov [%$thiscity],eax

	call bribecost
	imul eax,esi
	mov [%$cost],eax
	jz short .bribedone	// can't bribe

	test bl,1
	jz short .checkonly

	call dword [randomfn]
	mov [%$chance],ax

	// of course curplayer is set here... most of the L.A. action procs rely on that! -- Marcin
	movzx eax,byte [curplayer]

	mov edx,[%$thiscity]
	add edx,townarray

	bts dword [edx+town.companiesrated],eax
	lea ebx,[eax*2+edx+town.ratings]

	cmp word [%$chance],0x1111	// chance of 1 in 15 that the bribe fails
	jb short .bribefailed

	// do the actual bribing

	cmp word [ebx],600	// don't bribe if already excellent
	jg short .checkonly

	add word [ebx],200	// 200 = one ratings level

.bribedone:
	// re-draw window
	mov al,0x2b			// window type L.A. menu
	mov bx,[%$thiscity]		// window index = this city
	call dword [invalidatehandle]

.checkonly:
	xor eax,eax	// set zero flag
	popa
	leave

	mov ebp,dword [esp-8]	// [esp-8] = cost
	ret

.bribefailed:
	pusha

	// set to "poor"
	cmp word [ebx],byte -50
	jl short .alreadyappalling

	mov word [ebx],-50

.alreadyappalling:

	// set as "unwanted" for 6 months
	mov esi,[townarray2ofst]
	add esi,edx
	mov byte [esi+town2.companiesunwanted+eax],6

	// set all station ratings to zero
	mov esi,stationarray
	mov ecx,numstations

.stationloop:
	cmp word [esi+station.XY],byte 0
	je short .nextstation		// unused entry

	cmp byte [esi+station.owner],al
	jne short .nextstation		// wrong owner

	cmp dword [esi+station.townptr],edx
	jne short .nextstation		// different city


	// right owner and city; set all ratings to 0
	xor ebx,ebx

// newcargos note: this won't hurt the newcargos scheme since unused
// slots are re-initialized before activating them
.nextcargo:
	mov byte [esi+station.cargos+stationcargo.rating+ebx*8],0
	inc ebx
	cmp ebx,byte 12		// 12 different types of cargo
	jb .nextcargo

.nextstation:
	add esi,station_size
	loop .stationloop

	// show error popup
	mov bx,ourtext(bribefailed)
	or edx,byte -1
	xor eax,eax
	xor ecx,ecx
	call dword [errorpopup]
	jmp .bribedone

	%assign %$didret 1	// don't generate leave and ret here
endproc // dobribe
