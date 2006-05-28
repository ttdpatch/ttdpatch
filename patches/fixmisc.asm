//
// Miscellaneous general fixes
//

#include <std.inc>
#include <flags.inc>
#include <textdef.inc>
#include <vehtype.inc>
#include <station.inc>
#include <bitvars.inc>
#include <human.inc>
#include <window.inc>
#include <veh.inc>
#include <town.inc>
#include <player.inc>
#include <industry.inc>
#include <patchdata.inc>
#include <misc.inc>
#include <view.inc>
#include <ptrvar.inc>
#include <house.inc>
#include <newvehdata.inc>
#include <grf.inc>

extern CalcTrainDepotWidth,GetMainViewWindow,RefreshLandscapeRect,Sleep
extern TransmitAction,UpdateStationAcceptList,aircraftbboxtable
extern checkrandomseed_actionnum,closecompanywindows,coloryear,ctrlkeystate
extern curplayerctrlkey,curtooltracktypeptr,didupdateacsprite,errorpopup
extern expswitches,getroadowner,getroutemap,gettextwidth,getvehiclescore
extern houseavailyears,incomequarterstatslist,isengine,ishumanplayer
extern isremoteplayer,lastextrahousedata,lastkeyremapped,maglevclassadjust
extern maprefreshfrequency,miscmodsflags,newhouseyears,newvehicles
extern orgsetsprite,patchflags,realcurrency,redrawscreen,resheight,reswidth
extern setroadowner,sigbitsonpiece,newvehdata,currwaittime
extern stationarray2ofst,stationarray2ptr,tmpbuffer1,townarray2ofst
extern trainrunningcost,ttdtexthandler,vehdirectionroutemasks
extern yeartodate
extern spriteblockptr,gettextintableptr,gettextandtableptrs
extern waterbanksprites



//
// Fix the bug that crashes TTD if one tries to play a scenario with running road vehicles
//

// Strip the high-order bit when adding roadtrafficside to BL
global getrvmovementbyte1
getrvmovementbyte1:
	add bl,[roadtrafficside]	// overwritten by the call
	and bl,0x7f
	ret
; endp getrvmovementbyte1 

// same for DL
global getrvmovementbyte2
getrvmovementbyte2:
	add dl,[roadtrafficside]	// overwritten by the call
	and dl,0x7f
	ret
; endp getrvmovementbyte2 


// fix the screenshot hotkeys under Windows
// Windows and DOS: prevent multiple screenshots, allow remapping of Ctrl-G and Ctrl-S
// in:	ebx=address of Ctrl key in keypresstable
// out:	ZF if screenshot will be taken, NZ if not
//	AH=screenshot type (1 or -1) if ZF
// safe:eax ebx ecx edx
global checkscreenshotkeys
checkscreenshotkeys:
	mov ah,0

	// check if the key was remapped (see patches/kbdhand.asm)
	cmp byte [lastkeyremapped],0
	jz .allowed

	bt dword [uiflags],10
	jc .notctrls

.allowed:
	// check key states

#if WINTTDX
%assign KEY_G_OFFSET 54
%assign KEY_S_OFFSET 66
#else
%assign KEY_G_OFFSET -KEY_LCtrl+0x22
%assign KEY_S_OFFSET -KEY_LCtrl+0x1f
#endif

	mov al,[ebx]    		// Ctrl pressed?
	or al,[ebx+KEY_G_OFFSET]	// G pressed?
	jnz short .notctrlg

	mov ah,-1
	mov byte [ebx+KEY_G_OFFSET],0x80	// force G to be released
					// otherwise hundreds of screenshots will be made

.notctrlg:
	mov al,[ebx]
	or al,[ebx+KEY_S_OFFSET]	// Ctrl-S?
	jnz short .notctrls

	mov ah,1
	mov byte [ebx+KEY_S_OFFSET],0x80	// same here

%undef KEY_G_OFFSET
%undef KEY_S_OFFSET

.notctrls:	// set zero flag if ah!=0

	call screenshotgrfid

	mov al,ah
	and al,1
	dec al
	ret
; endp checkscreenshotkeys
	

#if WINTTDX
var screenshotgrfidbytes
	db 32, 16, 17, 26, 53, 60, 72, 80, 88, 106, 107, 112, 122, 128, 136, 154
#else
var screenshotgrfidbytes
	db  6, 16, 17, 26, 53, 60, 72, 80,  4,   5, 107, 112, 122, 128,   3, 154
#endif


screenshotgrfid:
	test dword [miscmodsflags],MISCMODS_NOGRFIDSINSCREENSHOTS
	jz .enabled
	ret
.enabled:
	cmp al, 0
	jz .addgrfidlist
	ret
.addgrfidlist:
	cmp byte [gamemode], 1
	jz .normalgame
	ret
.normalgame:
	pusha
#if WINTTDX
	mov edi, [sFullScreenUpdateBlock+scrnblockdesc.buffer]
	movzx ebx, word [reswidth]
#else
	push es
	les edi, [sFullScreenUpdateBlock+scrnblockdesc.buffer]
	mov ebx,640
#endif
	imul ebx, 21
	add edi, ebx
	
	mov ecx, 16
	mov esi, screenshotgrfidbytes
	rep movsb

	mov ecx, 16
	mov esi, [spriteblockptr]
.next:
	cmp ecx, 630
	jge .nomore

	mov esi,[esi+spriteblock.next]
	test esi,esi
	jle .nomore

	test byte [esi+spriteblock.active],1
	jz .next
	
	mov eax, [esi+spriteblock.grfid]
	cmp eax, -1
	jz .next

	xor ebx, ebx

	mov edx, 0
.nextbits:
	mov bl, al
	and bl, 0xF
	shr eax, 4
	mov bl, byte [screenshotgrfidbytes+ebx]
	mov byte [es:edi+edx], bl
	add edx, 2
	cmp edx, 16
	jb .nextbits

	add edi, 16
	add ecx, 16
	jmp .next
.nomore:
#if !WINTTDX
	pop es
#endif
	popa
	ret
// If an aircraft is taking off and needs to go to hangar,
// prevent it from landing back unnecessarily
// in:	ESI->vehicle
// out:	EDX=AH=target airport
// safe:AL
global gettargethangar
gettargethangar:
	mov al,byte [esi+veh.aircraftop]
	cmp al,0xd
	jb short .normal
	cmp al,0x10
	ja short .normal

	// taking off, check its current order
	mov ax,word [esi+veh.currorder]
	and al,0x1f
	dec al
	cmp al,1
	jbe short .done

.normal:
	mov ah,byte [esi+veh.targetairport]

.done:
	movzx edx,ah
	ret
; endp gettargethangar 


	// this is called when the computer decides whether to
	// call the ai building function for a player
	// in:	al=current player
	//	esi->player
	// out:	zero if player is human
	//	nz and al=fe (or any number other than 0-7, ff)
	//	if player is not human
	// safe:eax edx others?
global aibuilding
aibuilding:
	push byte PL_ORG
	call ishumanplayer
	jz short .haveit

	// also, if experimentalfeatures.cooperative is on, 75% owned AI counts as player
	testmultiflags experimentalfeatures
	jz .isai
	test byte [expswitches],EXP_COOPERATIVE
	jz .isai

	// see if any player owns 75%
	mov eax,[esi+player.shareowners]	// eax = ABCD
	cmp al,ah	// C == D -> this player must own one more
	je .havetwo
	rol eax,16
	cmp al,ah
	jne .isai	// C != D, A != B -> no player holds 75%

.havetwo:	// found two equal shares (in AH,AL), need one more
	cmp al,0xff
	je .isai	// but they were non-owned shares!
	mov dl,al	// one of the other two shares must equal this one
	rol eax,16
	cmp dl,al
	je .haveit
	cmp dl,ah
	je .haveit

.isai:
	mov al,0xfe
	test al,al	// clear ZF
.haveit:
	ret
; endp aibuilding 

	// same as above but for ai station rating bonus
global aistationrating
aistationrating:
	push byte PL_ORG | PL_PLAYER
	mov [esp+1],ah
	call ishumanplayer
	jz short .haveit
	mov ah,0xfe
.haveit:
	ret
; endp aistationrating 


	// called after TTD creates the data for human players
global makenewhumans1
makenewhumans1:
	mov byte [gamesemaphore],0	// overwritten

makenewhumans:
	mov al,[realcurrency]
	mov [landscape3+ttdpatchdata.realcurrency],al

	mov eax,[human1]
	mov [landscape3+ttdpatchdata.orgpl1],ax
	ret

	// also done when starting a scenario
	// clear town stats accumulated in the editor
	// while we're at it (but only if generalfixes is enabled)
global newscenarioinit
newscenarioinit:
	testflags generalfixes
	jnc .dontclearstats

	mov esi,townarray
	mov ecx,[townarray2ofst]
	mov bl,numtowns
	xor eax,eax

.clrstatsloop:
	mov [esi+town.maxpassacc],eax		// also clears .maxmailacc
	mov [esi+town.actpassacc],eax		// also clears .actmailacc
	mov [esi+town.foodthismonth],eax	// also clears .waterthismonth
	jecxz .clrnext
	mov [esi+ecx+town2.passthismonth],eax	// also clears .mailthismonth
	mov [esi+ecx+town2.goodsthismonth],eax	// also clears the next field (currently reserved)

.clrnext:
	add esi,byte town_size
	dec bl
	jnz .clrstatsloop

.dontclearstats:
	call $
ovar .origfn,-4,$,newscenarioinit
	jmp makenewhumans


	// the following functions are called when TTD finds the name
	// of a player.  If it's a human player, add the suffix "player 0/1"
	// if it's a human player currently managing a subsidiary,
	// add suffix "managed by player x"
	// if it's the original company of a player, add "owned by player"
global playertype1
playertype1:
	push eax
	push ebx

	call findplayername

	mov [textrefstack+6],ax

	pop ebx
	pop eax

	cmp al,0x7f	// definitely clears zero flag

	ret
; endp playertype1 

global playertype2
playertype2:
	push ebx

	mov al,dl
	call findplayername

	pop ebx

	jc short .ishuman
	xor ecx,ecx	// allow buying shares

.ishuman:

	xor dl,dl
	ret
; endp playertype2 

global playertype3
playertype3:
	push eax
	push ebx

	mov al,bl
	call findplayername

	mov [textrefstack+8],ax

	pop ebx
	pop eax
	ret
; endp playertype3 

global playertype4
playertype4:
	push eax
	push ebx

	mov al,bl
	call findplayername

	mov [textrefstack+6],ax

	pop ebx

	mov bl,0xfe
	or bl,bl

	pop eax
	ret
; endp playertype4 

	// finds out which suffix to use, and returns it in ax
	// in:	al=player id
	// out:	ax=suffix text id
	//	carry=is human
	// destroys ebx
findplayername:
	cmp byte [numplayers],1
	je .single
#if WINTTDX
	testflags enhancemultiplayer
	jc .newmulti
#endif

