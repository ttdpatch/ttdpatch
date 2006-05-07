//
// new station graphics
//

#include <std.inc>
#include <flags.inc>
#include <textdef.inc>
#include <grf.inc>
#include <station.inc>
#include <window.inc>
#include <veh.inc>
#include <misc.inc>
#include <ptrvar.inc>

extern GenerateDropDownMenu,actionhandler
extern actionnewstations_actionnum,cantrainenterstattile,cleartilefn
extern curcallback,curgrfstationlist,curselclass,curselclassid,curselstation
extern curselstationid,curspriteblock,disallowedlengths,disallowedplatforms
extern ecxcargooffset,fixednumber_addr,getdesertmap,geteffectivetracktype
extern getextendedbyte,getextendedbyte_noadjust,getnewsprite
extern gettextintableptr,gettileinfo,grffeature,grfstage,malloccrit
extern invalidatehandle,invalidatetile,irrgetrailxysouth,isrealhumanplayer
extern laststationid,miscgrfvar,newstationclasses,newstationlayout
extern newstationnames,newstationnum,numstationsinclass,patchflags
extern piececonnections,randomfn,randomstationtrigger
extern setstationdisabledbuttons,stationarray2ofst,stationcallbackflags
extern stationcargowaitingmask,stationclass,stationclassesused,stationflags
extern stationspritelayout,stsetids
extern unimaglevmode, Class5LandPointer, paStationtramstop
extern lookuptranslatedcargo,mostrecentspriteblock,statcargotriggers
extern lookuptranslatedcargo_usebit,gettileterrain
extern failpropwithgrfconflict,lastextragrm,curextragrm,setspriteerror
extern generatesoundeffect,redrawtile,stationanimtriggers,callback_extrainfo
extern miscgrfvar,irrgetrailxysouth,getirrplatformlength

// bits in L7:
%define L7STAT_PBS 1		// is station tile in a PBS block?
%define L7STAT_BLOCKED 2	// is station tile blocked (can't be entered)?

	// get sprite set for display in station construction window
	//
	// in:	al=railroad track type (or 0 for non-railroad stations)
	//	bl=station type; 2 or 3 for two railroad orientations;
	//	    other for other station types
	// out: eax=sprite offset of station sprites counted station base sprite
	// safe:---
global getstationselsprites
getstationselsprites:
	push ebx
	cmp bl,4
	jnb .notrail

	mov ebx,eax
	and ebx,0x0f

	testflags electrifiedrail
	jnc .notelectrified

	call geteffectivetracktype

.notelectrified:
	mov ah,[curselstation]
	test ah,ah
	jnz .isnewstation

.notrail:
	and eax,0x0f
	imul eax,82
	mov [realtempstationtracktypespriteofs],eax
	and dword [stationspritesetofs],0
	pop ebx
	ret

.isnewstation:
	push esi

	xchg al,bl
	imul ebx,82
	mov [realtempstationtracktypespriteofs],ebx

//	movzx ebx,al
//	mov bl,[tracktypes+ebx]
	xor ebx,ebx
	movzx eax,ah
	xor esi,esi

	mov [stationcurstation],esi
	mov [stationcurgameid],eax
	mov byte [grffeature],4
	call getnewsprite

	pop esi
	pop ebx

	sub eax,1069
	mov [stationspritesetofs],eax
	ret

uvard realtempstationtracktypespriteofs
uvard stationspritesetofs
uvard stationcurgameid
uvard stationcurstation


#if 0
	// called when left/right buttons in station selection window are pressed
	//
	// in:	cl=17h..1ah for class +/- and station +/- buttons
	// out:	---
	// safe:???
stationselbutton:
	cmp cl,0x18
	jbe near makestationclassdropdown

	pusha

	mov ch,[curselclass]

	movzx edx,byte [numstationclasses]	// counter for infinite loop detection
	inc edx

.nextclass:
	mov bh,cl
	and bh,1
	add bh,bh
	dec bh		// now bh=+1 for 17, 19 and -1 for 18, 1A
			// i.e. opposite to button logic

	movzx edi,byte [newstationnum]
	inc edi

	cmp cl,19h
	jnb .setstation

.setclass:
	movzx eax,byte [curselclass]

.cycleclass:
	dec edx
	jnz .noloop

	mov [curselclass],ch
	mov al,[curselstation]
	jmp .done

.noloop:
	sub al,bh
	cmp al,0xff
	jne .nowrap

	mov al,[numstationclasses]
	sub al,1

.nowrap:
	cmp al,[numstationclasses]
	jb .validclass

	mov al,0

.validclass:
	bt [stationclassesused],eax
	jnc .cycleclass

	mov [curselclass],al
	mov bl,al
	mov al,[laststationselinclass+eax]
	mov bh,0xff
	jmp short .nottoohigh	// check station class is right

.setstation:
	movzx eax,byte [curselstation]
	mov bl,[curselclass]

.cyclestat:
	dec edi
	jnz .notlooped

	// we went through all station IDs and apparently couldn't find anything
	// if we were selecting classes, it probably was one with station IDs
	// but all disabled by the callback

	cmp cl,19h
	jb .nextclass

	mov al,[curselstation]
	mov bl,ch
	jmp short .done

.notlooped:

	sub al,bh
	cmp al,0xff
	jne .nottoolow

	mov al,[newstationnum]

.nottoolow:
	cmp al,[newstationnum]
	jbe .nottoohigh

	mov al,0

.nottoohigh:
#endif

	// find suitable station for class
	//
	// in:	eax=class
	// out:	edx=station
	//	carry set if none available
global findstationforclass,findstationforclass.next
findstationforclass:
	movzx edx,byte [laststationselinclass+eax]
.trynext:
	cmp [stationclass+edx],al
	jne .next

	call isstationavailable
	jnc .done

.next:
	inc edx
	cmp edx,[newstationnum]
	jbe .nooverflow

	xor edx,edx

.nooverflow:
	cmp dl,[laststationselinclass+eax]
	jne .trynext

	stc
.done:
	ret

	// find out if station is available
	//
	// in:	edx=station
	// out:	carry set if not available
isstationavailable:
	test byte [stationcallbackflags+edx],1
	jz .done

	mov byte [curcallback],0x13
	mov byte [grffeature],4
	push eax
	push esi
	mov eax,edx
	xor esi,esi
	call getnewsprite
	mov byte [curcallback],0
	mov dh,al
	pop esi
	pop eax
	cmc
	jnc .done

	test dh,dh
	jnz .done

	stc

.done:
	mov dh,0
	ret

global makestationclassdropdown
makestationclassdropdown:
	mov eax,0xc000
	xor ebx,ebx
.loop:
	cmp al,MAXDROPDOWNENTRIES
	jae .done
	mov [tempvar+2*(eax-0xc000)],ax

	push eax
	movzx eax,al
	call findstationforclass
	pop eax
	jnc .gotstation

	bts ebx,eax	// mark as disabled, no stations available

.gotstation:
	inc eax
	cmp al,19
	jae .done
	cmp al,[numstationclasses]
	jb .loop

.done:
	mov word [tempvar+2*(eax-0xc000)],-1	// terminate it
	movzx dx,byte [curselclass]		// current selection
	jmp [GenerateDropDownMenu]

uvarb stationdropdownnums,32

global makestationseldropdown
makestationseldropdown:
	xor eax,eax
	mov bl,[curselclass]
	mov bh,-1
	xor edx,edx
.loop:
	cmp al,MAXDROPDOWNENTRIES
	jae .done

	cmp [stationclass+edx],bl
	jne .next

	call isstationavailable
	jc .next

	mov [tempvar+eax*2],dl
	mov byte [tempvar+1+eax*2],0xc1
	mov [stationdropdownnums+eax],dl

	cmp dl,[curselstation]
	jne .notcur

	mov bh,al

.notcur:
	inc eax

.next:
	cmp al,19
	jae .done
	inc edx
	cmp edx,[newstationnum]
	jbe .loop

.done:
	mov word [tempvar+2*eax],-1	// terminate it
	movzx edx,bh		// current selection
	xor ebx,ebx		// everything available
	jmp [GenerateDropDownMenu]

