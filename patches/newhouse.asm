// New house graphics

#include <std.inc>
#include <flags.inc>
#include <proc.inc>
#include <textdef.inc>
#include <house.inc>
#include <human.inc>
#include <town.inc>
#include <grf.inc>
#include <ptrvar.inc>
#include <bitvars.inc>

extern DistributeProducedCargo,actionhandler,addgroundsprite,addrelsprite
extern addsprite,callback_extrainfo,cleartilefn,ctrlkeystate,curcallback
extern curgrfhouselist,curspriteblock,exscurfeature,exsspritelistext
extern extfoundationspritebase,generatesoundeffect,getdesertmap,getnewsprite
extern gettextintableptr,gettileinfo,gettownnametexttable,grffeature,grfstage
extern isrealhumanplayer,istownbigger,miscgrfvar,mostrecentspriteblock
extern newcustomhousenames,patchflags,randomfn
extern randomhouseparttrigger,randomhousetrigger,recordtransppassmail
extern redrawtile
extern townarray2ofst
extern lookuptranslatedcargo,gettileinfoshort,miscmodsflags
extern failpropwithgrfconflict,lastextragrm,curextragrm


// New houses use the same dataid-gameid system as newstations (see there)

// usage of landscape arrays in class 3 with newhouses on:
// L1: periodic processings remaining before activating random triggers 1 and 2
// L2: substitute building type (for new house types) or real building type (for old types)
// L3:	bits 0-5: random triggers activated so far
//	bits 6-7: construction state (as in unpatched TTD)
//	bits 8-15: real building type (for new house types) or zero (meaning it's an old type)
// L5: (for old types 0x04 and 0x05, this field is special, see in Savegame Internals)
//	bits 0-2: construction counter (as in unpatched TTD)
//	bits 3-7: current animation frame
// L6: random bits
// L7: Year of construction. If eternalgame is on, it's adjusted in such a way that the age of
//     the building is still correct

// As you can see above, zero isn't a valid dataid. It isn't a valid gameid either, so we can
// use it to indicate unused slots in arrays.

uvarb lastextrahousedata

struc housegameid
	.grfid:		resd 1
	.setid:		resb 1
	.gameid:	resb 1
			resb 8-$
endstruc

%if housegameid_size <> 8
	%error "The size of housegameid must be 8 bytes!"
%endif

uvard lasthousedataid		// it's a byte really, but saved as dword in the houseid chunk

// Offsets to the original TTD data is copied here so we can access them later
uvard orghouseoffsets,12

// Offsets to the new house arrays in the same order as their original counterparts
// appear in the TTD executable. Needed to simplify updating offsets in vars.ah
// (see patches.ah)
vard newhouseoffsets

dd newhousepartflags
dd newhouseflags
dd newhouseyears
dd newhousepopulations
dd newhousemailprods
dd newhousepassaccept
dd newhousemailaccept
dd newhousefoodorgoodsaccept
dd newhouseremoveratings
dd newhouseremovemultipliers
dd newhousenames
dd newhouseavailmasks

endvar

// Set to 1 while generating the houses of a new town
uvarb newtownconstr

// Bit mask of disabled old buildings
uvard disabledoldhouses,4

global clearnewhousesafeguard
clearnewhousesafeguard:
	and dword [newhousedatablock+newhousedata.safeguard],0
	ret


	//
	// special functions to handle special house properties
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


// Called to set the substitute type for a new house. This function assigns
// the setid to a dataid and a gameid if this is the first usage of the setid
global setsubstbuilding
setsubstbuilding:
.next:
	xor edx,edx
	cmp byte [esi],0xff
	je .turnoff
	mov dl,[curgrfhouselist+ebx]		// Do we have a gameid yet?
	or dl,dl
	jnz near .alreadyhasoffset

	mov dl,[lastextrahousedata]		// No - use the next available ID, if any
	add dl,1
	jnc .foundgameid

.toomany:
	mov al,GRM_EXTRA_HOUSES
	jmp failpropwithgrfconflict

.invalid:
	mov eax,(INVSP_INVPROPVAL<<16)+ourtext(invalidsprite)
	stc
	ret

.turnoff:
	inc esi
	cmp ebx,110		// is this a valid old house ID?
	jae near .loopend
	bts [disabledoldhouses],ebx
	jmp .loopend

.foundgameid:
	cmp byte [grfstage],0
	je .dontrecord
	mov [lastextrahousedata],dl		// and the new last index
.dontrecord:
	mov [curgrfhouselist+ebx],dl		// Record the new gameid
	mov eax,[curspriteblock]
	mov [newhousespriteblock+edx*4],eax
	lodsb
	cmp al,110
	jae .invalid
	mov [substbuilding+edx],al
	call copyhousedata

// Now we try to find this GRFID and setid among the saved IDs. If we find it,
// we can store the gameid to the mapping array, if not, we allocate a new gameid.
	push ecx
	mov eax,[curspriteblock]
	mov eax,[eax+spriteblock.grfid]
	mov edi,housedataidtogameid+8
	movzx ecx,byte [lasthousedataid]
	jecxz .newslot

.findhouseslot:
	cmp [edi+housegameid.grfid],eax
	jne .nextslot

	cmp [edi+housegameid.setid],bl
	je .foundit

.nextslot:
	add edi,8
	loop .findhouseslot

.newslot:
	mov cl,[lasthousedataid]
	add cl,1
	jnc .hasemptyslot

	pop ecx
	jmp .toomany

.hasemptyslot:
	mov [lasthousedataid],cl
	lea edi,[housedataidtogameid+ecx*8]
	mov [edi+housegameid.grfid],eax
	mov [edi+housegameid.setid],bl

.foundit:
	mov [edi+housegameid.gameid],dl
	pop ecx
	jmp short .loopend

.alreadyhasoffset:
// this is not the first setting of prop 8 - just store the subst. building type
	lodsb
	cmp al,110
	jae .invalid
	mov [substbuilding+edx],al
.loopend:
	inc ebx
	dec ecx
	jne near .next

	mov eax,[curspriteblock]
	mov [curextragrm+GRM_EXTRA_HOUSES*4],eax

	clc
	ret

%macro copyprop 3
	mov ebx,[%2]
%ifidn %3,d
	mov ebx,[ebx+eax*4]
	mov [%1+4*(edx+128)],ebx
%elifidn %3,w
	mov bx,[ebx+eax*2]
	mov [%1+2*(edx+128)],bx
%elifidn %3,b
	mov bl,[ebx+eax]
	mov [%1+edx+128],bl
%endif
%endmacro

// function to initialize a new house type in edx with the data of the old type in eax,
// and reset new properties to defaults
copyhousedata:
	push ebx
	movzx eax,al
	movzx edx,dl
	copyprop newhousepartflags,orghouseoffsets,b
	copyprop newhouseflags,orghouseoffsets+0x4,b
	copyprop newhouseyears,orghouseoffsets+0x8,w
	copyprop newhousepopulations,orghouseoffsets+0xc,b
	copyprop newhousemailprods,orghouseoffsets+0x10,b
	copyprop newhousepassaccept,orghouseoffsets+0x14,b
	copyprop newhousemailaccept,orghouseoffsets+0x18,b
	copyprop newhousefoodorgoodsaccept,orghouseoffsets+0x1c,b
	copyprop newhouseremoveratings,orghouseoffsets+0x20,w
	copyprop newhouseremovemultipliers,orghouseoffsets+0x24,b
	copyprop newhousenames,orghouseoffsets+0x28,w
	copyprop newhouseavailmasks,orghouseoffsets+0x2c,w
	pop ebx
	mov byte [housecallbackflags+edx],0
	mov byte [housecallbackflags2+edx],0
	mov byte [houseprocessintervals+edx],0
	mov byte [houseextraflags+edx],0
// Default random colors are red, blue, orange and green (like for the modern office building)
	mov dword [housecolors+edx*4],0x060c0804
	mov byte [houseprobabs+edx],16
	mov byte [houseanimframes+edx],31
	mov byte [houseanimspeeds+edx],2
	and byte [newhouseflags+edx],~0x20	// Flag 0x20 (animated) isn't automatically copied
	and dword [houseclasses+5*edx],0	// clear class info
	mov byte [houseclasses+5*edx+4],0
	or dword [houseaccepttypes+edx*4],byte -1
	mov byte [houseminlifespans+edx],0	// default min. lifespan is 0 years
	and dword [extrahousegraphdataarr+edx*4],0
//	and dword [extrahousegraphdataarr+edx*8+housegraphdata.act3],0
//	and dword [extrahousegraphdataarr+edx*8+housegraphdata.spriteblock],0
	ret

%undef copyprop

