//
// Add a "load game" option to the disk menu
//

#include <std.inc>
#include <flags.inc>
#include <textdef.inc>
#include <human.inc>
#include <misc.inc>
#include <ptrvar.inc>
#include <window.inc>

extern ctrlkeystate, patchflags, DestroyWindow, FindWindow

uvard FlashWindow
uvard SearchAndDestoryWindow

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
//	int3
	pusha
	mov edi, 0
	mov ebx, 1 + (0 << 16)
extern SetTTDpatchVar_actionnum, actionhandler
	dopatchaction SetTTDpatchVar
	popa
	cmp dl, 2
	jb .done
	je .loadmenu

	cmp dl, 4
	jb .done

	or bl, bl
	jnz .editor

	cmp dl, 4
	je .newgame
	dec dl

.editor:
	cmp dl, 4
	je .abandon
	dec dl

.done:
	clc
	ret

.newgame:
	pusha
	mov edi, 1
	mov ebx, 1 + (0 << 16)
	dopatchaction SetTTDpatchVar
	popa                                                                                                                                                                                                             
	mov esi, 0x10038 // New game
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
	mov dl, byte [climate] // Store this in here as it will serive to the climate change
extern MenuStartNewGame_actionnum
	mov esi, MenuStartNewGame_actionnum // Call our special action handler function which will sort out most things
	ret

uvard CreateMainWindow // Holds a function address to reset the gui (setup through proc file)
exported MenuStartNewGame // Basically does the equivlent of exit game and start new random game!
	push edx			// Make sure the climate to generate servives
	call [CreateMainWindow]		// Reset the gui system
	pop edx

	mov esi, 0x40060 // Set climate type
	mov bl, 1
	call [actionhandler]

	mov ebp, [ophandler + (12 * 8)]	// Op Class 12
	mov ebx, 1			// reset and generate new game data
	call dword [ebp + 4]		// Op.function

	mov bl, 1
	mov esi, 0x00060 // Actually create the new game
	call [actionhandler]

	ud2 // We shouldn't end up here as it changes the stack back to the ttd start point
	ret	

// Closes any windows of commonly reconised yes / no type when opened
global closeyesnowindows
closeyesnowindows:
	cmp cl, 22
	jne .yesno

	mov cl, 23
	xor dx, dx
	call [SearchAndDestoryWindow]

	mov cl, 22
	xor dx, dx
	call [FlashWindow]
	ret

.yesno:
	mov cl, 22
	xor dx, dx
	call [SearchAndDestoryWindow]

	mov cl, 23
	xor dx, dx
	call [FindWindow]
	jz .noyesno

	mov ah, byte [newgameyesno]
	cmp ah, byte [esi+window.data]
	je .flash
	call [DestroyWindow]

.flash:
	mov cl, 23
	xor dx, dx
	call [FlashWindow]

.noyesno:
	ret

// Changes the element title on opening
global changeelementlist, abandonelemlist
changeelementlist:
	mov eax, dword 0
ovar abandonelemlist

	mov [esi+window.elemlistptr], eax
	lea eax, [eax+(12+10)]

	cmp byte [newgameyesno], 1
	je .newgame

	mov word [eax], 0x161
	mov byte [esi+window.data], 0
	ret

.newgame:
	mov word [eax], statictext(newgametitle)
	mov byte [esi+window.data], 1
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
