//
// Make it possible to build more things on slopes, on a foundation like houses and industries
//

#include <std.inc>
#include <flags.inc>
#include <grfdef.inc>

extern actionhandler,addgroundsprite,addrelsprite,addsprite
extern autoslopechecklandscape,bridgemiddlezcorrectslope,coastdirections
extern getgroundalt,gettileinfo,groundaltsubroutines
extern isrealhumanplayer,locationtoxy,patchflags,saved_ebx
extern stationbuildcostptr
extern waterbanksprites, curplayerctrlkey



var extfoundationspritebase, dw -1
var extfoundationspritenum, dd foundationtypes*3+8

// Normal (allowed by TTD) track and road combinations on slopes (for the 14 possible non-steep slopes)
var railslopenormal, db 20h,4,1,10h,0,2,8,8,2,0,10h,1,4,20h
db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00	// and steep slopes

var roadslopenormal, db 0,0,0ah,0,0,5,0,0,5,0,0,0ah,0,0

// Possible combinations of levelled (on a foundation) track and road
var railslopelevelled, db 10h,8,1ah,20h,3fh,29h,3fh,4,15h,3fh,3fh,26h,3fh,3fh
db 0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0x08,0xFF,0xFF,0xFF,0x10,0xFF,0x04,0x20 	// and steep slopes

var roadslopelevelled, db 3,6,7,0ch,0fh,0eh,0fh,9,0bh,0fh,0fh,0dh,0fh,0fh

// Map of levelled foundation types to incline types
var foundationinclinetypes, db 3,9,3,6,0ch,6,0ch,9

// Bit masks of possible slopes for bridge ends on foundations
var bridgeendfoundation, dw 0x990,0x4182,0x6006,0x2814
var bridgeendfoundationhigherbridges, dw 0x6990,0x6982,0x6886,0x6894

// Bit masks for possible slopes for busstops
var busstopfoundation, dw 0x6EE0,0x7CA8

// Foundation remap for the 4 possible steep slopes
var steepslopefoundationmap, dd 0x30, 0x4A, 0x1F, 0x0A, 0x30, 0x4A, 0x1F, 0x0A, 0x30, 0x4A, 0x1F, 0x0A

// Display foundation
// in:	AX,CX = X,Y of the north corner; DL = corrected altitude
//	EBP = foundation type and direction (22 possible combinations) in lowest 7 bits
// out:	clears the upper 25 bits of EBP
// preserves: everything else
global displayfoundation
displayfoundation:
	and ebp,0xfff
	pusha
	push ebp

	mov dh,1
	bt ebp, 7
	jc .incline						// flat (levelled), or inclined foundation?


.normal:
	mov dh,7
	sub dl,8					// revert to the original altitude (of the lowest corner)
	and ebp, 0x0F				// make steepslopes look like normal slopes
	jmp .typecheckdone
.incline:
	shr ebp, 8
	add ebp, 15
.typecheckdone:

	xor edi,edi
	or di,[extfoundationspritebase]
	jns .haveext

	// no extended foundation sprites, fall back to the standard ones
	cmp dh,7
	jz .getsprite

	// The worst situation: we need an inclined foundation but have no sprites.
	// We fall back to standard TTD sprites for the corresponding levelled foundation,
	// which will look *very* ugly, but that's about the best we can do.
	push ecx
	lea ecx,[ebp-15]
	shr ecx,1
	xor ebp,ebp
	inc ebp
	shl ebp,cl
	pop ecx
	jmp short .getsprite

.haveext:
	call gettilealtmergemap
	imul esi,byte foundationtypes
	add ebp,esi

.getsprite:
	lea ebx,[ebp+989]			// standard TTD sprites
	sub ebp,14+1				// 14 sprites in TRG1, offsets counted from 1 up
	jb .gotsprite

	// using extended sprites
	lea ebx,[edi+ebp]

.gotsprite:
	xor esi,esi
	inc esi
	cmp dh,1
	je .gotdim
	add esi,0xf

.gotdim:

	mov edi,esi	
	pop ebp	// steepslopes

	bt ebp, 4
	jc .steepslope
	call [addsprite]
	popa
	ret
.steepslope:
	sub dl, 8
	pusha
	call [addsprite]
	popa

	xor edi,edi
	or di,[extfoundationspritebase]
	mov bx, 997
	js .havenoext
	and ebp, 0xf
	xor ebp, 0xf
	bsf ebp,ebp

// doesn't work
//	push esi
//	call gettilealtmergemap
//	imul si, 4
//	add ebp, esi
//	pop esi
	mov ebp, [steepslopefoundationmap+ebp*4]
	lea ebx,[ebp+989]	
	sub ebp,14+1				// 14 sprites in TRG1, offsets counted from 1 up
	jb .havenoext
	lea ebx,[edi+ebp]
.havenoext:
	mov edi, esi
	add dl, 8
	call [addsprite]
.nosteepslope2:
	popa
	ret


// Auxiliary: see if tiles in NW and NE directions merge with the current one
// in:	AX,CX = current tile's north corner X,Y
// out:	ESI = bit 0: merges in NW direction, bit 1: merges in NE direction, other bits 0
// preserves: everything else
gettilealtmergemap:
	push edx

	testflags custombridgeheads
	jnc .notalwaysmerged

	// for custom bridge heads, always merge southern bridge head
	// foundation with bridge

