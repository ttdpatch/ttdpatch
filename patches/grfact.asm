//
// GRF Action handler code
//

#include <std.inc>
#include <flags.inc>
#include <proc.inc>
#include <textdef.inc>
#include <vehtype.inc>
#include <grf.inc>
#include <industry.inc>
#include <newvehdata.inc>
#include <house.inc>
#include <flagdata.inc>
#include <font.inc>
#include <bitvars.inc>
#include <airport.inc>

extern tramtracks,numtramtracks
extern newonewayarrows,numonewayarrows
extern newwaterspritebase,numnewwatersprites
extern guispritebase,numguisprites
extern extfoundationspritebase,extfoundationspritenum,industileaccepts3
extern newcargounitnames
extern newcargounitweights
extern catenaryspritebase,copystationlayout,industileaccepts2
extern industileanimspeeds,industilecallbackflags,industryspecialflags
extern ingameindustryprobs,newcargoamountnnames,newcargoicons
extern newcargotypenames,numelrailsprites,setcargoclasses,setcargographcolors
extern setcargopricefactors,setcargotranstbl,setconflindustry
extern setindustileoverride,setindustryoverride,setsoundpriority
extern setstationspritelayout
extern shuffletrainveh,MassageSoundData
extern alterbridgespritetable,basecostmult,callbackflags,calloc
extern copystationspritelayout,costrailmul,curcallback,curspriteblock
extern errorpopup,exscurfeature,extraindustilegraphdataarr,findgrfid
extern fundchances,getextendedbyte,gettextintableptr,gettexttableptr
extern industileaccepts1,industileanimframes,industileanimtriggers
extern industilelandshapeflags,industrycallbackflags,industrycallbackflags2,industrycreationmsgs
extern industryinputmultipliers,industrynames,initialindustryprobs
extern insertactivespriteblock,insertactivespriteblockaction1,lastcalcresult
extern lookuppersistenttextid,malloc,malloccrit,newcargoamount1names
extern newcargodelaypenaltythresholds1,newcargodelaypenaltythresholds2
extern newcargoshortnames,newvehdata,numactsprites,numsiggraphics
extern orggentextptr,overrideoldsound,overridesprite,patchflags
extern patchflagsfixed,presignalspritebase,procallsprites_replaygrm
extern procgrffile,refreshrectxleft,refreshrectxright,refreshrectydown
extern refreshrectyup,setcargobit,setcargocolors,setfreighttrainsbit
extern sethouseclass,sethouseflags,sethouseoverride,setindustrylayout
extern setindustrymapcolors,setindustrysoundeffects,setnormalindustryprop
extern setsoundvolume,setspriteerror,setstationclass,setstationlayout
extern setsubstbuilding,setsubstindustile,setsubstindustry,specialtext1
extern specialtext2,specialtext3,spriteblockptr,spriteerror,spriteerrortype
extern spritehandlertable,stationidgrfmap,temp_snowline,totalmem
extern ttdpatchvercode,ttdplatform
extern vehtypedataptr,textclass_maxid,restoretranstexts
extern currtextlist,currmultis,curropts,currsymsbefore,currsymsafter,eurointr
extern languagesettings
extern cargotowngrowthtype,cargotowngrowthmulti,cargocallbackflags,setindustileaccepts
extern setinduproducedcargos,setindustryacceptedcargos,industrydestroymultis
extern allocfonttable,hasaction12,setsnowlinetable,snowytemptreespritebase
extern numsnowytemptrees,setstatcargotriggers,industilespecflags
extern ttdpatchversion
extern stationanimdata,stationanimspeeds
extern newcoastspritebase, newcoastspritenum
extern setairportlayout,airportstarthangarnodes,setairportmovementdata
extern airportcallbackflags,airportspecialflags,airportaction3
extern airportweight,airporttypenames

uvarb action1lastfeature



	//
	// **************************************
	//
	// pseudo-sprite action handlers
	//
	// all are called with the following parameters:
	//	eax=first byte of data
	//	ecx=eax*4
	//	edx->sprite block
	//	esi->remainder of data
	//	edi=number of following sprite
	//
	// must preserve (or adjust properly) edi
	// all other registers are fair game
	//
	// **************************************
	//


	// *** action 0 handler ***
action0:
	// Four extra bytes in front of this sprite data are used this way:
	// - pointer to feature-specific data, or 0 if none

proc processnewinfo
	local vehtype,numinfo,offset, specificnum, speciallist,specialnum, maxesi
	local dataptrofs,orgoffset,ofstrans,curoffset,numofsleft,curprop

	_enter

	push edi

	lea ebx,[esi-6]
	mov [%$dataptrofs],ebx

	mov [%$vehtype],eax
	mov ebx,[specificpropertylist+ecx]
	movzx eax,byte [ebx]		// number of vehtype-specific properties
	lea ebx,[ebx+1+eax]
	mov [%$speciallist],ebx		// vehtype-special properties
	mov [%$specificnum],al
	mov al,[ebx]
	mov [%$specialnum],al
	mov eax,[action0transtable+ecx]
	mov [%$ofstrans],eax

	mov ecx,[esi-6]
	lea ecx,[esi-2+ecx+1]
	mov [%$maxesi],ecx

	xor eax,eax
	lodsb
	mov ecx,eax	// num-props
	lodsb
	mov [%$numinfo],eax
	call getextendedbyte
	add eax,[globalidoffset]
	mov [%$offset],eax
	mov [%$orgoffset],eax

	test byte [expswitches],EXP_MANDATORYGRM
	jz .notmandatory

	cmp byte [grfstage],0
	je .resok
	mov ebx,[%$vehtype]
	mov ebx,[grfresbase+ebx*4]
	test ebx,ebx
	js .resok
	add ebx,eax
	push ecx
	mov ecx,[%$numinfo]
	jecxz .noids
.checknextres:
	cmp [grfresources+ebx*4],edx
	jne near .unresid
	inc ebx
	loop .checknextres
.noids:
	pop ecx
.resok:

.notmandatory:

	add eax,[%$numinfo]
	mov ebx,[%$vehtype]

	mov bl,[vehbnum+ebx]
	test ebx,ebx
	jz .nextprop	// no simple limit; handled by the functions

	cmp eax,ebx
	jbe .nextprop

	mov al,INVSP_BADID

.invalid:
	shl eax,16
	mov ax,ourtext(invalidsprite)

.seterror:
	pop edi
	test ax,ax
	jz .nomsg
	call setspriteerror
.nomsg:
	or edi,byte -1
	_ret

.nextprop:
	mov al,INVSP_OUTOFDATA
	cmp esi,[%$maxesi]
	jae .invalid

	xor eax,eax
	mov [%$numofsleft],eax

	push ecx
	mov ecx,[%$numinfo]
	lodsb
	mov [%$curprop],eax

	mov ebx,[%$orgoffset]
.nextsinglevalue:
	mov [%$curoffset],ebx

	mov edi,[%$ofstrans]
	test edi,edi
	jz .notrans		// stations and houses need translation of the offset

	cmp al,8		// but not for prop. 08 which *sets* the translation
	je .notrans

	mov bl,[edi+ebx]
	mov [%$offset],bl

	mov [%$numofsleft],ecx
	mov cl,1		// only process one at a time

	test bl,bl
	jz .skip		// referring to an undefined offset

.notrans:
	cmp al,7
	jb .genprop
	je .loadamount

	mov ebx,[%$vehtype]

	sub al,8
	cmp al,[%$specificnum]
	jb .specificprop

	sub al,[%$specificnum]
	cmp al,[%$specialnum]
	jb .specialprop

.invalidprop:	// invalid property
	mov al,INVSP_BADPROP
	jmp short .invalidpop
.unresid:	// unreserved ID
	mov al,INVSP_UNRESID
.invalidpop:
	pop ecx
	jmp .invalid

.skip:
	// FIXME: somehow need to skip the data, which however can be about
	// any arbitrary size, if we have a handler function :/
	// maybe rewrite all handler functions to accept ID=-1 as "skip" command?

.next:
	mov ecx,[%$numofsleft]
	jecxz .notoneatatime

	mov eax,[%$curprop]
	mov ebx,[%$curoffset]
	inc ebx
	loop .nextsinglevalue

.notoneatatime:
	pop ecx
	loop .nextprop

.done:
	pop edi

	_ret

.loadamount:
	xor ebx,ebx
	inc ebx
	mov eax,loadamount
	mov dl,1
	jmp .getgenprop

.genprop:
	// need edi=[vehtypedataptr]+(vehbase[type]+offset)*vehtypeinfo_size+eax

	mov ebx,vehtypeinfo_size
	mov dl,[gendata+1+eax]
	add eax,[vehtypedataptr]

.getgenprop:
	mov edi,[%$vehtype]
	movzx edi,byte [vehbase+edi]
	add edi,[%$offset]
	imul edi,ebx
	add edi,eax
	jmp short .doprop

.specialprop:
	// need edi=[specialpropbase+eax*4]+offset*entrysize

	mov edi,[specialpropertybase+ebx*4]
	mov edi,[edi+eax*4]
	test edi,edi
	jz .invalidprop
	mov edx,[%$speciallist]
	jmp .specprop

.specificprop:
	// need edi=specpropbase+al*vehbnum[type]+offset*entrysize

	mov edi,[specificpropertybase+ebx*4]
	mov edx,[specificpropertylist+ebx*4]

	mov bl,[vehbnum+ebx]
	imul ebx,eax
	add edi,ebx

.specprop:
	mov dl,[edx+eax+1]		// size of entry
	mov al,dl
	and al,7			// mask out 0x80 bit
	movzx ebx,al
	mul byte [%$offset]
	add edi,eax

.doprop:
	// now:
	// esi->action 0 property data
	// edi->first destination entry, or handler function
	// ebx=how many bytes for each destination array entry
	// ecx=number of entries
	//  dl=property type (0, 1, 2, 4, 0x40, 0x80, 0x84)
	//	(note, dl & 7 is the number of bytes per value)

	movzx eax,dl
	and eax,7
	imul eax,ecx
	add eax,esi
	cmp eax,[%$maxesi]
	mov al,INVSP_OUTOFDATA
	jae .invalidpop

	cmp byte [grfstage],0
	jne .doprocess

	cmp dl,0x40
	je .doprocess	// during initialization, only process 40 and 80

	cmp dl,0x80
	jne near .skipprop	

.doprocess:
	cmp dl,0x82
	je .textid

	cmp dl,1
	jb .invalidprop		// 0
	je near .bytevalue	// 1
	js .pointervalue	// 0x84

	cmp dl,4
	jb .wordvalue		// 2
	je .dwordvalue		// 4
	jp .functionnotranslate	// 0x40 (40-4=3C=PE but 80-4=7C=PO)
				// 0x80

	// handler functions are called with the following registers:
	// in:	eax=prop-num
	//	ebx=offset (translated for type "F", untranslated for type "H")
	//	ecx=num-info (for type "H" only; type "F" should assume num-info=1)
	//	edx->feature specific data offset
	//	esi->data
	// out:	esi->after data
	//	carry clear if successful
	//	carry set if error, then ax=error message
	// safe:eax ebx ecx edx edi ebp

.specialfunction:
	mov eax,[%$curprop]
	mov ebx,[%$offset]
	mov edx,[%$dataptrofs]
	push ebp
	call edi
	pop ebp
	jnc .next

	pop ecx
	jmp .seterror

.functionnotranslate:
	mov eax,[%$curprop]
	mov ebx,[%$orgoffset]
	mov ecx,[%$numinfo]
	mov edx,[%$dataptrofs]
	push ebp
	call edi
	pop ebp
	jnc .notoneatatime

	pop ecx
	jmp .seterror

.pointervalue:	// for DOS, fall through to .dwordvalue
#if WINTTDX
	lodsd
	test eax,eax
	jz .zero
	add eax,datastart
.zero:
	mov [edi],eax
	add edi,ebx
	loop .pointervalue
	jmp .next
#endif

.dwordvalue:
	lodsd
	mov [edi],eax
	add edi,ebx
	loop .dwordvalue
	jmp .next

.wordvalue:
	lodsw
	mov [edi],ax
	add edi,ebx
	loop .wordvalue
	jmp .next

.textid:
	lodsw
	call lookuppersistenttextid
	mov [edi],ax
	add edi,ebx
	loop .textid
	jmp .next

.bytevalue:
	lodsb
	mov [edi],al
	add edi,ebx
	loop .bytevalue
	jmp .next

.skipprop:
	and edx,7
	imul edx,ecx
	add esi,edx
	jmp .next

endproc // processnewinfo

	// same as above; running during "reserve" pass
	// only applies cargo properties
action0cargo:
	cmp eax,11
	je processnewinfo
	ret


	// *** action 1 handler ***
action1:
	// Four extra bytes in front of this sprite data are used this way:
	// - unused
	// - (word) grfhelper: stores faked spritenumber

newspriteblock:
	mov byte [action1lastfeature], al
	lodsb
	mov ebp,eax
	mov [lastspriteblocknumsets],eax

		// get total number of sprites = num-sprites*num-dirs
	call getextendedbyte
	imul ebp,eax

	add ebp,edi
	cmp ebp,[edx+spriteblock.numsprites]
	mov dh,INVSP_BLOCKTOOLARGE
	ja near newcargoid.invalid

	dec eax
	mov [spriteand],al

	mov edi,ebp	// skip sprites
	ret
; endp newspriteblock

activatevehspriteblock:
	push esi
	mov byte [exscurfeature], al	//needed to resolve the action 1 feature later ...
	lodsb
	mov ecx,eax
	call getextendedbyte
	imul ecx,eax
	mov ah,0x7f
	jecxz .nosprites
	call insertactivespriteblockaction1
.nosprites:
	// grfhelper
	pop esi
	mov word [esi-2-2], ax		// esi is on pseudspritedata+2
	mov [spritebase],eax
	ret

skipvehspriteblock:
	lodsb
	mov ecx,eax
	call getextendedbyte
	imul ecx,eax
	add edi,ecx
	ret


	// *** action 2 handler ***
action2:
	// Four extra bytes in front of this sprite data are used this way:
	// - regular cargo ID:
	//   <00> <W:base-sprite> <B:and-mask>
	//	base-sprite: real sprite number of first sprite in action 1
	//		     after mapping into TTD's sprite number space
	//	and-mask: mask for the direction variable
	// - random ID:
	//   (unused)
	// - variational ID:
	//   for regular variables: unused
	//   for var. 7E: <W:spritenum> (sprite number of referred var.action 2)
	//
	// Also all sprite numbers are translated into numbers relative
	// to the action 1 sprite number.

newcargoid:
//	cmp byte [action1lastfeature], al
//      mov dh,INVSP_WRONGFEATURE
//	jnz near .invalid

	push eax

	xor ebp,ebp
	xchg ebp,[esi-6]
	lea ebp,[ebp+esi-2]

	mov al,[spriteand]
	mov [esi-3],al	// store and mask in front of cargo ID data

		// find out the number of directions and store in cl
	lea ecx,[eax+1]

	lodsb			// cargo id
	push eax
	call .doit		// do stuff, then set ID afterwards
	pop ecx
	lea ebx,[edi-1]		// edi is one too high
	mov [cargoids+2*ecx],bx	// store sprite number for this cargo ID