// We use prop. 9 to set both baHousePartFlags and baHouseFlags
// The value specified is the same format as baHouseFlags except
// that bit 0 is set for 1x1 buildings, so we can tell whether set
// baHousePartFlags to 8 or 0
global sethouseflags
sethouseflags:
	lodsb
	test al,1
	jz .not1x1
	mov ah,8
	jmp short .foundit

.not1x1:
	test al,4
	jz .not2x1
	mov ah,0xa
	jmp short .foundit

.not2x1:
	test al,8
	jz .not1x2
	mov ah,0xc
	jmp short .foundit

.not1x2:
	test al,0x10
	jz .not2x2
	mov ah,0xf
	jmp short .foundit

.not2x2:
	xor ah,ah

.foundit:
	and al,~1
	mov [newhousepartflags+ebx+128],ah
	mov [newhouseflags+ebx+128],al
	clc
	ret

// Set house override, but only if the given byte is a valid old ID and it isn't overridden yet
global sethouseoverride
sethouseoverride:
	xor eax,eax
	lodsb
	cmp al,110
	ja .error
	cmp byte [houseoverrides+eax],0
	jne .ignore
	mov [houseoverrides+eax],bl
.ignore:
	clc
	ret

.error:
	stc
	ret

// Set the class of the house. We store the GRFID as well, so each GRF has private classes
global sethouseclass
sethouseclass:
	mov eax,[curspriteblock]
	mov eax,[eax+spriteblock.grfid]
	mov [houseclasses+ebx*5],eax
	lodsb
	mov [houseclasses+ebx*5+4],al
	clc
	ret

// Called to reset gameids after loading a game or starting a new one
global clearhousedataids
clearhousedataids:
	mov ecx,256
.loop:
	mov byte [housedataidtogameid+(ecx-1)*8+housegameid.gameid],0
	loop .loop
	ret

// clean up a dataid->gameid mapping (housedataidtogameid or industiledataidtogameid)
// by removing entries that don't have their GRFs activated
// NOTE: this depends on the housegameid and industilegameid structs being identical - if
// any of those change, check all calls to this function and fix them as needed
// in:	ebx->a 256-byte array that will get the dataid mapping (the Nth byte says what the Nth ID changed into)
//	dl: the number of the last valid slot
//	esi-> dataid->gameid mapping
// out:	buffer at ebx filled
//	dl: new number of the last valid slot
// preserves: ebx,ebp
exported cleanuphousedataids
// start with an empty mapping
	xor eax,eax
	mov ecx,256
	mov edi,ebx
	rep stosb

	test dl,dl
	jz .exit	// no IDs defined - the empty mapping is OK

	push ebx

// the first slot is special, it should always be free, so start from slot 1
	add esi,byte housegameid_size
	mov edi,esi
	mov cx,0x0101
	inc ebx

// we're ready to compact the array, leaving out entries currently unused
// no insertions are made, so we can compact in-place
// now esi->"from" slot, edi->"to" slot, cl="from" index, ch="to" index
// ebx->"from" slot in the map

.nextslot:
	cmp byte [esi+housegameid.gameid],0
	je .unused

// the slot is used, copy it to the current "to" slot

	movsd
	movsd
	mov [ebx],ch		// remember where the ID goes in the mapping
	inc ch
	jmp short .doneslot

.unused:
// unused slot, skip over it
	add esi,byte housegameid_size
	// leve the default 0 mapping, meaning that it must be reverted to its substitute

.doneslot:
	inc ebx		// increase "from" slot

	cmp cl,dl
	je .done	// this was the last "from" slot

	inc cl
	jmp short .nextslot

.done:
// ch is now the number of the first unused slot, we need the number of the last used one
	dec ch
	mov dl,ch

// clean up the "leftover" between the new last slot and the previous last slot, so it can be compressed better
	sub cl,ch
	// cl is now the number of slots to clean
	xor eax,eax
	movzx ecx,cl
	add ecx,ecx	// one slot is 8 bytes, we need two stosd per slot
	rep stosd

	pop ebx		// restore ebx to what the caller gave us
.exit:
	ret

%macro copyarray 2
	mov ecx,%2*110
	mov esi,[eax]
	mov edi,%1
	rep movsb
	add eax,4
%endmacro

// called to copy the original house data to the new arrays before applying new grpahics
global copyorghousedata
copyorghousedata:
	pusha
	mov eax,orghouseoffsets
	copyarray newhousepartflags,1
	copyarray newhouseflags,1
	copyarray newhouseyears,2
	copyarray newhousepopulations,1
	copyarray newhousemailprods,1
	copyarray newhousepassaccept,1
	copyarray newhousemailaccept,1
	copyarray newhousefoodorgoodsaccept,1
	copyarray newhouseremoveratings,2
	copyarray newhouseremovemultipliers,1
	copyarray newhousenames,2
	copyarray newhouseavailmasks,2

// We use flags 0x40 and 0x80 to signal that a building is a church or a stadium, instead
// of checking fixed IDs, so set the according flags for the "old" churches and stadiums
	mov eax,newhouseflags
	mov bl,0x40
	or [eax+0x03],bl
	or [eax+0x3c],bl
	or [eax+0x3d],bl
	or [eax+0x53],bl
	or [eax+0x5b],bl
	or byte [eax+0x14],0x80
	or byte [eax+0x20],0x80

// Clear all house overrides
	mov edi,houseoverrides
	mov ecx,110
	xor al,al
	rep stosb
	popa
	ret

%undef copyarray

// Called to determine the acceptance of the house in three cargo types
// If the house acceps food/fizzy drinks, don't report it in the temperate climate
// because it can mean paper there
// in:	edi: XY of house
// out:	al/ah: amount/type of first accepted cargo
//	bl/bh: amount/type of second accepted cargo
//	cl/ch: amount/type of first accepted cargo
// safe: ebx,???
global gethouseaccept
gethouseaccept:
	push edx
	gethouseid edx,edi
	cmp edx,127
	jbe .normal		// old houses can't have callbacks

// first, check for callback 1F (cargo acceptance)
	test byte [housecallbackflags+edx-128],0x20
	jz .normal

	push esi
	lea eax,[edx-128]
	mov esi,edi
	mov byte [grffeature],7
	mov byte [curcallback],0x1f
	call getnewsprite
	mov byte [curcallback],0
	pop esi
	jc .normal

	// unpack the returned value
	mov ch,ah
	and ch,0xf
	bt eax,12
	jnc .notother
	neg ch
.notother:
	shl eax,4
	and ah,0xf
	shr al,4
	mov bh,ah
	mov ah,al
	jmp short .hasvalues

.normal:
	// callback disabled, or failed - load values specified by action0
	mov ah,[newhousepassaccept+edx]
	mov ch,[newhousefoodorgoodsaccept+edx]
	mov bh,[newhousemailaccept+edx]

.hasvalues:

	// now ah, bh and ch have correct values, but we must remove food acceptance on temperate
	cmp byte [climate],0
	jne .good
	or ch,ch
	jns .good
	xor ch,ch
.good:

	cmp edx,127
	jbe .normaltypes		// old houses can't have callbacks

	// check for callback 2A, that can override the default accepted types
	test byte [housecallbackflags2+edx-128],1
	jz .notypecallback

	push eax
	push esi
	lea eax,[edx-128]
	mov esi,edi
	mov byte [grffeature],7
	mov byte [curcallback],0x2a
	call getnewsprite
	mov byte [curcallback],0
	mov edx,eax
	pop esi
	pop eax
	jc .notypecallback

	// unpack al,bl and cl from dx
	mov al,dl
	and al,0x1f
	shr edx,5
	mov bl,dl
	and bl,0x1f
	shr edx,5
	mov cl,dl
	and cl,0x1f
	push dword [mostrecentspriteblock]
	jmp short .lookup

.notypecallback:
	// our new house type disabled callback 2A or failed to answer it correctly
	// if the according action0 property is specified, it can still override the
	// default types
	push dword [newhousespriteblock+(edx-128)*4]
	mov edx,[houseaccepttypes+(edx-128)*4]
	cmp edx,byte -1
	je .normaltypes_pop
	// unpack the three bytes in edx into al, bl and cl
	mov al,dl
	mov bl,dh
	shr edx,16
	mov cl,dl
	jmp short .lookup

.normaltypes_pop:
	pop edx
.normaltypes:
	// the old behavior: al=passengers, bl=mail, cl=goods if ch is positive, food if negative
	pop edx
	mov al,0
	mov bl,2
	mov cl,5
	or ch,ch
	jns .notfood

	neg ch
	mov cl,11
.notfood:
	ret

.lookup:
// look up the cargo types we got to get the slot number
// if the cargo isn't available, zero the acceptance so it won't appear at all
// the pointer to the spriteblock must be on the stack
	push eax
	call lookuptranslatedcargo
	pop eax
	cmp al,0xff
	jne .goodtype1
	xor eax,eax
