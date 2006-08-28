//  welcome to StevenHs attack on road vehicles...
//  Let me introduce to you TRAMS!!
//  The goal is to utilise a bit in vehmiscflags to tell if an RV is a 'Tram'
//  when it is, it need to check BITS 0..3 OF L3 of a CLASS 2 Road which states tram tracks
//   OR: bits 12..13 OF L3 on a LEVEL CROSSING... (two bits required to have raw tram/train crossings).
//  .... this is going to be hell.. I wonder if I can do it?

#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>
#include <ptrvar.inc>
#include <textdef.inc>
#include <misc.inc>
#include <vehtype.inc>

patchproc trams, patchtrams

extern setTramPtrWhilstRVProcessing, setTramPtrWhilstRVProcessing.origfn
extern shiftTramBytesIntoL5, insertTramTrackL3Value
extern DrawTramTracks, DrawTramTracks.origfn, newgraphicssetsenabled, grabLandData, RefreshWindows, gettileinfo
extern Class2RouteMapHandlerChunk1, Class2RouteMapHandlerChunk2, roadtoolbarelemlisty2
extern invalidatetile,oldClass2DrawLand, newStartToClass2DrawLand, attemptRemoveTramTracks
extern insertTramTrackIntoRemove, noOneWaySetTramTurnAround,noOneWaySetTramTurnAround.rvmovement
extern RoadToolBarDropDown,Class0DrawLand, updateRoadRemovalConditions, checkroadremovalconditions
extern insertTramsIntoGetGroundAltitude, insertTramsIntoGetGroundAltitude.origfn
extern stopTramOvertaking, rvcheckovertake, patchflags, editTramMode,stdRoadElemListPtr
extern tramtracks,saTramConstrWindowElemList,tramtracksprites
extern setTramXPieceTool,setTramYPieceTool, drawTramTracksInTunnel, addgroundsprite
extern bTempNewBridgeDirection, checkIfThisShouldBeATramStop, addsprite,paRoadConstrWinClickProcs
extern drawTramTracksUnderBridge, checkIfTramsAndKeepTracksUnder, newSendVehicleToDepotAuto
extern busstationwindow, oldbusstoptext, busdepotwindow, oldbusdepottext, DestroyWindow
extern buildtruckstopprocarea, buildtruckstopfunction, buildbuslorryorientation

extern roadmenudropdown,roadmenuelemlisty2,roadDropdownCode,createRoadConstructionWindow

extern checkdepot3jump, checkdepot4jump, checkdepot3return, checkdepot4return, checkdepot5jump, checkdepot5return

