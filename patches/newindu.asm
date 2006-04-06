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

// Called when an animation trigger event happens to the industry.
// Check all tiles and invoke callback 0x25 if they have it enabled for the current event.
// in:	edx: bit number of the event
//	edi->industry
// preserves all registers
industryanimtrigger:
	pusha

// set up the fields that will stay the same for all callbacks
	mov byte [grffeature],9
	mov byte [curcallback],0x25
	and dword [callback_extrainfo],0
	mov [callback_extrainfo],dl

	movzx esi,word [edi+industry.XY]
	movzx ecx,word [edi+industry.dimensions]

// esi will go through all tiles in the bounding rectangle of the industry
// ch will contain the number of remaining rows, cl the number of remaining
// tiles in the current row
.yloop:
// start the next row
	mov cl,[edi+industry.dimensions]
	push esi
.xloop:
// is it an industry tile?
	mov bl,[landscape4(si)]
	and bl,0xf0
	cmp bl,0x80
	jne .dontneed
	
// does it belong to the industry we're checking?
	movzx ebx,byte [landscape2+esi]
	imul ebx,industry_size
	add ebx,[industryarrayptr]
	cmp ebx,edi
	jne .dontneed

	mov ebx,esi
	call getindustileid
	jnc .dontneed					// old tiles can't have CB 25
	movzx eax,al

// is the callback enabled for this event?
	bt dword [industileanimtriggers+eax],edx
	jnc .dontneed

// do the callback, everything is set up for it now
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

// How the new industry handling works:
// Industry data arrays are accessed from too many places, so we can't follow the same method as
// for houses and industry tiles. Instead, we backup the data to a safe place, then modify it in
// its original place, so most functions can go unpatched. We can still add new industries, though.
// Unpatched TTD has 37 industry slots having static data of the 37 possible industry types.
// TTDPatch allows those slots that aren't used by the current climate to be reused by new industries.
// This scheme allows modifying industry data without patching most of the industry code.
// The only remaining problems are hard-coded type checks where an industry is checked against a fixed
// type number. These must be patched; we replace the old checks with a bit test in a bitmask, so the
// new industries can choose to copy any special behaviour present in the game, while disabling the
// behavior is still easy.

// points to the beginning of industry data block
// this block starts at baIndustryProductionFlags and ends at the end of paIndustryRandomSoundEffects
// (size: 925 bytes, 25*NINDUSTRIES)
// see the IDA DB for details
//uvard industrydatablockptr,1,s

// points to the layout table (saIndustryLayoutDataTable)
uvard industrylayouttableptr,1,s

// points to a memory block allocated by the patch and contains the original data block and layout table
// this block is read when initializing new industries, but is never written to after filling it
uvard industrydatabackupptr,1,s

// unpatched TTD doesn't have an industry name table, but instead depends on the fact that the name textID
// can be found by adding the type number to a fixed base ID. This is no longer true with new industries,
// so we must supply a name table.
uvarw industrynames,NINDUSTRIES

// slotNum<->setID mapping stored in savegames, allows us to find the according GRF again after loading the game
// if 0 is stored for a slot that has an old type enabled on this climate, it means the old type is available
// OTOH, nonzero values mean the old industry is overridden
uvard industrydataidtogameid,2*NINDUSTRIES

struc industrygameid
	.grfid:		resd 1
	.setid:		resb 1
endstruc_32

// helper bitmasks, containing the old industry types enabled on the current climate
// this is necessary so we can reuse unused slots for new industries
// (32 bits aren't enough, so we use 64 bits per climate. BT doesn't care as long as its
//  parameter is given in a register)
var defaultindustriesofclimate
	// temperate
	dd 00000000000001000001101101111111b,00000b
	// arctic
	dd 00000000000000011110101010011011b,00000b
	// tropical
	dd 00000011111110110010110000010000b,00000b
	// silly
	dd 11111100000000000000000000000000b,11111b

// The old code has count/type pairs for initial industry generation. We convert this to
// an array of probabilities and store that here, since this makes the handling easier.
// (NINDUSTRIES bytes for each climate)
uvarb orginitialindustryprobs,4*NINDUSTRIES

// The old code uses a fixed-size array filled with different type numbers to control the
// probabilities of the industry types during the game. We convert that to simple probabilities as well.
// (NINDUSTRIES bytes for each climate)
uvarb orgingameindustryprobs,4*NINDUSTRIES

// Counterparts of the above two arrays for the current climate. These arrays are the ones actually read
// by functions, and can be modified by GRFs
uvarb initialindustryprobs,NINDUSTRIES

uvarb ingameindustryprobs,NINDUSTRIES

// The old code had a map color for each industry tile type. This wouldn't work for new industries, since
// a tile type can be used by more industries at a time. Instead, we have a color per industry type, stored in
// this array
uvarb industrymapcolors,NINDUSTRIES

// The default industry colors, extracted from the original TTD array.
var defaultindustrymapcolors, 	db 0x01+0xd6*WINTTDX
				     db 0xb8,0xc2,0x56,0xbf,0x98,0xae,0xae, 0x0a,0x30,0x0a,0x98,0x0f,0x37,0x0a,0xc2
				db 0x0f,0xb8,0x37,0x56,0x27,0x25,0xd0,0xae, 0x30,0xc2,0x30,0xae,0x27,0x37,0xd0,0x0a
				db 0x25,0xb8,0x98,0xc2,0x0f

// Bitmasks for special industry functions. These bits are checked instead of checking against a fixed industry type,
// so new industries can have the same special effects. This also allows a slot reused by a new industry _not_ to have
// the special effect the original type did.
// Meanings of the bits:
// Bit	Meaning
//  0	The industry periodically plants fields around itself (temperate and arctic farms) 	
//  1	The industry cuts trees around itself and produces its first output cargo from them (lumber mill) 	
//  2	The industry is built on water (oil rig) 	
//  3	The industry can only be built in towns with population larger than 1200 (temperate bank) 	
//  4	The industry can only be built in towns (arctic and tropic banks, water tower) 	
//  5	The industry is always built near towns (toy shop) 	
//  6	Fields are planted around the industry when it's built (all farms) 	
//  7	The industry cannot increase its production on the temperate climate (oil wells) 	
//  8	The industry is built only before 1950 (oil wells) 	
//  9	The industry is built only after 1960 (oil rig) 	
// 10	AI players will attempt to establish air and ship routes going to this industry (oil rig) 	
// 11	The industry can be exploded by a military airplane (oil refinery) 	
// 12	The industry can be exploded by a military helicopter (factory) 	
// 13	The industry can cause a subsidence (coal mine) 	
// 14	Automatic production multiplier handing (No industry has this bit set by default.)
uvard industryspecialflags,NINDUSTRIES

// The default values for the above special flags, ie. a bit is only set if the unpatched TTD industry would
// have the special effect
var defaultindustryspecialflags, 	dd 0x2000,0,0,0,0x800,0x604,0x1000,0,	0,0x41,0,0x180,0x8,0,0,0
					dd 0x10,0,0,0,0,0,0x10,0,		0x40,0x2,0,0,0,0,0x20,0
					dd 0,0,0,0,0

// The old code has hard-coded creation messages. We introduce an array to store message IDs, so they can be
// customized
uvarw industrycreationmsgs,NINDUSTRIES

// Production multipliers. There's 2 words for every incoming type per industry.
// The first word tells how much of the first output cargo is generated from a unit of
// incoming cargo, in 1/256 units. The second word means the same, but for the second output cargo.
uvard industryinputmultipliers,3*NINDUSTRIES

%define industryinputmultipliers1 industryinputmultipliers
%define industryinputmultipliers2 (industryinputmultipliers+NINDUSTRIES*4)
%define industryinputmultipliers3 (industryinputmultipliers+2*NINDUSTRIES*4)

// copy of the original prospecting chances in moreindu.asm
uvard origfundchances, NINDUSTRIES

// callback flags
// Bit	Var. 0C	Callback 	
// 0	22	Determine whether the industry can be built 	
// 1	00	Call the production callback when cargo arrives at the industry 	
// 2	00	Call the production callback every 256 ticks 	
// 3	28	Determine whether the industry can be built on given spot 	
// 4	29	Control random production changes
uvarb industrycallbackflags,NINDUSTRIES

// helper array to hold incoming cargo amounts

