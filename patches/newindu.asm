// Support for new industries

#include <std.inc>
#include <misc.inc>
#include <textdef.inc>
#include <industry.inc>
#include <window.inc>
#include <town.inc>
#include <grf.inc>
#include <ptrvar.inc>

extern BringWindowToForeground,CreateTooltip,CreateWindowRelative
extern DestroyWindow,DrawWindowElements,RefreshWindowArea,WindowClicked
extern WindowTitleBarClicked,actionhandler,callback_extrainfo
extern cargoamount1namesptr,cargoamountnnamesptr,cargotypenamesptr
extern curcallback,curgrfindustilelist,curgrfindustrylist,curmiscgrf
extern currscreenupdateblock,curspriteblock,drawtextfn,errorpopup
extern fillrectangle,fundchances,fundprospecting_newindu_actionnum
extern generatesoundeffect,gethouseterrain,getnewsprite,gettileinfo
extern getwincolorfromdoscolor,grffeature,grfstage,malloccrit
extern industryspriteblock,invalidatehandle,lookuppersistenttextid
extern mostrecentspriteblock,processtileaction2,randomfn
extern randomindustiletrigger,randomindustrytrigger,redrawtile,setmousetool
extern specialerrtext1,substindustries
extern texthandler


// --- Industry tile stuff ---

// Usage of landscape arrays for industry tiles:

// L1: as in unpatched TTD
// L2: index into industry array (as in unpatched TTD)
// L3:	low byte: animation state
//	high byte: new type (zero if old type)
// L5: substitute type for new types, real type for old types
// L6: random bits
// L7: random triggers activated so far

// Industry tiles need a different handling than house tiles, since their
// IDs are often stored in a byte register instead of a dword one. Instead
// of having new, extended arrays for the old and new data, we leave the old
// data alone and have the data of the new tiles in new, separate arrays.
// This requires patching all code that accesses these arrays, but luckily
// there are only few such places.

// 0 isn't a valid gameid or dataid here either

// substitute industry tile types
uvarb substindustile,256

// action 3 data for the industry tiles
uvard extraindustilegraphdataarr,256

// index of the last valid entry of the above array
uvarb lastextraindustiledata

// mapping between gameids and dataids
uvard industiledataidtogameid,2*256

struc industilegameid
	.grfid:		resd 1
	.setid:		resb 1
	.gameid:	resb 1
endstruc_32

// index of the last valid entry of the above array
uvarb lastindustiledataid

// this array contains 0 for non-overridden old types and
// the corresponding new type for overridden ones
uvarb industileoverrides,0xAF

// Three accepted cargoes for the tile. The high byte contains
// the amount, the low byte the type
uvarw industileaccepts1,256
uvarw industileaccepts2,256
uvarw industileaccepts3,256

// land shape flags, see IDA DB for meaning of bits
// except bit 5, that means "allowed on both land and water"
uvarb industilelandshapeflags,256

// callback flags
uvarb industilecallbackflags,256

// Number of animation frames minus one in the low byte,
// looping info in the high byte (0 - non-looping, 1 - looping)
// Since industry tiles don't have a separate animation flag, we
// reserve FFFF to mean "no animation"
uvarw industileanimframes,256

// Speed of animation
uvarb industileanimspeeds,256

// Animation triggers
// Bit 0 - the construction state changes 	
// Bit 1 - the tile is processed in the periodic processing loop 	
// Bit 2 - the industry of the tile is processed in the periodic processing loop 	
// Bit 3 - the industry of the tile receives input cargo from a station
uvarb industileanimtriggers,256

// points to the acceptance table of the old tiles
uvard oldindutileacceptsbase

// points to the sprite table of old tiles
uvard industilespritetable

// Called to set the substitute type for an industry tile. This function assigns
// the setid to a dataid and a gameid if this is the first usage of the setid
// Almost identical to setsubstbuilding, used for new houses
global setsubstindustile
setsubstindustile:
.next:
	xor edx,edx
	mov dl,[curgrfindustilelist+ebx]		// Do we have a gameid yet?
	or dl,dl
	jnz near .alreadyhasoffset

	mov dl,[lastextraindustiledata]		// No - use the next available ID, if any
	add dl,1
	jnc .foundgameid

.toomany:
	mov ax,ourtext(toomanyspritestotal)
	stc
	ret

.invalid:
	mov ax,ourtext(invalidsprite)
	stc
	ret

.foundgameid:
	cmp byte [grfstage],0
	je .dontrecord
	mov [lastextraindustiledata],dl		// and the new last index
.dontrecord:
	mov [curgrfindustilelist+ebx],dl		// Record the new gameid
	lodsb
// now al contains the substitute type wanted
	cmp al,0xaf
	jae .invalid
	mov [substindustile+edx],al
	call copyindustiledata

// Now we try to find this GRFID and setid among the saved IDs. If we find it,
// we can store the gameid to the mapping array, if not, we allocate a new gameid.
	push ecx
	mov eax,[curspriteblock]
	mov eax,[eax+spriteblock.grfid]
	mov edi,industiledataidtogameid+8
	movzx ecx,byte [lastindustiledataid]
	jecxz .newslot

.findtileslot:
	cmp [edi+industilegameid.grfid],eax
	jne .nextslot

	cmp [edi+industilegameid.setid],bl
	je .foundit

.nextslot:
	add edi,8
	loop .findtileslot

.newslot:
	mov cl,[lastindustiledataid]
	add cl,1
	jnc .hasemptyslot

	pop ecx
	jmp short .toomany

.hasemptyslot:
	mov [lastindustiledataid],cl
	lea edi,[industiledataidtogameid+ecx*8]
	mov [edi+industilegameid.grfid],eax
	mov [edi+industilegameid.setid],bl

.foundit:
	mov [edi+industilegameid.gameid],dl
	pop ecx
	jmp short .loopend

.alreadyhasoffset:
// this is not the first setting of prop 8 - just store the subst. building type
	lodsb
	cmp al,0xaf
	jae .invalid
	mov [substindustile+edx],al
.loopend:
	inc ebx
	dec ecx
	jne near .next
	clc
	ret

// copy the properties of an old tile type to a new one, and fill
// new properties with defaults
copyindustiledata:
	push ebx
	push ecx

// Copying acceptance data is a bit tricky because TTD uses a different
// format. It has one byte per acceptance slot, where the byte is either
// FF to signal unused slot, or a cargo type number. The amount of acceptance
// is 8, except for passengers in the first slot, where it's 1.
// Convert this to our more flexible format.
// (Our pointer actually points to the middle acceptance array, so the other
//  two are accessable at offsets -0xAF and 0xAF)

	movzx eax,al
	mov ebx,[oldindutileacceptsbase]

	mov ch,8
	mov cl,[ebx-0xAF+eax]
	or cl,cl
	jns .hassecond
	xor ch,ch
.hassecond:
	mov [industileaccepts2+edx*2],cx

	mov ch,8
	mov cl,[ebx+0xAF+eax]
	or cl,cl
	jns .hasthird
	xor ch,ch
.hasthird:
	mov [industileaccepts3+edx*2],cx

	mov ch,8
	mov cl,[ebx+eax]
	or cl,cl
	jnz .notpassenger
	mov ch,1
.notpassenger:
	jns .hasfirst
	xor ch,ch
.hasfirst:
	mov [industileaccepts1+edx*2],cx

// Old land shape flags are always -2*0xAF bytes from the middle acceptance array
	mov cl,[ebx-2*0xAF+eax]
	mov [industilelandshapeflags+edx],cl

// and the defaults of new properties
	and dword [extraindustilegraphdataarr+edx*4],0 
	mov byte [industilecallbackflags+edx],0
	mov word [industileanimframes+2*edx],0xffff
	mov byte [industileanimspeeds+edx],2
	mov byte [industileanimtriggers+edx],0
	pop ecx
	pop ebx
	ret
	
// Called to override a given old tile type with the current one
global setindustileoverride
setindustileoverride:
	xor eax,eax
	lodsb
	cmp al,0xaf
	ja .error
	cmp byte [industileoverrides+eax],0
	jne .ignore
	mov [industileoverrides+eax],bl
.ignore:
	clc
	ret

.error:
	stc
	ret

// get the gameid of an industry tile
// in:	(e)bx: XY of tile
// out:	al: gameid
//	cf set if new type, clear if old
global getindustileid
getindustileid:
#if !WINTTDX
// in the DOS version, the upper half of ebx may contain junk
	push ebx
	movzx ebx,bx
#endif
	push ecx
	movzx ecx,byte [landscape3+2*ebx+1]
	or ecx,ecx
	jnz .newtile
// this is an old type (the high byte of landscape3 is zero), but may still be overridden
	movzx ecx,byte [landscape5(bx)]
	cmp byte [industileoverrides+ecx],0
	je .nooverride
//yes, it's overridden, so mimic the new type instead
	mov al,byte [industileoverrides+ecx]
	jmp short .havenewtileid
	
.fallback:
// we get here if a required new industry tile type is not available. Report the substitute type
// instead (it always should be available)
.nooverride:
	mov al,[landscape5(bx)]
	clc
	pop ecx
#if !WINTTDX
	pop ebx
#endif
	ret

.newtile:
// A new tile type - look up the gameid for this dataid
	mov al,[industiledataidtogameid+ecx*8+industilegameid.gameid]
	or al,al
	jz .fallback
.havenewtileid:
	stc
	pop ecx
#if !WINTTDX
	pop ebx
#endif
	ret

// called while determining whether a default foundation should be drawn
// in:	registers from GetTileTypeHeightInfo, except that ebx and esi are swapped
// out:	"faked" di and zf set to skip drawing foundations for sloped tiles
// safe: esi,???
global checkindustileslope
checkindustileslope:
	test di,0xf
	jnz .sloped
// the tile isn't sloped, so we won't draw foundations anyway
	ret

.drawfound:
// allow drawing the foundations
	pop eax
	test edi,edi	// clear zf
	ret

.sloped:
	push eax
	call getindustileid
	jnc .drawfound		// old tile types can't suppress foundations

	movzx eax,al
	test byte [industilecallbackflags+eax],0x20
	jz .drawfound		// callback isn't enabled - draw foundations

// do the callback
	movzx esi,bx
	mov byte [grffeature],9
	mov byte [curcallback],0x30
	call getnewsprite
	mov byte [curcallback],0
	jc .drawfound			// callback error
	test eax,eax
	jnz .drawfound			// callback wants to draw foundation

	xor edi,edi			// create fake di and set zf
	pop eax
	ret

// Called to decide the offset of the sprite entry to be drawn for the industry tile.
// If it's a new type, we call our custom draw routine instead
// in:	ax, cx: fine X and Y coordinates of tile
//	bx: XY of tile
//	di: slope data
global getindustrytilegraphics
getindustrytilegraphics:
	push eax
	movzx ebx,bx
	call getindustileid
	movzx eax,al
	jc .newtile