//	mov al,[action1lastfeature]

	pop eax
	mov [cargoidfeatures+ecx],al
	ret

.doit:
	lodsb			// num-loadtypes or random/variational bit
	cmp al,0x83
	je near .randomid

	cmp al,0x80
	// jb .cargoid
	je near .randomid
	ja near .variationalid

.cargoid:
	cmp byte [esi-3],0xa
	je near .industryid

	mov dl,[esi-3]
	cmp byte [action1lastfeature],dl
	mov dh,INVSP_WRONGFEATURE
	jne near .invalid

	cmp byte [esi-3],7
	je .houseid
	cmp byte [esi-3],9
	je .industileid
	mov edx,eax
	lodsb
	add edx,eax

.adjustnext:
	lodsw
	test ah,ah
	js .regcallback

	cmp ax,[lastspriteblocknumsets]
	mov dh,INVSP_BADBLOCK
	jae near .invalid
	mul cl
	mov [esi-2],ax

.regcallback:
	dec dl
	jnz .adjustnext

	cmp esi,ebp
	mov dh,INVSP_OUTOFDATA
	ja near .invalid
	ret

// Action 2s for houses and industry tiles have a different format that
// allows using original TTD sprites and recoloring as well. Adjust only
// the last 13 bits of the two sprite dwords, or leave everything alone
// if their bit 31 is clear
.houseid:
.industileid:
	or al,al
	jnz .advancedtileid

	call .adjusttilesprite
	jc near .invalid
	call .adjusttilesprite
	jc near .invalid

	add esi,5
	cmp esi,ebp
	mov dh,INVSP_OUTOFDATA
	ja near .invalid
	ret

.advancedtileid:
	mov dl,al
	call .adjusttilesprite
	jc .invalid

.nextadvancedtilesprite:
	call .adjusttilesprite
	jc .invalid
	cmp byte [esi+2],0x80
	je .short
	add esi,3
.short:
	add esi,3
	dec dl
	jnz .nextadvancedtilesprite

	cmp esi,ebp
	mov dh,INVSP_OUTOFDATA
	ja .invalid
	ret

.adjusttilesprite:
	lodsd
	or eax,eax
	jns .noadjust
	mov ch,ah
	and ch,0xc0
	and ah,~0xc0

	cmp ax,[lastspriteblocknumsets]
	mov dh,INVSP_BADBLOCK
	jae .invalidtilesprite

	mul cl
	or ah,ch
	mov [esi-4],ax
.noadjust:
	clc
	ret
.invalidtilesprite:
	stc
	ret

.industryid:
	// industry entries don't contain sprite numbers, so check the size only
	mov dh,INVSP_BADBLOCK
	or al,al
	jnz .invalid

	add esi,11
	cmp esi,ebp
	mov dh,INVSP_OUTOFDATA
	ja .invalid
	ret

.randomid:
	inc esi			// random-type
	inc esi			// randbit
	lodsb			// nrand

	mov ecx,eax

	dec eax
	mov [esi-1],al	// instead of nrand, store mask

.adjustrandom:
	lodsw
	test ah,ah
	js .randomcallback

	mov dh,INVSP_INVCID
	jnz .invalid

	mov ax,[cargoids+2*eax]
	test ax,ax
	jz .invalid
	mov [esi-2],ax
.randomcallback:
	loop .adjustrandom

	cmp esi,ebp
	mov dh,INVSP_OUTOFDATA
	ja .invalid
	ret

	// jmp here with dh=INVSP_* error code
.invalid:
	shrd eax,edx,24		// set eax(16:23)=dh
	mov ax,ourtext(invalidsprite)
	call setspriteerror
	or edi,byte -1
	ret

.variationalid:
	lea ecx,[esi-8]
	xor ebx,ebx
	inc ebx
	test al,0xc
	jz .notwide

	mov bl,2

	test al,0x8
	jz .notdword

	mov bl,4

.notdword:
.notwide:

.nextvar:
	lodsb			// variable
	mov ah,al
	and ah,0xe0
	cmp ah,0x60
	mov ah,0
	jne .noparam
	cmp al,0x7e
	lodsb
	jne .noparam
	// var 7E, need to resolve var.action 2 ID
	movzx eax,al
	mov ax,[cargoids+2*eax]
	test eax,eax
	mov dh,INVSP_INVCID
	jz .invalid
	mov [ecx],ax

.noparam:
	lodsb
	test al,0xc0
	jz .nodivision

	lea esi,[esi+2*ebx]	// skip the additional two numbers

.nodivision:
	lea esi,[esi+ebx+1]

	test al,0x20
	jnz .nextvar

	mov al,[esi-1]			// nvar

	lea ecx,[eax+1]		// +1  because there is a default cargo ID

.nextvariation:
	lodsw
	test ah,ah
	js .varcallback
	mov dh,INVSP_INVCID
	jnz .invalid

	mov ax,[cargoids+2*eax]
	test ax,ax
	jz .invalid
	mov [esi-2],ax
.varcallback:
	lea esi,[esi+2*ebx]			// skip ranges
	loop .nextvariation

	sub esi,ebx
	sub esi,ebx		// was too large by 2 (no range for default)
	cmp esi,ebp
	mov dh,INVSP_OUTOFDATA
	ja .invalid
	ret
; endp newcargoid


activatecargoid:
	cmp byte [esi+1],0x80
	jb .realcargoid
	ret

.realcargoid:
	mov ebx,[spritebase]	// that's really a WORD value
	mov eax,ebx
	xchg ax,[esi-5]
	sub ebx,eax

	xor eax,eax
	lodsb		// cargo-id

	// now new sprite base saved at esi-5, and difference new-old is in ebx
	lodsb		// num-loadtypes
	cmp byte [esi-3],7
	je .houseid
	cmp byte [esi-3],9
	je .industileid
	cmp byte [esi-3],0xa
	je .industryid
	mov ecx,eax
	lodsb
	add ecx,eax

.adjustnext:
	test byte [esi+1],0x80
	jnz .callback
	add [esi],bx
.callback:
	inc esi
	inc esi
	loop .adjustnext
	ret

// Again, handle house definitions differently - modify them only if their
// bit 31 is set
.houseid:
.industileid:
	or al,al
	jnz .advancedtileid
	lodsd
	or eax,eax
	jns .noadjustfirst
	add [esi-4],bx
.noadjustfirst:
	lodsd
	or eax,eax
	jns .noadjustsec
	add [esi-4],bx
.noadjustsec:
	ret

.advancedtileid:
	movzx ecx,al
	lodsd
	or eax,eax
	jns .noadjustground
	add [esi-4],bx
.noadjustground:

.adjustnexttilesprite:
	lodsd
	or eax,eax
	jns .noadjustsprite
	add [esi-4],bx
.noadjustsprite:
	cmp byte [esi+2],0x80
	je .short
	add esi,3
.short:
	add esi,3
	loop .adjustnexttilesprite
	ret

.industryid:
	// no sprite numbers here, so we're done
	ret


	// *** action 3 handler ***
action3:
	// Four extra bytes in front of this sprite data are used this way:
	//	- pointer to action3info struc

initializevehcargomap:
	mov [action1lastfeature],al

	push byte action3info_size
	call malloc
	pop ecx

	mov [ecx+action3info.spriteblock],edx

	dec edi
	mov [ecx+action3info.spritenum],di
	inc edi

	mov ebx,ecx
	xchg ecx,[esi-6]
	lea ebp,[ecx+esi-2]

	lodsb		// n-id
	test al,al
	jns .nooverride

	mov ecx,[lastnonoverride]

	cmp dword [ecx+action3info.overrideptr],0
	jg .getcargoids

	push eax
	mov al,[action1lastfeature]
	mov al,[vehbnum+eax]
	shl eax,2
	push eax
	call calloc
	pop dword [ecx+action3info.overrideptr]
	pop eax
	jmp short .getcargoids

.nooverride:
	mov [lastnonoverride],ebx

.getcargoids:
	and al,0x7f
	add esi,eax

	// translate cargo-IDs into actual sprite numbers
	lodsb
	mov ecx,eax

.nextcid:
	jecxz .defcid
	lodsb		// cargo type

.defcid:
	lodsw		// cargo ID
	test ah,ah
	mov dh,INVSP_INVCID
	jnz newcargoid.invalid

	mov bx,[cargoids+2*eax]
	test bx,bx
	jz newcargoid.invalid
	mov [esi-2],bx	// store sprite number instead

	mov al,[cargoidfeatures+eax]
	cmp al,[action1lastfeature]
	mov dh,INVSP_WRONGFEATURE
	jnz newcargoid.invalid

	dec ecx
	jns .nextcid

	cmp esi,ebp
	mov dh,INVSP_OUTOFDATA
	ja newcargoid.invalid
	ret

setvehcargomap:
	test byte [expswitches],EXP_MANDATORYGRM
	jz .notmandatory

	mov ebp,edx
	mov edx,eax
	cmp byte [grfstage],0
	je .resok
	mov ebx,eax
	mov ebx,[grfresbase+ebx*4]
	test ebx,ebx
	js .resok

	push esi
	lea ebx,[grfresources+ebx*4]

	lodsb
	mov ecx,eax
	and ecx,0x7f
	jz .noids	// generic action 3, no IDs
.checknextres:
	lodsb
	cmp [ebx+eax*4],ebp
	jne near .badres
	loop .checknextres
.noids:
	pop esi
	mov eax,edx
.resok:

.notmandatory:
	mov edx,eax

	mov ebp,[esi-6]
	lodsb
	mov ecx,eax
	and ecx,0x7f

	push edi
	cmp ecx,1
	sbb edi,edi
	or edi,edx	// now edi=feature or edi=-1 if n-vid=0
	mov ebx,[ebp+action3info.spriteblock]
	cmp dword [ebx+spriteblock.grfid],byte -1
	cmc
	sbb ebx,ebx	// now ebx=-1 if GRFID was FFFFFFFF or 0 if not
	push ebp
	call [action3storeid+edi*4]
	pop ebp
	pop edi

	// resolve cargo ids
	push edi
	mov ecx,NUMACTION3CARGOS/2
	lea edi,[ebp+action3info.cargolist]
	xor eax,eax
	rep stosd
%if NUMACTION3CARGOS & 1
	stosw
%endif
	pop edi

	mov edx,[curspriteblock]
	mov edx,[edx+spriteblock.cargotransptr]

	xor eax,eax
	lodsb
	mov ecx,eax
	jecxz .defid
.nextid:
	lodsb
	movsx ebx,al
	lodsw
	cmp ebx,byte -2
	jae .havetrans

	push eax
	movzx ebx,bl
	mov eax,[edx+cargotrans.tableptr]
	mov eax,[eax+ebx*4]
	xor ebx,ebx

.search:
	cmp eax,[globalcargolabels+ebx*4]
	je .found
	inc ebx
	cmp ebx,NUMCARGOS
	jb .search

	// not found, don't use (set ZF=0)
	test esp,esp

.found:
	pop eax
	jnz .notset
#if 0
	jmp short .havetrans

.notranstbl:
	bt [cargobits],ebx	// valid in climate?
	jnc .notset

	mov bl,[cargoid+ebx]
#endif

.havetrans:
	mov [ebp+action3info.cargo+ebx*2],ax
.notset:
	loop .nextid

.defid:
	lodsw
	mov [ebp+action3info.defcid],ax

.done:
	ret

.badres:
	pop esi
	mov dh,INVSP_UNRESID
	jmp newcargoid.invalid

// store pointer to action 3 data for each ID define
//
// in:	eax=n-id unmodified (bit 7 set for livery override)
//	ebx=0 if GRFID != FFFFFFFF, ebx=-1 if GRFID=FFFFFFFF
//	ecx=n-id & 7F
//	edx=feature
//	ebp->action3info struct (pointer value to store)
//	esi->action 3 id list
// out:	esi->action 3 num-cid
// safe:eax ebx ecx edx
grfcalltable action3storeid, dd addr(action3storeid.generic)

.gethouses:
	lodsb
	add eax,[globalidoffset]
	mov al,[curgrfhouselist+eax]
	test ebx,[extrahousegraphdataarr+eax*4]
	jnz .skiphouse
	mov [extrahousegraphdataarr+eax*4], ebp
.skiphouse:
	loop .gethouses
	ret

.getindustiles:
	lodsb
	add eax,[globalidoffset]
	mov al,[curgrfindustilelist+eax]
	test ebx,[extraindustilegraphdataarr+eax*4]
	jnz .skipindustile
	mov [extraindustilegraphdataarr+eax*4], ebp
.skipindustile:
	loop .getindustiles
	ret

.getindustries:
	lodsb
	add eax,[globalidoffset]
	mov al,[curgrfindustrylist+eax]
	or al,al
	jz .nextindustry
	test ebx,[industryaction3+(eax-1)*4]
	jnz .nextindustry
	mov [industryaction3+(eax-1)*4], ebp
.nextindustry:
	loop .getindustries
	ret

.getcargos:
	lodsb
	add eax,[globalidoffset]
	test ebx,[cargoaction3+eax*4]
	jnz .skipcargo
	mov [cargoaction3+eax*4], ebp
.skipcargo:
	loop .getcargos
	ret

.getairports:
	lodsb
	add eax,[globalidoffset]
	mov al,[curgrfairportlist+eax]
	or al,al
	jz .nextairport
	mov [airportaction3+eax*4],ebp
.nextairport:
	loop .getairports
	ret

.getcanals:
	lodsb				// canal feature id
	add eax,[globalidoffset]
	test ebx,[canalfeatureids+eax*4]
	jnz .skipcanal
	mov [canalfeatureids+eax*4],ebp	// pointer to this action data
.skipcanal:
	loop .getcanals
	ret

.getstations:
	lodsb				// station-id
	add eax,[globalidoffset]
	movzx ebx,byte [curgrfstationlist+eax]
	test ebx,ebx
	jz .nextstation			// ignore stations not defined yet

	// now eax=setid, ebx=gameid (for terminology see statspri.asm)

	mov [stsetids+ebx*stsetid_size+stsetid.act3info],ebp
	mov [stsetids+ebx*stsetid_size+stsetid.setid],al

	// set stationid.gameid in stationidgrfmap
	push ebp
	mov bh,al
	xor eax,eax
	mov ebp,[curspriteblock]
	mov ebp,[ebp+spriteblock.grfid]
	push esi
	mov esi,stationidgrfmap
.searchnext:
	cmp [esi+eax*8+stationid.grfid],ebp
	jne .notthis

	cmp [esi+eax*8+stationid.setid],bh
	jne .notthis

	mov [esi+eax*8+stationid.gameid],bl
	mov al,0xff	// skip out of the loop

.notthis:
	add al,1
	jnc .searchnext
	pop esi
	pop ebp
.nextstation:
	loop .getstations
	ret