.goodtype1:
	push ebx
	call lookuptranslatedcargo
	pop ebx
	cmp bl,0xff
	jne .goodtype2
	xor ebx,ebx
.goodtype2:
	push ecx
	call lookuptranslatedcargo
	pop ecx
	cmp cl,0xff
	jne .goodtype3
	xor ecx,ecx
.goodtype3:
	pop edx
	pop edx
	ret

#if 0
class3init:
	call copyorghousedata
	movzx ebx,word [noftowns]
	ret
#endif

// Called instead of mov ebp,[landscape2+ebx] to get the ID of a house.
// Return gameid+128 for new house types, so old TTD code will use the correct offsets
// in our new arrays while we can easily make difference between old and new types
global gethouseidebpebx
gethouseidebpebx:
	movzx ebp,byte [landscape3+2*ebx+1]
	or ebp,ebp
	jnz .newhouse

.fallback:
// this is an old type (the high byte of landscape3 is zero), but may still be overridden
	movzx ebp,byte [landscape2+ebx]
	cmp byte [houseoverrides+ebp],0
	je .nooverride
//yes, it's overridden, so mimic the new type instead
	movzx ebp,byte [houseoverrides+ebp]
	jmp short .havenewhouseid

.nooverride:
	ret

.newhouse:
// A new house type - look up the gameid for this dataid
	movzx ebp,byte [housedataidtogameid+ebp*8+housegameid.gameid]
	or ebp,ebp
	jz .fallback	// if the data isn't available, do as if it was an old house type
.havenewhouseid:
	add ebp,128
	ret

// The following functions do the same as above, but with different registers
// The used macro is in vars.ah, and calls gethouseidebpebx after saving the
// used registers
global gethouseidedxebx
gethouseidedxebx:
	gethouseid edx,ebx
	ret

global gethouseidedxedi
gethouseidedxedi:
	gethouseid edx,edi
	ret

global gethouseidebpesi
gethouseidebpesi:
	gethouseid ebp,esi
	ret

global gethouseidecxedi
gethouseidecxedi:
	gethouseid ecx,edi
	ret

global gethouseidesiebx
gethouseidesiebx:
	gethouseid esi,ebx
	ret

uvarb posandbuildflags

uvard currhousepos

// Called to determine the offset in saHouseSpriteTable for the given house
// If it's a new type, we call our custom draw routine instead
// in: (after executing the first two instructions)
//	esi:	bits 0-1: construction state
//		bits 2-3: pseudo-random value (determined from XY index)
//		bits 4-12: real house ID
//		other bits clear
//	ebx:	landscape XY
//	di:	slope data
// out:	esi: offset into saHouseSpriteTable
// safe: ebx,edx,esi,ebp
global gethousegraphics
gethousegraphics:
	shl dx,2	// overwritten
	or si,dx	// ditto
	mov edx,esi
	shr dx,4	// get the house ID from si
	cmp dx,128
	jae .oursprite
.imul:
	imul si,17	// overwritten
	ret

.fallback:
// We couldn't find the new sprites for a new house type - fall back to the sprites of the substitute type
	pop ebx
	movzx eax,byte [substbuilding+edx]	// edx is still the gameid
	and esi,0xf
	shl eax,4
	or esi,eax
	pop eax
	jmp short .imul

.oursprite:
// Save construction state and random bits so variable 40 can access them
// Bit 7 means that the data is valid
	push eax
	mov eax,esi
	and al,0xf
	or al,0x80
	mov [posandbuildflags],al
	movzx edx,dx
	sub edx,128
	mov eax,edx
	push ebx
	push esi
// Try to get offset to the new data
	mov [currhousepos],ebx
	mov esi,ebx
	mov byte [grffeature],7
	call getnewsprite
	mov byte [posandbuildflags],0
	pop esi
	jc .fallback		// use substitute if no graphics are available

// we're going to call our custom routine, processtileaction2; start putting parameters onto the stack

	push eax	// dataptr for processtileaction2
	push ebx	// spritesavail for processtileaction2

	mov ebp,esi
	and esi,3
	push esi	// conststate for processtileaction2

// if the building has a color callback, call it; otherwise select a color from the given four
	test byte [housecallbackflags+edx],0x10
	jz .nocolorcallback
	mov esi,[currhousepos]
	mov eax,edx
	mov byte [grffeature],7
	mov byte [curcallback],0x1e

	call getnewsprite
	mov byte [curcallback],0
	jc .nocolorcallback

	btr eax,14
	jnc .hascolor

	extern deftwocolormaps
	add ax,[deftwocolormaps]
	cmp word [deftwocolormaps],byte -1	// were two color maps defined?
	jne .hascolor

.nocolorcallback:
	mov eax,ebp
	shr eax,2
	and eax,3
	movzx eax,byte [housecolors+edx*4+eax]
	add eax,775
.hascolor:
	push eax		// defcolor for processtileaction2

	mov eax,[esp+20]	// restore saved X coordinate from stack
	mov dx,[esp+28]		// restore saved Z coordinate saved by the caller

	push dword 7		// grffeature for processtileaction2

	call processtileaction2
//sprites are added now, return from caller
	pop ebx
	pop eax
	add esp,8	// remove return address and two saved word regs from stack
	ret		// return from caller

// process a tile action2 (houses and industry tiles use those currently)
// in:	ax=X coordinate of north corner
//	cx=Y coordinate of north corner
//	dl=Z coordinate of north corner
//	di=slope data
// uses: ebx, esi, edi
global processtileaction2
proc processtileaction2
	arg dataptr, spritesavail, conststate, defcolor, grffeature
	slocal numsprites,byte

	_enter

	mov esi,[%$dataptr]

// read the number of sprites. 0 means old format: a ground sprite and a building sprite
	mov bl,[esi]
	inc esi
	mov [%$numsprites],bl

// if more than 3 sprites are available in the block, use only the first 3
	cmp dword [%$spritesavail],3
	jbe .spritenumok
	mov dword [%$spritesavail],3
.spritenumok:

// in both the old and the new formats, the first sprite is a ground sprite
	call .getadjustedspriteno

// 0 means we don't need to have any ground sprite
	test ebx,ebx
	jz .grounddone

// bit 30 is meaningless here, so disable it
	btr ebx,30

// if we aren't on flat ground, there's a foundation already added
// we must make the actual ground sprite share the foundation's bounding box
	test di,0xf
	jz .normalground

	add dl,8
	pusha
	mov ax,31
	mov cx,1
	call [addrelsprite]
	popa
	jmp short .grounddone

.normalground:
// flat land - we can simply add the ground sprite normally
	push ebp
	call [addgroundsprite]
	pop ebp

.grounddone:
	cmp byte [%$numsprites],0
	jne .extended
// building sprite of the old format

// read spritenum - 0 means no building sprite
	call .getadjustedspriteno
	test ebx,ebx
	jz .done

	btr ebx,30
	jc .nottransp1

// add the "transparent" color mapping if transp. buildings is on

	test byte [displayoptions],0x10
	jnz .nottransp1
	and ebx,0x3fff
	or ebx, (802 << 16)+0x4000
.nottransp1:

// add the sprite with the specified bounding box (z_base=0)

	push eax
	push ecx
	movsx edi,byte [esi]
	add eax,edi
	movsx edi,byte [esi+1]
	add ecx,edi
	movzx edi,byte [esi+2]
	mov dh,[esi+4]
	movzx esi,byte [esi+3]

	mov byte [exsspritelistext], 1

	push ebp
	call [addsprite]
	pop ebp
	pop ecx
	pop eax
.done:
	mov byte [exsspritelistext], 0
	_ret

.extended:
// in the extended format, we have more building sprites, so we use a loop to process them
.nextbox:
// read spritenum
	call .getadjustedspriteno

	btr ebx,30
	jc .nottransp2

// add the "transparent" color mapping if transp. buildings is on
	test byte [displayoptions],0x10
	jnz .nottransp2
	and ebx,0x3fff
	or ebx, (802 << 16)+0x4000
.nottransp2:
	pusha
	cmp byte [esi+2],0x80
	je .sharebox

// sprite with own bounding box - add the sprite with the specified bounding box
	movsx edi,byte [esi]
	add eax,edi
	movsx edi,byte [esi+1]
	add ecx,edi
	add dl,[esi+2]
	movzx edi,byte [esi+3]
	mov dh,[esi+5]
	movzx esi,byte [esi+4]
	call [addsprite]
	popa
	add esi,6
	jmp short .boxdone

.sharebox:
// this sprite shares the bounding box of the previous one - use addresprite
	movzx eax, byte [esi]
	movzx ecx, byte [esi+1]
	call [addrelsprite]
	popa
	add esi,3
.boxdone:
	dec byte [%$numsprites]
	jnz .nextbox
	_ret