struc industryincargodata
	.in_amount1:	resw 1
	.in_amount2:	resw 1
	.in_amount3:	resw 1
			resw 1		// some padding so we can use the *8 multiplier
endstruc_32

// amount of cargo accepted, but not processed by industries
uvard industryincargos,2*90

// Macro to get back the industry ID from its address. It assumes the pointer is actually pointing into the industry array.
%macro getinduidfromptr 1
	sub %1,[industryarrayptr]
	imul %1,1214	/*0x10000/industry_size*/		// multiplying by reciprocal instead of dividing to make things faster
	shr %1,16
%endmacro

// Clear the "waiting cargo" array
global clearindustryincargos
clearindustryincargos:
	mov edi,industryincargos
	mov ecx,2*90
	xor eax,eax
	rep stosd
	ret

// Clear all industry slots from new industries (called before starting/loading a game)
global clearindustrygameids
clearindustrygameids:
	mov edi,industrydataidtogameid
	mov ecx,2*NINDUSTRIES
	xor eax,eax
	rep stosd
	ret

// make a backup of all original industry arrays before overwriting them, and fill some other
// arrays with defaults
global saveindustrydata
saveindustrydata:
// backup the industry data block...
	mov esi,industrydatablock
	mov edi,[industrydatabackupptr]
	mov ecx,925
	rep movsb
// ... and the layout table
	mov esi,[industrylayouttableptr]
	mov ecx,296
	rep movsb
	add esi,0x2d
	xor ecx,ecx

// clear probability arrays, they will be increased later
	mov edi,orgingameindustryprobs
	mov cl,NINDUSTRIES
	xor eax,eax
	rep stosd

	mov edi,orginitialindustryprobs
	mov cl,NINDUSTRIES
	xor eax,eax
	rep stosd

// fill the in-game probabilities - every time a type is encountered, the
// corresponding array element is increased
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

// fill the starting probabilities - increase probabilities according to the
// number pairs, until the 0 terminator is encountered for the climate
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

// save the old funding chances to a safe place so we can restore them later
	mov esi,fundchances
	mov edi,origfundchances
	mov cl,NINDUSTRIES
	rep movsd

	ret

// restore all industry data to the initialization state
global restoreindustrydata
restoreindustrydata:
// restore the data block...
	mov edi,industrydatablock
	mov esi,[industrydatabackupptr]
	mov ecx,925
	rep movsb
// ...and the layout table
	mov edi,[industrylayouttableptr]
	mov ecx,296
	rep movsb
// default industry names are the consecutive textIDs starting from 0x4802
	mov edi,industrynames
	mov eax,0x4802
	mov ecx,NINDUSTRIES
.nextname:
	stosw
	inc eax
	loop .nextname

// the default creation message is 0x482d for every type except temperate forests, where it's 0x482e
	mov edi,industrycreationmsgs
	mov ax,0x482d
	mov cl,NINDUSTRIES
	rep stosw
	inc word [industrycreationmsgs+3*2]		// forest

// load original initial probabilities...
	movzx eax,byte [climate]
	imul eax,NINDUSTRIES
	lea esi,[orginitialindustryprobs+eax]
	mov edi,initialindustryprobs
	mov cl,NINDUSTRIES
	rep movsb

// ...in-game probabilities...
	lea esi,[orgingameindustryprobs+eax]
	mov edi,ingameindustryprobs
	mov cl,NINDUSTRIES
	rep movsb

// ...map colors...
	mov esi,defaultindustrymapcolors
	mov edi,industrymapcolors
	mov cl,NINDUSTRIES
	rep movsb

// ...special flags...
	mov esi,defaultindustryspecialflags
	mov edi,industryspecialflags
	mov cl,NINDUSTRIES
	rep movsd

// ...and funding chances
	mov esi,origfundchances
	mov edi,fundchances
	mov cl,NINDUSTRIES
	rep movsd

// all callback flags are zero by default
	mov edi,industrycallbackflags
	mov cl,NINDUSTRIES
	xor al,al
	rep stosb

// all multipliers are (1, 0)...
	mov edi,industryinputmultipliers
	mov eax,0x00000100
	mov cl,3*NINDUSTRIES
	rep stosd

// ...except for temperate banks, where it's (0, 0)
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

// copy the basic properties of an industry type to a new place
// depending on the pointers passed, this can be used to copy industry
// data between slots or to copy original properties into a slot
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
// first, copy basic properties
	mov esi,[industrydatabackupptr]
	mov edi,industrydatablock
	call copyindustryprops

// copy the 8-byte entry from the layout array
	mov esi,[industrydatabackupptr]
	mov edi,[industrylayouttableptr]
	lea esi,[esi+925+eax*8]
	lea edi,[edi+ebx*8]
	movsd
	movsd

// original name = 0x4802 + type
	mov si,0x4802
	add si,ax
	mov [industrynames+2*ebx],si

// copy probabilities...
	movzx ecx,byte [climate]
	imul ecx,NINDUSTRIES
	add ecx,eax
	mov dl,[orginitialindustryprobs+ecx]
	mov dh,[orgingameindustryprobs+ecx]
	mov [initialindustryprobs+ebx],dl
	mov [ingameindustryprobs+ebx],dh

// ...map color...
	mov dl,[defaultindustrymapcolors+eax]
	mov [industrymapcolors+ebx],dl

// ...special flags...
	mov edx,[defaultindustryspecialflags+eax*4]
	mov [industryspecialflags+ebx*4],edx

// creation message is 482e for forests, 482d for everything else
	mov dx,0x482d
	cmp eax,3
	jne .notforest
	inc edx
.notforest:
	mov [industrycreationmsgs+2*ebx],dx

// multiplier is (0, 0) for temperate banks, (1, 0) for everything else
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

// copy fund chance
	mov edx,[origfundchances+eax*4]
	mov [fundchances+ebx*4],edx

// callback flags are zero by default
	mov byte [industrycallbackflags+ebx],0
	ret

// copy every property between two slots
copynewindustrydata:
// copy basic properties...
	mov esi,industrydatablock
	mov edi,esi
	call copyindustryprops

// ...layout data...
	mov esi,[industrylayouttableptr]
	lea edi,[esi+ebx*8]
	lea esi,[esi+eax*8]
	movsd
	movsd

// ...industry name...
	mov si,[industrynames+2*eax]
	mov [industrynames+2*ebx],si

// ...probabilities...
	mov dl,[initialindustryprobs+eax]
	mov dh,[ingameindustryprobs+eax]
	mov [initialindustryprobs+ebx],dl
	mov [ingameindustryprobs+ebx],dh

// ...map color...
	mov dl,[industrymapcolors+eax]
	mov [industrymapcolors+ebx],dl

// ...special flags...
	mov edx,[industryspecialflags+eax*4]
	mov [industryspecialflags+ebx*4],edx

// ...creation message...
	mov dx,[industrycreationmsgs+2*eax]
	mov [industrycreationmsgs+2*ebx],dx

// ...production multipliers...
	mov edx,[industryinputmultipliers1+eax*4]
	mov [industryinputmultipliers1+eax*4],edx
	mov edx,[industryinputmultipliers2+eax*4]
	mov [industryinputmultipliers2+eax*4],edx
	mov edx,[industryinputmultipliers3+eax*4]
	mov [industryinputmultipliers3+eax*4],edx

// ...fund chances...
	mov edx,[fundchances+eax*4]
	mov [fundchances+eax*4],edx

// ...and callback flags
	mov dl,[industrycallbackflags+eax]
	mov [industrycallbackflags+ebx],dl
	ret

// Called to set the substitute type for an industry. This function assigns
// the setid to an industry slot if this is the first usage of the setid
// Note: since 0 means an unallocated slot in the GRF action handler, we
// add 1 to all industry slot numbers, and subtract 1 in action 0 handlers
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
	bt [defaultindustriesofclimate+edx*8],ecx		// is it occupied by an old industry?
	jc .nextid2
	cmp byte [grfstage],0
	je .foundemptyid
	cmp dword [industrydataidtogameid+ecx*8+industrygameid.grfid],0	// maybe by a new one?
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
// found an empty ID - associate this slot with the industry
	mov [industrydataidtogameid+ecx*8+industrygameid.grfid],eax
	mov [industrydataidtogameid+ecx*8+industrygameid.setid],bl