.oldgraph:

// we need to draw an old tile type
// we just reproduce the overwritten code
	shl eax,2
	movzx esi,byte [landscape1+ebx]
	and esi,3
	or esi,eax
	pop eax
	imul esi,17
	ret

.fallback:
// we couldn't find the graphics for the tile - fall back to drawing the substitute
	pop ebx
	pop eax
	movzx eax,byte [substindustile+eax]
	jmp short .oldgraph

.newtile:
// try getting the graphics
	push eax
	push ebx
	mov esi,ebx
	mov byte [grffeature],9
	call getnewsprite
	jc .fallback

	add esp,8	// if the action2 was found, we don't need those saved values

	push eax	// dataptr for processtileaction2
	push ebx	// spritesavail for processtileaction2

	movzx eax,byte [landscape1+esi]
	and al,3
	push eax	// conststate for processtileaction2

	movzx eax,byte [landscape2+esi]
	imul eax,industry_size
	add eax,[industryarrayptr]

	movzx eax,byte [eax+industry.buildingcolor]
	add eax,775
	push eax		// defcolor for processtileaction2

	mov eax, [esp+16]	// restore saved X coordinate

	push dword 9		// grffeature for processtileaction2

	call processtileaction2
	pop eax
	add esp,6		// remove return address and a saved word reg from stack
	ret			// return from caller

// Called to reset gameids after loading a game or starting a new one
global clearindustiledataids
clearindustiledataids:
	mov ecx,256
.loop:
	mov byte [industiledataidtogameid+(ecx-1)*8+industilegameid.gameid],0
	loop .loop
	ret

// Called if newindustries is on, but there's no industry tile data in the savegame
// Clear dataids from the high byte of L3 because we no longer know
// which graphics they are associated to
global clearindustileidsfromlandscape
clearindustileidsfromlandscape:
	push eax
	push esi

	xor esi,esi

.loop:
	mov al,[landscape4(si)]
	shr al,4

	cmp al,8
	jne .next

	mov byte [landscape3+2*esi+1],0

.next:
	inc esi
	cmp esi,0x10000
	jb .loop

	pop esi
	pop eax
	ret

// Called when the construction state of an industry tile changes, just before
// executing handlers for special old tile types. We must do two things:
// Prevent any special handling of new tile types, and execute callback 25
// if it's enabled for construction state changes.
// in:	ax, cx: fine X and Y coordinates of tile
//	bx: XY of tile
// safe: ???
global industileconststatechange
industileconststatechange:
	jz .exitcaller			// there was a jz locret_xxx overwritten
	call getindustileid
	jc .ourtile			// new tiles don't use the special functions
	ret

.exitcaller:
	pop edx
	ret

.ourtile:
	pop edx				// remove return address - we're taking the call over

	test byte [industileanimtriggers+eax],1
	jz .noconstcallback

// do callback 25 if it's enabled for construction state changes
	pusha
	push ebx
	movzx eax,al
	mov esi,ebx
	mov byte [grffeature],9
	mov byte [curcallback],0x25
	and dword [callback_extrainfo],0
	call getnewsprite
	mov byte [curcallback],0
	pop ebx
	jc .leavealone
	call setindutileanimstage
.leavealone:
	popa	
.noconstcallback:
	ret
	
// Called in the very beginning of Class8PeriodicProc
// Do some extra things for new tile types
global class8periodicproc0
class8periodicproc0:
	call getindustileid
	jnc .notnew

// activate random trigger 1 - periodic processing happened
	push ecx
	mov cl,1
	call randomindustiletrigger
	pop ecx

// if animation trigger bit 1 is enabled, call callback 25
	movzx eax,al
	test byte [industileanimtriggers+eax],2
	jz .noperiodicanim
	push ebx
	mov esi,ebx
	mov byte [grffeature],9
	mov byte [curcallback],0x25
	mov dword [callback_extrainfo],1
	call getnewsprite
	mov byte [curcallback],0
	pop ebx
	jc .leavealone
	call setindutileanimstage
.leavealone:

.noperiodicanim:

.notnew:
	mov al,[landscape1+ebx]		// overwritten
	ret

// called in Class8PeriodicProc to get the ID of the industry tile
// we add 256 to new tile IDs to separate them from old ones
// in:	bx: XY of tile
// out:	esi: ID of tile
// safe: eax, ???
global class8periodicproc1
class8periodicproc1:
	jz .exitcaller			// there was a jz locret_xxx overwritten
	xor eax,eax
	call getindustileid
	setc ah
	mov esi,eax
	ret
	
.exitcaller:
	pop esi
	ret

// points to the table with the same name in TTD memory
// see the IDA DB for details
uvard baIndustryTileTransformBack

// Called instead of checking baIndustryTileTransformBack
// in:	esi: tile ID as set above
// out:	zf set if the according array entry is -1
//	- or -
//	exit caller for new types (the rest of the caller code doesn't apply for these)
global class8periodicproc2
class8periodicproc2:
	cmp esi,256
	jae .exitcaller
	push eax
	mov eax,[baIndustryTileTransformBack]
	cmp byte [eax+esi],-1
	pop eax
	ret
	
.exitcaller:
	pop esi
	ret

// points to the table with the same name in TTD memory
// see the IDA DB for details
uvard baIndustryTileTransformOnDistr

// called instead of reading from baIndustryTileTransformOnDistr
// be return -1 for new types since they don't have entries in that array
// in:	esi: industry tile type
// out:	al: array element
// safe: ???
global distributeindustrycargo2
distributeindustrycargo2:
	cmp esi,256
	jae .newtype
	push ebx
	mov ebx,[baIndustryTileTransformOnDistr]
	mov al,[ebx+esi]
	pop ebx
	ret
	
.newtype:
	mov al,0xff
	ret

// Called at the very beginning of the class 8 animation handler.
// We must exit the caller for new tiles to avoid the special handling.
// in:	bx: XY of tile
// out:	dl: tile ID for old tiles
// safe: ax, cx, dl, ???
global class8animationhandler
class8animationhandler:
	call getindustileid
 	jc .ourtile
 	mov dl,al
 	cmp dl,0xae
 	ret

.ourtile:
	pop edx			// remove return address

// do our custom animation handling for new tiles

	movzx eax,al
	cmp word [industileanimframes+2*eax],0xffff
	je .exit					// animation is disabled

// in the scenario editor, the anim. counter doesn't change, so don't do animation there
	cmp byte [gamemode],2
	je .exit

	mov edx,eax
	movzx edi, word [animcounter]
	mov ebp,1

// do the animation speed callback, if enabled
	test byte [industilecallbackflags+eax],2
	jz .normalspeed

	push ebx
	mov esi,ebx
	mov byte [grffeature],9
	mov byte [curcallback],0x27
	call getnewsprite
	mov byte [curcallback],0
	mov cl,al
	pop ebx
	jnc .hasspeed

.normalspeed:
// otherwise, use the property
	mov cl,[industileanimspeeds+edx]

.hasspeed:
	shl ebp,cl
	dec ebp
// now edi is the anim. counter, and ebp has the lowest cl bits set only
// the animation should proceed only if all those low bits are zero in the counter
	test edi,ebp
	jz .proceed
.exit:
	ret

.proceed:
// if callback 26 (decide next anim. frame) is enabled, call it
	test byte [industilecallbackflags+edx],1
	jz .normal
	push ebx
	mov eax,edx
	mov esi,ebx
	mov byte [grffeature],9
	mov byte [curcallback],0x26
	call getnewsprite
	mov byte [curcallback],0
	pop ebx
	jc .normal

	or ah,ah
	jz .nosound

// a nonzero high byte means a sound to play
	pusha
	movzx eax,ah
	and al,0x7f
	mov ecx,ebx
	rol bx,4
	ror cx,4
	and bx,0x0ff0
	and cx,0x0ff0
	or esi,-1
	call [generatesoundeffect]
	popa

.nosound:
	cmp al,0xff
	je .stop		// FF means to stop the animation
	cmp al,0xfe
	jne .hasframe		// FE means start animation at current frame

.normal:
// increase animation frame
	mov al,[landscape3+2*ebx]
	inc al
// has the animation reached the last frame?
	mov ah,[industileanimframes+2*edx]
	cmp ah,al
	jb .finished
.hasframe:
// update animation frame and redraw tile to make the change appear
	mov [landscape3+2*ebx],al
	mov esi,ebx
	jmp redrawtile			// in manucnvt.asm

.finished:
// we're at the last frame - jump to the first for repeating animations, and stop for non-repeating ones
	cmp byte [industileanimframes+2*edx+1],1
	jne .stop
	xor al,al
	jmp short .hasframe

.stop:
// stop the animation - that is, remove the tile from the animated tiles list
	mov edi,ebx
	mov ebx,3				// Class 14 function 3 - remove animated tile
	mov ebp,[ophandler+0x14*8]
	jmp [ebp+4]

// called in the very beginning of class 8 acceptance query handler
// in:	edi: XY of tile
// out:	-- for old tiles --
//	ebx: tile ID
//	-- for new tiles --
//	return from parent with
//	ax, bx, cx: three acceptance values, amount in high byte, type in low byte
// safe: eax, ebx, ecx
global class8queryhandler
class8queryhandler:
	mov ebx,edi
	call getindustileid
	jc .ourtile
	movzx ebx,al
	ret

.ourtile:
	pop ebx					// remove our return address
	push ebp
	push edx

// first, fill ax, bx and cx according to the static properties
// if any callback is disabled/fails, those values will remain as default
	movzx ebp,al
	mov ax,[industileaccepts1+ebp*2]
	mov bx,[industileaccepts2+ebp*2]
	mov cx,[industileaccepts3+ebp*2]

// first, do the acceptance amount callback, if enabled
	test byte [industilecallbackflags+ebp],4
	jz .noacceptcallback

	mov edx,eax			// save the value of eax to edx
	mov eax,ebp			// so eax can be set to the tile ID
	xchg esi,edi			// put XY into esi while saving old esi into edi
	mov byte [grffeature],9
	mov byte [curcallback],0x2B
	call getnewsprite
	mov byte [curcallback],0
	xchg esi,edi			// restore old esi and put XY back to edi
	xchg eax,edx			// restore old eax and put callback result into edx
	jc .noacceptcallback

// the return value contains three 4-bit values packed together, so unpack it
	mov ah,dl
	and ah,0xf
	mov bh,dl
	shr bh,4
	mov ch,dh
	and ch,0xf
.noacceptcallback:

// now the acceptance type callback, if enabled
	test byte [industilecallbackflags+ebp],8
	jz .noaccepttypecallback

// the register juggling is the same as above
	mov edx,eax
	mov eax,ebp
	xchg esi,edi
	mov byte [grffeature],9
	mov byte [curcallback],0x2C
	call getnewsprite
	mov byte [curcallback],0
	xchg esi,edi
	xchg eax,edx
	jc .noaccepttypecallback