.generic:
	// n-id was zero, meaning this sets a generic class specific callback handler
	// also it's chainable, so remember the previous one
	mov ebx,ebp
	xchg ebx,[genericids+edx*4]
	mov [ebp+action3info.prev],ebx
	ret

.gettrains:
.getrvs:
.getships:
.getplanes:
	test al,0x80
	mov eax,edx
	movzx edx,byte [vehbase+edx]
	jns .regularmap

	push edx
	mov ebx,[lastnonoverride]
	mov edx,[ebx-7]
	mov bh,[ebx]
	mov edx,[edx+action3info.overrideptr]
	xor eax,eax

	// record wagon override
.nextwagon:
	lodsb
	mov [edx+eax*4],ebp
	cmp al,bh	// override for same vehid -> wagonoverride=2
	sete bl		// (used for rotors; planned for train steam etc.)
	inc bl
	add eax,[esp]
	mov [wagonoverride+eax],bl
	loop .nextwagon

	pop edx
	ret

.regularmap:
	mov [lastnonoverride],esi
	cmp dword [ebp+action3info.overrideptr],0
	jle .nooverrides

	// clear livery override list
	push edi
	push ecx
	movzx ecx,byte [vehbnum+eax]
	mov edi,[ebp+action3info.overrideptr]
	xor eax,eax
	rep stosd
	pop ecx
	pop edi

.nooverrides:
	lea edx,[vehids+edx*4]

	// record offset to cargo-ID table for all the veh.IDs
.nextvid:
	lodsb
	add eax,[globalidoffset]
	test ebx,[edx+4*eax]
	jnz .skipveh
	mov [edx+4*eax],ebp
.skipveh:
	loop .nextvid
	ret

.getbridges:
.getgeneric:
.getsounds:
	ud2


	// records original values for general text strings changed by an action 4
struc orggentext
	.next:		resd 1	// next action 4 for general texts in linked list
	.entries:		// variable number of pairs of DWORDs containing original string and new string
endstruc

// list of textIDs needing fixup, and the fixup procedures
// the textIDs need to be in increasing order, and the -1 guard entry shouldn't be removed

noglobal vard spectexthandlers
	dd 0x015b, addttdpatchver
	dd 0x0198, patchprofitcolor
	dd 0x0307, addttdpatchver
	dd 0x6809, fixloansizedisp
	dd 0x885e, fixpowerdisp
	dd 0xa007, fixaircraftcapandlife
	dd 0xa02e, fixaircraftcapacitynews
	dd -1, 0
endvar

// run all the fixup handlers on the original texts

exported runspectexthandlers

	pusha

	mov ebx, spectexthandlers

.next:
	mov eax, [ebx]
	cmp eax, byte -1
	je .done

	mov ebp,eax
	call gettextintableptr
	setc dl

	push eax
	mov esi,[eax+edi*4]
	jnc .noadd
	add esi,eax
.noadd:
	mov eax,esi
	call [ebx+4]

	mov esi,eax
	pop eax
	test dl,dl
	jz .nosub
	sub esi,eax
.nosub:
	mov [eax+edi*4],esi

	add ebx,8
	jmp short .next

.done:
	popa
	ret

// The following procedures handle fixing up some TTD texts
// These run during initialization, so they can allocate new buffers
// All share the same calling convention:
// in:	eax-> text
//	esi-> text
//	ebp: textID
// out:	eax-> new text
//	esi points to some "safe position" (there's exactly one NULL between esi and the next text)
// safe: eax

%assign maxverstringlen 64

// Append the TTDPatch version number to the main menu title and the about box title
// The version string is always all-ASCII, so we don't need to worry about UTF-8 here
addttdpatchver:
	push ecx
	push edi

// allocate the new storage
	mov ecx,maxverstringlen
	push ecx
	call malloccrit
	pop edi

	push edi

// copy the original text and add a comma
.nextbyte:
	lodsb
	test al,al
	jnz .notdone
	mov al,','
.notdone:
	stosb
	loopnz .nextbyte

// decrease esi so it points to the trailing NULL (a safe position), then save it
	dec esi
	push esi

// now append the version string
	mov esi,ttdpatchversion

.nextbyte2:
	lodsb
	cmp al,'('
	jne .notdone2
	mov al,0
.notdone2:
	stosb
	loopne .nextbyte2

// restore the saved safe position into esi
	pop esi
// pop the address of the buffer into eax
	pop eax

	pop edi
	pop ecx

	ret

// Fix the loan size display in the difficulty window so it doesn't have a hardcoded ",000" in it

fixloansizedisp:
	testflags generalfixes
	jc .doit
	testflags morecurrencies
	jc .doit
	ret

.doit:
	push eax
	push edi

// check if the string is encoded with UTF-8
	cmp word [eax],0x9ec3
	je .find7f_unicode

// just look for a plain 7F byte
.find7f:
	lodsb
	cmp al,0x7f
	je .foundit
	test al,al
	jz .endtoosoon
	jmp short .find7f

// in UTF-8 strings, the byte 7F means a literal character; the only way to encode
// the special character is EE 81 BF, so we only need to look for that
.find7f_unicode:
	lodsb
	test al,al
	jz .endtoosoon
	cmp al,0xee
	jne .find7f_unicode
	cmp word [esi],0xbf81
	jne .find7f_unicode

	add esi,2

.foundit:
// now esi points to the suspected start of ",000"; to make sure, we check if it really ends in "000"
	mov eax,[esi]
	shr eax,8
	cmp eax,'000'
	jne .endtoosoon

// remove those 4 chars, and copy the rest
	mov edi,esi
	add esi,4
.del:
	lodsb
	stosb
	test al,al
	jnz .del

.endtoosoon:
// rewind esi one byte so it surely points to a safe place
	dec esi

.done:
	pop edi
	pop eax
	ret

// fix the aircraft capacity display in the "new aircraft available" news message

fixaircraftcapacitynews:
	testflags newplanes
	jnc .done

	push eax
	push edi
	push ecx

	call fixaircraftcapacity

	dec esi
	pop ecx
	pop edi
	pop eax
.done:
	ret

// fix aircraft capacity and life display in the aircraft buy window

fixaircraftcapandlife:
	testflags newplanes
	jnc .done

	push eax
	push edi
	push ecx

	call fixaircraftcapacity

// now edi points one byte beyond the end of the text that has the capacity fixed up already
// ah is 1 if the text is UTF-8 encoded
	std

	test ah,ah
	jnz .unicode

// with normal encoding, we simply replace the last 7C with 7D
	mov al,0x7c
	repne scasb
	mov byte [edi+1],0x7d
// for the later code, esi needs to point inside the new string
	mov esi,edi
	jmp short .foundit

.unicode:
	mov esi,edi
	dec esi
// in UTF-8 mode, 7C is a verbatim character, the special char must be encoded as EE 81 BC

.find7c_unicode:
	lodsb
	cmp al,0xee
	jne .find7c_unicode
	cmp word [esi+2],0xbc81
	jne .find7c_unicode

// change it to EE 81 BD, the encoding for 7D

	mov byte [esi+3],0xbd
// in case we somehow went beyond the start of the string, pull esi back to the start of the sequence
	inc esi

.foundit:
	cld

// since we did the modification in-place, we must move esi to the start of the trailing junk to
// have it point to a safe place
	mov edi,esi
	xor eax,eax
	repne scasb
	mov esi,edi

	pop ecx
	pop edi
	pop eax
.done:
	ret


// auxiliary: fix the capacity display of an aircraft text so it uses {80} instead of "{7F} passengers, {7F} bags of mail"
// in:	esi->text
// out:	esi-> one byte beyond the end of the old text
//	edi-> one byte beyond the end of the new text
//	ah: 1 if the string uses UTF-8, 0 otherwise
fixaircraftcapacity:
	or ecx, byte -1

// check for UTF-8
	cmp word [esi],0x9ec3
	sete ah
	je .find7c_unicode

// in ASCII mode, it's simple to find the first 7C and replace it with 80
	mov edi,esi
	mov al,0x7c
	repne scasb
	mov byte [edi-1],0x80
	mov esi,edi
	jmp short .found7c

// like above, we need to find EE 81 BC
.find7c_unicode:
	lodsb
	cmp al,0xee
	jne .find7c_unicode
	cmp word [esi],0xbc81
	jne .find7c_unicode

// we can replace the whole sequence with a single 0x80, since the remaining two bytes
// will be removed anyway
	mov byte [esi-1], 0x80

	mov edi,esi

.found7c:
// now we need to remove all text from edi up to the next newline
// luckily, the newline looks the same way in both representations
	mov al,13
	repne scasb
	dec edi
	xchg esi,edi

.copynext:
	lodsb
	stosb
	test al,al
	loopnz .copynext

	ret

// fix the power display in the train details window so it can display powers above 32,000hp

fixpowerdisp:
	testflags newtrains
	jc .doit
	testflags multihead
	jc .doit
	ret

.doit:
	push eax
	push ecx

// check for Unicode
	cmp word [esi],0x9ec3
	je .unicode

// just find the second 7C byte and replace it with 7B in ASCII mode
	xchg esi,edi

	or ecx, byte -1
	mov al,0x7c
	repne scasb
	repne scasb
	dec edi

	mov byte [edi],0x7b
	xchg esi,edi
	jmp short .done

.unicode:
// in UTF-8 mode, we need to find the second occurence of EE 81 BC, and replace it with EE 81 BB
	mov ecx,2

.find7c_unicode:
	lodsb
	cmp al,0xee
	jne .find7c_unicode
	cmp word [esi],0xbc81
	jne .find7c_unicode
	loop .find7c_unicode

	mov byte [esi+1],0xbb

.done:
	pop ecx
	pop eax
	ret

// fixup the vehicle detail text in the vehicle list window so that it has the last year profit colored
// (actually, we just replace the second 7F with 80, the rest is done elsewhere)
// we also add a 80 to the end so we can show the performance score

patchprofitcolor:
	testflags showprofitinlist
	jc .doit
	ret

.doit:
	push ecx
	push esi
	push edi

	mov edi,esi
	or ecx,byte -1
	xor eax,eax

// the new text will be exactly one byte longer, so allocate a new buffer for it

	repnz scasb		// ecx is -length-1 now
	neg ecx
	push ecx		// allocate space for the new text
	call malloc
	pop edi
	push edi
	mov ecx,2		// which 0x7f to change

// check for UTF-8
	cmp word [esi],0x9ec3
	je .find7f_unicode

// in ASCII mode, just change the second 7F byte to 80
.find7f_normal:
	lodsb
	stosb
	cmp al,0x7f
	jne .find7f_normal
	loop .find7f_normal

	mov byte [edi-1],0x80
	jmp short .done

.find7f_unicode:
// in UTF-8 mode, look for the second EE 81 BF
	lodsb
	stosb
	cmp al,0xee
	jne .find7f_unicode
	cmp word [esi],0xbf81
	jne .find7f_unicode
	loop .find7f_unicode

// modify it to 80, and delete the remaining 2 bytes
	mov byte [edi-1],0x80
	add esi,2

.done:

// copy the rest of the text
.copyrest:
	lodsb
	stosb
	test al,al
	jnz .copyrest

// and add a 80 to the end
	mov word [edi-1],0x0080

	pop eax
	pop edi
	pop esi
	pop ecx
	ret

// check whether language byte matches current language
//
// in:	esi->language byte
// out:	esi->past language byte
//	al(7)=language byte(7)
//	CF=1 matches
//	CF=0 doesn't match
//	SF=bit 7 of language byte
// uses:al ecx
checklanguage:
	mov ecx,[curspriteblock]
	cmp byte [ecx+spriteblock.version],7
	lodsb
	mov ecx,[languageid]
	jae .oneid
	cmp cl,5
	jb .goodlang
	mov cl,0	// unknown language, pretend it's American
.goodlang:
	inc ecx
	sar al,cl
	ret

.oneid:
	mov ch,al
	and ch,0x80
	and al,0x7f
	cmp al,0x7f
	je .gotit
	xor cl,al
.gotit:
	sete al
	or al,ch	// set bit 7 correctly
	sar al,1	// this sets SF and CF correctly
	ret


	// *** action 4 handler ***
action4:
	// Four extra bytes in front of this sprite data are used this way:
	// - vehtype names: unused
	// - general texts: pointer to orggentext struc

initnewvehnames:
	xor ebp,ebp
	xchg ebp,[esi-6]
	lea ebp,[ebp+esi-2]

//	call checklanguage
//	jnc near .done

	lodsb
	test al,al
	jns near .done

	cmp word [esi+1],0xc000			// we don't need savig/restoring for patch texts
	jae .nosave

	cmp dword [edx+spriteblock.grfid],0x00ffffff
	jne .nottrans

	// this is a grf file made by grftrans
	// for general texts, replace the corresponding action 4 in the
	// previous file with the data from this one

//	XXX TODO XXX

.nottrans:
	// save original pointers for all modified strings in orggentext struc

	push esi

	lodsb
	mov ecx,eax

	lea edx,[orggentext.entries+ecx*8]
	push edx
	call malloccrit
	pop edx

	lea ebx,[esi-8]
	mov [ebx],edx			// store struct at DWORD before sprite data
	xchg ebx,[orggentextptr]	// store and load beginning of linked list
	mov [edx+orggentext.next],ebx	// link new struc at beginning and chain prev beginning

	push edi
	lodsw
	movzx edi,ax
	shr edi,11
	cmp ax,[textclass_maxid+edi*2]
	ja .badidpop
	call gettextintableptr
	test eax,eax
	jg .ok

.badidpop:
	pop edi

.badid:
	mov dh,INVSP_BADID
.invalid:
	jmp newcargoid.invalid		// trying to set invalid name

.ok:
	lea esi,[eax+edi*4]
	lea edi,[edx+orggentext.entries]

.nextorigtext:
	lodsd
	stosd
	add edi,4
	loop .nextorigtext

	pop edi

	lea ebx,[edx+orggentext.entries]

.geniddone:
	pop esi
	lodsb
	movzx ecx,word [esi]
	inc esi
	inc esi
	jmp short .checklen

.nosave:		// no need to save text IDs, but call text handler in
	push esi	// case it needs to allocate memory
	lodsb
	mov ecx,eax
	lodsw
.nextpatchid:
	push eax
	push edi
	call gettextintableptr
	test eax,eax
	pop edi
	pop eax
	jle .badid
	inc eax
	loop .nextpatchid
	xor ebx,ebx
	jmp .geniddone

.done:
	// check that action data is complete
	lodsb
	inc esi		// skip offset
	xor ebx,ebx

.checklen:
	push edi
	mov dl,al
	xchg ecx,ebp
	sub ecx,esi

	mov edi,spectexthandlers

// now ebx->orggentext or null, ecx=#of remaining bytes, edi->spec. text handler table, ebp=current textID
.compare:
// if we don't have an orggentext, we don't need to care about fixups (vehicle names or patch texts)
	test ebx,ebx
	jz .nextnull

	mov eax,esi

// edi always points to the next entry of the handler table so that the next ID is always greater or
// equal to the currently processed one

	cmp ebp,[edi]
	jb .notspecial
	je .special

// the text handler entry lags behind the current one - increase until it gets greater or equal

	add edi,8
	jmp short .compare