.foundid:
// remember the mapping for the current GRF
	mov [curgrfindustrylist+ebx],cl
	inc byte [curgrfindustrylist+ebx]

// store the sprite block of the industry (needed for newsounds)
	mov eax,[curspriteblock]
	mov [industryspriteblock+ecx*4],eax

// set the substitute industry type
	xor eax,eax
	lodsb
	cmp al,NINDUSTRIES
	jae .invalid_pop
	mov [substindustries+ecx],al
	pusha
// load all properties of the substitute industry into this slot
	mov ebx,ecx
	call reloadoldindustry
// replace the placement-check function with our special one that prepares things for callback 22
	mov dword [industryplacecheckprocs+ebx*4],addr(newindu_placechkproc)
	popa
	pop ecx
	jmp short .loopend

.alreadyhasoffset:
// this isn't the first prop. 8 setting - just set the substitute type and be done with it
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
// The zero will be replaced with the actual dataid
// layoutlength is replaced with the pointer to the pointer list after the first run

// property 0A - set industry layout
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

// called when checking if a given tile is suitable for an industry tile type,
// just before fetching the tile type from the layout data
// in:	ax, cx: fine X and Y of the current tile
//	di: slope data
//	ebp-> layout entry
// out:	bh: land shape flags for the given industry tile type
//	di: slope data to be used for the rest of processing
//	ebp adjusted so adding 3 will give the next entry
// safe: esi, ???
global getlayoutbyte
getlayoutbyte:
// fetch the first byte - if it's 0xfe, it means a new type
	movzx esi,byte [ebp+2]
	cmp esi,0xfe
	je .ourtile
// reproduce overwritten code
	push eax
	mov eax,[oldindutileacceptsbase]
	mov bh,[eax-2*0xAF+esi]
	pop eax

.checksteep:
// The old code always rejected steep slopes. They still must be forbidden for old
// types and new types that don't have a shape callback, so return a combination
// that will make the following code reject the tile
	test di,0x10
	jz .nosteep
.deny:
	mov bh,0x10
	mov di,0xf
.nosteep:
	ret


.ourtile:
// it's a new industry type; the format is <xoffs> <yoffs> FE <setid> <dataid>
// adjust ebp
	add ebp,2
// dig out the XY of the industry from the stack, so var 43. can keep working
// during callback 2F
	mov si,[esp+4]
	mov [industrycheck_mainXY],si
// get the shape flags
	movzx esi,byte [ebp+2]
	movzx esi,byte [industiledataidtogameid+8*esi+industilegameid.gameid]
	mov bh,[industilelandshapeflags+esi]
// if the shape callback isn't enabled, we're done
	test byte [industilecallbackflags+esi],0x10
	jz .checksteep

.shapecallback:
	push eax
	xchg eax,esi		// eax= gameid; esi=X
	movzx esi,si
	shr esi,4
	shl ecx,4
	or si,cx		// now esi=XY
	shr ecx,4
	mov byte [grffeature],9
	mov byte [curcallback],0x2f
	call getnewsprite
	mov byte [curcallback],0
	jc .callbackfailed
	test eax,eax
	pop eax

// if the callback returned 0, the tile must be denied
// otherwise, pretend it's a flat tile so the further code doesn't reject it
	jz .deny
	xor bh,bh
	ret

// the callback failed, but bh still contains the fallback shape flags
// all we need is popping eax, then resume the default handling
.callbackfailed:
	pop eax
	jmp short .checksteep

// called while putting an industry tile to the landscape, to fill L5
// in:	bx: ID of the containing industry
//	esi-> industry
//	edi: XY
//	ebp-> layout data
// out: ebp adjusted so adding 3 gives the next entry
// safe: eax, ecx
global putindutile
putindutile:
// fill random bits
	call [randomfn]
	mov [landscape6+edi],al
// clear all random triggers
	mov byte [landscape7+edi],0
// clear anim. stage and new type
	and word [landscape3+2*edi],0
// fetch first layout byte
	mov al,[ebp+2]
	cmp al,0xFE
	je .ourtile
// this is an old type, so just repeat overwritten code
	mov [landscape5(di)],al
// if it's overridden, we may need to start animation as for real new tiles
	movzx eax,al
	mov al,[industileoverrides+eax]
	or al,al
	jnz .doconstcallback
	ret

.ourtile:
// it's a new tile type;  the format is <xoffs> <yoffs> FE <setid> <dataid>
// adjust ebp
	add ebp,2
// store gameid in the "new type" field
	movzx eax,byte [ebp+2]
	mov [landscape3+1+2*edi],al
// and store the substitute type in L5
	mov al,[industiledataidtogameid+8*eax+industilegameid.gameid]
	mov cl,[substindustile+eax]
	mov [landscape5(di)],cl
//	call .doconstcallback
//	ret

.doconstcallback:
// if the tile type is animated, start the animation, and call
// the "const. state changed" animation trigger, if enabled
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

// Set random sound effects for the industry. The format is the same as TTD uses, so
// we just need to make the pointer point to the beginning of the data, then skip it.
global setindustrysoundeffects
setindustrysoundeffects:
	dec ebx
	mov [industryrandomsoundptrs+ebx*4],esi
	xor eax,eax
	lodsb
	add esi,eax
	clc
	ret

// Set conflicting industry types. If bit 7 is set, the data is a setID from the current
// GRF, otherwise it's an old industry type.
global setconflindustry
setconflindustry:
	dec ebx
	xor ecx,ecx
	mov cl,3
	mov edi,[industrylayouttableptr]
	lea edi,[edi+ebx*8+5]
// edi now points to "conflicting type" slot
	movzx edx,byte [climate]

.nexttype:
	xor eax,eax
	lodsb
	or al,al
	js .newtype
// an old type - ignore if isn't active at the current climate
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
// a new type from the current GRF - look up the dataid and store that
	and al,0x7f
	mov al,[curgrfindustrylist+eax]
	or al,al
	jz .ignore		// ID not allocated
	dec al
	jmp short .writeit

// Set the map color of the industry. This needs its own proc only to translate colors on Win
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

// points into the CreateInitialRandomIndustries proc so that CX means the real count, not the frequency
uvard createinitialindustry_nolookup,1,s

// number of industries to create on the different industry density settings
var industrycounts, db 25,55,75

uvarb industriestogenerate
uvard industryprobabtotal

// Called in the class 8 initialization handler to create the initial industries on the map.
// The old code simply created a fixed number from all types. We need a more general solution
// that scales well with increasing industry types. We first create one from all available
// types so no cargo chain is broken; then we fill the remaining count with randomly selected
// types, respecting their initial probability.
// safe: all
global createinitialindustries
createinitialindustries:
	movsx eax,word [numberofindustries]
	or eax,eax
	js near .exit				// industry count is set to "none"
	mov al,[industrycounts+eax]
	mov [industriestogenerate],al

// first, we're creating the "mandatory" copies of the industries
// while we're looping through the types, we also compute the sum of probabilities for later

	and dword [industryprobabtotal],0
	xor ecx,ecx
	mov cl,NINDUSTRIES
.mandatoryloop:
	movzx eax,byte [initialindustryprobs+ecx-1]

// we don't make mandatory copies of industries with 0 probability
	or al,al
	jz .nextmandatory

// if the industry has the "type availablity callback" enabled, ask if it is available
	test byte [industrycallbackflags+ecx-1],1
	jz .noallowcallback

	push eax
	lea eax,[ecx-1]
	xor esi,esi
	mov byte [grffeature],10
	mov dword [callback_extrainfo],0		// 0 - initial creation
	mov byte [curcallback],0x22
	call getnewsprite
	mov byte [curcallback],0
	mov esi,eax
	pop eax
	jc .nodisable
	or esi,esi
	jz .nodisable

// the industry isn't available - zero out its probability so it won't be created in the next step, either
	mov byte [initialindustryprobs+ecx-1],0
	loop .mandatoryloop

.nodisable:
.noallowcallback:
// add probability to the total
	add dword [industryprobabtotal],eax
// then create it
	push ecx
	mov bl,cl
	dec bl
	mov cl,1
	call [createinitialindustry_nolookup]
	pop ecx
	dec byte [industriestogenerate]
.nextmandatory:
	loop .mandatoryloop

// all mandatory industries are generated - check if there's space left for random ones
	mov cl,[industriestogenerate]
	test cl,cl
	jle .exit