global stationseldropdownclick
stationseldropdownclick:
	bt dword [esi+window.activebuttons],0x18
	jnc .notclass

	movzx eax,al
	call findstationforclass
	mov ah,dl
	jnc .notdflt
	mov al,0
	mov ah,0
.notdflt:
	mov [curselclass],al
	mov [curselstation],ah
	movzx eax,ah
	jmp near .update

.notclass:
	bt dword [esi+window.activebuttons],0x1a
	jc .isstation

	ret

.isstation:
	movzx eax,al
	mov al,[stationdropdownnums+eax]
	mov [curselstation],al

.update:
	movzx ebx,byte [curselclass]
	mov [laststationselinclass+ebx],al

	pusha
	mov dl,al	// station ID
	mov dh,bl	// class ID
	mov bh,0	// set station&class ID
	mov bl,1	// do it!
	xor eax,eax
	xor ecx,ecx
	dopatchaction actionnewstations
	popa

	// find out which platform numbers and lengths are (dis)allowed
	// and set buttons accordingly

	movzx ebx,word [wcurrentstationsize]

	// disallowed*: bit 0..6=lengths 1..7, bit 7=+7
	// so length bits 1..14 would be 0..6, 0|7, 1|7, 2|7... 7|7
	movsx ecx,byte [disallowedplatforms+eax]
	or ch,cl
	or ch,0x80
	shl cl,1
	shl ecx,16
	sar ecx,1

	movsx cx,byte [disallowedlengths+eax]
	or ch,cl
	or ch,0x80
	shl cl,1
	sar cx,1

	mov eax,ecx	// now eax bits 0..13 = lengths 1..14, bits 16..29 = platforms 1..14

	movzx ecx,bl

.checklength:
	bt eax,ecx
	jnc .lengthok

	dec cl
	jns .checklength

	mov cl,6
	jmp .checklength

.lengthok:
	mov bl,cl

	mov cl,bh
	and cl,0x7f	// high bit is orientation, mask it out

	shr eax,16

.checkplat:
	bt eax,ecx
	jnc .platok

	dec cl
	jns .checkplat

	mov cl,6
	jmp .checkplat

.platok:
	and bh,0x80
	or bh,cl
	mov [wcurrentstationsize],bx

	call setstationdisabledbuttons

	mov al,[esi]
	mov bx,[esi+6]
	call dword [invalidatehandle]
	ret

#if 0
showtrainstorient:
	add dx,15
	mov bh,0xc0
	mov bl,[curselclass]
	mov al,16	// default colour black
	ret

showtrainstnumtr:
	add dx,76
	mov bh,0xc1
	mov bl,[curselstation]
	mov al,16
	ret
#endif


// patch action to handle selecting new stations
//
// in:	bh=what to do
//		bh=0 set station&class IDs, dl=station ID, dh=class ID
global actionnewstations
actionnewstations:
	test bl,bl
	jnz .doit

	xor ebx,ebx	// choosing stations is free
.done:
	ret

.doit:
	cmp bh,0
	jne .done

	movzx eax,byte [curplayer]
	mov [curselstationid+eax],dl
	mov [curselclassid+eax],dh
	ret

uvarw stationanimdata,256
uvarb stationanimspeeds,256

	//
	// special functions to handle special station properties
	//
	// in:	eax=special prop-num
	//	ebx=offset
	//	ecx=num-info
	//	edx->feature specific data offset
	//	esi=>data
	// out:	esi=>after data
	//	carry clear if successful
	//	carry set if error, then ax=error message
	// safe:eax ebx ecx edx edi

global setstationclass
setstationclass:
	mov eax,[laststationid]
	inc eax
	cmp eax,ebx
	jne .bad

	mov eax,[curspriteblock]
	mov eax,[eax+spriteblock.grfid]
	test eax,eax
	jz .bad

	inc eax
	jnz .next

.bad:		// grfid is 0 or -1, not acceptable for stations
	mov eax,ourtext(invalidsprite) | (INVSP_BADID << 16)
	stc
	ret

.next:
	lodsd
	push ecx
	mov ecx,[numstationclasses]
	mov edi,stationclasses
	repne scasd
	je .gotit

	cmp dword [numstationclasses],byte maxstationclasses
	jb .newclass

.toomany:
	pop ecx
	mov al,GRM_EXTRA_STATIONS
	jmp failpropwithgrfconflict

.newclass:
	stosd
	inc dword [numstationclasses]

.gotit:
	movzx eax,byte [newstationnum]
	inc al
	jnz .ok		// too many stations in set?

	jmp .toomany

.ok:
	cmp byte [grfstage],0
	je .dontrecord
	mov [newstationnum],al
.dontrecord:
	mov [curgrfstationlist+ebx],al
	mov [laststationid],ebx

	neg ecx
	add ecx,[numstationclasses]
	dec ecx
	mov [stationclass+eax],cl
	bts [stationclassesused],ecx
	inc byte [numstationsinclass+ecx]

	or word [stationanimdata+eax*2],byte -1
	mov byte [stationanimspeeds+eax],2

	pop ecx

	inc ebx
	loop .next

	mov eax,[curspriteblock]
	mov [curextragrm+GRM_EXTRA_STATIONS*4],eax

	clc
	ret


vard stationspritelayoutinfo, stationspritelayout,curgrfstationlist,ttdstationspritelayout

global setstationspritelayout
setstationspritelayout:
	mov ebp,stationspritelayoutinfo
	// jmp short setgeneralspritelayout
	// fall through


	// call with standard action 0 prop registers for type "H", and also
	// ebp->sprite layout info
	//	where	[ebp+0]->table where to store sprite layouts
	//		[ebp+4]->ID translation table (may be 0 if none)
	//		[ebp+8]->default sprite layouts
	// note, the offset in ebx must be untranslated
	//	 (i.e. type "H" in the defvehdata argument in grfact.asm)
setgeneralspritelayout:
	mov edi,[edx]
	test edi,0xffff0000
	jnz .gotptr

	call getextendedbyte_noadjust
	inc eax
	imul edi,eax,4
	imul edi,ecx
	push edi
	call malloccrit
	pop edi
	mov [edx],edi

.gotptr:
	call getextendedbyte_noadjust
	mov edx,eax

.next:
	push ebx
	mov eax,[ebp+4]
	test eax,eax
	jz .notrl
	mov bl,[eax+ebx]
.notrl:
	push ecx
	mov [edi],edx	// store number of valid sprite slots
	add edi,4
	mov eax,[ebp]
	mov [eax+ebx*4],edi

	call getextendedbyte
	mov ecx,eax
	cmp ecx,edx
	je .nexttile
	pop ebx

.invalid:
	pop ecx
	mov eax,(INVSP_INVPROPVAL << 16)+ourtext(invalidsprite)
	call setspriteerror
	or edi,byte -1
	ret

.nexttile:
	mov eax,esi
	stosd
	lodsd		// ground sprite
	test eax,eax
	jnz .nextsprite	// has new layout data, skip to next tile

	// use default layout
	imul eax,ecx,byte -4
	lea eax,[eax+edx*4]
	add eax,[ebp+8]
	mov [edi-4],eax
	jmp short .tiledone

.nextsprite:
	lodsb
	cmp al,0x80
	je .tiledone
	add esi,9
	jmp .nextsprite
.tiledone:
	loop .nexttile

	pop ecx
	pop ebx
	inc ebx
	loop .next
	clc
	ret

global copystationspritelayout
copystationspritelayout:
	mov edx,stationspritelayout

docopystationdata:
.next:
	xor eax,eax
	lodsb
	mov al,[curgrfstationlist+eax]
	mov eax,[edx+eax*4]
	mov [edx+ebx*4],eax
	inc ebx
	loop .next
	clc
	ret

global copystationlayout
copystationlayout:
	mov edx,newstationlayout
	jmp docopystationdata

global setstationlayout
setstationlayout:

.next:
	mov [newstationlayout+ebx*4],esi
	or edx,byte -1
	push ecx
	call usenewstationlayout	// skip all layouts
	pop ecx
	jnz setstationclass.bad		// bad if we found 255 platforms...
	loop .next
	clc
	ret