// this return value contains three 5-bit values packed together, making the unpacking trickier
	mov al,dl
	and al,0x1f
	shr edx,5
	mov bl,dl
	and bl,0x1f
	shr edx,5
	mov cl,dl
	and cl,0x1f
.noaccepttypecallback:
	pop edx
	pop ebp
	ret

// called to get industry tile variable 40 (construction state)
global getindustileconststate
getindustileconststate:
	mov al,[landscape1+esi]
	and eax,3
	ret

// helper variable that contains the XY of the northern tile of a planned industry
// this allows var 43 (relative position) to work during callback 2F (custom land shape check)
// when the industry isn't really there yet
uvarw industrycheck_mainXY

// called to get industry tile variable 43 (relative position)
global getindustilepos
getindustilepos:
	mov ecx,esi
	cmp byte [curcallback],0x2F
	je .callback_2f
	movzx eax,byte [landscape2+esi]
	imul eax,industry_size
	add eax,[industryarrayptr]
// now eax points to the industry of the tile
	sub cx,[eax+industry.XY]
.gotoffset:
// for the 3rd byte, squeeze the X and Y differences into one byte
	mov ax,cx
	shl al,4
	shr ax,4
	shl eax,16
// the low word is the X and Y differences in one byte each
	mov ax,cx
	ret

.callback_2f:
// during callback 2F, use the helper var since the industry isn't there yet
	sub cx,[industrycheck_mainXY]
	jmp short .gotoffset

// called to get variable 44 (current animation frame)
global getindustileanimframe
getindustileanimframe:
	movzx eax,byte [landscape3+2*esi]
	ret

// called to get parametrized variable 60 (slope info of nearby tiles)
// the parameter is the signed X and Y offsets squeezed together into a byte
// the result is rrzzbbss, where
// - rr is reserved
// - zz is the height of the lowest corner of the tile
// - bb is a bit field
//	bit 0 is set if the tile is an industry tile and belongs to the same industry
//		as the current one
//	bit 1 is set if the tile has water on it
//	other bits are reserved
// - ss is the slope info as returned by GetTileTypeHeightInfo
global getindustilelandslope
getindustilelandslope:
	pusha
	mov ebp,esi		// save XY to a safe place

// get fine X and Y coordinates from XY (plus the offsets), for GetTileTypeHeightInfo

// first the Y coordinate into ecx
	mov ecx,esi
	shr cx,4
	and cl,0xf0
	movsx edx,ah
	and dl,0xf0
	add cx,dx

// now we can put the X coordinate into eax, we no longer need ah
	shl ah,4
	movsx edx,ah
	mov eax,esi
	shl eax,4
	and ah,0x0f
	add ax,dx

	call [gettileinfo]

	mov [esp+28],di		// low word of saved EAX of stack, the high byte is zero
	mov [esp+30],dl		// byte 3 of saved EAX
	mov byte [esp+31], 0	// highest byte of saved EAX

	cmp bx,8*8		// is it a class 8 tile?
	jne .notpart

	mov al,[landscape2+ebp]
	cmp al,[landscape2+esi]	// esi is now the offset of the asked tile
	sete byte [esp+29]	// byte 2 of saved eax
.notpart:

// check if the tile is watered (is a class 6 tile)
	cmp bx,6*8
	sete al
	shl al,1
	or [esp+29],al

	popa
	ret

// Start/stop animation and set the animation stage of a new industry tile
// (Almost the same as sethouseanimstage, but stores the current frame differently)
// in:	al:	number of new stage where to start
//		or: ff to stop animation
//		or: fe to start wherewer it is currently
//		or: fd to do nothing (for convenience)
//	ebx:	XY of house tile
setindutileanimstage:
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
	or esi,-1
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

	mov byte [landscape3+2*ebx],al

.dontset:
	pusha
	mov edi,ebx
	mov ebx,2				// Class 14 function 2 - add animated tile
	mov ebp,[ophandler+0x14*8]
	call [ebp+4]
	popa

.animdone:
	ret

industryanimtrigger:
	pusha

	mov byte [grffeature],9
	mov byte [curcallback],0x25
	and dword [callback_extrainfo],0
	mov [callback_extrainfo],dl

	movzx esi,word [edi+industry.XY]
	movzx ecx,word [edi+industry.dimensions]

.yloop:
	mov cl,[edi+industry.dimensions]
	push esi
.xloop:
	mov bl,[landscape4(si)]
	and bl,0xf0
	cmp bl,0x80
	jne .dontneed
	
	movzx ebx,byte [landscape2+esi]
	imul ebx,industry_size
	add ebx,[industryarrayptr]
	cmp ebx,edi
	jne .dontneed

	mov ebx,esi
	call getindustileid
	jnc .dontneed
	movzx eax,al

	bt dword [industileanimtriggers+eax],edx
	jnc .dontneed

	call getnewsprite
	jc .invalid

	mov ebx,esi
	call setindutileanimstage

.invalid:
.dontneed:
	inc esi
	dec cl
	jnz .xloop

	pop esi
	add esi,0x100
	dec ch
	jnz .yloop

	mov byte [curcallback],0

	popa
	ret

// --- industry stuff ---

// points to the beginning of industry data block
uvard industrydatablockptr,1,s

// points to the layout table
uvard industrylayouttableptr,1,s

// points to a memory block allocated by the patch and contains the original data block and layout table
uvard industrydatabackupptr,1,s

uvarw industrynames,NINDUSTRIES

uvard industrydataidtogameid,2*NINDUSTRIES

struc industrygameid
	.grfid:		resd 1
	.setid:		resb 1
endstruc_32

var defaultindustriesofclimate
	// temperate
	dd 00000000000001000001101101111111b,00000b
	// arctic
	dd 00000000000000011110101010011011b,00000b
	// tropical
	dd 00000011111110110010110000010000b,00000b
	// silly
	dd 11111100000000000000000000000000b,11111b

uvarb orginitialindustryprobs,4*NINDUSTRIES

uvarb orgingameindustryprobs,4*NINDUSTRIES

uvarb initialindustryprobs,NINDUSTRIES

uvarb ingameindustryprobs,NINDUSTRIES

uvarb industrymapcolors,NINDUSTRIES

var defaultindustrymapcolors, 	db 0x01+0xd6*WINTTDX
				     db 0xb8,0xc2,0x56,0xbf,0x98,0xae,0xae, 0x0a,0x30,0x0a,0x98,0x0f,0x37,0x0a,0xc2
				db 0x0f,0xb8,0x37,0x56,0x27,0x25,0xd0,0xae, 0x30,0xc2,0x30,0xae,0x27,0x37,0xd0,0x0a
				db 0x25,0xb8,0x98,0xc2,0x0f

uvard industryspecialflags,NINDUSTRIES

var defaultindustryspecialflags, 	dd 0x2000,0,0,0,0x800,0x604,0x1000,0,	0,0x41,0,0x180,0x8,0,0,0
					dd 0x10,0,0,0,0,0,0x10,0,		0x40,0x2,0,0,0,0,0x20,0
					dd 0,0,0,0,0

uvarw industrycreationmsgs,NINDUSTRIES

uvard industryinputmultipliers,3*NINDUSTRIES

%define industryinputmultipliers1 industryinputmultipliers
%define industryinputmultipliers2 (industryinputmultipliers+NINDUSTRIES*4)
%define industryinputmultipliers3 (industryinputmultipliers+2*NINDUSTRIES*4)

// copy of the original prospecting chances in moreindu.asm
uvard origfundchances, NINDUSTRIES

// callback flags
uvarb industrycallbackflags,NINDUSTRIES

// helper array to hold incoming cargo amounts

struc industryincargodata
	.in_amount1:	resw 1
	.in_amount2:	resw 1
	.in_amount3:	resw 1
			resw 1		// some padding so we can use the *8 multiplier
endstruc_32

uvard industryincargos,2*90

%macro getinduidfromptr 1
	sub %1,[industryarrayptr]
	imul %1,1214	/*0x10000/industry_size*/		// multiplying by reciprocal instead of dividing to make things faster
	shr %1,16
%endmacro

global clearindustryincargos
clearindustryincargos:
	mov edi,industryincargos
	mov ecx,2*90
	xor eax,eax
	rep stosd
	ret

global clearindustrygameids
clearindustrygameids:
	mov edi,industrydataidtogameid
	mov ecx,2*NINDUSTRIES
	xor eax,eax
	rep stosd
	ret

global saveindustrydata
saveindustrydata:
	mov esi,[industrydatablockptr]
	mov edi,[industrydatabackupptr]
	mov ecx,925
	rep movsb
	mov esi,[industrylayouttableptr]
	mov ecx,296
	rep movsb
	add esi,0x2d
	xor ecx,ecx

	mov edi,orgingameindustryprobs
	mov cl,NINDUSTRIES
	xor eax,eax
	rep stosd

	mov edi,orginitialindustryprobs
	mov cl,NINDUSTRIES
	xor eax,eax
	rep stosd

	mov edi,orgingameindustryprobs
	mov cl,4
.nextingameclimate:
	push ecx
	mov cl,32
.nextingameindustryprob:
	lodsb
	inc byte [edi+eax]
	loop .nextingameindustryprob
	pop ecx
	add edi,NINDUSTRIES
	loop .nextingameclimate

	add esi,16
	mov cl,4
	mov edi,orginitialindustryprobs
.initialclimateloop:
.nextinitialindustryprob:
	lodsb
	or al,al
	jz .nextinitialclimate
	mov bl,al
	lodsb
	add byte [edi+eax],bl
	jmp short .nextinitialindustryprob

.nextinitialclimate:
	add edi,NINDUSTRIES
	loop .initialclimateloop	

	mov esi,fundchances
	mov edi,origfundchances
	mov cl,NINDUSTRIES
	rep movsd

	ret

global restoreindustrydata
restoreindustrydata:
	mov edi,[industrydatablockptr]
	mov esi,[industrydatabackupptr]
	mov ecx,925
	rep movsb
	mov edi,[industrylayouttableptr]
	mov ecx,296
	rep movsb
	mov edi,industrynames
	mov eax,0x4802
	mov ecx,NINDUSTRIES
.nextname:
	stosw
	inc eax
	loop .nextname

	mov edi,industrycreationmsgs
	mov ax,0x482d
	mov cl,NINDUSTRIES
	rep stosw
	inc word [industrycreationmsgs+3*2]		// forest

	movzx eax,byte [climate]
	imul eax,NINDUSTRIES
	lea esi,[orginitialindustryprobs+eax]
	mov edi,initialindustryprobs
	mov cl,NINDUSTRIES
	rep movsb

	lea esi,[orgingameindustryprobs+eax]
	mov edi,ingameindustryprobs
	mov cl,NINDUSTRIES
	rep movsb

	mov esi,defaultindustrymapcolors
	mov edi,industrymapcolors
	mov cl,NINDUSTRIES
	rep movsb

	mov esi,defaultindustryspecialflags
	mov edi,industryspecialflags
	mov cl,NINDUSTRIES
	rep movsd

	mov edi,industryinputmultipliers
	mov eax,0x00000100
	mov cl,3*NINDUSTRIES
	rep stosd

	mov esi,origfundchances
	mov edi,fundchances
	mov cl,NINDUSTRIES
	rep movsd

	mov edi,industrycallbackflags
	mov cl,NINDUSTRIES
	xor al,al
	rep stosb

	and dword [industryinputmultipliers1+0xc*4],0
	and dword [industryinputmultipliers2+0xc*4],0
	and dword [industryinputmultipliers3+0xc*4],0
	ret