// create the random industries
.randomloop:
	call [randomfn]
	mul dword [industryprobabtotal]
// now edx is a random number between 0 and (industryprobabtotal-1)
// subtract probabilities from it, and when it goes negative, build the current type
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
	ret

// Called to select a random industry type for creating in-game
// in:	eax: random number, but the low word is used already
// out:	bl: type to build
// safe: all
global ingamerandomindustry
ingamerandomindustry:

// make a scratch variable on stack to store the bitmask of types available
	sub esp,8
	and dword [esp],0
	and dword [esp+4],0

// compute the sum of probabilities (in edx) and find available types
	xor edx,edx
	xor ecx,ecx
	mov cl,NINDUSTRIES-1
.probabsumloop:
	movzx ax,byte [ingameindustryprobs+ecx]
	or ax,ax
	jz .not_avail

// if the industry has the "type availablity callback" enabled, ask if it is available
	test byte [industrycallbackflags+ecx],1
	jz .avail

	push eax
	push esi
	mov eax,ecx
	xor esi,esi
	mov byte [grffeature],10
	mov dword [callback_extrainfo],1	// 1: random in-game creation
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
// set the type as available and add probability
	bts [esp],ecx
	add dx,ax

.not_avail:
	dec ecx
	jns .probabsumloop

// if there are no available types, exit the caller to avoid deadlock
	cmp dword [esp],0
	jnz .good
	cmp dword [esp+4],0
	jnz .good

	add esp,12
	ret

// find a type with the same method as above
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
	add esp,8		// remove scratch var
	ret

// Called to find the color of an industry tile on the map in the "Industries" mode
// The old code stored one color for every tile type, or new one has one color per industry type
// in:	bx: XY
// out:	dl: color
// safe: ebp,???
global drawmapindustrymode
drawmapindustrymode:
#if WINTTDX
	movzx ebp,byte [landscape2+ebx]
#else
	movzx ebp,bx
	movzx ebp,byte [landscape2+ebp]
#endif
	imul ebp,industry_size
	add ebp,[industryarrayptr]
	movzx ebp,byte [ebp+industry.type]
	mov dl,[industrymapcolors+ebp]
	ret

// Called after industry production, instead of a cmp/jnz pair checking for farms
// Do some extra things after the production, then check the special flags instead of
// a hard-coded type
// in:	esi-> industry
// safe: all but esi
global putfarmfields1
putfarmfields1:
// activate random triggers and animation triggers
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

// do the periodical production callback
	test byte [industrycallbackflags+eax],4
	jz .notcustomprod
	mov dword [callback_extrainfo],1
	call doproductioncallback
.notcustomprod:

// we've overwritten a jnz +5, so adjust the return address if the industry doesn't want fields
	test byte [industryspecialflags+eax*4],1
	jnz .dontskip
	add dword [esp],5
.dontskip:
	ret

// Called instead of a cmp/jnz locret combination that checks for lumber mills. Check special flags
// instead of hard-coded type.
// in:	esi-> industry
// safe: ebx,???
global cutlmilltrees
cutlmilltrees:
	movzx ebx,byte [esi+industry.type]
	test byte [industryspecialflags+ebx*4],2
	jnz .dontskip
	pop ebx
.dontskip:
	ret

// called to decide whether a watered tile is suitable for an industry
// in:	registers filled by GetTileTypeHeightInfo
//	byte [esp+6]: (before the call) industry type
// out:	zf set if only water is suitable
//	(bx, dh and di will be read in later code)
// safe: ???
global canindubuiltonwater
canindubuiltonwater:
// restore the "Site unsuitable" error message, it may have been overwritten
	mov word [operrormsg2],0x0239
	push eax
	mov al,[ebp+2]
	cmp al,0xfe
	jne .notours
// a new tile type - check for the special shape flag that allows to skip the check entirely
	movzx eax,byte [ebp+4]
	movzx eax,byte [industiledataidtogameid+8*eax+industilegameid.gameid]
	test byte [industilelandshapeflags+eax],0x20
	jnz .skipcheck
.notours:
	movzx eax,byte [esp+14]			// industry type
	mov al,[industryspecialflags+eax*4]
	xor al,4
	test al,4
	pop eax
// now zf is set for water industries
	jz .adjust
	ret

.skipcheck:
// skip the check by fooling TTD into thinking this is a non-full-water tile
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

// called instead a cmp against temperate banks
// check the special flag instead of the slot#
// in:	byte [esp+6]: (before the call) industry type
// out: zf set to allow in big towns only
// safe: ???
global caninduonlybigtown
caninduonlybigtown:
	push eax
	movzx eax,byte [esp+14]
	mov al,[industryspecialflags+eax*4]
	xor al,8
	test al,8
	pop eax
	ret

// called instead a cmp against non-temperate banks
// check the special flag instead of the slot#
// in:	byte [esp+6]: (before the call) industry type
// out: zf set to allow in towns only
// safe: ???
global caninduonlytown
caninduonlytown:
	push eax
	movzx eax,byte [esp+14]
	mov al,[industryspecialflags+eax*4]
	xor al,0x10
	test al,0x10
	pop eax
	ret

// called instead a cmp against toy shops
// check the special flag instead of the slot#
// in:	byte [esp+6]: (before the call) industry type
// out: zf set to allow near towns only
// safe: ???
global caninduonlyneartown
caninduonlyneartown:
	push eax
	movzx eax,byte [esp+14]
	mov al,[industryspecialflags+eax*4]
	xor al,0x20
	test al,0x20
	pop eax
	ret

// called instead of a check against temperate and non-temperate farms, after creating the industry
// check the special flag instead of the slot#
// in:	esi-> industry
// out:	zf cleared to plant fields around industry
// safe: ???
global putfarmfields2
putfarmfields2:
	movzx edi,byte [esi+industry.type]
	test byte [industryspecialflags+edi*4],0x40
	ret

// called instead of a cmp against oil wells in temperate
// check the special flag instead of the slot#
// in:	bl: industry type
// out:	zf set to prevent industry from increasing production
// safe: eax, ???
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

// Called to check if the current industry can be created randomly in-game
// (used for limiting oil wells and oil rigs in time)
// check the special flags instead of the slot#
// in:	bl: industry type
// out:	cf set to disallow building
// safe: eax, ???
global randominducantcreate
randominducantcreate:
	movzx eax,bl
	mov eax,[industryspecialflags+eax*4]
	cmp word [currentdate],30*365+8
	jbe .nocheck1				// 1950 hasn't passed yet, allow oil wells

	bt eax,8
	jc .exit

.nocheck1:
	cmp word [currentdate],40*365+10
	jae .nocheck2				// 1960 has already passed, allow oil rigs

	bt eax,9
	jc .exit

.nocheck2:
	clc
.exit:
	ret

// Called when the AI is planning a new route, to check for oil rigs
// check the special flags instead of the slot#
// in:	ebx-> industry
// out:	zf set if not oil rig
// safe: ???
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

// Called while generating a military airplane, to check for oil refineries
// check the special flags instead of the slot#
// in:	edi-> industry
// out:	zf clear if industry is suitable for the airplane
// safe: ???
global genmilairplane
genmilairplane:
	cmp word [edi+industry.XY],0
	je .exit
	movzx eax,byte [edi+industry.type]
	test byte [industryspecialflags+eax*4+1],8
.exit:
	ret

// Called while processing a military airplane, to check if it's on target yet
// check the special flags instead of the slot#
// in:	edi-> industry
// out:	exit caller if not on target
// safe: edi, ???
global tickprocmilairplane
tickprocmilairplane:
	movzx edi,byte [edi+industry.type]
	test byte [industryspecialflags+edi*4+1],0x8
	jnz .notreturn
	pop edi
.notreturn:
	ret

// Called while generating a military helicopter, to check for factories
// check the special flags instead of the slot#
// in:	edi-> industry
// out:	zf clear if industry is suitable for the helicopter
// safe: ???
global genmilhelicopter
genmilhelicopter:
	cmp word [edi+industry.XY],0
	je .exit
	movzx eax,byte [edi+industry.type]
	test byte [industryspecialflags+eax*4+1],0x10
.exit:
	ret