// helper function to read and pre-process a sprite number read from the action2
// in:	esi->data
// out:	esi moved forwards 4 bytes
//	ebx=sprite number
.getadjustedspriteno:

// despite it's documentation, exsspritelistext is a boolean (it's reset to zero every time
// a sprite is added), so set it to 1 every time we read a sprite. This way, the next
// sprite add function will work correctly

	mov bl,[%$grffeature]
	mov [exscurfeature],bl
	mov byte [exsspritelistext], 1

// read the sprite number
	mov ebx,[esi]
	add esi,4
	btr ebx,31
	jnc .ttdsprite

// This is a custom GRF sprite. If there are more than one sprites per block, select the
// correct one according to the construction state
	push edx
	mov edx,[%$spritesavail]
	shl edx,2
	add edx,[%$conststate]
	movzx edx,byte [.spriteoffsets+edx]
	add ebx,edx
	pop edx

.ttdsprite:
// if recoloring is requested, but no recolor sprite is specified, apply the default color
	test bx,bx
	jns .norecolor

	rol ebx,16
	test bx,0x3fff
	jnz .goodrecolor

	or bx,[%$defcolor]
.goodrecolor:
	ror ebx,16
.norecolor:
	_ret 0		// don't destroy our stack frame

endproc

.spriteoffsets:
	db 0,0,0,0
	db 0,0,0,1
	db 0,1,1,2
	db 0,1,2,3

uvarw createdhousedataid

uvarb canbuild

// called to get a random house type that can be built in the given house zone
// and climate. Other requirements are checked later.
// in:	ecx,edx: zero
//	bp: climate bit to test in baHouseAvailMasks
//	bx: zone bit to test in baHouseAvailMasks
//	edi-> current town
// out:	ebp: random house type
// safe: eax,ebx,ecx,edx,esi,ebp
// stack:	[esp]:return address
//		[esp+4]:1K block available for temporary storage
//		[esp+0x404]: W: saved di (not needed)
//		[esp+0x406]: D: current town
//		[esp+0x40a]: W: current XY
global getrandomhousetype
getrandomhousetype:
// First, collect the types that can be built here. The old code stores one byte per building,
// but we need two bytes for our larger IDs. Luckily, the 1K block allocated is enough for
// this as well ( (128+256)*2=768 )

	push edi
// edi will contain the sum of relative probablities so far
// (the sum will be needed for the random generation)
	xor edi,edi
// Collect old types without override first
.loop1:
	cmp byte [houseoverrides+edx],0
	jne .next1
	mov si,[newhouseavailmasks+2*edx]
	bt si,bp
	jnc .next1
	bt si,bx
	jnc .next1
	bt [disabledoldhouses],edx
	jc .next1
	mov [esp+8+ecx*2],dx	// +8 because edi is on the stack too
	inc ecx
	add edi,16		// all old buildings have a probality of 16

.next1:
	inc edx
	cmp edx,110
	jb .loop1

// Now collect dataids of new houses (remember they're valid only up to [lasthousedataid])
	cmp byte [lasthousedataid],0
	je .noextrahouses
	xor edx,edx
	inc edx

.loop2:
	movzx eax,byte [housedataidtogameid+edx*8+housegameid.gameid]
	or eax,eax
	jz .next2
	mov si,[newhouseavailmasks+2*(eax+128)]
	bt si,bp
	jnc .next2
	bt si,bx
	jnc .next2
	mov [esp+8+ecx*2],dx
	add word [esp+8+ecx*2],128
	inc ecx
	mov al,[houseprobabs+eax]		// add probablity to sum (top of eax is still zero)
	add edi,eax

.next2:
	inc dl
	jz .loop2_done				// overflow can happen when lasthousedataid=0xFF, protect from that
	cmp dl,[lasthousedataid]
	jbe .loop2

.loop2_done:
.noextrahouses:
// Now edi is the sum of all probablities. Use it to select a type randomly with the given
// probablities
	call [randomfn]
	mul edi
	xor ecx,ecx
	xor ebp,ebp

.nexttype:
	mov bp,[esp+8+ecx*2]
	cmp ebp,128
	jb .oldtype

	movzx eax,byte [housedataidtogameid+(ebp-128)*8+housegameid.gameid]
	mov al,[houseprobabs+eax]
	jmp short .haveprobab

.oldtype:
	mov eax,16

.haveprobab:
	inc ecx
	sub edx,eax
// if edx went negative, this is the right ID. Go on otherwise.
	jnb .nexttype

	pop edi
// store the dataid for later (further TTD code needs gameid to work correctly)
	mov [createdhousedataid],bp
	mov byte [canbuild],1
	cmp ebp,128
	jb .normalhouse

// determine gameid (later TTD code needs it to be gameid+128 in ebp)
	movzx ebp,byte [housedataidtogameid+(ebp-128)*8+housegameid.gameid]

// don't allow building houses with extra flag 0 set if this isn't a new town being generated
	test byte [houseextraflags+ebp],1
	jz .docallback
	cmp byte [newtownconstr],1
	je .docallback
	mov byte [canbuild],0
	jmp short .buildit

.docallback:
// call grf callback if requested to determine if this house can really built here
	test byte [housecallbackflags+ebp],1
	jz .buildit
	movzx esi,word [esp+0x400+14]		// saved XY from stack
	mov eax,ebp
	mov byte [grffeature],7
	mov byte [curcallback],0x17
	call getnewsprite
	mov byte [curcallback],0
	jc .buildit				// on error, allowing is the default action
	mov [canbuild],al

.buildit:
	add ebp,128
.normalhouse:
	ret

// Called to check if a building is a church/stadium and if it can be built in a town
// Since the previous call is in a very inconvenient place from where we cannot easily jump back,
// report here if the callback returned false as well
// in:	edi-> town
//	ebp: house type
// out:	zf clear to disallow because there's already a church/stadium in the town
//	cf set to disallow because of the callback
//	allow building otherwise
// safe: eax,???
global testcreatechurchorstadium
testcreatechurchorstadium:
	cmp byte [canbuild],0
	je .dontallow
	mov al,[edi+town.flags]
	shr al,1
	mov ah,[newhouseflags+ebp]
	shr ah,6
	and al,ah
	clc
	ret

.dontallow:
	stc
	ret

// Called when building a building to set the according church/stadium flags in the town structure
// in:	ebp: house type
//	esi-> town
// out:	esi+town.flags set correctly
// safe: ax,???
global createchurchorstadium
createchurchorstadium:
	mov al,[newhouseflags+ebp]
	shr al,5
	and al,~1
	or byte [esi+town.flags],al
	ret

// Called when removing a building to remove church/stadium flags from the town structure
// in:	ebp: house type
//	edi-> town
// out:	esi+town.flags set correctly
// safe: bl,???
global removechurchorstadium
removechurchorstadium:
	mov bl,[newhouseflags+ebp]
	shr bl,5
	not bl
	or bl,1
	and byte [edi+town.flags],bl
	ret

// put a house tile to the landscape.
// in:	edi: XY index
//	cl: gameid to go to the high byte of L3 (used for new houses only)
//	ch: data to go to the low byte of L3 (set in TTD code)
//	dl: data to go to L5 (set in TTD code)
//	dh: random bits to go to L6
//	ebp: house type
// out:	landscape arrays set correctly
// safe: eax
puthouseparttolandscape:
	pusha
	inc word [globalhousecounts+2*ebp]	// update house count cache

// now, update the bounding rectangle of the closest town if necessary

// first, get the closest town
	mov eax,edi
	xor ebx,ebx
	inc ebx
	mov ebp,[ophandler+(3*8)]
	call [ebp+4]

// get the offset of the according town2 struc
	add edi,[townarray2ofst]

// if this house part is outside the bounding rectangle, update the according
// coordinate(s)

	cmp al,[edi+town2.boundrectminx]
	jae .minxok
	mov [edi+town2.boundrectminx],al
.minxok:
	cmp al,[edi+town2.boundrectmaxx]
	jbe .maxxok
	mov [edi+town2.boundrectmaxx],al
.maxxok:
	cmp ah,[edi+town2.boundrectminy]
	jae .minyok
	mov [edi+town2.boundrectminy],ah
.minyok:
	cmp ah,[edi+town2.boundrectmaxy]
	jbe .maxyok
	mov [edi+town2.boundrectmaxy],ah
.maxyok:
	popa

	and byte [landscape4(di)],0xf		// tile type
	or byte [landscape4(di)],0x30
	mov byte [landscape5(di)],dl		// construction counter
	mov byte [landscape3+2*edi],ch		// construction stage
	mov [landscape6+edi],dh			// random bits
	mov al,[currentyear]
	mov [landscape7+edi],al			// year of construction
	cmp ebp,128
	jb .normalhouse

	and byte [landscape5(di)],7		// for animations to work correctly
	mov al,[substbuilding+ebp-128]
	mov [landscape2+edi],al			// substitute building type
	mov al,[houseprocessintervals+ebp-128]
	mov [landscape1+edi],al			// process interval
	mov [landscape3+2*edi+1],cl		// real type
	test byte [newhouseflags+ebp],0x20
	jz .notanim
	pusha
	mov ebx,2				// Class 14 function 2 - add animated tile
	mov ebp,[ophandler+0x14*8]
	call [ebp+4]
	popa