#if 0
	pusha
	call [gettileinfo]
	cmp bl,9 << 3
	clc
	jne .notbridgehead
	test word [landscape3 + 2*esi], 3 << 13
	jz .notbridgehead
	stc
.notbridgehead:
	popa
	jnc .notalwaysmerged
#endif
	call locationtoxy
	mov dl,[landscape4(si,1)]
	and dl,0xf0
	cmp dl,0x90
	jne .notalwaysmerged	// not bridge

	mov dl,[landscape5(si,1)]
	mov dh,dl
	and dl,11000000b
	cmp dl,10000000b
	jne .notalwaysmerged	// not bridge head

	test byte [landscape3+2*esi+1], 3 << (13-8)
	jz .notalwaysmerged	// not custom bridge head

	test dh,00100000b
	jz  .notalwaysmerged	// not southern custom bridge head

	mov esi,3	// join bridge head foundations
	pop edx
	ret

.notalwaysmerged:
	push ebp
	xor esi,esi
	mov ebp,addr(getgroundalt)	// in tools.asm

	// NE direction:
	call ebp
	mov bl,dl
	dec eax
	call ebp
	inc eax
	sub dl,bl
	inc edx
	cmp dl,3
	jae .nedone

	push ecx
	add ecx,15	// and the other corner
	call ebp
	mov bh,dl
	dec eax
	call ebp
	inc eax
	pop ecx
	sub dl,bh
	inc edx
	cmp dl,3

.nedone:
	rcl esi,1

	// NW direction:
	// (BL still holds our north corner's altitude)
	dec ecx
	call ebp
	inc ecx
	sub dl,bl
	inc edx
	cmp dl,3
	jae .nwdone

	push eax
	add eax,15	// and the other corner
	call ebp
	mov bh,dl
	dec ecx
	call ebp
	inc ecx
	pop eax
	sub dl,bh
	inc edx
	cmp dl,3

.nwdone:
	rcl esi,1
	pop ebp
	pop edx
	ret


var alwaysraiseland, db 0
// Auxiliary: get foundation type for a railway tile
// in:	DI = corner map as returned by gettileinfo
//	DH = track map
// out:	EDI = corner map, possibly faked (i.e. as seen with foundation)
//	EBP = foundation type/direction (0 if no foundation)
//	ZF set = no foundation
//	CF set = inclined foundation
//	bit 6 of DH cleared
// preserves:everything else
global gettrackfoundationtype
gettrackfoundationtype:
	push edx
	cmp byte [alwaysraiseland], 0
	jz .normal
	mov dh, 0xff
.normal:
	and dh,0xbf
	push ebx
	push ecx
	mov ebx,railslopenormal-1
	mov cx,0x201
	jmp short getroadfoundationtype.common

// Same for a road tile (DH = road piece map; preserved)
getroadfoundationtype:
	cmp dh, 0   //check for tram tracks...
	jne 	.dontInsertTramTracks0
	mov	dh, [landscape3+esi*2]
	
.dontInsertTramTracks0:
	push edx
	cmp byte [alwaysraiseland], 0
	jz .normal
	mov dh, 0x0f
.normal:
	push ebx
	push ecx
	mov ebx,roadslopenormal-1
	mov cx,0x50a

.common:
	cmp	dh, 0   //check for tram tracks...
	jnz 	.dontInsertTramTracks
	mov	dh, [landscape3+esi*2]
	
.dontInsertTramTracks:
	call auxisinclinedfoundation
	jna .done

	// no inclined foundation, check for a levelled one
	cmp [ebx+edi],dh
	je .done

	// ZF=0: levelled foundation
	xchg ebp,edi
	clc

.done:
	pop ecx
	pop ebx
	pop edx
	ret

// Similar for a bridge ending
// in:	DI = corner map as returned by gettileinfo
//	DH = L5 byte (only bit 0 checked)
// out:	EDI = corner map, possibly faked (i.e. as seen with foundation)
//	EBP = foundation type/direction (0 if no foundation)
//	ZF set = no foundation
//	CF set = inclined foundation
// preserves:everything else
global getbridgefoundationtype
getbridgefoundationtype:
	push ecx
	push edx
	cmp byte [alwaysraiseland], 1
	jz .usetrack
	
	and dh,1
	mov cx,0x100
	call auxisinclinedfoundation
	jna .done

	// no inclined foundation, check for a levelled one
	// slopes for which it can happen are the opposite of those for inclined
	push edi
	xor edi,byte 0xf
	call auxisinclinedfoundation
	pop edi
	jnc .nolevelled

	mov ebp,edi
	xor edi,edi

.nolevelled:
	test ebp,ebp

.done:
	pop edx
	pop ecx
	ret

.usetrack:
	pop edx
	pop ecx
	jmp gettrackfoundationtype
	ret

// in DI=corner map; CL,CH=values of DH for X,Y incl. foundation, resp.
// return CF set if inclined foundation, then EDI=fake slope, EBP=foundation type, ZF clear
// else CF clear, EDI=actual slope, EBP=0, ZF clear if (EDI & 0xF)<>0
auxisinclinedfoundation:
	xchg eax,edi
	xor ebp,ebp
	movzx eax,al

	cmp al,1
	je .chkincl

	inc ebp
	cmp al,2
	je .chkincl

	inc ebp
	cmp al,4
	je .chkincl

	inc ebp
	cmp al,8
	je .chkincl