.special:
// call the handler for special texts
	call [edi+4]

.notspecial:
// now eax either still has esi for non-special texts, or the new pointer for special ones
	mov [ebx+4],eax
	add ebx,8

.nextnull:
	lodsb
	test al,al
	loopnz .nextnull
	mov dh,INVSP_OUTOFDATA
	jnz .invalid_pop
	inc ebp
	dec dl
	jnz .compare
	pop edi
	ret

.invalid_pop:
	pop edi
	jmp newcargoid.invalid

global undogentextnames
undogentextnames:	// not an actual action handler, but best fits in here
			// undoes all general text changes
	mov esi,[orggentextptr]		// points to DWORD before action 4 sprite data

.nextaction4:
	test esi,esi
	jnz .undoit

.done:
	jmp restoretranstexts		// restore E0xx texts

.undoit:
	mov edx,[esi]	// get orggentext struc
	add esi,7
	xor eax,eax
	lodsb
	mov ecx,eax

	lodsw
	call gettextintableptr
	lea esi,[edx+orggentext.entries]
	lea edi,[eax+edi*4]

.nextentry:
	lodsd
	stosd
	add esi,4
	loop .nextentry

	mov esi,[edx+orggentext.next]
	jmp .nextaction4


applynewvehnames:
	movzx ebx,byte [vehbase+eax]
	call checklanguage
	jc .rightlanguage
.trans:
	ret

.rightlanguage:
	btr eax,7		// general texts instead of vehicle names?
	sbb edx,edx		// 0 for vehnames, -1 for general texts

#if 0
	// breaks anyway, edx is wrong here
	cmp dword [edx+spriteblock.grfid],0x00ffffff
	je .trans	// skip translated general texts
#endif

	xor ebp,ebp

	lodsb
	mov ecx,eax		// num-veh

	test edx,edx
	js .generaltext

	lodsb
	add eax,[globalidoffset]
	add ebx,eax		// offset

	mov ah,0x80
	call gettexttableptr
	lea ebx,[eax+ebx*4]
	jmp short .gotit

.generaltext:
	lodsw
	cmp ah,0xc0
	jb .notpatchtext

	// it's a patch text, which means text IDs might not be
	// contiguous in the table, so only process one at a time
	mov ebp,eax

.nextgeneraltext:
	mov eax,ebp
	inc ebp

	push edi
	call gettextintableptr
	lea ebx,[eax+edi*4]
	pop edi
	jmp short .gotit

.notpatchtext:

// this is not a patch text, so we have the new pointers stored in the orggentext structure, we just
// need to copy them from there

	mov esi,[esi-10]
	add esi,orggentext.entries+4
	push edi
	call gettextintableptr
	lea edi,[eax+edi*4]

.nextsavedtxt:
	lodsd
	stosd
	add esi,4
	loop .nextsavedtxt
	pop edi
	ret

.nextveh:
	test ebp,ebp
	jnz .nextgeneraltext

.gotit:
	mov [ebx],esi
	add ebx,byte 4
.nextnull:
	lodsb
	test al,al
	jnz .nextnull
	loop .nextveh
	ret


	// *** action 5 handler ***
action5:
	// Four extra bytes in front of this sprite data are used this way:
	// - unused
	// - (word) grfhelper: stores faked spritenumber

checknewgraphicsblock:
	mov ebp,eax
	call getextendedbyte
	add edi,eax
	cmp di,[edx+spriteblock.numsprites]
	mov al,INVSP_BLOCKTOOLARGE
	ja .invalid

	cmp ecx,byte (numnewgraphicssprites*4+4*4)
	mov al,INVSP_BADFEATURE
	jae .invalid	// unknown block

	mov ebx,[newgraphicsspritebases+ecx-4*4]
	test ebx,ebx
	jle .invalid	// signed or zero = bad value

	cmp dword [edx+spriteblock.grfid],byte -1
	jne .notstandard
	bts [newgraphicssetsavail],ebp
.notstandard:
	ret

	// jmp here with al=INVSP_* error code
.invalid:
	shl eax,16
	mov ax,ourtext(invalidsprite)
	call setspriteerror
	or edi,byte -1
	ret

activatenewgraphics:
	mov ebx,[newgraphicsspritebases+ecx-4*4]

	bt [newgraphicssetsenabled],eax
	jnc skipnewgraphicsblock

	cmp dword [edx+spriteblock.grfid],byte -1
	je .notnormalid

	// regular ID
	bts [newgraphicswithgrfid],eax
	jmp short .useset

.notnormalid:
	// ID is -1, only use this set if no regular ID has set it yet
	bt [newgraphicswithgrfid],eax
	jc skipnewgraphicsblock

.useset:
	push esi
	call getextendedbyte
	mov esi,[newgraphicsspritenums+ecx-4*4]
	test esi,esi
	jle .nonum

	mov [esi],eax

.nonum:
	xchg eax,ecx
	call insertactivespriteblock

	//grfhelper
	pop esi
	mov word [esi-2-2], ax		// esi is on pseudspritedata+2
	mov [ebx],ax
	ret

skipnewgraphicsblock:
	call getextendedbyte
	add edi,eax
	ret


	// *** action 6 handler ***
action6:
	// Four extra bytes in front of this sprite data are used this way:
	// - unused

applyparam:
	mov ebp,[esi-6]		// sprite size

.nextparam:
	// here ecx=number*4

	sub ebp,3
	mov al,INVSP_OUTOFDATA
	jle checknewgraphicsblock.invalid

	lodsb			// eax=size
	btr eax,7		// was bit 7 set?
	lea ebx,[ecx+eax+3]	// now ebx=number*4+size+3
	sbb ah,ah		// -1 if bit 7 set, 0 otherwise
	shr ebx,2		// now ebx=required number of params
	cmp bl,[edx+spriteblock.numparam]
	ja .dont

	mov ebx,[edx+spriteblock.paramptr]
	add ebx,ecx		// now ebx points to param value

	mov ecx,eax		// cl=size  ch=0/-1
	call getextendedbyte	// eax=offset
	push esi
	push edi
	mov esi,[edx+spriteblock.spritelist]
	mov edi,[esi+edi*4]
	movzx esi,cl
	add esi,eax
	cmp esi,[edi-4]		// outside of sprite length?
	ja .bad
	add edi,eax
	mov esi,ebx
	test ch,ch
	jz .copy
	xor ch,ch		// also clears CF
.add:
	lodsb
	adc al,[edi]
	stosb
	loop .add
	// safe to fall through, ecx is zero
.copy:
	rep movsb
.bad:
	pop edi
	pop esi

	jmp short .next

.dont:
	call getextendedbyte		// need to skip offset

.next:
	xor eax,eax
	lodsb
	imul ecx,eax,4
	cmp al,0xff
	jnz .nextparam
.done:
	ret


	// *** action 7 and 9 handler ***
action7:
action9:
	// Four extra bytes in front of this sprite data are used this way:
	// - sprite number of target sprite for jump, or -1 if jump to EOF

initaction7:
initaction9:
	// find and store target sprite number

	movzx ebx,byte [esi]	// varsize
	cmp byte [esi+1],2
	jnb .notbittest
	mov bl,1		// for bit tests, varsize is always 1
.notbittest:
	mov bh,byte [esi+ebx+2]	// numsprites/label
	mov bl,0x10		// now BX = action 10 data defining this label

	or ebp,byte -1
	test bh,bh
	jz .havetarget		// numsprites=0 -> jump to EOF

	// search for next matching label
	mov ebp,edi
	mov ecx,[edx+spriteblock.spritelist]

.next:
	cmp bp,[edx+spriteblock.numsprites]	// at EOF, start from beginning
	jb .ok
	xor ebp,ebp
.ok:
	mov eax,[ecx+ebp*4]
	inc ebp
	cmp [eax],bx
	je .havetarget

	cmp ebp,edi				// searched whole file?
	jne .next

	movzx ebx,bh
	add ebp,ebx	// jump to edi+numsprites

.havetarget:
	mov [esi-6],ebp
	ret

skipspriteif:
	mov ebp,edx

	test al,al
	jns .isparam

	cmp ecx,(numextvars+0x80)*4
	mov al,INVSP_INVVAR
	jae .invalid

	mov edx,[externalvars+ecx-0x80*4]
	mov bh,1
	jmp short .gotvalue

.isparam:
	cmp al,[edx+spriteblock.numparam]
	jae near .dont

	mov edx,[edx+spriteblock.paramptr]
	add edx,ecx		// now [edx]=param value
	mov bh,0

.gotvalue:
	lodsb

.gotsize:
	mov ecx,eax		// size
	lodsb

.gottest:
	sub al,2
	xchg eax,ebx		// ebx=condition type
	jb near .bittest

	mov edx,[edx]

	mov bh,ah		// bh=1 if externalvar, 0 if param

	// a value test
	mov eax,[esi]
//	add esi,ecx

	shl ecx,3
	neg ecx
	add ecx,32		// now ecx=32-8*size

	shl eax,cl
	shr eax,cl		// clear unset bits of eax

	test bh,bh
	jz .notgamevar

	shl edx,cl		// clear unset bits of edx too
	shr edx,cl
	mov bh,0

.notgamevar:
	or ecx,byte -1

	// now eax = value
	cmp ebx,byte .numtests
	jae .invtest

	cmp eax,edx
	jmp [.comptests+ebx*4]

noglobal vard .comptests
	dd .equal, .notequal, .greater, .less
	dd .isactive, .inactive, .willbeactive, .active
	dd .notactive, .notcargotype, .cargotype
.numtests equ ($-.comptests)/4
endvar

.invtest:
	mov al,INVSP_INVTEST
.invalid:
	jmp checknewgraphicsblock.invalid

.equal:		// 2 = equal
	je .skipit
	jmp short .dont		// "jmp" isn't short by default... stupid...

.notequal:	// 3 = not equal
	jne .skipit
	jmp short .dont

.greater:	// 4 = greater
	ja .skipit
	jmp short .dont

.less:		// 5 = less
	jb .skipit
	jmp short .dont

.isactive:	// 6 = GRFID is active
	mov bl,1
	jmp short .findgrfid

.inactive:	// 7 = GRFID is inactive
	mov bl,0
	jmp short .findgrfid

.willbeactive:	// 8 = GRFID is inactive but will become active
	mov bl,3
	jmp short .findgrfid

.active:	// 9 = GRFID is or will be active
	mov bl,7
	jmp short .findgrfid

.notactive:	// A = GRFID is not or will not be active
	mov bl,6
	mov cl,0
	jmp short .findgrfid

.notcargotype:	// B = Cargo type is not defined
	mov bl,0
	jmp short .findcargo

.cargotype:	// C = Cargo type is defined
	mov bl,1
	jmp short .findcargo

.findgrfid:
	mov bh,bl
	xor bh,cl	// cl=FF except cl=FF for condition 0A

	test edx,edx
	jz .gotstate	// bh is such that bh!=bl

	mov bh,[edx+spriteblock.active]
	test bl,4
	jz .notand
	and bh,1
	or bh,6
.notand:
	test bl,2
	jnz .keepfuture	// if bl is 2 or 3, bl must match exactly

	and bh,3
	cmp bh,1	// otherwise,
	sete bh		// 0, 2 and 3 all count as inactive; 3 because the
			// grf isn't active *yet*

.keepfuture:
	cmp eax,[edx+spriteblock.grfid]
	mov edx,[edx+spriteblock.next]
	jne .findgrfid

.gotstate:
	cmp bl,bh
	je .skipit

.dont:
	ret

.findcargo:
	xor edx,edx
.checknextcargo:
	cmp eax,[globalcargolabels+edx*4]
	sete bh
	je .gotstate
	inc edx
	cmp edx,NUMCARGOS
	jb .checknextcargo
	jmp .gotstate

.bittest:
	movzx eax,byte [esi]
		// eax=bit number
		// ebx=bit test type-2
		// [edx]=value

	bt [edx],eax	// use memory bit test so we can use bitnumbers>31

	adc bl,1	// Have cases:
			// test	case	bl in  carry  bl out  skip?
			// 0	set	-2	  0	 -1	 no
			// 0	set	-2	  1	 0	 yes
			// 1	not set	-1	  0	 0	 yes
			// 1	not set	-1	  1	 1	 no
	jnz .dont

.skipit:
	mov ebx,[esi-8]	// target sprite
	cmp ebx,byte -1
#if 0
	xor eax,eax
	lodsb
	test al,al
#endif
	jnz .ok

	mov al,[ebp+spriteblock.active]
	and al,7
	cmp al,7	// to be forced active?
	je .dont

	mov al,0
	or ebx,byte -1

.ok:
	mov edi,ebx
	ret


	// *** action 8 handler ***
action8:
	// Four extra bytes in front of this sprite data are used this way:
	// - unused

grfidactivate:
	mov ah,1	// ah=1 to activate, ah=0 (by default) to record

recordgrfid:
	mov [edx+spriteblock.version],al
	mov cl,ah

	mov ebp,edx
	cmp dword [edx+spriteblock.action8],1
	adc ah,-1
		// cases of ah before and ah and flags after:
		// bef	action8	after	flags
		// 0	0	0	ZF NS
		// 0	!=0	-1	NZ SF	=> give error (more than one action8 in file)
		// 1	0	1	NZ NS
		// 1	!=0	0	ZF NS
	mov dh,INVSP_MULTACT8
	js newcargoid.invalid

	lea ebx,[esi-1]
	mov [ebp+spriteblock.action8],ebx
	add ebx,5
	cmp byte [ebx],0	// name defined?
	jne .gotname
	mov ebx,[ebp+spriteblock.filenameptr]
.gotname:
	mov [ebp+spriteblock.nameptr],ebx

	cmp al,THISGRFVERSION
	jb .wronggrfversion

	cmp al,MAXGRFVERSION
	jna .isok

.wronggrfversion:
	mov ax,ourtext(wronggrfversion)
	call setspriteerror
.skip:
	or edi,byte -1
	ret

.isok:
	lodsd		// grf-ID

	mov [ebp+spriteblock.grfid],eax

	test cl,cl
	jnz .activate
	ret

.activate:
	and byte [ebp+spriteblock.active],~2		// mark as processed
	mov ch,[ebp+spriteblock.active]
	and ch,~4
	cmp ch,cl
	jne .skip	// skip rest of file if not active
	ret


	// *** action A handler ***
actiona:
	// Four extra bytes in front of this sprite data are used this way:
	// - unused

replacettdsprite:
	mov ebx,eax		// num-sets

.nextset:
	lodsb
	movzx ecx,al		// num-sprites

	lodsw			// first-sprite
	add eax,[globalidoffset]

	mov ebp,edx
	lea edx,[eax+ecx]

	test byte [ebp+spriteblock.flags],4
	jnz .allownewsprites

	cmp edx,totalsprites
	jbe .spritenumok
.spritenumbad:
	mov dh,INVSP_SPNUM
.bad:
	jmp newcargoid.invalid

.allownewsprites:
	cmp edx,[numactsprites]
	ja .spritenumbad

