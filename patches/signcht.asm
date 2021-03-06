
// Sign cheats.
// Note that CHT: Tracks is in trackcht.asm

#include <std.inc>
#include <proc.inc>
#include <flags.inc>
#include <textdef.inc>
#include <station.inc>
#include <house.inc>
#include <misc.inc>
#include <patchdata.inc>
#include <veh.inc>
#include <vehtype.inc>
#include <player.inc>
#include <industry.inc>
#include <ptrvar.inc>
#include <win32.inc>
#include <dest.inc>

extern actionhandler,actionmakewater_actionnum,addexpenses
extern clearfifodata,clearindustryincargos,deleteconsist
extern do_win_grfstat_create,errorpopup,findengines,findusedengines
extern generatesoundeffect,updatevehvars,gethouseidebpebx,getymd
extern hexnibbles,houseflags,int21handler
extern invalidatehandle,isengine,loadremovedvehs,makegrfidlist,makerisingcost
extern newspritedata,newspritenum,newvehtypeinit,ophandler,patchflags
extern planttreearea,redrawscreen,redrawtile,resetnewsprites
extern resetpathsignalling,setmainviewxy,specialerrtext1,specialerrtext2
extern subsidyfn,traincost,treenum,treestart,vehtypedataptr
extern yeartodate,trackcheat,isplaneinflight
extern convertplatformsinremoverailstation
extern invalidatetile,ResetBBlockVehicleLists
extern newtexthandler,stationarray2ptr,cargodestdata,cargodestdata_size


//uncoment for debugging purposes
//#undef DEBUG
//#define DEBUG 1

%assign cheattext "CHT:"	// gives "CHT:" in little endian
var cheatok, db "  ",0xac,0	// gives a tick mark
var cheatbad, db "  ",0xad,0	// gives an X mark

%assign uppercase ~("AAAA" ^ "aaaa")
%assign allowsemicolon ~("   :" ^ "   ;")

struc cheat
	.name:	resb 18		// size x*4-2
	.costs: resb 1
	.bit: 	resb 1
	.func: 	resd 1
endstruc

%assign cheatcount 0
%assign cheataliascount 0
%macro cheatentry 3.nolist // params: text,function,costs
	%if cheatcount>63
		%error "Too many cheats, need more bits to record Cht: Used"
	%endif
cht_%2:
	istruc cheat
		at cheat.name, db %1
		at cheat.costs, db %3
		at cheat.bit, db cheatcount
		at cheat.func, dd addr(%2)
	iend
	%assign cheatcount cheatcount+1
%endmacro

%macro cheatalias 2.nolist // params: newname,oldname
	istruc cheat
		at cheat.name, db %1
		at cheat.costs, db -1
		at cheat.bit, db -1
		at cheat.func, dd cht_%2
	iend
	%assign cheataliascount cheataliascount+1
%endmacro

%macro getwriteloc 1 //param: cheatnamelen
	mov esi,[esp+4]
	call skipspaces
	add ebx,%1
	mov edi,esi
%endmacro

	// Do not uncomment any of them, or the marking will be incorrect
	// Renaming is ok, and lowercase chars will never be matched
	// Each cheat should return with a "ret", and set the carry flag
	// if there was an error.
varb cheatlist
cheatentry "MONEY",moneycheat,0
cheatentry "YEAR",yearcheat,0
cheatentry "TRACKS",trackcheat,1
cheatentry "USED",usedcheat,0
cheatentry "OWNCROSSING",roadcheat,0
cheatentry "RENEW",renewcheat,1
cheatentry "DUMPMEMORY",dumpcheat,0
cheatentry "ALLNONSTOP",allnonstop,0
cheatentry "NONONSTOP",nononstop,0
cheatentry "SERVINT",servintcheat,0
cheatentry "RESETSTATION",resetstationcheat,0
cheatentry "ALLVEHICLES",allvehiclescheat,0
cheatentry "CLEARPRESIG",clearpresignalscheat,0
cheatentry "REMOVEVEHICLES",removevehiclescheat,0
cheatentry "CLEARGHOSTS",ghoststationcheat,0
cheatentry "PLAYERID",playeridcheat,0
cheatentry "NOUNLOAD",nounloadcheat,0
cheatentry "RESETVEHICLES",resetvehiclescheat,0
cheatentry "SEMAPHORES",semaphorecheat,0
cheatentry "PLANTTREES",planttreecheat,1
cheatentry "SUBSIDY",subsidycheat,0

cheatalias "ALLENGINES",allvehiclescheat
cheatalias "REMOVEENGINES",removevehiclescheat
cheatalias "RELOADENGINES",resetvehiclescheat

cheatentry "REMOVEHQ", removehqcheat, 0
cheatentry "CLIMATE", climatecheat, 0
cheatentry "DEBUGGER",debuggercheat,0
cheatentry "GRAPHICS",do_win_grfstat_create,0

cheatentry "RESETTHISSTATION",statresetcheat,0
cheatentry "FINDLOSTWAGONS",lostwagonscheat,0
cheatentry "RESTARTCONST",restartconstcheat,0
cheatentry "STOPALL",stopallcheat,0
cheatentry "RESETPBS",resetpbscheat,0
cheatentry "DELETEVEH",deletevehcheat,0
cheatentry "RESETFIFO",resetfifocheat,0
cheatentry "RELOADINDUSTRIES",resetinducheat,0
cheatentry "FACE",facecheat,0
cheatentry "LANDGEN",landgencheat,0
//cheatentry "ENGINE",enginecheat
//          12345678901234 (max length of name)

#ifndef RELEASE
cheatentry "GRFDEBUG",grfdebugcheat,0
#endif

cheatentry "LANDINFO",landinfocheat,0 // No longer a DEBUG sign cheat
cheatentry "PURGEHOUSES",purgehousescheat,0
cheatentry "PURGEINDUSTRIES",purgeindustriescheat,0

#if 1 && DEBUG
cheatentry "LANDD", landdispcheat,0
//cheatentry "SETSET", morestationsetset,0	// doesn't work anymore
cheatentry "SOUND", soundeffectcheat,0	// play a certain sound effect for testing
cheatentry "DSPRITE", findspriteinmemoryanddump,0
cheatentry "SMEM", patchspriteinmem, 0	// change spritememory
//cheatentry "WATER",landwatercheat,0
cheatentry "WHEREAMI",positioncheat,0
cheatentry "SNOWLINE",snowlinecheat,0
cheatentry "GOTOXY",gotocheat,0
cheatentry "TEXTID",textidcheat,0
cheatentry "RESETCARGO",resetcargocheat,0
cheatentry "CLONETILE", clonetilecheat,0
#endif

cheatentry "UNRESERVEPBSTRACK",unreservepbstrack,0
cheatentry "HEIGHTMAP",loadheightmapcheat,0

#if 1
// Give peeople a chance to use objects
//   in the scenario editor
extern win_objectgui_create
cheatentry "OBJECTGUI", win_objectgui_create, 0
#endif

#if 1 && DEBUG
cheatentry "SETINDVAL",setindustrystrucval,0
cheatentry "RESETBBLIST",ResetBBlockVehicleLists,0
cheatentry "CREATEOBJECT", createnewobject, 0
cheatentry "SETLANDVAL", setlandarrayval, 0
cheatentry "LOGCARGODEST", logcargodest, 0
#endif
cheatentry "FIXORDERS", fixorders, 0
cheatentry "CARGODEST", cargodestcheat, 0

#if DEBUGNETPLAY
cheatentry "LOGRANDOM",lograndomcheat,0
#endif

endvar

uvard activesign	// pointer to current sprite structure, or -1 if about to set
uvarw cheaterror


//
// called when checking whether a new sign doesn't have a duplicate name
//
// record that we're placing a sign, and not to actually check for duplicates
//
global putsign
putsign:
	or dword [activesign],byte -1

	xor ebx,ebx
	call dword [ebp+4]
	mov di,ax

	and dword [activesign],0
	ret


// Called when TTD decides whether to compare the text of the new sign/town/station/company/etc.
// with a text in the custom string list. If the check decides that
// they're equal, the renaming is cancelled, and a "Name is already in use"
// error pops up.
//
// This check is removed for landscape signs, which don't need to be unique.
//
// in:	ebx=pointer to the text in the string list
//	bp=index of the currently checked text
//	edi pointing to the new text
//	ax=index of the latest empty item that can be used to store the new text
//	esi pointing to the latest empty item or zero if no empty item has been found yet
// out:	zero flag set if check should be done
// safe:??
//
global checkduplicate
checkduplicate:
	cmp byte [ebx],0
	jne .notempty
	mov esi,ebx	// empty string - store its address and index
	mov ax,bp	// like the original code does
	or esi,esi	// and skip check
	ret

.notempty:
	cmp dword [activesign],byte -1
	jne .notsign
	or edi,edi	// if it's a sign, skip check
	ret

.notsign:
	cmp ax,ax	// the player isn't putting a sign and the checked text isn't empty - we should check
	ret


// called after creating a new sign or changing the text of a sign
//
// in:	esi=pointer to sign structure
// out:	ax=[esi+sign.x]
//	cx=[esi+sign.y]
// safe:everything but esi
global signcheat
signcheat:
	movzx ecx,word [esi+sign.text]
	mov al,ch
	and al,0xf8
	cmp al,0x78
	jne .exitsigncheat	// only custom texts can be sign cheats

	and ch,7
	imul ecx,0x20
	add ecx,[customtxtptr]

	mov eax,[ecx]
	and eax,uppercase & allowsemicolon
	cmp eax,cheattext & uppercase & allowsemicolon
	je short .issigncheat

.exitsigncheat:
	and dword [activesign],0
	mov ax,[esi+sign.x]
	mov cx,[esi+sign.y]
	ret

.issigncheat:
	mov [activesign],esi

	mov word [cheaterror],ourtext(cheatinvalidparm)	// default error

	pushad

	lea esi,[ecx+4]			// point to text after "CHT:"

	xor ebx,ebx
	call skipspaces

	mov edi,cheatlist-cheat_size
	mov dl,cheatcount+cheataliascount+1

	push esi

.continuechecknextcheat:
	pop esi
	push esi

	mov eax,[esi+ebx]
	and eax,uppercase		// switch to uppercase

.checknextcheat:
	add edi,byte cheat_size
	dec dl
	jz short .cheatunknown

	cmp dword [edi+cheat.name],eax
	je short .foundcheat
	jmp short .checknextcheat

.cheatunknown:
	mov word [cheaterror],ourtext(cheatunknown)

.cheatbad:
	pop esi
	popad		// restore registers but keep them saved
	pushad

.cheatbadpopped:

	mov bx,ourtext(cannotcheat)
	mov dx,word [cheaterror]
	xor ax,ax
	xor cx,cx
	call dword [errorpopup]

	popad
	pushad

	mov ebx,cheatbad
	jmp .cheatresult

.foundcheat:
	xor ecx,ecx
	lea esi,[esi+ebx+4]
.checknextbyte:
	mov al,[esi+ecx]
	cmp al," "
	je short .checkeofcheat
	cmp al,"?"
	je short .checkeofcheat
	cmp al,"!"
	je short .checkeofcheat
	and al,uppercase >> 24
	jz short .checkeofcheat
	cmp al,[edi+cheat.name+ecx+4]
	jne .continuechecknextcheat
	inc ecx
	cmp ecx,byte cheat.costs-cheat.name-4
	jb .checknextbyte
	jmp .cheatunknown

.checkeofcheat:
	cmp byte [edi+cheat.name+ecx+4],0
	jne .cheatunknown

.goodcheat:
	cmp byte [edi+cheat.bit],-1
	jne .notalias

	mov eax,[edi+cheat.func]
	pusha
	mov dword [specialerrtext1],edi
	mov dword [specialerrtext2],eax
	mov bx,ourtext(cheatobsolete1)
	mov dx,ourtext(cheatobsolete2)
	xor ax,ax
	xor cx,cx
	mov dword [textrefstack],((statictext(specialerr2))<<16)+statictext(specialerr1)
	call dword [errorpopup]
	popa
	xchg eax,edi

.notalias:
	xor ebx,ebx
	push esi
	mov esi,[esp+4]
.loop:
	lodsb
	cmp al,"?"
	je .checkcosts
	or al,al
	jnz .loop
	movzx edx,byte [edi+cheat.bit]
	bts [landscape3+ttdpatchdata.chtused],edx
	pop esi
