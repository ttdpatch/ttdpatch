// More news items

#include <std.inc>
#include <flags.inc>
#include <textdef.inc>
#include <station.inc>
#include <veh.inc>
#include <town.inc>
#include <industry.inc>
#include <ptrvar.inc>

extern clearcrashedtrainpath,newsmessagefn,patchflags


// ********
// WARNING!
// ********

//
// When passing arguments to [newsmessagefn], either in registers or on
// the textrefstack or the newsitemparams, make sure NOT to use ourtext() or
// statictext() directly, because these IDs may change, causing news messages
// in the queue to change too, possibly causing crashes or other Bad Things.
//
// Instead, use the defnewstext() et.al. C preprocessor macros in textdef.ah
// to define a corresponding newstext() ID and use only that.
//
// (This feature can and should be used for any text IDs that may be stored
//  directly anywhere in savegames.)
//

// Here we actually store the text ID redirection strings as set it textdef.ah

%push ntxt_def
%assign %$ntxtnum 0
%assign %$thistext 0
%macro _defnewstext 0.nolist
%$text_%$ntxtnum:
	%ifndef PREPROCESSONLY
		%define %$thistext %$text_%$ntxtnum
	%endif
	%if %$ntxtnum>0
		%xdefine %$ntxts %$ntxts,%$thistext
	%else
		%xdefine %$ntxts %$thistext
	%endif

	// make a substring using 81 ID(W) 00
	dd (0 << 24) + (NTXT_ARG_ %+ %$ntxtnum << 8) + (0x81)

	%assign %$ntxtnum %$ntxtnum+1
%endmacro

	align 4

// use a macro in %rep so as not to clutter the listing file so much
%rep NTXT_NUM
	_defnewstext
%endrep

var ntxtptr, dd %$ntxts
%undef _defnewstext
%pop

#define newsdata(text,category) ( newstext(text) | (category<<16) )

// Generate a news report when a large UFO is destroyed
// in:	ESI -> XCOM aircraft
//	EDI -> UFO
// safe:(E)AX,EBX,CX,DX,EBP (well, we PUSHA anyway)
global largeufodestroynews
largeufodestroynews:
	mov	word [esi+veh.currorder],1		// overwritten by runindex call
	mov	edx,newsdata(ufodestroyed,2)
	call	newsmsgwithnearesttown
	ret
; endp largeufodestroynews

	// find the nearest town and store its name
	// this is about how TTD does it when a large UFO lands
	//
	// in:	ax=XY
pushnearesttownonrefstack:
	push	edi
	mov	ebp,[ophandler+(3*8)]
	xor	ebx,ebx
	mov	bl,1
	call	dword [ebp+4]		// returns the nearest town ptr in EDI and distance in BP; scrambles BX,ESI
	mov	esi,textrefstack
	mov	ax,word [edi+town.citynametype]
	mov	[esi],ax
	mov	eax,dword [edi+town.citynameparts]
	mov	[esi+2],eax
	pop	edi
	ret


// Shows a news message with the given text centered on the given vehicle.
// textrefstack contains the closest town
// in:	edi: vehicle
//	dx: message ID
//	upper half of edx: message category
newsmsgwithnearesttown:
	pusha

	mov ax,[edi+veh.XY]
	call pushnearesttownonrefstack

	// now set coordinates and invoke the news/message handler
	movzx	eax,word [edi+veh.xpos]
	movzx	ecx,word [edi+veh.ypos]
	mov	ebx,eax
	shr	ebx,4
	shl	ecx,4
	mov	bh,ch
	shr	ecx,4
	mov	[newsitemparam],ebx
	mov	ebx,edx
	mov	bx,0x0502
	call	dword [newsmessagefn]

	popa
	ret

// Watching production of lumber mills works this way:
// We count the number of treecuts since the last unsuccessful one in the field that would contain
// the production rate of the second cargo. Since lumber mills product only one thing, our counter
// won't make problems (it will modify the production counter of the second cargo, but this isn't used
// anyway). We notify the player only if there were at least four successful cuts before an unsuccessful one.
// This way we can avoid multiple warnings caused by cutting the few baby trees that grow sometimes
// in the otherwise empty area.

// Called at the end of tree-finding loop for lumber mills. If no trees were found, the procedure exits here.
// esi points to the lumber mill in the industry array
// safe:none

global lmillcuttree1
lmillcuttree1:
	sub bx,0x101	// owerwritten
	cmp cl,41	// by the runindex call
	jnb .outoftrees
	ret		// haven't finished the loop yet

