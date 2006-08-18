// This houses the code for 'Clone Train' feature
// This is still very basic and early code
// 
// Created By Lakie
// Auguest 2006

#include <flags.inc>
#include <misc.inc>
#include <newvehdata.inc>
#include <player.inc>
#include <ptrvar.inc>
#include <std.inc>
#include <textdef.inc>
#include <veh.inc>
#include <vehtype.inc>
#include <window.inc>

extern setmousetool, patchflags, findvehontile, errorpopup, actionhandler
extern RefreshWindowArea, forceextrahead, isengine, trainplanerefitcost
extern traindepotwindowhandler.resizewindow, CloneTrainBuild_actionnum
extern currentexpensetype, FindWindow, newvehdata, forcenoextrahead

/*

	-= Basic Idea =-
* Click on a depot button "Clone Train"
* Set the Mouse Tool to the Clone Train tool
* Click on a train (in a depot or on the map)
* Get the train vehicle array pointer (And window pointer if from another depot)
* Run the action Handler with bl=1, (bl=0, then bl=1)
  > Check Loop
    * Check the consist to be cloned is owned by the player
    * Check that each vehicle type is available
    * Check that the vehicle can be built
    * If a vehicle can be built store it's cost
    * Check if the vehicle needs to be charged for a refit (change in cargotype)
    * If all ok, calculate the final amount of money required for the cloning of the consist
  > Creation Loop
    * Create the rail vehicle (only 1 vehicle at a time (articutated vehicles count as one vehicle)
    * Refit the vehicle (and it's artic parts if it has anyway)
    * Attach the constructed vehicle to the last constructed vehicle (Not for the first engine of course)
    * Once done set the type of expenses to put this clone under (New Vehicles)
* If successful, open the train window for the new created consist
* Reset the Mouse Tool, so that no consists get cloned by acciedent

	-= To Do =-
* Copy orders from the cloned train (use sharedorders instead if available)
* Add a some code for a customizable cursor

	-= Comments =-
* Might be a pain to do and take a while

*/

// Stores the location of the new depotwindow elementlist
uvard newDepotWinElemList

// Stores the location of the old depot tooltips
uvard CloneDepotToolTips

/*

	-= Fixes for the orginal Depot Window Handler =-

*/

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
	bt dword [esi+window.disabledbuttons], 7 // Disabled so non-usable
	jc .disabled

	bt dword [esi+window.activebuttons], 7 // Active so skip the next part
	jc .alreadyactive

	jmp CloneDepotActiveMouseTool

.disabled:
	ret

.alreadyactive:
	push ecx
	push esi
	mov ebx, 0
	mov al, 0
	call [setmousetool]
	pop esi
	pop ecx
	ret

// Handles the disabling of the "Clone Train" Button in the Train Depot Window
global CloneDepotDisableElements
CloneDepotDisableElements:
	je .isplayer
	or dword [esi+window.disabledbuttons], 0xA8
.isplayer:
	ret

// Handles the intercepting of the window handler events
global CloneDepotWindowHandler
CloneDepotWindowHandler:
	mov bx, cx
	mov esi, edi

testmultiflags clonetrain
	jz .noclonetrain
	cmp dl, cWinEventMouseToolClick
	je near CloneTrainMain
	cmp dl, cWinEventMouseToolClose
	je near CloneDepotDeActiveMouseTool
.noclonetrain:

testmultiflags enhancegui
	jz .noresizer
	cmp dl, cWinEventResize
	je traindepotwindowhandler.resizewindow
.noresizer:

	cmp dl, cWinEventRedraw // For the orginal subroutine
	ret

// Handles a special event when a train was clicked in the depot window
global CloneDepotVehicleClick
CloneDepotVehicleClick:
	test al, al
	jl .notactive // These function fine anyway

	cmp byte [curmousetoolwintype], 0x12 // Is this depot clone train active?
	jne .notactive

	cmp edi, 0
	je .notactive

	movzx edi, word [edi+veh.engineidx] // Make it a usable number
	shl edi, 7
	add edi, [veharrayptr]

	push edi
	movzx edx, word [curmousetoolwinid]
	mov cl, 0x12
	pop edi
	call [FindWindow]

	add dword [esp], 0x65 // Jumps to a ret after doing the clone subroutine
	jmp CloneTrainMain.foundvehicle

.notactive:
	cmp al, 1
	jne .nexttype
	add dword [esp], 0x65 // Jumps to a ret
	ret

.nexttype:
	cmp al, -1
	ret

/*

	Misc fixes to the buyRailVehicle subroutine

*/

// Fixes the buyhead check so that it can be bypassed
global CloneTrainBuySecondHead
CloneTrainBuySecondHead:
	cmp byte [forcenoextrahead], 1
	jae .bypass

	test byte [numheads+ebx], 1
	ret

