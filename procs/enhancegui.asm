#include <defs.inc>
#include <frag_mac.inc>
#include <window.inc>
#include <patchproc.inc>

patchproc enhancegui, patchenhancegui

extern RailConstrToolClickProcs,RailEWPieceToolClick,RailNSPieceToolClick
extern RailToolMouseDragDirectionPtr,RoadToolMouseDragDirectionPtr
extern enhancegui_settingschanged
extern enhanceguioptions_defaultdata,enhanceguioptions_savedata
extern malloccrit,loadenhanceguisettingsfromfile
extern windowDepotDropHandle1
extern windowDepotDropHandle2,windowDepotDropHandle3
extern windowRailDepotDropHandle

begincodefragments

codefragment findwindowraildepotdrophandle
	cmp cl, 3	// 80 F9 03 74 4E 80 F9 02 75 3E
	jz $+2+0x4E
	cmp cl, 2
 	jnz $+2+0x3E

codefragment oldwindowstreetdepotdrophandle
	cmp cl, 3	// 80 F9 03 74 3D 80 F9 02 75 1D
	jz $+2+0x3D
	cmp cl, 2
	jnz $+2+0x1D

codefragment oldaddstationsigntotexteffect
	mov [ebx+16h], ax
	mov [ebx+18h], dx
 	//db 0x66,0x89,0x43,0x16,0x66,0x89,0x53,0x18

codefragment newaddstationsigntotexteffect
	call runindex(addstationsigntoeffects)
	nop 
	nop

codefragment oldtextcolorrange
	cmp al, 99h
	db 0x73, 0x08 // jnb short +08
	cmp al, 88h
	
codefragment newtextcolorrange
	//cmp al, 0xAB
	call runindex(specialcolortextbytes)
	db 0x0F, 0x82 // was 0x0F 0x83 (jnb) now (jb/jc) 
//enhancegui: end

// Slowdown before roadcrossings
codefragment oldmapwindowclicked
	db 0x0F, 0x88, 0xCC, 0x03, 0x00, 0x00 // js ...

codefragment newmapwindowclicked
	icall mapwindowclicked

codefragment oldDemolishTile, 3
	pop ax
	ret
	mov bl, 1
	db 0x66, 0xc7, 0x05	// mov [operrormsg1], ...

codefragment newDemolishTile
	ijmp DemolishTile

codefragment oldRailConstrWinHandler, 3
	cmp dl, cWinEventMouseDragUITick
	jz near $-431+6

codefragment newRailConstrWinHandler
	icall RailConstrDragUITick

codefragment oldRoadConstrWinHandler, 3
	cmp dl, cWinEventMouseDragUITick
	jz near $-466+6

codefragment newRoadConstrWinHandler
	icall RoadConstrDragUITick

codefragment oldDockConstrWinHandlerEnd,3
	cmp dl, cWinEventMouseToolUITick
	jz near $-210+6

codefragment newDockConstrWinHandlerEnd
	icall DockConstrDragUITick

codefragment oldAirportConstrWinHandler,3
	cmp dl, cWinEventClick
	jz near $-150+6

codefragment newAirportConstrWinHandler
	icall AirportConstrDragUITick

codefragment oldLandscapeGenWinHandler,3
	cmp dl, cWinEventMouseToolClose
	jz near $-339+6

codefragment newLandscapeGenWinHandler
	icall LandscapeGenDragUITick

codefragment findrailroadtoolmousedragdirection,5
	db 0x01
	db 0x74, 0x29
	db 0x80, 0x3D

codefragment findRailConstrToolClickProcs,30
	bts dword [esi+window.disabledbuttons], 14
	btr dword [esi+window.activebuttons], 14

codefragment oldRailConstrMouseToolClose,6
	mov word [esi+window.data + 4], -1
	mov cl, 0x1B
	db 0xE8

codefragment newRailConstrMouseToolClose
	icall RailConstrOrigMouseToolClose
	setfragmentsize 7


endcodefragments


patchenhancegui:
	// Find memory locations for new Depot trash handler
	stringaddress findwindowraildepotdrophandle,1,1
	mov [windowRailDepotDropHandle], edi
	
	stringaddress oldwindowstreetdepotdrophandle,1,3
	mov [windowDepotDropHandle1], edi
	stringaddress oldwindowstreetdepotdrophandle,2,3
	mov [windowDepotDropHandle2], edi
	stringaddress oldwindowstreetdepotdrophandle,3,3
	mov [windowDepotDropHandle3], edi

#if 0
	// Find memory locations for new Rail Depot 
	stringaddress findwindowraildepotsize,1,1
	mov [windowRailDepotSize], edi
	stringaddress findwindowraildepotdrawwithengine,1,1
	mov [windowRailDepotDrawWithEngine], edi
	stringaddress findwindowraildepotdrawnoengine,1,1
	mov [windowRailDepotDrawWithNoEngine], edi
#endif

	// Transparent Station Signs
	multipatchcode oldaddstationsigntotexteffect,newaddstationsigntotexteffect,3
	patchcode oldtextcolorrange,newtextcolorrange,1,1

	push 12
	call malloccrit
	pop dword [enhanceguioptions_defaultdata]

	push 12
	call malloccrit
	pop dword [enhanceguioptions_savedata]

	call loadenhanceguisettingsfromfile // reset to file default
	call enhancegui_settingschanged

	// Fixable map window
	patchcode oldmapwindowclicked,newmapwindowclicked,1,1

	// Draggable dynamite
	patchcode oldDemolishTile,newDemolishTile,1,1
	patchcode oldRailConstrWinHandler,newRailConstrWinHandler,1,1
	patchcode oldRoadConstrWinHandler,newRoadConstrWinHandler,1,1
	patchcode oldDockConstrWinHandlerEnd,newDockConstrWinHandlerEnd,1,1
	patchcode oldAirportConstrWinHandler,newAirportConstrWinHandler,1,1
	patchcode oldLandscapeGenWinHandler,newLandscapeGenWinHandler,1,1
	stringaddress findrailroadtoolmousedragdirection,1+WINTTDX,2
	mov eax, [edi]
	mov [RailToolMouseDragDirectionPtr], eax
	stringaddress findrailroadtoolmousedragdirection,2-WINTTDX,2
	mov eax, [edi]
	mov [RoadToolMouseDragDirectionPtr], eax

	// Draggable N-S and E-W rails
	stringaddress findRailConstrToolClickProcs,1,1
	mov edi, [edi]
	mov [RailConstrToolClickProcs], edi
	mov dword [edi+8], addr(RailNSPieceToolClick)
	mov dword [edi+16], addr(RailEWPieceToolClick)

	patchcode oldRailConstrMouseToolClose,newRailConstrMouseToolClose,1,1
	ret