.docheat:
	add esi,ecx
	call dword [edi+cheat.func]
	jmp short .cheatdone

.checkcosts: // Cost check requested
	pop esi
	cmp byte [edi+cheat.costs],0
	jne .docheat // Cheat has costs, use cheatfunc
	xor al,al
	call showcost

.cheatdone:
	pop esi
	popad		// restore registers but keep them saved
	pushad

	mov ebx,cheatok
	jc .cheatbadpopped

.cheatresult:
	// copy string again, it might've been corrupted by errorpopup()
	mov esi,ecx
	mov edi,ecx
	xor ecx,ecx

.nextbyte:
	lodsb
	or al,al
	jz short .theend
	stosb
	inc ecx
	cmp ecx,byte 0x20
	jb short .nextbyte

.theend:
	or ebx,ebx
	jz short .copydone
	mov esi,ebx
	xor ebx,ebx
	cmp ecx,byte 0x1c
	jb short .nextbyte
	sub edi,ecx
	mov cl,0x1c
	add edi,ecx
	jmp short .nextbyte

.copydone:
	xor al,al
	stosb
	popad
	jmp .exitsigncheat
// endp signcheat

	// start at esi+ebx and return ebx such that [esi+ebx] is not a space
skipspaces:
	cmp byte [esi+ebx]," "
	jne short .nomorespaces
	inc ebx
	jmp short skipspaces
.nomorespaces:
	ret
// endp skipspaces

	// reads string pointed to by esi+ebx and returns number in edx (or -1 if error)
	// ebx now points to char after the number
	// cf set if error, clear otherwise
global getnumber
getnumber:
	push eax
	call skipspaces
	xor eax,eax
	xor edx,edx
	mov ah,1		// indicates no digits yet
.nextdigit:
	mov al,[esi+ebx]
	inc ebx
	or al,al
	jz short .exitgetnumber
	cmp al," "
	je short .exitgetnumber
	cmp al,"."
	je .nextdigit
	cmp al,","
	je .nextdigit
	sub al,"0"
	jl short .exitgetnumber
	cmp al,9
	jg short .exitgetnumber
	xor ah,ah		// found a digit
	imul edx,edx,byte 10
	add edx,eax
	jmp short .nextdigit

.exitgetnumber:
	or ah,ah
	jz short .havenumber		// at least some good digits
	or edx,byte -1			// no good digits at all
	stc

.havenumber:
	dec ebx			// leaves cf untouched
	pop eax
	ret
// endp getnumber

	// same as above but assumes the number is in hex
gethexnumber:
	push eax
	call skipspaces
	xor eax,eax
	xor edx,edx
	mov ah,1
.nextdigit:
	mov al,[esi+ebx]
	inc ebx
	and al,uppercase >> 24
	jz .done		// also takes care of " "
	sub al,"0" & (uppercase>>24)
	jb .done
	cmp al,9
	jbe .havedigit
	sub al,"A"-("0" & (uppercase>>24))
	jb .done
	cmp al,6
	jae .done
	add al,10

.havedigit:
	mov ah,0
	shl edx,4
	add edx,eax
	jmp .nextdigit

.done:
	test ah,ah
	jz .gotit
	or edx,byte -1
	stc

.gotit:
	dec ebx
	pop eax
	ret

// return in ESI the XY coordinate of the current sign
getsignxy:
	push eax
	mov eax,dword [activesign]
//	mov eax,[eax]
	movzx esi,word [eax+sign.y]	// get sign location
	movzx eax,word [eax+sign.x]	//
	shr esi,4
	shr eax,4
	shl esi,8
	or esi,eax	// compute the tile of the sign
	pop eax
	ret


	// check if cheats should cost, and if so, if we actually do the
	// cheat or just check only
	// returns  dl=do the cheat,  dh=whether cheats cost
	//
	//	dl = 0 no, just check cost
	//	dl = 1 yes, do it
	//
	//	dh = 0 no they don't cost
	//	dh = 1 yes they cost
	//

global checkcost
checkcost:
	push ebx

	testflags cheatscost
	setc dh

.next:
	mov dl,[esi+ebx]
	or dl,dl
	jz short .default

	cmp dl,'?'
	jne short .notquestion
	xor dl,dl		// check cost only
	jmp short .knowit

.notquestion:
	cmp dl,'!'		// do it
	je short .exclam

	inc ebx
	jmp .next

// by default, do it even if they cost
.default:
.exclam:
	mov dl,1

.knowit:
	pop ebx
	ret
; endp checkcost

	// subtract money from player funds
	// al,ah should be output from checkcost
	// ebx = cost in pounds
	// cl = which entry in the finance screen to attribute this cost to (expenses_*)
	// if "check only", it does nothing
global docost
docost:
	or al,al
	jz short .checkonly
	or ah,ah
	jz short .checkonly

	// subtract cost from player funds and add to appropriate expenses
	mov [currentexpensetype],cl
	call [addexpenses]

.checkonly:
	ret
; endp docost

	// show a rising "cost" on screen
	// in: same as docost
	// it shows a red popup with the cost if checking only
	// otherwise it shows the cost
global showcost
showcost:
	or al,al
	jz short .checkonly
	or ah,ah
	jnz short .realcost

	// no costs involved at all
	ret

.checkonly:
	// show error popup
	mov [textrefstack],ebx	// store cost

	mov bx,0x805	// "Estimated Cost: ..."
	mov dx,-1	// only one line
	xor ax,ax
	xor cx,cx
	push ebp
	call dword [errorpopup]
	pop ebp
	ret

.realcost:
	// show rising cost
	mov eax,dword [activesign]
//	mov eax,[eax]
	movzx ecx,word [eax+sign.y]	// get sign location
	movzx eax,word [eax+sign.x]	//
	sub ecx,byte 6	// make cost appear just above the sign
	sub eax,byte 6	//
	push ebp
	call dword [makerisingcost]
	pop ebp
	ret

; endp showcost

// check whether a player has enough money to do a costing cheat
// in:	ebx=cost
// out:	result from cmp op, so that jge means enough money, jl not enough

global checkmoney
checkmoney:
	push eax
	movzx eax,byte [curplayer]
	imul eax,player_size
	add eax,[playerarrayptr]
	cmp dword [eax+player.cash],ebx
	jge short .goodmoney

	// only MOVs here... these don't change flags
	mov [textrefstack],ebx
	mov word [cheaterror],3	// not enough money

.goodmoney:
	pop eax
	ret
; endp checkmoney 

// set the service interval of all vehicles
// cht: servint <days> [<types> [<ai?>]]
//	days: how many days
//	types: bit coded. 1=rr 2=rv 4=ship 8=plane. default all
//	ai: 0=no (default) 1=yes
servintcheat:
	call getnumber
	jc short .error
	mov di,dx
	call getnumber
	jnc short .havetypes
	mov dl,15	// default is all vehicle types
.havetypes:
	mov ah,dl
	cmp ah,15
	ja short .error

	call getnumber
	jnc short .haveai
	mov dl,0
.haveai:
	mov al,dl
	jmp short .goatit

.error:
	stc
	ret

.done:
	clc
	ret


.goatit:
	mov esi,[veharrayptr]

	// now: di=number of days, ah=types, al=ai, bl=player number
.checkislast:
	cmp esi,[veharrayendptr]
	jae .done
	or al,al	// ai too? if so, don't check owner
	jnz short .checktype
	
	extcall checkowner.veh
	jc short .checktype

.nextvehicle:
	sub esi,byte -vehiclesize	//add esi,vehiclesize
	jmp .checkislast

.checktype:
	mov cl,byte [esi+veh.class]
	sub cl,0x10
	mov bh,1
	shl bh,cl	// now ah=bit with vehicle type
	test ah,bh
	jz .nextvehicle	// was wrong type

	// now: right type, right owner, right everything!
	mov word [esi+veh.serviceinterval],di
	jmp .nextvehicle
; endp servintcheat 

// set all train commands to use non-stop
allnonstop:
	mov bl,0x80

	// ands all station commands with (not 80h), then ors with bl
setallnonstop:
	mov bh,[curplayer]
	mov esi,[veharrayptr]
.checkislast:
	cmp esi,[veharrayendptr]
	jae short .done
	mov eax,dword [esi+veh.scheduleptr]
	cmp eax,byte -1
	jne short .isengine
.nextvehicle:
	sub esi,byte -vehiclesize	//add esi,vehiclesize
	jmp .checkislast

.done:
	clc
	ret

.isengine:	// eax is offset into command array
	cmp byte [esi+veh.owner],bh
	jne .nextvehicle	// wrong owner

	movzx ecx,byte [esi+veh.totalorders]
	jecxz .nextvehicle

.nextcommand:
	and byte [eax],~ 0x80
	or byte [eax],bl
	add eax,byte 2
	loop .nextcommand
	jmp .nextvehicle

; endp allnonstop 

// remove non-stop from all train commands
nononstop:
	xor bl,bl
	jmp setallnonstop
; endp nononstop 

var hexdigits, db "0123456789ABCDEF"

// show what cheats have been used
usedcheat:
	getwriteloc 4
	mov edx,[landscape3+ttdpatchdata.chtused+4]
	call .showhex
	mov edx,[landscape3+ttdpatchdata.chtused]
	cmp dword [edi+ebx-2], " 0h"
	jne .skipwhite
	dec ebx
	jmp short .skipwhite
.showhex:
	mov dword [edi+ebx],"   "
	add ebx,byte 3
.skipwhite:
	mov ecx,8
.nextdigit:
	rol edx,4
	movzx eax,dl
	and al,0xf
	jnz .notzero
	cmp byte [edi+ebx-1]," "
	je .skipzero
.notzero:
	mov al,byte [hexdigits+eax]
	mov [edi+ebx],al
	inc ebx
.skipzero:
	loop .nextdigit
	cmp byte [edi+ebx-1]," "
	jne .no0
	mov byte [edi+ebx],"0"
	inc ebx
.no0:
	mov word [edi+ebx],"h"
	clc
	ret
; endp usedcheat

// stop all vehicles (Cht: StopAll [1]), or start all (Cht: StopAll 0)
stopallcheat:
	call getnumber
	add edx,edx
	and edx,2

	// stop or start all vehicles
	mov esi,[veharrayptr]
.again:
	cmp byte [esi+veh.class],0x10
	jb .next
	cmp byte [esi+veh.class],0x13
	ja .next
	jne .stopit

	call isplaneinflight	// can't stop aircraft in flight
	jc .next

.stopit:
	cmp dword [esi+veh.scheduleptr],byte -1
	je .next
	and byte [esi+veh.vehstatus],~2
	or [esi+veh.vehstatus],dl
.next:
	sub esi,byte -128
	cmp esi,[veharrayendptr]
	jb .again

	call redrawscreen
	ret


#if 1 && DEBUG
var sddumpname, db "SPRITE"
var sddumpnum,	db "####"
	db ".DMP",0

uvard sdspriteinfo

findspriteinmemoryanddump:

	call getnumber
	jnc .spritenumberok
.done:
	ret

.spritenumberok:
	mov [sdspriteinfo],edx
	xchg esi, edx

	CALLINT3

	mov edi,sddumpnum
	mov cl,4
	mov eax,esi
	call hexnibbles

	mov ax,0x3c00
	xor ecx,ecx
	mov edx, sddumpname
	CALLINT21
	jc .done

	xchg eax,ebx

	// get sprite data size
	mov edx,[newspritenum]
	mov eax,[newspritedata]

	lea eax,[eax+edx*4]
	movzx edi,word [eax+esi*2]	// spritedatasize
	// edi now sprite data size
	mov [sdspriteinfo+2], di

		// write sprite number and size
	mov ax,0x4000
	mov edx, sdspriteinfo
	mov cx, 4
	CALLINT21

	mov ecx, edi
	mov eax,[newspritedata]
	mov edx,[eax+esi*4]			// Sprite Data ptr

		// write sprite data
	mov ax,0x4000
	CALLINT21

	mov ax,0x3e00	// close file
	CALLINT21

	ret
; endp findspriteinmemoryanddump
#endif



#if 1 && DEBUG
// arguments:
// 1. spritenumber -> eax
// 2. memoffset -> edi
// 3. newvalue -> edx

patchspriteinmem:
	call getnumber
	jnc .spritenumberok