// Called while processing a military helicopter, to check if it's on target yet
// check the special flags instead of the slot#
// in:	edi-> industry
// out:	exit caller if not on target
// safe: edi, ???
global tickprocmilhelicopter
tickprocmilhelicopter:
	movzx edi,byte [edi+industry.type]
	test byte [industryspecialflags+edi*4+1],0x10
	jnz .notreturn
	pop edi
.notreturn:
	ret

// Called while planning a coal mine subsidence, to check if the industry is a coal mine
// check the special flags instead of the slot#
// in:	edi-> industry
// out:	zf clear if industry is suitable for subsidence
// safe: ???
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

// Called while creating the news message for a new industry.
// Allow the hard-coded messages to be replaced by custom ones
// in:	esi-> industry
// out:	dx: message ID
// safe: ???
global newindumessage
newindumessage:
	movzx edx,byte [esi+industry.type]
	mov edx,[industrycreationmsgs+2*edx]
	ret

// Called when an industry accepts cargo from a vehicle, to create output cargo
// We want a more sophisticated system than the original TTD
// in:	bx: incoming amount
//	ch: cargo type
//	edi-> industry
// out:	industry struc. adjusted
// safe: eax, ebx, ecx, edx, esi
global industryproducecargo
industryproducecargo:
	movzx eax,byte [edi+industry.type]

// activate the "new cargo arrives" random and animation triggers
	push edi
	mov esi,edi
	mov edi,4
	call randomindustrytrigger

	mov edi,esi
	mov edx,3
	call industryanimtrigger
	pop edi

// if the production callback is enabled, don't do our default calculation
	test byte [industrycallbackflags+eax],2+4
	jnz near .customproduction

// find out which input cargo this is and find the according multiplier
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
// now eax points to the multipliers that need to be used
	mov ecx,eax
// check if we have this output cargo defined
	cmp byte [edi+industry.producedcargos],-1
	je .nofirstcargo
	mov eax,ebx
	mul word [ecx]
// now dx:ax=amount to produce, in 1/256 units
	test dx,0xff00
	jnz .overflow1
	rol eax,16
	mov ax,dx
	rol eax,16
	shr eax,8
// now eax=amount to produce
	add word [edi+industry.amountswaiting],ax
	jnc .nooverflow1
.overflow1:
	mov word [edi+industry.amountswaiting],0xffff
.nooverflow1:
.nofirstcargo:

// the same as above, with the second output cargo
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
// we have the production callback enabled - produce nothing, just remember
// the amount of incoming cargo
	mov edx,edi
	getinduidfromptr edx
	lea edx,[industryincargos+8*edx]
// find out which input cargo this was
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
// and add the amount
	add [edx],bx
	jnc .nooverflow3
	mov word [edx],0xffff
.nooverflow3:
// if the production callback is enabled for incoming cargo, do it now
	mov esi,edi
	and dword [callback_extrainfo],0
	test byte [industrycallbackflags+eax],2
	jnz near doproductioncallback
	ret

// definition of the new "Fund industry"/"Industry generation" window that supports
// a flexible number of industry types

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

// Called to open the "Fund industry" or "Industry generation" window
// Our new code uses the same window for both purposes, with small differences in behavior
// safe: all but edi
global openfundindustrywindow
openfundindustrywindow:
// if it's already open, just bring it to the foreground
	mov cl,0x3b		// cWinTypeIndustryGeneration
	xor edx,edx
	call [BringWindowToForeground]
	jnz .alreadyopen

// create the window
	mov cx,0x3b
	mov ebx,indufundwin_width + ((16+indufundwin_listheight+45+10+1) << 16)
	or edx,byte -1
	mov ebp,addr(fundindustrywindowhandler)
	call [CreateWindowRelative]
	mov dword [esi+window.elemlistptr],newindufundelemlist

// to find out how many items there will be in the list, run through all slots looking
// for available types
	xor eax,eax
	movzx ebx,byte [climate]

.nexttypeslot:
// is it a default industry?
	bt [defaultindustriesofclimate+8*ebx],eax
	jc .inc

// maybe a new industry?
	cmp dword [industrydataidtogameid+eax*8+industrygameid.grfid],0
	je .noinc

.inc:	
	inc byte [esi+window.itemstotal]
.noinc:
	inc eax
	cmp eax,NINDUSTRIES
	jb .nexttypeslot

// set up some other fields
	mov byte [esi+window.itemsvisible],indufundwin_nument
	bts dword [esi+window.disabledbuttons],5
// we'll store the current type selection in the first custom data byte; FFh will mean nothing is selected
	mov byte [esi+window.data],0xff

.alreadyopen:
	ret

// The window handler of our new window. Since most event handlers are rather long, they have
// their own functions, this one only chooses which to call.
// in:	dl-> event ID
//	edi-> window
// safe: all
fundindustrywindowhandler:
	mov bx, cx			// I don't know why this is needed, but every window handler has it, so it's here to be sure...
	mov esi, edi			// edi is inconvenient for storing the window, most functions ecpect it in esi

// Call the event handlers of the events we care about
	cmp dl, cWinEventRedraw
	jz near induwindow_redraw
	cmp dl, cWinEventClick
	jz near induwindow_click
	cmp dl, cWinEventUITick
	jnz .noGUItick
// every UI tick we call a bogus click check to make sure the scroll arrows are unpushed
// it's a kludge, but all TTD windows do the same...
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

// our only button can work in two modes:
// - for fundable industries, it stays down while the player selects the site with a mouse tool
// - for prospectable industries, it behaves as a normal push button
// Therefore, it can pop in two ways: either the tool gets changed or the push time elapses
induwindow_toolclose:
induwindow_timer:
	and dword [esi+window.activebuttons],0
	jmp [RefreshWindowArea]

// When building a fundable industry, this is called when the player selects the site
// AX and CX contain the fine X and Y of the click
induwindow_toolclick:
// get the north corner of the tile
	and al,0xf0
	and cl,0xf0

// make sure there's a town already on map before funding the industry
// if we don't do that, the "fund industry" action will deadlock
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

// in normal gameplay, call the "Fund industry" action for multiplayer safety
	mov dl,[esi+window.data]
	mov bl,1
	mov esi,0x40
	mov word [operrormsg1],0x4830	// Can't construct this industry type here...
	call dword [actionhandler]
	cmp ebx,0x80000000
	je .failed

// and disable the mouse tool if successful, to prevent accidental fundings
	xor ebx,ebx
	xor al,al
	call [setmousetool]
.failed:
	ret

.scenedit:
// in the scenario editor, we call the CreateNewIndustry function instead, that has slightly
// different effect
	push eax
	push ecx
	mov byte [scenarioeditmodeactive],1
// get XY from the fine coordinates
	mov di,cx
	rol di,8
	or di,ax
	ror di,4

// get industry type
	movzx eax,byte [esi+window.data]
	push eax

// and call the functon; it returns -1 in al to report failure
	mov ebx,2
	mov ebp,[ophandler+0x8*8]
	call [ebp+4]

	cmp al,-1
	pop ebx
	pop eax
	pop ecx
	jnz .ok

// show error message if failed
	mov bx,[industrynames+2*ebx]
	mov [textrefstack],bx
	mov bx,0x0285		// Can't build xxx here...
	mov dx,[operrormsg2]
	call [errorpopup]
.ok:
	mov byte [scenarioeditmodeactive],0
// we don't need to disable the tool here; it's free anyway and incorrectly placed industries can be removed
	ret

// redraw the window; we show some details of the currently selected industry type
induwindow_redraw:
// the tile is different in-game and in the scenario editor - put the correct one on the text ref. stack
	mov word [textrefstack],0x314		// Fund industry
	cmp byte [gamemode],2
	jne .notscened
	mov word [textrefstack],0x23f		// Industry generation
.notscened:
// the label of the button can change as well - it's "Build industry" by default, but can change to
// "Fund prospecting to find resources for this industry", in-game for prospectable industries
	mov word [textrefstack+2],ourtext(newindubuildindustry)
	cmp byte [gamemode],2
	je .buttonok
	movzx eax,byte [esi+window.data]
	or al,al
	js .buttonok
	test byte [industryproductionflags+eax],3	// is it extractive or organic?
	jz .buttonok
	inc word [textrefstack+2]			// change textID
.buttonok:
// now we can draw the static elements
	call dword [DrawWindowElements]