// Various versions to get an industry text ID (instead of "add foo,0x4802")
global getindunamebx
getindunamebx:
	movzx ebx,bx
	mov bx,[industrynames+2*ebx]
	ret

global getindunamebp
getindunamebp:
	movzx ebp,bp
	mov bp,[industrynames+2*ebp]
	ret

global getindunameaxecx
getindunameaxecx:
	movzx eax,byte [ecx+industry.type]
	mov ax,[industrynames+2*eax]
	ret

global getindunameaxedi
getindunameaxedi:
	movzx eax,byte [edi+industry.type]
	mov ax,[industrynames+2*eax]
	ret

global getindunameaxesi
getindunameaxesi:
	movzx eax,byte [esi+industry.type]
	mov ax,[industrynames+2*eax]
	ret

%macro copyinduprop 1
	%if %1=1
		mov dl,[esi+eax]
		mov [edi+ebx],dl
	%elif %1=2
		mov dx,[esi+eax*2]
		mov [edi+ebx*2],dx
	%elif %1=4
		mov edx,[esi+eax*4]
		mov [edi+ebx*4],edx
	%else
		%error copyindudata invoked with wrong param
	%endif
	
	add esi,NINDUSTRIES*%1
	add edi,NINDUSTRIES*%1
%endmacro

// in:	esi->"from" data area
//	eax: "from" ID
//	edi->"to" data area
//	ebx: "to" ID
copyindustryprops:
	xor ecx,ecx
	copyinduprop 1
	mov cl,3
.loop1:
	copyinduprop 2
	loop .loop1
	copyinduprop 1
	copyinduprop 2
	copyinduprop 4
	mov cl,3
.loop2:
	copyinduprop 1
	loop .loop2
	mov cl,2
.loop3:
	copyinduprop 4
	loop .loop3
	ret

%undef copyinduprop

// restore every property of an old type from backup to the given slot
reloadoldindustry:
	mov esi,[industrydatabackupptr]
	mov edi,[industrydatablockptr]
	call copyindustryprops
	mov esi,[industrydatabackupptr]
	mov edi,[industrylayouttableptr]
	lea esi,[esi+925+eax*8]
	lea edi,[edi+ebx*8]
	movsd
	movsd
	mov si,0x4802
	add si,ax
	mov [industrynames+2*ebx],si

	movzx ecx,byte [climate]
	imul ecx,NINDUSTRIES
	add ecx,eax
	mov dl,[orginitialindustryprobs+ecx]
	mov dh,[orgingameindustryprobs+ecx]
	mov [initialindustryprobs+ebx],dl
	mov [ingameindustryprobs+ebx],dh

	mov dl,[defaultindustrymapcolors+eax]
	mov [industrymapcolors+ebx],dl

	mov edx,[defaultindustryspecialflags+eax*4]
	mov [industryspecialflags+ebx*4],edx

	mov dx,0x482d
	cmp eax,3
	jne .notforest
	inc edx
.notforest:
	mov [industrycreationmsgs+2*ebx],dx

	cmp eax,0xc
	jne .normal
.reset:
	and dword [industryinputmultipliers1+ebx*4],0
	and dword [industryinputmultipliers2+ebx*4],0
	and dword [industryinputmultipliers3+ebx*4],0
	jmp short .inputmultdone

.normal:
	mov dword [industryinputmultipliers1+ebx*4],0x00000100
	mov dword [industryinputmultipliers2+ebx*4],0x00000100
	mov dword [industryinputmultipliers3+ebx*4],0x00000100
.inputmultdone:

	mov edx,[origfundchances+eax*4]
	mov [fundchances+ebx*4],edx

	mov byte [industrycallbackflags+ebx],0
	ret

// copy every property between two slots
copynewindustrydata:
	mov esi,[industrydatablockptr]
	mov edi,esi
	call copyindustryprops
	mov esi,[industrylayouttableptr]
	lea edi,[esi+ebx*8]
	lea esi,[esi+eax*8]
	movsd
	movsd
	mov si,[industrynames+2*eax]
	mov [industrynames+2*ebx],si
	mov dl,[initialindustryprobs+eax]
	mov dh,[ingameindustryprobs+eax]
	mov [initialindustryprobs+ebx],dl
	mov [ingameindustryprobs+ebx],dh

	mov dl,[industrymapcolors+eax]
	mov [industrymapcolors+ebx],dl

	mov edx,[industryspecialflags+eax*4]
	mov [industryspecialflags+ebx*4],edx

	mov dx,[industrycreationmsgs+2*eax]
	mov [industrycreationmsgs+2*ebx],dx

	mov edx,[industryinputmultipliers1+eax*4]
	mov [industryinputmultipliers1+eax*4],edx
	mov edx,[industryinputmultipliers2+eax*4]
	mov [industryinputmultipliers2+eax*4],edx
	mov edx,[industryinputmultipliers3+eax*4]
	mov [industryinputmultipliers3+eax*4],edx

	mov edx,[fundchances+eax*4]
	mov [fundchances+eax*4],edx

	mov dl,[industrycallbackflags+eax]
	mov [industrycallbackflags+ebx],dl
	ret

global setsubstindustry
setsubstindustry:
.next:
	xor edx,edx
	mov dl,[curgrfindustrylist+ebx]
	or dl,dl
	jnz near .alreadyhasoffset

// first, try to find the ID in the current list
	push ecx
	xor ecx,ecx
	mov eax,[curspriteblock]
	mov eax,[eax+spriteblock.grfid]
.findid:
	cmp [industrydataidtogameid+ecx*8+industrygameid.grfid],eax
	jne .nextid
	cmp [industrydataidtogameid+ecx*8+industrygameid.setid],bl
	je .foundid
.nextid:
	inc ecx
	cmp cl,NINDUSTRIES
	jb .findid
// the ID isn't in the list yet - try to find an empty slot for it
	xor ecx,ecx
	movzx edx,byte [climate]
.findemptyid:
	bt [defaultindustriesofclimate+edx*8],ecx
	jc .nextid2
	cmp byte [grfstage],0
	je .foundemptyid
	cmp dword [industrydataidtogameid+ecx*8+industrygameid.grfid],0
	jz .foundemptyid
.nextid2:
	inc ecx
	cmp cl,NINDUSTRIES
	jb .findemptyid

	pop ecx
	mov ax,ourtext(toomanyspritestotal)
	stc
	ret

.invalid_pop:
	pop ecx
.invalid:
	mov ax,ourtext(invalidsprite)
	stc
	ret

.foundemptyid:
	mov [industrydataidtogameid+ecx*8+industrygameid.grfid],eax
	mov [industrydataidtogameid+ecx*8+industrygameid.setid],bl

.foundid:
	mov eax,[curspriteblock]
	mov [industryspriteblock+ecx*4],eax
	mov [curgrfindustrylist+ebx],cl
	inc byte [curgrfindustrylist+ebx]
	xor eax,eax
	lodsb
	cmp al,NINDUSTRIES
	jae .invalid_pop
	mov [substindustries+ecx],al
	pusha
	mov ebx,ecx
	call reloadoldindustry
	mov edi,[industrydatablockptr]
	mov dword [edi+17*NINDUSTRIES+ebx*4],addr(newindu_placechkproc)
	popa
	pop ecx
	jmp short .loopend

.alreadyhasoffset:
	lodsb
	cmp al,NINDUSTRIES
	jae .invalid
	mov [substindustries+edx-1],al
.loopend:
	inc ebx
	dec ecx
	jnz near .next
	clc
	ret

// When overriding an old industry, we simply move every property to the slot to be
// overridden, so everything will use it as if it was the old type
global setindustryoverride
setindustryoverride:
.next:
	xor edx,edx
	xor eax,eax
	lodsb
	mov dl,[curgrfindustrylist+ebx]
	or edx,edx
	jz .ignore		// undefined ID
	dec edx
	cmp al,NINDUSTRIES
	jae .invalid		// invalid destination industry
	cmp dword [industrydataidtogameid+eax*8+industrygameid.grfid],0
	jnz .ignore		// the industry is already overridden
// modify the associated gameid
	mov [curgrfindustrylist+ebx],al
	inc byte [curgrfindustrylist+ebx]
	pusha
// copy all data to the new place
	mov ebx,eax
	mov eax,edx
	call copynewindustrydata
// then restore the original state of the old slot
	mov ebx,eax
	call reloadoldindustry
	popa
// move things in the gameid table and clear old place to allow reusing it
	mov edi,[industrydataidtogameid+edx*8+industrygameid.grfid]
	mov [industrydataidtogameid+eax*8+industrygameid.grfid],edi
	and dword [industrydataidtogameid+edx*8+industrygameid.grfid],0
	mov dl,[industrydataidtogameid+edx*8+industrygameid.setid]
	mov [industrydataidtogameid+eax*8+industrygameid.setid],dl
.ignore:
	inc ebx
	loop .next
	clc
	ret

.invalid:
	mov ax,ourtext(invalidsprite)
	stc
	ret

// layout format: numlayouts(b) layoutlength(d) layout...
// a layout is in the same format as in TTD, except that
// 0xFE for tiletype signals extended types, and is followed by: setid(b) 0
// - OR -
// If a layout begins with 0xfe, an old industry type an layout number follows
// and the layout should be copied from the original
//
// The zero will be replaced with the actual gameid
// layoutlength is replaced with the pointer to the pointer list after the first run

global setindustrylayout
setindustrylayout:
	dec ebx
	xor eax,eax
	lodsb		// numlayouts
	push eax
	mov ecx,eax
	push esi	// we need to remember the starting address for checking the size later
	mov edi,[esi]
	push edi	// save length
	test edi,0xffff0000	// if it's still a length, it can't be bigger than 64K
	jnz .alreadyalloced

// alloc memory for the pointers
	imul edi,ecx,4
	push edi
	call malloccrit
	pop edi
	mov [esi],edi

.alreadyalloced:
	add esi,4
.nextlayout:
	mov al,[esi]	// do we need an old layout?
	cmp al,-2
	je .oldlayout

// we're defining a custom layout whose start address is where we currently are
// save it, then check if the layout is valid
	mov [edi],esi
	add edi,4
.nexttile:
	lodsw
	cmp ax,0x8000	// layout end marker
	je .endlayout
	lodsb
	cmp al,0xfe	// is it a new tile type?
	jne .nexttile