.errordone:
	stc
	ret

.spritenumberok:
//	xchg eax, edx
//	call getnumber
//	jc .errordone

//	xchg edi, edx
//	call getnumber
//	jc .errordone


	mov ebx,[newspritedata]
	mov ebp,[newspritenum]
	
	//imul ebp, edi
	//add ebx, ebp
	//mov [ebx+eax*2], dx
	mov ebx, [ebx+edx*4]
	CALLINT3

	clc 
	ret

#endif


// This cheat is obsolete
dumpcheat:
#if 1
	// cheat doesn't work here
	stc
	ret
#else
	local filehandle:word

	mov ax,0x3c00		// Create file
	mov cx,0		// Standard attributes
	mov edx,dumpname	// Filename
	int 0x21
	jc short .error
	mov filehandle,ax

	xor edx,edx
.nextchunk:
	mov ax,0x4000		// Write to file
	mov bx,filehandle	// Filehandle
	mov cx,0x1000		// Number of bytes
	push edx		// Address
	int 0x21
	pop edx
	jc short .closefile
	movzx eax,ax
	add edx,eax
	cmp ax,0x1000
	jne short .closefile
//	cmp edx,traindataend
	cmp edx,[veharrayendptr]
	jae short .closefile
	cmp edx,0x80000
	jne .nextchunk
//	mov edx,index
	mov edx,[veharrayptr]
	jmp .nextchunk

.closefile:
	mov ax,0x3e00		// Close file
	mov bx,filehandle
	int 0x21
.error:
	ret

var dumpname, db "TTDMEM.DMP",0

#endif
; endp dumpcheat 

// this doesn't work correctly...
enginecheat:
#if 0
	call getnumber
	cmp edx,-1
	je short .badengine
	cmp edx,2
	ja short .badengine
	mov al,dl
	call getnumber
	cmp edx,-1
	je short .badengine
	cmp edx,27
	ja short .badengine

	mov bx,dx
//	mov esi,index
	mov esi,[veharrayptr]
	add esi,-vehiclesize	//sub esi,vehiclesize

.nextengine:
	sub esi,-vehiclesize	//add esi,vehiclesize
//	cmp esi,traindataend
	cmp esi,[veharrayendptr]
	jae short .goodengine

	cmp byte [esi+veh.class],0x10
	jne .nextengine
	cmp byte [esi+veh.subclass],0
	jne .nextengine
	cmp byte [esi+veh.owner],0
	jne .nextengine
	cmp [esi+veh.tracktype],al
	jne .nextengine
	mov word [esi+veh.vehtype],bx
	jmp .nextengine

.goodengine:
	clc
	ret

.badengine:
#endif
	stc
	ret
; endp enginecheat


moneycheat:
	call getnumber
	jc .done
	movzx edi,byte [curplayer]
	imul edi,0x3b2
	add edi,[playerarrayptr]
	mov [edi+player.cash],edx
	mov [edi+player2ofs+player2.cash],edx
	mov eax,edx
	cdq
	mov [edi+player2ofs+player2.cash+4],edx
	clc

.done:
	ret
; endp moneycheat

yearcheat:
	call getnumber
	sub edx,1920
#if DEBUG
	jge short .getcurryear
#else
	jg short .getcurryear	// 1920 disallowed due to overflow problems
#endif

.badparameters:			// moved here so that we can use short jumps
	stc
.badparameters_c:		// useful when we know that CF is set
	ret

.getcurryear:
	push edx
//	call getnumber
//	mov ebp,edx

	// get current year as returned by getymd (for veh.yearbuilt adjustments)
	pop esi				// getymd destroys EDX, we need to save it somewhere
	mov eax,[currentdate]		// we ignore the high word anyway
	call [getymd]
	xchg eax,esi			// now EAX = entered value, SI = current year

	// the tortuous year to day conversion now moved to tools.asm

	call yeartodate			// now EBX = new date; EAX,ECX,EDX destroyed
	jc short .badparameters_c

	mov eax,0xff63			// 2099-1-1
	sub ebx,eax			// EBX = adjustment, EAX = internal date
	ja short .setyear

	// we're within the 16-bit limit -- use the computed value as actual date
	add eax,ebx
	xor ebx,ebx			// zero adjustment
	mov [landscape3+ttdpatchdata.yearsadd],bx	// might not be updated by limityear(), so zero it here

.setyear:
	mov [landscape3+ttdpatchdata.daysadd],ebx
	// note -- we needn't set .yearsadd, limityear() will take care of that

	lea edi,[eax-1]			// set EDI = target value, just 1 day before the New Year
	call [getymd]			// EAX = the new year value as recalculated by getymd
	xchg eax,ebx
	sub ebx,esi			// now BL = years difference

	mov ax,di			// we need to keep the high word clean
	xchg ax,[currentdate]

	sub edi,eax			// now EDI = days difference

//	test ebp,ebp
//	jz .done

		// change all vehicles accordingly
	mov esi,[veharrayptr]
.vehloop:
	add word [esi+veh.lastmaintenance],di
	add byte [esi+veh.yearbuilt],bl

	sub esi,byte -vehiclesize	//add esi,1 shl vehicleshift
	cmp esi,[veharrayendptr]
	jl .vehloop

	mov byte [currentmonth],12	// force month processing

.done:
	clc
	ret
; endp yearcheat

roadcheat:

	mov ebx,landscape1
	mov edi,landscape2

	mov ecx,0xffff
.nextsquare:
	mov al,[landscape4(cx,1)]	// important that ecx<10000h or GPF!
	and al,0xf0
	cmp al,0x20		// is a road on the square?
	jne short .loopagain

	test byte [landscape5(cx,1)],0x10
	jz short .loopagain	// just a normal road - no crossing

	mov ax,[edi+ecx*2]
	mov dl,[ebx+ecx]
	cmp dl,0x80		// tracks owned by a city?
	jnae short .loopagain

	// follow the tracks to find out whose they are
	mov dx,0x100
	test byte [landscape5(cx,1)],8
	jz short .vertical
	mov dx,0x001

.vertical:
	//... continue ... mov al,

	mov al,[human1]
	mov byte [ebx+ecx],al	// make tracks be owned by the first human player

.loopagain:
	loop .nextsquare

	clc
	ret
; endp roadcheat 

renewcheat:
	call getnumber
	jnc .gotnumber
	inc edx		// set edx to 0
.gotnumber:
	imul edx, 0x5b5
	shr edx, 2
	push edx
	mov ax,[currentdate]
	call dword [getymd]
	mov cl,al

	xor ebx,ebx
	call checkcost
	mov ax,dx

	pop edx

	or ah,ah		// do things cost money
	jz short .nocost
	or al,al		// do we check cost only
	jz short .nocost

	// things cost money, so we need to first make sure there is enough money
	xor al,al
	call .actualcheat

	call checkmoney

	jl short .notenoughmoney

	inc al

.nocost:
	call .actualcheat

	mov cl,expenses_newvehs
	call docost
	call showcost

	clc
	ret

.notenoughmoney:
	stc
	ret

.actualcheat:
	xor ebx,ebx

	mov esi,[veharrayptr]
	add esi,byte -vehiclesize	//sub esi,vehiclesize

.nextvehicle:
	sub esi,byte -vehiclesize	//add esi,vehiclesize
	cmp esi,[veharrayendptr]
	je short .renewdone

	cmp byte [esi+veh.class],0x10	// is it a train?
	jne .nextvehicle

	movzx edi,word [esi+veh.vehtype]
	bt dword [isengine],edi
	jc short .nextvehicle

	call checkowner.veh
	jnc short .nextvehicle		// not this player

	cmp [esi+veh.age], dx
	jl short .nextvehicle		// vehicle not old enough

	// it's a train waggon owned by the player
	movzx edi,byte [traincost+edi]		// get multiplier
	imul edi,[waggonbasevalue]		// multiply by base value
	shr edi,8

	add ebx,edi        		// add difference in values:
	sub ebx,dword [esi+veh.value]		// diff=new-old to money spent

	or al,al
	je .nextvehicle	// just checking cost

	mov dword [esi+veh.value],edi
	mov word [esi+veh.age],0
	mov byte [esi+veh.yearbuilt],cl
	mov di,[currentdate]
	mov word [esi+veh.lastmaintenance],di
	jmp .nextvehicle

.renewdone:
	ret
; endp renewcheat 

resetstationcheat:
	call getnumber
	xor ebp,ebp
	movzx eax,byte [curplayer]
	bts ebp,eax
	cmp edx,byte 0		// affect other players only if specified
	jle short .notall

	or ebp,byte -1		// affect all players

.notall:
	mov eax,stationarray
	mov ecx,numstations

.nextstation:
	movzx edx,byte [eax+station.owner]
	bt ebp,edx
	jnc short .doloop	// wrong owner

	xor edx,edx

.nextcargo:
	mov word [eax+station.cargos+stationcargo.amount+edx*8],0
	mov byte [eax+station.cargos+stationcargo.enroutefrom+edx*8],0xff
	mov byte [eax+station.cargos+stationcargo.lastspeed+edx*8],0
	inc edx
	cmp edx,byte 12		// 12 different types of cargo
	jb .nextcargo

	testflags newcargos
	jnc .doloop

	xor edx,edx

	mov [eax+station2ofs+station2.acceptedcargos],edx

.nextcargo2:
	mov byte [eax+station2ofs+station2.cargos+edx*stationcargo2_size+stationcargo2.type], 0xff
	inc edx
	cmp edx,byte 12
	jb .nextcargo2

.doloop:
	add eax,0x8e		// next station
	loop .nextstation

	clc
	ret
; endp resetstationcheat 

	// enable all engines
allvehiclescheat:
	mov esi,vehtypearray
	mov edi,dword [vehtypedataptr]
	xor ecx,ecx
	movzx edx,byte [climate]
.nextengine:
	mov ax,word [esi+vehtype.engineage]
	mov bx,word [esi+vehtype.durphase1]
	add bx,word [esi+vehtype.durphase2]
	sub bx,byte 24		// 2 years before
	cmp ax,bx
	jb short .engineloop	// not old enough yet

	bt dword [edi+vehtypeinfo.climates],edx	// available in this climate?
	jnc short .engineloop

	mov word [esi+vehtype.engineage],bx	// set age back
	mov word [esi+vehtype.playeravail],-1
	and byte [esi+vehtype.availinfo],~ 3
	or byte [esi+vehtype.availinfo],1	// make it available if it wasn't

.engineloop:
	add esi,byte vehtype_size
	add edi,byte vehtypeinfo_size
	inc ecx
	cmp ecx,totalvehtypes
	jb .nextengine

	// clc is unnecessary
	ret
; endp allvehiclescheat

proc removevehiclescheat
	slocal engineuse,dword,totalvehtypes/4/8

	_enter

	call findusedengines

	mov esi,vehtypearray
//	mov edx,v(d,enginepowers)
	xor ecx,ecx
.nextengine:
	bt [%$engineuse],ecx
	jc short .engineloop

// this is now handled by setting engineuse for all waggons
//	cmp ecx,116	// first 116 engine types are railroad engines/waggons
//	ja short @@notrailroad
//
//	// for railroad, we don't remove the waggons (i.e. vehicles w/o power)
//	cmp word ptr [edx+ecx*2],0
//	je short @@engineloop
//	bt v(d,istrainengine),ecx
//	jnc short @@engineloop
//
//
//@@notrailroad:
		// this engine is in not use, so remove it
	mov ax,word [esi+vehtype.engineage]
	mov bx,word [esi+vehtype.durphase1]
	add bx,word [esi+vehtype.durphase2]
	add bx,word [esi+vehtype.durphase3]
	add bx,180		// half a year after it disappears
	cmp ax,bx
	jnb short .engineloop	// too old already
	mov word [esi+vehtype.engineage],bx
	mov word [esi+vehtype.playeravail],0
	and byte [esi+vehtype.availinfo],~ 3
	or byte [esi+vehtype.availinfo],1	// mark it as "used to be available"

.engineloop:
	add esi,byte vehtype_size
	inc ecx
	or ch,ch		// cmp ecx,totalengines (100h)
	jz .nextengine
	// clc is not necessary
	_ret
endproc // removevehiclescheat