begincodefragments
	codefragment olddrawgroundspriteroad, 9
		cmp dh, 1
		jbe $+2+0x04
		add bx, byte -19

	codefragment oldGroundAltidudeGetTileInfo, 11
		push	ebx
		push	edi
		push	ax
		push	cx
		and	al, 0F0h
		and	cl, 0F0h

	codefragment oldCallRVProcessing, 9
		retn
		push	edi
		mov	esi, edi

	codefragment stopTownFromSeeingTramsOld, 2
		push    esi
		push    ebp
		mov     ax, 2

	codefragment stopTownFromSeeingTramsNew
		icall	setTownIsExpandingFlag
		setfragmentsize	9

	codefragment stopTownFromSeeingTramsOld2, 6
		mov     cx, ax
		movzx   edi, di
		mov     ax, 2



	codefragment oldClass2Chunk1
	#if WINTTDX
		mov	al, [landscape5(di)]
	#else
		db 0x67, 0x65, 0x8A, 0x05
	#endif
		mov	ah, al
		and	ah, 0F0h

	codefragment newClass2Chunk1
		icall   Class2RouteMapHandlerChunk1
	#if WINTTDX
		setfragmentsize 11
	#else
		setfragmentsize 9
	#endif

	//GetTileHeightMap will return the L5 array, we want L3
	codefragment oldGetTileHeightMapChunk, 7
		and	dh, 0Fh
		mov	bh, dh
		push	bx

	codefragment newGetTileHeightMapChunk
		icall	insertTramTrackL3Value
		setfragmentsize 8

	codefragment oldRemoveRoadGetTileInfo, 81
		inc dl
		stc
		retn

	codefragment newRemoveRoadGetTileInfo
		icall	insertTramTrackIntoRemove
		setfragmentsize 8

	//somehow 'create' the tram tracks
	codefragment oldSendRoadBytesToL5
	#if WINTTDX
		or	byte [landscape5(si)], bh
	#else
		db 0x67, 0x65, 0x08, 0x3c
	#endif
		mov	byte [landscape2+esi], 0

	codefragment newSendRoadBytesToL5
		icall	shiftTramBytesIntoL5
	#if WINTTDX
		setfragmentsize 13
	#else
		setfragmentsize 11
	#endif

	//delete tram tracks
	codefragment oldRemoveRoadL5Area
	#if WINTTDX
		xor	[landscape5(si)], bh
		test	byte [landscape5(si)], 0Fh
	#else
		db 0x67, 0x65, 0x30, 0x3c
		db 0x67, 0x65, 0xf6, 0x04, 0x0f 
	#endif

	codefragment newRemoveRoadL5Area
		icall   attemptRemoveTramTracks
	#if WINTTDX
		setfragmentsize 13
	#else
		setfragmentsize 9
	#endif

	codefragment oldClass2End, 8
		cmp ah, 6
		jnb $+2+0x0C
		and eax, 0Fh

	codefragment newClass2End
		icall	noOneWaySetTramTurnAround
		setfragmentsize 8

	codefragment findClass0DrawLand
		push	ebx
		mov	bl, dh
		and	ebx, 1Ch

	codefragment oldRoadRemovalConditions, -21
		mov	word [operrormsg2], 0FFFFh
		push	bx

	codefragment newRoadRemovalConditions
		icall	updateRoadRemovalConditions
		setfragmentsize 8

	codefragment oldRVProcCheckOvertake, 10
		cmp	byte [esi+66h], 0
	#if WINTTDX
		jnz	near $+6+0x1c9
	#else
		jnz	near $+6+0x1c1
	#endif

	codefragment newRVProcCheckOvertake
		ijmp	stopTramOvertaking
		retn

	codefragment oldroadmenudropdown,-9
		mov	eax, 1601DAh
		mov	ebx, 0C00A0h

	codefragment newroadmenudropdown
		icall	roadmenudropdown
		mov	eax, 1601DAh
		mov	bx,160
		push	ecx
		setfragmentsize 19

	reusecodefragment oldroadmenuselection, oldroadmenudropdown, 47

	codefragment newroadmenuselection
		icall	updateRoadMenuSelection

	codefragment newsetroadmenunum
		pop ecx
		mov [esi+0x2a],cx
		setfragmentsize 6

	codefragment oldCreateRoadConsWindow
		mov	eax, 356 + (22 << 16)
		mov	ebx, 284 + (36 << 16)

	codefragment newCreateRoadConsWindow
		icall	createRoadConstructionWindow
		retn

	codefragment oldSetRoadXPieceTool, 1
		push	esi
		mov	ebx, 1312
		mov	al, 1

	codefragment newSetRoadXPieceTool
		icall	setTramXPieceTool
		setfragmentsize 7

	codefragment oldSetRoadYPieceTool, 1
		push	esi
		mov	ebx, 1311
		mov	al, 1

	codefragment newSetRoadYPieceTool
		icall	setTramYPieceTool
		setfragmentsize 7

	codefragment oldBridgeGetTileInfo, 7
		push	dx
		push	di
		push	ebp
		push	bx

	codefragment oldBuildBusStop, -10
		push	bx
		push	dx
		push	edi
		push	si
		push	bp
		rol	di, 4
		mov	ax, di
		mov	cx, di


	codefragment newBuildBusStop
		icall checkIfThisShouldBeATramStop
		setfragmentsize 10
		

	codefragment findRVMovementArray
		db 0x00, 0x00, 0x00, 0x10, 0x00, 0x02, 0x08, 0x1A, 0x00, 0x04
    

	//-------------------Find creation of road Depot-----------------
	codefragment oldCreateRoadDepot
	#if WINTTDX
		mov	byte [landscape5(di)], bh
	#else
		db 0x67, 0x65, 0x88, 0x3D
	#endif
		mov     [esi+depot.XY], di
		push    ax
		push    di
		push    esi
	codefragment newCreateRoadDepot
		icall	insertTramDepotFlag
	#if WINTTDX
		setfragmentsize 9
	#else
		setfragmentsize 7
	#endif
	//------------------Hack the drawing to show our new depots--------
	codefragment oldDrawRoadDepot, -7
		pop	edi
		pop	cx
		pop	ax
		add	edi, 8
	codefragment newDrawRoadDepot
		icall	drawTramOrRoadDepot
		setfragmentsize 7
	//------------------------------------------------------------
	
	codefragment oldClass9DrawStart, 6
		retn
		test	dh, 0f0h
	codefragment newClass9DrawStart
		icall	storeArrayPointerFromClass9
		setfragmentsize 8

	codefragment oldDrawTunnel, 12
		db 0x0F,0xB6,0xF6,0x66,0x83,0xE6,0x03,0x66,0xD1,0xE6,0x03,0xDE
	codefragment newDrawTunnel
		icall	drawTramTracksInTunnel
		setfragmentsize 7
    
	codefragment drawTramTracksUnderBridgeOld, 36
		and	ebx, 2
		or	esi, ebx
		shl	esi, 1

	codefragment drawTramTracksUnderBridgeNew
		icall	drawTramTracksUnderBridge
		setfragmentsize 7

	codefragment oldDrawBridgeSlope, 11
		shl	ebx, 10h
		mov	bx, si
		or	bx, 8000h
	codefragment_jmp newDrawBridgeSlope,drawNormalSlopeAndAddTrams,5

	codefragment storeClass9LandPointerForBridgeOld, -6
		mov	bh, bl
		and	bx, 0F00Fh


	codefragment storeClass9LandPointerForBridgeNew
		icall	storeClass9LandPointerAgain
		setfragmentsize 6

	codefragment oldDrawBridgeMiddlePart
		mov	si, 0Bh
		test	byte [esp], 10h

	codefragment newDrawBridgeMiddlePart
		icall	drawTramBridgeMiddlePart
		setfragmentsize 8

	codefragment bridgeRemovalKeepTramsUnderOld