.spritenumok:
	lea dx,[ecx+edi]
	cmp dx,[ebp+spriteblock.numsprites]
	mov dh,INVSP_BLOCKTOOLARGE
	ja .bad

	mov edx,ebp
	mov ebp,edi
.replnext:
	pusha
	cmp dword [edx+spriteblock.grfid],byte -1
	jne .notdefgrf

	// GRFID is FFFFFFFF, only override sprite if it's not a patch sprite
	extern newspritenum,newspritedata
	imul edi,[newspritenum],19
	add edi,[newspritedata]
	cmp byte [edi+eax],0	// was it immutable (i.e. one of ours)?
	jne .skipsprite

.notdefgrf:
	mov edi,[edx+spriteblock.spritelist]
	mov esi,[edi+ebp*4]
	mov edi,[esi-4]		// sprite size
	xchg eax,edi
	call overridesprite

.skipsprite:
	popa
	inc edi
	inc eax
	inc ebp
	loop .replnext

	dec ebx
	jnz .nextset
	ret

replacettdspriteskip:
	mov ecx,eax
.nextset:
	lodsb
	add edi,eax
	lodsb
	lodsb
	loop .nextset
	ret


	// *** action B handler ***
actionb:
	// Four extra bytes in front of this sprite data are used this way:
	// - unused

grferrormsg:
	bts eax,31

	// fall through

checkgrferrormsg:
	// eax = severity
	test al,al
	js .evenwheninitializing

	cmp [grfstage],ah	// (ah==00)
	je .done		// skip during initialization stage

	mov ah,1		// just store message for grf stat window

.evenwheninitializing:
	and al,0x7f
	xchg eax,ebx

	cmp bl,3
	mov al,INVSP_INVSEVERITY
	ja checknewgraphicsblock.invalid

	call checklanguage
	jnc .done

	lodsb
	cmp al,0xff
	je .isvalid

	cmp al,3
	mov al,INVSP_INVERRMSG
	ja checknewgraphicsblock.invalid

.isvalid:
	lea ecx,[edi-1]

	test bh,bh
	jz .showmsg

	cmp bl,3
	jae .showmsg		// always show fatal messages

	// just storing it
	cmp word [edx+spriteblock.errsprite],0
	jne .alreadyhaveerror
	mov [edx+spriteblock.errsprite],cx
	jmp short .alreadyhaveerror

.showmsg:
	mov [edx+spriteblock.errsprite],cx
	cmp dword [spriteerror],0
	jne .alreadyhaveerror

	// don't actually show if this is a check only (ebx bit 31 clear)
	test ebx,ebx
	jns .alreadyhaveerror

	mov [operrormsg2],cx
	mov [spriteerror],edx
	mov byte [spriteerrortype],2

.alreadyhaveerror:
	cmp bl,3
	jb .done

	// don't actually deactivate if this is a check only (ebx bit 31 clear)
	test ebx,ebx
	jns .done

	mov byte [edx+spriteblock.active],0x80
	or edi,byte -1

.done:
	ret


	// in:	esi->spriteblock with error
	//	pusha done
global dogrferrormsg
dogrferrormsg:
	movzx eax,word [operrormsg2]	// sprite number which has this action 0B
	mov edx,esi
	mov ebx,statictext(specialerr1)-statictext(special1)
	call formatspriteerror
	or edx,byte -1	// have it split into lines automatically
	xor eax,eax
	xor ecx,ecx
	call dword [errorpopup]
	popa
	ret

global formatspriteerror
formatspriteerror:
	mov esi,[edx+spriteblock.spritelist]
	mov esi,[esi+eax*4]

	mov ebp,[esi-4]		// length of sprite
	add ebp,esi

	xor eax,eax
	lodsb
	lodsb	// message type
	and al,0x7f
	push word [.grferrortypes+eax*2]

	lodsb
	lodsb	// message

	cmp al,0xff
	lea eax,[eax+ourtext(grfneedspatchversion)]
	jne .gotmessage

	mov [specialtext1+ebx*4],esi

.nextbyte:
	lodsb
	test al,al
	jnz .nextbyte
	lea eax,[statictext(special1)+bx]

.gotmessage:	// got BX=textid for message type, AX=textid for message text
		// now set up textstack
	mov edi,textrefstack
	stosw
	lea eax,[statictext(special2)+bx]
	stosw
	mov ecx,[edx+spriteblock.filenameptr]
	mov [specialtext2+ebx*4],ecx

	inc ax
	stosw
	mov [specialtext3+ebx*4],esi

	// skip <data>
.nextbyte2:
	lodsb
	test al,al
	jnz .nextbyte2

	// add values of up to two grf parameters to text stack (to use 14 bytes max)
	mov ecx,ebp
	sub ecx,esi
	jbe .done	// "below" shouldn't happen but to be safe...
	cmp ecx,2
	jbe .nextparam
	mov ecx,2
.nextparam:
	xor eax,eax
	lodsb
	cmp al,[edx+spriteblock.numparam]
	jae .notset
	mov ebp,[edx+spriteblock.paramptr]
	mov eax,[ebp+eax*4]
	jmp short .haveit
.notset:
	xor eax,eax
.haveit:
	stosd
	loop .nextparam

.done:
	pop bx	// message type
	ret

	align 2
.grferrortypes:
	dw statictext(grfnotice),ourtext(grfwarning)
	dw ourtext(grferror),ourtext(grferror)


	// *** action C handler ***
actionc:
	// Four extra bytes in front of this sprite data are used this way:
	// - unused

	// no code here, nothing to do...


	// *** action D handler ***
actiond:
	// Four extra bytes in front of this sprite data are used this way:
	// - most recent result of this action D
	//   (used for replaying GRM value after reserve pass)

setparam:
	test al,al
	js .globalvar
	cmp al,[edx+spriteblock.numparam]
	jb .ok

	pusha
	inc eax
	imul ebx,eax,4	// lea ebx,[eax*4] uses imm32=0 and we need eax later
	push ebx
	add [totalmem],ebx
	call malloc
	pop edi
	jc .error
	mov esi,[edx+spriteblock.paramptr]
	mov [edx+spriteblock.paramptr],edi
	movzx ecx,byte [edx+spriteblock.numparam]
	mov [edx+spriteblock.numparam],al
	sub eax,ecx
	rep movsd
	xchg eax,ecx
	rep stosd
	clc
.error:
	popa
	jnc .doop
	ret

.globalvar:
	extern procall_type
	cmp dword [procall_type],PROCALL_ACTIVATE	// skip writing to global
	je .ok						// variables unless doing
	cmp dword [procall_type],PROCALL_INITIALIZE	// activation or initialization
	jne .done

.ok:
	test byte [esi],0x80
	jns .doop

	// was defined, and only to be set if undefined, so don't do anything
.done:
	ret

.doop:
	mov ebx,edx
	push eax
	call .getparam
	pop ebp
	je .done
.invalidvar:
	mov dh,INVSP_INVVAR
.invalidjmp:
	jae newcargoid.invalid

	lodsb
	and al,0x7f
	cmp al,actiondop.numactiondops
	mov dh,INVSP_INVOP
	jae .invalidjmp
	mov ah,al
	lodsb
	movzx ecx,al
	lodsb

	cmp al,0xfe
	jne near .notothergrf

	push eax
	lodsd
	cmp al,0xff		// GRFID FFffrrrr is special
	je .specialgrfid	// (but eax=rrrrffFF)
.notspecial:
	call findgrfid
	pop eax
	jnc near .get1

	// didn't find it, use zero
	xor ebx,ebx
	jmp .zero2

	// ecx=operation (from param1)
	//	0: reserve (find && mark rrrr entries)
	//	1: allocate (find rrrr entries)
	//	2: check (see if rrrr entries from param1 are available)
	//	3: mark (mark rrrr entries from param1 as reserved)
	//	4: allocate-no-fail (like 1 but don't deactivate on error)
	//	5: check-no-fail (like 2 but don't deactivate on error)
	//	6: get (find who owns an entry)
	// eax( 8:15)=ff=feature
	// eax(16:31)=rrrr=count
	// ebp->where to store result
	// esi->end of action D
.specialgrfid:
	cmp ah,NUMFEATURES
	jae .notspecial
	cmp ecx,byte .numspecialactions
	jae .notspecial

	cmp byte [grfstage],0
	je near .paramdone	// don't do this during initialization

	mov bh,ah		// bh=feature
	mov bl,cl		// bl=action
	shr eax,16
	mov ecx,eax		// ecx=rrrr

	mov eax,[curspriteblock]
	test byte [eax+spriteblock.active],1
	pop eax			// (just to clear the stack; makes eax=FE)

	jz .done		// not active, just ignore this

	movzx eax,bl
	movzx ebx,bh

	cmp byte [procallsprites_replaygrm],1
	jne .dogrm

	// not in reserve pass, just return most recent result if no conflict
	mov edx,[curspriteblock]
	test byte [edx+spriteblock.flags],2
	jnz .conflict

	mov eax,[esi-13]
	cmp eax,byte -1
	je .noresult
	mov [ebp],eax
.noresult:
	ret

.conflict:
	or edi,byte -1
	ret

.dogrm:
	or dword [esi-13],byte -1
	push ebp
	push esi
	jmp [.specialaction+eax*4]

noglobal vard .specialaction
	dd addr(.reserve),addr(.allocate),addr(.check),addr(.mark)
	dd addr(.allocnofail),addr(.checknofail),addr(.getonly)
.numspecialactions equ ($-.specialaction)/4
endvar

	// here we have
	// eax=operation
	// ebx=feature
	// ecx=rrrr
	// ebp->where to store the result
	// safe: edx

#define GRFRESGET 1	// find suitable ID
#define GRFRESMARK 2	// mark given/found IDs
#define GRFRESNOFAIL 4	// on error, continue loading, do not mark as conflicting
#define GRFRESREAD 8	// only return GRFID that defines the given ID

#define GRFRESCHECK 0	// check is also done by all of the above

.reserve:
	mov al,GRFRESGET+GRFRESMARK	// find and mark unused entries
	call [grfresource+ebx*4]
	jc .failgrm
	jnz .badres
	pop esi
	pop ebp
	mov [ebp],edx
	mov [esi-13],edx
	ret

.failgrm:
	pop esi
	pop ebp
	mov dh,INVSP_INVRESOURCE
	jmp newcargoid.invalid

.mark:
	mov edx,[ebp]
	mov al,GRFRESMARK
	call [grfresource+ebx*4]	// mark given entries
	jc .failgrm
	jnz .badres
	pop esi
	pop ebp
	ret

.allocate:
	mov al,GRFRESGET		// find unused entries 
	call [grfresource+ebx*4]
	jc .failgrm
	jnz .badres
	pop esi
	pop ebp
	mov [ebp],edx
	mov [esi-13],edx
	ret

.check:
	mov edx,[ebp]
	mov al,GRFRESCHECK		// check given entries
	call [grfresource+ebx*4]
	jc .failgrm
	jz .resok
.badres:
	mov ebp,[curspriteblock]
	or byte [ebp+spriteblock.flags],2
	mov [ebp+spriteblock.errparam],esi
	mov [ebp+spriteblock.errparam+4],dx
	mov [ebp+spriteblock.errparam+6],di
	or edi,byte -1
.resok:
	pop esi
	pop ebp
	ret

.allocnofail:
	mov al,GRFRESGET+GRFRESNOFAIL		// find unused entries 
	call [grfresource+ebx*4]
	jc .failgrm
	pop esi
	pop ebp
	jz .gotres
	or edx,byte -1
.gotres:
	mov [ebp],edx
	mov [esi-13],edx
	ret

.checknofail:
	mov edx,[ebp]
	mov al,GRFRESCHECK+GRFRESNOFAIL		// check given entries
	call [grfresource+ebx*4]
	jc .failgrm
	pop esi
	pop ebp
	jz .checkok
	mov [ebp],edx
	mov [esi-13],edx
.checkok:
	ret

.getonly:
	mov edx,[ebp]
	mov al,GRFRESREAD
	call [grfresource+ebx*4]
	jc .failgrm
	pop esi
	pop ebp
	mov [ebp],edx
	mov [esi-13],edx
	ret

.notothergrf:
	// now ah=op, al->source2, ecx->source1, ebp->target
.get1:
	push ecx
	call .getparam
	pop ecx
	je .zero1
	ja .invalidvar

	mov ecx,[ecx]

.zero1:
	push eax
	call .getparam
	pop ebx
	je .zero2
	ja .invalidvar

	mov ebx,[ebx]

.zero2:
	xchg ecx,eax

	// now ch=op, eax=source1, ebx=source2, ebp->target
	movzx ecx,ch
	call [actiondop+ecx*4]
	mov [ebp],eax
	ret

.getparam:
	push eax
	movzx eax,byte [esp+8]
	cmp al,0x80
	jb .paramsource
	cmp al,0xfe
	jb .varsource
	je .iszero

	mov eax,esi
	jmp short .gotsource

.varsource:
	cmp al,numextvars+0x80
	jae .paramdone

	mov eax,[externalvars+(eax-0x80)*4]
	jmp .gotsource

.paramsource:
	cmp al,[ebx+spriteblock.numparam]
	jb .paramsourcevalid
.iszero:
	xor eax,eax
	jmp short .gotzero

.paramsourcevalid:
	shl eax,2
	add eax,[ebx+spriteblock.paramptr]

.gotsource:
	test esp,esp	// clear ZF if param is valid
.gotzero:
	mov [esp+8],eax
	stc		// and set CF if not invalid action

.paramdone:
	pop eax
	ret

	align 4

var actiondop
	dd addr(.set),addr(.add),addr(.sub),addr(.mul),addr(.imul)
	dd addr(.shlr),addr(.salr),addr(.and),addr(.or)
	dd addr(.div),addr(.idiv),addr(.mod),addr(.imod)

	.numactiondops equ (addr($)-actiondop)/4

.sub:
	neg ebx

.add:
	add eax,ebx

.set:
	ret

.mul:
	mul ebx
	ret

.imul:
	imul eax,ebx
	ret

.shlr:
	mov ecx,ebx
	test ebx,ebx
	js .shr

.shl:
	shl eax,cl
	ret

.shr:
	neg cl
	shr eax,cl
	ret

.salr:
	mov ecx,ebx
	test ebx,ebx
	jns .shl

.sar:
	neg cl
	sar eax,cl
	ret

.and:
	and eax,ebx
	ret

.or:
	or eax,ebx
	ret

.idiv:
	test ebx,ebx
	jz .nozerodiv
	cwd
	idiv ebx
.nozerodiv:
	ret

.imod:
	test ebx,ebx
	jz .nozerodiv
	cwd
	idiv ebx
	mov eax,edx
	ret

.div:
	test ebx,ebx
	jz .nozerodiv
	xor edx,edx
	div ebx
	ret

.mod:
	test ebx,ebx
	jz .nozerodiv
	xor edx,edx
	div ebx
	mov eax,edx
	ret

