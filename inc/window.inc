
// And some GUI Constants to make life easier
%define cWinEventClick			0
%define cWinEventRedraw			1
%define cWinEventUITick			2
%define cWinEventProcTick		3
%define cWinEventSecTick		4
%define cWinEventTimer			5
%define cWinEventMouseToolClick		6
%define cWinEventMouseToolClose		7
%define cWinEventClose			8
%define cWinEventTextUpdate		9
%define cWinEventMouseMenuRelease	0Ah
%define cWinEventMouseMenuUITick	0Bh
%define cWinEventMouseRelease		0Ch
%define cWinEventMouseDragUITick	0Dh
%define cWinEventMouseDragRelease	0Eh
%define cWinEventMouseToolUITick	0Fh
%define cWinEventDropDownItemSelect	10h
#if WINTTDX
// mouse wheel messages sent by patched TTD only
%define cWinEventWheelUp		11h
%define cWinEventWheelDown		12h
#endif
%define cWinEventResize			13h
%define cWinEventGRFChanges		14h
#if WINTTDX
// mouse wheel messages sent by patched TTD only
%define cWinEventWheelClick		15h
#endif

%define cWinElemDummyBox	0
%define cWinElemSpriteBox	1
%define cWinElemSpriteBoxNextActive 2
%define cWinElemTextBox 	3
%define cWinElemTextBoxNextActive 4
%define cWinElemText		5
%define cWinElemPushedInBox	6
%define cWinElemTiledBox	7
%define cWinElemSlider		8
%define cWinElemFrameWithText	9
%define cWinElemTitleBar	0Ah
%define cWinElemLast		0Bh
%define cWinElemSizer		0Ch
%define cWinElemExtraData	0Dh	// fake window element, to save some extra data with window definitions
%define cWinElemTab		0Eh
%define cWinElemTabButton	0Fh
%define cWinElemCheckBox	10h
%define cWinElemSetTextColor	11h
%define cWinElemMax		cWinElemSetTextColor

%define cWinDataSizer		0
%define cWinDataTabs		1

%define cColorSchemeDarkBlue	0
%define cColorSchemePaleGreen	1
%define cColorSchemePink	2
%define cColorSchemeYellow	3
%define cColorSchemeRed		4
%define cColorSchemeLightBlue	5
%define cColorSchemeGreen	6
%define cColorSchemeDarkGreen	7
%define cColorSchemeBlue	8
%define cColorSchemeCream	9
%define cColorSchemeMauve	0Ah
%define cColorSchemePurple	0Bh
%define cColorSchemeOrange	0Ch
%define cColorSchemeBrown	0Dh
%define cColorSchemeGrey	0Eh
%define cColorSchemeWhite	0Fh
%define cColorSchemeBlack	10h