exported setstatcargotriggers
	lodsd

	cmp eax,byte -1	// sets carry if eax wasn't FFFFFFFFh
	cmc
	sbb edx,edx
			// edx is now zero if and only if eax wasn't FFFFFFFFh
	jnz .hasedx

	push dword [curspriteblock]

	or ecx,byte -1

.nextbit:
	inc ecx
	shr eax,1
	ja .nextbit		// ja = both carry and zero are clear
				// (no bit exited on the right, but there are bits left in eax)
	jnc .done		// if we didn't jump already, either carry or zero is set
				// if carry is clear, zero must be set, and we're done
				// (no more bits in eax, no bit exited)

	push ecx
	call lookuptranslatedcargo_usebit
	pop edi

	cmp edi,0xff
	je .nextbit

	bts edx,edi
	jmp short .nextbit

.done:
	add esp,4
.hasedx:
	mov [statcargotriggers+ebx*4],edx
	clc
	ret

	// get text table associated with station names and classes
	// in:	edi=text ID & 7ff
	//	0xx = get station class xx name
	//	1xx = get station xx name
	//	4xx = set station class xx name
	//	5xx = set station xx name
	// out:	eax=table ptr
	//	edi=table index
	// safe:---
global getstationtexttable
getstationtexttable:
	mov eax,edi
	movzx edi,al

	cmp eax,0x7ff
	je .specialnum

	test ah,1
	jz .class

	test ah,4
	mov eax,newstationnames
	jz .notwrite

	// translate from set-id to game-id
	movzx edi,byte [curgrfstationlist+edi]
	ret

.specialnum:
	mov ax,statictext(fixednumber)
	jmp gettextintableptr

.notwrite:
	test edi,edi
	jnz .stationname

.default:
	mov ax,ourtext(defaultstation)
	jmp gettextintableptr

.bad:
	movzx eax,byte [stsetids+edi*stsetid_size+stsetid.setid]
	inc eax
	call .setstationnum
	mov ax,ourtext(stationnumdefault)
	jmp gettextintableptr

.setstationnum:
	mov edi,fixednumber_addr
	aam		// -> al=num mod 10, ah=num div 10
	add al,'0'
	stosb
	test ah,ah
	jz .singledigit
	xchg al,ah
	add al,'0'
	stosb
.singledigit:
	mov al,0
	stosb		// zero-terminate
	ret


.stationname:
	cmp dword [eax+edi*4],0
	je .bad
	ret

.class:
	test ah,4
	mov eax,newstationclasses
	jz .notclasswrite

	movzx edi,byte [curgrfstationlist+edi]
	movzx edi,byte [stationclass+edi]
	ret

.notclasswrite:
	test edi,edi
	jz .default

.classname:
	cmp dword [eax+edi*4],0
	je .badclass
	ret

.badclass:
	mov eax,edi
	inc eax
	call .setstationnum
	mov ax,ourtext(stationclassdefault)
	jmp gettextintableptr


#if 0
	cmp al,[numstationclasses]
	jae .defclass

	cmp al,0
	je .defclass

	test ah,4
	mov eax,newstationclasses
	jz .nowrite
	ret

.nowrite:
	cmp dword [eax+edi*4],0
	je .defclassnowrite
	ret

.defclass:
	test ah,4
	jnz .badwrite	// trying to write name of class 0/an undefined class?
.defclassnowrite:
	mov ax,0x3002	// "Orientation"
	jmp gettextintableptr

.badwrite:
	xor eax,eax
	ret
#endif


//maxstationclasses equ 32
	align 4
	// list of predefined station classes
var stationclasses
	dd 'DFLT'
	dd 'WAYP'

%define CLASS_DFLT 0
%define CLASS_WAYP 1

global numpredefstationclasses
numpredefstationclasses equ (addr($)-stationclasses)/4

	times maxstationclasses-numpredefstationclasses dd 0

var numstationclasses, dd numpredefstationclasses


uvarb laststationselinclass,maxstationclasses


// New stations - how it all works
//
// Each new station basically has three different IDs
// 1) setid:  The ID that is used in the .grf file itself, one for each action 3
// 2) gameid: The global in-game ID
// 3) dataid: The ID stored in the savegame
//
// So we have three lists to maintain:
// a) a list that tells us which .grf a dataid belongs to, and what its
//    current gameid is: this is stationidgrfmap
// b) a list that translates gameid to setid; that's stsetids
// c) only while loading the .grf, a list that tells us what gameid to use for
//    a certain setid, that's curgrfstationlist
//
// So if we place a new station with some gameid, what happens?
// - we look up the gameid in stationsids and find grfid/setid
// - we search stationidgrfmap whether this combination of grfid/setid exists
//   if not, we add it to the first empty slot. we record the slot number->dataid
// - we store the dataid with the new station
//
// And if we want to draw a station with some dataid:
// - we look up this dataid in stationidgrfmap
// - we get the gameid
// - we use the data from stsetids for this gameid to draw the station
//
// If a station tile is deleted, we decrement the corresponding .numtiles,
// and consider it unused if .numtiles is zero


uvard stationidgrfmap,256*2
uvarb havestationidgrfmap	// is anything in the stationidgrfmap list?


// place new station tile
// in:	ah=gameid
// out:	ah=dataid; 0 if no more room in stationidgrfmap
// uses:---
newstationtile:
	pusha
	movzx ecx,ah
	jecxz .regular

	mov ebx,[stsetids+ecx*stsetid_size+stsetid.act3info]
	// mov ebx,[ebx-6]
	mov ebx,[ebx+action3info.spriteblock]
	mov dl,[stsetids+ecx*stsetid_size+stsetid.setid]

	mov ebx,[ebx+spriteblock.grfid]

	xor eax,eax
	mov edi,stationidgrfmap
.searchnext:
	cmp [edi+eax*8+stationid.grfid],ebx
	jne .notit

	cmp [edi+eax*8+stationid.gameid],cl
	je .gotit

.notit:
	add al,1
	jnc .searchnext

	inc eax
.findempty:
	cmp word [edi+eax*8+stationid.numtiles],0
	je .makenew
	add al,1
	jnc .findempty

	// couldn't find it, list is full, return ah=0
	popa
	mov ah,0
	ret

.makenew:
	mov byte [havestationidgrfmap],1
	mov [edi+eax*8+stationid.grfid],ebx
	mov [edi+eax*8+stationid.gameid],cl
	mov [edi+eax*8+stationid.setid],dl

.gotit:
	inc word [edi+eax*8+stationid.numtiles]
	xchg eax,ecx

.regular:
	mov [esp+0x1c+1],cl	// save it to be restored in ah by popa
	popa
	ret


// get spritebase to draw station tile
// in:	eax=track type
//	ebx=dataid (must *not* be zero!)
//	esi=>station
// out:	eax=sprite base
//	ebx=track type
//      carry flag if graphics not present
// safe:---
getdataidspritebase:
	push eax
	movzx eax,byte [stationidgrfmap+ebx*8+stationid.gameid]
	mov [stationcurgameid],eax
	xor ebx,ebx
	mov byte [grffeature],4
	call getnewsprite
	pop ebx
	ret

uvard curstationtile	// station tile currently having its graphics drawn


// called to calculate the sprite offset to use for drawing the current
// station tile
//
// in:	ebp=offset for track type
//	other registers from GetTileInfo except ebx and esi are swapped
// out:	ebp=new offset
// safe:---
global getnewstationsprite_noelrails
getnewstationsprite_noelrails:
	// we get here is elrails is off
	// otherwise we get to getnewstationsprite directly
	// with the following done already
	and ebp,byte 0xF
	imul ebp,byte 82

global getnewstationsprite
getnewstationsprite:
	push eax
	push ebx
	push ebp

	mov [realtempstationtracktypespriteofs],ebp

	xor eax,eax
	mov [stationspritesetofs],eax
	mov [stationcurgameid],eax

	cmp dh,	8
	jae near .nosprites

	// get dataid
	mov ax,[landscape3+ebx*2]
	test ah,ah
	jz near .nosprites

	push esi
	movzx esi,byte [landscape2+ebx]
	imul esi,station_size
	add esi,[stationarrayptr]

	mov [curstationtile],ebx
	mov [stationcurstation],esi

	movzx ebx,ah
	and eax,0x0f
	call getdataidspritebase
	jc .nospritespop

	sub eax,1069	// TTD will add sprite numbers based on this later
	xchg eax,ebx

	testflags electrifiedrail
	jnc .notelectrified

	call geteffectivetracktype

