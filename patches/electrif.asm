//
// Electrified railways instead of type=1 (originally monorail) tracks
//

#include <std.inc>
#include <proc.inc>
#include <flags.inc>
#include <textdef.inc>
#include <veh.inc>
#include <grf.inc>

extern addlinkedsprite,addsprite,bridgemiddlecheckifwirefit
extern bridgemiddlezcorrectforpylonswires,getbridgefoundationtype
extern getnewstationsprite,gettileinfo,gettrackfoundationtype
extern invalidatehandle,isengine,locationtoxy,patchflags,stationidgrfmap
extern stationnowires,stationpylons,unimaglevmode
extern gettextandtableptrs,gettextintableptr





// Define offsets to various sprite numbers
global elrailsprites.trackicons
struc elrailsprites
	.wires:		resb 3*8// regular full length wires (see below)
	.halfwires:	resb 4	// Wires over half a tile (for tunnels)
	.pylons:	resb 8	// Pylon sprites, 8 sprites for 8 directions
	.trackicons:	resb 4	// Icons for construction menu
	.trackcursors:	resb 4	// Cursors while constructing track
	.tunnelicon:	resb 1
	.tunnelcursor:	resb 1
	.anchor:	resb 2	// Anchors for drawing pylons in screen Z order
endstruc

// arrangement of wires:
// - three sets of eight regular length wires
//   * first set: full length of wire is on single tile
//   * second set and third set: wire spans two tiles, one set for each part
//   Each set has the following wires:
//	0  NE - SW
//	1  NW - SE
//	2  NW - NE or SW - SE (same sprite for both)
//	3  NW - SW or NE - SE (same sprite for both)
//	4  raised NE - SW
//	5  NW - raised SE
//	6  NE - raised SW
//	7  raised NW - SE
// - one set of four half-length wires for tunnel entrances

var catenaryspritebase, dw -1	// First new sprite with catenary graphics

		// number of sprites necessary for correct operation
		// (aborts with wrong version number if it doesn't match)
var numelrailsprites, dd elrailsprites_size

wireheight equ 10		// how high wires are drawn above the ground (landscape Z offset)


// get effective track type for various functions in this module
// function: EAX = {0, 0, unimaglevmode}[EAX & 0xF]
global geteffectivetracktype
geteffectivetracktype:
	and eax,byte 0xF
	jz short .done
	dec eax
	jz short .done
	movzx eax,byte [unimaglevmode]

.done:
	ret
; endp geteffectivetracktype


// Calculate offset to the sprite set for this track type
// (originally BP*82, see below)
// in:	BP = track type
global gettrackspriteset
gettrackspriteset:
	xchg eax,ebp
	call geteffectivetracktype
	xchg eax,ebp

	imul ebp,byte 82

	mov [dword -1],bp		// save it in a temp variable
ovar .tracktypetemp,-4,$,gettrackspriteset

	ret
; endp gettrackspriteset


// and the same for station sprites
// in:	BP{3:0} = track type
//	AX,CX,DL,DH,DI as returned by gettileinfo (but see correctstationalt in slopebld.asm)
// out: BP = offset
// safe:none?
global drawstationtile
drawstationtile:
	testflags electrifiedrail
	jnc getstationspriteset.noelrail

	// draw overhead wires while we're at it
	test bp,1
	jz .donedrawing

	cmp dh,8	// rail station tile?
	jae .donedrawing

	pusha
	xor edi,edi	// railway stations pretend to be flat even if they aren't (see slopebld.asm)

	call locationtoxy
	movzx ebx,byte [landscape3+esi*2+1]
	movzx ebx,byte [stationidgrfmap+ebx*8+stationid.gameid]
	mov bh,[stationpylons+ebx]
	mov bl,dh
	add bl,8
	bt ebx,ebx	// really bt bh,dh
	jnc .nopylons

	push dx		// not dx, need to preserve edx(16:31) from drawpylons
	and dh,1
	inc dh

	// and the pylons
	call drawpylons
	pop dx

.nopylons:
	movzx ebx,byte [landscape3+esi*2+1]
	movzx ebx,byte [stationidgrfmap+ebx*8+stationid.gameid]
	mov bh,[stationnowires+ebx]
	mov bl,dh
	add bl,8
	bt ebx,ebx	// really bt bh,dh
	jc .nowires

	and dh,1
	inc dh
	call displaywires
.nowires:
	popa

.donedrawing:

getstationspriteset:
	xchg eax,ebp
	call geteffectivetracktype
	xchg eax,ebp

.noelrail:
	and ebp,0xf
	imul ebp,byte 82

	testflags newstations
	jc near getnewstationsprite
	ret
; endp getstationspriteset


#if 0
	// now in statspri.asm/getstationselsprites
// called to display the possible orientations of a station
// NOTE: this is also used for other vehicle classes (busses, trucks etc)
//
// in:	AL=track type (0 for non-train stations)
// out:	EAX=new track type * 82
// safe:?
displaystationorient:
	call geteffectivetracktype
	imul eax,82
	ret
; endp displaystationorient
#endif


// Calculate offset to the sprite set for level crossings with this track type
// (originally SI*12, see below)
// in:	SI = track type
//	EBX = sprite for track type 0 crossing
// out: EBX = final sprite
// safe:ESI,EBP
global getcrossingspriteset
getcrossingspriteset:
	xchg eax,esi
	call geteffectivetracktype
	xchg eax,esi
	imul esi,byte 12
	add ebx,esi
	ret
; endp getcrossingspriteset


uvarb dontdisplaywireattunnel,1
// ...and same for tunnel entrances/exits
global gettunnelspriteset
gettunnelspriteset:
	// draw overhead wires and pylons while we're at it
	push ebx
	and ebx,byte 0xF
	dec ebx
	pop ebx
	jnz .donedrawing

	cmp dh,4	// rail tunnel?
	jae .donedrawing

	cmp byte [dontdisplaywireattunnel], 0
	jnz .nowire

	pusha

	movzx ebx,word [catenaryspritebase]
	or bh,bh
	js .nosprites

	movzx esi,dh
	lea ebx,[ebx+esi+elrailsprites.halfwires]

	and esi,1
	lea esi,[flatwires+esi*5]

	add al,[esi+1]
	adc ah,0
	add cl,[esi+2]
	adc ch,0
	add dl,wireheight

	movzx edi,byte [esi+3]
	movzx esi,byte [esi+4]
	mov dh,1
	call [addsprite]

	popa