// get/check/mark grf resources
//
// in:	eax=mask of GRFRESxxx flags (GET/CHECK/MARK)
//	ebx=feature
//	ecx=number of resource entries
// in/out:
//	edx=resource value (in for CHECK and MARK, out for GET, maybe both!)
// out:	CF=1 invalid resource
//	CF=0,ZF=0 resource not available (conflicting resource in edx)
//		for CHECK also esi->spriteblock of conflicting grf
//	CF=0,ZF=1 resource available
// safe:eax ebx ecx ebp esi

grfcalltable grfresource
.gettrains:
.getrvs:
.getships:
.getplanes:
	mov ah,[vehbnum+ebx]

	// we get here with
	//  al: GRFRESxxx mask
	// ebx: feature
	//  ah: total number of entries for this feature
	// ecx: number of entries to check/reserve
.bitsearch:
	mov ebx,[grfresbase+ebx*4]
	cmp ecx,0x7f
	ja near .fail	// more wouldn't work at the moment

	mov esi,ebx
	xchg ah,cl	// now esi=base ID, ecx=total IDs, ah=number we want
	test al,GRFRESGET
	jz .notvehget
	xor edx,edx	// start with first ID, see if it's available
.notvehget:
	sub ecx,edx	// now ecx=IDs available after edx
	cmp ah,cl
	jg .fail	// trying to allocate more vehicles that in the class
	add esi,edx	// now esi=actual bit number to test
	test al,GRFRESREAD
	jz .checknextidrange

	mov edx,[grfresources+esi*4]
	test al,0
	ret

.checknextidrange:
	push eax
.checknextvehid:
	cmp dword [grfresources+esi*4],0
	jne .vehidnotavail
	inc esi
	dec ah
	jz .gotidrange
	loop .checknextvehid

	// found no large enough available range
	pop eax
	mov edx,esi
	mov esi,[grfresources+esi*4]
	test esp,esp
	ret

.vehidnotavail:		// vehicle in range was not available
	pop eax
	test al,GRFRESGET	// if we're getting, try again with the next one
	jz .failwithptr		// else we're in bad shape

	inc esi
	mov edx,esi
	sub edx,ebx		// now edx=ID within class
	loop .checknextidrange

	dec esi

.failwithptr:
	mov edx,esi
	mov esi,[grfresources+esi*4]
	test esp,esp
	ret

.gotidrange:
	// if we get here, the range was ok
	pop eax
	test al,GRFRESMARK
	jz .done

	// mark range
	lea esi,[ebx+edx]
	movzx ecx,ah
	mov eax,[curspriteblock]
.marknextvehid:
	mov [grfresources+esi*4],eax
	inc esi
	loop .marknextvehid
	test al,0
	ret

.getindustries:
	mov ah,NINDUSTRIES
	jmp .bitsearch

.getcargos:
	test al,GRFRESGET
	jnz .fail

	mov ah,32+32
	jmp .bitsearch

.getstations:
.getcanals:
.getbridges:
.gethouses:
.getindustiles:
.getsounds:
.getairports:
.fail:
	stc
	ret

.getgeneric:	// mark sprite as used
	mov esi,[numactsprites]
	test al,GRFRESGET
	jz .notgenget
	mov edx,esi
.notgenget:
	cmp edx,esi
	jne .fail
	add esi,ecx
	cmp esi,0x4000
	jae .failsprites
	test al,GRFRESMARK
	jz .done
	cmp dword [procall_type],PROCALL_TEST
	je .dontallocsprites
	mov [numactsprites],esi
.dontallocsprites:
	mov esi,[curspriteblock]
	or byte [esi+spriteblock.flags],4
	mov [curextragrm+GRM_EXTRA_SPRITES*4],esi

.done:
	test al,0
	ret

.failsprites:
	mov edx,GRM_EXTRA_SPRITES
	mov esi,[lastextragrm+GRM_EXTRA_SPRITES*4]	// return whatever grf last allocated sprites as source of conflict
	test esp,esp
	ret


	// *** action E handler ***
actione:
	// Four extra bytes in front of this sprite data are used this way:
	// - unused
deactivategrfs:
	// 0E <num> <grfids...>
	xchg eax,ecx
.deactnext:
	lodsd
	cmp eax,[edx+spriteblock.grfid]
	jne .notthis

	// same grf as current file -> force-activate current file

	test byte [edx+spriteblock.active],2
	jz .bad
	or byte [edx+spriteblock.active],1
	jmp short .donethis

.notthis:
	call findgrfid
	jc .donethis

	mov al,[ebx+spriteblock.active]
	and al,3
	cmp al,1
.bad:
	mov al,INVSP_ALREADYACT
	je checknewgraphicsblock.invalid

	and byte [ebx+spriteblock.active],~1

.donethis:
	loop .deactnext
	ret


	// *** action F handler ***

uvard firsttownnamestyle	// first final style; others are linked via .nextstyle
uvard lasttownnamestyle

uvard defaultstylename
actionf:
	// Four extra bytes in front of this sprite data are used this way:
	// - unused

uvard currtownstylename
newtownnameparts:
	testflags newtownnames
	jc .loadit
	ret

.loadit:
	push edi
	mov ebp,eax

// first of all, process style name data if this is a final definition
// we can't use action4 to set style names since we need these texts even
// if the according grf isn't activated

	and dword [currtownstylename],0
	test al,0x80
	jz .noname
	jmp short .skipcheck

.stylenameloop:
	lodsb
	or al,al
	jz .endofnames
	dec esi		// checklanguage wants to lodsb too
.skipcheck:
	call checklanguage
	jnc .notthis
	mov [currtownstylename],esi	// yes, store offset in temp. var
.notthis:
	or ecx,byte -1			// then skip name
	xor al,al
	xchg esi,edi
	repnz scasb
	xchg esi,edi
	jmp short .stylenameloop

.endofnames:
.noname:
	xor eax,eax			// get numparts
	lodsb
	mov ecx,eax
	xor edi,edi

.nameloop:
	push ecx
	or ecx,ecx
	mov ah,INVSP_INVPARTS
	jz near .bad	// error if ecx is zero (this can happen only in the first round)
	xor eax,eax	// get numtexts (needed for the memory size)
	lodsb
	mov ecx,eax

// Allocate memory for the new item
	lea eax,[namepartlist.nameparts+eax*8]
	push eax
	call malloc
	pop eax
	jc near .nomemory

// now:	ecx = numtexts
//	edi = previous item of the link or zero in the first loop
//	eax -> current item
// in the first loop (if edi=0)
//	ebp = ID (bit 7 still set)

	or edi,edi
	jz .firstone
	mov dword [edi+namepartlist.next],eax	// link it to the list of the style
	jmp short .addressstored

.firstone:
	mov ebx,ebp
	and bl,0x7f
	mov [curgrftownnames+ebx*4],eax		// first item of the style - store offset
						// for later reference
	btr ebp,7
	jnc .notroot

// We get here if this is the first item of the style and ID has its bit 7 set
// (should be displayed in the options window)
// Set some variables that need to be valid in final elements and link the new one
// to the list of final styles
	mov ebx,[edx+spriteblock.grfid]		// set GRFID
	mov [eax+namepartlist.grfid],ebx
	mov ebx,ebp				// set setid
	mov [eax+namepartlist.setid],bl
	and dword [eax+namepartlist.nextstyle],0
	mov ebx,[currtownstylename]		// set name
	mov [eax+namepartlist.name],ebx

	mov edi,[lasttownnamestyle]
	or edi,edi
	jnz .notfirststyle

// this is the first final style - store its offset in the head
	mov [firsttownnamestyle],eax
	jmp short .setlast

.notfirststyle:
// not the first final style - put a link to this to the previous one
	mov [edi+namepartlist.nextstyle],eax

.setlast:
	mov [lasttownnamestyle],eax

.notroot:
.addressstored:
	mov edi,eax				// now edi points to the new item
	lodsb					// store first bit and bit count
	cmp al,32
	mov ah,INVSP_INVBIT
	jae .bad
	mov [edi+namepartlist.bitstart],al
	lodsb
	cmp al,32
	ja .bad
	mov [edi+namepartlist.bitcount],al
	
	xor ebx,ebx
	xor ebp,ebp
// now process all name part texts
// in the loop, ebp contains the sum of probablities so far
.partloop:
	xor eax,eax		// get probablity
	lodsb
	add ebp,eax		// and add it to the counter 
				// (bit 7 is added as well, we'll fix this later)
	mov [edi+namepartlist.nameparts+ebx*8+namepart.probablity],al
	or al,al
	js .otherid

// this is a plain name - store its pointer ...
	mov [edi+namepartlist.nameparts+ebx*8+namepart.ptr],esi

// ... and skip it
	xor al,al
	xchg esi,edi
.skipname:
	scasb
	jne .skipname
	xchg esi,edi
	jmp short .nextpart

.otherid:
// this is an ID for another part, store the offset to the other item
	add ebp,byte -0x80	// fix that we added bit 7 unnecessarily
	xor eax,eax
	lodsb
	mov eax,[curgrftownnames+eax*4]
	or eax,eax
	jz .badid		// this ID wasn't defined yet
	mov [edi+namepartlist.nameparts+ebx*8+namepart.ptr],eax

.nextpart:
	inc ebx
	cmp ebx,ecx
	jb .partloop

	mov [edi+namepartlist.maxprob],bp	// store the multiplier
	pop ecx
	dec ecx
	or ecx,ecx
	jnz near .nameloop

	and dword [edi+namepartlist.next],0	// close the linked list in the last item
	pop edi
	ret

.badid:
	mov ah,INVSP_BADID

.bad:
	shl eax,8
	mov ax,ourtext(invalidsprite)
	jmp short .seterror

.nomemory:
	mov ax,ourtext(outofmemory)
.seterror:
	pop ecx
	pop edi
	call setspriteerror
	or edi,byte -1
	ret


	// *** action 10 handler ***
action10:
	// Four extra bytes in front of this sprite data are used this way:
	// - unused

	// nothing to do here, all handled by action 7


	// *** action 11 handler ***
action11:

initgrfsounds:
	cmp dword [edx+spriteblock.soundinfo],0
	je .first
	mov dl,INVSP_MULTIACT11
.bad:
	jmp newcargoid.invalid

.first:
	mov ah,[esi]
	lea ecx,[edi+eax]
	cmp cx,[edx+spriteblock.numsprites]
	jbe .sizeok

	mov dl,INVSP_BLOCKTOOLARGE
	jmp .bad

.sizeok:
	inc esi

	mov [edx+spriteblock.numsounds],ax

	imul esi,eax,soundinfo_size
	push esi
	call malloc
	pop esi
	mov [edx+spriteblock.soundinfo],esi

	mov ecx,eax
.next:
	mov ebx,[edx+spriteblock.spritelist]
	mov ebp,[ebx+edi*4]
	inc edi
	cmp byte [ebp],0xfe	// FE=import from other grf, FF=binary data
	ja .isbinary
	jb .notbinary

	or byte [edx+spriteblock.flags],8
	mov [esi+soundinfo.dataptr],ebp
	movzx eax,byte [ebp+1]	// code 00 = import, others not defined yet
	inc eax
	neg eax			// store -(code+1) so that length is negative
	mov [esi+soundinfo.length],eax

	// data long enough?
	cmp dword [ebp-4],8
	jae .imported

	mov esi,ebp
	add esi,[ebp-4]		// to give correct offset in error message
	mov dl,INVSP_OUTOFDATA
	jmp .bad

.notbinary:
	mov esi,ebp
	mov dl,INVSP_NOTBININC
	jmp .bad

.isbinary:
	mov ebx,[ebp-4]
	movzx eax,byte [ebp+1]	// filename length
	add ebp,2		// skip the FF and length bytes
	mov [esi+soundinfo.filename],ebp
	lea ebp,[ebp+eax+1]	// skip the filename and 00
	sub ebx,eax
	sub ebx,3
	mov [esi+soundinfo.dataptr],ebp
	mov [esi+soundinfo.length],ebx

#if !WINTTDX
	push ebp
	push ebx
	call MassageSoundData
#endif

//fill in some useful defaults
.imported:
	mov byte [esi+soundinfo.priority],'0'
	mov byte [esi+soundinfo.ampl],0x80
	add esi,soundinfo_size
	loop .next
	ret

skipgrfsounds:
	mov ah,[esi]
	add edi,eax
	btr dword [edx+spriteblock.flags],3
	jc .import
	ret

		// need to import some sounds from another grf file
.import:	// this is done (and works only) once
	mov esi,[edx+spriteblock.soundinfo]
	movzx ecx,word [edx+spriteblock.numsounds]
.next:
	cmp dword [esi+soundinfo.length],byte -1	// was code 00
	jne .notthis

	xor ebp,ebp
	mov [esi+soundinfo.length],ebp		// initialize both to zero
	xchg ebp,[esi+soundinfo.dataptr]	// (if sound can't be found)

	mov eax,[ebp+2]			// GRFID
	call findgrfid
	jc .notthis			// can't find GRFID

	movzx eax,word [ebp+6]		// sound number
	cmp ax,[ebx+spriteblock.numsounds]
	jae .notthis			// invalid number

	imul eax,soundinfo_size
	add eax,[ebx+spriteblock.soundinfo]

	mov ebx,[eax+soundinfo.dataptr]
	mov eax,[eax+soundinfo.length]

	mov [esi+soundinfo.dataptr],ebx
	mov [esi+soundinfo.length],eax

.notthis:
	add esi,soundinfo_size
	loop .next
	ret


	// Action 12 handler
action12:

loadcharset:
	mov ebp,eax		// <num-def>

.nextset:
	push ebp
	xor eax,eax
	lodsb			// <font>
	cmp al,3
	jae near .badfont
	mov ebx,eax
	lodsb			// <num-char>
	mov ecx,eax
	add ax,di
	cmp ax,[edx+spriteblock.numsprites]
	ja .toomany

	lodsw			// <base-char>
	mov ebp,eax
	movzx eax,ah
	call allocfonttable
	shl ebx,8	// 256 tables per font
	mov ebx,[eax+ebx*4]

	mov eax,ebp
	and eax,0x7f
	dec ecx
	jl .badblock	// defining 0 characters?
	add al,cl
	jc .badblock	// crossed 256-byte boundary (very bad)
	js .badblock	// crossed 128-byte boundary (against specs)
	inc ecx

	// now ebx->fontinfo ebp=base-char ecx=num-char

	push ecx
	call insertactivespriteblock
	pop ecx
	cmp edi,byte -1
	je .bail
	and ebp,0xff

.nextchar:
	mov [ebx+ebp*fontinfo_size+fontinfo.sprite],ax
	inc eax
	inc ebp
	loop .nextchar

	pop ebp
	dec ebp
	jnz .nextset
	ret

.bail:
	pop eax
	ret

.toomany:
	mov dl,INVSP_BLOCKTOOLARGE
	jmp short .bad
.badfont:
	mov dl,INVSP_BADFONT
.bad:
	pop eax
	jnb newcargoid.invalid
.badblock:
	mov dl,INVSP_NOTINBLOCK
	jmp .bad

skipcharset:
	mov byte [hasaction12],1
	mov ecx,eax