// window type ids and refresh bits
// enum enWindowTypes
%define cWinTypeMainView         0
%define cWinTypeMainToolbar      1
%define cWinTypeMainStatusBar    2
%define cWinTypeConstrToolbar    3
%define cWinTypeNewsMessage      4
%define cWinTypeTownList         5
%define cWinTypeStationList      6
%define cWinTypeTown             7
%define cWinTypeMap              8
%define cWinTypeTrainList        9
%define cWinTypeRVList          0Ah
%define cWinTypeShipList        0Bh
%define cWinTypeAircraftList    0Ch
%define cWinTypeVehicle         0Dh
%define cWinTypeVehicleDetails  0Eh
%define cWinTypeVehicleRefit    0Fh
%define cWinTypeVehicleOrders   10h
%define cWinTypeStation         11h
%define cWinTypeDepot           12h
%define cWinTypeNewVehicle      13h
%define cWinTypeBridgeSel       14h
%define cWinTypeMessage         15h
%define cWinTypeExitDialog      16h
%define cWinTypeYesNo           17h
%define cWinTypeStationSel      18h
%define cWinTypeBusStationSel   19h
%define cWinTypeLorryStationSel 1Ah
%define cWinTypeDepotOrient     1Bh
%define cWinTypeDebugger        1Ch
%define cWinTypeCompany         1Dh
%define cWinTypeFinances        1Eh
%define cWinTypeColorScheme     1Fh
%define cWinTypeTextEdit        20h
%define cWinTypeLoadSave        21h
%define cWinTypeMainMenu        22h
%define cWinTypeLinkSetup       23h
%define cWinTypePullDownMenu    24h
%define cWinTypeIncome          25h
%define cWinTypeOperatingProfit 26h
%define cWinTypeToolTip         27h
%define cWinTypeIndustry        28h
%define cWinTypeFaceSelection   29h
%define cWinTypeLandQuery       2Ah
%define cWinTypeTTDPatchWindow  2Ah	// cWinTypeLandQuery reused for TTDPatch
%define cWinTypeLocalAuthority  2Bh
%define cWinTypeSubsidies       2Ch
%define cWinTypeGraphKey        2Dh
%define cWinTypeCargoDelivered  2Eh
%define cWinTypePerfRating      2Fh
%define cWinTypeCompanyValues      30h
%define cWinTypeCompanyLeagueTable 31h
%define cWinTypeTakeoverProposal   32h
%define cWinTypeCargoPaymentRates  33h
%define cWinTypeTutorialSel        34h
%define cWinTypeExclusiveOffer     35h
%define cWinTypeJukebox            36h
%define cWinTypeMusicProgram       37h
%define cWinTypeLandscapeGen       38h
%define cWinTypeResetLandscape     39h
%define cWinTypeTownGen            3Ah
%define cWinTypeIndustryGen        3Bh
%define cWinTypeScenEdRoadConst    3Ch
%define cWinTypeScenEdPlantTrees   3Dh
%define cWinTypePlayerMessage      3Eh
%define cWinTypeDropDownMenu       3Fh
%define cWinAll      40h
%define cWinElemRel  80h
%define cWinElem1   100h
%define cWinElem2   200h
%define cWinElem3   300h
%define cWinElem4   400h
%define cWinElem5   500h
%define cWinElem6   600h
%define cWinElem7   700h
%define cWinElem8   800h
%define cWinElem9   900h
%define cWinElem10 0A00h
%define cWinElem11 0B00h
%define cWinElem12 0C00h
%define cWinElem13 0D00h
%define cWinElem14 0E00h
%define cWinElem15 0F00h

// cWinTypeTTDPatchWindow Window ids
%define cPatchWindowEnhGUI		100
%define cPatchWindowNewsHistory		101
%define cPatchWindowGRFStatus		105
%define cPatchWindowGRFHelper		108
%define cPatchWindowSignalGUI		110
%define cPatchWindowTraceRestrict	111
%define cPatchWindowRailVehMenu		114
%define cPatchWindowTransOpts		115
%define cPatchWindowObjectGUI		120


// Window data
struc window
	.type:			resb 1	// 00h:	window type (0..3fh)
	.itemstotal:		resb 1	// 01h:	number of items in the list (if any)
	.itemsvisible:		resb 1	// 02h:	how many items are visible in the window
	.itemsoffset:		resb 1	// 03h:	index of the first item visible
	.flags:			resw 1	// 04h:	various flags:
					//	bits 0..2: timer: if nonzero decremented
					//	every tick, when reaches 0 event type 4
					//	is generated
					//	bit 3: window is being dragged
					//	bit 4: slider up arrow clicked
					//	bit 5: slider down arrow clicked
					//	bit 6: slider is being dragged
					//	bits 7..8: flash timer, decremented every
					//	tick unless already 0
					//	if nonzero window is being flashed
					//	bit 9: window's view area is not draggable
					//	bit 10: window is being resized
					//	bit 11: element list can be altered without
					//	making a copy (or this is already a copy)
					//	bit 12: the element list is dmalloc'ed and
					//	needs to be dfree'd on window closure
					//	bit 13: this window shouldn't get a default
					//      size when drawn, or has already been resized
					//	bit 14: this window is sticky (this window
					//	won't be closed when pressing <del>)
	.id:			resw 1	// 06h:	window ID
					//	(type and ID should uniquely identify
					//	 a window)
	.x:			resw 1	// 08h:	X position
	.y:			resw 1	// 0ah:	Y position
	.width:			resw 1	// 0ch:	width
	.height:		resw 1	// 0eh:	height
	.opclassoff:		resw 1	// 10h:	class offset of the handling class
					//	if the handler is an Op04 subfunction
					//	else -1
	.function:		resd 1	// 12h:	number of Op04 subfunction or pointer
					//	to window handler if opclassoff=-1
	.viewptr:		resd 1	// 16h:	pointer to view area descriptor
	.activebuttons:		resd 1	// 1ah:	bit mask of pushed buttons
	.disabledbuttons:	resd 1	// 1eh:	bit mask of disabled buttons
	.selecteditem:		resw 1	// 22h:	actually selected item, if any
	.elemlistptr:		resd 1	// 24h:	pointer to element list
					//	(windowbox structures terminated by 0xb)
	.company:		resb 1	// 28h:	company the window belongs to
				resb 1	// 29h:	??
	.data:			resb 10	// 2ah:	contains class-specific extra window data