// Execute callback 1c for the first time if needed
	test byte [housecallbackflags+ebp-128],8
	jz .nocallback1c
	pusha
	mov esi,edi
	lea eax,[ebp-128]
	mov byte [grffeature],7
	mov byte [curcallback],0x1c
	call getnewsprite
	mov byte [curcallback],0
	jc .leavealone
	mov ebx,edi
	call sethouseanimstage
.leavealone:
	popa	
.nocallback1c:
.notanim:
	ret

.normalhouse:
	mov ax,bp
	mov [landscape2+edi],al			// for old houses, the real type is in L2...
	mov byte [landscape3+2*edi+1],0		// and the "new type" field is zero
	mov byte [landscape1+edi],0		// for old types 0x04 and 0x05, this needs to be initialized to zero
	ret
	
// called to put a house to the landscape
// in:	ax: random bits, the bottom six bits should be put in L5 for all tiles
//	edi: landscape XY of the north tile
//	cl: low byte of house ID (ignored)
//	ch: data to go to low byte of L3 (only bits 6 and 7 may be set)
//	dl: data to go to L5
//	ebp: house ID
// out:	landscape arrays set correctly
// safe: eax, ebx, cl, edx, esi
global puthousetolandscape
puthousetolandscape:
	push ebp
	push edi
	mov dl,al
	and dl,0x3f
// now dl=the six random bits going to L5 (construction counter and possibly lift position)
	mov ax,[createdhousedataid]
	sub ax,128
	mov cl,al			// this is used for new types only, so it can safely go negative for normal houses
	call [randomfn]
	mov dh,al
// now dh=eight random bits for random action2

// the selected tile will always have a house tile created, plus the neighbors are affected
// as well for bigger houses

	call puthouseparttolandscape

	test byte [newhouseflags+ebp],0x10
	jz .not2x2

// a 2x2 house - 3 more tiles to go
	inc ebp
	inc cl
	add edi,0x100
	call puthouseparttolandscape
	inc ebp
	inc cl
	add edi,-0x100+1
	call puthouseparttolandscape
	inc ebp
	inc cl
	add edi,-1+0x101
	call puthouseparttolandscape
	jmp short .exit

.not2x2:
	test byte [newhouseflags+ebp],4
	jz .not2x1

// a 2x1 house
	inc ebp
	inc cl
	inc edi
	call puthouseparttolandscape
	jmp short .exit

.not2x1:
	test byte [newhouseflags+ebp],8
	jz .not1x2

// a 1x2 house
	inc ebp
	inc cl
	add edi,0x100
	call puthouseparttolandscape

.not1x2:
// it was an 1x1 house, so we have nothing else to do
.exit:
	pop edi
	pop ebp
	ret

// Called when initializing a random new game, before calling the class 3 init function
// In the original function, class 3 is initialized before class F (and new graphics),
// so new towns are created before new buildings become available. We fix this by
// initializing class F just before class 3. I hope it doesn't break anything since
// neither the original class F init handler nor our extra code accesses the old
// landscape arrays
// in: ax=1
// safe: ebp
global randomgame1
randomgame1:
	mov ebp,[ophandler+0xf*8]
	call [ebp]			// init class F
	mov ax,1
	mov ebp,[ophandler+0x3*8]
// the call itself stays in the TTD code
	ret

// The following four functions are used to get various variables for variational cargo IDs
// All of them called with esi containing the XY of the building and should return the
// needed value in eax. Ecx is safe to use.

// Called to access variable 40 (construction state and pseudo-random bits) for town buildings
// If we're drawing a sprite, we have both in [posandbuildflags], otherwise get the construction
// state from L3 and leave random bits at zero
// Return zero during callback 17 since the house hasn't been built yet
global gethousebuildstate
gethousebuildstate:
	cmp byte [curcallback],0x17
	je gethouseage.returnzero
	movzx eax,byte [posandbuildflags]
	xor al,0x80
	js .noflags
	ret

.noflags:
	movzx eax,byte [landscape3+2*esi]
	shr eax,6
	ret

// Called to access variable 41 (building age) for town buildings
// Return zero during callback 17 since the house hasn't been built yet
global gethouseage
gethouseage:
	cmp byte [curcallback],0x17
	je .returnzero
//	mov ecx,esi
//	add ecx,[landscape7ptr]
	xor eax,eax
	mov al,[currentyear]
	sub al,[landscape7+esi]
	ret

.returnzero:
	xor eax,eax
	ret

// Called to access variable 42 (town zone) for town buildings
// Use the according TTD function to find it out
global gethousezone
gethousezone:
	pusha
	mov ebp,[ophandler+(3*8)]
	xor ebx,ebx
	mov bl,2
	mov eax,esi
	xor edi,edi
	call dword [ebp+4]
	xor eax,eax
	mov al,dl
	mov [esp+28],eax	// will be popped to eax
	popa
	ret

// auxiliary: get the terrain type of a tile
// in:	esi: XY of the tile
// out:	eax:	0 for grass
//		1 for desert
//		2 for rainforest
//		4 for snow
// preserves: everything except eax
global gettileterrain
gettileterrain:
	xor eax,eax
	testflags tempsnowline
	jnc .nottempsnow
	cmp byte [climate],0
	je .snowtest

.nottempsnow:
	cmp byte [climate],1
	jne .nosnowtest

.snowtest:
	push ebx
	push edx
	push edi
	call [gettileinfoshort]

	test di,di
	jz .noadjust
	test dword [miscmodsflags],MISCMODS_DONTCHANGESNOW
	jnz .noadjust

	add dl,8

.noadjust:

	cmp dl,[snowline]
	seta al
	shl al,2
	// now al=4 if snowy, al=0 if not
	pop edi
	pop edx
	pop ebx
	ret

.nosnowtest:
	cmp byte [climate],2
	jne .gotit
	xchg ebx,esi
	call [getdesertmap]
	xchg ebx,esi

.gotit:
	ret

// Called to access variable 44 (house count)
global gethousecount
gethousecount:
	pusha
	cmp byte [curcallback],0x17
	jne .notconstruct
// the house isn't created yet (this can happen with new houses only, since overridden types aren't built)
	movzx ecx,word [createdhousedataid]
	movzx ecx,byte [housedataidtogameid+(ecx-128)*8+housegameid.gameid]
	add ecx,128
	jmp short .gotid

.notconstruct:
	gethouseid ecx,esi
.gotid:				//NOTE: this label is called from outside the proc!
// now ecx is the gameid we're looking for

// get the house count on the map, capped to 255
	mov dx,[globalhousecounts+ecx*2]
	test dh,dh
	jz .nottoomuchnormal
	mov dx,0xff
.nottoomuchnormal:

	cmp ecx,127
	jbe .noclass_map
	lea edi,[houseclasses+(ecx-128)*5]
	cmp dword [edi],0
	jz .noclass_map

// loop through all house types to get the sum of house counts for the class
	movzx eax,byte [lastextrahousedata]
	mov ebx,[edi]
.nextclass_map:
	cmp ebx,[houseclasses+eax*5]
	jne .skipclass_map		// wrong GRFID
	push ebx
	mov bl,[houseclasses+eax*5+4]
	cmp bl,[edi+4]
	pop ebx
	jne .skipclass_map		// wrong class

	cmp byte [globalhousecounts+(eax+128)*2+1],0
	jne .class_map_maxed		// more than 255 instances from this type - the byte will be maxed

	add dh,[globalhousecounts+(eax+128)*2]
	jc .class_map_maxed		// overflow - the byte got maxed

.skipclass_map:
	dec eax
	jnz .nextclass_map
	jmp short .class_map_ok

.class_map_maxed:
	mov dh,0xff
.class_map_ok:
.noclass_map:
	shl edx,16

// Now count the same values for the current town. To speed things up, every town has a bounding rectangle
// stored in town2, so we can limit our loop to that area.

// fetch the address of the "nearest town" call into ebp to make calling it faster and easier
	mov eax,[ophandler+(3*8)]
	mov ebp,[eax+4]
	mov eax,esi
	xor ebx,ebx
	inc ebx
	push ebp
	call ebp
	pop ebp
	mov esi,edi
// esi now contains the current town

	xor edi,edi
	cmp ecx,127
	jbe .noclass
	mov edi,[houseclasses+(ecx-128)*5]