// new tile type - check if it's defined, and lookup gameid
	xor eax,eax
	lodsb

	cmp byte [curgrfindustilelist+eax],0
	jz .error	// industry tile not defined
	push ebx
	push ecx
	mov ebx,[curspriteblock]
	mov ebx,[ebx+spriteblock.grfid]
	movzx ecx,byte [lastindustiledataid]
.finddataid:
	cmp [industiledataidtogameid+ecx*8+industilegameid.grfid],ebx
	jne .nextslot

	cmp [industiledataidtogameid+ecx*8+industilegameid.setid],al
	je .foundit

.nextslot:	
	loop .finddataid
// we shouldn't ever get here - according to curgrfindustilelist, the ID is defined,
// so it must be present in the gameid array somewhere
	ud2

.foundit:
	mov [esi],cl		// store the looked up dataid
	inc esi
	pop ecx
	pop ebx

	jmp short .nexttile

// we're reusing an old layout - just find its offset and copy into our pointer list
.oldlayout:
	inc esi
	push ebx
	xor eax,eax
	lodsb					// industry ID
	mov ebx,[industrydatabackupptr]
	mov ebx,[ebx+925+eax*8]			// ebx->beginning of layout pointer table
	lodsb					// layout#
	mov eax,[ebx+eax*4]			// load the address
	stosd					// and store it in our list
	pop ebx

.endlayout:
	loop .nextlayout

// we're finished; it's time for some sanity check
	pop eax		// length
	pop ecx		// begin address
	test eax,0xffff0000
	jnz .nocheck	// we've checked it before and it passed, the length got replaced by the pointer
	add eax,ecx
	add eax,4	// +4 because the length bytes don't count into the size
	cmp eax,esi
	jne .error_onepop
.nocheck:
// everything is OK - we can update the layout pointer in the layout table
	mov edi,[industrylayouttableptr]
	pop eax			// numlayouts
	lea edi,[edi+ebx*8]
	mov [edi+4],al
	mov eax,[ecx]		// pointer to our pointer table
	mov [edi],eax
	clc
	ret

.error:
	pop eax
	pop eax
.error_onepop:
	pop eax
	mov ax,ourtext(invalidsprite)
	stc
	ret

global getlayoutbyte
getlayoutbyte:
	movzx esi,byte [ebp+2]
	cmp esi,0xfe
	je .ourtile
// reproduce overwritten code
	push eax
	mov eax,[oldindutileacceptsbase]
	mov bh,[eax-2*0xAF+esi]
	pop eax

.checksteep:
	test di,0x10
	jz .nosteep
.deny:
	mov bh,0x10
	mov di,0xf
.nosteep:
	ret

.ourtile:
	add ebp,2
	mov si,[esp+4]
	mov [industrycheck_mainXY],si
	movzx esi,byte [ebp+2]
	movzx esi,byte [industiledataidtogameid+8*esi+industilegameid.gameid]
	test byte [industilecallbackflags+esi],0x10
	jnz .shapecallback
	mov bh,[industilelandshapeflags+esi]
	jmp short .checksteep

.callbackfailed:
	pop eax
	movzx esi,byte [ebp+2]
	movzx esi,byte [industiledataidtogameid+8*esi+industilegameid.gameid]
	mov bh,[industilelandshapeflags+esi]
	jmp short .checksteep

.shapecallback:
	push eax
	xchg eax,esi
	movzx esi,si
	shr esi,4
	shl ecx,4
	or si,cx
	shr ecx,4
	mov byte [grffeature],9
	mov byte [curcallback],0x2f
	call getnewsprite
	mov byte [curcallback],0
	jc .callbackfailed
	test eax,eax
	pop eax

	jz .deny
	xor bh,bh
	ret

global putindutile
putindutile:
//	push esi
//	mov esi,[landscape6ptr]
	call [randomfn]
	mov [landscape6+edi],al
//	mov esi,[landscape7ptr]
	mov byte [landscape7+edi],0
//	pop esi
	and word [landscape3+2*edi],0
	mov al,[ebp+2]
	cmp al,0xFE
	je .ourtile
	mov [landscape5(di)],al
	movzx eax,al
	mov al,[industileoverrides+eax]
	or al,al
	jnz .doconstcallback
	ret

.ourtile:
	add ebp,2
	movzx eax,byte [ebp+2]
	mov [landscape3+1+2*edi],al
	mov al,[industiledataidtogameid+8*eax+industilegameid.gameid]
	mov cl,[substindustile+eax]
	mov [landscape5(di)],cl
//	call .doconstcallback
//	ret

.doconstcallback:
	cmp word [industileanimframes+2*eax],0xffff
	je .noanim
	pusha
	mov ebx,2				// Class 14 function 2 - add animated tile
	mov ebp,[ophandler+0x14*8]
	call [ebp+4]
	popa
	test byte [industileanimtriggers+eax],1
	jz .noconstcallback
	pusha
	mov esi,edi
	mov byte [grffeature],9
	mov byte [curcallback],0x25
	and dword [callback_extrainfo],0
	call getnewsprite
	mov byte [curcallback],0
	jc .leavealone
	mov ebx,edi
	call setindutileanimstage
.leavealone:
	popa	
.noconstcallback:
.noanim:
	ret

var industrypropoffsets 
	dd 0,NINDUSTRIES,3*NINDUSTRIES,5*NINDUSTRIES,7*NINDUSTRIES,8*NINDUSTRIES,10*NINDUSTRIES,14*NINDUSTRIES
	dd 15*NINDUSTRIES,16*NINDUSTRIES
var industrypropsizes
	db 1,0x80        ,0x80        ,0x80         ,1            ,2            ,4             ,1
	db 1             ,1

global setnormalindustryprop
setnormalindustryprop:
	dec ebx
	movzx eax,al
	sub eax,0xb
	movzx ecx,byte [industrypropsizes+eax]
	mov edi,[industrydatablockptr]
	add edi,dword [industrypropoffsets+eax*4]
	or cl,cl
	js .textid
	imul ebx,ecx

	add edi,ebx
	rep movsb
	clc
	ret

.textid:
	lea edi,[edi+2*ebx]
	lodsw
	call lookuppersistenttextid
	stosw
	clc
	ret

global setindustrysoundeffects
setindustrysoundeffects:
	dec ebx
	mov ecx,[industrydatablockptr]
	mov [ecx+21*NINDUSTRIES+ebx*4],esi
	xor eax,eax
	lodsb
	add esi,eax
	clc
	ret

global setconflindustry
setconflindustry:
	dec ebx
	xor ecx,ecx
	mov cl,3
	mov edi,[industrylayouttableptr]
	lea edi,[edi+ebx*8+5]
	movzx edx,byte [climate]

.nexttype:
	xor eax,eax
	lodsb
	or al,al
	js .newtype
	cmp al,NINDUSTRIES
	jae .ignore
	bt [defaultindustriesofclimate+edx*8],eax
	jc .writeit

.ignore:
	mov al,0xff
.writeit:
	stosb
	loop .nexttype
	clc
	ret

.newtype:
	and al,0x7f
	cmp al,NINDUSTRIES
	jae .ignore
	mov al,[curgrfindustilelist+eax]
	or al,al
	jz .ignore
	dec al
	jmp short .writeit

global setindustrymapcolors
setindustrymapcolors:
	xor eax,eax
	lodsb
#if WINTTDX
	call getwincolorfromdoscolor
#endif
	mov [industrymapcolors-1+ebx],al
	clc
	ret

uvard createinitialindustry_nolookup,1,s

var industrycounts, db 25,55,75

uvarb industriestogenerate
uvard industryprobabtotal

global createinitialindustries
createinitialindustries:
	pusha
	movsx eax,word [numberofindustries]
	or eax,eax
	js near .exit
	mov al,[industrycounts+eax]
	mov [industriestogenerate],al

	and dword [industryprobabtotal],0
	xor ecx,ecx
	mov cl,NINDUSTRIES
.mandatoryloop:
	movzx eax,byte [initialindustryprobs+ecx-1]
	or al,al
	jz .nextmandatory

	test byte [industrycallbackflags+ecx-1],1
	jz .noallowcallback

	push eax
	lea eax,[ecx-1]
	xor esi,esi
	mov byte [grffeature],10
	mov dword [callback_extrainfo],0
	mov byte [curcallback],0x22
	call getnewsprite
	mov byte [curcallback],0
	mov esi,eax
	pop eax
	jc .nodisable
	or esi,esi
	jz .nodisable

	mov byte [initialindustryprobs+ecx-1],0
	loop .mandatoryloop

.nodisable:
.noallowcallback:
	add dword [industryprobabtotal],eax
	push ecx
	mov bl,cl
	dec bl
	mov cl,1
	call [createinitialindustry_nolookup]
	pop ecx
	dec byte [industriestogenerate]
.nextmandatory:
	loop .mandatoryloop

	mov cl,[industriestogenerate]
	cmp cl,0
	jbe .exit

.randomloop:
	call [randomfn]
	mul dword [industryprobabtotal]
	xor eax,eax
.nexttype:
	movzx ebx,byte [initialindustryprobs+eax]
	sub edx,ebx
	js .gotit
	inc eax
	jmp short .nexttype

.gotit:
	push ecx
	mov bl,al
	mov cl,1
	call [createinitialindustry_nolookup]
	pop ecx

	loop .randomloop

.exit:
	popa
	ret

global ingamerandomindustry
ingamerandomindustry:
	sub esp,8

	and dword [esp],0
	and dword [esp+4],0

	xor edx,edx
	xor ecx,ecx
	mov cl,NINDUSTRIES-1
.probabsumloop:
	movzx ax,byte [ingameindustryprobs+ecx]
	or ax,ax
	jz .not_avail

	test byte [industrycallbackflags+ecx],1
	jz .avail

	push eax
	push esi
	mov eax,ecx
	xor esi,esi
	mov byte [grffeature],10
	mov dword [callback_extrainfo],1
	mov byte [curcallback],0x22
	call getnewsprite
	mov byte [curcallback],0
	mov edi,eax
	pop esi
	pop eax
	jc .avail
	or edi,edi
	jnz .not_avail

.avail:
	bts [esp],ecx
	add dx,ax

.not_avail:
	dec ecx
	jns .probabsumloop

	cmp dword [esp],0
	jnz .good
	cmp dword [esp+4],0
	jnz .good

	add esp,12
	ret

.good:
	shr eax,16
	mul dx
	xor ebx,ebx
.typeloop:
	bt [esp],ebx
	jnc .skip

	movzx ax,byte [ingameindustryprobs+ebx]
	sub dx,ax
	js .gotit
.skip:
	inc ebx
	jmp short .typeloop

.gotit:
	add esp,8
	ret

global drawmapindustrymode
drawmapindustrymode:
#if !WINTTDX
	push ebx
	movzx ebx,bx