clearpresignalscheat:
	call getnumber
	// if edx is not 0,-1 we clear even manual signals
	or edx,edx
	setg bl		// bl=clear manual signals?

	xor ecx,ecx
	dec cx		// this will miss fs:[0] but there can never be a signal anyway

	// this always clears signals of all players (for now anyway)
.nextsquare:
	mov al,[landscape4(cx,1)]
	and al,0xf0
	cmp al,0x10
	je short .istrack

.nextloop:
	loop .nextsquare
	call redrawscreen
	clc
	ret

.istrack:
	mov al,[landscape5(cx,1)]
	and al,0x80+0x40		// 40+80h=depot  40h=signal
	cmp al,0x40
	jne .nextloop		// not a signal

	// is it a manual setup
	test byte [nosplit landscape3+1+ecx*2],0x80
	jz short .notmanual

	// it's manual, only clear if bl is not 0
	or bl,bl
	jz .nextloop

.notmanual:
	and byte [nosplit landscape3+1+ecx*2],~ 0x87
	jmp .nextloop

; endp clearpresignalscheat

// clear all ghost stations:
// - train station squares not connected to a train station entry
// - train station entries with no train station squares
proc ghoststationcheat
	slocal hassquares,dword,256/4/8	// 256=max number of stations

	_enter

		// clear hassquares array
	xor eax,eax
	lea edi,[%$hassquares]
	lea ecx,[eax+256/4/8]		// mov ecx,... in 3 bytes
	rep stosd

	// first check all squares, whether there are train station parts
	// not connected to an actual station
.nextsquare:
	mov dh,[landscape4(cx,1)]
	and dh,0xf0
	cmp dh,0x50
	jne short .donext

	mov dl,[landscape5(cx,1)]
	cmp dl,8
	jnb short .donext

	call .checksquare

.donext:
	loop .nextsquare,cx	// loop using only cx => 65536 squares

	// now go through all stations, check whether there are stations
	// which should have a train facility but don't.

	mov cl,numstations
	mov edi,stationarray
	xor ebx,ebx	// current station index

.nextstation:
	cmp word [edi+station.XY],byte 0
	jz short .skip		// no entry here

	test byte [edi+station.facilities],1
	setnz al

	cmp word [edi+station.railXY],byte 0
	setnz ah

	xor ah,al
	jnz short .bad		// either has no facility but a position or vice versa

	or al,al
	jz short .skip		// no train facility at all

	bt [%$hassquares],ebx
	jc short .skip		// has a facility, and actual squares too

.bad:
	// ok, so it claims to have a train facility, but there are no
	// squares.  Remove the train facility, and if it was the only thing,
	// mark it as an expiring station

	mov word [edi+station.railXY],0
	and byte [edi+station.facilities],~ 1
	jnz short .skip	// there are still facilities left

	// turn it into a gray sign
	// I don't know what all these instructions really do, but
	// that's how TTD does it
	bts dword [edi+0x1a],0
	mov byte [edi+0x7e],0
	mov byte [edi+station.owner],0x10

.skip:
	inc ebx
	add edi,station_size
	loop .nextstation

	call fixrvstation

	call redrawscreen

	clc
	_ret

.checksquare:
	movzx esi,byte [landscape2+ecx]
	imul edi,esi,station_size
	add edi,stationarray

	test byte [edi+station.facilities],1
	jz short .clear	// station has no train facility -> clear square

	mov ax,word [edi+station.railXY]
	or eax,eax
	jz short .clear	// no coordinates

	mov ebx, edx
	mov dl,byte [edi+station.platforms]
	xchg esi, edi
	call convertplatformsinremoverailstation
	xchg esi, edi
	xchg edx, ebx
	//bl=tracks, bh=length

	test dl,1	// horizontal or vertical?
	jnz short .vertical

	xchg bh,bl

.vertical:

	// check square is within specified size
	cmp cl,al
	jb short .clear
	cmp ch,ah
	jb short .clear
	add ax,bx
	cmp cl,al
	jae short .clear
	cmp ch,ah
	jae short .clear

	// looks like this is a valid square, so leave it

	bts [%$hassquares],esi	// this entry really has some squares
	ret

	// square is not part of the corresponding station entry, so clear it
.clear:
	sub byte [landscape4(cx,1)],0x40	// turn station into tracks
	and dl,1                                // dl still has gs:[ecx]
	inc dl
	mov byte [landscape5(cx,1)],dl
//	getds <mov byte ptr [X+ecx],10h>,landscape1,2,1	// no owner
	mov byte [landscape2+ecx],0
//	getds <mov word ptr [X+ecx*2],0>,landscape3,2,1
	ret

endproc // ghoststationcheat


fixrvstation:
	mov eax,stationarray
	mov ecx,numstations

.nextstation:
	cmp word [eax+station.XY], 0
	je .doloop

	cmp word [eax+station.lorryXY], 0
	je .checkbus
	movzx ebx, word [eax+station.lorryXY]
	
	mov dh,[landscape4(bx,1)]
	and dh,0xf0
	cmp dh,0x50
	je .couldbestationtiletruck
	// we don't know what it is, but we will fix the station entry for lorry
	mov word [eax+station.lorryXY], 0
	and byte [eax+station.facilities],~ 3
	jnz .checkbus

	// copied from ghoststation:
	// turn it into a gray sign
	// I don't know what all these instructions really do, but
	// that's how TTD does it
	bts dword [eax+0x1a],0
	mov byte [eax+0x7e],0
	mov byte [eax+station.owner],0x10
	// /copy
	jmp .checkbus
.couldbestationtiletruck:
	mov dl, numstations
	sub dl, cl

	cmp dl, byte [landscape2+ebx]
	jne .checkbus

	mov dl, byte [landscape5(bx,1)]
	cmp dl, 0x46
	jbe .checkbus
	mov byte [landscape5(bx,1)], 0x43	// fix the tile

.checkbus:
	// we don't need to check bus currently

.doloop:
	add eax,0x8e		// next station
	loop .nextstation
	clc
	ret





playeridcheat:
#if WINTTDX
	cmp byte [numplayers],2
	jne .noenhmulti
	testflags enhancemultiplayer
	jnc .noenhmulti

	// this cheat isn't supported with enhmulti
	stc
	ret

.noenhmulti:
#endif
	movzx ecx,byte [curplayer]

	mov eax,[human1]
	cmp cl,al
	jne short .maybeplayer2

	mov al,0
	jmp short .getpar

.maybeplayer2:
	cmp cl,ah
	jne short .bad		// shouldn't happen...

	mov al,1

.getpar:
	and eax,byte 1

	call getnumber
	or edx,edx
	jns short .notbacktoold

	movzx edx,byte [landscape3+ttdpatchdata.orgpl1+eax]

.notbacktoold:
	cmp dl,7
	ja short .bad
	mov ecx,edx

	call getnumber
	or edx,edx
	setg dh		// set if only temporary (any number >0)

	mov dl,cl

	imul ebx,ecx,player_size
	add ebx,[playerarrayptr]
	cmp word [ebx],byte 0
	jne short .check

		// no such player
.bad:
	stc
	ret


.check:
	// now eax=player number that wants to change (0=1st, 1=2nd)
	// dl=new player id
	// dh=1 if temporary

	mov ecx,eax
	xor ecx,byte 1

	// make sure not to change to the other player in multiplayer
	cmp dl,[human1+ecx]
	je short .bad

.change:
	mov [human1+eax],dl

	or dh,dh
	jnz short .temp

	// permanently take over
	mov [landscape3+ttdpatchdata.orgpl1+eax],dl

.temp:
	clc
	ret

; endp playeridcheat

nounloadcheat:
	call getnumber
	jc .gotmask

	mov cl,dl
	mov dl,1
	shl dl,cl

.gotmask:
	movzx ebx,dl

	mov edi,[veharrayptr]
	add edi,byte -vehiclesize	//sub edi,byte vehiclesize

.nextvehicle:
	sub edi,byte -vehiclesize	//add edi,vehiclesize
	cmp edi,[veharrayendptr]
	jne short .checkveh

	call redrawscreen

	ret

.checkveh:
	movzx eax,byte [edi+veh.class]
	sub al,0x10
	jb .nextvehicle

	bt ebx,eax
	jnc .nextvehicle

	xchg esi, edi
	call checkowner.veh
	xchg esi, edi
	jnc .nextvehicle

	mov esi,dword [edi+veh.scheduleptr]
	or esi,esi
	js .nextvehicle

	movzx ecx,byte [edi+veh.totalorders]
	jecxz .nextvehicle

.nextcommand:
	lodsw
	mov dh,al
	and dh,0x1f
	cmp dh,1
	jne short .notforcedunload

	test al,0x20
	jz short .notforcedunload

	and al,~ 0x20
	mov [esi-2],ax

.notforcedunload:
	loop .nextcommand
	jmp .nextvehicle
; endp nounloadcheat


#if 0
// Activate/deactivate graphics
graphicscheat:
	call gethexnumber
	xchg eax,edx

	// could use bswap here but TTDPatch should run on a 386 too....
	xchg al,ah
	rol eax,16
	xchg al,ah

	call getnumber
	cmp edx,1
	jna .gotit
	js .doactivate

.bad:
	stc
	ret

.doactivate:
	mov dl,1

.gotit:
	call setgrfidact
	test dh,dh	// ID not found
	jz .bad
	jmp short doresetgraphics
#endif

resetvehiclescheat:
	call makegrfidlist
#if 0
	mov eax,[currentdate]
	push eax
	cmp ax,0xb97a		// 2050
	jbe .ok

	mov word [currentdate],0xb97b

.ok:
#endif
	mov ax,0x100
	call doresetgraphics.yesdo
#if 0
	pop eax
	mov [currentdate],ax
#endif
	ret

global doresetgraphics
doresetgraphics:
	mov ax,0x101		// make sure we don't reset everything in newvehtypeinit
.yesdo:
	push dword [currentdate]
	cmp word [currentdate],0xb97a	// 2050
	jbe .dateok
	mov word [currentdate],0xb97a
.dateok:
	call newvehtypeinit
// now done in newvehtypeinit	 call monthlyengineloop	// enable persistent engines right away
	call updatevehvars
	call resetnewsprites
	call redrawscreen
	pop dword [currentdate]
	ret
; endp resetvehiclescheat

semaphorecheat:
	call getnumber
	test edx,edx
	setnz ah
	shl ah,3

	mov al,0xff	// all track types
	call getnumber
	test edx,edx
	js .alltracks

	mov al,0
	bts eax,edx

.alltracks:
	xchg eax,edx
	mov edi,landscape3
	xor ecx,ecx
	dec cx		// this will miss fs:[0] but there can never be a signal anyway

	// this always clears signals of all players (for now anyway)
.nextsquare:
	mov al,[landscape4(cx,1)]
	and al,0xf0
	cmp al,0x10
	je short .istrack

.nextloop:
	loop .nextsquare
	call redrawscreen
	clc

	ret

.istrack:
	mov al,[landscape5(cx,1)]
	and al,0x80+0x40		// 40+80h=depot  40h=signal
	cmp al,0x40
	jne .nextloop			// not a signal

	mov al,[edi+ecx*2]
	and eax,0xf
	bt edx,eax
	jnc .nextloop

	mov al,[edi+1+ecx*2]
	and al,~8
	or al,dh
	mov [edi+1+ecx*2],al
	jmp .nextloop

#ifndef RELEASE
grfdebugcheat:
	extern grfdebug_feature,grfdebug_id,grfdebug_callback,grfdebug_active
	xor eax,eax
	xchg eax,[grfdebug_active]
	call getnumber
	cmp edx,1
	je .active

	test eax,eax
	jz .done

	mov bx,ax
	mov ax,0x3e00
	CALLINT21

.done:
	ret

.active:
	test eax,eax
	jnz .isopen

	noglobal varb .grfdebugfile, "grfdebug.log",0
	mov ah,0x3c
	xor ecx,ecx
	mov edx,.grfdebugfile
	CALLINT21
	jnc .isopen

	noglobal varb .cantopen, 0x98,"failed to create grfdebug.log",0
	mov dword [specialerrtext1],.cantopen
	mov bx,statictext(specialerr1)
	mov dx,-1
	xor ax,ax
	xor cx,cx
	call dword [errorpopup]
	stc
	ret

.isopen:
	mov [grfdebug_active],ax

	call getnumber
	mov [grfdebug_feature],edx

	call getnumber
	mov [grfdebug_id],edx

	call getnumber
	mov [grfdebug_callback],edx
	clc
	ret