.single: 
	mov ebx,[human1]

	mov ah,0
	cmp al,bl
	je short .human		// is human 1

	inc ah
	cmp al,bh
	je short .human		// is human 2

	mov ah,0
	mov ebx,[landscape3+ttdpatchdata.orgpl1]

	cmp al,bl
	je short .gotit		// is org. human 1

	inc ah
	cmp al,bh
	je short .gotit		// is org. human 2

	// not human in any way
	inc ah
	clc
	jmp short .nothuman

.gotit:
	stc

.nothuman:
	movzx eax,ah
	mov ax,word [nosplit playersuffixtypes+eax*2]
	ret

.human:
		// check if human has another company
	movzx ebx,ah
	cmp al,[landscape3+ttdpatchdata.orgpl1+ebx]

	je short .gotit
	add ah,3
	jmp short .gotit

#if WINTTDX
.newmulti:
	cmp al,[human1]
	jne .notlocal
	mov ax,ourtext(localplayer)
	stc
	ret

.notlocal:
	movzx eax,al
	bt dword [isremoteplayer],eax
	jnc .notremoteeither
	mov ax,ourtext(remoteplayer)
	ret

.notremoteeither:
	mov ax,6
	ret
#endif
 
	align 2
var playersuffixtypes, dw 0x7002,0x7003,6
	dw ourtext(managedby1),ourtext(managedby2)
; endp findplayername 


// Fix the bug in the display of a train engine running cost
// (in the 'New Vehicles' and 'New Locomotive Available' windows)
// in:	EBX=vehicle ID
// out: EAX=running cost multiplier
global gettrainrunningcost
gettrainrunningcost:
//	mov	eax,dword [enginepowerstable]
	movzx	eax,byte [trainrunningcost+ebx]	// MOVZX instead of the original MOV...
	ret
; endp gettrainrunningcost

// Fix a crash when displaying exclusive offer of new wagon
// in:	esi=runningcostbaseptr
// out:	eax*[esi]>>8 unless esi==0
global gettrainrunningcostmultiplier
gettrainrunningcostmultiplier:
	test esi,esi
	jz .norunningcost
	mov esi,[esi]
.norunningcost:
	imul eax,esi
	shr eax,8
	ret


// Prevent TTD house building procedure from going into an infinite loop if year<1930
// out:	AX=date (possibly fake)
// safe:everything else
global buildhousegetdate
buildhousegetdate:
	// find the lowest availability start year (normally 10)
	mov esi,[houseavailyears]
	xor ecx,ecx
	mov cl,110
	xor eax,eax
	mov al,255

.typeloop:
	cmp [esi],al
	jae .next
	mov al,[esi]

.next:
	inc esi
	inc esi
	loop .typeloop

	testflags newhouses
	jnc short .noextrahouses

	mov esi,newhouseyears+2*129
	mov cl,[lastextrahousedata]
	jecxz .noextrahouses

.extratypeloop:
	cmp [esi],al
	jae .extranext
	mov al,[esi]

.extranext:
	inc esi
	inc esi
	loop .extratypeloop

.noextrahouses:

	call yeartodate

	mov eax,[currentdate]	// (overwritten)
	cmp ax,bx
	jae short .done
	mov eax,ebx		// pretend it's already that year
.done:
	ret
; endp buildhousegetdate


// Fix bug which causes crash if TTD runs out of special "vehicles" for
// bubbles (from bubble generators in toyland climate)
// in:	edi=new bubble "vehicle"
global initbubble
initbubble:
	pop eax
	or edi,edi
	jz short .novehicles
	mov word [edi+veh.currentload],ax

.novehicles:
	pop ebx
	ret
; endp initbubble 

// Fix bug with shares owned by a company that's bought out or sold out
// in:	dl=company ID
//	dh=new owner (FF if sold out)
// out:	esi=vehicle array
// safe:eax,(esi)
global companysold
companysold:
	pusha
	mov eax,dword [playerarrayptr]

	xor ecx,ecx
	mov cl,8	// check 8 players

.checkplayer:
	cmp word [eax+player.name],byte 0
	je short .nextplayer

	push ecx

	mov cl,4

.nextshare:	// any shares owned by the company to be removed?
	cmp byte [eax+player.shareowners+ecx-1],dl
	jne short .notowner

	mov byte [eax+player.shareowners+ecx-1],dh

.notowner:
	loop .nextshare

	pop ecx

.nextplayer:
	add eax,player_size
	loop .checkplayer

	mov bh,dl
	call callclosecompanywindows

	popa

	mov esi,[veharrayptr]
	ret
; endp companysold 

// because closecompanywindows pops cx and ax, we can't call it directly
callclosecompanywindows:
	push ax
	push cx
	jmp dword [closecompanywindows]


// Fix display of amount in litres, the multiplier should be 1000 not 100
global amountinlitres
amountinlitres:
	movsx eax,word [textrefstack]	// overwritten by runindex call
	imul eax,byte 10
	ret
; endp amountinlitres


// Fix zoom level of giant screenshot not to change
global rememberzoomlevel
rememberzoomlevel:
	mov esi,[esi+0x16]
	mov al,[esi+0x10]
	mov [curzoomlevel],al
	mov ax,[esi+8]
	ret

global makegiantscreenshot
makegiantscreenshot:
	mov edx,0x7f707f7 + (1 << 0x1e)		// old value plus bit 1e
	xor eax,eax
	mov cl,0
ovar curzoomlevel, -1
	ret


//
// Fix food/fizzy drinks subsidies
//

// Fix display of food subsidies
// in:	ESI->subsidy (source is an industry)
//	AL=cargo type (i.e. byte [ESI])
// out:	ZF set if the target is a town (i.e. cargo is goods/candy (sweets) or food/fizzy drinks), clear otherwise
// safe:EBP,EBX(saved) (we don't need them anyway)
global issubsidytotown1
issubsidytotown1:
	mov [textrefstack+6],ebx	// overwritten by runindex call
	cmp al,5			// this is what the original code checks...
	jz .done
	cmp al,11			// ...and this is what it fails to check
.done:
	ret
; endp issubsidytotown1

// Fix food subsidy award check
// in:	CH=cargo type
// out:	ZF set if the target is a town, clear otherwise
global issubsidytotown2
issubsidytotown2:
	cmp ch,2		// overwritten
	jz .done
	cmp ch,5		// ditto
	jz .done
	cmp ch,11
.done:
	ret
; endp issubsidytotown2

// Make food and sweets subsidies possible to medium-sized towns
// in:	EDI->town (randomly selected)
//	EBX->industry which is the cargo source
//	CL=cargo type
// out:	CF set if town's population is too low, clear if it's OK
// safe:EAX,EDX
global chksubsidytotown
chksubsidytotown:
	cmp byte [climate],3
	jz .toyland

	cmp cl,11
	jne .goods

.food:
	cmp word [edi+town.population],400	// same as passenger subsidies
	ret

.toyland:
	// in toyland, it's the reverse:
	// almost all town buildings accept sweets (cargo 5), but only few accept fizzy drinks (cargo 11)
	cmp cl,5
	je .food

.goods:
	cmp word [edi+town.population],900	// the original check, overwritten by runindex call
	ret
; endp chksubsidytotown


// Prevent bad things from happening if the target station of a subsidy changes its owner to N/A
// in:	EAX->station
// out: CF set if the station is owned by a company, clear otherwise
//	EAX=owner*player_size if CF=1
// safe:EBX
global getsubsidyowner
getsubsidyowner:
	movzx eax,byte [eax+station.owner]
	cmp al,8
	jnb .fin
	imul eax,player_size
	stc
.fin:
	mov word [textrefstack+0x12],0x1A6	// "N/A" (owner)
	ret
; endp getsubsidyowner

%define maxsubsidies 8

// When a station is deleted from the station array, remove references to it in the subsidy array
// as well as the vehicle cargo sources and waiting station cargo
// in:	ESI->station being deleted
//	AL=station idx
// out: EDI->start of vehicle array
// safe:EBP,DX
global deletestationrefs
deletestationrefs:
	mov edi,subsidyarray
	mov dl,maxsubsidies

.loop:
	cmp byte [edi+subsidy.cargo],-1
	jz .next
	cmp byte [edi+subsidy.age],12
	jb .next
	cmp al,[edi+subsidy.from]
	jz .delete
	cmp al,[edi+subsidy.to]
	jnz .next

.delete:
	mov byte [edi+subsidy.cargo],-1

.next:
	add edi,byte subsidy_size
	dec dl
	jnz .loop

	mov edi,[veharrayptr]
.checknext:
	cmp byte [edi+veh.class],0
	je .nextveh
	cmp word [edi+veh.currentload],0
	je .nextveh
	cmp byte [edi+veh.cargosource],al
	jne .nextveh

	mov word [edi+veh.currentload],0

.nextveh:
	sub edi,byte -veh_size
	cmp edi,[veharrayendptr]
	jb .checknext

	mov edi,[stationarrayptr]
	mov dl,numstations
.checkstat:
	cmp word [edi+station.XY],0
	je .nextstat

	xor ebp,ebp
.checkcargo:
	cmp byte [edi+station.cargos+ebp+stationcargo.enroutefrom],al
	jne .nextcargo

	and word [edi+station.cargos+ebp+stationcargo.amount], 0
	mov byte [edi+station.cargos+ebp+stationcargo.timesincevisit], 0
	mov byte [edi+station.cargos+ebp+stationcargo.enroutefrom], 0xFF
	mov byte [edi+station.cargos+ebp+stationcargo.rating], 175
	mov byte [edi+station.cargos+ebp+stationcargo.lastspeed], 0
	mov byte [edi+station.cargos+ebp+stationcargo.lastage], -1

.nextcargo:
	add ebp,byte stationcargo_size
	cmp ebp,12*stationcargo_size
	jb .checkcargo

.nextstat:
	add edi,station_size
	dec dl
	jnz .checkstat

	mov edi,[veharrayptr]		// overwritten by runindex call
	ret
; endp deletestationrefs


// Fix aircraft's notional size when on ground
// (currently used only if buildonslopes is on)
// in:	ESI->vehicle
//	EBX=current aircraft operation code (veh.aircraftop)
global dispatchaircraftop
dispatchaircraftop:
	push ebx
	mov [didupdateacsprite],bh	// bh=0
	call [dword ebx*4-1]
ovar .optable,-4,$,dispatchaircraftop
	pop ebx
	cmp bl,[esi+veh.aircraftop]
	je .ok
	cmp [didupdateacsprite],bh	// bh still 0
	jne .ok

	// aircraft op changed, but sprite didn't; update sprite

	push esi
	movzx eax,byte [esi+veh.class]
	movzx ebx,byte [esi+veh.direction]
	call [orgsetsprite+(eax-0x10)*4]
	pop esi

.ok:
	movzx ebx,word [esi+veh.nextunitidx]
	shl ebx,vehicleshift
	add ebx,[veharrayptr]

	mov ax,0x202
	cmp byte [esi+veh.xsize],0x10
	jae .shadow

	mov al,byte [esi+veh.direction]
	and eax,byte 3
	mov eax,[aircraftbboxtable+eax*2]
	mov [esi+veh.xsize],ax

.shadow:
	mov [ebx+veh.xsize],ax
	ret
; endp dispatchaircraftop