.notelectrified:
	mov [esp],ebx
	mov [stationspritesetofs],ebx
	imul eax,82

	mov [realtempstationtracktypespriteofs],eax

	mov eax,[stationcurgameid]
	test byte [stationcallbackflags+eax],2
	jz .nospritespop

	mov bl,dh
	call getspritelayoutcallback
	jc .nospritespop

	mov [orgtiletype],dh
	mov [modtiletype],eax
	mov dh,0xff

.nospritespop:
	pop esi

.nosprites:
	pop ebp
	pop ebx
	pop eax
	ret

	uvarb curstattiletype

// get sprite layout number from callback
//
// in:	al=gameid
//	bl=original layout number
//	esi=>station (or 0 if none)
// out:	eax=sprite layout
//	cf set if error
getspritelayoutcallback:
	push edx
	mov edx,[stationspritelayout+eax*4]

	mov byte [curcallback],0x14
	mov byte [grffeature],4
	mov [curstattiletype],bl
	call getnewsprite
	mov byte [curcallback],0
	jc .error

	push ebx
	and ebx,1
	and eax,byte ~1
	or eax,ebx

	mov bl,8

	test edx,edx
	jz .gotcustom

	mov ebx,[edx-4]

.gotcustom:
	cmp ebx,eax
	pop ebx
	jae .ok

.error:
	stc
	movzx eax,al

.ok:
	pop edx
	ret


// called to set the landscape3 entry for a new station tile
// landscape1 and landscape2 are already set appropriately, and
// some of the station structure fields for it are set
// (at least those set by SetupNewStation)
//
// in:	 ax=track type (0/1/2 for RR/MR/ML)
//	 dh=length remaining
//	 dl=platforms remaining
//	 si=direction (1 or 100)
//	edi=tile index
// out:	---
// safe:ax,cx
global alteraddlandscape3tracktype
alteraddlandscape3tracktype:
	push ebx
	push eax
	call [randomfn]
	and al,0x0f

	cmp dword [curstationsectionsize],0
	jne .notfirsttile
	mov [curstationsectionsize],dx
	mov [curstationsectionpos],edi
	mov [curstationsectiondir],si
.notfirsttile:
	cmp [curstationsectionsize],dl
	jne .notfirstpos
	or al,0x10
.notfirstpos:
	cmp [curstationsectionsize+1],dh
	jne .notfirstplat
	or al,0x20
.notfirstplat:
	cmp dl,1
	jne .notlastpos
	or al,0x40
.notlastpos:
	cmp dh,1
	jne .notlastplat
	or al,0x80
.notlastplat:
	mov [landscape6+edi],al
	pop eax

	mov byte [landscape7+edi],0

	// stop animation just in case the old tile was animated
	pusha
	mov ebx,3				// Class 14 function 3 - remove animated tile
	mov ebp,[ophandler+0x14*8]
	call [ebp+4]
	popa

	movzx ebx,byte [curplayer]
	mov ah,[curselstationid+ebx]
	call newstationtile
	mov [landscape3+edi*2], ax
	pop ebx
	ret

uvard curstationsectionsize
uvard curstationsectionpos
uvard curstationsectiondir

// called when removing a railway station tile
//
// in:	ax,cx=X,Y coord
//	bl has bit 0 set if actually clearing, bit 0 is clear if only checking
// out:	---
// safe:?
global removerailstation
removerailstation:
	test bl,1
	jz .notremoving

	pusha
	call [gettileinfo]
	movzx eax,byte [landscape3+esi*2+1]
	test eax,eax
	jz .notnewstation
	dec word [stationidgrfmap+eax*8+stationid.numtiles]
.notnewstation:
//	mov eax,[landscape6ptr]
	mov byte [landscape6+esi],0
	mov byte [landscape7+esi],0

	mov edi,esi
	mov ebx,3				// Class 14 function 3 - remove animated tile
	mov ebp,[ophandler+0x14*8]
	call [ebp+4]
	popa

.notremoving:
	call [cleartilefn]	// overwritten
	add ax,0x10
	ret

uvard orgtiletype
uvard modtiletype

// get pointer to sprite layout for station tile
//
// in:	 dh=tile type (FF if value comes from callback, then tiletype in [modtiletype])
//	ebx=landscape index
// out:	ebp->sprite layout
// safe:ebx
global getstationspritelayout
getstationspritelayout:

	//---------INSERTED BY STEVEN HOEFEL-----------------
	mov dword [Class5LandPointer], ebx
	//-------------------------------------------------------

	cmp dh,0xff
	je .modtype

	movzx ebp,dh
	cmp dh,8
	jb .isitours

	cmp dh, 0x53
	jb .notours
	test byte [landscape3+ebx*2],0x10
	jz .notours
	movzx ebp,dh
	mov ebp,[paStationtramstop+(ebp-0x53)*4]
	retn

.notours:
	movzx ebp,dh
	mov ebp,[dword 0+ebp*4]
ovar ttdstationspritelayout,-4
	ret

.modtype:
	mov ebp,[modtiletype]
	mov dh,[orgtiletype]

.isitours:
	movzx ebx,byte [landscape3+ebx*2+1]
	test ebx,ebx
	jz .notours

	movzx ebx,byte [stationidgrfmap+ebx*8+stationid.gameid]
	mov ebx,[stationspritelayout+ebx*4]
	test ebx,ebx
	jz .notours

	mov ebp,[ebx+ebp*4]
	ret

// same as above, but during displaying the construction window
//
// in:	ebx=tile type (2 or 3 for railway stations)
// out:	ebx->sprite layout
// safe:eax
global getstationdisplayspritelayout
getstationdisplayspritelayout:
	cmp ebx,8
	jb .isitours

.notours:
	mov eax,[ttdstationspritelayout]
	mov ebx,[eax+ebx*4]
	ret

.isitours:
	movzx eax,byte [curselstation]
	test eax,eax
	jz .notours

	push eax
	test byte [stationcallbackflags+eax],2
	jz .nocallback

	push esi
	xor esi,esi
	call getspritelayoutcallback
	pop esi
	jc .nocallback

	mov ebx,eax

.nocallback:
	pop eax
	mov eax,[stationspritelayout+eax*4]
	test eax,eax
	jz .notours

	mov ebx,[eax+ebx*4]
	ret

// translate track sprite number in ebx
//
// in:	ebx=sprite number
// out:	ebx=sprite number
// safe:?
global getstationtracktrl
getstationtracktrl:
	btr ebx,31
	jc .newsprites

	add ebx,[realtempstationtracktypespriteofs]
	ret

.newsprites:
	push eax
	mov eax,[stationcurgameid]
	test byte [stationflags+eax],1
	jnz .differentspriteset

.notdifferentspriteset:
	mov eax,[realtempstationtracktypespriteofs]
	shr eax,6
	add ebx,eax
	add ebx,[stationspritesetofs]
	pop eax
	ret

.differentspriteset:
	push esi
	push ebx
	mov esi,[stationcurstation]
	inc dword [miscgrfvar]
	mov byte [grffeature],4
	call getnewsprite
	dec dword [miscgrfvar]
	pop ebx
	pop esi
	jc .notdifferentspriteset

	lea eax,[eax+ebx-1069]
	mov ebx,[realtempstationtracktypespriteofs]
	shr ebx,6
	add ebx,eax
	pop eax
	ret



// same for station sprite numbers
global getstationspritetrl
getstationspritetrl:
	btr ebx,31
	jc .ttdsprites

	add ebx,[stationspritesetofs]
	ret

.ttdsprites:
	add ebx,[realtempstationtracktypespriteofs]
	ret