#endif

//Shows values of the landscape arrays in the sign text,
//maybe helps finding out more info about landscape arrays.
//Without allowing identical signs, this cheat gives you a lot of headache
//when you try to query two or more identical tiles.
landinfocheat:
	call skipspaces
	mov edi,[esp+4]
	call getsignxy

	push edi // Makes the need Red Box
	push ebx
	mov edi, landdispl
	mov ebx, 0

	mov dx, si // Adds The XY of the Tile to the Sign
	xchg dh, dl
	call writehexbyte
	dec ebx
	xchg dh,dl
	call writehexbyte

	mov dl,[esi+landscape1]
	call writehexbyte
	mov dl,[esi+landscape2]
	call writehexbyte
	mov edx,[esi*2+landscape3]
	xchg dh,dl
	call writehexbyte
	dec ebx
	xchg dh,dl
	call writehexbyte
	mov dl,[landscape4(si,1)]
	call writehexbyte
	mov dl,[landscape5(si,1)]
	call writehexbyte

	// Please note that if a landscape isn't loaded it has a value of 0x80000000 or 0x0
	mov edx,landscape6
	test edx,edx
	jle .no_l6
	mov dl,[edx+esi]
	call writehexbyte

.no_l6:
	mov edx, landscape7 // Adds L7 information to the sign
	test edx,edx
	jle .no_l7
	mov dl, [edx+esi]
	call writehexbyte

.no_l7:
	mov edx, landscape8 // Adds L8 information to the sign
	test edx,edx
	jle .no_l8
	mov dx, [edx+esi*2]
	xchg dh, dl
	call writehexbyte
	dec ebx
	xchg dh,dl
	call writehexbyte

.no_l8:
	mov byte [edi+ebx],0

	mov dword [specialerrtext1],landdisp // Copied from below to make a red box
	mov bx, statictext(specialerr1)
	mov dx, -1
	xor ax, ax
	xor cx, cx
	push ebp
	call dword [errorpopup]
	pop ebp
	pop ebx
	pop edi

	clc
	ret

writehexbyte:
	mov al,dl

	mov ah,dl
	shr al,4
	and ah,0xf
	cmp ah,0xa
	jae .letter1
	add ah,"0"
	jmp short .secondnum
.letter1:
	add ah,"A"-10
.secondnum:
	cmp al,0xa
	jae .letter2
	add al,"0"
	jmp short .end
.letter2:
	add al,"A"-10
.end:
	mov [edi+ebx],ax
	mov byte [edi+ebx+2]," "
	add ebx,3
	ret

var landdisp, db 94h, "LAND:  "
var landdispl, times 36 db 0

#if 1 && DEBUG

landdispcheat:
	call skipspaces
	mov edi,[esp+4]
	call getsignxy
	push edi
	push ebx
	mov edi, landdispl
	mov ebx, 0 
	
	CALLINT3

	mov dl,[esi+landscape1]
	call writehexbyte
	mov dl,[esi+landscape2]
	call writehexbyte
	mov dx,[esi*2+landscape3]
	xchg dh,dl
	call writehexbyte
	dec ebx
	xchg dh,dl
	call writehexbyte
	mov dl,[landscape4(si,1)]
	call writehexbyte
	mov dl,[landscape5(si,1)]
	call writehexbyte

	mov edx,landscape6
	or edx,edx
	jz .no_l6

	mov dl,[edx+esi]
	call writehexbyte
.no_l6:

	mov edx,landscape7
	or edx,edx
	jz .no_l7

	mov dl,[edx+esi]
	call writehexbyte
.no_l7:

	mov dword [specialerrtext1],landdisp
	mov bx,statictext(specialerr1)
	mov dx,-1
	xor ax,ax
	xor cx,cx
	push ebp
	call dword [errorpopup]
	pop ebp
	pop ebx
	pop edi
	clc
	ret
#endif


removehqcheat:
	push eax

	movzx eax,byte [human1]		// receive the current player/company
	imul esi,eax,player_size
	add esi,[playerarrayptr]	// receive the player/company struct
	mov ax,-1
	xchg ax,[esi+player.hqlocation]	// reset it, so its not already build
	cmp ax,byte -1
	je .removedone

	push byte -1
	push eax	// remove four tiles; eax, eax+1, eax+101h, eax+100h
	inc eax
	push eax
	inc ah
	push eax
	dec eax

.removenext:
	mov byte [landscape1+eax],10h
	mov byte [landscape2+eax],0
	mov word [landscape3+eax*2],0
	and byte [landscape4(ax,1)],0x0f
	mov byte [landscape5(ax,1)],0

	pop eax
	test eax,eax
	jns .removenext

.removedone:
	call redrawscreen
	pop eax
	clc
	ret

planttreecheat:

	mov ecx,3		// up to 3 parameters
	push byte -1		// where params are stored

.nextparam:
	mov [esp+ecx-1],dl	// first store will be disregarded, last we don't need

	call getnumber
	test edx,edx
	js .paramdone		// no param -> rest is default
	jnz .paramok		// zero is an invalid parameter

.error:
	pop eax
.error2:
	stc
	ret

.paramok:
	dec edx
	cmp edx,255		// maximum is 256
	jna .nottoomuch

	mov dl,255

.nottoomuch:
	loop .nextparam

.paramdone:
	pop eax

	cmp al,-1
	jne .xyset

	cmp ah,al
	jne .xset

	mov ah,40
.xset:
	mov al,ah
.xyset:

	test dl,dl
	js .random

	mov cl,[climate]	// all but cl were zero already
	cmp dl,[treenum+ecx]
	jnb .error2

	add dl,[treestart+ecx]

.random:
	push edx

	push esi
	call getsignxy
	mov edx,esi
	mov ecx,esi
	pop esi

	shr ah,1

	sbb dl,ah		// if [%$xsize] was odd, subtract one more
	jnc .x1correct

	mov dl,0

.x1correct:
	add cl,ah
	jnc .x2correct

	mov cl,255

.x2correct:
	shr al,1

	sbb dh,al
	jnc .y1correct

	mov dh,0

.y1correct:
	add ch,al
	jnc .y2correct

	mov ch,255

.y2correct:
	// now edx, ecx = top-left and bottom-right corner

	push edx
	call checkcost		// call checkcost with the original ebx
	mov ebx,edx
	pop edx

	pop eax			// now eax=tree type

	push ebx

	lea esi,[edx-1]		// don't exclude any squares
	mov edi,esi

	test bl,bh
	mov bh,al
	jz .nocost		// sign cheats don't cost or checking cost only

	pusha

	mov bl,0		// cheat costs and we have to do it - but first check if player has enough money

	call planttreearea	// in manytree.asm
	call checkmoney
	popa
	jl .error

.nocost:
	call planttreearea

	pop eax			// eax = output of checkcost
	mov cl,expenses_other	// trees are accounted under "Other"
	call docost
	call showcost
	clc
	ret


climatecheat:	
	mov dl, 0
	call getnumber
	cmp edx, byte 3
	jg .badparameters
	mov byte [climate], dl
	clc
	ret
.badparameters:
	stc
	ret

#if 0
// doesn't work anymore; uses the enhgui and newstations instead
morestationsetset:
	mov dl, 0
	call getnumber
	cmp edx, byte 5
	jg .badparameters
	mov byte [morestationcurtyp], dl
	clc
	ret
.badparameters:
	stc
	ret
#endif


// Launch TTD's built-in debugger
debuggercheat:
	xor ebx,ebx
	mov ebp,[ophandler+8*0xb]
	call [ebp+4]
	clc
	ret

subsidycheat:
	call dword [subsidyfn]
	clc
	ret


soundeffectcheat:
	call getnumber
	xchg eax,edx
	mov esi,-1
	mov edi,[activesign]
	mov bx,[edi+sign.x]
	mov cx,[edi+sign.y]
	call [generatesoundeffect]
	ret

statresetcheat:
	push esi
	call getsignxy
	mov edi,esi
	pop esi
	mov al,[landscape4(di)]
	and al,0xf0
	cmp al,0x50
	je .isstation
	mov word [cheaterror],ourtext(nostationhere)
	stc
	ret

.isstation:
	movzx edi,byte [landscape2+edi]
	push edi
	imul edi,station_size
	add edi,stationarray
	or eax,-1
	call getnumber
	jc .all
	xor eax,eax
	bts eax,edx
.all:
	mov ecx,12
.loop:
	lea ebx,[ecx-1]
	testflags newcargos
	jnc .gotcargo
	movzx ebx, byte [edi+station2ofs+station2.cargos+(ecx-1)*8+stationcargo2.type]
	or bl,bl
	js .next	// unused slot

.gotcargo:
	bt eax,ebx
	jnc .next
	and word [edi+station.cargos+(ecx-1)*8+stationcargo.amount],0
	mov byte [edi+station.cargos+(ecx-1)*8+stationcargo.enroutefrom],-1
	mov byte [edi+station.cargos+(ecx-1)*8+stationcargo.lastspeed],0

	testflags newcargos
	jnc .next

	btr dword [edi+station2.acceptedcargos], ebx
	mov byte [edi+station2ofs+station2.cargos+(ecx-1)*8+stationcargo2.type], 0xff

.next:
	loop .loop
	pop ebx
	mov al,0x11
	call dword [invalidatehandle]
	clc
	ret

lostwagonscheat:
	call findengines

	mov esi,[veharrayptr]

.nextveh:
	cmp byte [esi+veh.class],0x10
	jne .notlost
	mov ax,[esi+veh.idx]
	cmp ax,[esi+veh.engineidx]
	jne .notlost

	cmp byte [esi+veh.subclass],0
	je .notlost
	cmp byte [esi+veh.subclass],4
	je .notlost

	mov byte [esi+veh.subclass],4

.notlost:
	sub esi,byte -0x80
	cmp esi,[veharrayendptr]
	jb .nextveh
	call redrawscreen
	ret
	
restartconstcheat:
	call getsignxy
	mov al,[landscape4(si)]
	and al,0xf0
	cmp al,0x30
	je .ishouse
	cmp al,0x80
	je .isindustry
	mov word [cheaterror],6
	stc
	ret

.isindustry:
	movzx eax,byte [landscape2+esi]
	imul edi,eax,industry_size
	add edi,[industryarrayptr]

	movzx ebx,word [edi+industry.XY]
	mov cx,[edi+industry.dimensions]
.nexty:
	mov bl,[edi+industry.XY]
	mov cl,[edi+industry.dimensions]
.nextx:
	mov dl,[landscape4(bx)]
	and dl,0xf0
	cmp dl,0x80
	jne .skip

	cmp [landscape2+ebx],al
	jne .skip

	mov byte [landscape1+ebx],0
	mov esi,ebx
	call redrawtile

.skip:
	inc bl
	dec cl
	jnz .nextx

	inc bh
	dec ch
	jnz .nexty

	clc
	ret

.ishouse:
	gethouseid ebp,esi
	mov ebx,[houseflags]
	test byte [ebx+ebp-3],0x10
	jz .notS
	sub esi,0x101
	sub ebp,3
	jmp short .foundmaintile
	
.notS:
	test byte [ebx+ebp-2],0x10
	jz .notW2x2
	dec esi
	dec ebp
	dec ebp
	jmp short .foundmaintile
	
.notW2x2:
	test byte [ebx+ebp-1],0x18
	jz .notE
	sub esi,0x100
	dec ebp
	jmp short .foundmaintile

.notE:
	test byte [ebx+ebp-1],4
	jz .foundmaintile
	dec esi
	dec ebp
	
.foundmaintile:
	call .restartbuild
	mov al,[ebx+ebp]
	test al,0x10
	jz .not2x2
	inc esi
	call .restartbuild
	add esi,-1+0x100
	call .restartbuild
	inc esi
	call .restartbuild
	clc
	ret
	
.not2x2:
	test al,8
	jz .not1x2
	add esi,0x100
	call .restartbuild
	clc
	ret
	
.not1x2:
	test al,4
	jz .not2x1
	inc esi
	call .restartbuild
.not2x1:
	clc
	ret
	

.restartbuild:
	and byte [landscape3+2*esi],~0xc0
	and byte [landscape5(si)],~7
	jmp redrawtile

resetpbscheat:
	testflags pathbasedsignalling
	cmc
	jc .done

	call resetpathsignalling
	call redrawscreen
	clc
