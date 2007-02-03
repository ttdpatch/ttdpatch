
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

// Data for a window element (usage of last word depends on type)
struc windowbox
	.type:		resb 1	// 0h:	type of UI element
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

