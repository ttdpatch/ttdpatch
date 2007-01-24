//
// Add a "load game" option to the disk menu
//

#include <std.inc>
#include <flags.inc>
#include <textdef.inc>
#include <human.inc>
#include <window.inc>

extern ctrlkeystate,patchflags


// handle the four entries in the disk menu
// in:	dx=menu entry
//	old meanings:
//	0,1: save; 2: quit game; 3: empty; 4: quit to do
//	new meanings:
// 	0,1: save; 2: load game; 3: quit game; 4: quit to dos
//
//	i.e. need to map 0,1,2,3,4 to 0,1,carry,2,4
// out:	carry if we open the load menu
global diskmenuselection
diskmenuselection:
	setz bl			// zero-flag means this is the scenario editor
	jz short .keepdx
	or dl,dl
	jz short .keepdx
	inc dl

.keepdx:
	mov byte [newgameyesno], 0
	cmp dl, 2
	jb .done
	je .loadmenu

	cmp dl, 4
	jb .done

	or bl, bl
	jnz .editor

	cmp dl, 4
	je .newgame
.editor:
	dec dl
	cmp dl, 4
	je .abandon
	dec dl

.done:
	clc
	ret

.newgame:
	mov esi, 0x10038 // Abandon game
	mov byte [newgameyesno], 1
	jmp .doload

.loadmenu:
	mov esi,0x40038	// "load game" dialog
	or bl,bl	// are we in the editor?
	jz short .doload
	push byte CTRL_DEFAULT
	call ctrlkeystate
	jnz short .doload

	mov esi,0x30038	// "save game" dialog

.doload:
	xor ax,ax
	mov cx,ax
	mov bl,1
	mov dl,0
	stc
	ret

.abandon:
	mov dl, 2
	jmp .done

; endp diskmenuselection 

// Changes the text string to use based off addition variables
uvarb newgameyesno
global changeabandontext
changeabandontext:
	cmp byte [gamemode], 2
	je .editor
	mov bx, 0x160
	cmp byte [newgameyesno], 1
	jne .done
	mov bx, ourtext(newgamewindow)

.done:
	ret

.editor:
	mov bx, 0x29B
	ret

// Changes the action to be done
global changeabandonaction
changeabandonaction:
	cmp byte [newgameyesno], 1
	je .newgame

	mov dl, 2
	mov esi, 0x10038
	ret

.newgame:
	mov dl, byte [climate]
	mov byte [newgameclimate], dl
	mov esi, 0x00060
	ret

// called to determine the next disk menu entry, stored in bx
// bx=15c..15f: save/quit game/empty/quit to dos
//
// old numbers:
// 15c/15d/15e/15f
//
// want to change this to:
// 15c/141/15d/15f		(141 is "Load Game")
//
// i.e., change:  15c->15c; 15d->141; 15e->15d; 15f->15f
//
// In scenario editor:
//
// old: 292/293/294/295/296
// new: 292/293/xxx/294/296	(xxx=load game or savegame, depending on Ctrl)
diskmenustrings:
	test byte [gamemode], 2
	jnz .editor

	cmp bx, 0x15d
	jb .done
	je .load

	cmp bx, 0x15f
	jb .done
	je .newgame

	cmp bx, 0x161
	ja .done
	je .notabandon
	dec bx
.notabandon:
	sub bx, 2

.done:
	ret

.newgame:
	mov bx, ourtext(newgame)
	ret

.editor:
	cmp bx, 0x298
	ja .done

	cmp bx, 0x294
	jb .done
	je .loadorsave

	cmp bx, 0x295
	je .done
	dec bx

	cmp bx, 0x296
	je .done
	dec bx
	ret

.loadorsave:
	push byte CTRL_ANY
	call ctrlkeystate
	jnz .load
	mov bx,0x15c
	ret

.load:
	mov bx,ourtext(loadgame)
	ret
; endp diskmenustrings


global toolbardropdown
toolbardropdown:
	mov eax,[toolbarelemlisty2]
	mov ecx,[numnewoptionentries]
	add ecx,9
	imul ebx,ecx,10
	inc ebx
	mov [eax],bx
	inc ebx
	shl ebx,16
	ret

global tooldiskbardropdown
tooldiskbardropdown:
	mov eax, [toolbarelemlisty2]
	mov ecx, 2 // 2 new items to add
	add ecx, 4 // 5 orginal items
	imul ebx,ecx,10
	inc ebx
	mov [eax],bx
	inc ebx
	shl ebx,16
	ret

// Will be called if a dropdown menu will be drawn

global dropdownmenustrings
dropdownmenustrings:
	testflags diskmenu
	jnc short .nodiskmenu
	call diskmenustrings
.nodiskmenu:
	cmp dword [numnewoptionentries],0
	je .done

	push ebx
	mov ebx,[esp+12+4+4]
	mov bx,[ebx+0x30]
	cmp bx,0x2C3	// tool menu drop down?
	je .doToolMenu
	cmp bx, 180Ah
	je .doRoadMenu
	pop ebx
	jmp	.done

.doRoadMenu:
	pop ebx
	cmp bx, 180Bh
	jne .done
	mov bx, ourtext(txteroadmenu)
	jmp .done

.doToolMenu:
	pop ebx
	cmp bx,0x02C7
	jb .done

	sub bx,0x02C7
	shr bx,1
	cmp bx,[numnewoptionentries]
	jb .newopt

	sub bx,[numnewoptionentries]
	shl bx,1
	add bx,0x2c7

.done:
	test si,1
	jz .noinc
	inc ebx
.noinc:
	ret

.newopt:
	rol si,1
	mov [esp+4],si
	push eax
	movzx eax,bx
	mov bx,[newoptionentrytxts+eax*2]
	pop eax
	ret
;endp dropdownmenustrings

global selecttool
selecttool:
	movzx edx,dx
	sub edx,1	// can't do dec, because it doesn't set carry
	jbe .done

	dec edx
	sub edx,[numnewoptionentries]
	jae .regular

	add edx,[numnewoptionentries]
	call [newoptionentryfns+edx*4]
	mov dh,1	// so none of the following cmps will match

.regular:
	inc edx
	inc edx
	clc

.done:
	ret


	// new entries in the option menu
uvarw newoptionentrytxts,3
uvard newoptionentryfns,3
uvard numnewoptionentries
uvard toolbarelemlisty2