.nowire:
	pusha

	call makesingleexitmap
	mov dh,bl
	or dh,0x40	// mark as containing exit map, not track layout

	// and the pylons
	call drawpylons_makeesi

.nosprites:
	popa

.donedrawing:
	xchg eax,ebx
	call geteffectivetracktype
	xchg eax,ebx
	shl ebx,3			// EBX *= 8
	ret
; endp gettunnelspriteset


// ...and same for bridges
global getbridgespriteset
getbridgespriteset:
	// again, draw wires while we're at it
	test si,1
	jz .donedrawing
	pusha

	test dh,0x40
	jnz .raised
	call getbridgefoundationtype
	jbe .notlevelled
	add dl,8
.notlevelled:
	or edi,edi
	jnz .raised

	mov di,6
	test dh,1
	jnz .nw_se
	mov di,3
.nw_se:
	test dh,0x20
	jz .setlayout
	xor di,byte 0xF
	jmp short .setlayout

.raised:
	add dl,8
	call bridgemiddlezcorrectforpylonswires
	xor edi,edi

.setlayout:
	and dh,1
	inc dh
	or dh,0x80
	call drawpylons_makeesi
	call displaywires
	popa

.donedrawing:
	xchg eax,esi
	call geteffectivetracktype
	or eax,eax
	jnz short .ok
	dec eax				// 0 -> -1, others unchanged

.ok:
	xchg eax,esi
	ret
; endp getbridgespriteset


// ...and same for tracks under bridges
global getunderbridgespriteset
getunderbridgespriteset:
	test dh,0x40	// middle piece?
	jz .donedrawing
	test dh,0x20	// with something under it?
	jz .donedrawing
	test dh,0x18	// rail?
	jnz .donedrawing
	test si,1
	jz .donedrawing
	pusha
	and dh,1
	inc dh
	xor dh,3
	mov dword [badpylondirs],(1<<3)+(1<<31)
	call drawpylons_makeesi
	//call displaywires	// don't show wires, they'd be at wrong z
	popa

.donedrawing:
	xchg eax,esi
	call geteffectivetracktype
	xchg eax,esi
	imul esi,byte 82
	ret
; endp getunderbridgespriteset


// Check if the track a train is about to drive on has the right type
// Note, do *not* check track type for anything but the engine of a consist
// in:	EBX = DI = tile XY
//	ESI -> engine
// out:	AL = effective track type (compared then with veh.tracktype)
// safe:EAX,EBX
global istrackrighttype,istrackrighttype.tracktypeset
istrackrighttype:
//	mov ah,[esi+veh.tracktype]
	mov al,[landscape3+ebx*2]	// overwritten
.tracktypeset:	// used for enhancetunnels
	mov ah,[esi+veh.tracktype]
	and al,0xF
	cmp ah,0
	jne short .done
	cmp al,1
	jne short .done
	mov al,0
.done:
	mov ebx,[esi+veh.veh2ptr]
	test byte dword [ebx+veh2.flags],1<<VEH2_MIXEDPOWERTRAIN
	jz .candrive

	or byte dword [ebx+veh2.flags],1<<VEH2_MUSTCHECKTILE
	push eax
	mov al,0x0e		// display updated power
	mov bx,[esi+veh.idx]
	call [invalidatehandle]
	pop eax

	// for realistic acceleration, allow driving on unelectrified tile
	// as long as there's at least one electrified engine (not counting
	// powered wagons, because they're the same power type as the engine)
	cmp ah,1
	jne .candrive
	cmp al,1
	jae .candrive

	// ok, electric train on non-electric track, check for other electric
	// engines

	push esi

.nextveh:
	movzx esi,word [esi+veh.nextunitidx]
	cmp si,byte -1
	je .last
	shl esi,7
	add esi,[veharrayptr]

	cmp byte [esi+veh.tracktype],0		// diesel/steam ?
	jne .nextveh
	movzx eax,word [esi+veh.vehtype]
	bt [isengine],eax
	jnc .nextveh

	// is an electric engine, so pretend landscape3 track type is 1
	mov al,1

.last:
	pop esi

.candrive:
	ret
; endp istrackrighttype


// tables of wire sprite base index (into the first set)
// as well as landscape X offset, Y offset, X extent, Y extent

	// first for flat land, one entry for each bit in landscape5
var flatwires
	db 0, 0, 7,15, 1			// NE - SW
	db 1, 7, 0, 1,15			// NW - SE
	db 2, 7, 0, 1, 1			// NW - NE
	db 2,15, 8, 3, 3			// SW - SE
	db 3, 8, 0, 8, 8			// NW - SW
	db 3, 0, 8, 8, 8			// NE - SE

	// for sloped land, one entry for each combination of raised
	// corners, except obviously for no and all corners raised
var slopewires
	db 3, 0, 8, 8, 8	// 1: W 	flat E
	db 2, 7, 0, 1, 1	// 2: S		flat N
	db 6, 0, 7,15, 8	// 3: W + S	NE - raised SW
	db 3, 8, 0, 8, 8	// 4: E		flat W
	db 0, 0, 0, 0, 0	// 5: W + E	(n/a)
	db 5, 7, 0, 8,15	// 6: S + E	NW - raised SE
	db 2,15, 8, 3, 3	// 7: W+S+E	flat S (raised)
	db 2,15, 8, 3, 3	// 8: N		flat S
	db 7, 7, 0, 8,15	// 9: W + N	raised NW - SE
	db 0, 0, 0, 0, 0	// A: S + N	(n/a)
	db 3, 8, 0, 8, 8	// B: W+S+N	flat W (raised)
	db 4, 0, 7,15, 8	// C: E + N	raised NE - SW
	db 2, 7, 0, 1, 1	// D: W+E+N	flat N (raised)
	db 3, 0, 8, 8, 8	// E: S+E+N	flat E (raised)

var sloperailheightadjs
	dw 1111111011101000b	// height adjustment required
	dw 0001001001001000b	// inclined


	// define contents of the pylonoffsets array
struc pylon
	.x:		resb 1	// landscape X,Y,Z offsets of the pylon
	.y:		resb 1
	.z:		resb 1
	.delx:		resb 1	// X,Y extents, either of anchor or pylon
	.dely:		resb 1
	.anchorx:	resb 1	// landscape X,Y,Z offsets and X,Y extents
	.anchory:	resb 1	// of the anchor (used to simplify sorting)
	.anchorz:	resb 1
	.anchortype:	resb 1	// 0: no anchor, 1, 2: anchors with different relx, rely in sprite data
endstruc