.bypass:
	sar dword [edi+veh.value], 1
	cmp bl, bl
	ret

/*

	-= Mouse Tool Handlers =-

*/

// Holds a sprite table for the mouse cursor
var CloneDepotMouseSpriteTable
	dw 0x2CC, 0x1D, 0x2CD, 0x1D, 0x2CE, 0x62, 0xFFFF

// Handles the activation of the Mouse Tool
CloneDepotActiveMouseTool:
	push esi
	bts dword [esi+window.activebuttons], 7 // Active the bit (Button)

	mov dx, [esi+window.id] // Settings for the Mouse Tool
	mov ah, 0x12
	mov al, 1

	mov ebx, -1 // Makes the Cursor animated
	mov esi, CloneDepotMouseSpriteTable

	call [setmousetool]
	pop esi

	call dword [RefreshWindowArea]

	ret

// Handles the deactivation of the Mouse Tool
global CloneDepotDeActiveMouseTool
CloneDepotDeActiveMouseTool:
	btr dword [esi+window.activebuttons], 7
	call dword [RefreshWindowArea]
	ret

/*

	The Code that makes Clone Train work!

*/

// Holds the location to call for the Open Train Window subroutine
uvard CloneTrainOpenTrainWindow

// Handles the code for Clone Trains, all the calls etc
CloneTrainMain:
	movzx edi, word [mousetoolclicklocxy] // Get the tile to check
	call findvehontile // Is there a vehicle on this tile?
	jnz .foundvehicle
	ret

.foundvehicle:
	push edi
	movzx edi, word [esi+window.id] // Get the x, y for the action to take place
	mov bh, [esi+window.company]

	rol di, 4 // Store the x, y in the ax, cx registors
	mov ax, di
	mov cx, di
	rol cx, 8
	and ax, 0x0FF0
	and cx, 0x0FF0
	pop edi

	push esi
	mov bl, 1
	mov word [operrormsg1], ourtext(txtcloneerrortop) // Header for error messages
	dopatchaction CloneTrainBuild // Clone the consist
	cmp ebx, 1<<31 // Skip opening of the vehicle window (would crash otherwise)
	je .failed

	push edi // Get the created consist id and open the train window for it
	movzx edi, word [CloneTrainLastIdx]
	shl edi, 7
	add edi, [veharrayptr]
	call dword [CloneTrainOpenTrainWindow]
	pop edi

.failed:
	pop esi // What ever the out come, reset the mouse tool
	push ecx
	push esi
	mov ebx, 0
	mov al,  0
	call [setmousetool]
	pop esi
	pop ecx
	ret

/*

	The Actual PatchAction CloneTrain!

*/

// A few Variables to keep cloning working correctly
uvard CloneTrainCost // Stores the total cost of cloning
uvarw CloneTrainLastIdx // Stores the last created unit id

// Handles the actual operation of cloning the consist
// Input:	esi = Depot Window Pointer
//		edi = Vehicle Engine Pointer
// Output:	ebx = 0x80000000 if failed otherwise cost
//		esi = New consist Vehicle Engine Pointer
//		edi = Old consist Vehicle Engine Pointer
exported CloneTrainBuild
	push edi // Store the orginal vehicle consist's vehicle pointer
	xchg esi, edi

	test bl, 1
	jz near CloneTrainCalcOnly

	mov word [CloneTrainLastIdx], 0xFFFF // Blank this otherwise the attach loop will fail
	jmp .loop

// Atric's are special so you need to move to the next artic piece in the train being created
.artic:
	movzx edi, word [edi+veh.nextunitidx]
	shl edi, 7
	add edi, [veharrayptr]
	jmp .refit

.loop:
	cmp byte [esi+veh.artictype], 0xFD // Is this an artic vehicle?
	jae .artic

	cmp word [CloneTrainLastIdx], 0xFFFF // Is it the first vehicle
	je .firstvehicle
	mov byte [forceextrahead], 1 // Makes the engine a additional head

.firstvehicle:
	mov byte [forcenoextrahead], 1 // Only really applies to the first vehicle

	push esi // Create the new train / train consist (if artic)
	mov dx, -1
	movzx ebx, word [esi+veh.vehtype]
	shl bx, 8
	mov bl, 1
	mov esi, 0x80
	push ebp
	call [actionhandler]
	mov byte [forcenoextrahead], 0 // Reset these for next time
	mov byte [forceextrahead], 0
	pop ebp
	pop esi

	cmp byte [edi+veh.subclass], 4	// Make a multihead unit attachable
	jne .goodvehicle
	mov byte [edi+veh.subclass], 2