endstruc

// More window data. Same size as struc window.
struc window2
	.height:		resw 1	// 00h:	Backup of window structure
	.opclassoff:		resw 1	// 02h:	...
	.function:		resd 1	// 04h:	when the window is shaded
	.viewwidth:		resw 1	// 08h:	Backup of view width
	.data1:			resw 1	// 0Ah: class-specific word, (because misaligned dword fetches are bad...)
	.origelemlist:		resd 1	// 0Ch: Backup of original element list, valid is flags bit 12 is set
	.origsize:		resd 1	// 10h: Backup of orignial window size, valid if above is
	.data2:			resd 4	// 14h: 4 class-specific dwords
	.extitemshift:		resb 1	// 24h: amount by which itemstotal, itemsvisible and itemsoffset are left shifted
	.extactualvisible:	resb 1	// 25h:	actual number of items visible, not shifted
			resb window_size-$
endstruc

// Data for a window element (usage of last word depends on type)
struc windowbox
	.type:		resb 1	// 0h:	type of UI element
	.subtype:		// 1h:	for extradata boxes, type of extra data
	.bgcolor:	resb 1	// 1h:	background color
	.x1:		resw 1	// 2h:	coordinates relative to owner window
	.x2:		resw 1	// 4h
	.y1:		resw 1	// 6h
	.y2:		resw 1	// 8h
	.extra:			//	optional extra data for classes 0, 6 and 8
	.text:			//	text ID for classes 3, 4, 5, 9 and a
	.sprite:		//	sprite number for classes 1, 2
	.xtiles:	resb 1	// ah	number of tiles for class 7
	.ytiles:	resb 1	// bh
endstruc

// For checkboxes, extra is layed out like this:
//	bits 0..3:   colour of check mark (0..15)
//	bits 4..10:  bit mask of elements to disable, based on the above (up to 7 consecutive elements)
//	bits 11..15: base element ID of IDs to disable when unchecked (0..31)

// If type is 0Dh (extra data), second byte is the subtype for this box. Remaining ten bytes are the extra data.
struc windatabox_tabextra		// Starting at windowbox+2
	.elemlistptrs:	resd 1	// 0h: pointer to array of pointers to additional elementlists, one elementlist per tab.
	.unused:	resd 1
			resw 1
endstruc

struc windatabox_sizerextra		// Starting at windowbox+2
	.eleminfo:	resd 1	// 0h:	pointer to instructions for resizing the windowboxes
	.constraints:	resd 1	// 4h:	pointer to window size constraints
	.flags:		resw 1	// 8h:	sizerdata flags.
endstruc
// .elements points to an array of instructions, one byte per element:
//	bits 0..3: Set if that element's x1,x2,y1,y2 are to be changed when resizing
//	bits 4..7: Same, but the change is only half the window's delta
// If bit 0 of flags is set, .elelments points to an array of words instead. The additional bits are:
//	bits 8..9:   Set if that element's x1,x2 is to be changed by one-third the window's delta
//	bits 10..11: Set if that element's x1,x2 is to be changed by two-third the window's delta

// .constraints points to
struc winsizer_constraints
	.minwidth:	resw 1	// 0h: Min and max
	.maxwidth:	resw 1	// 2h:    window width
	.itemwidth:	resb 1	// 4h: Width of a single item
	.widtheleidx:	resb 1	// 5h: Element whose .extra needs to get the item count, or -1. Only if .itemwidth is not 1
	.basewidth:	resw 1	// 6h: Extra width to be added to an integer number of items. Only if .itemwidth is not 1

	.minheight:	resw 1	// 8h: repeat above for height
	.maxheight:	resw 1	// Ah
	.itemheight:	resb 1	// Ch
	.heighteleidx:	resb 1	// Dh: item count stored in .extra+1
	.baseheight:	resw 1	// Eh
endstruc