#if WINTTDX
		and	byte [landscape4(di)], 0Fh
		or	byte [landscape4(di)], dh
		mov	byte [landscape5(di)], dl
#else
		// same but different order of prefixes
		db 0x67,0x64,0x80,0x25,0x0f
		db 0x67,0x64,0x08,0x35
		db 0x67,0x65,0x88,0x15
#endif


	codefragment bridgeRemovalKeepTramsUnderNew
		icall	checkIfTramsAndKeepTracksUnder
	#if WINTTDX
		setfragmentsize 19
	#else
		setfragmentsize 13
	#endif

	codefragment vehicleToDepotOld, -5
		mov	edx, ebx
		pop	cx
		pop	ebx
		pop	ax

	codefragment vehicleToDepotOld2, 10
		and	al, 5Fh
		cmp	al, 42h

	codefragment vehicleToDepotNew
		icall	newSendVehicleToDepot
		setfragmentsize	7
	
	codefragment vehicleToDepotNew2
		icall	newSendVehicleToDepotAuto
		setfragmentsize	7

	codefragment oldfindcreatebusORtruckstationwindow, 4
		mov	dx, 28h
		mov	ebp, 8

	codefragment newfindcreatebusORtruckstationwindow
		icall	updateDisableStandardRVStops
		setfragmentsize	10

	codefragment findwindowbusstationelements, 10
		db 0x0A,0x07,0x0B,0x00,0xCF,0x00,0x00,0x00,0x0D,0x00,0x42,0x30
	codefragment findwindowbusdepotelements, 10
		db 0x0A,0x07,0x0B,0x00,0x8B,0x00,0x00,0x00,0x0D,0x00,0x06,0x18
	codefragment findroadconsproctable, 42
		dw 0x1810,0x1811,0x329

	codefragment oldSetSelectedBusStop
		add	bp, 7
		bts	eax, ebp

	codefragment newSetSelectedBusStop
		icall	deSelectNormalBusStops
		nop

	codefragment oldDepotListRvs1
		movzx   cx, [human1]
		bt      [eax+vehtype.playeravail], cx

	codefragment newDepotListRvs1
		icall	checkIfTramDepot1
		setfragmentsize 12

	codefragment oldDepotListRvs2
		bt	[ebx+vehtype.playeravail], cx
		adc	dl, 0

	codefragment newDepotListRvs2
		icall	checkIfTramDepot2
		setfragmentsize 7

	codefragment oldDepotListRvs3, 5
		mov	ebx, 116
		bt	[eax+vehtype.playeravail], bp

	codefragment newDepotListRvs3
		icall	checkIfTramDepot3

	codefragment oldDepotListRvs4, 2
		mov	bl, 116
		bt	[eax+vehtype.playeravail], bp

	codefragment newDepotListRvs4
		icall	checkIfTramDepot4

	codefragment oldDepotListRvs5, 5
		mov	ebx, 116
		bt	[eax+vehtype.playeravail], bp

	codefragment newDepotListRvs5
		icall	checkIfTramDepot5

	codefragment oldRemoveTrainTrack, 6
		mov	byte [landscape1 + esi], dl
		mov	byte [landscape2 + esi], 0

	codefragment newRemoveTrainTrack
		icall	resetL3DataToo
		setfragmentsize 7