.noincl:
	xor ebp,ebp
	test al,0xf	// CF=0

.done:
	xchg eax,edi
	ret

.chkincl:
	// check for inclined foundation
	shl ebp,1
	cmp dh,cl
	je .incl

	inc ebp
	cmp dh,ch
	jne .noincl

.incl:
	mov al,[foundationinclinetypes+ebp]
	//add ebp,15			// guarantees ZF clear
	shl ebp, 8
	bts ebp, 7
	test esp, esp	// set zf flag to clear 
	
	stc
	jmp .done


// Correct the lowest corner altitude of a station if it's on a sloped land
// in:	AX,CX,DL,DH,DI as returned by gettileinfo
//	EBX = XY index
//	SI = 0x28
// out:	DL = corrected altitude
// safe:ESI,EBP
global correctstationalt
correctstationalt:
	test di,di
	jz .done
	
	// Busstops
	cmp dh, 0x53
	je .slope
	cmp dh, 0x54
	je .slope

	cmp dh,0x4b
	jae .done
.slope:
	add dl,8
.done:
	jmp near $
ovar .oldfnoffset,-4,$,correctstationalt


// Display the first (ground) sprite of a station tile;
// if on a slope we add a foundation sprite and then add the ground sprite relative to it
// in:	AX,CX,DH,DI as returned by gettileinfo
//	DL = corrected altitude
//	EBX = sprite
// safe:ESI,EDI,EBP
global displstationgroundsprite
displstationgroundsprite:
	test di,di
	jz .noslope
	cmp dh,0x4b
	jb .slope

	// Busstops
	cmp dh, 0x53
	je .slope
	cmp dh, 0x54
	je .slope

.noslope:
	call [addgroundsprite]
	ret

.slope:
	mov ebp,edi

global displbasewithfoundation
displbasewithfoundation:
    cmp	dh, 0
    jne .dontInsertTracks
    mov dh, [landscape3+esi*2]
.dontInsertTracks:
	call displayfoundation

displfoundationrelsprite:
	pusha
	mov ax,0x1f
	xor ecx,ecx
	inc ecx
//	cmp ebp,14
//	jbe .relok
	bt ebp, 7
	jnc .relok
	add ecx,8

.relok:
    mov     di, 6
    mov     si, 6
    mov     dh, 10
	call [addrelsprite]
	popa
	ret


// Display the ground sprite below a lighthouse or transmitter;
// if on a slope we add a foundation sprite and then add the ground sprite relative to it
// in:	AX,CX,DL,DH,DI as returned by gettileinfo
//	EBX = tile XY
// safe:EBX,ESI,EDI,EBP
global displlighthouseground
displlighthouseground:
	mov bx,3962
	// fallthrough to displhqgroundsprite

// Display the first (ground) sprite of a company HQ;
// if on a slope we add a foundation sprite and then add the ground sprite relative to it
// in:	AX,CX,DL = tile X,Y,Z
//	DI = corner map from gettileinfo
//	DH = L5 byte & 0x7F
//	EBX = sprite
//	EBP -> TTD's depot sprite table
// safe:ESI,EDI,EBP
global displhqgroundsprite
displhqgroundsprite:
	mov ebp,edi
	// fallthrough to displdepotgroundsprite

// Display the first (ground) sprite of a railway or road depot;
// if on a slope we add a foundation sprite and then add the ground sprite relative to it
// in:	AX,CX,DL,DH as returned by gettileinfo
//	EBX = sprite
//	EDI -> TTD's depot sprite table
//	BP = corner map from gettileinfo (see codefragment newbegindrawdepot)
// safe:ESI,EBP
global displdepotgroundsprite
displdepotgroundsprite:
	test bp,bp
	jz displstationgroundsprite.noslope
	add dl,8
	jmp displbasewithfoundation


// Display the first (ground) sprite of railway or road;
// if necessary we add a foundation sprite and then add the ground sprite relative to it
// common registers:
// in:	AX,CX,DL,DI,ESI as returned by gettileinfo
//	EBX = sprite
//	EBP = 0 if normal, otherwise foundation type (then DL and EDI are faked)
//	(see initrailspritedispl/initroadspritedispl)
// safe:BX
global displrailroadgroundsprite
displrailroadgroundsprite:
	test ebp,ebp
	jnz displbasewithfoundation

// Display successive ground sprites of railway
// in:	AX,CX,DL = X,Y,Z location
//	EBX = sprite+flags
//	EBP = 0 if normal, otherwise foundation type (then DL and EDI are faked)
// safe:BX
global displrailnextsprite
displrailnextsprite:
	test ebp,ebp
	jnz displfoundationrelsprite

addgroundsprite_preserveebp:
	push ebp
	call [addgroundsprite]
	pop ebp
	ret


// Initialize display of the ground sprites of railway
// in:	AX,CX,DL,DI as returned by gettileinfo
//	DH = track map
//	EBX=ESI = tile XY
//	ZF set as per OR DI,DI
// out:	EBP = 0 if normal, otherwise saved corner map (then DL and EDI are faked)
//	ZF set = use TTD's flat-land sprites, clear = use TTD's sloped sprites
//	high word of EDI cleared
// safe:EBX
global initrailspritedispl
initrailspritedispl:
	mov ebp,addr(gettrackfoundationtype)
	jmp short initroadspritedispl.getfnd