// Make difficulty settings window show initial loan size properly
// Old code shows the money divided by 1000 and adds a ",000" suffix to it.
// This isn't correct if the thousand separator isn't comma (DM, FF, Pt) and
// if the position of the currency symbol was changed by TTD Translator or
// the morecurrencies patch.
// Change the code to do a real multiply instead of this trick. Changing
// the according string is done in patches.ah.
//
// Called when textrefstack is about to be filled.
//
// In:	eax: number to put in textrefstack
//		epb: number of item in the list
//
// Out:	textrefstack filled correctly
//
// Safe:	eax, cx, dx

global showdifficultynums
showdifficultynums:
	cmp ebp,4
	jnz .default	// adjust initial loan size (number 4) only

	imul eax,1000
.default:
	mov [textrefstack],eax
	jmp near $		// instead of call to save a ret
ovar fndrawstring,-4


// Fix oilfield removal:
// delete the station only if there are no facilities left
// (otherwise stations 'taken over' by a player would screw up)
global fixremoveoilstation
fixremoveoilstation:
	test byte [esi+station.flags],1
	jz .done

	jmp near $
ovar .delstation,-4,$,fixremoveoilstation

.done:
	ret


// Make train break down for a long time when it collides with a road vehicle
global crashrv
crashrv:
	jnz .continue
	pop edi
	ret

.continue:
	movzx edi,word [edi+veh.engineidx]
	shl edi,7
	add edi,[veharrayptr]

	mov byte [edi+veh.breakdowncountdown],1
	mov byte [edi+veh.breakdowntime],0xff
	and word [edi+veh.speed],0
	call redrawscreen
	inc word [esi+0x68]
	or word [esi+veh.vehstatus],0x80
	ret

// called when marking an industry to be closed next month
// in: esi -> industry
// safe: eax,ebx,ecx,edx
global industryclosedown
industryclosedown:
	cmp byte [economy],0
	je .noclose
	mov byte [esi+industry.prodmultiplier],0	// overwritten by the
	movzx ebx,byte [esi+industry.type]		// runindex call
	ret

.noclose:
	pop ebx	// remove our return address and
	ret	// return to the caller's caller instead of creating a news message


// Make income stats still work even if the cash reaches the maximum value
// This one is for vehicle running costs
//
// in:	eax=previous cash amount
//	ebx->player struc
//	edx=amount to deducted from cash (plus carry)
//	flags from subtraction
// out:	--
// safe:edx
global dodeductvehruncost
dodeductvehruncost:
	jno .nooverflow

	mov [ebx+player.cash],eax

.nooverflow:
	sub eax,[ebx+player.cash]
	movzx edx,byte [currentexpensetype]
	add [ebx+player.thisyearexpenses+edx],eax
	jno .nooverfloweither

	sub [ebx+player.thisyearexpenses+edx],eax

.nooverfloweither:
	add edx,[incomequarterstatslist]
	mov edx,[edx]
	test edx,edx
	js .done

	add [ebx+player.thisquarterincome+edx],eax

	jno .done

	sub [ebx+player.thisquarterincome+edx],eax

.done:
	pop edx		// was saved by original procedure
	ret


// Same but for regular expenses
//
// in:	ebx=amount deducted
//	edx->player struc
//	flags from subtraction
// out:	--
// safe:edx
global doaddexpenses
doaddexpenses:
	jno .nooverflow

	add [edx+player.cash],ebx

.nooverflow:
	push eax
	movzx eax,byte [currentexpensetype]
	add [edx+player.thisyearexpenses+eax],ebx
	jno .nooverfloweither

	sub [edx+player.thisyearexpenses+eax],ebx

.nooverfloweither:
	add eax,[incomequarterstatslist]
	mov eax,[eax]
	test eax,eax
	js .done

	add [edx+player.thisquarterincome+eax],ebx
	jno .done

	sub [edx+player.thisquarterincome+eax],ebx

.done:
	pop eax
	ret

// When calculating the company value, limit it to the maximum too
//
// in:	eax=value so far
//	esi->player struc
//	flags from cmp [esi+player.cash],0
// out:	eax=company value (add cash)
// safe:?
global companyvalue
companyvalue:
	jle .done
	add eax,[esi+player.cash]
	jno .done
	mov eax,0x7fffffff
.done:
	ret

// fill textrefstack for the profit display in the vehicle list window
// in: edi -> vehicle
//	???
// safe: eax,ebx,edi,ebp,esi,???
global showprofitdata
showprofitdata:
	mov eax,[edi+veh.profit]
	mov [textrefstack],eax

	mov eax,[edi+veh.previousprofit]
	mov [textrefstack+6],eax
	mov bx,statictext(profit_black)
	cmp word [edi+veh.age],365*2	// don't color if less than 2 years old
	jb .foundid_noperf

	inc ebx

	testflags newperformance
	jc .newperf

	or eax,eax
	js .foundid_noperf
	inc ebx
	inc ebx
	cmp eax,10000
	jb .foundid_noperf
	inc ebx
	inc ebx
.foundid_noperf:
	mov word [textrefstack+10],6
	mov [textrefstack+4],bx
	ret

.newperf:
	mov ax,[lastperfcachereset]
	add ax,2
	cmp ax,[currentdate]
	jae .noreset

	pusha
	mov ecx,[newvehicles]
	mov edi,[perfcacheptr]
	mov al,-1
	rep stosb
	mov ax,[currentdate]
	mov [lastperfcachereset],ax
	popa

.noreset:
	movzx esi,word [edi+veh.idx]
	add esi,[perfcacheptr]
	mov al,[esi]
	cmp al,-1
	jnz .scorefound
	call getvehiclescore
	mov [esi],al

.scorefound:
	or al,al
	jz .foundid_perf
	inc ebx
	cmp al,2
	jbe .foundid_perf
	inc ebx
	cmp al,3
	jbe .foundid_perf
	inc ebx
	cmp al,5
	jbe .foundid_perf
	inc ebx

.foundid_perf:
	mov [textrefstack+4],bx
	mov word [textrefstack+10],ourtext(performance)
	mov [textrefstack+12],al
	mov byte [textrefstack+13],0
	ret

uvarw lastperfcachereset
uvard perfcacheptr,1,s

// Called to make news messages black and white
// safe: ???
global makenewsblackandwhite
makenewsblackandwhite:
	push eax
	movzx ax,byte [currentyear]
	add ax,1920
	cmp ax,[coloryear]
	pop eax
	jae .exit
	mov bp,0x4323	// overwritten by the
	call $		// runindex call
ovar .fillrectangle,-4,$,makenewsblackandwhite
.exit:
	ret

// sets the background color for the "new vehicle available" news messages
// out: color in bp
// safe: ???
global setnewsbackground
setnewsbackground:
	mov bp,103	// greenish background color
	push eax
	movzx ax,byte [currentyear]
	add ax,1920
	cmp ax,[coloryear]
	pop eax
	jae .exit
	mov bp,10	// default grey background color
.exit:
	ret

// decides whether a wagon can be appended to a consist
// in:	edi -> vehicle to check (at this point, it's surely a train)
//	ebx shr 8: source vehicle type
//	al: source sprite type (used by the old code)
// out:	zf set to allow
// safe: ???
global lookforsamewagontype
lookforsamewagontype:
	cmp byte [noattachnewwagon],0
	jne .exit
	cmp byte [edi+veh.subclass],4	// overwritten by the runindex call
	jnz .exit
	ror ebx,8
	cmp bx,[edi+veh.vehtype]
	pushf	// must preserve zf
	rol ebx,8
	popf
.exit:
	ret
uvarb noattachnewwagon

// Called when preparing new vehicle array entry
//
// in:	bl=action code
// out:	CF=1 if error
//	CF=0, SF=1, esi->entry if forced entry
//	CF=0, SF=0, ZF from cmp [curplayer],[human1]: use normal proc
// safe:ax esi
global preparenewveharrentry
preparenewveharrentry:
	test bl,1
	jz .normal
	xor esi,esi
	xchg esi,[forcenewvehentry]
	test esi,esi
	jz .normal
	cmp byte [esi+veh.class],0
	stc
	jne .done	// error, can't use this entry
	or al,0x80	// set SF
	mov ax,cx
	xchg ax,[esp+4]	// pop ax; push cx in caller's frame
	ret

.normal:
	mov al,[curplayer]
	cmp al,[human1]
	setne ah	// need to return CF=SF=0 but ZF from the cmp
	test ah,ah
.done:
	ret
uvard forcenewvehentry

// Called to decide if a Zeppelin can crash at a given station tile
// in: al: landscape5 value of the field
// out: cf set to allow crashing
global checkzeppelincrasharea
checkzeppelincrasharea:
	test word [miscmodsflags],MISCMODS_NOZEPPELINONLARGEAP
	jnz .onlysmall
	cmp al,0x42	// no heliports
	je .deny

	cmp al,8
	jb .deny
	cmp al,0x43
	ret

.onlysmall:
	cmp al,0x34
	jb .deny
	cmp al,0x42
	ret

.deny:
	clc
	ret


// Make the sprite sorting algorithm more stable

uvard currspritedescpp

// part 1: save pointer to the current entry in table of pointers to sprite descriptors
global savecurrspritedescptr
savecurrspritedescptr:
	mov [tempvar],edi	// overwritten by runindex call
	mov [currspritedescpp],edi
	ret

// part 2: use our pointer instead of tempvar and adjust it
global usecurrspritedescptr
usecurrspritedescptr:
	mov ebx,[currspritedescpp]
	add dword [currspritedescpp],4
	ret


// Fix the cost limit for towns when they're trying to level terrain for their expansion
global townraiselowermaxcost
townraiselowermaxcost:
	mov esi,[raiselowercost]
	shl esi,4
	ret


// choose how many options the track construction type menu will have
// (only used if unimaglev=3 and electrifiedrailway=off)
//
// in:	edx=>player
// out:	ecx=number of options
global trackconstmenusize
trackconstmenusize:
	movzx ecx,byte [edx+player.tracktypes]
	cmp ecx,3
	cmc
	sbb ecx,0
	ret

// decide what default to use for track construction type menu selection
//
// in:	cx=number of track types available (1..3)
//	esi=>window struct
// out:	cx=default track type (0..2)
//	set [esi+2a]=cx
// safe:?
global settracktypedefault
settracktypedefault:
	mov [esi+0x2a],cx
	dec ecx
	test byte [miscmodsflags+1],MISCMODS_NODEFAULTOLDTRACKTYPE>>8
	jnz .done
	mov cl,[landscape3+ttdpatchdata.lastrailclass]
	cmp cl,[esi+0x2a]
	jb .done
	mov cl,[esi+0x2a]
	dec ecx
.done:
	ret

// actually open track construction and remember previous choice
//
// in:	edx=track type selection
// out:	[set curtooltracktype]
// safe:eax ebx cx dx ebp
global opentrackconstruction
opentrackconstruction:
	cmp dl,1
	jne .done
	add dl,[maglevclassadjust]

.done:
	mov eax,[curtooltracktypeptr]
	mov [eax],dl
	mov [landscape3+ttdpatchdata.lastrailclass],dl
	ret


