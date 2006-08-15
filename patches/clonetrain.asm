// This houses the code for 'Clone Train' feature
// This is still very basic and early code
// 
// Created By Lakie
// Auguest 2006

#include <std.inc>
#include <textdef.inc>

/*

	-= Basic Idea =-
* Add a button to the train depot gui
* Button makes the mouse cursor change
* Click on a tile
* Check for vehicle
* Get vehicle engine id
* Check that aviable funds are enough to pay for the train consist (bl=0)
* If failed (edx=80000000), quite with error message
* If passed create the wagons for the vechile
* Then Create the engine finish the consist
* Attach the wagons in the order they were made
* End (whilest giving the player the train window) and charging the player

	-= Possible Problems =-
* Artutated Vehicles since they can be multiple parts
* Trying to store the new vehicle ids so that they may be attached in the same order
* Refitting Vehicles to have the same cargo types

	-= Possiblities =-
* Maybe adding the ablity to add it to shared orders (if clicked with ctrl key)?
* Maybe copy the same misc bits so that the graphics and cargo etc. are exactly the same

	-= Comments =-
* Might be a pain to do and take a while

*/

// Stores the location of the new depotwindow elementlist
uvard newDepotWinElemList

// Stores the location of the old depot tooltips
uvard CloneDepotToolTips

// Handles the right click code for the depot window (to prevent crash)
global CloneDepotRightClick
CloneDepotRightClick:
	cmp cl, 7
	je .isclonetrain
	push edi
	mov edi, [CloneDepotToolTips]
	mov ax, [edi+ebx*2]
	pop edi
	ret

.isclonetrain:
	mov ax, ourtext(txtclonetooltip)
	ret

// Handles the normal click for the depot window
global CloneDepotClick
CloneDepotClick:
	cmp cl, 7
	je .isclonetrain
	cmp cl, 2
	jne .bad
	add dword [esp], 0x1B4+3
.bad:
	ret

.isclonetrain:
	ret

