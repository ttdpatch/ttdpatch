//
// Add a "load game" option to the disk menu
//

#include <std.inc>
#include <flags.inc>
#include <textdef.inc>
#include <human.inc>

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
	cmp dl,2
	jb short .done		// 0, 1 -> don't touch
	je short .loadmenu	// 2 -> load
	cmp dl,3
	jne short .done	// 4 -> don't touch

	// was 3
	mov dl,2

.done:
	clc
	ret


// set carry flag for "load game"
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
; endp diskmenuselection 

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
	//test si,1
	//jz short .noinc
	//inc ebx

//.noinc:
	cmp bx,0x15d
	jb short .done		// 15c or below; don't touch
	je short .load		// 15d

	cmp bx,0x295
	ja short .done		// 296 or above; don't touch
	je short .notempty	// 295

	cmp bx,0x294
	je short .loadorsave

	cmp bx,0x15e
	ja short .done		// 15e or above; don't touch

		// 15e->15d or 295h->294h
.notempty:
	dec bl
.done:
	ret

.load:
	mov bx,ourtext(loadgame)
	ret

.loadorsave:
	push byte CTRL_ANY
	call ctrlkeystate
	jnz .load
	mov bx,0x15c
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
	pop ebx
	jne .done

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