// Called when a ship can't enter a tile
// normal processing is to reverse the direction
// we additionally check if the reverse direction is still valid on the current tile
// and if not we try other directions to free ships stuck under bridges
// in:	ESI->ship
//	EBX=current direction
// safe:EAX,ECX,EDX,EBP
global turnbackship
turnbackship:
	xor bl,4		// overwritten by runindex call

	pusha
	movzx edi,word [esi+veh.XY]
	mov ax,4
	call [getroutemap]
	or al,ah
	and bl,3
	test al,[vehdirectionroutemasks+ebx]
	popa
	jnz .found

	// invalid direction, turn the ship 45 degrees clockwise
	inc ebx
	and ebx,7

.found:
	mov [esi+veh.direction],bl	// overwritten
	ret


// Prevent overflow in the cash limit calculation
// which would disable all LA actions
global townactionthreshold
townactionthreshold:
	jno .finish
	mov edx,0x7fffffff

.finish:
	mov ebp,[fundingbasecost]	// overwritten
	ret


// Called when finding the scale of a company graph window
//
// in:	ebp=>temp structure on stack with graph data
//	cl=companies left on stack (counts from max down to 1)
// out:	eax=[ebp+edx]
//	zero flag set if value not to be considered
// safe:(eax)
global findcompanygraphmax
findcompanygraphmax:
	movzx eax,byte [ebp+0x614]	// number of companies on graph
	sub al,cl
	bt [ebp+0x610],eax		// bit mask of companies to ignore
	cmc
	sbb eax,eax
	jnz .notignored

	ret

.notignored:
	mov eax,[ebp+edx]
	cmp eax,0x80000000
	ret


// Remember the fact that a construction action was transmittable to the other player
global newtransmitaction
newtransmitaction:
	or byte [actiontransmitflag],1
	jmp near $
ovar .oldfn,-4,$,newtransmitaction

uvarb actiontransmitflag

// If the current company is Player 1 and the action was not transmitted,
// don't record the XY in the player array (or else sync would be lost)
// out: ZF set=don't, clear=do record
// safe:ESI
global chkrecordactionxy
chkrecordactionxy:
	btr dword [actiontransmitflag],0
	jc .record

	// always safe in single player mode
	cmp byte [numplayers],1
	jz .record

	// always do it for the remote player and AIs
	push eax
	mov al,[curplayer]
	cmp al,[human1]
	pop eax
	jnz .record

	// unsafe, return with ZF set
	ret

.record:
	// do the overwritten part
	mov esi,eax
	or si,cx
	ret


// Record the control key state in the high bit(s) of ESI
// before (possibly) sending the action to the other player
global recordcurplayerctrlkey
recordcurplayerctrlkey:
	push eax
	mov al,[curplayer]
	cmp al,[human1]
	pop eax
	jne .done

	push byte CTRL_ANY+CTRL_MP
	call ctrlkeystate
	jnz .done
	bts esi,31

.done:
	or word [operrormsg2],byte -1		// overwritten
	ret

// Check the high bit(s) of ESI and set the control key state variable(s)
global setcurplayerctrlkey
setcurplayerctrlkey:
	cmp byte [actionnestlevel],0
	jnz .done

	btr esi,31
	setb [curplayerctrlkey]

.done:
	inc byte [actionnestlevel]	// overwritten
	ret


// Auxiliary: check if the current AI company can buy any engines from a given range
// in:	BL=first vehtype to check
//	BH=number of vehtypes to check
// out:	CF set=yes, clear=no
// uses:EAX,BX,ECX
canaibuyengines:
	movzx ecx,byte [curplayer]

.engloop:
	movzx eax,bl
	bt [isengine],eax
	jnc .next
	imul eax,0+vehtype_size
	add eax,vehtypearray
	cmp word [eax+vehtype.reliab],0x8a3d
	jb .next
	bt [eax+vehtype.playeravail],ecx
	jc .done

.next:
	inc bl
	dec bh
	jnz .engloop

	clc

.done:
aidonttryroute:
	ret

// Prevent AI from building routes if it can't buy engines for it
// (function call chained in)
// safe:everything except ESI
global aitrytrainroute
aitrytrainroute:
	mov bl,TRAINBASE
	mov bh,NTRAINTYPES
	call canaibuyengines
	jnc aidonttryroute
	jmp near $
ovar .origfn,-4,$,aitrytrainroute

global aitryairroute
aitryairroute:
	mov bl,AIRCRAFTBASE
	mov bh,NAIRCRAFTTYPES
	call canaibuyengines
	jnc aidonttryroute
	jmp near $
ovar .origfn,-4,$,aitryairroute

// Prevent AI from building a road route
// if there are no vehicles to carry this cargo type
// (function calls chained in)
// in:	ESI->company
//	CL=cargo type
//	EBX->source (industry or town)
//	EDI->destination (industry or town)
// out:	if cannot build then set CL to -1
// safe:EAX,EDX,EBP
global aitryroadcargoroute
aitryroadcargoroute:
	mov al,aicargovehtable.roadbase

aitryroadorshipcargoroute:
	pusha
	movzx eax,al
	add eax,aicargovehicles
	movzx ecx,cl
	mov bl,[eax+ecx*2]
	mov bh,[eax+(aicargovehtable.roadnum-aicargovehtable.roadbase)+ecx]
	or bh,bh
	jz .gotcf

	call canaibuyengines

.gotcf:
	popa
	jc near $
ovar goodairoutefnofst,-4

	mov cl,-1
	ret

// Similar for a ship route
// (uses the same original function)
global aitryshipcargoroute
aitryshipcargoroute:
	mov al,aicargovehtable.shipbase
	jmp aitryroadorshipcargoroute


// Prevent placing buoys at (0,0)
// in:	AX,CX=X,Y
//	BL=constr. flags
//	DX,DI,ESI from gettileinfo
// out:	ZF set if at (0,0)
// safe:EBP
global canplacebuoy
canplacebuoy:
	mov word [operrormsg2],0x304b	// overwritten
	mov ebp,eax
	or bp,cx
	ret


// Bulldoze signals when bulldozing track pieces
// in:	bl=action flags
//	bh=track piece
//	dx/esi/di from GetTileInfo
// out:	ZF=1 allowed
//	ZF=0 fail
// safe:ebx
global removetracksignals
removetracksignals:
	push eax
	movzx eax,bh
	bsf eax,eax
	mov al,[sigbitsonpiece+eax]
	and al,[landscape3+esi*2]
	jz .done	// no signals, allow

	test bl,1
	jz .done	// not doing it yet, but allow it

	xor [landscape3+esi*2],al
	test byte [landscape3+esi*2],0xf0
	jnz .signalsdone

	// was the last signal, clear "signals present" bit
	and byte [landscape5(si,1)],~0x40

.signalsdone:
	test al,0	// set ZF

.done:
	pop eax
	ret


// Prevent a crash when trying to save game with no player 1 (e.g. in scenario editor)
// out:	ESI=player 1
//	CF=0 if no player 1
global defaultsavetitle
defaultsavetitle:
	movzx esi,byte [human1]		// overwritten
	cmp esi,8
	ret


// Called for every class 2 tile on sellout/bankrupt
// in:	dl: landscape5 entry for the tile
//	dh: buyer or 0xff for bankrupt
//	ebx: tile XY
// safe: dx
// (A jump to the old wrong code was overwritten)
global roadsellout
roadsellout:
	and dl,0xf0	// overwritten
	cmp dl,0x10	// ditto
	jne .exit

	cmp dh,0xff
	jne .nobankrupt
	mov dh,0x10

.nobankrupt:
	mov [landscape3+ebx*2],dh
.exit:
	ret

// Called to take over a class 2 tile in the scenario editor
// The old code doesn't check road/railway crossings and sets the owner of the railway
// in:	al: new owner (a town)
//	ebx: tile XY
// safe: ecx
global townclaimroad
townclaimroad:
	test word [miscmodsflags],MISCMODS_NOROADTAKEOVER
	jz .continue
	cmp byte [human1],0x10
	jne .exit
	call getroadowner		// in abanroad.asm
	cmp cl,0x10
	jne .exit
.continue:
	mov cl,al
	call setroadowner		// in abanroad.asm
.exit:
	ret

// Called when the town delete function tries to demolish a tile.
// The old code doesn't work if player1 is a company (not 0x10),
// because the local authority will refuse to destroy the town buildings.
// Even this can fail for road tiles that have vehicles on it, so set
// an appropriate operrormsg1 for error popups.
global deletetown
deletetown:
	mov bl,0x41					// proceed even if LA doesn't allow it
	rol di,4					// overwritten
	mov word [operrormsg1],0x00b5		// Can't clear this area...
	ret


// Called to count how many rows are filled in the current depot
// in:	esi=>window
//	edi=>vehicle
//	bl=number of rows so far
//	cl=vehicle subclass (00 for train, 04 for wagon row)
// out:
// safe:cl,others?
global counttrainsindepot
counttrainsindepot:
	cmp ax,[edi+veh.XY]
	jne .done
	cmp byte [edi+veh.movementstat],0x80
	jne .done
	cmp cl,4
	je .done	// only count one row for wagon rows
	clc

	dec bl
	push edi
	push eax
.nextrow:
	call advancetonextrow
	inc bl		// doesn't touch CF
	jc .nextrow
	pop eax
	pop edi

	test al,0	// set ZF to add another row after returning

.done:
	ret
#if 0 //Now use CalcTrainDepotWidth instead of accessing this variable
var trainvehsperdepotrow, db 10	// Can be overwritten at any time by enhancegui!
#endif

// advance edi by as many vehicle as fit in a row
// returns CF and EDI=>next if train is not done, otherwise NC and ZF and DI=-1
advancetonextrow:
	pushf
	call CalcTrainDepotWidth
	popf
	sbb al,0

.next:
	movzx edi,word [edi+veh.nextunitidx]
	cmp di,byte -1
	je .done

	shl edi,vehicleshift
	add edi,[veharrayptr]
	dec al
	jnz .next

	stc

.done:
	ret

// Called when starting next row in depot
// in:	esi=>window
//	edi=>vehicle
// out:	CF if edi is determined to start a new row
// safe:ax,others?
global checktrainindepot
checktrainindepot:
	push eax
	xor eax,eax
	xchg eax,[nextrowoftrainveh]
	test eax,eax
	jz .notcontinued

	xchg eax,edi
	cmp dword [nextvehtocheck],0
	stc
	jne .gotrow
	mov [nextvehtocheck],eax
	jmp short .gotrow

.notcontinued:
	xchg eax,[nextvehtocheck]
	test eax,eax
	jz .notafterrow

	xchg eax,edi

.notafterrow:
	cmp byte [edi+veh.class],0x10
	jne .done

	cmp byte [edi+veh.subclass],0
	jne .done

	mov ax,[esi+6]
	cmp ax,[edi+veh.XY]
	jne .done

	cmp byte [edi+veh.movementstat],0x80
	jne .done

.gotrow:
	push edi
	call advancetonextrow
	jnc .nocontinuation

	mov [nextrowoftrainveh],edi

.nocontinuation:
	pop edi
	pop eax
	stc
	ret

.done:
	pop eax
	clc
	ret