var pylonoffsets
	//  X  Y Z DX DY AX AY AZ AT	// num pos orient
	db  4, 0,0, 4,1,  3, 0,0, 1	//  0  NW  SW
	db  4,16,0, 4,1,  3,15,0, 1	//  1  SE  SW
	db 12, 0,0, 4,1, 11, 0,0, 2	//  2  NW  NE
	db 12,16,0, 4,1, 11,15,0, 2	//  3  SE  NE
	db  0, 4,0, 1,4,  0, 3,0, 2	//  4  NE  SE
	db 16, 4,0, 1,4, 15, 3,0, 2	//  5  SW  SE
	db  0,12,0, 1,4,  0,11,0, 1	//  6  NE  NW
	db 16,12,0, 1,4, 15,11,0, 1	//  7  SW  NW

	db 14, 6,0, 4,4, 14, 6,0, 0	//  8  SW  S
	db  6,14,0, 4,4,  6,14,0, 0	//  9  SE  S
	db 10, 2,0, 4,4, 10, 4,0, 0	// 10  NW  N
	db  2,10,0, 4,4,  2,10,0, 0	// 11  NE  N
	db  2, 6,0, 4,4,  2, 6,0, 0	// 12  NE  E
	db 10,14,0, 4,4, 10,14,0, 0	// 13  SE  E
	db  6, 2,0, 4,4,  6, 2,0, 0	// 14  NW  W
	db 14,10,0, 4,4, 14,10,0, 0	// 15  SW  W


	align 2

	// text replacements
	// first new text ID, second text ID to replace
	// ONLY for the last entry may (and must) the second ID be an ourtext() ID

	// make third menu option be for monorail
var monorailtextreplace
	dw 0x100b,0x100c	// construction window title
	dw 0x1016,0x1017	// menu entry
	dw 0x8106,0x8107	// new engine
	dw 0x881d,0x881e	// new waggon
	dw ourtext(monorailwagon),ourtext(maglevwagon)

	// text IDs to save and restore (all TTD IDs in the above list)
varw railtypetextids, 0x100b,0x100c,0x1016,0x1017,0x8106,0x8107,0x881d,0x881e,-1
uvard railtypetextbackup,8	// as many as there are IDs in railtypetextids

global nummonorailtextreplace
nummonorailtextreplace equ (addr($)-monorailtextreplace)/4

	// make second menu option be for electrified rails
var electrtextreplace
	dw statictext(elecrailconstitle),0x100b
	dw statictext(elecrailconsmenu),0x1016
	dw 0x8102,0x8106
	dw 0x881c,0x881d
	dw ourtext(railwaywagon),ourtext(monorailwagon)

global numelectrtextreplace
numelectrtextreplace equ (addr($)-electrtextreplace)/4


struc railexit		// must be 1, 2, 3, 4, 5, 8 or 9 bytes in size
	.deltaindex:	resb 2
	.deltax:	resb 2	// could make this a single byte and use adc ..,0
	.deltay:	resb 2
	.otherdir:	resb 1
	.unused:	resb 1
endstruc

var railexitinfo	// should really use istruc, but this is easier
	dw -0x100,0,-16,8	// NW
	dw -1,-16,0,4		// NE
	dw 1,16,0,2		// SW
	dw 0x100,0,16,1		// SE

uvard badpylondirs	// bit mask of pylon directions that cause glitches


// in:	DH = map of tracks on this tile
// out:	EBX = map of exits from this tile (bits:0=NW,1=NE,2=SW,3=SE)
// preserves: everything else
makerailexitmap:
	xor ebx,ebx
	test dh,010110b
	jz .not0
	inc ebx
.not0:
	test dh,100101b
	jz .not1
	inc ebx			// OR reg8,imm8 = 3 bytes
	inc ebx			// INC reg32 = 1 byte
.not1:
	test dh,011001b
	jz .not2
	or bl,4
.not2:
	test dh,101010b
	jz .not3
	or bl,8
.not3:
	ret

// similar to the above, but for things like depots and tunnels, which
// encode the exit map differently
//
// in:	DH = depot/tunnel type
// out:	EBX = exit map
//	upper two bits of DH are cleared
makesingleexitmap:
	mov ebx,0x8214	// BL for SE, NE, NW, SW
	shl dh,2
	xchg cl,dh
	shr ebx,cl
	xchg cl,dh
	shr dh,2
	and ebx,15
	ret

// count how many rails are connected to each exit
//
// in:	DH = track layout
// out:	BH = 0xddccbbaa
//	where aa=NW, bb=NE, cc=SW, dd=SE
//
makerailexitcount:
	mov bh,0
	test dh,1
	jz .not1
	mov bh,00010100b
.not1:
	test dh,2
	jz .not2
	add bh,01000001b
.not2:
	test dh,4
	jz .not4
	add bh,00000101b
.not4:
	test dh,8
	jz .not8
	add bh,01010000b
.not8:
	test dh,0x10
	jz .not10
	add bh,00010001b
.not10:
	test dh,0x20
	jz .not20
	add bh,01000100b
.not20:
	ret


// in:	AX,CX=X,Y; BL=which direction (1=NW, 2=NE, 4=SW, 8=SE, bit 7 set if on bridge)
// out:	ZF=1, CF=? if the tile has a pylon in this direction (i.e., we do not draw one from our tile)
//	ZF=0, CF=0 if the tile has railroad tracks, but no pylon in this direction
//	ZF=0, CF=1 if the tile has no railroad tracks at all
// uses:EBX,EDX,ESI,EDI,EBP

haspyloninthisdirection.tunnel:
	// new tunnel code support enhancetunnels.
	mov bl,[landscape3+esi*2]
	and bl,0xF
	cmp bl,1
	mov ebx, 0
	jne .tunneluppart

	// was a depot or tunnel, orientation of exit now in dh
	// dh:  0 => +X (SW), 1 => -Y (NW), 2 => -X (NE), 3 => +Y (SE)
	// want ZF if org. bl (now ebp) is this direction
	call makesingleexitmap
.tunneluppart:
	testflags enhancetunnels 
	jnc .tunneldone

	test byte [landscape7+esi], 0x80
	jz .tunneldone

	push ebx
	mov bl,[landscape7+esi]
	and bl,0xF
	cmp bl,1
	pop ebx
	jne .tunneldone

	// (bits:0=NW,1=NE,2=SW,3=SE)
	test dh, 1
	jnz .tunnelotherdir
	or bl, 0110b
	jmp .tunneldone
.tunnelotherdir:
	or bl, 1001b
.tunneldone:
	jmp haspyloninthisdirection.gotexitmap
	//cmp ebx,ebp
	//ret

