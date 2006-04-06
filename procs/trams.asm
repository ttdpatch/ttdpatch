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

patchproc trams, patchtrams

extern storeVehIDAndContinue, destroyVehIDAndContinue, shiftTramBytesIntoL5, insertTramTrackL3Value
extern DrawTramTracks, DrawTramTracks.origfn, newgraphicssetsenabled, grabLandData, RefreshWindows, gettileinfo
extern Class2RouteMapHandlerChunk1, Class2RouteMapHandlerChunk2, roadtoolbarelemlisty2
extern invalidatetile,oldClass2DrawLand, newStartToClass2DrawLand, attemptRemoveTramTracks
extern insertTramTrackIntoRemove, noOneWaySetTramTurnAround,noOneWaySetTramTurnAround.rvmovement
extern RoadToolBarDropDown,Class0DrawLand, updateRoadRemovalConditions, checkroadremovalconditions
extern drawTramTracksOnStation, drawTramTracksOnStation.origfn
extern insertTramsIntoGetGroundAltitude, insertTramsIntoGetGroundAltitude.origfn
extern stopTramOvertaking, rvcheckovertake, patchflags, editTramMode,stdRoadElemListPtr
extern tramtracks,saTramConstrWindowElemList,tramtracksprites
extern setTramXPieceTool,setTramYPieceTool
extern bTempNewBridgeDirection, checkIfThisShouldBeATramStop, addsprite,paRoadConstrWinClickProcs

extern updateBridgeData1, updateBridgeData2, updateBridgeData1.origfn, updateBridgeData2.origfn


extern roadmenudropdown,roadmenuelemlisty2,roadDropdownCode,createRoadConstructionWindow

extern dontForgetTramCrossingsRail, dontForgetTramCrossingsRoad, drawTramTracksLevelCrossing

begincodefragments
	codefragment olddrawgroundspriteroad, 9
		cmp dh, 1
		jbe $+2+0x04
		add bx, byte -19

	codefragment oldDrawRoadStationCode, -5
		pop	ebp
		add	ebp,4

	codefragment oldGroundAltidudeGetTileInfo, 11
		push	ebx
		push	edi
		push	ax
		push	cx
		and	al, 0F0h
		and	cl, 0F0h

	//hack the start of RVProcessing to get the Cur Vehicle IDX
	codefragment oldStartRVProcessing, 7
		add	dl, 2
		and	dl, 7

	codefragment newStartRVProcessing
		icall	storeVehIDAndContinue
		setfragmentsize 12

	//hack the end of RVProcessing to cancel the stored IDX
	codefragment oldEndRVProcessing, 2
		mov	al, 12h
		mov	bx, [esi+veh.XY]

	codefragment newEndRVProcessing
		icall	destroyVehIDAndContinue
		setfragmentsize 9

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
		push    bx
		push    dx
		push    edi
		push    si
		push    bp
		rol     di, 4
		mov     ax, di
		mov     cx, di


		
	codefragment newBuildBusStop
		icall checkIfThisShouldBeATramStop
		setfragmentsize 10
		
	codefragment oldSetupLevelCrossingViaRail
		and     byte [landscape4(bx)], 0Fh
		or      byte [landscape4(bx)], 10h
		or      byte [landscape5(bx)], dh

	
	codefragment newSetupLevelCrossingViaRail
		icall	dontForgetTramCrossingsRail
	#if WINTTDX
		setfragmentsize 20
	#else
		setfragmentsize 14
	#endif
	
	#if WINTTDX
	codefragment oldSetupLevelCrossingViaRoad, 16
		shl     edi, 1
		pop     bx
		test    bl, 1
	#else
	codefragment oldSetupLevelCrossingViaRoad
		and	byte [landscape4(si)], 0Fh
		or	byte [landscape4(si)], 20h
		mov	byte [landscape5(si)], dl
		movzx   esi, si
	#endif


	codefragment newSetupLevelCrossingViaRoad
		icall	dontForgetTramCrossingsRoad
	#if WINTTDX
		setfragmentsize 20
	#else
		setfragmentsize 14
	#endif

	codefragment oldDrawLevelCrossing,-8
		shr     si, 8
		and     si, 0Fh

	
	codefragment newDrawLevelCrossing
		icall	drawTramTracksLevelCrossing
		setfragmentsize 8

	codefragment findRVMovementArray
		db 0x00, 0x00, 0x00, 0x10, 0x00, 0x02, 0x08, 0x1A, 0x00, 0x04


	//-------------------Find creation of road Depot-----------------
	codefragment oldCreateRoadDepot
	#if WINTTDX
		mov     byte [landscape5(di)], bh
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
		pop     edi
		pop     cx
		pop     ax
		add     edi, 8
	codefragment newDrawRoadDepot
		icall	drawTramOrRoadDepot
		setfragmentsize 7
	//------------------------------------------------------------
	
	codefragment oldFindRoadDepot, 35
		mov     bp, 100h
	codefragment newFindRoadDepot
		icall	insertTramTracksIntoFindRoadDepot
		setfragmentsize 8
    