// search station layout and if found, copy to edi
//
// in:	dh=number of platforms
//	dl=platform length
//	esi->new station layout data (must not be 0)
//	edi->station layout buffer
// out:	zf if not found, nz if found
// safe:eax ebx ecx
global usenewstationlayout
usenewstationlayout:
	xor eax,eax

.nextset:
	lodsw
	test eax,eax
	jnz .checkit
	ret	// not found, zf set

.checkit:
	movzx ecx,al
	movzx ebx,ah
	imul ecx,ebx
	cmp ax,dx
	je .foundit
	add esi,ecx
	jmp .nextset

.foundit:
	rep movsb
	or al,1	// clear zf
	ret

// route map handler for station tiles
global checktrainenterstationtile
checktrainenterstationtile:
	cmp al,0
	jne .old

	movzx eax,byte [landscape3+edi*2+1]
	movzx eax,byte [stationidgrfmap+eax*8+stationid.gameid]
	mov ah,[cantrainenterstattile+eax]
	mov al,[landscape5(di,1)]
	add al,8
	bt eax,eax	// really bt ah,tiletype
	mov eax,0	// not xor eax,eax to preserve CF
	jnc .old
	ret

.old:
	jmp near $+5
ovar .oldfn, -4, $, checktrainenterstationtile

// called when checking whether train stops at this station tile or another
// follows
//
// fixes reversing of trains in station when station tile blocked
// or station tile is in the wrong direction

// in:	bx+si=tile index of next tile
//		bx=current tile
//	dl=tile type of next tile
// out:	CF=1 won't stop, CF=0 will stop (station doesn't continue)
// safe:dx esi
global doestrainstopatstationtile
doestrainstopatstationtile:
	cmp dl,8
	jnb .done	// not a train station tile
	lea esi,[bx+si]
	mov dh, [landscape5(bx,1)]
	xor dh, [landscape5(si,1)]
	and dh,1
	jnz .done       // wrong 
	
	movzx esi,byte [landscape3+esi*2+1]
	movzx esi,byte [stationidgrfmap+esi*8+stationid.gameid]
	mov dh,[cantrainenterstattile+esi]
	add dl,8
	bt edx,edx	// really bt dh,tiletype
//	jc .stop
//	stc
	cmc
.done:
	ret

//.stop:
//	clc		// want to return to original address
//	ret


// called by var. action 2 for variables 40+x
//
// in:	esi->station
// out:	eax=variable content
// safe:ecx

// variable 40: platforms/tile location
// out:	eax=0TNLcCpP
//	 T tile type
//	 N number of platforms
//	 L length
//	 C current platform number (0 for first)
//	 c current platform number, counted from last (0 for last)
//	 P position along this platform (0 for beginning)
//	 p position counted from end (0 for end)
//
global getplatforminfo,getplatforminfo.getccpp
getplatforminfo:
	mov byte [.checkdirection],0	// direction doesn't matter

.getinfo:
	test byte [esi+station.facilities],1
	jnz .hastrainfacility
	xor eax,eax
	ret

.hastrainfacility:
	mov ecx,[curstationtile]
	testmultiflags irrstations
	jnz .irregular

	mov ah,[esi+station.platforms]
	mov al,ah
	and ax, 8778h 	// Bitmask: 10000111 1111000
	shr al, 3
	cmp ah, 80h
	jb .istoosmall
	sub ah, (80h - 8h)
.istoosmall:
	// now al = length, ah = tracks
	shl eax,16
	mov ax,cx
	sub ax,[esi+station.railXY]
.getccppflip:
	test byte [landscape5(cx,1)],1	// orientation
	jz .getccpp
	xchg ah,al
.getccpp:
	// here eax=NNLLCCPP
	ror eax,16
	mov ecx,eax
	shr ax,4
	or al,cl
	or ah,[curstattiletype]
	rol eax,16	// now cx=NNLL, eax=0TNLCCPP
	sub cx,ax	// now cx=ccpp
	sub cx,0x0101
	shl cx,4
	or ax,cx
	ret

.irregular:
	// ecx=tile
	push ebx
	push edx

	// first loop, calculate LL and PP
	xor eax,eax
	xor ebx,ebx

	lea edx,[eax+1]		// edx=1
	mov bh,[landscape5(cx,1)]
	and bh,1
	jz .start

	mov edx,ebx

.start:
	and bh,[.checkdirection]	// .checkdirection is zero when ignoring direction

.nexttile1:
	mov bl,[landscape4(cx,1)]
	and bl,0xf0
	cmp bl,0x50
	jne .gotend1

	mov bl,[landscape5(cx,1)]
	cmp bl, 7	// train station 
	ja .gotend1

	and bl,[.checkdirection]
	cmp bl,bh
	jne .gotend1

	add ecx,edx
	add eax,0x10000		// increase LL
	test edx,edx
	sets bl
	add al,bl		// when going to beginning, also increase PP
	jmp .nexttile1

.gotend1:
	mov ecx,[curstationtile]
	test eax,eax
	jz .gotirr		// not a station tile at all???

	sub ecx,edx
	neg edx
	js .nexttile1

	// second part, get NN and CC
	mov ecx,[curstationtile]
	xchg dh,dl

.nexttile2:
	mov bl,[landscape4(cx,1)]
	and bl,0xf0
	cmp bl,0x50
	jne .gotend2

	mov bl,[landscape5(cx,1)]
	cmp bl, 7	// train station 
	ja .gotend2

	and bl,[.checkdirection]
	cmp bl,bh
	jne .gotend2

	add ecx,edx
	add eax,0x1000000	// increase NN
	test edx,edx
	sets bl
	add ah,bl		// when going to beginning, also increase CC
	jmp .nexttile2

.gotend2:
	mov ecx,[curstationtile]
	sub ecx,edx
	neg edx
	js .nexttile2

	// done!
.gotirr:
	pop edx
	pop ebx
	jmp .getccpp

.checkdirection: db 0

// variable 49: same as above, but only for tiles in same direction
global getplatformdirinfo
getplatformdirinfo:
	mov byte [getplatforminfo.checkdirection],1	// only if direction matches
	jmp getplatforminfo.getinfo

// variable 41: same but only for each individually built section
global getstationsectioninfo
getstationsectioninfo:
	test byte [esi+station.facilities],1
	jnz .hastrainfacility

.notnewstation:
	xor eax,eax
	ret

.bad:
	mov ecx,[curstationtile]
	or byte [ebx+ecx],0xf0
	pop edx
	pop ebx
	xor eax,eax
	ret

.hastrainfacility:
	mov ax,0x0101
	push ebx
	push edx
	mov ebx,landscape6
	mov ecx,[curstationtile]
	mov edx,1
	test byte [landscape5(cx,1)],1	// orientation
	jz .notflip
	xchg dh,dl
.notflip:

.moreplat1:
	test ecx,0xffff0000
	jnz .bad
	test byte [ebx+ecx],0x40
	jnz .doneplat1
	inc al
	add ecx,edx
	jmp .moreplat1

.doneplat1:
	xchg dh,dl

.morelen1:
	test ecx,0xffff0000
	jnz .bad
	test byte [ebx+ecx],0x80
	jnz .donelen1
	inc ah
	add ecx,edx
	jmp .morelen1

.donelen1:
	xchg dh,dl

	mov ecx,[curstationtile]

.moreplat2:
	test ecx,0xffff0000
	jnz .bad
	test byte [ebx+ecx],0x10
	jnz .doneplat2
	inc al
	sub ecx,edx
	jmp .moreplat2

.doneplat2:
	xchg dh,dl

.morelen2:
	test ecx,0xffff0000
	jnz .bad
	test byte [ebx+ecx],0x20
	jnz .donelen2
	inc ah
	sub ecx,edx
	jmp .morelen2

.donelen2:
	// now ecx=first tile of section ax=NNLL
	shl eax,16
	mov ax,[curstationtile]
	sub ax,cx	// ax = CCPP
	pop edx
	pop ebx
	mov ecx,[curstationtile]
	jmp getplatforminfo.getccppflip

