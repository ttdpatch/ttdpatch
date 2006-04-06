// ExtraSpriteLimit Patch

#include <std.inc>
#include <textdef.inc>
#include <grf.inc>
#include <flags.inc>
#include <veh.inc>
#include <bitvars.inc>

extern currscreenupdateblock,drawsplittextfn,drawspritefn,miscmodsflags
extern numactsprites

// Todolist:
//

// 0, 1, 2 or 3 for trains, road vehicles, ships or planes
// 4 train station sets
// 5 canals
// 6 bridges (unused)
// 7 newhouses

exsfeaturemaxspritesperblockstandard equ 0x3FFF	// the standard region
exsfeaturemaxspritesperblockextrachunks equ (0x3FFF - baseoursprites)

var exsfeatureuseseparatesprites, dd 00010001111b

var exsfeaturemaxspritesperblock
	dd exsfeaturemaxspritesperblockstandard+1*exsfeaturemaxspritesperblockextrachunks  	// 0 trains
	dd exsfeaturemaxspritesperblockstandard+2*exsfeaturemaxspritesperblockextrachunks	// 1 road
	dd exsfeaturemaxspritesperblockstandard+3*exsfeaturemaxspritesperblockextrachunks  	// 2 ships
	dd exsfeaturemaxspritesperblockstandard+4*exsfeaturemaxspritesperblockextrachunks	// 3 planes
	dd exsfeaturemaxspritesperblockstandard 						// 4 stations
	dd exsfeaturemaxspritesperblockstandard 						// 5 canals
	dd exsfeaturemaxspritesperblockstandard 						// 6 bridges (unused)
	dd exsfeaturemaxspritesperblockstandard+5*exsfeaturemaxspritesperblockextrachunks  	// 7 newhouses
	dd exsfeaturemaxspritesperblockstandard 						// 8 specialvars
	dd exsfeaturemaxspritesperblockstandard 						// 9 industry tiles
	dd exsfeaturemaxspritesperblockstandard 						// 10 industries
	dd exsfeaturemaxspritesperblockstandard 						// 11 cargoes
	dd 0											// 12 sounds
	checkfeaturesize exsfeaturemaxspritesperblock, 4

var exsfeaturetospritebaseoffsets
	dd exsfeaturemaxspritesperblockstandard+0*exsfeaturemaxspritesperblockextrachunks 	// 0 trains
	dd exsfeaturemaxspritesperblockstandard+1*exsfeaturemaxspritesperblockextrachunks 	// 1 road
	dd exsfeaturemaxspritesperblockstandard+2*exsfeaturemaxspritesperblockextrachunks 	// 2 ships
	dd exsfeaturemaxspritesperblockstandard+3*exsfeaturemaxspritesperblockextrachunks	// 3 planes
	dd baseoursprites									// 4 stations
	dd baseoursprites									// 5 canals
	dd baseoursprites									// 6 bridges (unused)
	dd exsfeaturemaxspritesperblockstandard+4*exsfeaturemaxspritesperblockextrachunks	// 7 newhouses
	dd 0											// 8 specialvars
	dd baseoursprites									// 9 industry tiles
	dd baseoursprites									// 10 industries
	dd baseoursprites									// 11 cargoes
	dd 0											// 12 sounds
	checkfeaturesize exsfeaturetospritebaseoffsets, 4

var exsnumactspritesptrlist
	dd numactspritesvehtrains	// 0 trains
	dd numactspritesvehrv		// 1 road
	dd numactspritesvehships	// 2 ships
	dd numactspritesvehplanes	// 3 planes
	dd numactsprites		// 4 stations
	dd numactsprites		// 5 canals
	dd numactsprites		// 6 bridges (unused)
	dd numactspritesnewhouses	// 7 newhouses
	dd 0				// 8 specialvars
	dd numactsprites		// 9 industries
	dd numactsprites		// 10 industries
	dd numactsprites		// 11 cargoes
	dd 0				// 12 sounds
	checkfeaturesize exsnumactspritesptrlist, 4

uvard numactspritesvehtrains,1,z
uvard numactspritesvehrv,1,z
uvard numactspritesvehships,1,z
uvard numactspritesvehplanes,1,z


uvard numactspritesnewhouses,1,z



uvarb exscurfeature
uvarb exsspritelistext	// toggles extendend sprite mode for add*sprite, if > 0 it will be decreased every call
uvarb exsdrawsprite	// toggles extendend drawsprites & mouse cursor...