.nextset:
	inc esi		// skip <font>
	lodsb		// <num-char>
	add edi,eax
	inc esi		// skip <base-char>
	inc esi		// (two bytes)
	loop .nextset
	ret



//
// Action 0 property info
//


// sizes of each entry in the vehicle specific data tables
// format: total, sizes...
// total is the sum of all sizes in the list, anything beyond that
// is handled by the vehicle specific subroutine.
// this should be probably moved to vars.ah, eventually

%push defveh	// so we don't need to undef all these temporary identifiers

%define %$d_U 0		// unused/undefined/invalid
%define %$d_B 1		// a byte
%define %$d_W 2,0	// a word
%define %$d_T 0x82,0	// a text id
%define %$d_D 4,0,0,0	// a dword
%define %$d_P 0x84,0,0,0 //a pointer, relative to the data segment (for WINTTDX)
%define %$d_F 0x80	// call special handler function
%define %$d_H 0x40	// call special handler function with untranslated offset (for features like newstations and newhouses that translate offsets)
%define %$d_w 2		// a word for special properties
%define %$d_t 0x82	// a text id for special properties
%define %$d_d 4		// a dword for special properties

%define %$s_U 1
%define %$s_B 1
%define %$s_W 2
%define %$s_T 2
%define %$s_D 4
%define %$s_P 4
%define %$s_F 1
%define %$s_H 1
%define %$s_w 1
%define %$s_t 1
%define %$s_d 1

%macro defvehdata 1-*.nolist	// params: name,arraysizes...
	var %1
	%assign %$totalsize 0
	%rotate 1
	%rep %0-1
		%assign %$totalsize %$totalsize+%$s_ %+ %1
		%rotate 1
	%endrep
	db %$totalsize
	%rotate 1
	%rep %0-1
		db %$d_%1
		%rotate 1
	%endrep
	%1_totalsize equ %$totalsize
%endmacro

defvehdata gendata, W,B,B,B,B,B				// 00..06

defvehdata spectraindata, B,W,W,B,P,B,B,B,B,B,B,B	// 08..18
defvehdata spcltraindata, B,F,w,B,d,B,B,B,B,B,B,B,B,B,B,w,w	// 19..29

defvehdata specrvdata, B,B,P,B,B,B,B,B			// 08..12
defvehdata spclrvdata, B,B,B,d,B,B,B,B,B,B,w,w		// 13..1E

defvehdata specshipdata, B,B,B,B,B,W,B,B		// 08..10
defvehdata spclshipdata, d,B,B,B,B,B,B,w,w		// 11..19

defvehdata specplanedata, B,B,B,B,B,B,B,W,B,B		// 08..12
defvehdata spclplanedata, d,B,B,B,B,w,w			// 13..19

defvehdata specstationdata				// no properties
defvehdata spclstationdata, F,H,F,B,B,B,F,F,w,B,F,B,B,B,w,B,w	// 08..18

defvehdata specbridgedata, B,B,B,B			// 08..0B
defvehdata spclbridgedata, w,F,B			// 0C..0E

defvehdata spechousedata
defvehdata spclhousedata, F,F,w,B,B,B,B,B,w,B,t,w,B,F,B,d,B,B,B,B,F,B,d	// 08..1e

defvehdata specglobaldata
defvehdata spclglobaldata, B,F,t,d,w,d,d,w,F		// 08..10
		

defvehdata specindustiledata
defvehdata spclindustiledata, F,F,F,F,F,B,B,w,B,B,B	// 08..12

defvehdata specindustrydata
defvehdata spclindustrydata, F,H,F, B,t,t,t,B,F,F,B,B,B	,F,F,B,B,F,d,t, d,d,d,t,d,B,B,D		// 08..23

defvehdata speccargodata
defvehdata spclcargodata, F,t,t,t,t,t,w,B,B,B,F,F,F,F,F,d,B,w,B	// 08..1a

defvehdata specsounddata
defvehdata spclsounddata, F,F,F				// 08..0A

defvehdata specairportdata
defvehdata spclairportdata, F,F,B,B,B,B,t			// 08..0d

%undef defvehdata

%pop

global specvehdatalength
specvehdatalength equ \
 totalvehtypes*vehtypeinfo_size + \
 NTRAINTYPES*spectraindata_totalsize + \
 NROADVEHTYPES*specrvdata_totalsize + \
 NSHIPTYPES*specshipdata_totalsize + \
 NAIRCRAFTTYPES*specplanedata_totalsize


uvarb spriteand
uvard spritebase

uvard numactivesprites
uvard lastnonoverride
uvarb grfstage

// Actions for which we don't need to check that the GRFID is valid
// so far that's actions 6-9, B-E and 10
spriteactnogrfid equ 10111101111000000b

	// pointers to the actions specified in the first byte of
	// the pseudo sprite data

global numspriteactions,spritegrfidcheckofs

	align 4

	// what to do when initializing .grf the first time
var spriteinitializeaction
	dd addr(processnewinfo)		// 0: new vehicle data
	dd addr(newspriteblock)		// 1: sprite block
	dd addr(newcargoid)		// 2: cargo ID
	dd addr(initializevehcargomap)	// 3: veh ID->cargo ID mapping
	dd addr(initnewvehnames)	// 4: new veh name
	dd addr(checknewgraphicsblock)	// 5: non-veh sprite block
	dd addr(applyparam)		// 6: apply parameter
	dd 0				// 7: skip sprites if condition true
	dd addr(recordgrfid)		// 8: grf ID
	dd skipspriteif			// 9: skip sprites even during init
	dd addr(replacettdspriteskip)	// A: replace TTD's sprites
	dd addr(grferrormsg)		// B: generate error message
	dd 0				// C: NOP
	dd addr(setparam)		// D: Set GRF parameter
	dd 0				// E: deactivate other GRFs
	dd addr(newtownnameparts)	// F: specify new town name styles
	dd 0				//10: define label
	dd addr(initgrfsounds)		//11: define sounds
	dd skipcharset			//12: define glyphs

numspriteactions equ (addr($)-spriteinitializeaction)/4
spritegrfidcheckofs equ numspriteactions*4

	dd spriteactnogrfid

	// what to do when activating .grf file
var spriteactivateaction
	dd addr(processnewinfo)		// 0: new vehicle data
	dd addr(activatevehspriteblock)	// 1: sprite block
	dd addr(activatecargoid)	// 2: cargo ID
	dd addr(setvehcargomap)		// 3: veh ID->cargo ID mapping
	dd addr(applynewvehnames)	// 4: new veh name
	dd addr(activatenewgraphics)	// 5: non-veh sprite block
	dd addr(applyparam)		// 6: apply parameter
	dd addr(skipspriteif)		// 7: skip sprites if condition true
	dd addr(grfidactivate)		// 8: grf ID
	dd addr(skipspriteif)		// 9: skip sprites even during init
	dd addr(replacettdsprite)	// A: replace TTD's sprites
	dd addr(grferrormsg)		// B: generate error message
	dd 0				// C: NOP
	dd addr(setparam)		// D: Set GRF parameter
	dd addr(deactivategrfs)		// E: deactivate other GRFs
	dd 0				// F: specify new town name styles
	dd 0				//10: define label
	dd addr(skipgrfsounds)		//11: define sounds
	dd loadcharset			//12: define glyphs

	dd spriteactnogrfid



	// what to do when checking whether .grf file will activate
var spritetestactaction
	dd 0				// 0: new vehicle data
	dd addr(skipvehspriteblock)	// 1: sprite block
	dd 0				// 2: cargo ID
	dd 0				// 3: veh ID->cargo ID mapping
	dd 0				// 4: new veh name
	dd addr(skipnewgraphicsblock)	// 5: non-veh sprite block
	dd addr(applyparam)		// 6: apply parameter
	dd addr(skipspriteif)		// 7: skip sprites if condition true
	dd addr(grfidactivate)		// 8: grf ID
	dd addr(skipspriteif)		// 9: skip sprites even during init
	dd addr(replacettdspriteskip)	// A: replace TTD's sprites
	dd addr(checkgrferrormsg)	// B: generate error message
	dd 0				// C: NOP
	dd addr(setparam)		// D: Set GRF parameter
	dd addr(deactivategrfs)		// E: deactivate other GRFs
	dd 0				// F: specify new town name styles
	dd 0				//10: define label
	dd addr(skipgrfsounds)		//11: define sounds
	dd skipcharset			//12: define glyphs

	dd spriteactnogrfid



	// what to do after loading a .grf file
var spritesloadedaction
	dd 0				// 0: new vehicle data
	dd addr(skipvehspriteblock)	// 1: sprite block
	dd 0				// 2: cargo ID
	dd 0				// 3: veh ID->cargo ID mapping
	dd 0				// 4: new veh name
	dd addr(skipnewgraphicsblock)	// 5: non-veh sprite block
	dd 0				// 6: apply parameter
	dd initaction7			// 7: skip sprites if condition true
	dd 0				// 8: grf ID
	dd initaction9			// 9: skip sprites even during init
	dd addr(replacettdspriteskip)	// A: replace TTD's sprites
	dd 0				// B: generate error message
	dd 0				// C: NOP
	dd 0				// D: Set GRF parameter
	dd 0				// E: deactivate other GRFs
	dd 0				// F: specify new town name styles
	dd 0				//10: define label
	dd addr(skipgrfsounds)		//11: define sounds
	dd skipcharset			//12: define glyphs

	dd -1				// never check for valid GRFID


	// everything that needs to happen before grfs are really activated
	// that's GRM and cargo action 0
var spritereserveaction
	dd addr(action0cargo)		// 0: new vehicle data
	dd addr(skipvehspriteblock)	// 1: sprite block
	dd 0				// 2: cargo ID
	dd 0				// 3: veh ID->cargo ID mapping
	dd 0				// 4: new veh name
	dd addr(skipnewgraphicsblock)	// 5: non-veh sprite block
	dd addr(applyparam)		// 6: apply parameter
	dd addr(skipspriteif)		// 7: skip sprites if condition true
	dd addr(grfidactivate)		// 8: grf ID
	dd addr(skipspriteif)		// 9: skip sprites even during init
	dd addr(replacettdspriteskip)	// A: replace TTD's sprites
	dd addr(checkgrferrormsg)	// B: generate error message
	dd 0				// C: NOP
	dd addr(setparam)		// D: Set GRF parameter
	dd addr(deactivategrfs)		// E: deactivate other GRFs
	dd 0				// F: specify new town name styles
	dd 0				//10: define label
	dd addr(skipgrfsounds)		//11: define sounds
	dd skipcharset			//12: define glyphs

	dd -1				// never check for valid GRFID

%ifndef PREPROCESSONLY
%if (numspriteactions+1 <> (addr($)-spritereserveaction)/4) ||  (numspriteactions+1 <> (spritereserveaction-spritesloadedaction)/4) || (numspriteactions+1 <> (spritetestactaction-spriteactivateaction)/4) || (numspriteactions+1 <> (spritesloadedaction-spritetestactaction)/4)
	%error "Inconsistent number of sprite actions"
%endif
%endif

uvard callback_extrainfo

var externalvars		// for variational cargo IDs and action 7/9/D
	dd currentdate		// 00	80 (first number var.cargoID;
	dd currentyear		// 01	81  second number action 7/9/D param-num)
	dd currentmonth		// 02	82
	dd climate		// 03	83
	dd grfstage		// 04	84
	dd patchflagsfixed	// 05	85
	dd roadtrafficside	// 06	86
	dd 0			// 07	87 (unused)
	dd spriteblockptr	// n/a	88 (slightly hackish)
	dd datefract		// 09	89
	dd animcounter		// 0A	8A
	dd ttdpatchvercode	// 0B	8B
	dd curcallback		// 0C	8C (for various callbacks)
	dd ttdversion		// 0D	8D 00=DOS, 01=Windows, 02=Linux
	dd trainspritemove	// 0E	8E
	dd costrailmul		// 0F	8F
	dd miscgrfvar		// 10	90
	var curtooltracktypeptr, dd 0	// 11	91
	dd gamemode		// 12	92
	dd refreshrectxleft	// 13	93
	dd refreshrectxright	// 14	94
	dd refreshrectyup	// 15	95
	dd refreshrectydown	// 16	96
	dd temp_snowline	// 17	97
	dd callback_extrainfo	// 18	98 (callbacks can give extra info to the grf via this variable and/or var. 10)
	dd globalidoffset	// 19	99
	dd alwaysminusone	// 1A	9A (a dword always being all-ones to make GRF coders' lives easier)
	dd displayoptions	// 1B	9B
	dd lastcalcresult	// 1C	9C
	dd ttdplatform		// 1D	9D
	dd grfmodflags		// 1E   9E
	dd languagesettings	// 1F	9F
	dd snowline		// 20	A0

global numextvars
numextvars equ (addr($)-externalvars)/4

uvard alwaysminusone,1,s

	// first entry in grf resource list for each feature
	// must be synchronized with NGRFRESOURCES and grfresources below
	// -1 = no resources defined yet, -2 = has special handler
var grfresbase, dd GRM_TRAINS,GRM_RVS,GRM_SHIPS,GRM_PLANES
	dd -1, -1, -1, -1		// stations, canals, bridges houses
	dd -2, -1,GRM_INDUSTRIES	// sprites, industiles, industries,
	dd GRM_CARGOS,-1,-1		// cargos, sounds, airports
checkfeaturesize grfresbase, 4
	// next one starts with 357

	// the following variables need to be close in memory
var vehbase, db TRAINBASE,ROADVEHBASE,SHIPBASE,AIRCRAFTBASE,0,0,0,0,0,0,0,0,0,0
checkfeaturesize vehbase, 1

var vehbnum, db NTRAINTYPES,NROADVEHTYPES,NSHIPTYPES,NAIRCRAFTTYPES
	db 255,255,NBRIDGES,255		// stations,canals,bridges,houses
	db 255,255,NINDUSTRIES,32	// generic,industiles,industries,cargos
	db 0,NUMNEWAIRPORTS		// sounds
checkfeaturesize vehbnum, 1

	// for action 0, where are the regular vehicle specific properies listed
var specificpropertylist, dd spectraindata,specrvdata,specshipdata,specplanedata,specstationdata, 0, specbridgedata
			dd spechousedata,specglobaldata,specindustiledata,specindustrydata,speccargodata,specsounddata
			dd specairportdata
checkfeaturesize specificpropertylist, 4

	// for action 0, where the data for each vehicle class starts
	// (set by patching functions)
var specificpropertybase, times NUMFEATURES dd -1
checkfeaturesize specificpropertybase, 4

	// and how much these are offset from the sprite bases
var specificpropertyofs, db -10,-6,0,0

	// special vehicle properties stored in newvehdatastruc (or with handler func)
var specialpropertybase, dd newtrainvehdata,newrvvehdata,newshipvehdata,newplanevehdata
	dd newstationdata, 0, bridgedata, housedata, globaldata, industiledata, industrydata, cargodata, sounddata
	dd airportdata
checkfeaturesize specialpropertybase, 4

	// for those features that need ID translation, put the table here