// variable 42: station terrain
// out:	eax=0000ttTT
//	tt=track type
//	TT=terrain type
global getstationterrain
getstationterrain:
	mov ecx,[curstationtile]

	// get terrain type into eax (this clears ah as well)
	xchg ecx,esi
	call gettileterrain
	xchg ecx,esi

	movzx ecx,byte [landscape3+ecx*2]	// track type
	and ecx,0x0f

	testmultiflags electrifiedrail
	jnz .iselrail

	// elrail off
	inc ecx
	cmp ecx,2
	sbb ecx,0
.gotit:
	mov ah,cl
	ret

.iselrail:
	cmp ecx,1
	jbe .gotit
	mov ah,[unimaglevmode]
	inc ah
	ret

// variable 44: PBS state
// out:	eax=bit 0/1 PBS state
global getstationpbsstate
getstationpbsstate:
	mov eax,2
	testmultiflags pathbasedsignalling
	jz .nopbs

	mov eax,[curstationtile]
	bt dword [landscape3+eax*2],7
	sbb eax,eax
	and eax,3
	or eax,4

.nopbs:
	ret

// variable 45: does track continue
// out: eax=xxxxxxAA
//	AA, bits 0..3: track in +L -L +P -P dir
//	AA, bits 4..7: track in +L -L +P -P dir, even if not connected
global gettrackcont
gettrackcont:
	push ebx
	push edi
	push esi

	xor ebx,ebx

	mov edi,[curstationtile]
	movzx esi,byte [landscape5(di,1)]
	and esi,1
	shl esi,3

.nextdir:
	movsx edi,word [.ofs+esi*2]
	add edi,[curstationtile]

	mov al,[landscape4(di,1)]
	shr al,1
	and eax,0x78
	mov ecx,[ophandler+eax]
	xor eax,eax
	push esi
	call [ecx+0x24]		// GetRouteMap
	pop esi
	or al,ah
	jz .nothing

	movzx ecx,byte [.dir+esi]
	test al,[piececonnections+ecx]
	setnz al
	mov ah,1
	mov ecx,esi
	and ecx,7
	shl eax,cl
	or ebx,eax

.nothing:
	inc esi
	test esi,7
	jnz .nextdir

	mov eax,ebx
	pop esi
	pop edi
	pop ebx
	ret

	align 4
.dir:	db 5,1,3,7,3,3,7,7		// station in X direction
	db 3,7,5,1,5,5,1,1		// station in Y direction
.ofs:	dw 1,-1,0x100,-0x100,0x101,0xff,-0xff,-0x101
	dw 0x100,-0x100,1,-1,0x101,-0xff,0xff,-0x101

// variables 46/47: similar to 40/41 but counted from the middle
// out: eax=xTNLxxCP
//	C and P signed variables counted from the middle, -8..7
global getplatformmiddle
getplatformmiddle:
	call getplatforminfo
	jmp short getstationsectionmiddle.getmiddle

global getstationsectionmiddle
getstationsectionmiddle:
	call getstationsectioninfo
.getmiddle:	// eax=0TNLcCpP
	shld ecx,eax,20		// ecx=xxx0TNLc
	shr cl,5
	shr ch,1 
	and ch,7		// ecx=xxxx0n0l where n,l=N,L div 2 //rounded up
	and ax,0x0f0f
	sub ah,ch
	sub al,cl
	shl al,4
	shr ax,4	
	mov ah,0		// eax=0TNL00CP
	ret

// var. 48: bit mask of accepted cargos
global getstationacceptedcargos
getstationacceptedcargos:
	testflags newcargos
	jc .new

	xor eax,eax
	xor ecx,ecx
.nextslot:
	test byte [esi+station.cargos+ecx*stationcargo_size+stationcargo.amount+1],0x80
	jz .noaccept
	bts eax,ecx
.noaccept:
	inc cl
	cmp cl,12
	jb .nextslot

	ret

.new:
	mov eax,esi
	add eax,[stationarray2ofst]
	mov eax,[eax+station2.acceptedcargos]
	ret

// var. 4A: get current animation frame
exported getstationanimframe
	mov eax,[curstationtile]
	movzx eax, byte [landscape7+eax]
	ret

// parametrized var. 66: get animation frame of nearby tile
exported getnearbystationanimframe
	push ebx
	sar ax,4
	sar al,4
	mov ebx,[curstationtile]
	test byte [landscape5(bx)],1
	jz .noswap
	xchg al,ah
.noswap:
	add al,bl
	add ah,bh

	mov cl,[landscape4(ax,1)]
	and cl,0xf0
	cmp cl,0x50
	jne .nottile

	mov cl,[landscape2+eax]
	cmp [landscape2+ebx],cl
	jne .nottile

	mov cl,[landscape5(ax,1)]
	cmp cl,8
	jae .nottile

	pop ebx
	movzx eax,byte [landscape7+eax]
	ret

.nottile:
	pop ebx
	or eax,byte -1
	ret

// helper function for vars 60..64
// in:	ah: cargo#
//	esi->station
// out: ecx: cargo offset
getstationcargooffset:
	push dword [mostrecentspriteblock]
	movzx eax,ah
	push eax
	call lookuptranslatedcargo
	pop eax
	add esp,4
	cmp al,0xff
	je .notpresent

	testflags newcargos
	jc .newoffset
	movzx ecx,al
	shl ecx,3
	cmp ecx,12*8	// now cf is set if ecx is OK
	cmc
	ret

.newoffset:
	xchg ebx,esi
	call ecxcargooffset
	xchg ebx,esi
	inc cl		//now cl=0 if and only if it was FF (cargo not present)
	sub cl,1	//now cl is back to the old value, but cf is set if it's FF
	ret

.notpresent:
	stc
	ret

// var 60: amount of cargo waiting
global getcargowaiting
getcargowaiting:
	call getstationcargooffset
	jc .returnzero

	movzx eax,word [esi+station.cargos+ecx+stationcargo.amount]
	and ax,[stationcargowaitingmask]	// mask out acceptance data
	ret

.returnzero:
	xor eax,eax
	ret

// var 61: time since cargo was last picked up
global getcargotimesincevisit
getcargotimesincevisit:
	call getstationcargooffset
	jc getcargowaiting.returnzero

	movzx eax,byte [esi+station.cargos+ecx+stationcargo.timesincevisit]
	ret

// var 62: cargo rating (-1 if unrated)
global getcargorating
getcargorating:
	call getstationcargooffset
	jc .returnminusone

	cmp byte [esi+station.cargos+ecx+stationcargo.enroutefrom],-1
	je .returnminusone

	movzx eax,byte [esi+station.cargos+ecx+stationcargo.rating]
	ret

.returnminusone:
	or eax,-1
	ret

// var 63: time since cargo is in transit
global getcargoenroutetime
getcargoenroutetime:
	call getstationcargooffset
	jc getcargowaiting.returnzero

	movzx eax,byte [esi+station.cargos+ecx+stationcargo.enroutetime]
	ret

// var 64: age/speed of last vehicle picking up the cargo
global getcargolastvehdata
getcargolastvehdata:
	call getstationcargooffset
	jc .returndefault

	xor eax,eax
	mov al,[esi+station.cargos+ecx+stationcargo.lastspeed]
	mov ah,[esi+station.cargos+ecx+stationcargo.lastage]
	ret

.returndefault:
	mov eax,0xFF00
	ret

exported getcargoacceptdata
	push dword [mostrecentspriteblock]
	movzx eax,ah
	push eax
	call lookuptranslatedcargo
	pop eax
	add esp,4
	cmp al,0xff
	je getcargowaiting.returnzero

	testflags newcargos
	jc .newformat
	shl eax,3
	cmp eax,12*8
	jae getcargowaiting.returnzero
	movzx eax, byte [esi+station.cargos+eax+stationcargo.amount+1]
	shr eax,4
	ret

.newformat:
	cmp eax,32
	jae getcargowaiting.returnzero
	mov ecx,esi
	add ecx,[stationarray2ofst]
	bt dword [ecx+station2.acceptedcargos],eax
	setc al
	shl al,3
	ret

