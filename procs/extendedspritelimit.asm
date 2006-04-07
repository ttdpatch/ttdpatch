#include <defs.inc>
#include <frag_mac.inc>


extern addgroundsprite,addgroundspritetodisplayspritenumber,addlinkedsprite
extern addlinkedspritetodisplayafterspritenumber,addrelsprite
extern addrelspritetodisplayspritenumber,addsprite
extern addspritetodisplayafterspritenumber,collectvehiclesprites
extern displayregularspriteslinkedspritedescgetsprite
extern displayregularspritesrelspritedescgetsprite
extern displayregularspritesstdspritedescgetsprite,drawgroundspritesgetsprite
extern drawspriteandeax,drawspriteandebx
extern drawspritefn


global patchextendedspritelimit

begincodefragments

codefragment olddrawgroundspritesgetsprite, 9
	mov dx, cx
	mov cx, ax
	mov ebx, [ebp]
	db 0xE8

codefragment_call newdrawgroundspritesgetsprite,drawgroundspritesgetsprite,5

codefragment olddisplayregularspritegetsprite, 11
	mov dx, cx
	mov cx, ax
	mov ebx, [ebp]
	push edi

codefragment_call newdisplayregularspritegetsprite,displayregularspritesstdspritedescgetsprite,5

codefragment olddisplayregularspriterelativegetsprite, 6
	add dx, [ebp+6]
	mov ebx, [esi]

codefragment_call newdisplayregularspriterelativegetsprite,displayregularspritesrelspritedescgetsprite,5

codefragment olddisplayregularspritelinkedgetsprite, 8
	mov dx, cx
	mov cx, ax
	mov ebx, [esi]

codefragment_call newdisplayregularspritelinkedgetsprite,displayregularspriteslinkedspritedescgetsprite,5

codefragment oldcollectvehiclesprites
	movsx si, [esi+veh.ysize]

codefragment_call newcollectvehiclesprites,collectvehiclesprites,5

codefragment oldupdatevehiclespritebox
	and ebp, 0x3FFF

codefragment newupdatevehiclespritebox
	icall updatevehiclespritebox


codefragment oldsetmousecursor, 6
	mov [curmousecursor], ebx
	and ebx, 0x3FFF

codefragment newsetmousecursor
	icall setmousecursorsprite

codefragment olddrawmousecursor
	mov ebx, [curmousecursor]

codefragment newdrawmousecursor
	icall drawmousecursor


endcodefragments

patchextendedspritelimit:
	patchcode drawgroundspritesgetsprite
	patchcode displayregularspritegetsprite
	patchcode displayregularspriterelativegetsprite
	patchcode displayregularspritelinkedgetsprite

	// feature specific patches
	patchcode collectvehiclesprites

	patchcode updatevehiclespritebox
	patchcode setmousecursor
	patchcode drawmousecursor

	// Patch DrawSprite
	mov edi, [drawspritefn]
#if WINTTDX
	call .gettarget
#endif
	add edi, 101
	storefunctioncall drawspriteandeax
	add edi, 180
	storefunctioncall drawspriteandeax
	add edi, 96
	storefunctioncall drawspriteandebx
	mov byte [edi+5], 0x90	// one byte to small the call...

	//Now patch the add*sprite functions, we already know where the function is :)
	mov edi, [addsprite]
	add edi, 67
	mov byte [edi-1], 0x90
	storefunctioncall addspritetodisplayafterspritenumber
	add edi, 166
	add byte [edi], 2

	mov edi, [addlinkedsprite]
	add edi, 22
	mov byte [edi-1], 0x90
	storefunctioncall addlinkedspritetodisplayafterspritenumber
	add edi, 170
	add byte [edi], 2

	mov edi, [addrelsprite]
	add edi, 16
	mov word [edi-2], 0x9090
	add byte [edi+32], 2
	storefunctioncall addrelspritetodisplayspritenumber
	
	mov edi, [addgroundsprite]
	add byte [edi+27], 2
	mov word [edi+31], 0x9090
	storefunctioncall addgroundspritetodisplayspritenumber, 33
	ret

.gettarget:
	cmp byte [edi], 0xE9
	jnz .fullerror
	push eax
	mov eax,[edi+1]
	lea edi,[edi+eax+5]
	pop eax
	ret
.fullerror:
	UD2	// we can't find the target, let's crash :/
	ret