// Called when displaying one row of a train
//
// in:	esi=>window
//	edi=>vehicle
// 	cx=x pos
//	dx=y pos
// out:	adjust cx
//	al=max. number of wagons to show
// safe:?
global showtrain
showtrain:
	add cx,0x15
	call CalcTrainDepotWidth
	cmp byte [edi+veh.subclass],0
	je .regular

	add cx,29
	dec al

.regular:
	ret

// Called to display the train number in the depot
//
// in:	esi=>window
//	edi=>vehicle
// out:	bx=text index, CF if continuation
// safe:bx,bp
global showtrainnum
showtrainnum:
	mov bx,statictext(continuedtrain)
	cmp byte [edi+veh.subclass],0
	stc
	jne .continued

	mov bx,0xe2
	mov bp,[edi+veh.maxage]
	clc

.continued:
	ret

// Called to display the red/green flag
//
// in:	esi=>window
//	edi=>vehicle
// out:	bx=sprite for flag
// safe:bx
global showtrainflag
showtrainflag:
//	mov bx,13	// 13 for "+", 774 for a white dot in the wrong place...
	cmp byte [edi+veh.subclass],0
	stc
	jne .continued

	mov bx,3090
	test byte [edi+veh.vehstatus],2

.continued:
	ret

// Called when click in train depot window
//
// in:	esi=>window
//	edi=>vehicle
//	al=rows remaining
// out:	adjust al
// safe:?
global depotclick
depotclick:
	cmp byte [edi+veh.movementstat],0x80
	jne .nope

	dec al		// is it this row?
	js .gotit

	push edi
	push ebx

	dec bl		// first slot on following rows is empty
	inc al		// counteract following dec

.nextrow:
	dec al
	jns .trynextrow

	// yep, right train
	add esp,8
.gotit:
	test al,al	// restore sign flag
	ret

.trynextrow:
	push eax
	call advancetonextrow
	pop eax
	jc .nextrow

	// that wasn't the right train
	pop ebx
	pop edi
.nope:
	test al,0	// clear sign flag
	ret

uvard nextrowoftrainveh
uvard nextvehtocheck


// Called when creating a new text effect
// in:	esi=texteffects
// out:	esi=place for new text effect
// safe:-
global findemptytexteffect
findemptytexteffect:

.checknext:
	cmp word [esi+texteffect.text],byte -1
	je .done
	add esi,byte texteffect_size
	cmp esi,texteffects_end
	jb .checknext

	// advance all text effects
	// (otherwise all of them would have the same age when building paused)
	pusha
	mov eax,[ophandler+0x14*8]
	mov eax,[eax+3*4]
	mov esi,[eax+1]
	lea esi,[eax+esi+5]		// convert call offset to absolute address
	call esi

	// then pick oldest one to replace
	or eax,byte -1
	mov esi,texteffects
.checkage:
	cmp ax,[esi+texteffect.timer]
	jb .notolder
	mov edi,esi
	mov ax,[esi+texteffect.timer]
.notolder:
	add esi,byte texteffect_size
	cmp esi,texteffects_end
	jb .checkage

	mov [esp+4],edi

	popa

.done:
	ret

// Called just before creating a drop-down menu.
// The old code puts the menu under the button even if it doesn't fit on the screen.
// We fix this by putting the menu above the button if it doesn't fit below it.
// in:	eax: (top shl 16) + left
//	ebx: (height shl 16) + width
//	esi -> parent window
//	ebp -> caller button
// safe: cx, dx
global makedropdownmenu
makedropdownmenu:
	rol eax,16	// make Y coordinates accessible
	rol ebx,16
	mov cx,ax	// does it end below the visible area? (the status bar takes 12 pixels)
	add cx,bx
	mov dx,[resheight]
	sub dx,12
	cmp cx,dx
	jl .ok
	mov ax,[ebp-0xc+windowbox.y1]	// correct position: the bottom should be
					// just above the caller button's "parent"
	add ax,[esi+window.y]
	sub ax,bx
.ok:
	rol eax,16	// restore original format
	rol ebx,16
	mov cx,0x3f	// overwritten
	mov dx,-1	// ditto
	ret

#if !WINTTDX
// Called to wait the rest of the tick time.
// Give away the rest of the timeslice after every check to reduce CPU usage.
global wait27ms
wait27ms:
	mov ax,[currwaittime]
	cmp [0x774d4],ax	// overwritten
	jnb .elapsed
	mov ax,0x1680		// release current VM timeslice
	int 0x2f
	jmp short wait27ms
.elapsed:
	ret

// same but without giving away time slices
global wait27ms_nogiveaway
wait27ms_nogiveaway:
	mov ax,[currwaittime]
	cmp [0x774d4],ax	// overwritten
	jb wait27ms_nogiveaway
	ret

// calculate how many simulation ticks to advance
global calcsimticks
calcsimticks:
	xor dx,dx
	mov cx,[currwaittime]
	ret


// The same thing, called in a loop while the title screens are showing
// Return elapsed time in ax
global waittitle
waittitle:
	mov ax,0x1680
	int 0x2f
	mov ax,word [ss:0x774d4]
	ret

// Called while showing the high-score table and the game end screen
// Give away timeslices here as well.
global waitforkey
waitforkey:
	cmp ax,[0x7f9d6]	// overwritten
	jna .exit
	push eax
	mov ax,0x1680
	int 0x2f
	pop eax
.exit:
	ret
#endif

#if WINTTDX
global waitforkey
waitforkey:
	pusha
	push dword 30			// should be at least 27
	call dword [Sleep]
	popa
	cmp [dword 0],ax		// overwritten
ovar .timeroffset, -4, $, waitforkey
	ret
#endif

// the hint-array is too short in the lorry station selection window, so right-clicking on the
// last two buttons causes Bad Things. Fix this by specifying a correct version here and redirecting
// the according function to this array.

var lorryhints, dw 0x18b,0x18c,0,0x3052,0x3052,0x3052,0x3052,0x3065,0x3064

// Fix useless fences bug
// For some reason, TTD doesn't remove fences that don't have farmland on either side,
// unless they're in a desert or a snowy area. Pretend snow or desert everywhere
// where there isn't farmland.
// in:	dl: type of current tile: 2-farmland 1-snow or desert 0-something else
//	dh: the same with the neighbour tile
global updatehedges1
updatehedges1:
	or dl,dl
	jnz .noincdl
	inc dl
.noincdl:
	or dh,dh
	jnz .noincdh
	inc dh
.noincdh:
	test word [landscape3+2*ebx],0xe000	// overwritten
	ret

// The same, but in the other direction. Dl wasn't touched, so check dh only.
global updatehedges2
updatehedges2:
	or dh,dh
	jnz .noincdh
	inc dh
.noincdh:
	test word [landscape3+2*ebx],0x1c00	// overwritten
	ret

// Called to find out how many cargo icons should be displayed in a station window.
// The old code could cause a divide overflow, and using an incorrect result.
// Report 255 if the result would be bigger than that.
// In:	ax: amount of cargo waiting + 5
// Out:	al: ax/10
// Safe: dx
global calciconstodraw
calciconstodraw:
	xor dx,dx
	push ecx
	mov cx,10
	div cx
	pop ecx
	or ah,ah
	jz .nooverflow
	mov al,0xff
.nooverflow:
	ret

// Called every tick to determine if the map should be updated
// In:	al: timer incremented every tick (stored in window.itemsoffset)
// Out:	zf clear to update top half
//	zf clear to update bottom part
//	exit caller to cancel redraw
// safe: ax,bx,dx,bp
global updatemap
updatemap:
	testflags enhancegui
	jnc .noenhancegui
	call CheckMapPosition
.noenhancegui:
	mov ah,[maprefreshfrequency]
	cmp al,ah
	jb .nooverflow
	xor al,al			// on overflow, reset timer
	mov [esi+window.itemsoffset],al
	or ah,ah			// and update the top
	ret

.nooverflow:
	shr ah,1		// if timer=frequency/2, update bottom
	cmp al,ah
	je .exit
	pop eax			// in other cases, update nothing
.exit:
	ret

// Called every tick to determine if the position of the map should be updated
// In:  esi: window
global updatemappos
updatemappos:
	call CheckMapPosition

	test al, 1Fh
	jnz .skipcaller
	test al, 20h
	ret
.skipcaller:
	pop eax
	ret

// Called to update the position of the map 
global CheckMapPosition
CheckMapPosition:
	bt dword [esi+window.activebuttons], 15
	jnc .return
	pusha
	call [GetMainViewWindow]
	mov edi, [edi+window.viewptr]
	mov cx, [edi+view.width]

	mov ax, [esi+window.width]
	sub ax, 28
	shl ax, 4
	sub cx, ax
	
	sar cx, 1
	add cx, [edi+view.x]
	sar cx, 2
	mov dx, [edi+view.height]
	
	mov ax, [esi+window.height]
	sub ax, 62
	shl ax, 4
	sub dx, ax

	sar dx, 1
	add dx, [edi+view.y]
	sar dx, 1
	sub dx, 20h
	mov ax, dx
	sub ax, cx
	add cx, dx
	and ax, 0FFF0h
	and cx, 0FFF0h
	mov [esi+window.data+0], ax
	mov [esi+window.data+2], cx
	mov word [esi+window.data+4], 0
	popa
.return:
	ret

// New route maps for depot tiles. The old code always put al into ah, making TTD assume that
// trains can go both ways in any depot. This for example could cause signals to go red un-
// necessarily.
// This solution is not perfect, however, because TTD still thinks that trains can go through
// the back wall of a depot, to the rails behind it. IMHO a perfect solution would need rewriting
// the routing algorithm.
var newdepotroutemaps, dw 0x100,0x200,1,2


// --------------------
//  Network play fixes
// --------------------

// Called before sending the end of actions signal.
// Send a randomfn-check action before the end of actions.
global transmitendofactions
transmitendofactions:
	cmp byte [numplayers],1		// overwritten
	jz .exit
	pusha
	cmp byte [gamemode],0		// title screens don't have to be synched
	jz .dontcheck
	mov edx,[randomseed1]		// check random seeds with an action
	mov edi,[randomseed2]
	xor eax,eax
	xor ecx,ecx
	xor ebx,ebx
	inc bl
	mov esi,checkrandomseed_actionnum
	call dword [TransmitAction]
.dontcheck:
	xor ah,ah			// clear zf
	sahf
	popa
.exit:
	ret

uvarb desynchtimeout

// TTDPatch action called by the above proc.
// If the local and remote random seeds differ, show a warning.
global checkrandomseed
checkrandomseed:
	test bl,1
	jz .justthecost
	cmp edx,[randomseed1]
	jnz .error
	cmp edi,[randomseed2]
	jz .noerror
.error:
	mov bl,[desynchtimeout]		// display warning every TTD day
	or bl,bl
	jnz .notagain
	mov byte [desynchtimeout],74
	pusha
	xor ax,ax			// show warning
	xor cx,cx
	mov bx,ourtext(desynch1)
	mov dx,ourtext(desynch2)
	call dword [errorpopup]
	popa
.noerror:
.justthecost:
	xor ebx,ebx
	ret