endcodefragments

patchtrams:
	stringaddress olddrawgroundspriteroad
	chainfunction DrawTramTracks, .origfn, 1

	#if WINTTDX
		stringaddress oldDrawRoadStationCode, 1, 3
	#else
		stringaddress oldDrawRoadStationCode, 2, 3
	#endif
	chainfunction drawTramTracksOnStation, .origfn, 1

	stringaddress oldGroundAltidudeGetTileInfo, 1
	chainfunction insertTramsIntoGetGroundAltitude, .origfn, 1
    
	mov eax, [ophandler+0x02*8]
	mov ecx, [eax+0x1C]
	mov [oldClass2DrawLand], ecx
	mov dword [eax+0x1C],addr(newStartToClass2DrawLand)

	patchcode oldStartRVProcessing, newStartRVProcessing, 1, 1
	patchcode oldEndRVProcessing, newEndRVProcessing, 3, 4
	patchcode oldClass2Chunk1, newClass2Chunk1, 1, 1
	patchcode oldGetTileHeightMapChunk, newGetTileHeightMapChunk, 1, 1

	storeaddress findClass0DrawLand, 1, 1, Class0DrawLand
	patchcode oldSendRoadBytesToL5, newSendRoadBytesToL5, 1, 1
	patchcode oldRemoveRoadL5Area, newRemoveRoadL5Area, 1, 1
	patchcode oldRemoveRoadGetTileInfo,newRemoveRoadGetTileInfo, 1, 1
	patchcode oldRoadRemovalConditions,newRoadRemovalConditions, 1, 1

	patchcode oldRVProcCheckOvertake,newRVProcCheckOvertake,1,1

	patchcode oldBuildBusStop, newBuildBusStop, 1, 2

	#if WINTTDX
		patchcode oldCreateRoadDepot, newCreateRoadDepot, 1, 2
		patchcode oldDrawRoadDepot, newDrawRoadDepot, 1, 4
		patchcode oldFindRoadDepot, newFindRoadDepot, 1, 3
	#else
		patchcode oldCreateRoadDepot, newCreateRoadDepot, 2, 2
		patchcode oldDrawRoadDepot, newDrawRoadDepot, 3, 4
		patchcode oldFindRoadDepot, newFindRoadDepot, 3, 3
	#endif
	
	
	//----------------------------LEVEL CROSSINGS
	
	//patchcode oldSetupLevelCrossingViaRail,newSetupLevelCrossingViaRail,1,1
	//patchcode oldSetupLevelCrossingViaRoad,newSetupLevelCrossingViaRoad,1,1
	
	//patchcode oldDrawLevelCrossing, newDrawLevelCrossing, 1, 1
	
	//-----------------------------------------------------
	//My attempt at bridges... failed.

	//stringaddress oldBridgeGetTileInfo,1,3
	//mov eax,[edi+8h]
	//mov [bTempNewBridgeDirection],eax

	//stringaddress oldBridgeGetTileInfo, 1, 3
	//chainfunction updateBridgeData1, .origfn, 1

	//stringaddress oldBridgeGetTileInfo, 2, 3
	//chainfunction updateBridgeData2, .origfn, 1
	
	//-----------------------------------------------------

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

	stringaddress oldroadmenudropdown,1,1
	mov eax,[edi+3]
	mov [roadmenuelemlisty2],eax

	storefragment newroadmenudropdown
	add edi,lastediadj+50
	storefragment newsetroadmenunum

	patchcode oldSetRoadXPieceTool,newSetRoadXPieceTool,1,1
	patchcode oldSetRoadYPieceTool,newSetRoadYPieceTool,1,1

	or byte [newgraphicssetsenabled+1],1 << (11 - 8)
	retn