.noclass:
// now edi=GRFID of current house or 0 if no class

	mov eax,[townarray2ofst]

	movzx eax,word [esi+eax+town2.boundrectminx]	// this actually loads both boundrectminx and boundrectminy

.nexttile:
// is it a house?
	mov bl,[landscape4(ax,1)]
	shr bl,4
	cmp bl,3
	jne .tiledone

// is it the same type as ours?
	gethouseid ebx,eax
	cmp ebx,ecx
	jne .notsametype

// it's the correct type, but is it in the correct town?
// (using a bounding rectangle doesn't guarantee that houses from other towns
// aren't processed, only that all houses of the current town will be processed)
	xor ebx,ebx
	inc ebx
	push edi
	push esi
	push ebp
	call ebp
	pop ebp
	pop esi
	cmp esi,edi
	pop edi
	jne .tiledone

// correct type in the correct town - increase dl, and dh as well if the house has a class
// (if it has one, the type itself will belong to its class)
// use overflow protection to keep the values in the byte range
	add dl,1
	sbb dl,0
	test edi,edi
	jz .tiledone
	add dh,1
	sbb dh,0
	jmp short .tiledone

.notsametype:
// this house isn't the same type as ours, but it can still be in the same class

	test edi,edi
	jz .tiledone				// our building has no class
	cmp ebx,127
	jbe .tiledone				// old buildings have no class
	cmp edi,[houseclasses+(ebx-128)*5]
	jne .tiledone				// wrong GRFID
	mov bl,[houseclasses+(ebx-128)*5+4]
	cmp bl,[houseclasses+(ecx-128)*5+4]
	jne .tiledone				// wrong class

// the class is OK - check the town
	xor ebx,ebx
	inc ebx
	push edi
	push esi
	push ebp
	call ebp
	pop ebp
	pop esi
	cmp esi,edi
	pop edi
	jne .tiledone

// all OK - increase dh with overflow protection
	add dh,1
	sbb dh,0

.tiledone:
	mov ebx,[townarray2ofst]
	inc al
	cmp al,[esi+ebx+town2.boundrectmaxx]
	jbe .nexttile

	mov al,[esi+ebx+town2.boundrectminx]
	inc ah
	cmp ah,[esi+ebx+town2.boundrectmaxy]
	jbe .nexttile

// all values are known now, but they're in the wrong order
// exchange bytes 1 and 2
	ror edx,8
	xchg dl,dh
	rol edx,8

	mov [esp+28],edx	// will be popped to eax
	popa
	ret

// Called to access parametrized variable 60 (count old house type)
// we call the above function to do the hard work, after reading the parameter
global getotherhousecount
getotherhousecount:
	movzx ecx,ah
	pusha
	jmp gethousecount.gotid

// Called to access parametrized variable 61 (count new house type)
// Before we can call the function above, we must find the gameID
// associated to this GRFID and setID
global getothernewhousecount
getothernewhousecount:
	pusha
	mov edx,[mostrecentspriteblock]
	mov edx,[edx+spriteblock.grfid]

	movzx ecx,byte [lasthousedataid]
	jecxz .notfound

.nextdataid:
	cmp [housedataidtogameid+ecx*8+housegameid.grfid],edx
	jne .notgood							// bad GRFID
	cmp [housedataidtogameid+ecx*8+housegameid.setid],ah
	jne .notgood							// bad setID

// this is the correct gameID; now we can call our function
	movzx ecx,byte [housedataidtogameid+ecx*8+housegameid.gameid]
	add ecx,128
	jmp gethousecount.gotid

.notgood:
	dec ecx
	jnz .nextdataid

.notfound:
// gameID not found - return zero
	popa
	xor eax,eax
	ret

// Called to access variable 45 (town expansion bits)
global getexpandstate
getexpandstate:
	movzx eax,byte [newtownconstr]
	ret

// Start/stop animation and set the animation stage of a new house
// This isn't used in the animation handler, where we need something
// more complex
// in:	al:	number of new stage where to start
//		or: ff to stop animation
//		or: fe to start wherewer it is currently
//		or: fd to do nothing (for convenience)
//	ebx:	XY of house tile
sethouseanimstage:
	or ah,ah
	jz .nosound

// if we have anything in the high byte, it is a sound number to play
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
// 0xfd means "do nothing"
	cmp al,0xfd
	je .animdone

	cmp al,0xff
	jne .dontstop

// 0xff - stop animation
	pusha
	mov edi,ebx
	mov ebx,3				// Class 14 function 3 - remove animated tile
	mov ebp,[ophandler+0x14*8]
	call [ebp+4]
	popa
	ret

.dontstop:
// 0xfe means "start at current frame", so skip to the starting part
	cmp al,0xfe
	je .dontset

// update animation frame
	shl al,3
	and byte [landscape5(bx)],7
	or byte [landscape5(bx)],al

.dontset:
// add the tile to the animation list - adding it repeatedly won't hurt, the add function checks
// for duplicates
	pusha
	mov edi,ebx
	mov ebx,2				// Class 14 function 2 - add animated tile
	mov ebp,[ophandler+0x14*8]
	call [ebp+4]
	popa

.animdone:
	ret

// Called in the very beginning of the class3 periodic proc
// Activate random triggers 1 and 2 if the specified time has elapsed
// in:	ebx: XY of tile
// safe: eax,ebp
global class3periodicproc
class3periodicproc:
	gethouseid ebp,ebx
	sub ebp,128
	jb near .normalhouse
	mov al,[landscape1+ebx]
	or al,al
	jz .process			// has the timer reached zero?
	cmp al,[houseprocessintervals+ebp]
	ja .process			// is it larger than its maximum? if it is, something went wrong earlier,
					// so activate triggers and reset timer
	dec byte [landscape1+ebx]	// time hasn't elapsed yet - decrease timer
	jmp near .noprocess
	
.process:
	mov al,1
	call randomhouseparttrigger
	mov al,2
	call randomhousetrigger

// for multi-tile buildings, callback 1B comes in two flavors - you can either
// have it called for every tile independently, or do it simultaneously with the
// northern tile to ensure synchronization
	test byte [houseextraflags+ebp],4
	jnz .notsimpleanim

// this tile uses the independent version - call a special function to do the actual work
	mov eax,ebp
	call .checktileanim

// in case this tile is the northern tile of a multi-tile building, we need to check all
// tiles of the building and call callback 1B if they use the simultaneous version
// (if this tile isn't a northern part, its part flags should be zero, so all calls will
//  be simply skipped)
.notsimpleanim:

	call [randomfn]
	mov [miscgrfvar],eax

	push ebx
	test byte [newhousepartflags+ebp+128],8
	jz .notmain
	call .checktileanim_building
.notmain:
	add ebx,0x100
	test byte [newhousepartflags+ebp+128],4
	jz .noty
	call .checktileanim_building
.noty:
	sub ebx,0xff
	test byte [newhousepartflags+ebp+128],2
	jz .notx
	call .checktileanim_building
.notx:
	add ebx,0x100
	test byte [newhousepartflags+ebp+128],1
	jz .notxy
	call .checktileanim_building
.notxy:
	pop ebx

	and dword [miscgrfvar],0

// call callback 21 if it's enabled
	test byte [housecallbackflags+ebp],0x80
	jz .dontdestroy
	pusha
	mov eax,ebp
	mov esi,ebx
	mov byte [grffeature],7
	mov byte [curcallback],0x21
	call getnewsprite
	mov byte [curcallback],0
	mov [esp+0x1c],al				// will be popped to al
	popa
	jc .dontdestroy
	or al,al
	jnz .destroyhouse
.dontdestroy:

	mov al,[houseprocessintervals+ebp]	// restart counting from maximum
	mov [landscape1+ebx],al

.noprocess:
.normalhouse:
	mov ax,[landscape3+2*ebx]		// overwritten
	ret

.destroyhouse:
	pop eax
	pusha
	mov eax,ebx			// prepare coordinates
	mov ecx,ebx
	rol ax,4
	ror cx,4
	and ax,0x0ff0
	and cx,0x0ff0
	mov bl,1			// actually do it
	mov esi,(1<<16)+(3<<3)
	mov byte [curplayer],0x10	// remove house
	call [actionhandler]
	popa
	ret

.checktileanim_building:
// check a house tile in the simultaneous version
	gethouseid eax,ebx
	sub eax,128
	jb .animdone				// an old house doesn't have animation callbacks
	test byte [housecallbackflags+eax],4
	jz .animdone
	test byte [houseextraflags+eax],4
	jz .animdone				// this tile doesn't use the simultaneous model

	push eax
	call [randomfn]
	mov [miscgrfvar],ax
	pop eax

	jmp short .dotileanim

.checktileanim:
// if callback 1B is enabled, call it and set the animation accordingly
	test byte [housecallbackflags+eax],4
	jz .animdone

	push eax
	call [randomfn]
	mov [miscgrfvar],eax
	pop eax