haspyloninthisdirection:
	movsx ebp,bl
	call [gettileinfo]
	cmp bl,0x10/2
	jnz .maybecrossing

	cmp dh,0xc3
	ja .getrailtype

	sub dh,0xc0
	jb .getrailtype

.checkdepotdir:
	xor dh,2	// sense of direction for depots is opposite to tunnels

.tunnelold:
	mov bl,[landscape3+esi*2]
	and bl,0xF
	cmp bl,1
	jne .norailthere

	// was a depot or tunnel, orientation of exit now in dh
	// dh:  0 => +X (SW), 1 => -Y (NW), 2 => -X (NE), 3 => +Y (SE)
	// want ZF if org. bl (now ebp) is this direction

	call makesingleexitmap
	cmp ebx,ebp
	ret

.getrailtype:
	mov bl,[landscape3+esi*2]

.checkrailtype:
	and ebp,0xF
	and bl,0xF
	cmp bl,1
	jne .norailthere
	call makerailexitmap
.gotexitmap:
	xor ebx,ebp		// reverse test
	test ebx,ebp
	ret

.maybecrossing:
	cmp bl,0x20/2
	jnz .maybestation
	mov bl,dh
	and bl,0xF0
	cmp bl,0x10
	jne .norailthere
	and dh,8
	shr dh,3
	xor dh,1
	inc dh
	mov bl,[landscape3+esi*2+1]
	jmp .checkrailtype

.maybestation:
	cmp bl,0x50/2
	jne .maybebridgeortunnel

	movzx edi,byte [landscape3+esi*2+1]
	movzx edi,byte [stationidgrfmap+edi*8+stationid.gameid]
	movzx ebx,dh
	and dh,1
	inc dh
	bt [stationpylons+edi],ebx
	jc .getrailtype

.norailthere:
	stc
	ret

.maybebridgeortunnel:
	cmp bl,0x90/2
	jne .norailthere

	cmp dh,4
	jb .tunnel

	test dh,0x80
	jz .norailthere

	mov bl,dh
	and bl,0xe8	// bits 3, 5-7 = what's under the bridge

	and dh,3	// bit 0 = direction, bit 1 = set for road bridges
	inc dh

	test bl,0x40	// for bridge heads, both upper and lower part identical
	jz .getrailtype

	test ebp,ebp	// for actual bridge pieces, find out which level we want
	js .wantupper

	cmp bl,0xe0	// 5,6,7 set, 3 clear: rail under bridge
	jz .getrailtype
	jmp .norailthere

.wantupper:
	cmp dh,3
	jae .norailthere	// road bridge

	mov bl,[landscape3+esi*2]
	shr bl,4		// rail type stored in upper four bits
	jmp .checkrailtype
; endp haspyloninthisdirection

// same as above
// but returns ZF=1 if the tile is such that we should even omit our pylon
// this is true for the following configurations:
//	- all depots, which should not have a pylon in front
//	- tubular bridges, which don't have pylons on the middle pieces
//
dontwantpyloninthisdirection:
	movsx ebp,bl
	call [gettileinfo]
	cmp bl,0x10/2
	jne .mightbebridge

	cmp dh,0xc3
	ja .donenz

	sub dh,0xc0
	jnb haspyloninthisdirection.checkdepotdir

.donenz:
	// return NZ if not special
	or bl,1
	ret

.mightbebridge:
	cmp bl,0x90/2
	jne .donenz

	test ebp,ebp
	jns .donenz	// interested in track on lower level (not tubular)

	test dh,2
	jnz .donenz	// road bridge

	test dh,0x40
	jz .donenz	// bridge head

		// middle pieces are 0xa0, 0xa2..0xa5
	mov bl,[landscape2+esi]
	cmp bl,0xa0
	je .donezf
	cmp bl,0xa2
	jb .donenz
	cmp bl,0xa5
	ja .donenz	// not a tubular middle piece

	// return ZF=1
.donezf:
	test al,0
	ret


// draw one pylon at the landscape coords in AX:CX:DL
// on stack:
//	- location and orientation, see pylonoffsets table above
//	- bit value that must be set in EDI for drawing upper altitude
// EBP=catenary base sprite
// saves all registers
draw1pylonflipdir:
	pusha
	movzx ebx,al
	xor bl,cl
	shr bl,3
	and bl,2
	xor bl,[esp+0x28]
	jmp short draw1pylon.afterpush

draw1pylon:
	pusha
	mov ebx,[esp+0x28]

.afterpush:
	bt [badpylondirs],ebx	// does this direction cause glitches?
	jnz .notbaddir

	xor ebx,2		// if so draw it on the other side
				// (that better not cause glitches too!)

.notbaddir:
	test edi,[esp+0x24]
	jz .notelevated
	
	add dl,8
.notelevated:
	lea esi,[pylonoffsets+ebx*pylon_size]
	cmp byte [esi+pylon.anchortype],0
	je .noanchor

	pusha
	add al,[esi+pylon.anchorx]
	adc ah,bh
	add cl,[esi+pylon.anchory]
	adc ch,bh
	add dl,[esi+pylon.anchorz]
	movzx ebx,byte [esi+pylon.anchortype]
	movzx edi,byte [esi+pylon.delx]
	movzx esi,byte [esi+pylon.dely]
	lea ebx,[ebp+ebx-1+elrailsprites.anchor]
	mov dh,13
	call [addsprite]	// insert anchor
	test dh,dh		// can't attach if anchor wasn't drawn
	popa
	jnz .done
	add al,[esi+pylon.x]
	adc ah,bh
	add cl,[esi+pylon.y]
	adc ch,bh
	add dl,[esi+pylon.z]

	shr ebx,1
	lea ebx,[ebp+elrailsprites.pylons+ebx]
	call [addlinkedsprite]
	jmp short .done

.noanchor:
	add al,[esi+pylon.x]
	adc ah,bh
	add cl,[esi+pylon.y]
	adc ch,bh
	add dl,[esi+pylon.z]
	movzx edi,byte [esi+pylon.delx]
	movzx esi,byte [esi+pylon.dely]

	shr ebx,1
	lea ebx,[ebp+elrailsprites.pylons+ebx]
	mov dh,13
	call [addsprite]