// Similar for road
// in:	AX,CX,DL,DH,DI as returned by gettileinfo
//	BX = tile XY
// out:	EBP = 0 if normal, otherwise saved corner map (then DL and EDI are faked)
//	ZF set = use TTD's flat-land sprites, clear = use TTD's sloped sprites
//	high word of EDI cleared
//	ESI = tile XY
// safe:EBX
global initroadspritedispl
initroadspritedispl:
//    cmp dh,0
//    jnz .skipInsertingTramTracks
//    mov dh, [landscape3+esi*2]
//.skipInsertingTramTracks:
	movzx esi,bx			// the overwritten part
	mov ebp,addr(getroadfoundationtype)

.getfnd:
	call ebp
	jbe .normal
	bt ebp, 4	//steep slope support
	jnc .nosteepslope
	add dl,8
.nosteepslope:
	add dl,8
.normal:
	or edi,edi
	ret


// Display the land sprite under a bridge ending;
// if on a slope we add a foundation sprite and then add the ground sprites relative to it
// part 3: display the last sprite of a bridge ending
// (placed before the other parts to make a jump short)
// in:	AX,CX,DL = X,Y,Z of the north corner
//	EBX = sprite
//	EDI = slope type (faked if EBP<>0)
//	EBP = foundation type (0 if no foundation)
global displbridgeendsprite
displbridgeendsprite:
	test edi,edi
	jz .normal			// don't add the ramp relative, it wouldn't sort correctly
	test ebp,ebp
	jnz displfoundationrelsprite

.normal:
	mov di,2
	mov esi,edi
	mov dh,7
	call [addsprite]
	ret

// part 1: getting the offset of bridge ending sprite in ESI
// (runindex call patched at CS:153A94)
// out:	EBP = foundation type (0 if no foundation)
//	DL,EDI faked if EBP<>0
//	ZF set = flat, clear = ramp
global isbridgeendingramp
isbridgeendingramp:
	mov esi,[esi+0x18]		// overwritten
	mov ebp,addr(getbridgefoundationtype)
	jmp short initroadspritedispl.getfnd

// part 2: display the ending sprite
// in:	AX,CX = location
//	DL = altitude (possibly corrected, see above)
//	DH = L5 byte
//	EDI = slope (possibly faked)
//	EBX = bridge ending sprite
//	EBP = foundation type (0 if no foundation)
//	ZF set if on grass, clear if on snow/desert
// safe:ESI
global displbridgeendgroundsprite
displbridgeendgroundsprite:
	push ebx
	mov bx,3981
	jz .spritebaseok
	mov bx,4550

.spritebaseok:
	add ebx,edi
	or ebp,ebp
	jnz near .usefoundation

	push eax

	push edi
	shl edi, 1
	and edi, 0xFFFF
	movsx eax, word [coastdirections+edi]
	pop edi
	cmp ax, 1234h
	je .drawcoast
	cmp ax, 0
	je .nocoast
	add eax, [saved_ebx]
	cmp eax,0xffff
	ja .nocoast	// beyond map

	cmp byte [landscape4(ax,1)], 60h
	je .drawcoast
	cmp byte [landscape4(ax,1)], 90h
	je .testcoast
	jmp .nocoast
	
.testcoast:
	test byte [landscape5(ax,1)], 20h
	jnz .nocoast
	test byte [landscape5(ax,1)], 19h
	jz .nocoast
	test word [landscape3 + 2*eax], 1
	jz .drawcoast
	jmp .nocoast

.drawcoast:
	push edi
	shl edi, 1
	and edi, 0xFFFF
	add edi, [waterbanksprites]
	mov bx, [edi]
	pop edi
	jmp .nocoast

.nocoast:
	pop eax
	call addgroundsprite_preserveebp
	pop ebx
	ret

.usefoundation:
	call displbasewithfoundation
	pop ebx
	ret


// Fix sprite sorting at southern bridge ends
// (patched at CS:153C34, see TTDMEM.IDB for details)
// (may not work very well with modified sets)
global displbridgelastmid2ndpart
displbridgelastmid2ndpart:
	call locationtoxy
	inc esi
	test byte [esp+4],0x10		// check direction
	jz .chknexttile
	add si,0xff

.chknexttile:
	mov dh,[landscape5(si)]
	and dh,0xe0
	cmp dh,0xa0			// southern ending?
	jne .done
	inc edi				// yes, increase 'object length'

.done:
	// do the overwritten part
	xor esi,esi
	inc esi
	mov dh,0x28
	ret


// Correct the altitude of an exact point on a station tile
// in:	AX,CX = X,Y
//	DL = ground altitude (as on bare land)
//	DH = tile type from L5
//	EDI = (bits 4..1) corner height map, shifted 1 bit to the left
// out:	DL = corrected altitude
//	DH = 0
// safe:EBX,ESI,EDI,EBP
global correctstationexactalt,correctexactalt.getfoundationtype
correctstationexactalt:
	// Busstops
	cmp dh, 0x53
	je correctexactalt.chkslope
	cmp dh, 0x54
	je correctexactalt.chkslope

	cmp dh,0x4b
	jb correctexactalt.chkslope

correctexactalt.done:
	xor dh,dh
	ret

// Same for a Class A (special objects) tile
global correctspecialexactalt
correctspecialexactalt:
	cmp dh,3			// leave company-owned land alone
	jne correctexactalt.chkslope
	jmp correctexactalt.done

