/************************ Fragments for the Two Company Colours Window ***************************/
// Includes
#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>
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

endcodefragments

// Code to active fragments for twoccgui
patchtwoccgui:
	patchcode oldcreatecolourwindow, newcreatecolourwindow
	ret