// out:	EBX = maxspritecount 
global exsgetspritecount
exsgetspritecount:
	test dword [miscmodsflags],MISCMODS_SMALLSPRITELIMIT
	jnz .small
	// well, if you get overexited, this can result in a crash when to much memory seems to be allocated
	mov ebx, 16384 + 5*exsfeaturemaxspritesperblockextrachunks + 100  // this should be calculated!
	ret
.small:
	mov ebx, 16384
	ret

global exsresetspritecounts
exsresetspritecounts:
	pusha
	mov esi, 0
.next:
	mov eax, [exsfeaturetospritebaseoffsets+esi*4]
	mov edi,[exsnumactspritesptrlist+esi*4]
	mov [edi], eax
	inc esi
	cmp dword [exsfeaturetospritebaseoffsets+esi*4], 0
	jnz .next
	popa
	ret

// So much code for the status
global exsshowstats
exsshowstats:
	setbase esi,exsnumactspritesptrlist

	// count total active sprites
	mov eax,[BASE exsnumactspritesptrlist+0*4]
	mov ebx,[eax]
	sub ebx,[BASE exsfeaturetospritebaseoffsets+0*4]
	mov eax,[BASE exsnumactspritesptrlist+1*4]
	add ebx,[eax]
	sub ebx,[BASE exsfeaturetospritebaseoffsets+1*4]
	mov eax,[BASE exsnumactspritesptrlist+2*4]
	add ebx,[eax]
	sub ebx,[BASE exsfeaturetospritebaseoffsets+2*4]
	mov eax,[BASE exsnumactspritesptrlist+3*4]
	add ebx,[eax]
	sub ebx,[BASE exsfeaturetospritebaseoffsets+3*4]
	mov eax,[BASE exsnumactspritesptrlist+7*4]
	add ebx,[eax]
	sub ebx,[BASE exsfeaturetospritebaseoffsets+7*4]
	add [edi-10],ebx

	setbase none

	// display that in the first info block
	mov edi, [currscreenupdateblock]
	mov bx, ourtext(grfstatgeninfo1)
	call [drawsplittextfn]

	// now set up rest of the info blocks

	// rail
	mov edi, textrefstack
	mov eax, [exsnumactspritesptrlist]
	mov eax, [eax]
	sub eax, [exsfeaturetospritebaseoffsets]
	stosd
	mov ax,ourtext(grfstatmax)
	stosw
	mov eax, [exsfeaturemaxspritesperblock]
	sub eax, [exsfeaturetospritebaseoffsets]
	stosd

	// road
	mov eax, [exsnumactspritesptrlist+4]
	mov eax, [eax]
	sub eax, [exsfeaturetospritebaseoffsets+4]
	stosd
	mov ax,ourtext(grfstatmax)
	stosw
	mov eax, [exsfeaturemaxspritesperblock+4]
	sub eax, [exsfeaturetospritebaseoffsets+4]
	stosd

	mov edi, [currscreenupdateblock]
	mov bx, ourtext(grfstatgeninfo2)
	call [drawsplittextfn]

	// ship
	mov edi, textrefstack
	mov eax, [exsnumactspritesptrlist+8]
	mov eax, [eax]
	sub eax, [exsfeaturetospritebaseoffsets+8]
	stosd
	mov ax,ourtext(grfstatmax)
	stosw
	mov eax, [exsfeaturemaxspritesperblock+8]
	sub eax, [exsfeaturetospritebaseoffsets+8]
	stosd

	//plane
	mov eax, [exsnumactspritesptrlist+12]
	mov eax, [eax]
	sub eax, [exsfeaturetospritebaseoffsets+12]
	stosd
	mov ax,ourtext(grfstatmax)
	stosw
	mov eax, [exsfeaturemaxspritesperblock+12]
	sub eax, [exsfeaturetospritebaseoffsets+12]
	stosd

	mov edi, [currscreenupdateblock]
	mov bx, ourtext(grfstatgeninfo3)
	call [drawsplittextfn]

	// new houses
	mov edi, textrefstack
	mov eax, [exsnumactspritesptrlist+7*4]
	mov eax, [eax]
	sub eax, [exsfeaturetospritebaseoffsets+7*4]
	stosd
	mov ax,ourtext(grfstatmax)
	stosw
	mov eax, [exsfeaturemaxspritesperblock+7*4]
	sub eax, [exsfeaturetospritebaseoffsets+7*4]
	stosd

	// other
	mov eax, [numactsprites]
	sub eax, baseoursprites
	stosd

	mov ax,ourtext(grfstatmax)
	stosw
	mov ax,16383-baseoursprites
	stosd

	mov bx, ourtext(grfstatgeninfo4)
	ret