.done:
	ret


deletevehcheat:
	call getsignxy
	mov edi,esi

	mov edx,loadremovedvehs
	mov eax,[veharrayptr]
	mov ecx,eax
.next:
	cmp byte [ecx+veh.class],0x10
	jb .nothere
	cmp byte [ecx+veh.class],0x13
	ja .nothere
	cmp [ecx+veh.XY],di
	jne .nothere
	mov bl,[curplayer]
	cmp bl,[ecx+veh.owner]
	jne .nothere

	call deleteconsist

.nothere:
	sub ecx,byte -veh_size
	cmp ecx,[veharrayendptr]
	jb .next
	call redrawscreen
	clc
	ret

resetfifocheat:
	call clearfifodata
	clc
	ret

#if DEBUG
positioncheat:
	call skipspaces
	mov edi,[esp+4]
	call getsignxy
	mov edx,esi

	call writehexbyte
	xchg dh,dl
	call writehexbyte

	dec ebx

	mov byte [edi+ebx],0
	clc
	ret

snowlinecheat:
	call getnumber
	jc .exit
	mov [snowline],dl
.exit:
	ret	

gotocheat:
	call gethexnumber
	mov eax,edx
	shl eax,4
	call gethexnumber
	mov ecx,edx
	shl ecx,4
	jmp [setmainviewxy]
#endif

resetinducheat:
	call clearindustryincargos
extern clearindustry2array
	call clearindustry2array
	mov edi,[industryarrayptr]
	movzx ecx, byte [numindustries]
.nextindu:
	cmp word [edi+industry.XY],0
	je .skipindu
	movzx eax,byte [edi+industry.type]
	mov ebx,[industryproducedcargos+eax*2]
	mov [edi+industry.producedcargos],bx
	and dword [edi+industry.amountswaiting],0
	mov bl,[industryprod1rates+eax]
	mov bh,[industryprod2rates+eax]
	mov [edi+industry.prodrates],bx
	mov byte [edi+industry.prodmultiplier],0x10
	mov ebx,[industryacceptedcargos+eax*4]
	mov [edi+industry.accepts],bx
	shr ebx,16
	mov [edi+industry.accepts+2],bl
.skipindu:
	add edi,industry_size
	loop .nextindu

	call redrawscreen
	clc
	ret

textidcheat:
	call gethexnumber
	jc .error

	mov ebx,edx
	or edx,-1
	xor eax,eax
	xor ecx,ecx
	call [errorpopup]

	clc
.error:
	ret

facecheat:
	movzx eax,byte [curplayer]
	imul eax,player_size
	add eax,[playerarrayptr]

	call gethexnumber
	jc .show

	mov [eax+player.face],edx
	call redrawscreen

	xor ebx,ebx
.show:
	getwriteloc 4
	mov edx,[eax+player.face]
	jmp usedcheat.showhex

	extern initializecargofn
resetcargocheat:
	call [initializecargofn]
	clc
	ret

svard landgen_forceparam
landgencheat:
	call getnumber
	xchg eax,edx
	jc .done
	call getnumber
	mov ah,dl
	call getnumber
	shl edx,16
	or eax,edx
.done:
	mov [landgen_forceparam],eax
	clc
	ret

extern cleanuphousedataids	// in newhouse.asm
extern housedataidtogameid,lasthousedataid

purgehousescheat:
	mov esi,housedataidtogameid
	sub esp,256			// create the mapping array on stack
	mov ebx,esp
	mov dl,[lasthousedataid]
	call cleanuphousedataids
	mov [lasthousedataid],dl

	xor esi,esi
.nexttile:
	mov al,[landscape4(si)]
	shr al,4
	cmp al,3
	jne .skiptile

	mov al,[landscape3+2*esi+1]	// old dataid
	xlatb
	mov [landscape3+2*esi+1],al

.skiptile:
	inc si
	jnz .nexttile

	add esp,256			// free mapping array

	clc
	ret

extern cleanupindustrytypes	// in newindu.asm
extern industiledataidtogameid,lastindustiledataid

purgeindustriescheat:
	call cleanupindustrytypes

	mov esi,industiledataidtogameid
	sub esp,256			// create the mapping array on stack
	mov ebx,esp
	mov dl,[lastindustiledataid]
	call cleanuphousedataids
	mov [lastindustiledataid],dl

	xor esi,esi
.nexttile:
	mov al,[landscape4(si)]
	shr al,4
	cmp al,8
	jne .skiptile

	mov al,[landscape3+2*esi+1]	// old dataid
	xlatb
	mov [landscape3+2*esi+1],al

.skiptile:
	inc si
	jnz .nexttile

	add esp,256			// free mapping array

	clc
	ret
	
unreservepbstrack:
	call getsignxy
	movzx eax, BYTE [landscape4(si)]
	movzx ecx, BYTE [landscape5(si)]
	
	and al,0xf0
	cmp al,0x10
	je .rail
	cmp al,0x20
	je .roadcrossing
	cmp al,0x50
	je .station
	cmp al,0x90
	jne .fret
.bridgeortunnel:
	test cl, 0x8C
	js .bridge
	jnz .fret	//road bridge
	jmp .btclear
.bridge:
	test cl, 6
	jnz .fret	//not rail
.btclear:
	mov BYTE [landscape6+esi], 0
	jmp .done
.rail:
	test cl, 0xC0
	js .fret	//depot
	jnz .signal
	and BYTE [landscape6+esi], ~0x1F
	jmp .done
.signal:
	and BYTE [landscape6+esi], ~0xF0
	jmp .done
.roadcrossing:
	and cl,0xf0
	cmp cl,0x10	// crossing?
	jne .fret
	and BYTE [landscape5(si)], ~0x4
	jmp .done
.station:
	cmp cl, 0x8
	jae .fret	//not train
	and byte [landscape3+esi*2],~0x80
//	jmp .done
.done:
	mov eax, esi
	movzx ecx, ah
	shl ecx, 4
	movzx eax, al
	shl eax, 4
	call [invalidatetile]
.tret:
	clc
.ret:
	ret
.fret:
	stc
	ret

#if 1 && DEBUG
	//parameters: 4 hex digits source coordinates, decimal integer x extent (NE->SW), decimal integer y extent (NW->SE), optional 4 hex digits dest coords
clonetilecheat:
	call gethexnumber
	jc NEAR .ret
	test edx, 0xFFFF0000
	jnz NEAR .fret
	mov ecx, edx
	call getnumber
	test edx, 0xFFFFFF00
	jnz NEAR .singtile
	or edx, edx
	jz NEAR .singtile
	mov al, dl
	call getnumber
	test edx, 0xFFFFFF00
	jnz NEAR .singtile
	or edx, edx
	jz NEAR .singtile
	mov ah, dl
	call gethexnumber
	jc .getsxy
	test edx, 0xFFFF0000
	jnz NEAR .fret
	mov esi, edx
	jmp .gotsxy
.getsxy:
	call getsignxy
.gotsxy:
	mov bx, ax
	
	mov ax, si
	add al, bl
	jc .singtile2
	add ah, bh
	jc .singtile2
	jmp .nsingtile
.singtile:
	call getsignxy
	mov ax, si
.singtile2:
	mov ebx, 0x101
.nsingtile:
	mov edx, esi
	mov ah, bh

.loop:
	mov al, [landscape1+ecx]
	mov [landscape1+edx], al
	mov al, [landscape2+ecx]
	mov [landscape2+edx], al
	mov bp, [landscape3+ecx*2]
	mov [landscape3+edx*2], bp
	mov al, [landscape4(cx,1)]
	and al, 0xF0
	and BYTE [landscape4(dx,1)], 0x0F
	or [landscape4(dx,1)], al
	mov al, [landscape5(cx,1)]
	mov [landscape5(dx,1)], al
	mov al, [landscape6+ecx]
	mov [landscape6+edx], al
	mov al, [landscape7+ecx]
	mov [landscape7+edx], al
	mov edi, landscape8
	test edi,edi
	jle .end
	mov bp, [edi+ecx*2]
	mov [edi+edx*2], bp
.end:
	pushad
	movzx eax, dl
	shl eax, 4
	movzx ecx, dh
	shl ecx, 4
	call [invalidatetile]
	popad
	inc ch
	inc dh
	dec bh
	jnz NEAR .loop
	sub ch, ah
	sub dh, ah
	mov bh, ah
	inc cl
	inc dl
	dec bl
	jnz NEAR .loop

.tret:
	clc
.ret:
	ret
.fret:
	stc
	ret
	
	
	//parameters: hex dword new values, hex dword bit mask, hex byte offset (max 32h), flag: (0/1) return existing dword
setindustrystrucval:
	call gethexnumber
	jc NEAR .fret
	mov ecx, edx
	call gethexnumber
	jc NEAR .fret
	mov ebp, edx
	call gethexnumber
	jc NEAR .fret
	cmp edx, 32h
	jae NEAR .fret
	push edx
	call gethexnumber
	jc NEAR .pfret
	xchg edx, [esp]
	call getsignxy

	mov al, [landscape4(si)]
	shr al, 4
	cmp al, 8
	jne NEAR .pfret //not an industry
	movzx eax, BYTE [esi+landscape2]
	add eax, eax
	lea eax, [eax*2+eax]
	lea eax, [eax*8+eax]	//*36h = industry structure width
	add eax, [industryarrayptr]
	add eax, edx
	mov edi, [eax]
	and ecx, ebp
	mov esi, edi
	not ebp
	and edi, ebp
	or edi, ecx
	mov [eax], edi
	pop eax
	or eax, eax
	jz .tret
	
	push edi
	mov edi, inddispl
	xor ebx, ebx
	call writehexbyte
	mov BYTE [edi+2], ':'

	mov edi, inddisp2
	xor ebx, ebx
	mov ecx, 4
	mov edx, esi
.loop:
	call writehexbyte
	shr edx, 8
	loop .loop
	
	mov edi, inddisp3
	xor ebx, ebx
	mov ecx, 4
	pop edx
.loop2:
	call writehexbyte
	shr edx, 8
	loop .loop2

	mov byte [edi+ebx],0

	mov dword [specialerrtext1],inddisp // Copied from below to make a red box
	mov bx, statictext(specialerr1)
	mov dx, -1
	xor ax, ax
	xor cx, cx
	push ebp
	call dword [errorpopup]
	pop ebp
.tret:
	clc
.ret:
	ret
.pfret:
	add esp, 4
.fret:
	stc
	ret
var inddisp, db 94h, "INDUSTRY:  "
var inddispl, db "##:  "
var inddisp2, db "##-##-##-## --> "
var inddisp3, db "##-##-##-##", 0,0

vard getlandscapearrayoffsets
dd getlandscape1
dd getlandscape2
dd getlandscape3
dd getlandscape4
dd getlandscape5
dd getlandscape6
dd getlandscape7
dd getlandscape8
endvar

vard setlandscapearrayoffsets
dd setlandscape1
dd setlandscape2
dd setlandscape3
dd setlandscape4
dd setlandscape5
dd setlandscape6
dd setlandscape7
dd setlandscape8
endvar

getlandscape1:
	movzx eax, BYTE [landscape1+esi]
	ret
setlandscape1:
	mov [landscape1+esi], al
	ret
getlandscape2:
	movzx eax, BYTE [landscape2+esi]
	ret
setlandscape2:
	mov [landscape2+esi], al
	ret
getlandscape3:
	movzx eax, WORD [landscape3+esi*2]
	ret
setlandscape3:
	mov [landscape3+esi*2], ax
	ret
getlandscape4:
	movzx eax, BYTE [landscape4(si)]
	ret
setlandscape4:
	mov [landscape4(si)], al
	ret
getlandscape5:
	movzx eax, BYTE [landscape5(si)]
	ret
setlandscape5:
	mov [landscape5(si)], al
	ret
getlandscape6:
	movzx eax, BYTE [landscape6+esi]
	ret
setlandscape6:
	mov [landscape6+esi], al
	ret
getlandscape7:
	movzx eax, BYTE [landscape7+esi]
	ret
setlandscape7:
	mov [landscape7+esi], al
	ret
getlandscape8:
	movzx eax, WORD [landscape8+esi*2]
	ret
setlandscape8:
	mov [landscape8+esi*2], ax
	ret

	//parameters: hex word new values, hex word bit mask, hex byte array (1-8), flag: (0/1) call display land info afterwards