// now draw the list elements
	mov cx,[esi+window.x]		// cx will stay since all names start at the same X
	mov dx,[esi+window.y]		// dx will increase with every element
	add cx,4
	add dx,17
	mov edi, [currscreenupdateblock]
	mov ah,[esi+window.itemsoffset]		// ah will indicate where we are relative to the visible part

// we loop through all slots, skipping disabled ones
	xor ebx,ebx
	movzx ebp,byte [climate]
.nextindustry:
// is it a default type?
	bt [defaultindustriesofclimate+8*ebp],ebx
	jc .dontskip

// is it a new type?
	cmp dword [industrydataidtogameid+ebx*8+industrygameid.grfid],0
	je .skip

.dontskip:
	dec ah
// if ah hasn't gone negative yet, we're above the visible part
	jns .skip
// have we already filled the visible part?
	cmp ah,-indufundwin_nument
	jl .finishlist

// draw a small rectangle with the industry color
	pusha
	push ebx
// first a 8x8 black rectangle...
	mov ax,cx
	mov cx,dx
	lea ebx,[eax+8]
	lea edx,[ecx+8]
	xor ebp,ebp
	call [fillrectangle]
// ...then a 6x6 colored rectangle inside it
	inc eax
	inc ecx
	dec ebx
	dec edx
	pop ebp
	movzx ebp,byte [industrymapcolors+ebp]
	call [fillrectangle]
	popa

// now the name itself, 10 pixels to the left, white if selected, black otherwise
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

// the next item will be 15 pixels below
	add dx,15

.skip:
	inc ebx
	cmp ebx,NINDUSTRIES
	jb .nextindustry
.finishlist:
// if nothing is selected, we're done
	movzx ebx,byte [esi+window.data]
	or bl,bl
	jns .writeinfo
	ret

.writeinfo:
// otherwise, draw the accepted and produced cargo types plus the cost

// first the accepted cargoes
	lea eax,[industryacceptedcargos+4*ebx]
// if there's no accepted cargoes, we skip the line entirely
	cmp byte [eax],-1
	jz .nofirstline
// otherwise, loop through the accepted cargoes, updating the textID and filling
// the text. ref. stack
	mov bx,0x4827-1			// Requires: xxx
	xor ecx,ecx
.nextcargo:
	inc ebx				// increase ID to have one more item
	movzx edx,byte [eax]		// get cargo name
	shl edx,1
	add edx,[cargotypenamesptr]
	mov dx,[edx]
	mov [textrefstack+2*ecx],dx	// and store it
	inc ecx
	inc eax
	cmp ecx,3			// have we reached the max?
	jae .drawit
	cmp byte [eax],-1		// have we reached the end?
	jne .nextcargo

.drawit:
// now we can draw the first line
	mov cx,[esi+window.x]
	mov dx,[esi+window.y]
	add cx,4
	add dx,15+indufundwin_listheight+3
	pusha
	call [drawtextfn]
	popa
.nofirstline:
// the second line: produced cargoes
	movzx eax,byte [esi+window.data]
	mov ax,[industryproducedcargos+2*eax]
// if the first item is -1, no cargoes are produced, so skip the line altogether
	cmp al,-1
	jz .nosecondline

// assume we'll have one output cargo
	mov bx,statictext(newindu_onecargo)
// get its name
	movzx edx,al
	shl edx,1
	add edx,[cargotypenamesptr]
	mov dx,[edx]
// and store it
	mov [textrefstack+2],dx

// is there a second cargo?
	test ah,ah
	js .nosecondcargo
// yes - increase textID and repeat the steps above
	inc ebx
	movzx edx,ah
	shl edx,1
	add edx,[cargotypenamesptr]
	mov dx,[edx]
	mov [textrefstack+4],dx
.nosecondcargo:
// draw the line
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
// the third line: the cost
// we don't need to show it in the scenario editor
	cmp byte [gamemode],2
	je .nothirdline

// calculate the actual cost from the base cost and the multiplier
	mov ebp,[fundingcost]
	sar ebp, 8

	movzx eax,byte [esi+window.data]
	movzx eax,byte [industryfundcostmultis+eax]
	imul eax,ebp
// and store it
	mov [textrefstack],eax

// now we can draw the third line and we're done
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

// Click handler. This includes reactions for pushing the button, selecting an industry type
// or right-clicking for tooltips
induwindow_click:
	call [WindowClicked]
	js .exit				// the click wasn't really for us

// now cl is the number of UI element clicked on
	cmp byte [rmbclicked],0
	jne .tooltip				// the right button was pressed - we need to show a tooltip

// if the element is disabled, do nothing
	movzx ecx,cl
	bt dword [esi+window.disabledbuttons],ecx
	jc .exit

// is it the close button?
	test cl,cl
	jnz .notclosebutton
	jmp [DestroyWindow]

.notclosebutton:
// the title bar?
	cmp cl,1
	jnz .nottitlebar
	jmp [WindowTitleBarClicked]
.nottitlebar:
// the list?
	cmp cl,2
	je near .list
// the button?
	cmp cl,5
	je .button
.exit:	
	ret

.tooltip:
	mov byte [rmbstate],0
// the button needs different tooltips for its different captions
	cmp cl,5
	je .buttontooltip
// the others can be looked up from the array
	movzx eax,cl
	mov ax,[newindufundtooltips+eax*2]
	jmp [CreateTooltip]


.buttontooltip:
// we have the "Fund industry" button unless we're in-game and selected a prospectable industry
	mov ax,ourtext(newindubuild_tooltip)
	cmp byte [gamemode],2
	je .buttontipok
	movzx ebx,byte [esi+window.data]
	or bl,bl
	js .buttontipok
	test byte [industryproductionflags+ebx],3
	jz .buttontipok
	mov ax,ourtext(newinduprospect_tooltip)
.buttontipok:
	jmp [CreateTooltip]


.button:
// the player clicked on the button - we need to find out whether it's in the build mode or the prospect mode
	cmp byte [gamemode],2
	je .build				// in the scenario editor, it's always build mode
	movzx eax,byte [esi+window.data]
	test byte [industryproductionflags+eax],3	// is it an organic or extracting industry?
	jz .build

// we're in prospect mode; push the button and set it up to unpush
	bts dword [esi+window.activebuttons],5
	or byte [esi+window.flags],5
	call [RefreshWindowArea]

// then call the special version of "fund prospecting" action, the one that gets an industry type
// instead of a button number
	mov dl,[esi+window.data]
	xor eax,eax
	xor ecx,ecx
	mov bl,1
	dopatchaction fundprospecting_newindu,jmp

.build:
// we're in build mode
// toggle the button
	btc dword [esi+window.activebuttons],5
	jc .cancelbuild			// if the button is already pressed, the player wants to cancel building

// set the mouse tool to "build industry"
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
// the player wants to cancel, so restore the default mouse cursor
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
// the player clicked on the list - find out which type she clicked on
	mov ax,bx
	sub ax,[esi+window.y]
	sub ax,14
	mov bl,15
	div bl
// now al is the 0-based index of the element clicked on, relative to the first visible one

// the click was out of the list
	cmp al,indufundwin_nument
	jae .exit

	add al,[esi+window.itemsoffset]
// now al is the 0-based index in the whole list

// loop through the valid industries until we find the al-th one
	xor ebx,ebx
	movzx ecx,byte [climate]
.nextindustry:
// default industry?
	bt [defaultindustriesofclimate+8*ecx],ebx
	jc .dontskip

// new industry?
	cmp dword [industrydataidtogameid+ebx*8+industrygameid.grfid],0
	je .skip

.dontskip:
	dec al
	js .gotit		// when al goes negative, we're at the correct entry

.skip:
	inc ebx
	cmp ebx,NINDUSTRIES
	jb .nextindustry
// the user clicked on an empty element below the end of the list - do nothing
	ret

.gotit:
// store the new current type
	mov byte [esi+window.data],bl
// enable the button in case it was disabled
	btr dword [esi+window.disabledbuttons],5

// now we may need to ask the industry type whether it's available for building
// in the scenario editor, everything can be built
	cmp byte [gamemode],2
	je .nocallback

// in-game, call the callback if enabled
	test byte [industrycallbackflags+ebx],1
	jz .nocallback
	push esi
	mov eax,ebx
	xor esi,esi
	mov byte [grffeature],10
	mov dword [callback_extrainfo],2		// 2: player tries to build
	mov byte [curcallback],0x22
	call getnewsprite
	mov byte [curcallback],0
	pop esi
	jc .nodisable
	or eax,eax
	jz .nodisable