#if 0
// variable 41: major cargo waiting
// out:	eax=aaRRTTAA
//	aa age in days (00 if no cargo)
//	RR rating for this cargo (average rating if no cargo)
//	TT cargo type (FE if no cargo ever, FF if no cargo at the moment)
//	AA amount in units of 16 (00 if no cargo)
getmajorcargo:
	push ebx
	xor ebx,ebx
	mov bh,0xff
	xor eax,eax
.nextcargo:
	mov ecx,[esi+eax*stationcargo_size+stationcargo.amount]
	// now ecx = RRxxAAAA
	shr cx,4
	cmp cl,bh
	jbe .notmore
	mov bh,cl
	mov bl,al
.notmore:
	cmp byte [esi+eax*stationcargo_size+stationcargo.enroutefrom],0xff
	je .notrated
	// store sum of ratings and number in upper 16 bits of ecx to get avg
	shr ecx,3
	and ecx,0xff000000
	lea ebx,[ebx+ecx+0x10000]
.notrated:
	inc al
	cmp al,12
	jb .nextcargo
	cmp bh,0xff
	je .nocargo
	movzx ebx,bh
	mov al,[esi+ebx*stationcargo_size+stationcargo.enroutetime]
	mov ah,[esi+ebx*stationcargo_size+stationcargo.rating]
	shl eax,16
	mov ecx,[esi+ebx*stationcargo_size+stationcargo.amount]
	shr cx,4
	mov al,cl
	mov ah,bl
	pop ebx
	ret

.nocargo:
	shld eax,ecx,16		// load ax with upper 16 bits of ecx
	cmp al,0
	je .nocargoever
	mov bl,al
	movzx eax,ah
	div bl
	jmp short .gotrating

.nocargoever:
	mov bh,0xfe
.gotrating:
	mov ah,0
	shl eax,16
	mov ah,bh
	pop ebx
	ret
#endif

// called when initialing a new station structure
// in:	esi->new station struct
// safe:edi
global setupstationstruct
setupstationstruct:
	push eax
	and word [esi+station.flags],0
	mov ax,[currentdate]
	mov [esi+station.datebuilt],ax
	call [randomfn]
	mov [esi+station.random],ax
	pop eax
	ret

// called when creating a new railway station
// in:	esi->station struct
// safe:eax ebp
global setuprailwaystation
setuprailwaystation:
	cmp byte [esi+station.facilities],0
	jne .nowaypoint		// already has other facilities

	movzx eax,byte [curplayer]
	cmp byte [curselclassid+eax],CLASS_WAYP
	jne .nowaypoint

	or byte [esi+station.flags],1<<6

.nowaypoint:
	or byte [esi+station.facilities],1
	ret

// called when a "bad" station in the city's transport zone would decrease ratings
//
// in:	esi->city
//	edi->station
//	 ax=old rating
//	ebx=owner
// out:	 ax=adjusted rating
// safe:?
global badstationintransportzone
badstationintransportzone:
	test byte [edi+station.flags],0x40
	jnz .waypoint
	sub ax,15	// replaced code
.waypoint:
	cmp ax,-1000
	ret


// called to update station windows when a station's cargo or ratings change
//
// in:	bx=station number
// out:	---
// safe:???
global updatestationwindow
updatestationwindow:
	push esi
	movzx esi,bx
	imul esi,station_size
	add esi,[stationarrayptr]
	call updatestationgraphics
	pop esi
	mov al,0x11
	call [invalidatehandle]
	ret

global updatestationgraphics
updatestationgraphics:
	pusha
	movzx eax,word [esi+station.railXY]
	test eax,eax
	jz .notrainstation
	

	testflags irrstations
	jnc .noirrstations

	call irrgetrailxysouth
	sub dl, al
	sub dh, ah
	add dx, 0x101
	jmp short .notflip
	
.noirrstations:
	mov dh,[esi+station.platforms]
	mov dl,dh
	and dx, 8778h 	// Bitmask: 10000111 1111000
	shr dl, 3
	cmp dh, 80h
	jb .istoosmall
	sub dh, (80h - 8h)
.istoosmall:
	// now dl = length, dh = tracks
	test byte [landscape5(ax,1)],1	// orientation
	jz .notflip
	xchg dh,dl
.notflip:
	movzx ecx,ah
	movzx eax,al
	shl ecx,4
	shl eax,4

.nexty:
	push edx
	push eax
.nextx:
	push edx
	call [invalidatetile]
	pop edx
	add eax,16
	dec dl
	jnz .nextx

	pop eax
	pop edx
	add ecx,16
	dec dh
	jnz .nexty

.notrainstation:
	popa
	ret


// called when cargo has been added to a station from an industry/town
// in:  ax=amount
//	dl=station number
//	esi->station
//	on stack: cargo type*8
// out:	bx=station number
// safe:???

//WARNING: This code isn't called if newcargos is on, but instead reproduced in patch code
//Anything you modify here must be modified in addcargotostation_2 (newcargo.asm) as well
global cargoinstation
cargoinstation:
	mov ebx,[esp+4]
	pusha
	
	shr ebx,3

	mov [statanim_cargotype],bl
	mov edx,1
	call stationanimtrigger

	xor edx,edx
	bts edx,ebx
	mov al,1
	mov ah,0x80
	mov ebx,esi
	call randomstationtrigger
	popa
	movzx ebx,dl
	jmp updatestationwindow

// trigger only the platform on which the train is active
// in:	esi->vehicle
//	edx=cargo mask for triggers
//	on stack: trigger bits
global stationplatformtrigger
stationplatformtrigger:
	pusha
	cmp byte [esi+veh.class],0x10
	jne .norail

	mov al,[esi+veh.laststation]
	movzx ebx,word [esi+veh.XY]
.withtile:
	mov ah,station_size
	mul ah
	movzx eax,ax
	add eax,[stationarrayptr]
	test byte [eax+station.facilities],1
	jz .norail

	mov [curstationtile],ebx
	mov ebx,eax
	mov esi,eax
	call getplatforminfo
	and ah,0x0f
	mov al,[esp+0x24]
	or ah,0x40	// force redraw
	call randomstationtrigger
.norail:
	popa
	ret 4

// same as above, but called with
// in:	ebx=XY of station tile
// 	edx/stack as above
stationplatformtriggerxy:
	pusha
	mov al,[landscape2+ebx]
	jmp stationplatformtrigger.withtile

// called when querying a station tile
// in:	cl=landscape5 value
//	di=tile index
// out:	carry set if railway station tile, then also
//		 ax=text id
//		ecx=textrefstack values
//	carry clear if other station
// safe:bh,si,ebp,others?
global stationquery
stationquery:
	cmp cl,8
	jb .railway
	ret

.railway:
	mov ax,statictext(railstationquery0)
	xor ecx,ecx

	movzx ebp,di
	movzx ebp,byte [landscape3+ebp*2+1]
	movzx ebp,byte [stationidgrfmap+ebp*8+stationid.gameid]
#if 0
	cmp dword [newstationnames+ebp*4],0
	je .nostationname
#endif

	mov ecx,ebp
	mov ch,0xc1
	inc eax

.nostationname:
	movzx ebp,byte [stationclass+ebp]
	cmp dword [newstationclasses+ebp*4],0
	je .nostationclassname

	shl ecx,16
	mov cx,bp
	mov ch,0xc0
	inc eax

.nostationclassname:
	stc
	ret

uvarb buildoverstationflag

// called when trying to clear station tile
// in:	bx=action flags
// out:	zf=1 allow clearing tile
//	zf=0 cf=1 prohibit clearing tile
//	zf=0 cf=0 continue checking
// safe:?
//
global allowbuildoverstation
allowbuildoverstation:
	cmp dh,7
	ja .done

	call isrealhumanplayer
	stc
	jnz .done

	cmp byte [buildoverstationflag],1

.done:
	ret

// action called to create railway station
global createrailwaystation
createrailwaystation:
	mov byte [buildoverstationflag],1
	call $
ovar .oldfn,-4,$,createrailwaystation
	mov byte [buildoverstationflag],0
	ret

// ---- Animation support added by Csaba ----