setlandarrayval:
	pusha
	call gethexnumber
	jc NEAR .fret
	mov ecx, edx
	call gethexnumber
	jc NEAR .fret
	mov ebp, edx
	call gethexnumber
	jc NEAR .fret
	dec edx
	cmp edx, 8
	jae NEAR .fret
	push edx
	call gethexnumber
	jc NEAR .pfret
	xchg edx, [esp]
	call getsignxy
	movzx esi, si

	//esi=coords

	call DWORD [getlandscapearrayoffsets+edx*4]	//puts landscape value in eax
	and ecx, ebp
	not ebp
	and eax, ebp
	or eax, ecx
	call DWORD [setlandscapearrayoffsets+edx*4]
	pop eax
	or eax, eax
	jz .tret
	popa
	jmp landinfocheat
.tret:
	clc
.ret:
	popa
	ret
.pfret:
	add esp, 4
.fret:
	popa
	stc
	ret

// Arguments:
// - Object id (hex) 0..190
// - Layout number (dec/hex) 0..3
createnewobject:
	call gethexnumber // Result in dx
	mov ax, dx

	call gethexnumber // Result in dx
	jnc .arg2	// Argument 2 is optional
	mov dl, 0

.arg2:
	and dl, 3 // Should eliminate the need for sanity checks
	shl edx, 16
	mov dx, ax

	call getsignxy // results in esi
	mov edi, esi
	rol di, 4 // Store the x, y in the ax, cx registors
	mov eax, edi
	mov ecx, edi
	rol cx, 8
	and ax, 0x0FF0
	and cx, 0x0FF0
	ror di, 4
extern BuildObject_actionnum
	mov bl, [actionnestlevel]
	pusha
	mov bl, 0xB
	and byte [actionnestlevel], 0
	mov word [operrormsg1], ourtext(objecterr)
	dopatchaction BuildObject
	popa
	mov [actionnestlevel], bl
	clc
	ret

extern cargodestdebugflag
logcargodest:
	call gethexnumber
	jnc .param
	or edx, BYTE -1
.param:
	mov DWORD [cargodestdebugflag], edx
	clc
	ret
	
#endif

uvard fixordermessflags
uvard fixorderserr1
uvard fixorderserr2
uvard fixorderserr3
uvard fixorderserr4
uvard fixorderserr5
uvard fixorderserr6
uvard fixorderserr7
uvard fixorderserr8
uvard fixorderserr9
uvard fixorderserr10
uvard fixorderserr11
uvard fixorderserr12
uvard fixorderserr13
uvard fixorderserr14

fixorders:
	pushad
	
	xor eax, eax
	cld
	mov ecx, 15
	mov edi, fixordermessflags
	rep stosd
	
	call gethexnumber
	jc .passivenocheckflags
	cmp edx, 1
	jb .passive
	cmp edx, 2
	jb .fix1
	ja .passive
	call orderfixmethod2
	jmp .passive
.fix1:
	call orderfixmethod1
	
.passive:
	call gethexnumber
	jc .passivenocheckflags
	mov [fixordermessflags], edx
.passivenocheckflags:
	
	mov edi,[veharrayptr]
.next:
	cmp byte [edi+veh.class],0x10
	jb NEAR .iterate
	cmp byte [edi+veh.class],0x13
	ja NEAR .iterate
	mov eax, [edi+veh.scheduleptr]
	movzx ebx, BYTE [edi+veh.totalorders]
	cmp eax, -1
	je NEAR .iterate
	cmp eax, scheduleheap
	jb NEAR .err1
	cmp eax, scheduleheapend
	jae NEAR .err2
	cmp eax, [scheduleheapfree]
	jae NEAR .err3
	test eax, 1
	jnz NEAR .err14
	
	//inconsistent share length check
	call schedulesharecheck
	shr ecx, 16
	jz .doneshlcheck	//not the last vehicle with this shared order
	
	xor ecx, ecx
	mov edx, [veharrayptr]
.shlnext:
	cmp byte [edx+veh.class],0x10
	jb .shliterate
	cmp byte [edx+veh.class],0x13
	ja .shliterate
	cmp eax, [edx+veh.scheduleptr]
	jne .shliterate
	cmp bl, [edx+veh.totalorders]
	je .shliterate
	or cl, 1
.shliterate:
	sub edx,byte -veh_size
	cmp edx,[veharrayendptr]
	jb .shlnext
	add DWORD [fixorderserr13], ecx
.doneshlcheck:

	lea ecx, [eax+ebx*2]
	cmp WORD [ecx], 0
	jne NEAR .err4
	cmp ecx, scheduleheapend
	ja NEAR .err5
	je .noprecheck
	cmp eax, scheduleheap
	je .noprecheck
	cmp WORD [eax-2], 0
	jne NEAR .err6
.noprecheck:
	
	mov esi, eax
	jmp .orderloopcheck
.orderloop:
	mov dx, [esi]
	and dl, 0x1F
	cmp dl, 0
	jne NEAR .noerr7
	pushad
	lea eax, [esi+2]
	mov edx, [veharrayptr]
	mov ecx, 0x10001
	call schedulesharecheck.next
	shr ecx, 16
	jnz .noclash
	//clashing orders, help!
	popad
	jmp .err12	
	
.noclash:
	popad
	jmp .err7
.noerr7:
	cmp dl, 5
	ja NEAR .err8
	jb .orderloopcheckadv
	
	//specials
	mov dl, dh
	shr dh, 5	//number of extra words
	and dl, 0x1F	//special order type
	cmp dl, 6
	ja NEAR .err9
	cmp dl, 3
	setae dl
	cmp dl, dh
	ja NEAR .err10
	
.orderloopspecialerradv:
	movzx edx, dh
	lea esi,  [esi+edx*2]
	
	
.orderloopcheckadv:
	inc esi
	inc esi
.orderloopcheck:
	cmp esi, ecx
	jb NEAR .orderloop
	ja NEAR .err11
	
.iterate:
	sub edi,byte -veh_size
	cmp edi,[veharrayendptr]
	jb NEAR .next

	mov dword [specialerrtext1],fixorderdisp

	call orderfixoutmess

	popad
	clc
	ret
.err1:
	mov ecx, 1<<1
	call messagevehicleifflag
	inc DWORD [fixorderserr1]
	jmp .iterate	
.err2:
	mov ecx, 1<<2
	call messagevehicleifflag
	inc DWORD [fixorderserr2]
	jmp .iterate
.err3:
	mov ecx, 1<<3
	call messagevehicleifflag
	inc DWORD [fixorderserr3]
	jmp .iterate
.err14:
	push ecx
	mov ecx, 1<<14
	call messagevehicleifflag
	inc DWORD [fixorderserr3]
	jmp .iterate
.err4:
	mov ecx, 1<<4
	call messagevehicleifflag
	call schedulesharecheck
	add DWORD [fixorderserr4], ecx
	jmp .iterate	
.err5:
	mov ecx, 1<<5
	call messagevehicleifflag
	call schedulesharecheck
	add DWORD [fixorderserr5], ecx
	jmp .iterate
.err6:
	mov ecx, 1<<6
	call messagevehicleifflag
	call schedulesharecheck
	add DWORD [fixorderserr6], ecx
	jmp .iterate
.err7:
	pushad
	mov ecx, 1<<7
	call messagevehicleifflag
	call schedulesharecheck
	add DWORD [fixorderserr7], ecx
	popad
	jmp .orderloopcheckadv
.err12:
	pushad
	mov ecx, 1<<12 | 1<<7
	call messagevehicleifflag
	call schedulesharecheck
	add DWORD [fixorderserr7], ecx
	add DWORD [fixorderserr12], ecx
	popad
	jmp .orderloopcheckadv
.err8:
	pushad
	mov ecx, 1<<8
	call messagevehicleifflag
	call schedulesharecheck
	add DWORD [fixorderserr8], ecx
	popad
	jmp .orderloopcheckadv
.err9:
	pushad
	mov ecx, 1<<9
	call messagevehicleifflag
	call schedulesharecheck
	add DWORD [fixorderserr9], ecx
	popad
	jmp .orderloopspecialerradv
.err10:
	pushad
	mov ecx, 1<<10
	call messagevehicleifflag
	call schedulesharecheck
	add DWORD [fixorderserr10], ecx
	popad
	jmp .orderloopspecialerradv
.err11:
	mov ecx, 1<<11
	call messagevehicleifflag
	call schedulesharecheck
	add DWORD [fixorderserr11], ecx
	jmp .iterate
	
schedulesharecheck:
	mov ecx, 0x10001
	mov edx, edi
	jmp .iterate
.next:
	cmp byte [edx+veh.class],0x10
	jb .iterate
	cmp byte [edx+veh.class],0x13
	ja .iterate
	cmp eax, [edx+veh.scheduleptr]
	je .foundshare
	
.iterate:
	sub edx,byte -veh_size
	cmp edx,[veharrayendptr]
	jb .next
	ret
.foundshare:
	sub ecx, 0x10000
	ret
	
orderfixoutmess:
	push DWORD fixordertitletext
	call genoutmess
	ret
genoutmess:
#if WINTTDX
	sub esp, 1024
	mov edi, esp
	mov ax, statictext(specialerr1)
	call newtexthandler
	mov edi, esp
	push byte 0
	push DWORD [esp+4+1024+4] //fixordertitletext
	push edi
	push byte 0
	call [MessageBoxA]
	add esp, 1024
#else	
	mov bx, statictext(specialerr1)
	mov dx, -1
	xor ax, ax
	xor cx, cx
	call dword [errorpopup]
#endif
	ret 4

uvard orderfix1flags
uvard orderfix1truncated
uvard orderfix1extended
uvard orderfix1addedzero
	
orderfixmethod1:	//autofix order termination and length
			//you should probably not run this if errors 1, 2, 3 or 14 are present
			//this will perhaps "fix" errors 4,5,6,11,13
	pushad
	
	xor eax, eax
	mov [orderfix1truncated], eax
	mov [orderfix1extended], eax
	mov [orderfix1addedzero], eax
	mov [orderfix1flags], eax
	
	call gethexnumber
	jc .noflags
	mov [orderfix1flags], edx
.noflags:

	mov edi, [veharrayptr]
	jmp .iterate
.next:
	cmp byte [edi+veh.class],0x10
	jb NEAR .iterate
	cmp byte [edi+veh.class],0x13
	ja NEAR .iterate
	mov eax, [edi+veh.scheduleptr]
	cmp eax, -1
	je NEAR .iterate
	cmp eax, scheduleheap
	jb NEAR .iterate
	cmp eax, [scheduleheapfree]
	jae NEAR .iterate
	
	//found order starting at eax for vehicle edx
	//ebx is next order in list
	mov ebx, [scheduleheapfree]
	
	//inner iteration
	mov edx, [veharrayptr]
.loop:
	cmp byte [edx+veh.class],0x10
	jb .inneriterate
	cmp byte [edx+veh.class],0x13
	ja .inneriterate
	mov ecx, [edx+veh.scheduleptr]
	cmp ecx, eax
	jbe .inneriterate
	cmp ecx, ebx
	jae .inneriterate
	mov ebx, ecx	//new closest order above eax
	
.inneriterate:
	sub edx,byte -veh_size
	cmp edx,[veharrayendptr]
	jb .loop

	//ebx is the next order in the list from eax
	lea ecx, [ebx-2]
	sub ebx, eax
	shr ebx, 1
	dec ebx
	
	xor edx, edx
	xchg dx, [ecx]
	or dx, dx
	jz .nozeroset
	//this is mildly bad
	inc DWORD [orderfix1addedzero]
	mov ecx, 8
	call messagevehiclemeth1
.nozeroset:
	
	cmp [edi+veh.totalorders], bl 
	je .iterate
	//this is rather bad
	mov [edi+veh.totalorders], bl
	ja .trunc
	inc DWORD [orderfix1extended]
	mov ecx, 2
	call messagevehiclemeth1
	jmp .iterate
.trunc:
	inc DWORD [orderfix1truncated]
	mov ecx, 4
	call messagevehiclemeth1
		
.iterate:
	sub edi,byte -veh_size
	cmp edi,[veharrayendptr]
	jb .next

	mov dword [specialerrtext1], fixordermethod1
	call orderfixoutmess
	popad
	ret