// the industry isn't available - disable button
	bts dword [esi+window.disabledbuttons],5

.nodisable:
.nocallback:
// if the current mouse tool is ours, go back to the normal cursor to prevent accidental building
// of the wrong industry
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
	and dword [esi+0x32],0			// this one is unused now, but clear it anyway for the future
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

// a production instruction returned by the production callback
// it contains three values to subtract from the three waiting cargo types,
// two values to add the two outgoing cargo types, plus a boolean telling whether to
// call the callback again
struc productioninstruction
	.subtract_in_1:		resw 1
	.subtract_in_2:		resw 1
	.subtract_in_3:		resw 1
	.add_out_1:		resw 1
	.add_out_2:		resw 1
	.call_again:		resb 1
endstruc_32

// Auxiliary function to do the production callback
// in:	esi-> industry
//	[callback_extrainfo] already set up correctly
// preserves everything
doproductioncallback:
	pusha
	movzx eax,byte [esi+industry.type]
	mov edi,esi
	getinduidfromptr edi
	lea edi,[industryincargos+8*edi]
// now eax=industry type; edi->incoming cargo data

// if the special scaling flag isn't set, the division factor is 1
	xor ebp,ebp
	inc ebp

	test byte [industryspecialflags+eax*4+1],0x40
	jz .nodiv

// otherwise, it's the production multiplier
	movzx ebp,byte [esi+industry.prodmultiplier]
.nodiv:

	mov [getincargo_div],bp
	mov byte [grffeature],0xa
	and word [callback_extrainfo+1],0

// Now everything is set up for getnewsprite. We'll keep every needed register untouched
// during the loop, so we don't need to refill them every time
.again:
	push eax
	call getnewsprite
	jc near .error
// now eax-> production instruction

// process the three "in" instructions with a loop
	mov ecx,3
.nextininstruction:

// load value...
	movzx ebx,word [eax+productioninstruction.subtract_in_1+(ecx-1)*2]
// multiply with the division factor to maintain scaling
	imul ebx,ebp
// cap the result to 64K
	test ebx,0xffff0000
	jz .notmuloverflow
	mov bx,0xffff
.notmuloverflow:
// subtract amount, but don't go negative
	sub [edi+industryincargodata.in_amount1+(ecx-1)*2],bx
	jnc .nottoofew
	and word [ecx+industryincargodata.in_amount1+(ecx-1)*2],0
.nottoofew:
	loop .nextininstruction

// the same steps for the two "out" instructions, but add instead of subtracting
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
	or word [esi+industry.amountswaiting+(ecx-1)*2],-1
.nottoomuch:
	loop .nextoutinstruction

// increase the loop counter for the GRF
	inc word [callback_extrainfo+1]
// repeat if the GRF asks so
	cmp byte [eax+productioninstruction.call_again],1
	pop eax
	je .again

// invalidate the corresponding industry window
	mov ebx,esi
	getinduidfromptr ebx
	mov al,0x28
	call [invalidatehandle]

// restore division factor
	mov word [getincargo_div],1
	popa
	ret

.error:
// if an error occurs, quit the loop and restore division factor
	mov word [getincargo_div],1
	pop eax
	popa
	ret

// pointers to the original and the modified industry window
// the modified one has more space in the info part so the incoming cargo stats fit
uvard oldinduwindowitemlist
uvard newinduwindowitemlist

// Called to create the info window of an industry being clicked on
// If the industry has the production callback enabled, show the new window that shows the amounts of
// incoming cargo as well
// in:	everything except dx and ebp set up for CreateWindowRelative
//	dx: industry ID
// out:	esi-> window
// safe: all
global createindustrywindow
createindustrywindow:
	movzx ebp,dx
	imul ebp,industry_size
	add ebp,[industryarrayptr]
// now ebp-> industry
	movzx edx,byte [ebp+industry.type]
// now edx=type
	xor ebp,ebp					// overwritten
// check for the production callback
	test byte [industrycallbackflags+edx],2+4
	mov dx,0x40					// ditto
	jnz .specialprod
// no production callback - reproduce overwritten code
	call [CreateWindowRelative]
	mov edx,[oldinduwindowitemlist]
	mov [esi+window.elemlistptr],edx
	ret

.specialprod:
// production callback is used - add 30 to the height of the window...
	add ebx, 30<<16
	call [CreateWindowRelative]
// ...and use the new layout
	mov edx,[newinduwindowitemlist]
	mov [esi+window.elemlistptr],edx
	ret

// Called when drawing the acceptance list in the industry window
// If the production callback is enabled, draw the amounts of incoming cargoes instead of
// the usual one line
// in:	cx, dx: X and Y of text position
//	ebp-> industry
//	esi-> window
//	edi-> screen update block descriptor
// out:	cx, dx: X and Y of last drawn text, following lines will be relative to this
//	zf set to skip drawing of normal acceptance list
//	eax=first accepted cargo type if zf is clear
// safe: eax, ebx
global drawinduacceptlist
drawinduacceptlist:
// reproduce overwritten code - if there's no incoming cargo, don't draw anything
	movzx eax,byte [ebp+industry.accepts]
	cmp al,-1
	je .exit
// first, check the production callback
	movzx ebx,byte [ebp+industry.type]
	test byte [industrycallbackflags+ebx],2+4
	jnz .specialprod
// restore zf for normal operation
	cmp al,-1
.exit:
	ret

.specialprod:
// we have a production callback - print waiting cargo amounts
	push esi
	push ebp
	push ecx
	push edx

	mov ebx,ebp
	getinduidfromptr ebx
	lea ebx,[industryincargos+8*ebx]
// now ebx-> incoming cargo data
	
// fill up to three slots on the text reference stack with either message 6 (empty string) or cargo amount messages
	push edi
	mov edi,textrefstack
	xor ecx,ecx
.cargoloop:
// fill slot with the empty string if the cargo slot is unused
	mov ax,6
	movzx edx,byte [ebp+industry.accepts+ecx]
	cmp dl,-1
	jne .notempty
	stosw
	jmp short .nextcargo

.notempty:
// get the cargo amount textID; assume that we need the plural one...
	shl edx,1
	add edx,[cargoamountnnamesptr]
	cmp word [ebx+ecx*2],1
	jne .plural

// ... and correct the pointer if there's 1 unit waiting
	sub edx,[cargoamountnnamesptr]
	add edx,[cargoamount1namesptr]

.plural:
// store the textID...
	mov ax,[edx]
	stosw
// ...and the amount
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

// draw the thing
	mov bx,ourtext(newindu_cargowaiting)
	call [drawtextfn]

	pop edx
	pop ecx
	pop ebp
	pop esi

// leave some empty space after the list
	add dx,30
	cmp edx,edx	// set zf
	ret

// fake industry data structure to be used during callback 28 (industry location permissibility)
uvarb fakeinduentry,industry_size
// structure:
// 00 W:	XY			/These two must be
// 02 D:	pointer to town		\the same place as in the industry struc
// 06 B:	number of layout
// 07 B:	ground type
// 08 B:	town zone
// 09 B:	distance from town
// 0a B:	heigth of tile
// 0b W:	distance of nearest water/land tile

// Called as the placement check procedure for new industry types
// The layout isn't known yet, so we don't reject anything here; we just collect some information about the site
// in:	ax: xy of north corner
//	ebx: industry type
// out:	cf set if site is unsuitable
// safe: ???
newindu_placechkproc:
// if we don't have callback 28 enabled, don't collect any info
	test byte [industrycallbackflags+ebx],8
	jnz .collectdata

	// TEST always clears cf, so we're done
	ret

.collectdata:
// store XY
	mov [fakeinduentry+0],eax

	pusha

// first, check whether we need to look for water or dry land, and store the corresponding proc. address in ebp
	mov ebp,addr(.testwater)
	test byte [industryspecialflags+ebx*4],4	// must be built on water?
	jz .notonwater
	mov ebp,addr(.testdryland)
.notonwater:

// make fine X and Y from XY
	mov cx,ax
	rol ax,4
	ror cx,4
	and ax,0x0ff0
	and cx,0x0ff0

	call [gettileinfo]