var action0transtable, dd 0,0,0,0,curgrfstationlist,0,0,curgrfhouselist,
		       dd 0, curgrfindustilelist, curgrfindustrylist,0,0, curgrfairportlist
checkfeaturesize action0transtable, 4

	// pointers to the data for each of the special properties
var newtrainvehdata
	dd traintractiontype,addr(shuffletrainveh),trainwagonpower // 19,1A,1B
	dd trainrefitcost,newtrainrefit,traincallbackflags	// 1C,1D,1E
	dd traintecoeff,trainc2coeff,trainvehlength		// 1F,20,21
	dd trainviseffect,trainwagonpowerweight,railvehhighwt	// 22,23,24
	dd trainuserbits,trainphase2dec,trainmiscflags		// 25,26,27
	dd traincargoclasses,trainnotcargoclasses		// 28,29

var newrvvehdata
	dd rvpowers, rvweight, rvhspeed, newrvrefit		// 13,14,15,16
	dd rvcallbackflags, rvtecoeff, rvc2coeff, rvrefitcost	// 17,18,19,1A
	dd rvphase2dec,rvmiscflags,rvcargoclasses		// 1B,1C,1D
	dd rvnotcargoclasses					// 1E

var newshipvehdata
	dd newshiprefit, shipcallbackflags, shiprefitcost	// 11,12,13
	dd oceanspeedfract, canalspeedfract, shipphase2dec	// 14,15,16
	dd shipmiscflags,shipcargoclasses,shipnotcargoclasses	// 17,18,19

var newplanevehdata
	dd newplanerefit, planecallbackflags, planerefitcost	// 13,14,15
	dd planephase2dec,planemiscflags,planecargoclasses	// 16,17,18
	dd planenotcargoclasses					// 19

var newstationdata
	dd addr(setstationclass),addr(setstationspritelayout)	// 08,09
	dd addr(copystationspritelayout),stationcallbackflags	// 0A,0B
	dd disallowedplatforms,disallowedlengths		// 0C,0D
	dd addr(setstationlayout),addr(copystationlayout)	// 0E,0F
	dd stationcargolots,stationpylons,setstatcargotriggers	// 10,11,12
	dd stationflags,stationnowires,cantrainenterstattile	// 13,14,15
	dd stationanimdata,stationanimspeeds			// 16,17
	dd stationanimtriggers					// 18

var bridgedata	// (prop 0C is set in patches.ah)
	dd 0, addr(alterbridgespritetable), bridgeflags		// 0C..0E

var housedata
	dd addr(setsubstbuilding)				// 08
	dd addr(sethouseflags)					// 09
	dd newhouseyears+2*128					// 0a
	dd newhousepopulations+128				// 0b
	dd newhousemailprods+128				// 0c
	dd newhousepassaccept+128				// 0d
	dd newhousemailaccept+128				// 0e
	dd newhousefoodorgoodsaccept+128			// 0f
	dd newhouseremoveratings+2*128				// 10
	dd newhouseremovemultipliers+128			// 11
	dd newhousenames+2*128					// 12
	dd newhouseavailmasks+2*128				// 13
	dd housecallbackflags					// 14
	dd addr(sethouseoverride)				// 15
	dd houseprocessintervals				// 16
	dd housecolors						// 17
	dd houseprobabs						// 18
	dd houseextraflags					// 19
	dd houseanimframes					// 1a
	dd houseanimspeeds					// 1b
	dd addr(sethouseclass)					// 1c
	dd housecallbackflags2					// 1d
	dd houseaccepttypes					// 1e
	
var globaldata
	dd basecostmult,addr(setcargotranstbl)			// 08..09
	dd currtextlist,currmultis,curropts,currsymsbefore	// 0A..0D
	dd currsymsafter,eurointr,setsnowlinetable		// 0E..10

var industiledata
	dd addr(setsubstindustile),addr(setindustileoverride)	// 08..09
	times 3 dd setindustileaccepts				// 0a..0c
	dd industilelandshapeflags,industilecallbackflags	// 0d..0e
	dd industileanimframes,industileanimspeeds		// 0f..10
	dd industileanimtriggers,industilespecflags		// 11..12

var industrydata
	dd addr(setsubstindustry),addr(setindustryoverride)	// 08..09
	dd addr(setindustrylayout)				// 0a
	dd industryproductionflags-1				// 0b
	dd industryclosuremsgs-2				// 0c
	dd industryprodincmsgs-2				// 0d
	dd industryproddecmsgs-2				// 0e
	dd industryfundcostmultis-1				// 0f
	dd setinduproducedcargos				// 10
	dd setindustryacceptedcargos				// 11
	dd industryprod1rates-1					// 12
	dd industryprod2rates-1					// 13
	dd industrymindistramounts-1				// 14
	dd addr(setindustrysoundeffects),addr(setconflindustry)	// 15..16
	dd initialindustryprobs-1,ingameindustryprobs-1		// 17..18
	dd addr(setindustrymapcolors),industryspecialflags-4	// 19..1a
	dd industrycreationmsgs-2				// 1b
	dd industryinputmultipliers-4				// 1c
	dd (industryinputmultipliers+NINDUSTRIES*4)-4		// 1d
	dd (industryinputmultipliers+2*NINDUSTRIES*4)-4		// 1e
	dd industrynames-2					// 1f
	dd fundchances-4					// 20
	dd industrycallbackflags-1				// 21
	dd industrycallbackflags2-1				// 22
	dd industrydestroymultis-4				// 23

var cargodata
	dd addr(setcargobit),newcargotypenames,newcargounitnames	//08..0a
	dd newcargoamount1names,newcargoamountnnames			//0b..0c
	dd newcargoshortnames,newcargoicons,newcargounitweights		//0d..0f
	dd newcargodelaypenaltythresholds1				//10
	dd newcargodelaypenaltythresholds2,addr(setcargopricefactors)	//11..12
	dd addr(setcargocolors),addr(setcargographcolors)		//13..14
	dd addr(setfreighttrainsbit),addr(setcargoclasses)		//15,16
	dd globalcargolabels,cargotowngrowthtype,cargotowngrowthmulti	//17..19
	dd cargocallbackflags						//1a

var sounddata
	dd addr(setsoundvolume),addr(setsoundpriority)			//08..09
	dd addr(overrideoldsound)					//0A

var airportdata
	dd setairportlayout,setairportmovementdata			//08..09
	dd airportstarthangarnodes,airportcallbackflags			//0a..0b
	dd airportspecialflags,airportweight,airporttypenames		//0c..0e

uvard grfvarreinitstart,0
%define SKIPGUARD 1

	// All variables that must be reset when loading graphics again
	// are in this block.  They must all use uvard.
	// (If you need byte/word variables just divide the number by 4/2 and round up)
	//
	// ----------------------------
	//
	// pointer to where the vehicle ID has the cargo IDs specified
	// followed by a pointer to the corresponding sprite block
uvard vehids,256
uvard wagonoverride, (256+4)/4	// "1" for wagons that have override

	// the new station stuff
uvard stationclass,256/4
uvard stsetids,256*stsetid_size/4
uvard newstationnames,256	// station names
uvard stationspritelayout,256	// custom sprite layout
uvard disallowedplatforms,256/4
uvard disallowedlengths,256/4
uvard newstationlayout,256
uvard stationclassesused
uvard newstationclasses,maxstationclasses 	// class names
uvard numstationsinclass,(maxstationclasses+3)/4
uvard stationcallbackflags,256/4
uvard curselclass		// current selections for local player
global curselstation
curselstation equ (curselclass+1)
uvard curselclassid,8/2		// current selections for each player
uvard curselstationid,8/2
uvard stationcargolots,256/2
uvard stationpylons,256/4
uvard stationnowires,256/4
uvard stationflags,256/4
uvard statcargotriggers,256
uvard cantrainenterstattile,256
uvard stationanimtriggers,256/2
uvard bridgeflags,(NBRIDGES+3)/4
uvard trainuserbits,NTRAINTYPES/4
uvard canalfeatureids,6
uvard genericids,NUMFEATURES

uvard industryaction3,NINDUSTRIES
uvard industryspriteblock,NINDUSTRIES
uvard substindustries,(NINDUSTRIES+3)/4

uvard cargoaction3,32

	// other variables
uvard newstationnum
uvard trainspritemove
uvard newgraphicswithgrfid	// bit mask of action 5 sets that were set by grfs with a GRFID
uvard newcustomhousenames,256
uvard cargoclasscargos,16	// bit mask of cargo bits that belong to each class
uvard cargoclass,32/2		// bit mask of cargo classes each cargo belongs to
uvard deftwocolormaps		// sprite numbers for 2nd CC translation tables

	// aggregate resources, which grf last reserved them or is currently using them
uvard lastextragrm,GRM_EXTRA_NUM
uvard curextragrm,GRM_EXTRA_NUM

uvard grfvarreinitgrmstart,0

	// GRF Resource Management variables that must be reinitialized
	// always, except when replaying GRM during final activation

	// list of reserved grf resources, spriteblock ptr that reserved them
	// (see GRM_* values in grfdef.inc)
uvard grfresources,GRM_NUM

	// All variables that are reinitialized even for just checking
	// activation (e.g. clicking on flag in grf status window)

uvard grfvarreinitalwaysstart,0

	// ----------------------------

uvard grfvarreinitend,0

uvard grfvarclearstart,0

	// All variables that must be reset for each .grf file
	// are in this block.  They must all use uvard.
	//
	// ----------------------------
	//

uvard cargoids,256/2
uvard cargoidfeatures,256/4
uvard curgrfstationlist,256/4
uvard lastspriteblocknumsets
uvard curgrfhouselist,256/4
uvard curgrftownnames,128
uvard curgrfindustilelist,256/4
uvard curgrfindustrylist,NINDUSTRIES/4 + 1
uvard globalidoffset
uvard curgrfairportlist,256/4

uvard grfvarclearsigned,0

	// the following variables will be set to -1
	// ----------------------------

uvard laststationid

	// ----------------------------

uvard grfvarclearend,0
%undef SKIPGUARD

global numgrfvarreinitgrm
numgrfvarreinitgrm equ (grfvarreinitend-grfvarreinitgrmstart)/4

global numgrfvarreinitalways
numgrfvarreinitalways equ (grfvarreinitend-grfvarreinitalwaysstart)/4

global numgrfvarreinitzero
numgrfvarreinitzero equ (grfvarclearsigned-grfvarclearstart)/4

global numgrfvarreinitsigned
numgrfvarreinitsigned equ (grfvarclearend-grfvarclearsigned)/4

global numgrfvarreinit
numgrfvarreinit equ (grfvarreinitend-grfvarreinitstart)/4

	// for action 5, where to store the first sprite number
	// (the ones that are -1 are safe to be reused)
var newgraphicsspritebases, dd presignalspritebase,catenaryspritebase,extfoundationspritebase,guispritebase,newwaterspritebase,newonewayarrows,deftwocolormaps,tramtracks,snowytemptreespritebase,newcoastspritebase
var newgraphicsspritenums, dd numsiggraphics,numelrailsprites,extfoundationspritenum,numguisprites,numnewwatersprites,numonewayarrows,-1,numtramtracks,numsnowytemptrees,newcoastspritenum

global numnewgraphicssprites
numnewgraphicssprites equ (newgraphicsspritenums-newgraphicsspritebases)/4
%ifndef PREPROCESSONLY
%if (addr($)-newgraphicsspritenums <> 4*numnewgraphicssprites)
	%error "Inconsistent number of action 5 variables"
%endif
%endif

uvard newgraphicssetsenabled	// bit mask of action 5 sets that are turned on
uvard newgraphicssetsavail	// bit mask of action 5 sets that are available
				// (counting only those with an FFFFFFFF GRFID)

%macro grfswitchpar 1.nolist
	db %1_OFS
%endmacro

var grfswitchparamlist
	grfswitchpar miscmodsflags		// 00
	grfswitchpar expswitches		// 01
	grfswitchpar vehicledatafactor		// 02
	grfswitchpar mctype			// 03
	grfswitchpar planecrashctrl		// 04
	grfswitchpar replaceage			// 05 S
	grfswitchpar multihdspeedup		// 06
	grfswitchpar disastermask		// 07
	grfswitchpar unimaglevmode		// 08
	grfswitchpar newbridgespeedpc		// 09
	grfswitchpar languageid			// 0A
	grfswitchpar startyear			// 0B
	grfswitchpar morebuildoptionsflags	// 0C
	grfswitchpar moresteamsetting		// 0D
	grfswitchpar freightweightfactor	// 0E
	grfswitchpar wagonspeedlimitempty	// 0F
	grfswitchpar planespeedfactor		// 10

%undef grfswitchpar

global numgrfswitchparam
numgrfswitchparam equ addr($)-grfswitchparamlist
uvard grfswitchparam,numgrfswitchparam

// cargo types available in each climate
// for each of the values in the cargotypes list below, that bit is set
// in the variable here
// (new cargos 27 and 28 for moreindustriesperclimate will be set in patches.ah)
var defclimatecargobits, dd 0x7ff,0x1cff,0x1f4ed,0x7fe0005

uvard cargobits		// bit mask of defined cargo bits in current climate

// cargo types for refitting, for all climates
var defcargotypes
	db  0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,27	// Temperate
	times 20 db 0xff
	db  0, 1, 2, 3, 4, 5, 6, 7,28,11,10,12	// Arctic
	times 20 db 0xff
	db  0,16, 2, 3,13, 5, 6, 7,14,15,10,12	// Tropic
	times 20 db 0xff
	db  0,17, 2,18,19,20,21,22,23,24,25,26	// Toyland
	times 20 db 0xff

uvarb cargotypes, 32	// list of cargo bits for each cargo type, FF if unused slot

// and the inverse of the above list
// for each of the above numbers, this specifies the real TTD cargo type,
// i.e. the horizontal position in the above table
var defcargoid, db 0,1,2,3,4,5,6,7,8,9,10,9,11,4,8,9,1,1,3,4,5,6,7,8,9,10,11,11,8,0,0,0

uvarb cargoid, 32	// list of cargo types for each cargo bit, only valid if bit set in cargobits

// patchflags bit numbers for each of the newgrf features
var newgrfflags, db newtrains,newrvs,newships,newplanes,newstations,canals,newbridges,newhouses
	db anyflagset,newindustries,newindustries,newcargos,newsounds,newairports
	times 0x48-(addr($)-newgrfflags) db noflag
	db anyflagset	// feature 0x48 is special, for action 4/gen. textIDs


	dd 0x590000			// marker as valid sprite data
	dd dummygrfid_end-dummygrfid	// sprite length is before sprite data
var dummygrfid	// dummy action 8 so that at least one is in the list
	db 8,THISGRFVERSION	// action,version
	db 0xff,0xff,0,0	// grf-id
	db "Hello" // 0,0			// description, copyright
var dummygrfid_end

var ttdversion, db WINTTDX+2*LINTTDX

uvard tempvard
uvard miscgrfvar	// Misc. use for callbacks
			// WARNING: must be set to 0 after callback is done

global articulatedvehicle
articulatedvehicle equ miscgrfvar

global grfmodflags
uvard grfmodflags