.notagain:
	dec bl
	mov [desynchtimeout],bl
	xor ebx,ebx
	ret


// --------------------------
//  End of network play fixes
// --------------------------

// Called while making an airplane crash.
// Airplanes have a zero XY in flight to avoid collision detection.
// XY used to remain zero after a crash, so you could even remove the airport from below the plane.
// Fix this by setting the XY value of the plane.
// safe: ax,cx,???
global crashplane
crashplane:
	or byte [esi+veh.vehstatus],0x80	// overwritten
	mov ax,[esi+veh.xpos]
	mov cx,[esi+veh.ypos]
	shr ax,4
	shr cx,4
	mov ah,cl
	mov [esi+veh.XY],ax
	ret

// The same with crashed Zeppelins
// safe: ax.dx
global crashzeppelin
crashzeppelin:
	and word [esi+veh.age],0		// overwritten
	mov ax,[esi+veh.xpos]
	mov dx,[esi+veh.ypos]
	shr ax,4
	shr dx,4
	mov ah,dl
	mov [esi+veh.XY],ax
	ret

// Called to fill operrormsg with an error message "xxx in the way"
// in:	esi-> vehicle in the way
//	operrormsg2="Aircraft in the way"
// out:	fill operrormsg2
global whatvehicleintheway
whatvehicleintheway:
	cmp byte [esi+veh.class], 0x12		// class 12h is definitely ship
	je .isship
	cmp byte [esi+veh.subclass],13		// submarines are ships, others are aircraft
	jae .isship
	ret

.isship:
	mov word [operrormsg2],0x980e		// "Ship in the way"
	ret


// Called when inserting the number of a vehicle into a news message
// We insert the name instead
// in:	esi=>vehicle
// out:	ebx=0x50a00 (new category)
//	set textrefstack
// safe:ax
global genvehmessage
genvehmessage:
	mov ax,[esi+veh.name]
	mov [textrefstack],ax
	mov al,[esi+veh.consistnum]
	mov ah,0
	mov [textrefstack+2],ax
	mov ebx,0x50a00
	ret

// Show vehicle status as colour in vehicle list
// in:	edi->vehicle
//	bl=1 if in depot, 0 otherwise
//	bp=maxage
// out:	bx=textid with colour
// safe:bx,esi,edi,bp
global showvehstat
showvehstat:
	sub bp,366
	cmp bp,[edi+veh.age]
	jnb .notold
	or bl,2
.notold:
	test byte [edi+veh.vehstatus],2
	jz .notstopped
	or bl,4
.notstopped:
	movzx esi,bl
	mov bx,[vehstatcol+esi*2]
	ret

	align 2
var vehstatcol
	// normal, in depot, old, old in depot
	dw   0xe2,    0x21f,0xe3, statictext(vehstat_olddepot)
	// same but stopped
	dw statictext(vehstat_stopped),0x21f
	dw statictext(vehstat_stoppedold),statictext(vehstat_olddepot)

// text IDs to change from, e.g., "Train ",7c to 80, with text to replace
// being found by text ID as well
	align 2
var vehnametextids, dw 0x8864,0x8814,0x902b,0x9016,0x9830,0x981c,0xa02f,0xa014
	dw -1,0x01a0,-1,0x01a1,-1,0x01a2
	dw -1,ourtext(vehiclelost),-1,ourtext(cantreverse)	// not newstext, we want the actual string data
	dw 0

%assign numvehnametexts ($-vehnametextids-2)/4

noglobal uvard oldvehtexts, numvehnametexts
var genericvehmsg, db 0x80,0x20,0x7c,0

// the following procedures work on the texts affected by the "use veh. name not number" patch
// these need some special attention to be translatable via GRFs

// back up all affected text pointers, so they can be restored if GRFs are disabled
// the texts are already fixed up by the patchproc at this point
exported backupvehnametexts
	pusha

	xor ecx,ecx
.nexttext:
	mov ax,[vehnametextids+ecx*4+2]
	call gettextandtableptrs
	mov [oldvehtexts+ecx*4],edi

	inc ecx
	cmp ecx,numvehnametexts
	jb .nexttext

	popa
	ret

// restore all the saved text pointers before GRFs are applied
exported restorevehnametexts
	pusha

	xor ecx,ecx
.nexttext:
	mov ax,[vehnametextids+ecx*4+2]
	mov ebx,[oldvehtexts+ecx*4]
	call gettextintableptr
	jnc .nosubtract
	sub ebx,eax
.nosubtract:
	mov [eax+edi*4],ebx

	inc ecx
	cmp ecx,numvehnametexts
	jb .nexttext

	popa
	ret

// fallback text, will expand to something like "Train 7??"
noglobal varb vehtextfallback, 0x80,"??",0

// after GRFs are applied, check if any of the special IDs are modified
// if this is the case, the text supplied by the GRF won't work, and we have little hope to
// fix it up as we do for original texts in the EXE
// instead, the GRF should supply the fixed-up replacements, or have its texts replaced by the fallback
exported fixupvehnametexts
	pusha

	xor ecx,ecx
	mov edx,ourtext(newtrainindepot)
.nexttext:
	mov ax,[vehnametextids+ecx*4+2]
	mov ebx,[oldvehtexts+ecx*4]
	call gettextandtableptrs

	cmp ebx,edi
	je .donetext			// if the pointer hasn't changed, we have nothing to do

	mov eax,edx			// edx holds the ID of the replacement text
	call gettextandtableptrs
	cmp byte [edi],0
	jne .havereplacement		// if the replacement text isn't empty, we can use it

	mov edi,vehtextfallback		// if it is, we have no choice but use the fallback

.havereplacement:

	mov ax,[vehnametextids+ecx*4+2]	// store the new pointer
	mov ebx,edi
	call gettextintableptr
	jnc .nosubtract
	sub ebx,eax
.nosubtract:
	mov [eax+edi*4],ebx

.donetext:
	inc ecx
	inc edx

	cmp ecx,numvehnametexts
	jb .nexttext

	popa
	ret

// Periodic class 6 (water) proc
// Floods water into adjacent flat non-water tiles
//
// in:	bx=tile
// out:
// safe:eax ecx esi edi ebp, others?
global class6periodicproc
class6periodicproc:
	test bl,bl
	jz .notne

	// flood to NE (-x)
	mov byte [esp-12], 0x0
	xor esi,esi		//  0  0
	mov ebp,0x100		// +1  0
	or eax,byte -1		// -1 -1
	mov edi,eax		// -1 -1
	lea ecx,[ebp-1]		//  0 -1
	call [floodtile]

.notne:

	test bh,bh
	jz .notnw

	// flood to NW (-y)
	mov byte [esp-12], 0x0
	xor esi,esi		//  0  0
	mov ebp,1		//  0  1
	mov eax,-0x100		// -1  0
	mov edi,eax		// -1  0
	lea ecx,[eax+1]		//  0 -1
	call [floodtile]

.notnw:
	cmp bl,0xfd
	ja .notsw

	// flood to SW (+x)
	mov byte [esp-12], 0x0
	mov edi,1		//  0  1
	mov esi,edi		//  0  1
	mov ebp,0x101		//  1  1
	lea eax,[edi+1]		//  0  2
	lea ecx,[ebp+1]		//  1  2
	call [floodtile]

.notsw:
	cmp bh,0xfd
	ja .notse

	// flood to SW (+y)
	mov byte [esp-12], 0x0
	mov edi,0x100		//  1  0
	mov esi,edi		//  1  0
	lea ebp,[edi+1]		//  1  1
	lea eax,[edi*2]		//  2  0
	lea ecx,[eax+1]		//  2  1
	call [floodtile]

.notse:
	// Only flood diagons if this bit has not been set
	test byte [miscmodsflags+2], MISCMODS_NODIAGONALFLOODING>>(8*2)
	jnz near .nodiagonalflooding

	cmp bh, 0x0
	je .notn
	cmp bl, 0x0
	je .notn
	// Tile to change
	mov edi, -0x0101 // -1 -1
	// Internal use only...
	mov byte [esp-12], 0x1 // Corner tile
	// Set the adjecent tile corner (north point)
	mov esi, 0x0000 // 0 0 (South corner)
	// Set the two close corners
	mov ecx, -0x0001 // +0 -1 (East corner)
	mov eax, -0x0100 // -1 +0 (West corner)
	// Set the furthest tile corner
	mov ebp, -0x0101 // -1 -1 (North corner)
	call [floodtile]

.notn:

	cmp bl, 0xFE
	jae .notw
	cmp bh, 0x0
	je .notw
	mov edi, 0xFFFFFF01 // -1 +1
	// Internal use only...
	mov byte [esp-12], 0x1 // Corner tile
	// Set the adjecent tile corner (north point)
	mov esi, 0x0001 // +0 +1 (South corner)
	// Set the two close corners
	mov ecx, 0x0002 // +0 +2 (East corner)
	mov eax, 0xFFFFFF01 // -1 +1 (West corner)
	// Set the furthest tile corner
	mov ebp, 0xFFFFFF02 // -1 +2 (North corner)
	call [floodtile]

.notw:
	cmp bh, 0xFE
	jae .nots
	cmp bl, 0xFE
	jae .nots
	mov edi, 0x0101 // +1 +1
	// Internal use only...
	mov byte [esp-12], 0x1 // Corner tile
	// Set the adjecent tile corner (north point)
	mov esi, 0x0101 // +1 +1 (South corner)
	// Set the two close corners
	mov ecx, 0x0201 // +2 +1 (East corner)
	mov eax, 0x0102 // +1 +2  (West corner)
	// Set the furthest tile corner
	mov ebp, 0x0202 // +2 +2 (North corner)
	call [floodtile]

.nots:
	cmp bh, 0xFE
	jae .note
	cmp bl, 0x0
	je .note
	mov edi, 0x00FF // +1 -1
	// Internal use only...
	mov byte [esp-12], 0x1 // Corner tile
	// Set the adjecent tile corner (north point)
	mov esi, 0x0100 // +1 0 (South corner)
	// Set the two close corners
	mov ecx, 0x0200 // +2 +0 (East corner)
	mov eax, 0x00FF // +1 -1 (West corner)
	// Set the furthest tile corner
	mov ebp, 0x01FF // +2 -1 (North corner)
	call [floodtile]

.note:
.nodiagonalflooding:
	ret

uvard floodtile		// function to flood adjacent tile