#if WINTTDX
	codefragment oldRVFindDepot, -13
		add	bx, di
		movzx	edx, bx
	codefragment newRVFindDepot
		icall	checkIfDepotIsTramDepot
		setfragmentsize 9
#else
	codefragment rvFindDepot, -10
		add	bx, di
		movzx	edx, bx
	codefragment newRVFindDepot
		icall	checkIfDepotIsTramDepot
#endif

endcodefragments

patchtrams:
	patchcode oldDepotListRvs1, newDepotListRvs1, 1+WINTTDX, 3 //danger, should be 4! something is patching the same chunk!
	patchcode oldDepotListRvs2, newDepotListRvs2, 1+WINTTDX, 3 //there is 4 of these, so thats a good thing
	storeaddress oldDepotListRvs3, 1, 2, checkdepot3return, 6
	storeaddress oldDepotListRvs3, 1, 2, checkdepot3jump, 10
	patchcode oldDepotListRvs3, newDepotListRvs3, 1, 2 //one gets used...
	storeaddress oldDepotListRvs4, 1, 1, checkdepot4return, 6
	storeaddress oldDepotListRvs4, 1, 1, checkdepot4jump, 10
	patchcode oldDepotListRvs4, newDepotListRvs4, 1, 1
	storeaddress oldDepotListRvs5, 1, 1, checkdepot5return, 6
	storeaddress oldDepotListRvs5, 1, 1, checkdepot5jump, 10
	patchcode oldDepotListRvs5, newDepotListRvs5, 1, 1

	stringaddress olddrawgroundspriteroad
	chainfunction DrawTramTracks, .origfn, 1

	patchcode oldClass9DrawStart, newClass9DrawStart, 2, 4
	patchcode oldDrawTunnel, newDrawTunnel, 1, 1

	patchcode oldRemoveTrainTrack, newRemoveTrainTrack, 1, 1

	stringaddress findwindowbusstationelements, 1, 1
	mov	dword [busstationwindow], edi
	push	ax
	mov	ax, [edi]
	mov	word [oldbusstoptext], ax
	pop	ax
	stringaddress findwindowbusdepotelements, 1, 1
	mov	dword [busdepotwindow], edi
	push	ax
	mov	ax, [edi]
	mov	word [oldbusdepottext], ax
	pop	ax
	stringaddress findroadconsproctable, 1, 1
	mov	dword [buildtruckstopprocarea], edi
	push	eax
	mov	eax, dword [edi]
	mov	dword [buildtruckstopfunction], eax
	pop	eax

	patchcode oldfindcreatebusORtruckstationwindow, newfindcreatebusORtruckstationwindow, 2, 2	//trucks
	patchcode oldfindcreatebusORtruckstationwindow, newfindcreatebusORtruckstationwindow, 1, 1	//buses
	patchcode oldSetSelectedBusStop, newSetSelectedBusStop, 1, 1

	stringaddress oldGroundAltidudeGetTileInfo, 1
	chainfunction insertTramsIntoGetGroundAltitude, .origfn, 1

	mov eax, [ophandler+0x02*8]
	mov ecx, [eax+0x1C]
	mov [oldClass2DrawLand], ecx
	mov dword [eax+0x1C],addr(newStartToClass2DrawLand)

	//---------we only need to chain... no need to hack both start and end.