// in: 	EBX = spritenumber (real)
// out:	EBX = spritenumber (faked)
exsrealtofeaturesprite:
	push eax
	push esi
	movzx eax, byte [exscurfeature]
	mov esi, [exsfeaturetospritebaseoffsets+eax*4]
	sub ebx, esi
	add ebx, baseoursprites
	pop esi
	pop eax
	mov byte [exscurfeature], 0
	ret

// the same with eax
global exsrealtofeaturespriteeax
exsrealtofeaturespriteeax:
	push ebx
	push esi
	movzx ebx, byte [exscurfeature]
	mov esi, [exsfeaturetospritebaseoffsets+ebx*4]
	sub eax, esi
	add eax, baseoursprites
	pop esi
	pop ebx
	mov byte [exscurfeature], 0
	ret


// in: 	EBX = spritenumber (faked) => baseoursprites
// out:	EBX = spritenumber (real)
exsfeaturespritetoreal:
	cmp ebx, baseoursprites
	jb .ttdorgsprite
	push eax
	push esi
	sub ebx, baseoursprites
	movzx eax, byte [exscurfeature]
	mov esi, [exsfeaturetospritebaseoffsets+eax*4]
	add ebx, esi
	pop esi
	pop eax
.ttdorgsprite:
	mov byte [exscurfeature], 0
	ret

// same but useing eax
exsfeaturespritetorealeax:
	cmp eax, baseoursprites
	jb .ttdorgsprite
	push ebx
	push esi
	sub eax, baseoursprites
	movzx ebx, byte [exscurfeature]
	mov esi, [exsfeaturetospritebaseoffsets+ebx*4]
	add eax, esi
	pop esi
	pop ebx
.ttdorgsprite:
	mov byte [exscurfeature], 0
	ret

// DrawSprite Patches
global drawspriteandebx
drawspriteandebx:
	and ebx, 3FFFh	//overwritten
	cmp byte [exsdrawsprite], 1
	mov byte [exsdrawsprite], 0
	jz exsfeaturespritetoreal
	ret

global drawspriteandeax
drawspriteandeax:
	and eax, 3FFFh	//overwritten
	cmp byte [exsdrawsprite], 1
	mov byte [exsdrawsprite], 0
	jz exsfeaturespritetorealeax
	ret


// called after storeing a spritenumber
global addspritetodisplayafterspritenumber
addspritetodisplayafterspritenumber:
	and ebx, 3FFFh	// overwritten by icall
//	cmp bx, baseoursprites
//	jb .done		//otherwise newhouses and maybe other patches don't work
	cmp byte [exsspritelistext], 0
	jnz .ext
.done:
	mov byte [exsspritelistext], 0
	mov word [ebp+0x1C], 0	// No new feature needed
	ret
.ext:
	movzx esi, byte [exscurfeature]
	mov word [ebp+0x1C], si	//it's normally a byte, but so we don't need to stack around
	mov byte [ebp+0x1D], 1
	call exsfeaturespritetoreal
	//mov byte [exsspritelistext], 0
	dec byte [exsspritelistext]
	ret
;endp

global addlinkedspritetodisplayafterspritenumber
addlinkedspritetodisplayafterspritenumber:
	and ebx, 3FFFh	// overwritten by icall
//	cmp bx, baseoursprites
//	jb .done		//otherwise newhouses and maybe other patches don't work
	cmp byte [exsspritelistext], 0
	jnz .ext
.done:
	mov byte [exsspritelistext], 0
	mov word [ebp+0x0E], 0	// No new feature needed
	ret
.ext:
	movzx esi, byte [exscurfeature]
	mov word [ebp+0x0E], si	//it's normally a byte, but so we don't need to stack around
	mov byte [ebp+0x0F], 1
	call exsfeaturespritetoreal
	//mov byte [exsspritelistext], 0
	dec byte [exsspritelistext]
	ret
;endp

global addrelspritetodisplayspritenumber
addrelspritetodisplayspritenumber:
	mov [ebp], ebx	// overwritten by icall
	mov word [ebp+4], ax

	and ebx, 3FFFh