// New FloodTile subroutine to help with diagonal flooding
// This also adds a few bad tile conversion checks
// Input :
//	ebx - Base tile (offsets calculated from this)
//	edi - New tile offset
//	esi - One of the 2 joinging corner (With diagonal flooding this is the only joing corner)
//	ebp - Other joining corner (With Diagonal flooding this is the FURTHEREST corner)
//	eax - One of the 2 corners which do not touch the base tile
//	ecx - Other corner which doesn't touch the base tile
//	[esp-4] - The type of flooding to occur (value of 0x0 is normal, 0x1 is diagonal)
// Output:
//	Nothing?
// Safe: edx
global Class6FloodTile
Class6FloodTile:
	// Check the tile to change and it's class
	mov dl, [landscape4(di, 1)+ebx] // Get the tile Type and north corner height
	and dl, 0xF0 // Only keep the tile class
	cmp dl, 0x60 // Is this tile already class 6 (water or coast)
	jz .badcorners // If it is we don't want to flood it again, so quit

	cmp byte [esp-4], 0x1 // IS this diagonal flooding?
	je .diagonalflooding

	// Checks that the 2 base points are at sea level
	mov dl, [landscape4(si, 1)+ebx] // Get the tile types and corner hieghts
	mov dh, [landscape4(bp, 1)+ebx]
	and dx, 0x0F0F // Are the north tile points at sea level
	jnz .badcorners

	// Check if this is a slope and hense if to make it a coast
	mov dh, [landscape4(ax, 1)+ebx] // Get the tile types and corner hieghts
	mov al, [landscape4(cx, 1)+ebx]
	and dh, 0x0F // Is this corner at sea hieght
	jnz .coast // No, so make it a coast
	and al, 0x0F // Is this corner at sea hieght
	jnz .coast // No, so make it a coast
	cmp al, dh
	jnz .badcorners
	cmp al, dl
	jnz .badcorners
	jmp .plainwater

.badcorners:
	ret

// Following jumps, will set the return points back to the orginal subroutine
// in the sections that would change the tile to what is needed.

.plainwater:
	push edx
	mov dword edx, [floodtile]
	mov dword [esp+4], edx
	pop edx
#if WINTTDX
	add dword [esp], 0x61
#else
	add dword [esp], 0x4D
#endif
	ret

.coast:
	push edx
	mov dword edx, [floodtile]
	mov dword [esp+4], edx
	pop edx
#if WINTTDX
	add dword [esp], 0xFE
#else
	add dword [esp], 0xDE
#endif
	ret

// Handles diagonal flooding
.diagonalflooding:
	mov dl, [landscape4(si, 1)+ebx] // Get the tile types and corner hieghts
	and dl, 0x0F // Is this corner at sea level
	jnz .badcorners

	mov dh, [landscape5(bx, 1)] // Get the subtype of tile
	and dh, 0x0F // We are only interested in the subclass (0x0 to 0x2)
	cmp dh, 0x1 // Is this a coast tile?
	jnz .flat
	ret

.flat:

	// Special cases for diagonal flooding (allowed) for a FLAT tile
	mov dh, [landscape4(si, 1)+ebx]
	mov dl, [landscape4(cx, 1)+ebx]
	shl edx, 16
	mov dh, [landscape4(ax, 1)+ebx]
	mov dl, [landscape4(bp, 1)+ebx]
	and edx, 0x0F0F0F0F
	cmp edx, 0x00010100
	je .dbadcorners

	// If any other corners are raised it's a slope
	mov ax, dx
	shr edx, 16
	and ah, 0x0F
	jnz .coast
	and dl, 0x0F
	jnz .coast
	and al, 0x0F
	jnz .coast

	// Change this for the following checks
	cmp ah, dh
	jnz .dbadcorners
	cmp ah, al
	jnz .dbadcorners
	cmp ah, dl
	jnz .dbadcorners
	jmp .plainwater

.dbadcorners:
	ret

// Handles getting the sprites for the coasts, since 8 new types have appeared
global Class6CoastSprites, newcoastspritebase, newcoastspritenum
Class6CoastSprites:
	cmp edi, 0x20
	jb .goodoffset

// Alters the values for steep slopes so they can use the old array
	cmp edi, 0x2E
	jne .next1
	mov edi, 0x00
	jmp .goodoffset
.next1:
	cmp edi, 0x36
	jne .next2
	mov edi, 0x0A
	jmp .goodoffset
.next2:
	cmp edi, 0x3A
	jne .next3
	mov edi, 0x14
	jmp .goodoffset
.next3:
	mov edi, 0x1E

.goodoffset:
	cmp word [newcoastspritebase], -1
	jne .newsprites

.badnewsprites:
	push ecx
	mov ecx, [waterbanksprites]
	mov bx, [ecx+edi]
	pop ecx
	ret

.newsprites:
	cmp dword [newcoastspritenum], 0x10
	jne .badnewsprites
	mov bx, [newcoastspritebase]
	shr di, 1
	add bx, di
	ret

uvarw newcoastspritebase, 1, s
uvard newcoastspritenum

uvard tempSplittextlinesNumlinesptr,1,s
uvard SplittextlinesMaxlines,1,s

	// called after splittextlines is done
	// safe:cx
global splittextlines_done
splittextlines_done:
	mov edi,[tempSplittextlinesNumlinesptr]
	mov cx,[edi]
	or edi,byte -1
	xchg edi,[SplittextlinesMaxlines]
	cmp cx,di
	jbe .ok
	mov cx,di
.ok:
	xchg cx,di
	ret

#if WINTTDX
global comparefilenames
comparefilenames:
	mov al,[ebx]
	cmp al,'a'
	jb .notlower
	cmp al,'z'
	ja .notlower
	sub al,'a'-'A'
.notlower:
	cmp al,[esi]
	jz .normalexit
	add dword [esp],0x2d
.normalexit:
	ret

global soundeffectvolume
soundeffectvolume:
	imul ebx,[dword 0]
ovar .relvolume,-4,$,soundeffectvolume
	shr ebx,9
	add bl,0x40
	ret
#endif

global spritesorter
spritesorter:
	push edi

	mov eax,0
ovar .spritelistptr,-4,$,spritesorter

.sortnext:
	mov ebp,[eax]
	test ebp,ebp
	jz .done

	bts dword [ebp+spritedesc.flags],0
	jnc .sortit

	add eax,4
	jmp .sortnext

.done:
	pop edi
	ret

.sorted:
	mov eax,[tempvar]
	jmp .sortnext

.sortit:
	mov di,[ebp+spritedesc.X1]
	mov bx,[ebp+spritedesc.Y1]
	mov cx,[ebp+spritedesc.Z1]	// cl=Z1 and ch=Z2
	mov dx,[ebp+spritedesc.X2]
	mov si,[ebp+spritedesc.Y2]

	mov [tempvar],eax
	mov [currspritedescpp],eax

.a_infront:
.checknext:
	add eax,4
	mov ebp,[eax]
	test ebp,ebp
	jz .sorted

	test byte [ebp+spritedesc.flags],1
	jnz .checknext

	push eax

	// first check for overlap in all coordinates
	// overlap if c1A <= c1B <= c2A OR c1A <= c2B <= c2A in all coordinates c=X,Y,Z

	// now DI=X1A BX=Y1A CL=Z1A DX=X2A SI=Y2A CH=Z2A

%macro checkspritecoord 4	// params: c1A,c2A,.cnB,pass
	mov al,2
	cmp [ebp+spritedesc.%3],%1	// c1A<=c1B (really !c1B<c1A)

	sbb al,0
	cmp %2,[ebp+spritedesc.%3]	// c1B<=c2A
	sbb al,0			// now al=2 if both conditions true
	and al,2			// mask out "2" bit
	%if %4
	or ah,al			// and add to ah if it was set
	%else
	mov ah,al
	%endif
%endmacro

	// check whether all of X, Y and Z have overlap

	checkspritecoord di,dx,X1,0
	checkspritecoord di,dx,X2,1
	jz .nooverlap	// no overlap in X

	checkspritecoord bx,si,Y1,0
	checkspritecoord bx,si,Y2,1
	jz .nooverlap	// no overlap in Y

	checkspritecoord cl,ch,Z1,0
	checkspritecoord cl,ch,Z2,1
	jnz .hasoverlap

.nooverlap:
	xor eax,eax

	// if no overlap, do TTD's original comparisons
	cmp di,[ebp+spritedesc.X2]
	rcl eax,1			// 20:	X1A<X2B

	cmp bx,[ebp+spritedesc.Y2]
	rcl eax,1			// 10:	Y1A<Y2B

	cmp cl,[ebp+spritedesc.Z2]
	rcl eax,1			// 8:	Z1A<Z2B

	cmp dx,[ebp+spritedesc.X1]
	rcl eax,1			// 4:	X2A<X1B

	cmp si,[ebp+spritedesc.Y1]
	rcl eax,1			// 2:	Y2A<Y1B

	cmp ch,[ebp+spritedesc.Z1]
	rcl eax,1			// 1:	Z2A<Z1B

	cmp byte [0x12345678+eax],0
ovar .spritesorttableofs,-5,$,spritesorter

	pop eax
	je .checknext

.b_infront:
.swapthem:
	push ebx
	mov ebx,[currspritedescpp]
	add dword [currspritedescpp],4

.swapnext:
	xchg ebp,[ebx]
	add ebx,4
	cmp ebx,eax
	jbe .swapnext

	pop ebx
	jmp .checknext

.hasoverlap:
	// so we have overlap

	// we have two possibilities:
	// - draw A before B
	//	to do that, we do nothing
	// - draw B before A
	//	to do that, we swap them

	// to find the one in front, we find the center of both boxes,
	// 	and draw the one which has a larger screen-Z last
	//
	// 	(screen-Z = X/2+Y/2+Z/2)
	//
	//	instead of finding the center X/Y/Z, e.g. X=(X1+X2)/2,
	//	we'll just double screen-Z, and subtract both values

	mov al,cl
	sub al,[ebp+spritedesc.Z1]
	add al,ch
	sub al,[ebp+spritedesc.Z2]
	cbw
//	imul ax,4
//	add ax,ax
	add ax,di
	sub ax,[ebp+spritedesc.X1]
	add ax,dx
	sub ax,[ebp+spritedesc.X2]
	add ax,bx
	sub ax,[ebp+spritedesc.Y1]
	add ax,si
	sub ax,[ebp+spritedesc.Y2]
	pop eax

	// now flags=screenZA-screenZB

.again:
	jg .swapthem
	jl .checknext

	// they were equal, there's really no "right" order to draw them, but
	// to provide for well-behaved sorting, we need a tie-breaker
	// we just compare all coordinates in turn until we have a difference

	cmp di,[ebp+spritedesc.X1]
	jnz .again
	cmp dx,[ebp+spritedesc.X2]
	jnz .again
	cmp bx,[ebp+spritedesc.Y1]
	jnz .again
	cmp si,[ebp+spritedesc.Y2]
	jnz .again
	cmp cl,[ebp+spritedesc.Z1]
	jnz .again
	cmp cl,[ebp+spritedesc.Z2]
	jnz .again
	jmp .checknext	// all coordinates equal, bleh....


	// called when clearing tile, also reset the new landscape arrays
	//
	// in:	esi=XY
	// safe:ebx edx esi edi ebp
global cleartile
cleartile:
	mov byte [landscape1+esi],0x10	// overwritten
	mov ebx,landscape6
	test ebx,ebx
	jle .nol6
	mov byte [ebx+esi],0
.nol6:
	mov ebx,landscape7
	test ebx,ebx
	jle .nol7
	mov byte [ebx+esi],0
.nol7:
	ret