// Same for a railway tile
global correctrailexactalt
correctrailexactalt:
	or dh,dh
	jns .track

	test dh,0x40
	jnz correctexactalt.chkslope
	jmp correctexactalt.done	// don't know what's this, but it's not a depot for sure

.track:
	// steep slope support
	bt word [calcexactgroundcornercopy], 4	// (not altered corner map)
	jnc correctrailexactalt.trackdone
	add dl, 4	// fake a bit the bareland height, so all stuff works right
	nop
	nop
.trackdone:
	mov ebp,addr(gettrackfoundationtype)

// entry point for variable foundation type code
// in:	see above, plus:
//	EBP -> foundation type function
// out:	EBP = shifted corner map (copy of in:EDI)
//	EDI = fake slope
//	DL = corrected altitude
//	DH = 0
// uses:EBX,ESI
correctexactalt.getfoundationtype:
	push edi
	shr edi,1
	call ebp
	pop ebp
	jne correctexactalt.fix
	jmp correctexactalt.done

global correctexactalt.chkslope
correctexactalt.chkslope:		// jump here if slope means a level foundation
	test edi,edi
	jz correctexactalt.done

	mov ebp,edi
	xor edi,edi			// (no inclined foundations)

correctexactalt.fix:
	// now: EBP = shifted corner map (as in EDI on entry)
	// EDI = fake slope

	// restore the lowest corner altitude:
	// call TTD's subroutine again with DL=0
	// to figure out the amount added by TTD
	mov esi,[groundaltsubroutines]
	push edx
	xor dl,dl			// CF=0, no steep slopes
	call [esi+ebp*2]
	mov bl,dl
	pop edx

	// undo TTD's correction
	sub dl,bl			// hmm... should never underflow, hence CF=0

	// now call another TTD's subroutine
	// to correct the altitude for our 'fake slope'
	call [esi+edi*4]

	// if EDI=0 (level foundation) add one height level
	test edi,edi
	jnz correctexactalt.done
	add dl,8
	jmp correctexactalt.done

// Same for a road tile
global correctroadexactalt
correctroadexactalt:
	test dh,0x20			// depot?
	jnz correctexactalt.chkslope
	test dh,0xf0
	jnz correctexactalt.done	// not a regular road

	mov ebp,addr(getroadfoundationtype)
	jmp correctexactalt.getfoundationtype

// Similar for bridge endings
// in:	AX,CX = X,Y
//	DL = ground altitude (as on bare land)
//	DH = tile type from L5
//	EDI = (bits 4..1) corner height map, shifted 1 bit to the left
// out:	DL = partially corrected altitude (to take account for a possible foundation)
//	EDI faked if necessary
// safe:EBX,ESI,EBP
global correctbridgeendexactalt
correctbridgeendexactalt:
	js .isbridge		// replicate the overwritten test (reversed)
	pop ebp			// originally success means jump to a RET
	ret

.isbridge:
	test dh,0x40
	jnz near bridgemiddlezcorrectslope

	pusha
	and al, 0xF0
	and cl, 0xF0
	call [gettileinfo]
	cmp dh, 0
	jnz .dontInsertTramTracks
	mov dh, byte [landscape3 + 2*esi]
	
.dontInsertTramTracks:
	test word [landscape3 + 2*esi], 3 << 13
	popa
	jnz .bridgeend

	push edx
	mov ebp,addr(getbridgefoundationtype)
	call correctexactalt.getfoundationtype
	pop ebx
	mov dh,bh

	mov byte [alwaysraiseland],0

.normal:
	shl edi,1

.done:
	ret

.bridgeend:
	mov byte [alwaysraiseland], 1
	push edx
	mov ebp,addr(getbridgefoundationtype)
	call correctexactalt.getfoundationtype
	pop ebx
	mov byte [alwaysraiseland],0
	xor dh, dh
	pop ebp
	ret
					

// Called to check whether land under airport is flat
// in:	AX,CX,DL,DH,DI,ESI as returned by gettileinfo for the currently checked tile
//	BL = construction flags
//	BH = airport type
//	on stack:
//		WORD:	saved XY of currently checked tile
//		WORD:	number of tiles to check (low byte=X, high byte=Y)
//		WORD:	saved BX (see above)
//		WORD:	saved XY of first tile in currently checked row
//		WORD:	saved number of tiles to check at the start of a row
//		WORD:	saved dimensions of the airport
// out:	ZF set = square OK
// safe:ESI,EBP,EDX,DI
global chkairportflatland
chkairportflatland:
	mov ebp,esp
	push eax
	mov al,0
	mov dx,[ebp+4+2]
	cmp dl,1
	jne .notlastx
	or al,0011b
.notlastx:
	cmp dh,1
	jne .notlasty
	or al,0110b
.notlasty:
	cmp dl,[ebp+4+10]
	jne .notfirstx
	or al,1100b
.notfirstx:
	cmp dh,[ebp+4+11]
	jne .notfirsty
	or al,1001b
.notfirsty:
	or eax,edi
	xor al,1111b
	pop eax
	jz stationallowslope

stationnotallowslope:
	// the usual check (overwritten)
	test di,0xf
	ret

