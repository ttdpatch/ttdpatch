// ExtraSpriteLimit Patch

#include <std.inc>
#include <textdef.inc>
#include <grf.inc>
#include <flags.inc>
#include <veh.inc>
#include <bitvars.inc>

extern currscreenupdateblock,drawsplittextfn,drawspritefn,miscmodsflags

vard exsfeatureuseseparatesprites, 00010001111b

// maximum sprites per extended block
%assign exsfeaturemaxspritesperblockextrachunks 0x3FFF - baseoursprites

// Number of sprites in the various extended sprite blocks
%assign EXTCOUNT_OTHER	exsfeaturemaxspritesperblockextrachunks
%assign EXTCOUNT_TRAINS	exsfeaturemaxspritesperblockextrachunks
%assign EXTCOUNT_RVS	exsfeaturemaxspritesperblockextrachunks
%assign EXTCOUNT_SHIPS	8724
%assign EXTCOUNT_PLANES	8724
%assign EXTCOUNT_HOUSES	8724

// Base sprites in the linear 0..65535 sprite space
%assign EXTBASE_OTHER	baseoursprites
%assign EXTBASE_TRAINS	EXTBASE_OTHER+ EXTCOUNT_OTHER+1
%assign EXTBASE_RVS	EXTBASE_TRAINS+EXTCOUNT_TRAINS+1
%assign EXTBASE_SHIPS	EXTBASE_RVS+   EXTCOUNT_RVS+1
%assign EXTBASE_PLANES	EXTBASE_SHIPS+ EXTCOUNT_SHIPS+1
%assign EXTBASE_HOUSES	EXTBASE_PLANES+EXTCOUNT_PLANES+1

// Last sprite used, must be <65535
%assign EXTBASE_END	EXTBASE_HOUSES+EXTCOUNT_HOUSES+1

// Show counts and bases (non-fatal warning)
//%error Counts: EXTCOUNT_OTHER EXTCOUNT_TRAINS EXTCOUNT_RVS EXTCOUNT_SHIPS EXTCOUNT_PLANES EXTCOUNT_HOUSES
//%error Bases: EXTBASE_OTHER EXTBASE_TRAINS EXTBASE_RVS EXTBASE_SHIPS EXTBASE_PLANES EXTBASE_HOUSES EXTBASE_END

%if EXTBASE_END>=65535
	%error "Extended sprite limit too large (EXTBASE_END sprites)"
%endif

vard exsfeaturemaxspritesperblock
	dd EXTBASE_TRAINS+EXTCOUNT_TRAINS	// 0 trains
	dd EXTBASE_RVS+   EXTCOUNT_RVS		// 1 road
	dd EXTBASE_SHIPS+ EXTCOUNT_SHIPS 	// 2 ships
	dd EXTBASE_PLANES+EXTCOUNT_PLANES	// 3 planes
	dd EXTBASE_OTHER+ EXTCOUNT_OTHER	// 4 stations
	dd EXTBASE_OTHER+ EXTCOUNT_OTHER 	// 5 canals
	dd EXTBASE_OTHER+ EXTCOUNT_OTHER 	// 6 bridges (unused)
	dd EXTBASE_HOUSES+EXTCOUNT_HOUSES	// 7 newhouses
	dd 0			 		// 8 specialvars
	dd EXTBASE_OTHER+ EXTCOUNT_OTHER 	// 9 industry tiles
	dd EXTBASE_OTHER+ EXTCOUNT_OTHER 	// 10 industries
	dd EXTBASE_OTHER+ EXTCOUNT_OTHER 	// 11 cargoes
	dd 0					// 12 sounds
	dd EXTBASE_OTHER+ EXTCOUNT_OTHER 	// 13 airports
	checkfeaturesize exsfeaturemaxspritesperblock, 4
endvar