.goodvehicle:

	cmp word [CloneTrainLastIdx], 0xFFFF // No last vehicle so cannot attach (ie. if train engine)
	je .refit

	push eax // Attach this vehicle to the last build vehicle
	push ecx
	push esi
	push edi
	movzx edi, word [edi+veh.idx]
	mov dx, [CloneTrainLastIdx]
	mov bl, 1
	mov esi, 0x90080
	push ebp
	call [actionhandler]
	pop ebp
	pop edi
	pop esi
	pop ecx
	pop eax

.refit:
	mov dl, [esi+veh.cargotype] // Copy all the refit settings to make the vehicle the same refits
	mov byte [edi+veh.cargotype], dl
	mov dx, [esi+veh.capacity] // Copy the vehicle capacity as a word
	mov word [edi+veh.capacity], dx
	mov dl, [esi+veh.refitcycle] // This is important for refit graphics etc
	mov byte [edi+veh.refitcycle], dl

	push edi // Store the id for the next loop cycle (for the attach part mainly)
	movzx edi, word [edi+veh.idx]
	mov word [CloneTrainLastIdx], di
	pop edi

	movzx esi, word [esi+veh.nextunitidx] // Move to the next vehicle in the consist to be copied
	cmp si, byte -1
	je .done
	shl esi, 7
	add esi, [veharrayptr]
	jmp .loop

.done:
	movzx edi, word [edi+veh.engineidx] // Get and store the engine head's id for the next subroutine
	mov [CloneTrainLastIdx], di
	mov byte [currentexpensetype], expenses_newvehs
	pop edi
	ret

// Calculate the cost of the cloning
CloneTrainCalcOnly:
	mov dword [CloneTrainCost], 0 // Set this to 0 for now
	mov dword [trainplanerefitcost], 0

	mov word [operrormsg2], ourtext(txtcloneerror1) // Bad vehicle owner
	cmp bh, [esi+veh.owner]
	jne near .fail

	mov word [operrormsg2], ourtext(txtcloneerror3) // No Engine head
	cmp byte [esi+veh.subclass], 0
	jne near .fail

	mov word [operrormsg2], ourtext(txtcloneerror4) // Unknown issue with copying

.loop:
	cmp byte [esi+veh.artictype], 0xFD // Artic vehicles are already bought with there head
	jae near .artic

	push ebx
	movzx bx, bh
	mov word [operrormsg2], ourtext(txtcloneerror2) // Vehicle not avilable anymore
	movzx edx, word [esi+veh.vehtype]
	imul edx, vehtype_size
	add edx, vehtypearray
	bt word [edx+vehtype.playeravail], bx
	jnc near .failebx
	pop ebx

	mov word [operrormsg2], ourtext(txtcloneerror4) // Unknown issue with copying

	cmp word [CloneTrainLastIdx], 0xFFFF // Is it the first vehicle
	je .firstvehicle
	mov byte [forceextrahead], 1 // Makes the engine a additional head

.firstvehicle:
	mov byte [forcenoextrahead], 1 // Only really applies to the first vehicle

	push ebx
	mov dx, -1 // Contruct the vehicle (not for real though)
	movzx ebx, word [esi+veh.vehtype]
	shl bx, 8
	mov bl, 0
	push esi
	mov esi, 0x80
	push ebp
	call [actionhandler]
	mov byte [forcenoextrahead], 0 // Reset these for next time
	mov byte [forceextrahead], 0
	pop ebp
	pop esi

	cmp ebx, 1<<31 // Fail or add costs
	je near .failebx
	add dword [CloneTrainCost], ebx
	pop ebx

.artic:
	push ebx // Attemps to work out refit cost
	push edx
	push eax
	xor ax, ax
	movzx ebx, word [esi+veh.vehtype]

	mov dl, [traincargotype+ebx] // Check if the cargo type is the same
	cmp byte [esi+veh.cargotype], dl
	je .nocapacity // If not there is a charge for the refitting which is constant

	movzx edx, byte [trainrefitcost+ebx] // Calculate the cost of this refit
	bt [isengine], ebx
	jc .engine
	imul edx, [wagonpurchasecostbase]
	jmp short .gotcost
.engine:
	imul edx, [trainpurchasecostbase]
.gotcost:
	sar edx, 2 // Fix it alittle and then store it for the end
	add dword [trainplanerefitcost], edx

.nocapacity:
	pop eax // Restore the values
	pop edx
	pop ebx

.next:
	movzx esi, word [esi+veh.nextunitidx] // Get the next id of the consist to clone
	cmp si, byte -1
	je .done
	shl esi, 7 // Move to the pointer in veh array
	add esi, [veharrayptr]
	jmp .loop

.failebx:
	pop ebx
	mov ebx, 1<<31
	pop edi
	ret

.fail:
	mov ebx, 1<<31
	pop edi
	ret

.done:
	mov ebx, [trainplanerefitcost] // Refit cost
	sar ebx, 7 // Correct the end value for refits
	add ebx, [CloneTrainCost]
	pop edi
	ret