.done:
	popa
	ret 8



	// check what horizontal or vertical pylons to draw for a track piece
	//
	// IN:	same as drawpylons
	//	additionally,
	//	BH=tile type for alternating pylons
	//
	// on stack:
	//	0xaabbccdd
	//	0xeeff
	//
	// where
	//	aa=mask for track piece (e.g. 0x20)
	//	bb=mask for other track piece in same dir (e.g. 0x10)
	//	cc=mask for other tracks connected to same exit as aa (e.g. 0x0A)
	//	dd=mask for other tracks for exit bb (e.g. 0x05)
	//	ee=direction for exit 1 (0=NW, 1=NE, 2=SW, 3=SE)
	//	ff=direction for exit 2
	//
	// OUT:	BL=bit mask of exits to draw
	//	bit 0: if any pylon is to be drawn for first exit
	//	bit 1: same for second exit
	//	bit 2: draw horizontal / vertical pylon on first exit
	//	bit 3: same for second exit
	//	bits 4,5: draw regular diagonal pylon on first exit (both bits set for easier ANDing)
	//	bits 6,7: same on second exit


proc checkpylons_horver
	// strategy for e.g. northern track:
	// - draw horizontal pylon on northeast corner if track ends there
	// - draw diagonal pylon on northeast corner if track turns there
	// - draw diagonal pylon on northwest corner if track turns there
	// - draw horizontal pylon on northwest corner if track ends there,
	//   or every other tile if horizontal track continues in that direction
	//
	// the upper 8 bits of ebx are used to keep track of the exits at which
	// we draw non-horizontal pylon.  We'll use the regular drawpylons for these.
	//

	local exits,orgedx

	arg param1,param2

	%define %$track1 %$param1+3
	%define %$track2 %$param1+2
	%define %$other1 %$param1+1
	%define %$other2 %$param1+0

	%define %$dir1 %$param2+1
	%define %$dir2 %$param2+0

	%define %$tiletype %$exits+1

	_enter

	and dword [%$exits],0
	mov [%$tiletype],bh	// for alternating pylons
	mov [%$orgedx],edx

	// --- first exit ---

	// see if track in adjacent tile has right configuration

	movzx edx,byte [%$dir1]
	lea edx,[railexitinfo+edx*railexit_size]

	push esi
	add si,[edx+railexit.deltaindex]
	call geteffectivetracklayout
	pop esi
	mov bl,[edx+railexit.otherdir]
	jnz .drawexit1	// no tracks in next tile

	test bh,[%$other1]	// has other tracks at this exit?
	jnz .drawexit1regular

	test bh,[%$track2]	// has required track?
	jz .drawexit1

.drawexit1if:
	cmp byte [%$tiletype],0
	jne .exit1done

.drawexit1:
	mov bh,4
	or bl,0x80	// always run dontwantpylon..., not haspylon...
	jmp short .checkdrawexit1

.drawexit1regular:
	mov bh,0x30

	// check if the other side has drawn a pylon already
.checkdrawexit1:
	or byte [%$exits],1
	pusha
	add ax,[edx+railexit.deltax]
	add cx,[edx+railexit.deltay]
	mov edx,[%$orgedx]
	and dh,0x80

	cmp bl,4
	jb .sesw1

	and bl,~0x80
	or bl,dh
	call dontwantpyloninthisdirection
	popa
	jz .exit1done
	jmp short .placeregularpylon1

.sesw1:
	or bl,dh
	call haspyloninthisdirection
	popa
	jz .exit1done

.placeregularpylon1:
	or byte [%$exits],bh

.exit1done:

	// --- second exit ---

	movzx edx,byte [%$dir2]
	lea edx,[railexitinfo+edx*railexit_size]

	push esi
	add si,[edx+railexit.deltaindex]
	call geteffectivetracklayout
	pop esi
	mov bl,[edx+railexit.otherdir]
	jnz .drawexit2

	test bh,[%$other2]
	jnz .drawexit2regular

	test bh,[%$track2]		// has southern horizontal track?
	jz .drawexit2


.drawexit2if:
	cmp byte [%$tiletype],1
	jne .exit2done

.drawexit2:
	mov bh,8
	or bl,0x80
	jmp short .checkdrawexit2

.drawexit2regular:
	mov bh,0xc0

	// check if the other side has drawn a pylon already
.checkdrawexit2:
	or byte [%$exits],2
	pusha
	add ax,[edx+railexit.deltax]
	add cx,[edx+railexit.deltay]
	mov edx,[%$orgedx]
	and dh,0x80

	cmp bl,4
	jb .sesw2

	and bl,~0x80
	or bl,dh
	call dontwantpyloninthisdirection
	popa
	jz .exit2done
	jmp short .placeregularpylon2

.sesw2:
	or bl,dh
	call haspyloninthisdirection
	popa
	jz .exit2done

.placeregularpylon2:
	or byte [%$exits],bh

.exit2done:
	mov edx,[%$orgedx]
	mov ebx,[%$exits]	// also restore BH
	_ret


	// check tile at ESI and get effective track layout to find out
	// whether track continues straight
	//
	// in:	ESI=landscape index
	//	DI=reference slope
	// out:	ZF=0 if no tracks present at this tile, or not electrified,
	//		or can't be straight (e.g. slope changes)
	//	ZF=1 and BH=track layout otherwise
	// safe:BL, BH, ESI

geteffectivetracklayout:
	mov bl,[landscape4(si)]
	mov bh,[landscape5(si)]
	and bl,0xf0
	cmp bl,0x10
	je .istrack

	cmp bl,0x20
	je .iscrossing

	cmp bl,0x90
	je near .isbridgeortunnel

	cmp bl,0x50
	je .isstation

.notracks:
	test esi,esi
	_ret 0

.istrack:
	cmp bh,0xbf	// depots don't count as having tracks
	ja .wrongtracks

	test byte [%$track1],3	// for diagonal track need to check the slope
	jz .checkrailtype	// (for other tracks it'll be a curve anyway)

	test bh,3
	jz .checkrailtype

	pusha

.checkslope:
	xchg eax,esi
	movzx ecx,ah
	movzx eax,al
	shl eax,4
	shl ecx,4
	mov ebp,edi
	call [gettileinfo]
	xchg eax,ebp
	cmp bl,8
	jne .nottrackslope
	and dh,0x3f
	call gettrackfoundationtype	// in slopebld.asm

.nottrackslope:
	cmp ax,di
	popa

	jne .wrongtracks

.checkrailtype:
	test byte [landscape3+esi*2],1	// electrified?
	jnz .hastracks

.wrongtracks:
	mov bh,0xff

.hastracks:
	test al,0
	_ret 0