// Start/stop animation and set the animation stage of a station tile
// (Almost the same as sethouseanimstage, but stores the current frame differently)
// in:	al:	number of new stage where to start
//		or: ff to stop animation
//		or: fe to start wherewer it is currently
//		or: fd to do nothing (for convenience)
//	ah: number of sound effect to generate
//	ebx:	XY of station tile
setstattileanimstage:
	or ah,ah
	jz .nosound

	pusha
	movzx eax,ah
	and al,0x7f
	mov ecx,ebx
	rol bx,4
	ror cx,4
	and bx,0x0ff0
	and cx,0x0ff0
	or esi,byte -1
	call [generatesoundeffect]
	popa

.nosound:
	cmp al,0xfd
	je .animdone

	cmp al,0xff
	jne .dontstop

	pusha
	mov edi,ebx
	mov ebx,3				// Class 14 function 3 - remove animated tile
	mov ebp,[ophandler+0x14*8]
	call [ebp+4]
	popa
	jmp short .animdone

.dontstop:
	cmp al,0xfe
	je .dontset

	mov byte [landscape7+ebx],al

.dontset:
	pusha
	mov edi,ebx
	mov ebx,2				// Class 14 function 2 - add animated tile
	mov ebp,[ophandler+0x14*8]
	call [ebp+4]
	popa

.animdone:
	ret

exported stationanimhandler
#if WINTTDX
	movzx ebx,bx
#endif
	mov al,[landscape5(bx)]

	cmp al,8
	jb .railstation

	cmp al,0x27		// overwritten
	ret

.railstation:
	movzx eax, byte [landscape3+ebx*2+1]
	test eax,eax
	jz near .stop

	mov [curstationtile],ebx

	movzx eax, byte [stationidgrfmap+eax*8+stationid.gameid]

	cmp word [stationanimdata+2*eax],0xFFFF
	je .animdone1

	cmp byte [gamemode],2
	je .animdone1

	movzx esi,byte [landscape2+ebx]
	imul esi,station_size
	add esi,[stationarrayptr]

	mov edx,eax
	movzx edi, word [animcounter]
	mov ebp,1

	test byte [stationcallbackflags+eax],8
	jz .normalspeed

	mov byte [grffeature],4
	mov dword [curcallback],0x142
	call getnewsprite
	mov dword [curcallback],0
	mov cl,al
	jnc .hasspeed

.normalspeed:
	mov cl,[stationanimspeeds+edx]

.hasspeed:
	shl ebp,cl
	dec ebp
	test edi,ebp
	jz .nextframe

.animdone1:
	xor al,al
	stc
	ret

.nextframe:
	test byte [stationcallbackflags+edx],4
	jz .normal
	test byte [stationflags+edx],4
	jz .norandom

	push eax
	call [randomfn]
	mov [miscgrfvar],eax
	pop eax
.norandom:

	mov byte [grffeature],4
	mov dword [curcallback],0x141
	call getnewsprite
	mov dword [curcallback],0
	mov dword [miscgrfvar],0
	jc .normal

	test ah,ah
	jz .nosound

	pusha
	mov ecx,ebx
	rol bx,4
	ror cx,4
	and bx,0x0ff0
	and cx,0x0ff0
	or esi,byte -1
	call [generatesoundeffect]
	popa

.nosound:
	cmp al,0xff
	je .stop
	cmp al,0xfe
	jne .hasframe

.normal:
	mov al,[landscape7+ebx]
	inc al
	cmp [stationanimdata+2*edx],al
	jb .finished
.hasframe:
	mov [landscape7+ebx],al
	mov esi,ebx
	call redrawtile
	xor al,al
	stc
	ret

.finished:
	cmp byte [stationanimdata+2*edx+1],1
	jne .stop
	xor al,al
	jmp short .hasframe

.stop:
	mov edi,ebx
	mov ebx,3
	mov ebp,[ophandler+0x14*8]
	call [ebp+4]
	xor al,al
	stc
	ret

varb statanim_cargotype, 0xFF

exported stationplatformanimtrigger
	pusha
	cmp byte [esi+veh.class],0x10
	jne .norail

	movzx ebx, word [esi+veh.XY]
	movzx esi, byte [esi+veh.laststation]
	imul esi,station_size
	add esi,[stationarrayptr]

	test byte [esi+station.facilities],1
	jz .norail

	mov ch,1

	testflags irrstations
	jc .irregular

	mov cl,[esi+station.platforms]
	and cl,0x78
	shr cl,3

	test byte [landscape5(bx)],1
	jnz .ydir

	mov bl,[esi+station.XY]
	jmp stationanimtrigger.gotposandsize

.ydir:
	mov bh,[esi+station.XY+1]
	xchg cl,ch
	jmp stationanimtrigger.gotposandsize

.norail:
	popa
	ret

.irregular:
	xchg ebx,esi
	call getirrplatformlength
	xchg ebx,esi
	mov cl,al
	test byte [landscape5(bx)],1
	jz .noflip
	xchg cl,ch
.noflip:
	jmp stationanimtrigger.gotposandsize

// in:	esi-> station
//	edx: trigger bit + extra info for callback
exported stationanimtrigger
	test byte [esi+station.facilities],1
	jnz .hasrailway
	ret

.hasrailway:
	pusha

	movzx ebx,word [esi+station.railXY]

	testflags irrstations
	jc .irregular

	mov ch,[esi+station.platforms]
	mov cl,ch
	and ch, 0x87
	and cl, 0x78
	shr cl, 3
	test ch,0x80
	jz .notlarge
	add ch,8-0x80
.notlarge:

	test byte [landscape5(bx)],1
	jz .gotposandsize
	xchg cl,ch
	jmp short .gotposandsize

.irregular:
	mov ebp,edx
	xor edx,edx
	call irrgetrailxysouth
	sub edx,ebx
	lea ecx,[edx+0x0101]
	mov edx,ebp

.gotposandsize:
	mov byte [grffeature],4
	mov dword [curcallback],0x140
	mov [callback_extrainfo],edx
	movzx edx,dl
	call [randomfn]
	mov [miscgrfvar],eax

	movzx edi, byte [statanim_cargotype]

	push ebx
	push ecx

.checktile:
	mov al,[landscape4(bx)]
	and al,0xf0
	cmp al,0x50
	jne .nexttile

	cmp byte [landscape5(bx)],8
	jae .nexttile

	movzx eax, byte [landscape2+ebx]
	imul eax,station_size
	add eax,[stationarrayptr]
	cmp eax,esi
	jne .nexttile

	movzx eax, byte [landscape3+ebx*2+1]
	movzx eax, byte [stationidgrfmap+eax*8+stationid.gameid]
	test eax,eax
	jz .nexttile

	bt [stationanimtriggers+eax*2],edx
	jnc .nexttile

	mov [curstationtile],ebx

	mov ebp,eax

	cmp edi,0xFF
	je .nocargo

	mov eax,[stsetids+eax*stsetid_size+stsetid.act3info]
	mov eax,[eax+action3info.spriteblock]
	mov eax,[eax+spriteblock.cargotransptr]
	mov al,[eax+cargotrans.fromslot+edi]
	mov [callback_extrainfo+1],al

.nocargo:
	call [randomfn]
	mov [miscgrfvar],ax

	mov eax,ebp

	call getnewsprite
	jc .nexttile

	call setstattileanimstage

.nexttile:
	inc ebx
	dec cl
	jnz .checktile

	pop ecx
	pop ebx

	inc bh
	dec ch
	jz .done

	push ebx
	push ecx
	jmp .checktile

.done:
	and dword [curcallback],0
	and dword [miscgrfvar],0
	mov byte [statanim_cargotype],0xFF

	popa
	ret

exported newtrainstatcreated
	call .doanimtrigger
	btr word [esi+station.flags],0	// overwritten
	ret

.doanimtrigger:
	pusha
	xor edx,edx
	xor ecx,ecx
	xchg ecx,[curstationsectionsize]
	mov ebx,[curstationsectionpos]
	cmp word [curstationsectiondir],0x100
	jne .noswap
	xchg ch,cl
.noswap:
	jmp stationanimtrigger.gotposandsize

exported periodicstationupdate
	bt word [esi+station.flags],0	// overwritten
	jnc .trigger
	ret

.trigger:
	mov edx,6
	call stationanimtrigger
	clc
	ret