.dotileanim:
	pusha
	mov esi,ebx
	mov byte [grffeature],7
	mov byte [curcallback],0x1b
	call getnewsprite
	mov byte [curcallback],0
	mov [esp+0x1c],al				// will be popped to al
	popa
	jc .animdone
	call sethouseanimstage
.animdone:
	ret

// Called if newhouses is on, but there's no house data in the savegame
// Clear dataids from the high byte of L3 because we no longer know
// which graphics they are associated to
global clearhouseidsfromlandscape
clearhouseidsfromlandscape:
	push eax
	push esi

	xor esi,esi

.loop:
	mov al,[landscape4(si)]
	shr al,4

	cmp al,3
	jne .next

	mov byte [landscape3+2*esi+1],0

.next:
	inc esi
	cmp esi,0x10000
	jb .loop

	pop esi
	pop eax
	ret

uvard newhousename_junk

// Called to get or set texts associated to new house types
// in:	edi=text ID & 7ff
//	0xx = get new house type xx name
//	1xx = set new house type xx name
// out:	eax=table ptr
//	edi=table index
// safe: none
global gethousetexttable
gethousetexttable:
	mov eax,edi
	movzx edi,al
	cmp ah,1
	ja near gettownnametexttable
	testflags newhouses
	jnc .notexts
	cmp ah,1
	jne .notset

	movzx edi,byte [curgrfhouselist+edi]
	mov eax,edi
// Update house name array at the same time
	or ax,0xc800
	mov [newhousenames+2*(edi+128)],ax
	mov eax,newcustomhousenames
	ret

.notexts:
	mov eax,newhousename_junk
	xor edi,edi
	ret

.notset:
	or edi,edi
	jz .default
	mov eax,newcustomhousenames
	cmp dword [eax+edi*4],0
	je .default
	ret

.default:
// something is wrong if we get here...
	mov ax,0x203f			// "Houses"
	jmp gettextintableptr

// Called instead of ExpandTown while generating houses for a new town.
// Save the fact that we're generating a new town
global expandnewtown
expandnewtown:
	mov byte [newtownconstr],1
	call $
ovar .oldfn,-4,$,expandnewtown
	mov byte [newtownconstr],0
	ret

// Called instead of mov edx,[landscape2+edi] in the town building removal handler
// Check whether this house is protected and prevent destruction if so
global canremovehouse
canremovehouse:
	gethouseid edx,edi
	cmp edx,128				// old houses can't be protected
	jb .allow
//towns can remove the house only if its minimum lifespan is expired
	cmp byte [curplayer],0x80
	jb .nottown
	push eax
	mov al,[currentyear]
	sub al,[landscape7+edi]
	cmp al,[houseminlifespans+edx-128]
	pop eax
	jb .deny
.nottown:
	test byte [housecallbackflags2+edx-128],4	// is the protection callback enabled?
	jnz .callback
	test byte [houseextraflags+edx-128],2	// is it protected?
	jz .allow
.deny_for_nonplayer:
	call isrealhumanplayer			// humans can remove even protected houses
	jz .allow
	cmp byte [curplayer],0x10		// allow in scenario editor as well
	je .allow
	cmp byte [curplayer],0x11		// water can flush anything it wants...
	je .allow
.deny:
	pop edx					// remove our return address
	pop cx					// restore regs saved by the caller
	pop ax
	mov ebx,0x80000000			// indicate error
	mov word [operrormsg2],6		// but no message (humans shouldn't see this anyway)
.allow:
	ret

.callback:
	push eax
	lea eax,[edx-128]
	xchg edi,esi
	mov byte [grffeature],7
	mov dword [curcallback],0x143
	call getnewsprite
	mov dword [curcallback],0
	mov edx,eax
	xchg edi,esi
	pop eax
	jc .allow
	test edx,edx
	jz .allow
	jmp short .deny_for_nonplayer
	
// Called in the class 3 animation handler
// The old code checks landscape2 in a special way, but
// we need the real (word) ID instead.
global class3animation
class3animation:
	push eax
	gethouseid eax,ebx
	cmp eax,127
	ja .newhouse
	cmp eax,4
	jz .goodflags
	cmp eax,5
.goodflags:
	pop eax
	ret

.newhouse:
	// we're taking this call over, remove saved eax and return address
	pop ecx
	pop ecx
	// Since the animation counter isn't refreshed in the scenario editor,
	// animations would either stop or go berserk depending on where
	// the counter stopped. To avoid this, we don't do any animation
	// in the scenario editor.
	cmp byte [gamemode],2
	je .abort
	sub eax,128
	movzx edi, word [animcounter]
	mov ebp,1

// if callback 20 is enabled, call it to get the speed, use the action 0 prop otherwise
	test byte [housecallbackflags+eax],0x40
	jz .normalspeed

	push eax
	push esi
	mov esi,ebx
	mov byte [grffeature],7
	mov byte [curcallback],0x20
	call getnewsprite
	mov byte [curcallback],0
	mov cl,al
	pop esi
	pop eax
	jnc .hasspeed

.normalspeed:
	mov cl,[houseanimspeeds+eax]
.hasspeed:
	shl ebp,cl
	dec ebp
// now ebp has the low cl bits set, all others cleared
// we go to the next frame only if the low cl bits of the anim counter are clear
	test edi,ebp
	jz .progress
.abort:
	ret

.progress:
// if callback 1A is enabled, call it to get the next frame - otherwise, do the default thing
	test byte [housecallbackflags+eax],2
	jz .normal
	test byte [houseextraflags+eax],8
	jz .norandom

	push eax
	call [randomfn]
	mov [miscgrfvar],eax
	pop eax

.norandom:
	push eax
	push esi
	mov esi,ebx
	mov byte [grffeature],7
	mov byte [curcallback],0x1a
	call getnewsprite
	mov byte [curcallback],0
	mov dword [miscgrfvar],0	// don't hurt flags
	mov ecx,eax
	pop esi
	pop eax
	jc .normal

	or ch,ch
	jz .nosound

// if the upper byte of the return value isn't zero, it's a sound index to be played
	pusha
	movzx eax,ch
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
	cmp cl,0xff
	je .stop		// FF means "stop"
	cmp cl,0xfe
	jne .hasframe		// FE means "proceed normally", everything else is a frame number

.normal:
// if we have frames remaining, just jump to the next one
	mov cl,[landscape5(bx)]
	shr cl,3
	inc cl
	mov ch,[houseanimframes+eax]
	and ch,0x7f
	cmp ch,cl
	jb .finished		// this was the last frame
.hasframe:
// update current frame field and redraw the tile
	shl cl,3
	and byte [landscape5(bx)],7
	or [landscape5(bx)],cl
	mov esi,ebx
	jmp redrawtile			// in manucnvt.asm

.finished:
// we're at the end of the animation - if it's looping, jump to the first frame, stop it otherwise
	test byte [houseanimframes+eax],0x80
	jz .stop
	xor cl,cl
	jmp short .hasframe

.stop:
// stop animation - that is, remove the tile from the animated tile list
	mov edi,ebx
	mov ebx,3				// Class 14 function 3 - remove animated tile
	mov ebp,[ophandler+0x14*8]
	jmp [ebp+4]

// By default, the "flat land only" flag works for 1x1 buildings only.
// We fix it so it is checked for 2x1 and 1x2 as well by modifying a test.
// in:	ax, cx: fine X and Y coordinates of tile
//	di: slope info
//	ebp: house ID of the north tile
// out:	zf clear to signal unsuitable tile
// safe: ebx, edx, esi
global checkhouseslopes
checkhouseslopes:
	call [gettileinfo]			// overwritten
	test byte [newhouseflags+ebp],2
	jz .notonlyflat

// only flat land is allowed
	test di,di
	ret

.notonlyflat:
	test di,0x10				// overwritten - don't allow steep slopes
	ret

global gethouseanimframe
gethouseanimframe:
	movzx eax,byte [landscape5(si)]
	shr eax,3
	ret

// Called to decide if the current house is an old animated type that needs re-randomizing
// the lift position
// in:	al: L3 & 0xC0
//	ebp: house type
// out:	zf set for animated old houses
// safe: ???
global isoldhouseanimated
isoldhouseanimated:
	cmp ebp,127
	ja .newhouse
	test byte [newhouseflags+ebp],0x20
	ret

.newhouse:
	test al,0	// set zf
	ret

// new code to increase the construction counter
// (the original one would destroy the animation frame field)
// in:	al: L5 value of the tile
//	ebx: XY
// out:	zf set if the counter overflowed
//	L5 updated
// safe: eax, ???
global processhouseconstruction
processhouseconstruction:
	push ecx
	gethouseid ecx,ebx
	cmp ecx,127
	pop ecx
	mov ah,al
	ja .newhouse