// a small tweak in the RLE encoding code to allow saving some disk space
//
// The main idea is that starting a "repeat" block for a double byte isn't
// worth: we get two compressed bytes ( FF xx ) for the two original bytes
// ( xx xx ). On the top of this, we may have to start a new "non-repeat"
// block because of the "repeat" block, so we get three bytes for the original
// two. That's why we tweak it a bit: if we're in the middle of a "non-repeat"
// block, switch to a "repeat" block only if three identical bytes follow each
// other, instead of the original two.
//
// According to my tests, savegames occupy 4-5% less space with the tweaked method
// [Csaba]
global newrlesave
newrlesave:
	mov edi,[dword 0]
ovar .chunkptr,-4,$,newrlesave
// edi points to the end of the input buffer. At this point, the input buffer is
// guaranteed to contain at least two bytes. Return with zf set to switch to
// "repeat" mode
	cmp al,[edi]
	jnz .notgood
	cmp al,[edi-1]
.notgood:
	ret

// called to check if the vehicle is stopped (for breakdown processing)
// in:	esi -> vehicle
// out: zf set if vehicle is moving
global canvehiclebreakdown
canvehiclebreakdown:
	cmp byte [esi],0x10
	jne .normalcheck

// what the original code misses: trains waiting on a red signal and trains waiting to get out of a depot

	cmp word [esi+veh.loadtime],0		// this field is nonzero while waiting on a signal
						// and while loading ( loading means being stopped as well)
	jne .haveflags
	cmp byte [esi+veh.movementstat],0x80	// is it in a depot?
	jne .normalcheck
	or esi,esi		// clear zf
.haveflags:
	ret

.normalcheck:
	test byte [esi+veh.vehstatus],2	// a shorter form of the overwritten instruction
	ret

// Called to check whether train should ignore the depot signal
//
// in:	esi->vehicle
// out:	CF=1 don't check signal
//	CF=0 ZF=0 ignore signal
//	CF=0 ZF=1 check signal state
// safe:al cx di ebp
exported trainignoredepotsignal
	cmp byte [esi+veh.movementstat],80h	// stopped?
	jne .donecf
	cmp byte [esi+veh.ignoresignals],0
	je .done

	// check that train is entirely inside depot
	movzx ebp,word [esi+veh.nextunitidx]
	mov cx,[esi+veh.XY]
.checknext:
	cmp bp,byte -1
	je .donenz

	shl ebp,7
	add ebp,[veharrayptr]
	cmp byte [ebp+veh.movementstat],80h
	jne .donecf

	cmp cx,[ebp+veh.XY]
	movzx ebp,word [ebp+veh.nextunitidx]
	je .checknext

.donecf:
	stc
.done:
	ret
.donenz:
	test esp,esp
	ret

// Calculate the position of the slider
// (the original code only worked for slider < 256 pixels)
//
// in:	esi->window
//      cx,dx = slider box top and bottom
// out: cx,dx = slider top and bottom
// uses:ax,bp
global GetSliderPosition
GetSliderPosition:
	add cx, 0x0A
	sub dx, 9
	sub dx, cx
	mov bp, cx
	movzx ax, byte [esi+window.itemsoffset]
	push dx
	mul dx
	push bx
	movzx bx, byte [esi+window.itemstotal]
	test bx,bx
	jz .zero
	div bx
	pop bx
	pop dx
	add cx, ax
	mov al, [esi+window.itemstotal]
	mov ah, [esi+window.itemsvisible]
	cmp ah, al
	jb .notallvisible
	mov ah, al
.notallvisible:
	sub al, [esi+window.itemsoffset]
	sub al, ah
	xor ah, ah
	push dx
	mul dx
	push bx
	movzx bx, byte [esi+window.itemstotal]
	div bx
.zero:
	pop bx
	pop dx
	add dx, bp
	sub dx, ax
	dec dx
	ret

//Used to calculate the width of the name of a town
global SetTownNamePosition
SetTownNamePosition:
	mov ax, [esi+town.citynametype]
	mov word [textrefstack], ax
	mov eax, [esi+town.citynameparts]
	mov dword [textrefstack+2], eax
	movzx eax, word [esi+town.population]
	movzx edi, word [esi+town.population]
	cmp dword [townarray2ofst], 0
	jz .notown2
	push esi
	add esi, [townarray2ofst]
	mov eax, [esi+town2.population]
	pop esi
.notown2:
	mov dword [textrefstack+6], eax
	
	mov ax, statictext(townnamesize)
	ret

global settownnamepositionend
settownnamepositionend:
	add cx, 2
	mov [esi+town.namewidthsmall], cl
	add byte [esi+town.namewidth], 20
	call RefreshTownNameSign
	ret

global RefreshTownNameSignedi
RefreshTownNameSignedi:
	pusha
	mov ax, [edi+town.nameposx]
	mov bx, [edi+town.nameposy]
	movzx dx, [edi+town.namewidth]
	jmp RefreshTownNameSign.update
	
global RefreshTownNameSign
RefreshTownNameSign:
	pusha
	mov ax, [esi+town.nameposx]
	mov bx, [esi+town.nameposy]
	movzx dx, [esi+town.namewidth]
.update:
	shl dx, 2
	add dx, ax
	sub bx, 3
	mov bp, bx
	add bp, 48
	sub ax, 6
	add dx, 12
	call [RefreshLandscapeRect]
	popa
	ret

global drawtownsize
drawtownsize:
	shl edx, 10h
	shr ebp, 10h

	movzx edi, word [esi+town.population]
	cmp dword [townarray2ofst], 0
	jz .notown2
	push esi
	add esi, [townarray2ofst]
	mov edi, [esi+town2.population]
	pop esi
.notown2:
	rol edi, 16
	push eax
	mov eax, edi
	and eax, 0xffff0000
	or ebp, eax
	pop eax
	ret

// fix rounding error when subtracting running costs
//
// in:	eax=ebx=daily running costs*256
//	edx=remainder
//	esi->vehicle
// out:	adjust [esi+veh.profit]
// safe:eax ebx edx
global subtractruncosts
subtractruncosts:
	shr ebx,8
	sub [esi+veh.profit],ebx

	test byte [currentdate],3
	jnz .done

	// subtract 4 times the remainder every 4th day,
	// and 32 times the remaining remainder every 32nd day
	movzx ebx,al
	shr ebx,6	// V*4 >> 8 = V >> 6
	sub [esi+veh.profit],ebx

	test byte [currentdate],31
	jnz .done

	and eax,7<<3	// only the fraction we haven't used yet
	shr eax,3	// V*32 >> 8 = V << 3
	adc eax,0	// to round up half-pounds
	sub [esi+veh.profit],eax

.done:
	ret


// expire vehicle some time before its end of phase 2
// if variable is set in new vehicle data
//
// in:	esi->vehtype
// out:	(set reliability)
// safe:dx
global vehphase2
vehphase2:
	call vehexpireearly
	mov ax,[esi+vehtype.reliabmax]
	mov [esi+vehtype.reliab],ax
	ret

global vehphase3
vehphase3:
	call vehexpireearly
	mov cx,[esi+vehtype.reliabmax]
	sub cx,[esi+vehtype.reliabend]
	ret

vehexpireearly:
	push eax
	mov eax,esi
	sub eax,vehtypearray
	mov dl,vehtype_size
	div dl
	movsx eax,byte [vehphase2dec+eax]
	test eax,eax
	jz .notexp
	imul eax,byte -12
	add ax,[esi+vehtype.durphase1]
	add ax,[esi+vehtype.durphase2]
	cmp ax,[esi+vehtype.engineage]
	jae .notexp
	mov word [esi+vehtype.playeravail],0
.notexp:
	pop eax
	ret


// Automatically adjust width of drop-down menu's to fit the longest text.
global calcdropdownmenuwidth
calcdropdownmenuwidth:
	shr ebx, 16
	push bx
	mov bx, [ebp+windowbox.x2]
	sub bx, ax
	sub bx, 8
//	mov bx, 0
	
	push ebp
	push ecx
	push eax
	push esi
	push edi
	push edx
	
	mov ebp, tempvar
.loop:
	mov ax, word [ebp]
	cmp ax, -1
	je .done
	
	mov edi, tmpbuffer1
	pusha
	call [ttdtexthandler]
	popa
	mov esi, edi
	push bx
	call [gettextwidth]
	pop bx
	cmp cx, bx
	jb .okay
	mov bx, cx
.okay:
	add ebp, 2
	jmp .loop
.done:
	pop edx
	pop edi
	pop esi
	pop eax
	pop ecx
	pop ebp
	
	shl ebx, 16
	pop bx
	rol ebx, 16

	add bx, 8

	ret

// called while calculating the catchment area of a station
// in:	bx,cx: (after the overridden instructions) corners of catchment area
//	esi->station
// safe: esi,???
global calccatchment
calccatchment:
	add ch,4	// overwritten
	jnc .nooverflow	// by
	mov ch,0xff	// the
.nooverflow:		// runindex call
	add esi,[stationarray2ofst]
	mov [esi+station2.catchmenttop],bx
	mov [esi+station2.catchmentbottom],cx
	ret

// called to decide if an industry is "close enough" to a station to accept its cargo
// the old code simply checked if the distance is <=16 between the station sign and
// the industry. Our new function checks if the station catchment area overlaps the
// industry rectangle instead.
// in:	[esp+17] B: ID of target station
//	edi->industry
//	bp: distance of closest accepting industry or -1 if none
// out: return 0x14 bytes further if the industry is too far
// safe: eax,ebx,edx,ebp,esi
global checkstationindustrydist
checkstationindustrydist:
	cmp bp,-1
	jne .foundsomething
	add dword [esp],0x14
	ret

.foundsomething:
	movzx ebp,byte [esp+17]
	push ecx
	imul ebp,station2_size
	add ebp,[stationarray2ptr]

	cmp dword [ebp+station2.catchmenttop],0
	jne .catchmentok

	push ebp
	push edi
	mov al,1
	mov esi,ebp
	sub esi,[stationarray2ofst]
	call [UpdateStationAcceptList]
	pop edi
	pop ebp

.catchmentok:
	mov ax,[ebp+station2.catchmenttop]
	mov bx,[ebp+station2.catchmentbottom]
	mov cx,[edi+industry.XY]
	mov dx,[edi+industry.dimensions]
	add dx,cx

	cmp ah,ch
	ja .ahcorrect
	mov ah,ch
.ahcorrect:

	cmp bh,dh
	jb .bhcorrect
	mov bh,dh
.bhcorrect:

	cmp ah,bh
	ja .toofar

	cmp al,cl
	ja .alcorrect
	mov al,cl
.alcorrect:

	cmp bl,dl
	jb .blcorrect
	mov bl,dl
.blcorrect:

	cmp al,bl
	jbe .nottoofar

.toofar:
	add dword [esp+4],0x14
.nottoofar:
	pop ecx
	ret

exported getsnowyheight
	push edx
	test di,di
	jz .noadjust
	add dl,8
.noadjust:
	cmp dl,[snowline]		// overwritten
	pop edx
	ret

exported getsnowyheight_fine
	test di,di
	jz .noadjust
	add dl,8
.noadjust:
	mov bh,[snowline]		// overwritten
	ret

exported calcboxz
	add si,cx		// overwritten
	add dh,dl		// ditto
	jnc .done
	mov dh,0xFF
.done:
	ret