.outoftrees:
	cmp byte [esi+industry.prodrates+1],4
	jbe .notenough
 
	push eax
	push ebx
	push ecx

	mov ecx,textrefstack

	// fill the text stack with the needed information
	// first the city name
	mov eax, [esi+industry.townptr]
	mov bx, [eax+town.citynametype]
	mov [ecx],bx
	mov eax, [eax+town.citynameparts]
	mov [ecx+2],eax

	// then the industry name
	movzx ax, byte [esi+industry.type]
	add ax, 0x4802
	mov [ecx+6],ax

	// make parameters for newsmessagefn
	movzx ebx,word [esi+industry.XY]
	movzx eax,bl
	movzx ecx,bh
	mov [newsitemparam],ebx
	shl eax,4
	shl ecx,4
	add eax,16
	add ecx,16
	mov ebx,0x40502		// category 4 = "economy changes"
	mov dx,newstext(lmilloutoftrees)

	// and show the message
	call dword [newsmessagefn]
	pop ecx
	pop ebx
	pop eax
	
.notenough:
	and byte [esi+industry.prodrates+1],0	// reset counter
	clc	// need to clear carry to exit the loop
	ret

// Called after successfully cutting a tree.
// safe: none
global lmillcuttree2
lmillcuttree2:
	add word [esi+industry.amountswaiting],45	// overwritten
	jae .noprodoverflow				// by the

	mov word [esi+industry.amountswaiting],0xffff	// runindex call

.noprodoverflow:
	add byte [esi+industry.prodrates+1],1	// inc wouldn't set the flags
	jae .nocutcountoverflow

	mov byte [esi+industry.prodrates+1],0xff

.nocutcountoverflow:
	ret

// News message when a crashed Zeppelin has been cleared from an airport
// in:	esi -> Zeppelin about to be cleared
//	edi -> station where the Zeppelin is
// safe: eax,ebx,ecx,edx

global clearzeppelin
clearzeppelin:
	btr word [edi+station.airportstat],7 // overwritten by the call
	mov dl, [edi+station.owner]
	cmp dl, [human1]
	jne .exit

	mov edx,newsdata(zeppelincleared,5)
	mov ebx,edi
	call newsmsgwithstation
.exit:
	ret

// The same with crashed aircrafts
// in:	esi -> aircraft to be cleared
//	ebx -> station where the aircraft is
// safe: eax,ebx,ecx,edx

global clearcrashedaircraft
clearcrashedaircraft:
	btr word [ebx+station.airportstat],ax // overwritten by the call
	mov dl, [ebx+station.owner]
	cmp dl, [human1]
	jne .exit

	mov edx,newsdata(aircraftcleared,5)
	call newsmsgwithstation
.exit:
	ret

// Shows a news message with the given text centered on the given vehicle
// textrefstack contains the name of the given station
// in:	ebx -> station
//	dx: message ID
//	esi -> vehicle
// destroys eax,ebx,ecx,edx
newsmsgwithstation:
	push edx
	mov edx,textrefstack
	mov eax,[ebx+station.name]
	mov [edx],eax
	mov ecx,[ebx+station.townptr]
	mov eax,[ecx+town.citynametype]
	mov [edx+2],eax
	mov eax,[ecx+town.citynameparts]
	mov [edx+4],eax
	movzx eax,word [esi+veh.xpos]
	movzx ecx,word [esi+veh.ypos]
	mov ebx,eax
	shr ebx,4
	shl ecx,4
	mov bh,ch
	shr ecx,4
	mov [newsitemparam],ebx
	pop edx
	mov ebx,edx
	mov bx,0x0502
	call dword [newsmessagefn]
	ret

uvarw lastcleardate	// used to prevent multiple news messages when multiple trains are cleared

// called for every wagon of the crashed train being cleared
// in:	esi -> wagon being cleared
//	edi -> wagon before [esi] in the consist
// safe: eax,ecx,edx,ebp
global clearcrashedtrain
clearcrashedtrain:
	testflags pathbasedsignalling
	jnc .nopathsig

	call clearcrashedtrainpath

.nopathsig:
	mov word [edi+veh.nextunitidx],-1	// overwritten by the runindex call
	mov al,[esi+veh.owner]
	cmp al,[human1]
	jne .exit
	cmp esi,edi
	jne .exit
	mov ax,[lastcleardate]
	add ax,3
	mov cx,[currentdate]
	cmp ax,cx
	ja .exit

	mov [lastcleardate],cx

	mov	edx,newsdata(traincleared,5)
	call	newsmsgwithnearesttown
.exit:
	ret