messagevehiclemeth1:
	test [orderfix1flags], ecx
	jnz .teststop
	ret
.teststop:
	test BYTE [orderfix1flags], 1
	jz messagevehicle
	jmp messagevehicleandstop

messagevehicleifflag:	
	test [fixordermessflags], ecx
	jnz .teststop
	ret
.teststop:
	test BYTE [fixordermessflags], 1
	jz messagevehicle
messagevehicleandstop:
	cmp BYTE [edi+veh.class], 13h		//don't bother with planes
	je messagevehicle
	cmp DWORD [edi+veh.scheduleptr], BYTE -1
	je messagevehicle
	or BYTE [edi+veh.vehstatus], 2
	ret					//things seem to go wrong if both stop and open window are run (fixme?)
messagevehicle:
	pushad
	movzx eax,byte [edi+veh.class]
	mov eax,[ophandler+eax*8]
	call [eax+0x18]		// mouse click handler
	popad
ret

orderfixmethod2:
	pushad
	mov edi,[veharrayptr]
.next:
	cmp byte [edi+veh.class],0x10
	jb .iterate
	cmp byte [edi+veh.class],0x13
	ja .iterate
	mov eax, [edi+veh.scheduleptr]
	cmp eax, -1
	je .iterate
	cmp eax, scheduleheap
	jb .err
	cmp eax, scheduleheapend
	jae .err
	cmp eax, [scheduleheapfree]
	jae .err
	test eax, 1
	jz .iterate
.err:
	mov DWORD [edi+veh.scheduleptr], -1
	mov BYTE [edi+veh.totalorders], 0
.iterate:
	sub edi,byte -veh_size
	cmp edi,[veharrayendptr]
	jb NEAR .next
	popad
	ret
	
varb fixorderdisp
db 0x94
db 0x9A, 0x9
dd fixorderserr1
db "1: Below heap start: ", 0x7E, 13, 10
db 0x9A, 0x9
dd fixorderserr2
db "2: Past heap end: ", 0x7E, 13, 10
db 0x9A, 0x9
dd fixorderserr3
db "3: Past heap free point: ", 0x7E, 13, 10
db 0x9A, 0xA
dd fixorderserr14
db "14: Odd order addresses: ", 0x7E, " (", 0x7E, ")", 13, 10
db "---", 13, 10
db 0x9A, 0xA
dd fixorderserr4
db "4: Badly terminated orders: ", 0x7E, " (", 0x7E, ")", 13, 10
db 0x9A, 0xA
dd fixorderserr5
db "5: Order extends beyond allocated heap area: ", 0x7E, " (", 0x7E, ")", 13, 10
db 0x9A, 0xA
dd fixorderserr6
db "6: Order not preceded by terminator: ", 0x7E, " (", 0x7E, ")", 13, 10
db 0x9A, 0xA
dd fixorderserr7
db "7: Order type 0 in middle of order: ", 0x7E, " (", 0x7E, ")", 13, 10
db 0x9A, 0xA
dd fixorderserr12
db "12: of which the following word was the beginning of another vehicle's orders: ", 0x7E, " (", 0x7E, ")", 13, 10
db 0x9A, 0xA
dd fixorderserr8
db "8: Order type >5 in order: ", 0x7E, " (", 0x7E, ")", 13, 10
db 0x9A, 0xA
dd fixorderserr9
db "9: Advanced order type >6: ", 0x7E, " (", 0x7E, ")", 13, 10
db 0x9A, 0xA
dd fixorderserr10
db "10: Advanced order extra word count not consistent with type: ", 0x7E, " (", 0x7E, ")", 13, 10
db 0x9A, 0xA
dd fixorderserr11
db "11: Orders overrun declared length: ", 0x7E, " (", 0x7E, ")", 13, 10
db 0x9A, 0x9
dd fixorderserr13
db "13: Shared orders with inconsistent lengths: ", 0x7E, 13, 10
db "---", 13, 10
db "cht: fixorders 1	autofix order termination and length", 13, 10
db "		you should probably not run this if errors 1, 2, 3 or 14 are present", 13, 10
db "		this will perhaps 'fix' errors 4, 5, 6, 11 and 13", 13, 10
db "cht: fixorders 2	reset bad pointers to -1", 13, 10
db "		this *might* fix errors 1, 2, 3 and 14", 13, 10
db 0
endvar

var fixordertitletext, db "Fix Order Sign Cheat Report", 0

varb fixordermethod1
db 0x94
db 0x9A, 0xA
dd orderfix1truncated
db "1: Orders truncated: ", 0x7B, 13, 10
db 0x9A, 0xA
dd orderfix1extended
db "2: Orders extended: ", 0x7B, 13, 10
db 0x9A, 0xA
dd orderfix1addedzero
db "3: Additional zero markers added: ", 0x7B, 13, 10
db 0
endvar

cargodestcheat:
	testflags cargodest
	jnc NEAR .fret
	call skipspaces
	mov eax, [esi+ebx]
	or eax, 0x20202020
	cmp eax, "rstm"
	je .reset
	cmp eax, "fix1"
	je .fix1
	cmp eax, "stat"
	je NEAR .stat
.help:
	mov dword [specialerrtext1], cargodestchthelpmessage
	push DWORD cargodestmessagetitle
	call genoutmess
	clc
	ret
.fret:
	stc
	ret
.reset:
	extcall initcargodestmemory
	extcall cargodestinitstationroutingtable_all
	clc
	ret
.fix1:
	pushad
	xor ebx, ebx
	mov ecx, 0x10000
	mov esi, stationarray
	mov edi, [stationarray2ptr]
	mov ebp, [cargodestdata]
.fix1loop:
	cmp WORD [esi+station.XY], 0
	je .fix1next
	mov eax, [edi+station2.cargoroutingtableptr]
	cmp [ebp+eax+routingtable.location], ecx
	je .fix1next
	inc ebx
#if WINTTDX && DEBUG
	int3
#endif
	mov [ebp+eax+routingtable.location], ecx
.fix1next:
	add esi, station_size
	add edi, station2_size
	inc cl
	cmp cl, 250
	jb .fix1loop
	popad
	clc
	ret
.stat:
	pushad
	mov ebp, [cargodestdata]
	xor ebx, ebx
	xor edi, edi
	xor edx, edx
	mov ecx, 0x10000
.vehpacketloop:
	mov eax, [ebp+cargodestgamedata.vehcplist+ecx*4-4]
	call countcargopackets
	loop .vehpacketloop
	mov [cdstatpacketsveh], edi
	mov [cdstatvehstatpackets], edx
	mov [cdstatcargoveh], ebx
	
	xor ebx, ebx
	xor edi, edi
	xor edx, edx
	mov ecx, numstations
	mov esi, stationarray
	mov [cdstatnearroutes], edx
	mov [cdstatfarroutes], edx
.statloop:
	cmp WORD [esi+station.XY], 0
	je .next
	mov eax, [esi+station2ofs+station2.cargoroutingtableptr]
	or eax, eax
	je .next
	call countroutes
	mov eax, [ebp+eax+routingtable.cargopacketsfront]
	call countcargopackets
.next:
	add esi, station_size
	loop .statloop
	mov [cdstatpacketsstat], edi
	mov [cdstatcargostat], ebx
	or edx, edx
	jz .aok
	int3	//flag discrepancy	
.aok:

	mov eax, [ebp+cargodestgamedata.cddusedend]
	mov [textrefstack], eax
	mov eax, [cargodestdata_size]
	mov [textrefstack+4], eax
	mov DWORD [textrefstack+8], cargodestdata_reservesize*WINTTDX

	mov dword [specialerrtext1], cargodeststatmessage
	push DWORD cargodestmessagetitle
	call genoutmess
	clc
	popad
	ret

uvard cdstatpacketsstat
uvard cdstatcargostat
uvard cdstatpacketsveh
uvard cdstatcargoveh
uvard cdstatvehstatpackets
uvard cdstatnearroutes
uvard cdstatfarroutes
uvard cdstatlastmonthcyclicroutecull

//eax=first packet or 0
//ebp=[cargodestdata]
//increases edi=count, edx=count of veh stat packets, ebx=cargo
//trashes: none
countcargopackets:
	jmp .test
.start:
	test BYTE [ebp+eax+cargopacket.flags], 2
	jz .cargo
	inc edx
	jmp .next
.cargo:
	inc edi
	push eax
	movzx eax, WORD [ebp+eax+cargopacket.amount]
	add ebx, eax
	pop eax
.next:
	mov eax, [ebp+eax+cargopacket.nextptr]
.test:
	or eax, eax
	jnz .start
.end:
	ret

//eax=cargo routing table
//ebp=[cargodestdata]
//trashes: none
countroutes:
	push eax
	push DWORD [eax+ebp+routingtable.destrtptr]
	mov eax, [eax+ebp+routingtable.nexthoprtptr]
	jmp .neartest
.nearstart:
	inc DWORD [cdstatnearroutes]
	mov eax, [ebp+eax+routingtableentry.next]
.neartest:
	or eax, eax
	jnz .nearstart
	
	pop eax
	
	jmp .fartest
.farstart:
	inc DWORD [cdstatfarroutes]
	mov eax, [ebp+eax+routingtableentry.next]
.fartest:
	or eax, eax
	jnz .farstart	
	pop eax
	ret
	
var cargodestmessagetitle, db "Cargo Destinations Operations Sign Cheat Messagebox Title Text", 0
varb cargodestchthelpmessage
db "Cht: cargodest rstm	Reset all cargo dest memory. All cargo becomes unrouted, all routes are erased, etc", 13, 10
db "Cht: cargodest fix1		Fix existance corruption caused by the bug fixed in r2276 (new routing tables with bad location fields)", 13, 10
db "Cht: cargodest stat		Display cargodest statistics", 13, 10
db 0
endvar

varb cargodeststatmessage
db 0x94
db 0x9A, 0xA
dd cdstatpacketsveh
db "Packets in vehicles: ", 0x7B, 13, 10
db 0x9A, 0xA
dd cdstatvehstatpackets
db "Vehicle status packets: ", 0x7B, 13, 10
db 0x9A, 0xA
dd cdstatcargoveh
db "Routed cargo in vehicles: ", 0x7B, 13, 10
db 0x9A, 0xA
dd cdstatpacketsstat
db "Packets in stations: ", 0x7B, 13, 10
db 0x9A, 0xA
dd cdstatcargostat
db "Routed cargo in stations: ", 0x7B, 13, 10
db 0x9A, 0xA
dd cdstatnearroutes
db "Single hop routes: ", 0x7B, 13, 10
db 0x9A, 0xA
dd cdstatfarroutes
db "Far routes: ", 0x7B, 13, 10
db 0x9A, 0xA
dd cdstatlastmonthcyclicroutecull
db "Cyclic routes between adjacent nodes culled during last route rebuild: ", 0x7B, 13, 10
db 0x9A, 0xA
dd cargodestdata
db "Memory offset: ", 0x9A, 8, 13, 10
db "Used end: ", 0x9A, 8, ", Allocated: ", 0x9A, 8, ", Reserved: ", 0x9A, 8, 13, 10
db 0
endvar

#if DEBUGNETPLAY
/*
** -- How to use random generator logging --
**
**
** "Cht: LogRandom 0" disables logging, anything but 0 for parameter enables it,
** using no parameters toggles the state. The return address of randomfn gets dumped to
** a file named random.log while logging is enabled. In multiplayer, the file
** gets truncated every time the random seed check succeeds, and logging is automatically
** disabled on the first mismatch, so you end up with the interesting part only.
** You can turn it on before reproducing a known desync, or keep it enabled during
** playing and examine the resulting log when a "random" desync happens.
**
** Don't forget to turn it off manually before exiting (if it didn't turn itself off,
** of course) to make sure the file gets closed correctly.
*/

extern lograndom_enabled,enable_lograndom,disable_lograndom

lograndomcheat:
	or word [cheaterror],-1		// don't show "invalid parameter" when failing
	call getnumber
	jc .toggle

	test edx,edx
	jz .disable

.enable:
	jmp enable_lograndom	// will set cf correctly

.disable:
	call disable_lograndom
	clc
	ret

.toggle:
	cmp byte [lograndom_enabled],0
	je .enable
	jmp short .disable
	
#endif


loadheightmapcheat:
	pusha
	extcall loadheightmap
	popa
	ret