// now esi=XY
// store height
	mov [fakeinduentry+0xa],dl

// now look for the closest water/land tile (closest using Manhattan distance)
// (edi will contain the current distance)

// check for the selected tile (0 distance)
	xor edi,edi
	mov ebx,esi
	call ebp
	jz .distfound

// the current tile isn't OK - try increasing the distance gradually, and check all tiles
// with the current distance until a correct one is found
// we give up after 512 since that is the largest possible Manhattan distance on a 256x256 map
.nextdistance:
	inc edi

// the tiles with a given Manhattan distance are those where |xoffs|+|yoffs|=dist
// ecx will contain the X offset, and edx the Y offset
// we start from X=0 and Y=dist, then keep increasing X and decreasing Y until Y goes 0
	xor ecx,ecx
	mov edx,edi

.nextoffset:

// when X or Y goes over 255, we'd reference nonexistant tiles
	or ch,ch
	jnz .notpresent
	or dh,dh
	jnz .notpresent

%macro testtile 2
// macro to test a tile, given its relative coordinates to esi, and the signs (add/sub) given as parameters
// it will skip checking tiles out of map

		mov ebx,esi
		%1 bl,cl
		jc %%overflow
		%2 bh,dl
		jc %%overflow
		call ebp
		jz .distfound
	%%overflow:

%endmacro

// since both xoffs and yoffs can be negative and positive, we have 4 tiles to check in each step
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

// store the distance we've found
	mov [fakeinduentry+0xb],di

// gethouseterrain doesn't really assumes the tile being a house tile, so we can use it here
	push esi
	call gethouseterrain
	mov [fakeinduentry+7],al

	pop eax

// find the nearest town, the town zone and the distance
	xor edi,edi
	mov ebx,2			// class 3 function 2 - find nearest town and zone
	mov ebp,[ophandler+3*8]
	call [ebp+4]

	mov [fakeinduentry+2],edi
	mov [fakeinduentry+8],dl

// save distance, capped to 255
	mov eax,ebp
	test ah,ah
	jz .al_ok
	mov al,0xff
.al_ok:
	mov [fakeinduentry+9],al
	popa

	// the last TEST cleared cf, so we're done
	ret

// check for full water tile at bx; zf is set if the tile is OK
.testwater:
	mov al,[landscape4(bx)]
	shr al,4
	cmp al,6
	jne .notwater
	cmp byte [landscape5(bx)],0
.notwater:
	ret

// check for (partly) dry tile at bx; zf is set if the tile is OK
.testdryland:
	test byte [landscape4(bx)],0xf0
	ret

// Auxiliary: call callback 28 and interpret the returned value
// in:	ebx: industry type
//	[fakeinduentry] filled with correct values
// out:	cf set and [operrormsg2] filled if site is denied
//	cf clear if site is OK
// uses: none
doinduplacementcallback:
	pusha
// do the callback
	mov eax,ebx
	mov esi,fakeinduentry
	mov byte [grffeature],0xa
	mov byte [curcallback],0x28
	call getnewsprite
	mov byte [curcallback],0
	jc .invalid
// 0x400 means "allow"
	cmp ax,0x400
	je .allow
// values below 0x400 mean custom error messages
	jb .custom

// values above 0x400 mean "canned" error messages
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
// for custom GRF messages, look up the string and use a special textID for operrormsg2
	mov esi,[mostrecentspriteblock]
	mov [curmiscgrf],esi
	add ah,0xd4
	call texthandler
	mov [specialerrtext1],esi
	mov word [operrormsg2],statictext(specialerr1)
	jmp short .deny

.invalid:
.allow:
// allowing only needs clearing cf
	clc
	popa
	ret

// Called in CreateIndustry, before checking whether a site is suitable for the industry layout
// We can grab the layout number now, and do our callback before the suitablity check
// in:	ebx: industry type
//	edx: layout number
// out:	cf clear and ebp-> layout if the callback result was "allow"
//	cf set if the callback result was "deny"
// safe: ???
global createindustry_chkplacement
createindustry_chkplacement:
	mov ebp,[industrylayouttableptr]		// reproduce
	mov ebp,[ebp+ebx*8]				// overwritten
	mov ebp,[ebp+edx*4]				// code
// store layout#
	mov [fakeinduentry+6],dl
// if the placement callback is enabled, do it now
	test byte [industrycallbackflags+ebx],8
	jnz doinduplacementcallback
	ret

// Called in FundNewIndustry, before checking whether a site is suitable for the industry layout
// We must do the same as above
// in:	ebx: industry type
//	edx: layout number+1
//	ebp-> layout list
// out:	return 5 bytes further and set cf to make the site unsuitable
//	ebp-> layout if returning normally
//	layout number and pointer to layout list on top of stack
// safe: edx,???
global fundindustry_chkplacement
fundindustry_chkplacement:
	pop eax			// remove return address
	push edx		// push type and
	push ebp		// layout pointer
	dec edx
// now edx=layout number
	mov ebp,[ebp+4*edx]
// now ebp-> layout
// save layout#
	mov [fakeinduentry+6],dl
// if the placement callback is enabled, call it
	test byte [industrycallbackflags+ebx],8
	jz .allow
	call doinduplacementcallback
	jnc .allow
	add eax,5		// modify return address
	stc
.allow:
	push eax
	ret

// pointers to parts of the random production change proc that...
uvard industry_decprod,1,s		// ...decrease production
uvard industry_incprod,1,s		// ...increase production
uvard industry_closedown,1,s		// ...initate imminent closedown
uvard industry_primaryprodchange,1,s	// ...decides production change for primary industries

// Called in the beginning of the random production change proc
// Handle callback 29 (random production change) here if enabled
// in:	ebx: industry type
//	esi-> industry
// out:	al: industry production flags, if exiting normally
// safe: all
global industryrandomprodchange
industryrandomprodchange:
	mov al,[industryproductionflags+ebx]	// recreation of overwritten code
// check for the callback
	test byte [industrycallbackflags+ebx],0x10
	jnz .docallback
	ret

.docallback:
	pop eax					// remove return address - we'll return from the caller
// give a random value to the GRF
	call [randomfn]
	mov [callback_extrainfo],eax
// and do the callback
	mov eax,ebx
	mov byte [grffeature],0xa
	mov byte [curcallback],0x29
	call getnewsprite
	mov byte [curcallback],0
	jc .error

// 0 means "do nothing"
	or al,al
	jz .nothing

// values above 3 are an error
	cmp al,3
	ja .error

// call the procedure part defined by the returned value
	movzx eax,al
	jmp [industry_decprod+(eax-1)*4]

.nothing:
.error:
	ret

// Called while looking for the closest industry accepting a cargo type, when a vehicle unloads cargo
// Adjust bx so it points to the middle tile of the industry, not the north corner
// This will result in more realistic "closest" match
// in:	bx: XY of industry
//	esi-> industry
// out:	bx adjusted
// safe: ???
global adjustindustrypos
adjustindustrypos:
	push edx
	mov edx,[esi+industry.dimensions]
	shr dh,1
	shr dl,1
	add bx,dx
	pop edx
	ret

// Called while checking if a tile is "empty", that is, suitable for a layout element type -1
// The old code always checked for water; we check for grass and trees instead for non-water industries
// in:	registers filled by GetTileTypeHeightInfo
// out:	zf clear if site is unsuitable
// safe: eax, ecx, ???
global inducheckempty
inducheckempty:
// restore operrormsg2 to "site unsuitable"; it may have been overwritten
	mov word [operrormsg2],0x0239

// dig up industry type from stack
	movzx eax,byte [esp+10]
	mov al,[industryspecialflags+eax*4]
	test al,4
	jz .checkground

// for water industries, we either need a "void" tile or a full-water one
	cmp bl,0x38
	je .haveflags
	cmp bl,0x30
	jne .haveflags
	test di,0xf
.haveflags:
	ret

.checkground:
// for land industries, we accept grass and trees
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

// Called when deciding if an industry should make a random sound effect
// We need to fill [mostrecentspriteblock] so new sounds work correctly
global industryrandomsound
industryrandomsound:
	movzx eax,byte [esi+industry.type]
	mov eax,[industryspriteblock+eax*4]
	mov [mostrecentspriteblock],eax
	call [randomfn]				//overwritten
	cmp ax,0x1249				//ditto
	ret
