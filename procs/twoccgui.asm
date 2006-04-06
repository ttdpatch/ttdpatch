/************************ Fragments for the Two Company Colours Window ***************************/
// Includes
#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>
#include <player.inc>
#include <textdef.inc>

// Procedures
patchproc enhancegui, patchtwoccgui

// Fragments
begincodefragments

codefragment oldcreatecolourwindow
	push dx
	mov cx, 31

codefragment newcreatecolourwindow
	icall win_twoccgui_create
	ret // End the sub after creating the window

codefragment oldcompanywindowsprite
	movzx bx, byte [ebx+player.colourscheme]
	add bx, 775
	shl ebx, 0x10
	mov bx, 3097+32768

codefragment newcompanywindowsprite
	icall recolourcompanywindowsprite
	setfragmentsize 17

endcodefragments

// Code to active fragments for twoccgui
patchtwoccgui:
	patchcode oldcreatecolourwindow, newcreatecolourwindow
	patchcode oldcompanywindowsprite, newcompanywindowsprite
	ret