#if WINTTDX
	stringaddress oldCallRVProcessing, 1, 5
#else
	stringaddress oldCallRVProcessing, 3, 5
#endif
	chainfunction setTramPtrWhilstRVProcessing, .origfn, 1

	patchcode oldClass2Chunk1, newClass2Chunk1, 1, 1

	patchcode stopTownFromSeeingTramsOld, stopTownFromSeeingTramsNew, 1, 1
	patchcode stopTownFromSeeingTramsOld2, stopTownFromSeeingTramsNew, 1, 1
	patchcode oldGetTileHeightMapChunk, newGetTileHeightMapChunk, 1, 1

	storeaddress findClass0DrawLand, 1, 1, Class0DrawLand
	patchcode oldSendRoadBytesToL5, newSendRoadBytesToL5, 1, 1
	patchcode oldRemoveRoadL5Area, newRemoveRoadL5Area, 1, 1
	patchcode oldRemoveRoadGetTileInfo,newRemoveRoadGetTileInfo, 1, 1
	patchcode oldRoadRemovalConditions,newRoadRemovalConditions, 1, 1

	patchcode oldRVProcCheckOvertake,newRVProcCheckOvertake,1,1

	patchcode oldBuildBusStop, newBuildBusStop, 1, 2
	
	patchcode storeClass9LandPointerForBridgeOld,storeClass9LandPointerForBridgeNew, 1, 1
	patchcode drawTramTracksUnderBridgeOld, drawTramTracksUnderBridgeNew, 1, 1
	patchcode oldDrawBridgeSlope, newDrawBridgeSlope, 1, 1
	patchcode oldDrawBridgeMiddlePart, newDrawBridgeMiddlePart, 1, 1
	patchcode bridgeRemovalKeepTramsUnderOld, bridgeRemovalKeepTramsUnderNew, 1, 1
	
	#if WINTTDX
		patchcode oldCreateRoadDepot, newCreateRoadDepot, 1, 2
		patchcode oldDrawRoadDepot, newDrawRoadDepot, 1, 4
	#else
		patchcode oldCreateRoadDepot, newCreateRoadDepot, 2, 2
		patchcode oldDrawRoadDepot, newDrawRoadDepot, 3, 4
	#endif
	
	patchcode vehicleToDepotOld, vehicleToDepotNew, 1, 2
	patchcode vehicleToDepotOld2, vehicleToDepotNew2, 2, 4
	
	stringaddress findRVMovementArray
	mov dword [noOneWaySetTramTurnAround.rvmovement], edi
	stringaddress oldClass2End,1,1

	testmultiflags onewayroads
	jnz .dontTryInsertTramCode
	storefragment newClass2End

.dontTryInsertTramCode:
	//GUI CODE:
	stringaddress oldCreateRoadConsWindow,1,1
	mov eax,[edi+1Fh]
	mov [stdRoadElemListPtr],eax

	patchcode oldCreateRoadConsWindow,newCreateRoadConsWindow,1,1

	patchcode oldroadmenuselection, newroadmenuselection, 1, 1
	stringaddress oldroadmenudropdown,1,1
	mov eax,[edi+3]
	mov [roadmenuelemlisty2],eax

	storefragment newroadmenudropdown
	add edi,lastediadj+50
	storefragment newsetroadmenunum

	patchcode oldSetRoadXPieceTool,newSetRoadXPieceTool,1,1
	patchcode oldSetRoadYPieceTool,newSetRoadYPieceTool,1,1

	;patchcode oldRVFindDepot, newRVFindDepot, 1, 1

	or byte [newgraphicssetsenabled+1],1 << (11 - 8)
	retn