.iscrossing:
	mov bl,bh
	and bl,0xF0
	cmp bl,0x10
	jne .notracks

	test di,di
	jnz .wrongtracks	// crossing doesn't have slope, so we shouldn't either!

	test byte [landscape3+esi*2+1],1	// electrified?
	jz .wrongtracks

	and bh,8
	shr bh,3
	xor bh,1
	inc bh
	jmp .hastracks

.isstation:
	test di,di
	jnz .wrongtracks

	movzx esi,byte [landscape3+esi*2+1]
	movzx esi,byte [stationidgrfmap+esi*8+stationid.gameid]

	push ebx
	mov bl,bh
	mov bh,[stationpylons+esi]
	add bl,8
	bt ebx,ebx		// really bt [stationpylons+esi],bh
	pop ebx
	jnc .wrongtracks

	mov bl,bh
	and bh,1
	inc bh
	jmp .hastracks


.istunnel:		// support for enhancetunnels
	testflags enhancetunnels 
	jnc .wrongtracks

	test byte [landscape7+esi], 0x80
	jz .wrongtracks

	push ebx
	mov bl,[landscape7+esi]
	and bl,0xF
	cmp bl,1
	pop ebx
	jne .wrongtracks

	test bh, 1
	jnz .tunnelotherdir
	mov bh, 10b
	jmp .tunneldone
.tunnelotherdir:
	mov bh, 1b
.tunneldone:
	jmp .hastracks


.isbridgeortunnel:
	cmp bh,4
	jb .istunnel	//.wrongtracks	// tunnels don't count

	test bh,0x80
	jz .notracks

	mov bl,bh
	and bl,0xe8	// bits 3, 5-7 = what's under the bridge

	test bl,0x40	// for bridge heads, both upper and lower part identical
	jz .headpiece

	and bh,3	// bit 0 = direction, bit 1 = set for road bridges
	inc bh

	test di,di
	jnz .wrongtracks

	test byte [%$orgedx+1],0x80	// for actual bridge pieces, find out which level we want
	js .wantupper

	xor bh,3	// track under bridge is in opposite direction

	cmp bl,0xe0	// 5,6,7 set, 3 clear: rail under bridge
	jz .checkrailtype
	jmp .notracks

.wantupper:
	cmp bh,3
	jae .wrongtracks	// road bridge

	test byte [landscape3+esi*2],0x10
	jz .wrongtracks
	jmp .hastracks

.headpiece:
	mov bl,bh
	and bh,3

	cmp bh,3
	jae .wrongtracks

	test byte [%$track1],3	// for diagonal track need to check the slope
	jz .wrongtracks

	inc bh

	pusha

	// find the di bits that need to be set for the head piece to have
	// the correct slope

	cmp bh,1
	je .ne_sw

	// direction of current tile is NW-SE.  Assume bridge piece is
	// oriented the same, otherwise the track won't be considered straight
	// anyway
	//
	test bl,0x20
	jnz .nw

	// bridge is in SE direction
	xor edi,15

.nw:
	// bridge is in NW direction
	//
	// if bits 0+3 (W+N) are set here, the land for the head piece
	// must be flat
	// if here is flat, bits 1+2 must be set there
	// if here has bits 1+2, it can't work

	xor edi,6
	jnz .invertbits

	popa
	jmp .wrongtracks

.invertbits:
	cmp edi,15
	jne .checkslope

	xor edi,15
	jmp .checkslope

.ne_sw:
	test bl,0x20
	jnz .ne

	// bridge is in SW direction
	xor edi,15

.ne:
	// bridge is in NE direction
	//
	// if bits 2+3 (E+N) set here, land at ESI must be flat
	// if flat here, bits 0+1 must be set there
	// if 0+1 set here, it can't work

	xor edi,3
	jnz .invertbits
	popa
	jmp .wrongtracks

endproc checkpylons_horver

	//************************

	// Functions to deal with drawing the straight track
	//
	// in:	same as drawpylons
	//	in addition,
	//	BH=map of exits to ignore
	// out:	BL=map of exits that need regular pylons

	//************************
drawpylons_straight:
	mov bl,0
	push ebx

drawpylons_horizontal:
	mov ebx,esi
	sub bh,bl	// Y-X
	add bl,bl
	add bl,bh	// X+Y
	and bh,2
	and bl,1
	or bh,bl	// for alternating pylons

	test dh,4
	jz .south

	// --- north west and north east exit ---

	param_call checkpylons_horver, 0x04082211, 0x0001

	// see which sprite set to use

	push ebx
	test bh,2
	jz .notonotherside

	dec bh
	or bl,bh

.notonotherside:
	mov bh,[esp+5]
	and bh,3	// collect bits 0&1 for sprite set
	or bl,bh
	shl bh,2
	not bh
	and bh,bl

	test bh,4
	jz .notnorthwest

	push 10
	push 8
	call draw1pylon

	or byte [esp+5],1

.notnorthwest:
	test bh,8
	jz .notnortheast

	push 11
	push 8
	call draw1pylon

	or byte [esp+5],2

.notnortheast:
	and ebx,3
	xor ebx,3	// now ebx=sprite set for 0x04 track piece
	shl ebx,16+2*2
	or edx,ebx	// set appropriate bits in edx
	pop ebx

	shr bl,5
	and bl,3
	or [esp],bl	// exits to draw regular pylons at (1=NW, 2=NE)

.south:
	test dh,8
	jz .doneh

	// --- south west and south east exit ---

	param_call checkpylons_horver, 0x08042112, 0x0203

	push ebx
	test bh,2
	jz .notonotherside2

	dec bh
	or bl,bh

.notonotherside2:
	mov bh,[esp+5]
	shr bh,2	// collect bits 2&3 for sprite set
	or bl,bh
	shl bh,2
	not bh
	and bh,bl

	test bh,4
	jz .notsouthwest

	push 8
	push 2
	call draw1pylon

	or byte [esp+5],4

.notsouthwest:
	test bh,8
	jz .notsoutheast

	push 9
	push 2
	call draw1pylon

	or byte [esp+5],8

.notsoutheast:
	and ebx,3
	xor ebx,3	// ebx=sprite set for 0x08 track piece
	shl ebx,16+2*3
	or edx,ebx
	pop ebx

	shr bl,3
	and ebx,0x0c
	or [esp],bl	// regular pylons here (4=SW, 8=SE)

.doneh:

	// **********************

drawpylons_vertical:
	mov ebx,esi
	add bh,bl
	and bh,3	// for alternating pylons

	test dh,0x20
	jz .west

	// --- north east and south east exits ---

	param_call checkpylons_horver, 0x20100903, 0x0103

	push ebx
	test bh,2
	jz .notonotherside

	dec bh
	or bl,bh