// this is an old type - if L5 has bit 7 set, the meaning is different, so leave the caller
	or ah,ah
	jns .continue
	pop eax
	ret

.continue:
// an old type, but bit 7 isn't set - reproduce overwritten code
	inc al
	and ax,0xc007
	jmp short .ax_ok

.newhouse:
// increase the counter (bottom 3 bits) without hurting the others
	and ax,0xf807
	inc al
	and al,7
.ax_ok:
	or ah,al
	mov [landscape5(bx)],ah
	or al,al
	ret

vard refreshrectxleft, 31
vard refreshrectxright, 36
vard refreshrectyup, 122
vard refreshrectydown, 32

// Called in RefreshTile, to calculate the rectangle that needs to be redrawn
// in:	ax,dx=absolute x coordinate of N corner of tile
// 	bx,bp=absoulte y coordinate of N corner of tile
// out:	ax,bx,dx,bp= x1

global calcrefreshrect
calcrefreshrect:
	sub ax,[refreshrectxleft]
	add dx,[refreshrectxright]
	sub bx,[refreshrectyup]
	add bp,[refreshrectydown]
	ret
	
// called when a house changes its construction stage
// execute callback 1c if needed
global changeconststate
changeconststate:
	mov [landscape3+2*ebx],al	// functionally overwritten, but not literally
					// (the original moved ax, but in fact changed
					//  the low byte only)
	pusha
	gethouseid eax,ebx
	sub eax,128
	jb .animdone
	test byte [housecallbackflags+eax],8
	jz .animdone
	push ebx
	mov esi,ebx
	mov byte [grffeature],7
	mov byte [curcallback],0x1c
	call getnewsprite
	mov byte [curcallback],0
	pop ebx
	jc .animdone
	call sethouseanimstage
.animdone:
	popa
	ret

// get town variable 40 - how largertowns affects this town
// 0 - largertowns enabled, this town isn't larger
// 1 - largertowns enabled, this town is larger
// 2 - largertowns disabled
global getistownlarger
getistownlarger:
	push ebx

// get town index from offset
	mov eax,esi
	sub eax,townarray
	mov bl,town_size
	div bl

	call istownbigger
	jc .disabled
	setz al
	jmp short .end

.disabled:
	mov al,2
.end:
	movzx eax,al
	pop ebx
	ret

// get town variable 41 - index of town
global gettownnumber
gettownnumber:
	push ebx
	mov eax,esi
	sub eax,townarray
	mov bl,town_size
	div bl
	movzx eax,al
	pop ebx
	ret

// called when the "place rock" tool is used in the scenario editor
// if ctrl is held down, place a house instead
// in:	esi: XY
//	???
// safe: ???
global placerocks
placerocks:
	push CTRL_ANY
	call ctrlkeystate
	jz .puthouseinstead

	and dh,0xe3	// overwritten
	or dh,8		// ditto
	ret

.puthouseinstead:
// remove return address - we're taking the call over
	pop ebx

	pusha

// find the nearest town for the tile
	push eax
	mov ebp,[ophandler+(3*8)]
	xor ebx,ebx
	inc ebx
	mov eax,esi
	call dword [ebp+4]

// if bp is FFFF, there are no towns on the map yet
	cmp bp,0xffff
	je .notownyet

// calculate the index of the town from the pointer,
// so we can have the correct curplayer
	mov eax,edi
	sub eax,townarray
	mov bl,town_size
	div bl
	or al,0x80
	mov [curplayer],al
	pop eax

	mov bl,0x0b
	mov esi,0x18		// create new house
	mov byte [newtownconstr],1
	mov byte [scenarioeditmodeactive],1
	call [actionhandler]
	mov byte [scenarioeditmodeactive],0
	mov byte [newtownconstr],0
	popa
	ret

.notownyet:
// if we have no towns on the map yet, placing a house would cause various Bad Things to happen
	pop eax
	popa
	ret

// called when generating cargo for a house tile
// handle custom cargo generation here if needed
// in:	eax: random bits
//	ebx: XY
//	ebp: house type
global generatehousecargo
generatehousecargo:
	cmp ebp,127
	jbe .nocallback					// old type, can't have callback
	test byte [housecallbackflags2+ebp-128],2
	jnz .docallback					// callback disabled
.nocallback:
	cmp al,[newhousepopulations+ebp]	//overwritten
	ret

.docallback:
	add dword [esp],122	// modify return address so we skip the old code
	push edi
	mov [callback_extrainfo],eax
	and dword [miscgrfvar],0
	lea edx,[ebp-128]	// save type to a safe place, the distribute func overwrites ebp
	mov edi,ebx		// XY for the distribute function
.nextcall:
	mov byte [curcallback],0x2e
	mov byte [grffeature],7
	mov esi,ebx		// XY for getnewsprite
	mov eax,edx
	call getnewsprite
	jc near .finished
	cmp ax,0x20ff
	je .finished

	// reset stuff for callbacks/triggers in DistributeProducedCargo
	push dword [miscgrfvar]
	push dword [callback_extrainfo]
	and dword [miscgrfvar],0
	mov byte [curcallback],0

	xchg al,ah

	push dword [mostrecentspriteblock]
	push eax
	call lookuptranslatedcargo
	pop eax
	add esp,4
	cmp al,0xff
	je .dontrecord
	push eax

	mov ecx,0x101		// dimensions for the distribute function
	call [DistributeProducedCargo]
	pop ecx

	cmp cl,0	// passengers
	jne .notpass
	push edx
	mov dl,0
	jmp short .record
.notpass:
	cmp cl,2	// mail
	jne .dontrecord
	push edx
	mov dl,2
.record:
	movzx ecx,ch
	movzx eax,al
	xchg edi,[esp+12]
	call recordtransppassmail		// in towndata.asm
	xchg edi,[esp+12]
	pop edx
.dontrecord:
	pop dword [callback_extrainfo]
	pop dword [miscgrfvar]

	inc byte [miscgrfvar]
	jnz .nextcall
.finished:
	and dword [miscgrfvar],0
	mov byte [curcallback],0
	pop edi
	ret

// called to fill the house count cache and the town bounding boxes
// when a new game is started or loaded. The cache will save a lot of time later
global recalchousecounts
recalchousecounts:
	pusha

// zero out the cache - the later code assumes all counts start from zero
	mov edi,globalhousecounts
	mov ecx,(128+256)/2
	xor eax,eax
	rep stosd

// fill all bounding box fields with sentinel values
	mov edi,[townarray2ofst]
	add edi,townarray
	mov ecx,numtowns
.nexttown:
	mov dword [edi+town2.boundrectminx],0x0000FFFF		// min=(FF,FF), max=(0,0), so the first house will
								// always set all coordinates
	add edi,town2_size
	dec ecx
	jnz .nexttown

// fetch the address of the "nearest town" call into ebp to make calling it faster and easier
	mov eax,[ophandler+(3*8)]
	mov ebp,[eax+4]

// eax will go through all tiles of the map
	xor eax,eax
.nexttile:
// is it a house?
	mov bl,[landscape4(ax,1)]
	and bl,0xf0
	cmp bl,0x30
	jne .skiptile

	xor ebx,ebx
	inc ebx
	push ebp
	call ebp
	pop ebp

	add edi,[townarray2ofst]

// update bounding box coords if the house is outside the bounding box
	cmp al,[edi+town2.boundrectminx]
	jae .nonewminx
	mov [edi+town2.boundrectminx],al
.nonewminx:
	cmp al,[edi+town2.boundrectmaxx]
	jbe .nonewmaxx
	mov [edi+town2.boundrectmaxx],al
.nonewmaxx:
	cmp ah,[edi+town2.boundrectminy]
	jae .nonewminy
	mov [edi+town2.boundrectminy],ah
.nonewminy:
	cmp ah,[edi+town2.boundrectmaxy]
	jbe .nonewmaxy
	mov [edi+town2.boundrectmaxy],ah
.nonewmaxy:

// then increase the cached house count

	gethouseid ebx,eax

	inc word [globalhousecounts+ebx*2]

.skiptile:
	inc ax
	jnz .nexttile

	popa
	ret

// called when removing a house tile from the map
// decrease the according house count to keep the cache correct
// in:	bl bit 0 clear if checking cost only
//	ax, cx: fine X and Y of north corner of the tile
// safe: ???
global removehousetilefromlandscape
removehousetilefromlandscape:
	test bl,1
	jz .testonly

	push ebp
// get back the XY from the fine coords
	movzx ebp,ax
	rol bp,8
	or bp,cx
	rol bp,4

	gethouseid ebp,ebp
	dec word [globalhousecounts+ebp*2]
	pop ebp

.testonly:
	jmp [cleartilefn]		// we've hijacked the call to this func