#endif
	movzx ebp,byte [landscape2+ebx]
	imul ebp,industry_size
	add ebp,[industryarrayptr]
	movzx ebp,byte [ebp+industry.type]
	mov dl,[industrymapcolors+ebp]
#if !WINTTDX
	pop ebx
#endif
	ret

global putfarmfields1
putfarmfields1:
// this code runs just after doing random production
	push edi
	mov edi,2
	call randomindustrytrigger
	push edx
	mov edi,esi
	mov edx,2
	call industryanimtrigger
	pop edx
	pop edi

	movzx eax,byte [esi+industry.type]

	test byte [industrycallbackflags+eax],4
	jz .notcustomprod
	mov dword [callback_extrainfo],1
	call doproductioncallback
.notcustomprod:

	test byte [industryspecialflags+eax*4],1
	jnz .dontskip
	add dword [esp],5
.dontskip:
	ret

global cutlmilltrees
cutlmilltrees:
	movzx ebx,byte [esi+industry.type]
	test byte [industryspecialflags+ebx*4],2
	jnz .dontskip
	pop ebx
.dontskip:
	ret

global canindubuiltonwater
canindubuiltonwater:
	mov word [operrormsg2],0x0239
	push eax
	mov al,[ebp+2]
	cmp al,0xfe
	jne .notours
	movzx eax,byte [ebp+4]
	movzx eax,byte [industiledataidtogameid+8*eax+industilegameid.gameid]
	test byte [industilelandshapeflags+eax],0x20
	jnz .skipcheck
.notours:
	movzx eax,byte [esp+14]
	mov al,[industryspecialflags+eax*4]
	xor al,4
	test al,4
	pop eax
	jz .adjust
	ret

.skipcheck:
	pop eax
	mov dh,1	// zf should stay cleared
	ret

// if we exit with zf set, the calling proc will either exit or skip to the next tile
// adjust ebp to skip extra bytes if needed
.adjust:
	cmp byte [ebp+2],0xfe
	jne .adjustdone
	add ebp,2
.adjustdone:
	cmp eax,eax	//set zf again
	ret

global caninduonlybigtown
caninduonlybigtown:
	push eax
	movzx eax,byte [esp+14]
	mov al,[industryspecialflags+eax*4]
	xor al,8
	test al,8
	pop eax
	ret

global caninduonlytown
caninduonlytown:
	push eax
	movzx eax,byte [esp+14]
	mov al,[industryspecialflags+eax*4]
	xor al,0x10
	test al,0x10
	pop eax
	ret

global caninduonlyneartown
caninduonlyneartown:
	push eax
	movzx eax,byte [esp+14]
	mov al,[industryspecialflags+eax*4]
	xor al,0x20
	test al,0x20
	pop eax
	ret

global putfarmfields2
putfarmfields2:
	movzx edi,byte [esi+industry.type]
	test byte [industryspecialflags+edi*4],0x40
	ret

global inducantincrease
inducantincrease:
	cmp byte [climate],0
	jnz .exit
	movzx eax,bl
	mov al,[industryspecialflags+eax*4]
	xor al,0x80
	test al,0x80
.exit:
	ret

global randominducantcreate
randominducantcreate:
	movzx eax,bl
	mov eax,[industryspecialflags+eax*4]
	cmp word [currentdate],30*365+8
	jbe .nocheck1

	bt eax,8
	jc .exit

.nocheck1:
	cmp word [currentdate],40*365+10
	jae .nocheck2

	bt eax,9
	jc .exit

.nocheck2:
	clc
.exit:
	ret

global aioilrigcheck
aioilrigcheck:
	cmp word [ebx+industry.XY],0
	je .exit
	push eax
	movzx eax,byte [ebx+industry.type]
	test byte [industryspecialflags+eax*4+1],4
	pop eax
.exit:
	ret

global genmilairplane
genmilairplane:
	cmp word [edi+industry.XY],0
	je .exit
	movzx eax,byte [edi+industry.type]
	test byte [industryspecialflags+eax*4+1],8
.exit:
	ret

global tickprocmilairplane
tickprocmilairplane:
	movzx edi,byte [edi+industry.type]
	test byte [industryspecialflags+edi*4+1],0x8
	jnz .notreturn
	pop edi
.notreturn:
	ret

global genmilhelicopter
genmilhelicopter:
	cmp word [edi+industry.XY],0
	je .exit
	movzx eax,byte [edi+industry.type]
	test byte [industryspecialflags+eax*4+1],0x10
.exit:
	ret

global tickprocmilhelicopter
tickprocmilhelicopter:
	movzx edi,byte [edi+industry.type]
	test byte [industryspecialflags+edi*4+1],0x10
	jnz .notreturn
	pop edi
.notreturn:
	ret

global gencoalminesubs
gencoalminesubs:
	cmp word [edi+industry.XY],0
	je .exit
	push eax
	movzx eax,byte [edi+industry.type]
	test byte [industryspecialflags+eax*4+1],0x20
	pop eax
.exit:
	ret

global newindumessage
newindumessage:
	movzx edx,byte [esi+industry.type]
	mov edx,[industrycreationmsgs+2*edx]
	ret

global industryproducecargo
industryproducecargo:
	movzx eax,byte [edi+industry.type]

	push edi
	mov esi,edi
	mov edi,4
	call randomindustrytrigger

	mov edi,esi
	mov edx,3
	call industryanimtrigger
	pop edi

	test byte [industrycallbackflags+eax],2+4
	jnz near .customproduction

	shl eax,2
	add eax,industryinputmultipliers
	cmp ch,[edi+industry.accepts]
	je .gotit
	add eax,4*NINDUSTRIES
	cmp ch,[edi+industry.accepts+1]
	je .gotit
	add eax,4*NINDUSTRIES
	cmp ch,[edi+industry.accepts+2]
	je .gotit

	ud2

.gotit:
	mov ecx,eax
	cmp byte [edi+industry.producedcargos],-1
	je .nofirstcargo
	mov eax,ebx
	mul word [ecx]
	test dx,0xff00
	jnz .overflow1
	rol eax,16
	mov ax,dx
	rol eax,16
	shr eax,8
	add word [edi+industry.amountswaiting],ax
	jnc .nooverflow1
.overflow1:
	mov word [edi+industry.amountswaiting],0xffff
.nooverflow1:
.nofirstcargo:

	cmp byte [edi+industry.producedcargos+1],-1
	je .nosecondcargo
	mov eax,ebx
	mul word [ecx+2]
	test dx,0xff00
	jnz .overflow2
	rol eax,16
	mov ax,dx
	rol eax,16
	shr eax,8
	add word [edi+industry.amountswaiting+2],ax
	jnc .nooverflow2
.overflow2:
	mov word [edi+industry.amountswaiting+2],0xffff
.nooverflow2:
.nosecondcargo:
	ret

.customproduction:
	mov edx,edi
	getinduidfromptr edx
	lea edx,[industryincargos+8*edx]
	cmp ch,[edi+industry.accepts]
	je .gotit2
	add edx,2
	cmp ch,[edi+industry.accepts+1]
	je .gotit2
	add edx,2
	cmp ch,[edi+industry.accepts+2]
	je .gotit2

	ud2

.gotit2:
	add [edx],bx
	jnc .nooverflow3
	mov word [edx],0xffff
.nooverflow3:
	mov esi,edi
	and dword [callback_extrainfo],0
	test byte [industrycallbackflags+eax],2
	jnz near doproductioncallback
	ret

%assign indufundwin_width 200
%assign indufundwin_nument 12
%assign indufundwin_listheight 15*indufundwin_nument



var newindufundelemlist
db cWinElemTextBox,cColorSchemeDarkGreen
dw 0, 10, 0, 13, 0x00C5

db cWinElemTitleBar,cColorSchemeDarkGreen
dw 11, indufundwin_width-1, 0, 13, statictext(newindugentitle)

db cWinElemTiledBox,cColorSchemeDarkGreen
dw 0, indufundwin_width-12, 14, 14+indufundwin_listheight
db 1, indufundwin_nument

db cWinElemSlider,cColorSchemeDarkGreen
dw indufundwin_width-11, indufundwin_width-1, 14, 14+indufundwin_listheight,0

db cWinElemSpriteBox,cColorSchemeDarkGreen
dw 0, indufundwin_width-1, 15+indufundwin_listheight, 15+indufundwin_listheight+45,0

db cWinElemTextBox,cColorSchemeDarkGreen
dw 0, indufundwin_width-1, 16+indufundwin_listheight+45, 16+indufundwin_listheight+45+10,statictext(newindugenbutton)

db cWinElemLast

var newindufundtooltips, dw 0x018b,0x018c,ourtext(newindulist_tooltip),0x0190,ourtext(newinduinfo_tooltip)

global openfundindustrywindow
openfundindustrywindow:
	mov cl,0x3b		// cWinTypeIndustryGeneration
	xor edx,edx
	call [BringWindowToForeground]
	jnz .alreadyopen

	mov cx,0x3b
	mov ebx,indufundwin_width + ((16+indufundwin_listheight+45+10+1) << 16)
	or edx,byte -1
	mov ebp,addr(fundindustrywindowhandler)
	call [CreateWindowRelative]
	mov dword [esi+window.elemlistptr],newindufundelemlist

	xor eax,eax
	movzx ebx,byte [climate]

.nexttypeslot:
	bt [defaultindustriesofclimate+8*ebx],eax
	jc .inc

	cmp dword [industrydataidtogameid+eax*8+industrygameid.grfid],0
	je .noinc

.inc:	
	inc byte [esi+window.itemstotal]
.noinc:
	inc eax
	cmp eax,NINDUSTRIES
	jb .nexttypeslot

	mov byte [esi+window.itemsvisible],indufundwin_nument
	bts dword [esi+window.disabledbuttons],5
	mov byte [esi+window.data],0xff

.alreadyopen:
	ret

fundindustrywindowhandler:
	mov bx, cx
	mov esi, edi
	cmp dl, cWinEventRedraw
	jz near induwindow_redraw
	cmp dl, cWinEventClick
	jz near induwindow_click
	cmp dl, cWinEventUITick
	jnz .noGUItick
	push edx
	push esi
	mov ax,0x8000
	call [WindowClicked]
	pop esi
	pop edx
.noGUItick:
	cmp dl, cWinEventTimer
	jz induwindow_timer
	cmp dl, cWinEventMouseToolClose
	jz induwindow_toolclose
	cmp dl, cWinEventMouseToolClick
	jz induwindow_toolclick
	ret

induwindow_toolclose:
induwindow_timer:
	and dword [esi+window.activebuttons],0
	jmp [RefreshWindowArea]

induwindow_toolclick:
	and al,0xf0
	and cl,0xf0

	mov edi,townarray