// Similar for bus or lorry station
// (stack setup different; BH = direction)
global chkbuslorrystationflatland
chkbuslorrystationflatland:
	// AI are excluded, they wouldn't know how to connect these stations
	call isrealhumanplayer
	jnz stationnotallowslope
	cmp bh, 3
	ja stationbusstopcheck

	xchg cl,bh
	mov dl,1001100b
	shr edx,cl
	xchg bh,cl
	and edx,byte 0xf
	test edi,edx

stationallowslopeifnz:
	jz stationnotallowslope

stationallowslope:
	// steep slopes not allowed
	test di,0x10
	jnz .done

	// do we actually have slope?
	test di,di
	jz .done

	// we're building on a slope -- increase cost
	mov esi,[stationbuildcostptr]
	mov ebp,[raiselowercost]
	add [esi],ebp
	cmp eax,eax			// force ZF=1

.done:
	ret
stationbusstopcheck:
	push ebx
	shr bx, 8
	and ebx, 0xf
	sub bl, 0x0C // well the directions are a bit screwed here ?!?
	bt [busstopfoundation+ebx*2],di
	pop ebx
	jc stationallowslope
	jmp stationnotallowslope

// Similar for railway station
// in:	AX,CX,DL,DH,DI,ESI as returned by gettileinfo for the currently checked tile
//	BL = construction flags
//	BH = direction (0=X, 1=Y)
//	on stack:
//		WORD:	saved XY of currently checked tile
//		WORD:	number of tiles to check (low byte=X, high byte=Y)
//		WORD:	saved BX (see above)
//		WORD:	saved XY of first tile in currently checked row
//		WORD:	saved number of tiles to check at the start of a row
//		WORD:	saved dimensions of the station (low byte=length, high byte=number of platforms)
//		WORD:	saved Y of the north corner
//		WORD:	saved X of the north corner
// out:	ZF set = square OK
// safe:ESI,EBP,EDX,DI
global chkrailstationflatland
chkrailstationflatland:
	call isrealhumanplayer
	jnz stationnotallowslope

	mov ebp,esp
	test di,di
	jz .chkalt
	add dl,8

.chkalt:
	cmp ax,[ebp+4+14]
	jne .notfirst
	cmp cx,[ebp+4+12]
	jne .notfirst
	mov [railstationaltitude],dl

.notfirst:
	cmp [railstationaltitude],dl
	jne stationallowslope.done

	xchg eax,edi
	mov dx,[ebp+4+2]
	or bh,bh
	jnz .ydir

	test al,3
	jnz .lastxok
	cmp dl,1
	je .bailout

.lastxok:
	test al,12

.isfirst:
	jnz .bailout
	cmp dl,[ebp+4+10]

.bailout:
	xchg eax,edi
	jmp stationallowslopeifnz

.ydir:
	test al,6
	jnz .lastyok
	cmp dh,1
	je .bailout

.lastyok:
	mov dl,dh
	test al,9
	jmp .isfirst

uvarb railstationaltitude

// Similar for a railway or road depot
// in:	AX,CX,DL,DH,DI,ESI as returned by gettileinfo for the currently checked square
//	BL = construction flags
//	BH = direction of depot
// out:	DI = 0 if OK, nonzero if bad
// safe:ESI,EBP,EDX
global chkdepotflatland
chkdepotflatland:
	mov word [operrormsg2],7		// overwritten
	mov [depotbuildslopemap],di

	call isrealhumanplayer
	jnz .done

	mov word [operrormsg2],0x1000	// "Land sloped in wrong direction"
	xchg cl,bh
	mov dl,1001100b
	shr edx,cl
	xchg bh,cl
	and edx,byte 0xf
	test edi,edx
	jz .done

	// direction OK, pretend there's no slope (unless it's steep)
	and edi,byte ~0xf

.done:
	ret

uvarw depotbuildslopemap

// Similar for a company HQ
// Part 1: initialize our variable
global initchkhqflatland
initchkhqflatland:
	mov dword [companyhqcheckslope],0x08040102
	jmp near $
ovar .oldfnoffset,-4,$,initchkhqflatland

uvard companyhqcheckslope

// Part 2: check slope for the current tile
// (4 tiles checked in sequence: XY=00,01,10,11; stops on failure)
// in:	AX,CX,DL,DH,DI,ESI from gettileinfo
//	BL = constr. flags
// out:	ZF set = can build, clear = nope
// safe:everything except AX,BX,CX
global chkhqflatland
chkhqflatland:
	mov edx,edi
	test dl,0x10			// steep slopes are straight out
	jnz .done

	mov esi,companyhqcheckslope
	mov dh,[esi]
	shr dword [esi],8

	test dl,dl			// flat land is OK
	jz .done

	and dl,dh
	cmp dl,dh

.done:
	ret

// Similar when placing a lighthouse or transmitter
// in the scenario editor
// in:	AX,BX,CX,DX,DI,ESI from gettileinfo
// out:	ZF set = can place, clear = nope
// safe:EDX,?
global chklighthouseflatland
chklighthouseflatland:
	test bl,bl
	je .land_ok
	cmp bl,6*8
	jne .done
	cmp dh,1
	jne .done

.land_ok:
	test di,0x10

.done:
	ret


