//followvehicle
//by steven hoefel... allows teh user to right-click on the eye button and have the main view
//follow the vehicle around the map

#include <std.inc>
#include <window.inc>
#include <veh.inc>

extern CreateTooltip,GetMainViewWindow,WindowClicked,setmainviewxy


uvard tooltiptextlocTrain
uvard tooltiptextlocRV
uvard tooltiptextlocPlane
uvard tooltiptextlocShip
uvard followvehicleidx,1,s


global followvehiclefunc
followvehiclefunc:						//run on right-click of ANY vehicle window eye-click
	call 	[WindowClicked]
	
	movzx 	edi,word [esi+window.id]	// get the current vehicle from the window data
	shl 	edi,vehicleshift
	add 	edi,[veharrayptr]
	
	cmp     cl, 5						//the user hit the CenterMainView button
	jnz	.tooltipclick
	
	mov 	ax, [edi+veh.idx]
	mov	[followvehicleidx], edi
	call 	[GetMainViewWindow]			//grab the main window data
	
	cmp 	[edi+window.data],ax			//is this train already set?
	jz	.stopfollowing
	
	mov 	[edi+window.data],ax			//set main window to follow train	
	jmp 	short .drawToolTip

.stopfollowing:
	mov	[edi+window.data],word -1		//set main window to follow none
	mov	edi, [followvehicleidx]
	mov	ax, [edi+veh.xpos]
	mov	cx, [edi+veh.ypos]
	mov	[followvehicleidx],dword -1		//leave the location as the last point we were watching
	jmp	[setmainviewxy]


.tooltipclick:
	mov     byte [rmbstate], 0				//we only want this to run when the mouse is down
	call 	[WindowClicked]
	js	.endfollowvehicle			//if the mouse aint down, then skip!

.drawToolTip:
	movzx 	edi,word [esi+window.id]
	shl 	edi,vehicleshift
	add 	edi,[veharrayptr]
	movzx	edi,byte [edi+veh.class]
	mov	edi,[tooltiptextlocTrain+(edi-0x10)*4]
	movzx 	ebx,cx							//cx is the button clicked returned from WindowClicked
	mov 	ax, [edi+ebx*2]					//add the offset to the correct text string
	jmp	[CreateTooltip]					//show it

.endfollowvehicle:
	retn
	
global cancelfollowvehicle
cancelfollowvehicle:
	mov 	[esi+window.data],word -1		//firstly tell the main window to stop following
	
	mov	edi, [followvehicleidx]			//check if we had saved a vehicle id that we were following
	cmp	edi, -1
	jz	.skipmovinglocation		//we havent.
	
	mov	ax, [edi+veh.xpos]				//grab the position of htis vehicle.
	mov	cx, [edi+veh.ypos]	
	mov	[followvehicleidx],dword -1		//cancel the saved vehicle id
	jmp	[setmainviewxy]					//set the xy of the main view to the current vehicle location
											//otherwise the viewpoint will shift back to where we started watching.
											//do we want this as an option?
	
.skipmovinglocation:
	shl ax,cl								//continue the code we hacked.
	shl bx,cl								//what does shl do? :)
	add [esi+window.data+2], ax				//main window x view pos
	add [esi+window.data+4], bx				//main window y view pos
	clc
	retn
	
global cancelfollowonsetxy
cancelfollowonsetxy:
	xor		dh,dh							//hack into the setmainviewxy proc to reset the vehicle idx
	mov		bx,cx
	mov		cx,dx
	mov		[followvehicleidx],dword -1		//reset it so we don't try and jump back to the old position
	retn
	