.nextslot:
	cmp word [edi+town.XY],0
	jne .hastown
	add edi,town_size
	cmp edi,townarray+numtowns*town_size
	jb .nextslot

	movzx ebx,byte [esi+window.data]
	mov bx,[industrynames+2*ebx]
	mov [textrefstack],bx
	mov bx,0x0285		// Can't build xxx here...
	mov dx,0x0286		// ...must build town first
	jmp [errorpopup]

.hastown:
	cmp byte [gamemode],2
	je .scenedit

	mov dl,[esi+window.data]
	mov bl,1
	mov esi,0x40
	mov word [operrormsg1],0x4830	// Can't construct this industry type here...
	call dword [actionhandler]
	cmp ebx,0x80000000
	je .failed

	xor ebx,ebx
	xor al,al
	call [setmousetool]
.failed:
	ret

.scenedit:
	push eax
	push ecx
	mov byte [scenarioeditmodeactive],1
	mov di,cx
	rol di,8
	or di,ax
	ror di,4

	movzx eax,byte [esi+window.data]
	push eax

	mov ebx,2
	mov ebp,[ophandler+0x8*8]
	call [ebp+4]

	cmp al,-1
	pop ebx
	pop eax
	pop ecx
	jnz .ok

	mov bx,[industrynames+2*ebx]
	mov [textrefstack],bx
	mov bx,0x0285		// Can't build xxx here...
	mov dx,[operrormsg2]
	call [errorpopup]
.ok:
	mov byte [scenarioeditmodeactive],0
	ret

induwindow_redraw:
	mov word [textrefstack],0x314
	cmp byte [gamemode],2
	jne .notscened
	mov word [textrefstack],0x23f
.notscened:
	mov word [textrefstack+2],ourtext(newindubuildindustry)
	cmp byte [gamemode],2
	je .buttonok
	movzx eax,byte [esi+window.data]
	or al,al
	js .buttonok
	add eax,[industrydatablockptr]
	test byte [eax],3
	jz .buttonok
	inc word [textrefstack+2]
.buttonok:
	call dword [DrawWindowElements]

	mov cx,[esi+window.x]
	mov dx,[esi+window.y]
	add cx,4
	add dx,17
	mov edi, [currscreenupdateblock]
	mov ah,[esi+window.itemsoffset]

	xor ebx,ebx
	movzx ebp,byte [climate]
.nextindustry:
	bt [defaultindustriesofclimate+8*ebp],ebx
	jc .dontskip

	cmp dword [industrydataidtogameid+ebx*8+industrygameid.grfid],0
	je .skip

.dontskip:
	dec ah
	jns .skip
	cmp ah,-indufundwin_nument
	jl .finishlist

	pusha
	push ebx
	mov ax,cx
	mov cx,dx
	lea ebx,[eax+8]
	lea edx,[ecx+8]
	xor ebp,ebp
	call [fillrectangle]
	inc eax
	inc ecx
	dec ebx
	dec edx
	pop ebp
	movzx ebp,byte [industrymapcolors+ebp]
	call [fillrectangle]
	popa

	pusha
	add cx,10
	mov al,0x10
	cmp bl,[esi+window.data]
	jne .notselected
	mov al,0xc
.notselected:
	mov bx,[industrynames+2*ebx]
	call [drawtextfn]
	popa

	add dx,15

.skip:
	inc ebx
	cmp ebx,NINDUSTRIES
	jb .nextindustry
.finishlist:
	movzx ebx,byte [esi+window.data]
	or bl,bl
	jns .writeinfo
	ret

.writeinfo:
	lea eax,[4*ebx+10*NINDUSTRIES]
	add eax,[industrydatablockptr]
	cmp byte [eax],-1
	jz .nofirstline
	mov bx,0x4827-1			// Requres: xxx
	xor ecx,ecx
.nextcargo:
	inc ebx
	movzx edx,byte [eax]
	shl edx,1
	add edx,[cargotypenamesptr]
	mov dx,[edx]
	mov [textrefstack+2*ecx],dx
	inc ecx
	inc eax
	cmp ecx,3
	jae .drawit
	cmp byte [eax],-1
	jne .nextcargo

.drawit:
	mov cx,[esi+window.x]
	mov dx,[esi+window.y]
	add cx,4
	add dx,15+indufundwin_listheight+3
	pusha
	call [drawtextfn]
	popa
.nofirstline:
	movzx eax,byte [esi+window.data]
	lea eax,[2*eax+8*NINDUSTRIES]
	add eax,[industrydatablockptr]
	cmp byte [eax],-1
	jz .nosecondline

	mov bx,statictext(newindu_onecargo)
	movzx edx,byte [eax]
	shl edx,1
	add edx,[cargotypenamesptr]
	mov dx,[edx]
	mov [textrefstack+2],dx
	movzx edx,byte [eax+1]
	or dl,dl
	js .nosecondcargo
	inc ebx
	shl edx,1
	add edx,[cargotypenamesptr]
	mov dx,[edx]
	mov [textrefstack+4],dx
.nosecondcargo:
	mov [textrefstack],bx
	mov bx,ourtext(newinduproduces)
	mov cx,[esi+window.x]
	mov dx,[esi+window.y]
	add cx,4
	add dx,15+indufundwin_listheight+3+15
	pusha
	call [drawtextfn]
	popa
.nosecondline:
	cmp byte [gamemode],2
	je .nothirdline
	mov ebp,[fundingcost]
	sar ebp, 8
	movzx eax,byte [esi+window.data]
	add eax,7*NINDUSTRIES
	add eax,[industrydatablockptr]
	movzx eax,byte [eax]
	imul eax,ebp
	mov [textrefstack],eax

	mov bx,0x482f		// Cost: $xxx
	mov cx,[esi+window.x]
	mov dx,[esi+window.y]
	add cx,4
	add dx,15+indufundwin_listheight+3+30
	pusha
	call [drawtextfn]
	popa
.nothirdline:
	ret

induwindow_click:
	call [WindowClicked]
	js .exit

	cmp byte [rmbclicked],0
	jne .tooltip

	movzx ecx,cl
	bt dword [esi+window.disabledbuttons],ecx
	jc .exit

	or cl,cl
	jnz .notclosebutton
	jmp [DestroyWindow]

.notclosebutton:
	cmp cl,1
	jnz .nottitlebar
	jmp [WindowTitleBarClicked]
.nottitlebar:
	cmp cl,2
	je near .list
	cmp cl,5
	je .button
.exit:	
	ret

.tooltip:
	mov byte [rmbstate],0
	cmp cl,5
	je .buttontooltip
	movzx eax,cl
	mov ax,[newindufundtooltips+eax*2]
	jmp [CreateTooltip]


.buttontooltip:
	mov ax,ourtext(newindubuild_tooltip)
	cmp byte [gamemode],2
	je .buttontipok
	movzx ebx,byte [esi+window.data]
	or bl,bl
	js .buttontipok
	add ebx,[industrydatablockptr]
	test byte [ebx],3
	jz .buttontipok
	mov ax,ourtext(newinduprospect_tooltip)
.buttontipok:
	jmp [CreateTooltip]


.button:
	cmp byte [gamemode],2
	je .build
	movzx eax,byte [esi+window.data]
	add eax,[industrydatablockptr]
	test byte [eax],3
	jz .build

	bts dword [esi+window.activebuttons],5
	or byte [esi+window.flags],5
	call [RefreshWindowArea]

	mov dl,[esi+window.data]
	xor eax,eax
	xor ecx,ecx
	mov bl,1
	dopatchaction fundprospecting_newindu,jmp

.build:
	btc dword [esi+window.activebuttons],5
	jc .cancelbuild
	push ecx
	push esi
	mov ebx,0xff1
	mov ax,0x3b01
	xor edx,edx
	call [setmousetool]
	pop esi
	pop ecx
	jmp [RefreshWindowArea]

.cancelbuild:
	push ecx
	push esi
	xor ebx,ebx
	xor al,al
	call [setmousetool]
	pop esi
	pop ecx
	jmp [RefreshWindowArea]

	ret	

.list:
	mov ax,bx
	sub ax,[esi+window.y]
	sub ax,14
	mov bl,15
	div bl

	cmp al,indufundwin_nument
	jae .exit

	add al,[esi+window.itemsoffset]

	xor ebx,ebx
	movzx ecx,byte [climate]
.nextindustry:
	bt [defaultindustriesofclimate+8*ecx],ebx
	jc .dontskip

	cmp dword [industrydataidtogameid+ebx*8+industrygameid.grfid],0
	je .skip

.dontskip:
	dec al
	js .gotit

.skip:
	inc ebx
	cmp ebx,NINDUSTRIES
	jb .nextindustry
	ret

.gotit:
	mov byte [esi+window.data],bl
	btr dword [esi+window.disabledbuttons],5

	cmp byte [gamemode],2
	je .nocallback

	push edx
	movzx edx,byte [climate]
	bt [defaultindustriesofclimate+8*edx],ebx
	pop edx
	jnc .notdefault

	

.notdefault:
	test byte [industrycallbackflags+ebx],1
	jz .nocallback
	push esi
	mov eax,ebx
	xor esi,esi
	mov byte [grffeature],10
	mov dword [callback_extrainfo],2
	mov byte [curcallback],0x22
	call getnewsprite
	mov byte [curcallback],0
	pop esi
	jc .nodisable
	or eax,eax
	jz .nodisable

	bts dword [esi+window.disabledbuttons],5

.nodisable:
.nocallback:
	cmp byte [curmousetooltype],1
	jne .dontresettool
	cmp byte [curmousetoolwintype],0x3b
	jne .dontresettool

	push ecx
	push esi
	xor ebx,ebx
	xor al,al
	call [setmousetool]
	pop esi
	pop ecx

.dontresettool:
	jmp [RefreshWindowArea]

// Called during the initialization of a new industry struc
// The old overwritten code pedantly zeroed out 8 bytes that
// are never accessed. We store extra data there instead.
// in:	esi->industry
// safe: eax,ecx
global initnewindustry
initnewindustry:
	call [randomfn]
	mov [esi+industry.random],ax
	mov ax,[currentdate]
	mov [esi+industry.consdate],ax
	and dword [esi+0x32],0
	mov eax,esi
	getinduidfromptr eax
	and dword [industryincargos+8*eax],0
	and dword [industryincargos+8*eax+4],0
	ret

var getincargo_div, dw 1

// get the incoming cargo amount from type 1..3
// eax=variable-0x40 (0-first cargo, 1-second, 2-third)
// esi->industry
// safe:ecx
global getincargo
getincargo:
	mov ecx,esi
	getinduidfromptr ecx
	lea ecx,[industryincargos+8*ecx+industryincargodata.in_amount1]
	movzx eax,word [ecx+2*eax]
	cmp word [getincargo_div],1
	ja .divide		// ignore request to divide by zero
	ret

.divide:
	push edx
	xor edx,edx
	div word [getincargo_div]
	pop edx
	ret

struc productioninstruction
	.subtract_in_1:		resw 1
	.subtract_in_2:		resw 1
	.subtract_in_3:		resw 1
	.add_out_1:		resw 1
	.add_out_2:		resw 1
	.call_again:		resb 1