// Check if a road is to be built on foundation
// (note: if we get here we know the land is sloped)
// Part 1: check if there's already a valid sloped road,
// in which case we're not allowed to 'convert' it to levelled
// in:	AX,CX = tile X,Y location
//	DI = corner map as returned by gettileinfo
//	BL = construction flags
//	BH = piece(s) to place
// out:	on return (which may or may not lead to part 2):
//		ESI = nonzero if there is already a valid sloped road or the slope is steep
//	on skip:
//		BL,DH from gettileinfo
//		EDI = foundation cost
//		previous BX (see above) pushed on stack
//	on fail: EBX = 0x80000000
// safe:EDX,ESI,EBP
//	(also EDI on fail)
global chkbuildroadslope
chkbuildroadslope:
	cmp	byte [landscape3+esi*2], 0   //check for tram tracks...
	jz 	.dontInsertTramTracks
	mov	dh, [landscape3+esi*2]

.dontInsertTramTracks:
	mov word [operrormsg2],0x1800	// "Land sloped in wrong direction for road"
					// (overwritten by runindex call)
	mov esi,edi			// cheap way to ensure ESI<>0
	cmp di,0x10
	jae .back			// it'll trigger part 2

	push ebx
	xor edi,edi			// this ensures EDI<31:16>=0 for the subsequent code
	call [gettileinfo]
	
	cmp	byte [landscape3+esi*2], 0   //check for tram tracks...
	jz 	.dontInsertTramTracks2
	mov	dh, [landscape3+esi*2]
	
.dontInsertTramTracks2:
	xor esi,esi
	cmp bl,0x10
	pop ebx
	jnz .back
	test dh,0xf0
	jnz .back

	inc esi				// have road already
	push edi
	call getroadfoundationtype	// checking existing combination
	ja .haveit
	pop ebp				// dummy POP to adjust stack (use returned EDI)

.back:
	ret

.haveit:
	// there's already a levelled road here
	pop edi
	pop ebp				// remove the return address from stack
	jmp short buildroadslopeext.chk

// Part 2: cannot place 'normal' road (slope/direction mismatch),
// check if it can be placed on foundation
// in: as in point 1, except ESI = nonzero if there is already a valid sloped road or the slope is steep
// note: jumped to, not called
global buildroadslopeext
buildroadslopeext:
	test esi,esi
	jnz .fail			// can't turn sloped/inclined road into levelled,
					// or if steep slope then can't build at all
	// AIs are excluded, they get very confused by this feature
	call isrealhumanplayer
	jnz .fail

.chk:
	// check if this combination of road is possible on this slope
	mov dl,[roadslopelevelled+edi-1]
	and dl,bh
	cmp dl,bh
	je .ok

	// so perhaps can build it as inclined?
	test esi,esi
	jnz .fail			// already levelled, can't turn into inclined either

	test bh,5
	jz .noincl1
	or bh,5

.noincl1:
	test bh,0xa
	jz .noincl2
	or bh,0xa

.noincl2:
	mov dh,bh
	call getroadfoundationtype	// checking proposed combination
	jc .ok

.fail:
	mov ebx,0x80000000
	ret

.ok:
	push bx

	// check if there's already road (in which case we don't add the foundation cost)
	call [gettileinfo]
	
	cmp	byte [landscape3+esi*2], 0   //check for tram tracks...
	jz 	.dontInsertTramTracks3
	mov	dh, [landscape3+esi*2]
.dontInsertTramTracks3:
	
	xor edi,edi
	cmp bl,0x10
	jz .skip
	mov edi,[raiselowercost]

.skip:
	jmp near $
ovar .goodexit,-4,$,buildroadslopeext


// Fixed removal of road on sloped land
// in:	AX,CX,DH,DI,ESI from gettileinfo (DI<>0)
//	BL = construction flags
//	BH = piece(s) to remove
// out:	ZF set if sloped, clear if levelled (i.e. on foundation)
// safe:EDI,EBP
global removeroadonslope
removeroadonslope:
	cmp	byte [curplayerctrlkey], 0
	jz	.dontLoadTramArray
	mov	byte dh, [landscape3+esi*2]
.dontLoadTramArray:
	//mov byte [landscape3+esi*2], 0   //TrAsH! tram tracks...

	call getroadfoundationtype
	ja .done

	// regular sloped road, do the overwritten part
	mov dl,bh
	and dl,0xc
	shr dl,2
	cmp edx,edx			// set ZF

.done:
	ret


// Check if we can build this piece of track on this tile
// in:	AX,CX = tile X,Y location
//	EDI = corner map from gettileinfo
//	BL = construction flags
//	BH = piece to build
// out:	ZF set = impossible combination
//	EBP = additional construction cost if ZF clear
// safe:everything except AX,BX,CX
// note:already checked if DI:4 is zero
global canbuildtrackslope
canbuildtrackslope:
	xor ebp,ebp
	test edi,edi
	jnz .slope			// can build all combinations on flat land

.canbuild:
	or bh,bh
	ret

.slope:
	push ebx
	call [gettileinfo]
	cmp bl,8
	pop ebx
	jz .havetrack

	// no track built yet
	mov dh,bh

.checkany:
	// check if what we're about to build is going to need levelling
	push edi
	call gettrackfoundationtype	// checking proposed combination
	pop edi
	jz .canbuild			// (if ZF=0 then EBP=0)
	rcl ebp,1			// save CF

	// yes -- exclude the AI
	call isrealhumanplayer
	jnz .nope

	// add foundation cost to the build costs
	shr ebp,1			// restore CF
	mov ebp,[raiselowercost]
	jc .canbuild