vard exsfeaturetospritebaseoffsets
	dd EXTBASE_TRAINS	// 0 trains
	dd EXTBASE_RVS		// 1 road
	dd EXTBASE_SHIPS	// 2 ships
	dd EXTBASE_PLANES	// 3 planes
	dd EXTBASE_OTHER	// 4 stations
	dd EXTBASE_OTHER	// 5 canals
	dd EXTBASE_OTHER	// 6 bridges (unused)
	dd EXTBASE_HOUSES	// 7 newhouses
	dd 0			// 8 specialvars
	dd EXTBASE_OTHER	// 9 industry tiles
	dd EXTBASE_OTHER	// 10 industries
	dd EXTBASE_OTHER	// 11 cargoes
	dd 0			// 12 sounds
	dd EXTBASE_OTHER	// 13 airports
	checkfeaturesize exsfeaturetospritebaseoffsets, 4
endvar

// to add new block, also adjust 
varb exsnumactspritesindex
	db 1	// 0 trains
	db 2	// 1 road
	db 3	// 2 ships
	db 4	// 3 planes
	db 0	// 4 stations
	db 0	// 5 canals
	db 0	// 6 bridges (unused)
	db 5	// 7 newhouses
	db -1	// 8 specialvars
	db 0	// 9 industries
	db 0	// 10 industries
	db 0	// 11 cargoes
	db -1	// 12 sounds
	db 0	// 13 airports
	checkfeaturesize exsnumactspritesindex,1
endvar

uvard numactsprites,NUMSPRITEBLOCKS	// Number of active sprites in TTD's sprite number space

uvarb exscurfeature
uvarb exsspritelistext	// toggles extendend sprite mode for add*sprite, if > 0 it will be decreased every call
uvarb exsdrawsprite	// toggles extendend drawsprites & mouse cursor...


// out:	EBX = maxspritecount 
global exsgetspritecount
exsgetspritecount:
	test dword [miscmodsflags],MISCMODS_SMALLSPRITELIMIT
	jnz .small
	// well, if you get overexited, this can result in a crash when to much memory seems to be allocated
	mov ebx, EXTBASE_END + 1
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
	movzx edi,byte [exsnumactspritesindex+esi]
	mov [numactsprites+edi*4], eax
	inc esi
	cmp dword [exsfeaturetospritebaseoffsets+esi*4], 0
	jnz .next
	popa
	ret

// So much code for the status
global exsshowstats
exsshowstats:
	setbase esi,exsfeaturetospritebaseoffsets

	// count total active sprites
	mov ebx,[numactsprites+1*4]
	sub ebx,[BASE exsfeaturetospritebaseoffsets+0*4]
	add ebx,[numactsprites+2*4]
	sub ebx,[BASE exsfeaturetospritebaseoffsets+1*4]
	add ebx,[numactsprites+3*4]
	sub ebx,[BASE exsfeaturetospritebaseoffsets+2*4]
	add ebx,[numactsprites+4*4]
	sub ebx,[BASE exsfeaturetospritebaseoffsets+3*4]
	add ebx,[numactsprites+5*4]
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
	movzx eax,byte [exsnumactspritesindex]
	mov eax, [numactsprites+eax*4]
	sub eax, [exsfeaturetospritebaseoffsets]
	stosd
	mov ax,ourtext(grfstatmax)
	stosw
	mov eax, [exsfeaturemaxspritesperblock]
	sub eax, [exsfeaturetospritebaseoffsets]
	stosd

	// road
	movzx eax,byte [exsnumactspritesindex+1]
	mov eax, [numactsprites+eax*4]
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
	movzx eax,byte [exsnumactspritesindex+2]
	mov eax, [numactsprites+eax*4]
	sub eax, [exsfeaturetospritebaseoffsets+8]
	stosd
	mov ax,ourtext(grfstatmax)
	stosw
	mov eax, [exsfeaturemaxspritesperblock+8]
	sub eax, [exsfeaturetospritebaseoffsets+8]
	stosd

	//plane
	movzx eax,byte [exsnumactspritesindex+3]
	mov eax, [numactsprites+eax*4]
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
	movzx eax,byte [exsnumactspritesindex+7]
	mov eax, [numactsprites+eax*4]
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
global exsrealtofeaturesprite
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
global exsfeaturespritetoreal
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
global exsfeaturespritetorealeax
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