//	cmp bx, baseoursprites
//	jb .done		//otherwise newhouses and maybe other patches don't work
	cmp byte [exsspritelistext], 0
	jnz .ext
.done:
	mov byte [exsspritelistext], 0
	mov word [ebp+0x0C], 0	// No new feature needed
	ret
.ext:
	movzx esi, byte [exscurfeature]
	mov word [ebp+0x0C], si	//it's normally a byte, but so we don't need to stack around
	mov byte [ebp+0x0D], 1
	//mov byte [exsspritelistext], 0
	dec byte [exsspritelistext]
	ret
;endp

global addgroundspritetodisplayspritenumber
addgroundspritetodisplayspritenumber:
	mov dword [ebp+4], 0	// overwritten by icall
	and ebx, 3FFFh
//	cmp bx, baseoursprites
//	jb .done		//otherwise newhouses and maybe other patches don't work
	cmp byte [exsspritelistext], 0
	jnz .ext
.done:
	mov byte [exsspritelistext], 0
	mov word [ebp+0x0E], 0	// No new feature needed
	ret
.ext:
	push esi
	movzx esi, byte [exscurfeature]
	mov word [ebp+0x0E], si	//it's normally a byte, but so we don't need to stack around
	mov byte [ebp+0x0F], 1
	pop esi
	//mov byte [exsspritelistext], 0
	dec byte [exsspritelistext]
	ret
;endp



global drawgroundspritesgetsprite
drawgroundspritesgetsprite:
	mov bx, [ebp+0x0E]
	mov byte [exscurfeature], bl
	mov byte [exsdrawsprite], bh
	mov ebx, dword [ebp]
	jmp [drawspritefn]

global displayregularspritesstdspritedescgetsprite
displayregularspritesstdspritedescgetsprite:
	mov bx, [ebp+0x1C]
	mov byte [exscurfeature], bl
	mov byte [exsdrawsprite], bh
	mov ebx, dword [ebp]
	jmp [drawspritefn]

global displayregularspritesrelspritedescgetsprite
displayregularspritesrelspritedescgetsprite:
	mov bx, [esi+0x0C]
	mov byte [exscurfeature], bl
	mov byte [exsdrawsprite], bh
	mov ebx, dword [esi]
	jmp [drawspritefn]

global displayregularspriteslinkedspritedescgetsprite
displayregularspriteslinkedspritedescgetsprite:
	mov bx, [esi+0x0E]
	mov byte [exscurfeature], bl
	mov byte [exsdrawsprite], bh
	mov ebx, dword [esi]
	jmp [drawspritefn]



// Feature specific patches:
//vehicles
global collectvehiclesprites
collectvehiclesprites:
	push ebx
	mov bl, [esi+veh.class]	
	sub bl, 10h
	cmp bl, 3
	ja .special
	mov [exscurfeature], bl
	mov byte [exsspritelistext], 1
.special:
	pop ebx
	movzx si, [esi+veh.ysize] //overwritten
	ret


global updatevehiclespritebox
updatevehiclespritebox:
	and ebp, 0x3FFF //overwritten
	push ebx
	mov bl, [esi+veh.class]	
	sub bl, 10h
	cmp bl, 3
	ja .special
	mov [exscurfeature], bl
	xchg ebx, ebp
	call exsfeaturespritetoreal
	xchg ebx, ebp
.special:
	pop ebx
	ret


uvarb exsmousecursor,1,z
uvarb exsmousecursorfeature,1,z

global setmousecursorsprite
setmousecursorsprite:
	and ebx, 0x3FFF //overwritten
	cmp byte [exsdrawsprite], 0 
	mov byte [exsdrawsprite], 0
	jnz .extended
	mov byte [exsmousecursor], 0
	ret

.extended:
	push ebx
	mov byte [exsmousecursor], 1
	mov bl, byte [exscurfeature]
	mov byte [exsmousecursorfeature], bl
	pop ebx
	call exsfeaturespritetoreal	// for proper reading sprite relative
	ret

global drawmousecursor
drawmousecursor:
	mov bl, byte [exsmousecursor]	
	mov bh, byte [exsmousecursorfeature]
	mov byte [exsdrawsprite], bl
	mov byte [exscurfeature], bh
	mov ebx, [curmousecursor] // overwritten
	ret