endstruc_32

doproductioncallback:
	pusha
	movzx eax,byte [esi+industry.type]
	mov edi,esi
	getinduidfromptr edi
	lea edi,[industryincargos+8*edi]

	xor ebp,ebp
	inc ebp

	test byte [industryspecialflags+eax*4+1],0x40
	jz .nodiv

	movzx ebp,byte [esi+industry.prodmultiplier]
.nodiv:

	mov [getincargo_div],bp
	mov byte [grffeature],0xa
	and word [callback_extrainfo+1],0

.again:
	push eax
	call getnewsprite
	jc near .error

	mov ecx,3
.nextininstruction:

	movzx ebx,word [eax+productioninstruction.subtract_in_1+(ecx-1)*2]
	imul ebx,ebp
	test ebx,0xffff0000
	jz .notmuloverflow
	mov bx,0xffff
.notmuloverflow:
	sub [edi+industryincargodata.in_amount1+(ecx-1)*2],bx
	jnc .nottoofew
	and word [ecx+industryincargodata.in_amount1+(ecx-1)*2],0
.nottoofew:
	loop .nextininstruction

	mov cl,2
.nextoutinstruction:
	movzx ebx,word [eax+productioninstruction.add_out_1+(ecx-1)*2]
	imul ebx,ebp
	test ebx,0xffff0000
	jz .notmuloverflow2
	mov bx,0xffff
.notmuloverflow2:
	add [esi+industry.amountswaiting+(ecx-1)*2],bx
	jnc .nottoomuch
	or word [esi+industry.amountswaiting+(ecx-1)*2],0xff
.nottoomuch:
	loop .nextoutinstruction

	inc word [callback_extrainfo+1]
	cmp byte [eax+productioninstruction.call_again],1
	pop eax
	je .again

	mov ebx,esi
	getinduidfromptr ebx
	mov al,0x28
	call [invalidatehandle]

	mov word [getincargo_div],1
	popa
	ret

.error:
	mov word [getincargo_div],1
	pop eax
	popa
	ret

uvard oldinduwindowitemlist
uvard newinduwindowitemlist

global createindustrywindow
createindustrywindow:
	movzx ebp,dx
	imul ebp,industry_size
	add ebp,[industryarrayptr]
	movzx edx,byte [ebp+industry.type]
	xor ebp,ebp
	test byte [industrycallbackflags+edx],2+4
	mov dx,0x40
	jnz .specialprod
	call [CreateWindowRelative]
	mov edx,[oldinduwindowitemlist]
	mov [esi+window.elemlistptr],edx
	ret

.specialprod:
	add ebx, 30<<16
	call [CreateWindowRelative]
	mov edx,[newinduwindowitemlist]
	mov [esi+window.elemlistptr],edx
	ret

global drawinduacceptlist
drawinduacceptlist:
	cmp byte [ebp+industry.accepts],-1
	je .exit
	movzx eax,byte [ebp+industry.type]
	test byte [industrycallbackflags+eax],2+4
	jnz .specialprod
	movzx eax,byte [ebp+industry.accepts]
	cmp al,-1
.exit:
	ret

.specialprod:
	push esi
	push ebp
	push ecx
	push edx

	mov ebx,ebp
	getinduidfromptr ebx
	lea ebx,[industryincargos+8*ebx]
	
	push edi
	mov edi,textrefstack
	xor ecx,ecx
.cargoloop:
	mov ax,6	// no message
	movzx edx,byte [ebp+industry.accepts+ecx]
	cmp dl,-1
	jne .notempty
	stosw
	jmp short .nextcargo

.notempty:
	shl edx,1
	add edx,[cargoamountnnamesptr]
	cmp word [ebx+ecx*2],1
	jne .plural

	sub edx,[cargoamountnnamesptr]
	add edx,[cargoamount1namesptr]

.plural:
	mov ax,[edx]
	stosw
	mov ax,[ebx+ecx*2]
	stosw

.nextcargo:
	inc ecx
	cmp ecx,3
	jb .cargoloop

	pop edi

	pop edx
	pop ecx
	push ecx
	push edx

	mov bx,ourtext(newindu_cargowaiting)
	call [drawtextfn]

	pop edx
	pop ecx
	pop ebp
	pop esi

	add dx,30
	cmp edx,edx	// set zf
	ret

uvarb fakeinduentry,industry_size
// structure:
// 00 W:	XY			/These two must be
// 02 D:	pointer to town		\the same place as in the industry struc
// 06 B:	number of layout
// 07 B:	ground type
// 08 B:	town zone
// 09 B:	distance from town
// 0a B:	heigth of tile
// 0b W:	distance of nearest water tile

newindu_placechkproc:
	test byte [industrycallbackflags+ebx],8
	jnz .collectdata

	clc
	ret

.collectdata:
	mov [fakeinduentry+0],eax

	pusha

	mov ebp,addr(.testwater)
	test byte [industryspecialflags+ebx*4],4	// must be built on water?
	jz .notonwater
	mov ebp,addr(.testdryland)
.notonwater:

	mov cx,ax
	rol ax,4
	ror cx,4
	and ax,0x0ff0
	and cx,0x0ff0

	call [gettileinfo]
// now esi=XY
	mov [fakeinduentry+0xa],dl

// now look for the closest water/land tile (closest using Manhattan distance)

// check for the selected tile (0 distance)

	xor edi,edi
	mov ebx,esi
	call ebp
	jz .distfound

.nextdistance:
	inc edi

	xor ecx,ecx
	mov edx,edi

.nextoffset:

	or ch,ch
	jnz .notpresent
	or dh,dh
	jnz .notpresent

%macro testtile 2

		mov ebx,esi
		%1 bl,cl
		jc %%overflow
		%2 bh,dl
		jc %%overflow
		call ebp
		jz .distfound
	%%overflow:

%endmacro

	testtile add,add
	testtile add,sub
	testtile sub,add
	testtile sub,sub

%undef testtile

.notpresent:
	inc ecx
	dec edx
	jns .nextoffset

	cmp edi,512
	jb short .nextdistance

.distfound:

	mov [fakeinduentry+0xb],di

	push esi
	call gethouseterrain
	mov [fakeinduentry+7],al

	pop eax

	xor edi,edi
	mov ebx,2			// class 3 function 2 - find nearest town and zone
	mov ebp,[ophandler+3*8]
	call [ebp+4]

	mov [fakeinduentry+2],edi
	mov [fakeinduentry+8],dl
	mov eax,ebp
	test ah,ah
	jz .al_ok
	mov al,0xff
.al_ok:
	mov [fakeinduentry+9],al
	popa

	clc
	ret

.testwater:
	mov al,[landscape4(bx)]
	shr al,4
	cmp al,6
	jne .notwater
	cmp byte [landscape5(bx)],0
.notwater:
	ret

.testdryland:
	test byte [landscape4(bx)],0xf0
	ret

doinduplacementcallback:
	pusha
	mov eax,ebx
	mov esi,fakeinduentry
	mov byte [grffeature],0xa
	mov byte [curcallback],0x28
	call getnewsprite
	mov byte [curcallback],0
	jc .invalid
	cmp ax,0x400
	je .allow
	jb .custom

	mov word [operrormsg2],0x0317	// ...can only be built in rainforest areas
	cmp ax,0x402
	je .deny
	mov word [operrormsg2],0x0318	// ...can only be built in desert areas
	cmp ax,0x403
	je .deny
	mov word [operrormsg2],0x0239	// site unsuitable

.deny:
	stc
	popa
	ret

.custom:
	mov esi,[mostrecentspriteblock]
	mov [curmiscgrf],esi
	add ah,0xd4
	call texthandler
	mov [specialerrtext1],esi
	mov word [operrormsg2],statictext(specialerr1)
	jmp short .deny

.invalid:
.allow:
	clc
	popa
	ret

global createindustry_chkplacement
createindustry_chkplacement:
	mov ebp,[industrylayouttableptr]
	mov ebp,[ebp+ebx*8]
	mov ebp,[ebp+edx*4]
	mov [fakeinduentry+6],dl
	test byte [industrycallbackflags+ebx],8
	jnz doinduplacementcallback
	ret

global fundindustry_chkplacement
fundindustry_chkplacement:
	pop eax
	push edx
	push ebp
	dec edx
	mov ebp,[ebp+4*edx]
	mov [fakeinduentry+6],dl
	test byte [industrycallbackflags+ebx],8
	jz .allow
	call doinduplacementcallback
	jnc .allow
	add eax,5
	stc
.allow:
	push eax
	ret

uvard industry_decprod,1,s
uvard industry_incprod,1,s
uvard industry_closedown,1,s
uvard industry_primaryprodchange,1,s

global industryrandomprodchange
industryrandomprodchange:
	mov eax,[industrydatablockptr]		// recreation of
	mov al,[eax+ebx]			// overwritten code
	test byte [industrycallbackflags+ebx],0x10
	jnz .docallback
	ret

.docallback:
	pop eax
	call [randomfn]
	mov [callback_extrainfo],eax
	mov eax,ebx
	mov byte [grffeature],0xa
	mov byte [curcallback],0x29
	call getnewsprite
	mov byte [curcallback],0
	jc .error

	or al,al
	jz .nothing

	cmp al,3
	ja .error

	movzx eax,al
	jmp [industry_decprod+(eax-1)*4]

.nothing:
.error:
	ret

// adjust bx so it points to the middle tile of the industry, not the north corner
global adjustindustrypos
adjustindustrypos:
	push edx
	mov edx,[esi+industry.dimensions]
	shr dh,1
	shr dl,1
	add bx,dx
	pop edx
	ret

global inducheckempty
inducheckempty:
	mov word [operrormsg2],0x0239
	movzx eax,byte [esp+10]
	mov al,[industryspecialflags+eax*4]
	test al,4
	jz .checkground

	cmp bl,0x38
	je .haveflags
	cmp bl,0x30
	jne .haveflags
	test di,0xf
.haveflags:
	ret

.checkground:
	test bl,bl
	jz .haveflags
	cmp bl,0x20
	ret

// called when looking for an empty industry slot
//
// in:	---
// out:	CF=clear:
//		esi->industry
//	CF=set:
//		[operrormsg2]=error message
// safe: al esi
global getindustryslot
getindustryslot:
	mov esi,[industryarrayptr]
	mov al,0

.checknext:
	cmp word [esi+industry.XY],0
	je .done	// carry is clear

	add esi,industry_size
	inc al
	cmp al,90
	jb .checknext

	mov word [operrormsg2],ourtext(toomanyindustries)
	stc

.done:
	ret

global industryrandomsound
industryrandomsound:
	movzx eax,byte [esi+industry.type]
	mov eax,[industryspriteblock+eax*4]
	mov [mostrecentspriteblock],eax
	call [randomfn]				//overwritten
	cmp ax,0x1249				//ditto
	ret