.notonotherside:
	mov bh,[esp+5]
	and bh,10	// collect bits 2&4 for sprite set
	shr bh,2
	adc bh,0
	or bl,bh
	shl bh,2
	not bh
	and bh,bl

	test bh,4
	jz .notnortheast

	push 12
	push 4
	call draw1pylon

	or byte [esp+5],2

.notnortheast:
	test bh,8
	jz .notsoutheast

	push 13
	push 4
	call draw1pylon

	or byte [esp+5],8

.notsoutheast:

	and ebx,3
	xor ebx,3	// ebx=sprite set for 0x20 track piece
	shl ebx,16+2*5
	or edx,ebx
	pop ebx

	shr bl,3
	and bl,0x0a	// 2=NE, 8=SE
	or [esp],bl

.west:
	test dh,0x10
	jz .donev

	// --- north west and south west exits ---

	param_call checkpylons_horver, 0x10200a05, 0x0002

	push ebx
	test bh,2
	jz .notonotherside2

	dec bh
	or bl,bh

.notonotherside2:
	mov bh,[esp+5]
	and bh,5	// collect bits 1&3 for sprite set
	shr bh,1
	adc bh,0
	or bl,bh
	shl bh,2
	not bh
	and bh,bl

	test bh,4
	jz .notnorthwest

	push 14
	push 1
	call draw1pylon

	or byte [esp+5],1

.notnorthwest:
	test bh,8
	jz .notsouthwest

	push 15
	push 1
	call draw1pylon

	or byte [esp+5],4

.notsouthwest:

	and ebx,3
	xor ebx,3	// ebx=sprite set for 0x10 track piece
	shl ebx,16+2*4
	or edx,ebx
	pop ebx

	shr bl,4
	and bl,5	// 1=NW, 4=SW
	or [esp],bl

.donev:

	// **********************

drawpylons_diagonal:
	test dh,1
	jz .otherdiag

	mov ebx,esi
	add bh,bh
	xor bh,bl
	and bh,3	// for alternating pylons

	// --- north east and south west exits ---

	param_call checkpylons_horver, 0x01011824, 0x0102

	push ebx
	test bh,2
	jz .notonotherside

	dec bh
	or bl,bh

.notonotherside:
	mov bh,[esp+5]
	shr bh,1	// collect bits 1&2 for sprite set
	or bl,bh
	shl bh,2
	not bh
	and bh,bl

	test bh,4
	jz .notnortheast

	push 6
	push 12
	call draw1pylon

	or byte [esp+5],2

.notnortheast:
	test bh,8
	jz .notsouthwest

	push 5
	push 3
	call draw1pylon

	or byte [esp+5],4

.notsouthwest:
	and ebx,3
	xor ebx,3	// ebx=sprite set for 0x01 track piece
	shl ebx,16+2*0
	or edx,ebx
	pop ebx
	shr bl,4
	and bl,6	// 2=NE, 4=SW

	or [esp],bl

.otherdiag:
	test dh,2
	jz near .donediag

	mov ebx,esi
	add bl,bl
	xor bh,bl
	and bh,3	// for alternating pylons

	// --- north west and south east exits ---

	param_call checkpylons_horver, 0x02022814, 0x0003

	push ebx
	test bh,2
	jz .notonotherside2

	dec bh
	or bl,bh

.notonotherside2:
	mov bh,[esp+5]
	and bh,9	// collect bits 0&3 for sprite set
	shr bh,1
	adc bh,0
	shr bh,1
	adc bh,0
	or bl,bh
	shl bh,2
	not bh
	and bh,bl

	test bh,4
	jz .notnorthwest

	push 2
	push 9
	call draw1pylon

	or byte [esp+5],1

.notnorthwest:
	test bh,8
	jz .notsoutheast

	push 1
	push 6
	call draw1pylon

	or byte [esp+5],8

.notsoutheast:

	and ebx,3
	xor ebx,3
	shl ebx,16+2*1	// ebx=sprite set for 0x02 track piece
	or edx,ebx
	pop ebx
	shr bl,4
	and bl,9	// 1=NW, 8=SE

	or [esp],bl

.donediag:
	pop ebx

	ret


// draw all the pylons
// in:	AX,CX,DL,DH,DI from gettileinfo
//	DH has bit 6 set if it contains the exit map, instead of the track layout
//	DH has bit 7 set only if we want to draw on a bridge instead of below
// out:	ESI=XY index
// uses:EBX,EBP,upper 2 bytes of EDX
drawpylons_makeesi:
	call locationtoxy

global drawpylons
// use this entry point if ESI = XY index already
drawpylons:
		// make sure badpylondirs is reset the next time drawpylons is called
	btr dword [badpylondirs],31
	jc .dontreset

	and dword [badpylondirs],0

.dontreset:
	movzx edx,dx

	test byte [displayoptions],0x20
	jnz .fulldetail

.return:
	ret

.fulldetail:
	xor ebp,ebp
	or bp,[catenaryspritebase]
	js .return

	mov bl,dh
	mov bh,15
	test bl,0x40
	jnz .haveexitmap

	call makerailexitcount

	shr bh,2		// bh is A?B?C?D? where A..D are set if > 1 track piece
	rcr bl,1		// want to make bl 0000ABCD
	shr bh,2
	rcr bl,1
	shr bh,2
	rcr bl,1
	shr bh,2
	rcr bl,1

	shr bl,4
	mov bh,bl		// ignore exits that have multiple tracks
				// when finding straight tracks below

.haveexitmap:
		// remove directions in which we should not draw pylons
	test bl,4
	jz .notsw
	pusha
	add eax,16
	mov bl,2
	and dh,0x80
	or bl,dh
	call haspyloninthisdirection
	popa
	jnz .notsw
	and bl,~4
.notsw:
	test bl,8
	jz .notse
	pusha
	add ecx,16
	mov bl,1
	and dh,0x80
	or bl,dh
	call haspyloninthisdirection
	popa
	jnz .notse
	and bl,~8
.notse:
	cmp bh,15
	jae .useexitmap		// all four exits determined already

	push ebx
	call drawpylons_straight
	or [esp],bl		// add exits that didn't have continuous tracks
	pop ebx

.useexitmap:
	shr bl,1
	jnc .northeast

	// check next square in this direction
	pusha
	sub ecx,byte 0x10
	mov bl,8
	and dh,0x80
	or bl,dh
	call dontwantpyloninthisdirection
	popa
	je .northeast

	// northwest, or -Y direction
	push 0
	push 9
	call draw1pylonflipdir