.checklevelled:
	// check if this combination of track is really possible on this slope
	mov dl,[railslopelevelled+edi-1]
	and dl,dh
	cmp dl,dh

.canbuildifeq:
	jz .canbuild

.nope:
	cmp bh,bh
	ret

.havetrack:
	// track already there, don't add levelling costs if already on foundation
	and dh,0x3f
	pusha
	call gettrackfoundationtype	// checking existing combination
	popa
	jc .haveinclined

	pushf
	or dh,bh
	popf
	jnz .checklevelled
	jmp .checkany

.haveinclined:
	// have track on inclined foundation, can't add any other directions
	cmp bh,dh
	jmp .canbuildifeq


// Check if we can start or end a bridge here
// (already checked if it's possible without a foundation)
// in:	AX,CX,DL,DH,DI,ESI from gettileinfo
//	EBX = direction: 0=X, 1=Y; +2 if the southern end (see codefragment newcanstartendbridgehere)
//	on stack:
//		WORD:	construction flags
//		DWORD:	cost so far
//		WORD:	southern end XY
//		WORD:	northern end XY
// out:	CF set = OK, clear = fail (in this case pop stack values above into BX,EBP,DI,DX)
// safe:on failure: EAX,EBX,ECX
//	on success: EBX,DX,DI,EBP
global canstartendbridgehere
canstartendbridgehere:
	call isrealhumanplayer
	jnz .fail			// AI excluded

	mov ebp,[raiselowercost]
	add [esp+6],ebp

	cmp di,0x10
	jae .fail

	bt [bridgeendfoundation+ebx*2],di
	jc .done

.fail:
	pop ecx

	// the overwritten part
	pop bx
	pop ebp
	pop di
	pop dx
	mov word [operrormsg2],0x1000	// "Land sloped in wrong direction"

	push ecx
	clc

.done:
	ret


// Check if we can clear a Class 6 (water) tile
// (already checked that it's not a ship depot)
// in:	AX,CX = tile location
//	BL = construction flags
//	DL,DH,DI from gettileinfo
// out:	ZF set if possible, clear if not
// safe:ESI,DL
global canbuildonwater
canbuildonwater:
	mov word [operrormsg2],0x3807	// overwritten
	cmp dh,1
	jnz .normal

	call isrealhumanplayer
	jz .done

.normal:
	test bl,8			// the original check, overwritten

.done:
	ret


// Prevent raising or lowering land with track on foundation
// in:	BX = tile XY
//	AL = L4[BX] & 0xF0
//	ZF set if AL=0x10 (track)
// out:	ZF set = perhaps possible, clear = impossible
//	AL = L5[BX] & 0xBF (only if ZF set)
// safe:AH,ESI,EBP
global canraiselowertrack,canraiselowertrack.done
canraiselowertrack:
	jnz .done

	// the overwritten part
	mov al,[landscape5(bx)]
	and al,0xbf
	js .done			// depots excluded anyway

	pusha
	movzx eax,bl
	shl eax,4
	movzx ecx,bh
	shl ecx,4
	call [gettileinfo]
	call gettrackfoundationtype
	popa

.done:
	ret		// will be replaced with NOP by autoslope so flags aren't changed by feature testing!
	call autoslopechecklandscape
	ret


// Prevent water from flooding 1-piece road tiles
uvarb dontignorehalfroads

// Part 1: if flooding a coast set a variable
global dofloodcoast
dofloodcoast:
	mov byte [dontignorehalfroads],1
	call [actionhandler]
	mov byte [dontignorehalfroads],0
	ret

// Part 2: if the variable is set disable the 1-tile check
// out:	CF set = skip, clear = perform the check
global canalwaysremoveroad
canalwaysremoveroad:
	mov bh,dh			// overwritten by...
	and bh,0xf			// ... runindex call

	neg byte [dontignorehalfroads]
	jc .done

	cmp bh,8			// the original test, overwritten
	clc

.done:
	ret

// Similar for lighthouses and transmitters
// (now that we can place them on coasts in the scenario editor)
// out:	ZF set = can remove, clear = nope
global canalwaysremovespecial
canalwaysremovespecial:
	neg byte [dontignorehalfroads]
	jnz .done
	cmp byte [gamemode],2

.done:
	ret


// Remove track fences if foundation is removed
// in:	AX,CX = tile location
//	BL = construction flags
//	BH = which pieces to remove
//	DH,DI,ESI from gettileinfo
// out:	CF set if BL:0 clear (i.e. don't do it yet), clear otherwise
//	ZF set if no track left after removal
// safe:EDI,EBP
global removetrackfences
removetrackfences:
	test bl,1
	stc
	jz .fin

	pusha
	push edi
	call gettrackfoundationtype
	pop edi
	jz .done

	xor dh,bh
	call gettrackfoundationtype
	jnz .done

	// foundation removed, clear fences, if any
	mov al,[landscape2+esi]
	cmp al,0xc
	jae .done
	cmp al,1
	jbe .done

	mov byte [landscape2+esi],1

.done:
	popa

	xor [landscape5(si,1)],bh	// overwritten

.fin:
	ret

uvard calcexactgroundcornercopy,1,z
global calcexactgroundcornermapcopy
calcexactgroundcornermapcopy:
	and edi, 0xFFFF	// overwritten
	mov [calcexactgroundcornercopy], edi
	ret