.northeast:		// -X direction
	shr bl,1
	jnc .southwest

	// check next square in this direction
	pusha
	sub eax,byte 0x10
	mov bl,4
	and dh,0x80
	or bl,dh
	call dontwantpyloninthisdirection
	popa
	je .southwest

	push 4
	push 12
	call draw1pylonflipdir

.southwest:		// +X direction
	shr bl,1
	jnc .southeast

	// check next square in this direction
	pusha
	add eax,byte 0x10
	mov bl,2
	and dh,0x80
	or bl,dh
	call dontwantpyloninthisdirection
	popa
	jz .southeast

	// no railway in the +X direction, draw a pylon there
	push 7
	push 3
	call draw1pylonflipdir

.southeast:		// +Y direction
	shr bl,1
	jnc .done

	test dh,dh
	js .done

	// check next square in this direction
	pusha
	add ecx,byte 0x10
	mov bl,1
	and dh,0x80
	or bl,dh
	call dontwantpyloninthisdirection
	popa
	jz .done

	// no railway in the +Y direction, draw a pylon there
	push 3
	push 6
	call draw1pylonflipdir

.done:
displaywires_return:
	ret
; endp drawpylons


// draw overhead wires
// in:	(directly from gettileinfo, or faked)
//	AX:CX:DL = X:Y:Z of N corner
//	DH = track layout
//	upper two bytes of EDX:
//		two bits for each bit in DH itself that select the
//		wire sprite set to use
//		(normally set/reset and returned by drawpylon)
//	DI = height layout
// uses:everything
global displaywires
displaywires:
	movzx ebx,word [catenaryspritebase]
	or bh,bh
	js displaywires_return

	add dl,wireheight
	movzx edi,di
	or edi,edi
	jnz .slope

	add ebx,byte elrailsprites.wires
	and dh,0x3F
	xor esi,esi
.wireloop:
	shr dh,1
	jnc .nextwire

	pusha
		// find sprite number
	push ecx
	lea ecx,[esi*2+16-3]
	lea esi,[flatwires+esi*5]
	ror edx,cl
	mov ch,dl
	and ch,3<<3
	add ch,[esi]
	add bl,ch
	adc bh,0
	rol edx,cl
	pop ecx

		// adjust x and y offset
	add al,[esi+1]
	adc ah,0
	add cl,[esi+2]
	adc ch,0
	movzx edi,byte [esi+3]
	movzx esi,byte [esi+4]
	mov dh,1
	call [addsprite]
	popa

.nextwire:
	inc esi
	or dh,dh
	jnz .wireloop
	jmp short .wiresdone

.slope:
	cmp edi,byte 15
	jae .wiresdone

	push ecx
	xor ecx,ecx
	bsr cx,dx
	lea ecx,[(ecx-8)*2+16-3]

	mov esi,sloperailheightadjs
	bt [esi],edi
	jnc .notabove
	add dl,8
.notabove:
	mov dh,1
	bt [esi+2],edi
	jnc .notinclined
	add dh,8
.notinclined:

	lea edi,[slopewires+(edi-1)*5]

		// find sprite number
	ror edx,cl
	mov ch,dl
	and ch,3<<3
	add ch,[edi]
	add bl,ch
	adc bh,0
	rol edx,cl
	pop ecx

		// adjust offsets
	add al,[edi+1]
	adc ah,0
	add cl,[edi+2]
	adc ch,0
	movzx esi,byte [edi+4]
	movzx edi,byte [edi+3]
	call [addsprite]

.wiresdone:
	ret
; endp displaywires


// Display railway catenary sprites
// in:	AX,CX = landscape coordinates of the north corner
//	ESI = landscape XY index
//	DH = L5[ESI]
//	DL = altitude of the lowest corner
//	DI = bitmap of corners above the lowest one
//	BL = track type
// uses:EBX,EBP
displrailwaycatenary:
	and bl,0xF
	cmp bl,1
	jne .done

// disable display if it's a higherbridge, we already drawn the caternery support
	push edx
	mov dl,[landscape4(si)]		// is this a tunnel or bridge 
	and dl,0xf0
	cmp dl,0x90
	jnz .notbridge

	// but draw it if it's a custom bridge head
	test byte [landscape3+esi*2+1],3 << (13-8)

.notbridge:
	pop edx	
	jz .bridge	

	push edx	// preserve upper two bytes of EDX just to be sure
	and dh,0x3f
	call drawpylons

	pusha
	call displaywires
	popa
	pop edx

.done:
	ret

.bridge:
	call bridgemiddlecheckifwirefit
	jnc .noroomforwire 	
	pusha
	call displaywires
	popa
	.noroomforwire:
	ret
; endp displrailwaycatenary


// Display overhead wires etc. over a track when necessary
// in:	see displrailwaycatenary
// out:	ZF clear = display fences
// safe:EBX,EBP
global displtrackdetails
displtrackdetails:
	mov bl,[landscape3+esi*2]
	call displrailwaycatenary

	test byte [displayoptions],0x20
	ret
; endp displtrackdetails


// Display a level crossing
// in:	AX,CX,DL,DH,DI as returned by gettileinfo
//	EBX = tile XY index
// safe:EDI,EBP
global drawcrossing
drawcrossing:
	mov esi,ebx		// overwritten

	pusha
	and dh,8
	shr dh,3
	xor dh,1
	inc dh
	mov bl,[landscape3+ebx*2+1]
	call displrailwaycatenary
	popa

	mov bx,1371		// overwritten
	ret
; endp drawcrossing

exported restoreelrailstexts
	// restore default strings
	xor ecx,ecx
	mov esi,railtypetextids
.next:
	lodsw
	cmp ax,byte -1
	je .done
	call gettextintableptr
	mov ebx,[railtypetextbackup+ecx*4]
	mov [eax+edi*4],ebx
	inc ecx
	jmp .next

.done:
	ret

// Set menu texts etc
global setelrailstexts
setelrailstexts:
	cmp byte [unimaglevmode],1
	jne .notmonorail

	mov esi,monorailtextreplace
	mov ecx,nummonorailtextreplace
	call .nextelectrtext

.notmonorail:
	mov esi,electrtextreplace
	mov ecx,numelectrtextreplace

.nextelectrtext:
	lodsd		// now ax=new text ID, [esi-2]=text ID to replace
	call gettextandtableptrs
	push edi
	mov eax,[esi-2]
	call gettextintableptr
	pop dword [eax+edi*4]
	loop .nextelectrtext
	ret
