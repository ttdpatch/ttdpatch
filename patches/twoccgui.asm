/*********************************** New Colour Scheme Window ************************************/
// Created By: Lakie
// Created Date: Decemeber 2005
// Last Change Date: Decemeber 10 2005

/******************************************* Includes ********************************************/
#include <std.inc> // Must be inclided first
#include <human.inc>
#include <misc.inc>
#include <player.inc>
#include <textdef.inc>
#include <window.inc>

/************************************** External Referances **************************************/
extern BringWindowToForeground
extern CreateTooltip
extern CreateWindowRelative
extern DestroyWindow
extern dfree
extern dmalloc
extern DrawWindowElements
extern FindWindow
extern FindWindowData
extern GenerateDropDownMenu
extern invalidatehandle
extern player2array
extern redrawscreen
extern resetcolmapcache
extern SearchAndDestroy
extern WindowClicked
extern WindowTitleBarClicked
extern getnewsprite,grffeature

/************************************ Compile Time Cosntants *************************************/
%assign winwidth 300 // Total width of window
%assign winheight 16 + (16) + 25 + 143
%assign numtabs 4

/************************************* Constants for ingame **************************************/
noglobal varb twoccguitabrows
	db 0x09
	db 0x03
	db 0x02
	db 0x04

noglobal varb twoccguitabbits
	db 0x01
	db 0x0A
	db 0x0D
	db 0x0F
endvar

/************************************* Variables For Ingame **************************************/
uvarb twoccguilasttabclicked, 8 // One for each Company (n-player games)
uvard numtwocolormaps

/********************* This Changes the Company Window Sprite to support 2cc *********************/
extern deftwocolormaps
global recolourcompanywindowsprite
recolourcompanywindowsprite:
	movzx ebx, byte [ebx+player.colourscheme] // Get the current colour scheme
	cmp byte [numtwocolormaps+1], 0x1 // Are at least 256 colormaps loaded?
	jb .nomappings // If not skip the next part
	push ecx // Backup what was in this registor
	movzx ecx, byte [esi+window.company] // Get the company the winodw belongs to
	imul ecx, player2_size // Number of bytes to skip to get to entry
	add ecx, dword [player2array] // Move to the player2 array
	bt dword [ecx+player2.colschemes], 0 // IS the second colour enabled?
	jnc .nocolour2
	movzx ecx, byte [ecx+player2.col2] // Add the second company colour
	jmp .colour2 // Don't run the next part
.nocolour2:
	mov ecx, ebx // The second colour is the primary colour so add itself
.colour2:
	shl ecx, 4 // Increase the second colour to the top 4 bits of a byte
	add ebx, ecx // Add the second colour to the remap table pointer
	pop ecx // Restore this registor
	add ebx, [deftwocolormaps]
	jmp .mappings
.nomappings:
	add ebx, 775 // Default Company Colour Remaps
.mappings:
	shl ebx, 0x10 // Move this into the top 16 bits of ebx
	mov bx, 3097 // The srpte to change
	add bx, 0x8000 // Set bit 15 of ebx
	ret

/****************************** Two Company Colours Window Elements ******************************/
var win_twoccgui_elements
	// Close button
	db cWinElemTextBox, cColorSchemeGrey
	dw 0, 10, 0, 13, 0x00C5

	// Tilte Bar
	db cWinElemTitleBar, cColorSchemeGrey
	dw 11, winwidth-1, 0, 13, ourtext(txtltwocc)
	
	// Background of the Window
	db cWinElemSpriteBox, cColorSchemeGrey
	dw 0, winwidth-1, 14, winheight-1, 0

	// Global Items
	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour1
	dw winwidth-100, winwidth-88, 18, 18+12, statictext(txtetoolbox_dropdown)

	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour2
	dw winwidth-17, winwidth-5, 18, 18+12, statictext(txtetoolbox_dropdown)

	// Tabs
	db cWinElemTab, cColorSchemeGrey // Rail Tab
	dw 0, winwidth-1, 59, winheight-1, 0

	db cWinElemTab, cColorSchemeGrey // Road Tab
	dw 0, winwidth-1, 59, winheight-1, 1

	db cWinElemTab, cColorSchemeGrey // Sea Tab
	dw 0, winwidth-1, 59, winheight-1, 2

	db cWinElemTab, cColorSchemeGrey // Air Tab
	dw 0, winwidth-1, 59, winheight-1, 3

	// Tab Buttons
	db cWinElemTabButton, cColorSchemeGrey // Rail Tab Button
	dw 6, 6+25, 34, 34+25
.railtabsprite:	dw 731

	db cWinElemTabButton, cColorSchemeGrey // Road Tab Button
	dw 34, 34+25, 34, 34+25
.roadtabsprite: dw 732

	db cWinElemTabButton, cColorSchemeGrey // Sea Tab Button
	dw 62, 62+25, 34, 34+25
.shiptabsprite: dw 733

	db cWinElemTabButton, cColorSchemeGrey // Air Tab Button
	dw 90, 90+25, 34, 34+25
.airtabsprite: dw 734

	// Store the Extra Tabs information
	db cWinElemExtraData, cWinDataTabs
	dd win_twoccgui_tabs, 0
	dw 0

	// Text boxes for Global dropdown lists
	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour1 Dropdown List
	dw winwidth-151, winwidth-101, 18, 18+12, ourtext(txtltwocclr1)

	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour2 Dropdown List
	dw winwidth-78, winwidth-18, 18, 18+12, ourtext(txtltwocclr2)

	// Global Text
	db cWinElemText, cColorSchemeGrey
	dw 24, winwidth-161, 16, 16+12, ourtext(txtltwoccglb)

	// End of the List
	db cWinElemLast

/***************************************** Tabs Entries ******************************************/
var win_twoccgui_tabs
	dd win_twoccgui_rail_elements
	dd win_twoccgui_road_elements
	dd win_twoccgui_sea_elements
	dd win_twoccgui_air_elements

/*************************************** Rail Vehicles Tab ***************************************/
var win_twoccgui_rail_elements
	// Steam
	db cWinElemCheckBox, cColorSchemeGrey
	dw 4, 2+12, 64, 64+12, 0xC

	// Diesel
	db cWinElemCheckBox, cColorSchemeGrey
	dw 4, 2+12, 79, 79+12, 0xC

	// Electric
	db cWinElemCheckBox, cColorSchemeGrey
	dw 4, 2+12, 94, 94+12, 0xC

	// Monorail
	db cWinElemCheckBox, cColorSchemeGrey
	dw 4, 2+12, 109, 109+12, 0xC

	// Maglev
	db cWinElemCheckBox, cColorSchemeGrey
	dw 4, 2+12, 124, 124+12, 0xC

	// Diesel Multiple Unit
	db cWinElemCheckBox, cColorSchemeGrey
	dw 4, 2+12, 139, 139+12, 0xC

	// Electric Multiple Unit
	db cWinElemCheckBox, cColorSchemeGrey
	dw 4, 2+12, 154, 154+12, 0xC

	// Passenger Wagons (And Mail)
	db cWinElemCheckBox, cColorSchemeGrey
	dw 4, 2+12, 169, 169+12, 0xC

	// Freight Wagons
	db cWinElemCheckBox, cColorSchemeGrey
	dw 4, 2+12, 184, 184+12, 0xC

	// Steam
	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour1
	dw winwidth-100, winwidth-88, 63, 63+12, statictext(txtetoolbox_dropdown)

	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour2
	dw winwidth-17, winwidth-5, 63, 63+12, statictext(txtetoolbox_dropdown)

	// Diesel
	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour1
	dw winwidth-100, winwidth-88, 78, 78+12, statictext(txtetoolbox_dropdown)

	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour2
	dw winwidth-17, winwidth-5, 78, 78+12, statictext(txtetoolbox_dropdown)

	// Electric
	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour1
	dw winwidth-100, winwidth-88, 93, 93+12, statictext(txtetoolbox_dropdown)

	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour2
	dw winwidth-17, winwidth-5, 93, 93+12, statictext(txtetoolbox_dropdown)

	// Monorail
	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour1
	dw winwidth-100, winwidth-88, 108, 108+12, statictext(txtetoolbox_dropdown)

	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour2
	dw winwidth-17, winwidth-5, 108, 108+12, statictext(txtetoolbox_dropdown)

	// Maglev
	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour1
	dw winwidth-100, winwidth-88, 123, 123+12, statictext(txtetoolbox_dropdown)

	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour2
	dw winwidth-17, winwidth-5, 123, 123+12, statictext(txtetoolbox_dropdown)

	// Diesel Multiple Unit
	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour1
	dw winwidth-100, winwidth-88, 138, 138+12, statictext(txtetoolbox_dropdown)

	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour2
	dw winwidth-17, winwidth-5, 138, 138+12, statictext(txtetoolbox_dropdown)

	// Electric Multiple Unit
	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour1
	dw winwidth-100, winwidth-88, 153, 153+12, statictext(txtetoolbox_dropdown)

	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour2
	dw winwidth-17, winwidth-5, 153, 153+12, statictext(txtetoolbox_dropdown)

	// Passenger Wagons (And Mail)
	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour1
	dw winwidth-100, winwidth-88, 168, 168+12, statictext(txtetoolbox_dropdown)

	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour2
	dw winwidth-17, winwidth-5, 168, 168+12, statictext(txtetoolbox_dropdown)

	// Freight Wagons
	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour1
	dw winwidth-100, winwidth-88, 183, 183+12, statictext(txtetoolbox_dropdown)

	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour2
	dw winwidth-17, winwidth-5, 183, 183+12, statictext(txtetoolbox_dropdown)

	// Steam
	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour1 Dropdown List
	dw winwidth-151, winwidth-101, 63, 63+12, ourtext(txtltwocclr1)

	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour2 Dropdown List
	dw winwidth-78, winwidth-18, 63, 63+12, ourtext(txtltwocclr2)

	// Diesel
	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour1 Dropdown List
	dw winwidth-151, winwidth-101, 78, 78+12, ourtext(txtltwocclr1)

	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour2 Dropdown List
	dw winwidth-78, winwidth-18, 78, 78+12, ourtext(txtltwocclr2)

	// Electric
	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour1 Dropdown List
	dw winwidth-151, winwidth-101, 93, 93+12, ourtext(txtltwocclr1)

	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour2 Dropdown List
	dw winwidth-78, winwidth-18, 93, 93+12, ourtext(txtltwocclr2)

	// Monorail
	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour1 Dropdown List
	dw winwidth-151, winwidth-101, 108, 108+12, ourtext(txtltwocclr1)

	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour2 Dropdown List
	dw winwidth-78, winwidth-18, 108, 108+12, ourtext(txtltwocclr2)

	// Meglev
	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour1 Dropdown List
	dw winwidth-151, winwidth-101, 123, 123+12, ourtext(txtltwocclr1)

	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour2 Dropdown List
	dw winwidth-78, winwidth-18, 123, 123+12, ourtext(txtltwocclr2)

	// Diesel Multiple Unit
	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour1 Dropdown List
	dw winwidth-151, winwidth-101, 138, 138+12, ourtext(txtltwocclr1)

	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour2 Dropdown List
	dw winwidth-78, winwidth-18, 138, 138+12, ourtext(txtltwocclr2)

	// Electric Multiple Unit
	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour1 Dropdown List
	dw winwidth-151, winwidth-101, 153, 153+12, ourtext(txtltwocclr1)

	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour2 Dropdown List
	dw winwidth-78, winwidth-18, 153, 153+12, ourtext(txtltwocclr2)

	// Passenger Wagon
	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour1 Dropdown List
	dw winwidth-151, winwidth-101, 168, 168+12, ourtext(txtltwocclr1)

	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour2 Dropdown List
	dw winwidth-78, winwidth-18, 168, 168+12, ourtext(txtltwocclr2)

	// Freight Wagon
	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour1 Dropdown List
	dw winwidth-151, winwidth-101, 183, 183+12, ourtext(txtltwocclr1)

	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour2 Dropdown List
	dw winwidth-78, winwidth-18, 183, 183+12, ourtext(txtltwocclr2)

	// Steam Text
	db cWinElemText, cColorSchemeGrey
	dw 24, winwidth-161, 63, 63+12, ourtext(txtltwoccstm)

	// Diesel Text
	db cWinElemText, cColorSchemeGrey
	dw 24, winwidth-161, 78, 78+12, ourtext(txtltwoccdsl)

	// Electric Text
	db cWinElemText, cColorSchemeGrey
	dw 24, winwidth-161, 93, 93+12, ourtext(txtltwoccelc)

	// Monorail Text
	db cWinElemText, cColorSchemeGrey
	dw 24, winwidth-161, 108, 108+12, ourtext(txtltwoccmor)

	// Maglev Text
	db cWinElemText, cColorSchemeGrey
	dw 24, winwidth-161, 123, 123+12, ourtext(txtltwoccmgv)

	// Diesel Multiple Unit Text
	db cWinElemText, cColorSchemeGrey
	dw 24, winwidth-161, 138, 138+12, ourtext(txtltwoccdmu)

	// Electric Multiple Unit Text
	db cWinElemText, cColorSchemeGrey
	dw 24, winwidth-161, 153, 153+12, ourtext(txtltwoccemu)

	// Passenger Wagon Text
	db cWinElemText, cColorSchemeGrey
	dw 24, winwidth-161, 168, 168+12, ourtext(txtltwoccpaw)

	// Freight Wagon Text
	db cWinElemText, cColorSchemeGrey
	dw 24, winwidth-161, 183, 183+12, ourtext(txtltwoccfrw)

	// End of element list
	db cWinElemLast

/*************************************** Road Vehicles Tab ***************************************/
var win_twoccgui_road_elements
	// Buses
	db cWinElemCheckBox, cColorSchemeGrey
	dw 4, 2+12, 64, 64+12, 0xC

	// Trams
	db cWinElemCheckBox, cColorSchemeGrey
	dw 4, 2+12, 79, 79+12, 0xC

	// Trucks
	db cWinElemCheckBox, cColorSchemeGrey
	dw 4, 2+12, 94, 94+12, 0xC

	// Buses
	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour1
	dw winwidth-100, winwidth-88, 63, 63+12, statictext(txtetoolbox_dropdown)

	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour2
	dw winwidth-17, winwidth-5, 63, 63+12, statictext(txtetoolbox_dropdown)

	// Trams
	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour1
	dw winwidth-100, winwidth-88, 78, 78+12, statictext(txtetoolbox_dropdown)

	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour2
	dw winwidth-17, winwidth-5, 78, 78+12, statictext(txtetoolbox_dropdown)

	// Trucks
	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour1
	dw winwidth-100, winwidth-88, 93, 93+12, statictext(txtetoolbox_dropdown)

	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour2
	dw winwidth-17, winwidth-5, 93, 93+12, statictext(txtetoolbox_dropdown)

	// Buses
	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour1 Dropdown List
	dw winwidth-151, winwidth-101, 63, 63+12, ourtext(txtltwocclr1)

	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour2 Dropdown List
	dw winwidth-78, winwidth-18, 63, 63+12, ourtext(txtltwocclr2)

	// Trams
	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour1 Dropdown List
	dw winwidth-151, winwidth-101, 78, 78+12, ourtext(txtltwocclr1)

	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour2 Dropdown List
	dw winwidth-78, winwidth-18, 78, 78+12, ourtext(txtltwocclr2)

	// Trucks
	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour1 Dropdown List
	dw winwidth-151, winwidth-101, 93, 93+12, ourtext(txtltwocclr1)

	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour2 Dropdown List
	dw winwidth-78, winwidth-18, 93, 93+12, ourtext(txtltwocclr2)

	// Buses Text
	db cWinElemText, cColorSchemeGrey
	dw 24, winwidth-161, 63, 63+12, ourtext(txtltwoccbus)

	// Tram Text
	db cWinElemText, cColorSchemeGrey
	dw 24, winwidth-161, 78, 78+12, ourtext(txtltwocctrm)

	// Truck Text
	db cWinElemText, cColorSchemeGrey
	dw 24, winwidth-161, 93, 93+12, ourtext(txtltwocctrk)

	// End of element list
	db cWinElemLast

/*************************************** Sea Vehicles Tab ****************************************/
var win_twoccgui_sea_elements
	// Passenger Ships
	db cWinElemCheckBox, cColorSchemeGrey
	dw 4, 2+12, 64, 64+12, 0xC

	// Freight Ships
	db cWinElemCheckBox, cColorSchemeGrey
	dw 4, 2+12, 79, 79+12, 0xC

	// Passenger Ships
	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour1
	dw winwidth-100, winwidth-88, 63, 63+12, statictext(txtetoolbox_dropdown)

	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour2
	dw winwidth-17, winwidth-5, 63, 63+12, statictext(txtetoolbox_dropdown)

	// Freight Ships
	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour1
	dw winwidth-100, winwidth-88, 78, 78+12, statictext(txtetoolbox_dropdown)

	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour2
	dw winwidth-17, winwidth-5, 78, 78+12, statictext(txtetoolbox_dropdown)

	// Passenger Ship
	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour1 Dropdown List
	dw winwidth-151, winwidth-101, 63, 63+12, ourtext(txtltwocclr1)

	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour2 Dropdown List
	dw winwidth-78, winwidth-18, 63, 63+12, ourtext(txtltwocclr2)

	// Freight Ship
	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour1 Dropdown List
	dw winwidth-151, winwidth-101, 78, 78+12, ourtext(txtltwocclr1)

	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour2 Dropdown List
	dw winwidth-78, winwidth-18, 78, 78+12, ourtext(txtltwocclr2)

	// Passenger Ship Text
	db cWinElemText, cColorSchemeGrey
	dw 24, winwidth-161, 63, 63+12, ourtext(txtltwoccpsh)

	// Freight Ship Text
	db cWinElemText, cColorSchemeGrey
	dw 24, winwidth-161, 78, 78+12, ourtext(txtltwoccfsh)

	// End of element list
	db cWinElemLast

/************************************** Air Vehicles Tab ****************************************/
var win_twoccgui_air_elements
	// Small Airports
	db cWinElemCheckBox, cColorSchemeGrey
	dw 4, 2+12, 64, 64+12, 0xC

	// Large Airports
	db cWinElemCheckBox, cColorSchemeGrey
	dw 4, 2+12, 79, 79+12, 0xC

	// Freight Planes
	db cWinElemCheckBox, cColorSchemeGrey
	dw 4, 2+12, 94, 94+12, 0xC

	// Helicopter
	db cWinElemCheckBox, cColorSchemeGrey
	dw 4, 2+12, 109, 109+12, 0xC

	// Small Airports
	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour1
	dw winwidth-100, winwidth-88, 63, 63+12, statictext(txtetoolbox_dropdown)

	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour2
	dw winwidth-17, winwidth-5, 63, 63+12, statictext(txtetoolbox_dropdown)

	// Large Airports
	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour1
	dw winwidth-100, winwidth-88, 78, 78+12, statictext(txtetoolbox_dropdown)

	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour2
	dw winwidth-17, winwidth-5, 78, 78+12, statictext(txtetoolbox_dropdown)

	// Freight Planes
	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour1
	dw winwidth-100, winwidth-88, 93, 93+12, statictext(txtetoolbox_dropdown)

	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour2
	dw winwidth-17, winwidth-5, 93, 93+12, statictext(txtetoolbox_dropdown)

	// Helicopter
	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour1
	dw winwidth-100, winwidth-88, 108, 108+12, statictext(txtetoolbox_dropdown)

	db cWinElemTextBox, cColorSchemeBlue // Drop Down List button for Colour2
	dw winwidth-17, winwidth-5, 108, 108+12, statictext(txtetoolbox_dropdown)

	// Small Airports
	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour1 Dropdown List
	dw winwidth-151, winwidth-101, 63, 63+12, ourtext(txtltwocclr1)

	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour2 Dropdown List
	dw winwidth-78, winwidth-18, 63, 63+12, ourtext(txtltwocclr2)

	// Large Airports
	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour1 Dropdown List
	dw winwidth-151, winwidth-101, 78, 78+12, ourtext(txtltwocclr1)

	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour2 Dropdown List
	dw winwidth-78, winwidth-18, 78, 78+12, ourtext(txtltwocclr2)

	// Freight Planes
	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour1 Dropdown List
	dw winwidth-151, winwidth-101, 93, 93+12, ourtext(txtltwocclr1)

	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour2 Dropdown List
	dw winwidth-78, winwidth-18, 93, 93+12, ourtext(txtltwocclr2)

	// Helicopter
	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour1 Dropdown List
	dw winwidth-151, winwidth-101, 108, 108+12, ourtext(txtltwocclr1)

	db cWinElemTextBox, cColorSchemeBlue // Text Box of the Colour2 Dropdown List
	dw winwidth-78, winwidth-18, 108, 108+12, ourtext(txtltwocclr2)

	// Small Airports
	db cWinElemText, cColorSchemeGrey
	dw 24, winwidth-161, 63, 63+12, ourtext(txtltwoccsap)

	// Large Airports
	db cWinElemText, cColorSchemeGrey
	dw 24, winwidth-161, 78, 78+12, ourtext(txtltwocclap)

	// Freight Planes
	db cWinElemText, cColorSchemeGrey
	dw 24, winwidth-161, 93, 93+12, ourtext(txtltwoccfrp)

	// Helicopter
	db cWinElemText, cColorSchemeGrey
	dw 24, winwidth-161, 108, 108+12, ourtext(txtltwocchel)

	// End of element list
	db cWinElemLast

/****************************** Two Company Colours Window Creation ******************************/
global win_twoccgui_create
win_twoccgui_create:
	pusha // Back up all registors
	push dx // Keep the company window information
	
	mov cx, 0x1F // Use Company Colour Window Class
	call dword [BringWindowToForeground] // Bring the window to front if already open
	jnz .alreadywindowopen // If not open, skip to end

	mov cx, 0x1F // Use Company Colour Window Class
	mov ebx, winwidth + (winheight << 16) // Set the window diamentions (x, y)
	mov dx, -1 // Use own window handler
	mov ebp, win_twoccgui_handler // address of the window handler
	call [CreateWindowRelative] // Create the window near the Company Window

	mov dword [esi+window.elemlistptr], addr(win_twoccgui_elements) // Elements of the window
	pop dx // Restore the company data
	mov word [esi+window.id], dx // Window Id for the colour window
	mov byte [esi+window.company], dl // Change the colour of the title bar

	push edx // Back up registors
	push eax

	movzx edx, dl // Get only the company part of the registor
	movzx eax, word [edx+twoccguilasttabclicked] // Get Bits to set
	call setuptabs // Setup the tabs on startup

	pop eax // Restore Registors
	pop edx

.alreadywindowopen:
	popa // Restore all the registors
	ret

// These setup the tabs with the correct desabled enabled elements
setuptabs:
	mov word [esi+window.selecteditem], ax // Set the current tab
	xor edx, edx // Set edx to 0
	bts edx, eax // Set the bit of the current window
	shl edx, 5+numtabs // Bit shift the on / off
	add dword [esi+window.activebuttons], edx // Set the avctive bits for the tabs

	push edx
	mov ecx, 4*(numtabs*2) // Number of bytes required for the tabs
	call dmalloc // Create the memory block
	mov [esi+window.data], edi // Place the dymanic memory storage
	push edi // Store this for later
	xor eax, eax // Clear eax which is to be applied below
	mov ecx, 2*numtabs // Only clear the number of tabs (Stops Memory Leak)
	rep stosd // Clear all the memory blocks
	pop edi // Make sure the position of the memory remains intact
	pop edx

	movzx eax, byte [esi+window.company] // Get company owner of the window
	imul eax, player2_size // Make sure that the bytes for each player2 entry and stored
	add eax, [player2array] // Move to the player2 artray

	xor ecx, ecx // Set counter to 0
.loop:
	inc ecx // Move to next bit (Also skips global colour 2 bit at start)
	push edi // Make sure that each loop has the correct edi offset
	mov edx, ecx // Make sure the counter is preseved due to order of calculations

	mov ebx, numtabs // Make sure this is numtabs+1
	add edi, 2*(4*numtabs) // Move edi the the last tab's dwords

.onnexttab:
	sub edi, 8 // 2*dword of data per tab	
	dec ebx //decrease the tab being tested
	cmp cl, byte [twoccguitabbits+ebx] // Is it on the tab being checked
	jb .onnexttab

	sub dl, byte [twoccguitabbits+ebx] // Make sure edx points to the bit for the tab
	bt dword [eax+player2.colschemes], ecx // Is the coloursheme active
	jnc .inactive

	bts [edi], edx // Active the custom colour scheme on the gui
	jmp .nextloop // Don't run the next part of the subroutine

.inactive:
	add edx, edx // Double the pointer for which element
	add dl, byte [twoccguitabrows+ebx] // add the number of elements before it

	bts [edi+4], edx // Disable the first dropdown button on the gui
	inc edx // Move to second dropdown button element
	bts [edi+4], edx // Disable the second dropdown button on the gui

.nextloop:
	pop edi // Make sure that each loop has the orgianl offset for active / disabled dwords
	cmp ecx, COLSCHEME_NUM // Make sure it does all the colourscheme bits
	jne .loop // Makes the loop work
	ret

/**************************************** Window Handler *****************************************/
win_twoccgui_handler:
	mov bx, cx
 	mov esi, edi

	cmp dl, cWinEventRedraw // Does the window need redrawing
	jz near win_twoccgui_redraw

	cmp dl, cWinEventClick // Has the mouse clicked on anything
	jz near win_twoccgui_clickhandler

	cmp dl, cWinEventTimer // Is the event timer
	jz near win_twoccgui_timer

	cmp dl, cWinEventDropDownItemSelect // Has a drop down menu item been clicked
	jz near win_twoccgui_dropdown

	ret

/***************************************** Redraw Window *****************************************/
win_twoccgui_redraw:
	call twoccgui_recolour // Recolour the Main Gui before redrawing
	call twoccgui_settabsprites // Set tab sprites to current grf selection
	call twoccguitab_recolour // Recolour the tab data
	call dword [DrawWindowElements] // Redraw the window's elements
	ret

// Set tab sprites to current grf selection
twoccgui_settabsprites:
#if 0
	pusha
	mov edi,win_twoccgui_elements.railtabsprite
	mov edx,0x100	// generic handler for feature 0 (trains)
	xor ebx,ebx
	xor esi,esi
.nextfeature:
	mov [grffeature],dl
	mov eax,edx
	call getnewsprite
	jnc .gotsprite
	movzx eax,dl
	add eax,731
.gotsprite:
	mov [edi],ax
	add edi,12
	inc edx
	cmp dl,4
	jb .nextfeature
	popa
#endif
	ret

// Recolours the Elements of the Gui
twoccgui_recolour:
	pusha // Backup all registors

	movzx eax, byte [esi+window.company] // Get the Company
	mov edi, [esi+window.elemlistptr] // Get the element list location

	push eax // Push this registor

	mov ecx, eax // Move the company to the registor for using as pointers

	imul eax, player_size // Multiple up the offsets for the correct offsets
	imul ecx, player2_size

	add eax, [playerarrayptr] // Add the respect array pointers
	add ecx, [player2array]

	movzx ebx, byte [eax+player.colourscheme] // Get the 2 company colours
	movzx edx, byte [ecx+player2.col2]

	bt dword [ecx+player2.colschemes], 0 // Is the second colour set?
	jc .secondcolour
	mov edx, ebx // If not Set move first Company Colour there

.secondcolour:
	pop eax // Restore this registor

	xor ecx, ecx // Make ecx 0 for the loop
	add ecx, 1 // move to the colour part of the element entry

.loop:
	cmp ecx, 12*2+1 // Move past the first 3 entries
	jbe .skip
	cmp ecx, 12*4+1 // Recolour these sprites
	jbe .applycolour
	cmp ecx, 12*(2*numtabs+5)+1 // Don't change the tab colours
	jbe .skip

.applycolour:
	cmp ecx, 12*4+1 // Is it element 5 (second colour dropdown box)
	je .colourtwo
	cmp ecx, 12*(2*numtabs+7)+1 // Is it element 18 (second colour dropdown text)
	je .colourtwo

	mov byte [edi+ecx], bl // Apply First Company Colour
	jmp .skip

.colourtwo:
	mov byte [edi+ecx], dl // Apply Second Company Colour

.skip:
	add ecx, 12 // Move to next element
	cmp ecx, 12*(2*numtabs+8)+1 // 17 elements to change on the master element list
	jne .loop

	popa // Restore all registors
	ret

// Recolour the tab currently selectted.
twoccguitab_recolour:
	pusha // Back up all registors

	movzx eax, byte [esi+window.company] // Move the Current Company into eax
	mov ebp, eax // Store the current player company id
	mov edx, player2_size // Useds to multiple the value up below
	mul edx // Change to hold the number of bytes to skip in the player2 array
	add eax, [player2array] // Move to the player2 array
	mov edi, [esi+window.data] // Move the current memory location for the tabs

	push eax // Preserve the address of the player2 array entries
	movzx edx, byte [esi+window.selecteditem] // Temparly store the tab number
	push edx
	mov eax, edx // Copy value so that it can be used to get the tab address
	mov ecx, 8 // Used to multiple the value below
	mul ecx // Increase to a dword value such as 8 bytes (Next active element dword)
	add edi, eax // Increase edi to the active element dword for this tab
	mov ecx, 2 // Used to devide the value below
	div ecx // Devide the variable to a dword size
	mov esi, [win_twoccgui_tabs+eax] // get the tabs address
	pop edx
	pop eax // Restore the player2 array entries pointer

	mov bl, byte [twoccguitabbits+edx] // Get the current bit offsets for the check bits
	mov bh, byte [twoccguitabrows+edx] // Get the number of items on the tab

	xor ecx, ecx // Set the counter to 0

.loop:
	push ecx // Back up the counter
.ismu:
	bt dword [edi], ecx // Is this special colour scheme enabled
	jnc .nospecscheme

	push edi // Preserve data address
	push ebx
	movzx ebx, bl // Make sure that the usage of this could be used
	movzx edi, cl // Move the current bit
	add edi, ebx // Make sure the tab bit offsets are applied
	sub edi, 1 // Decrease the current bit by one
	add edi, edi // Double edi's pointer
	mov ch, byte [eax+player2.specialcol+edi] // Get the colour scheme for this special class
	inc edi // Move to next byte
	mov cl, byte [eax+player2.specialcol+edi] // Get second colour
	pop ebx // Restore the data address
	pop edi
	jmp .skip // move to the next part of the loop

.nospecscheme:
	cmp ecx, COLSCHEME_DMU-1 // Is the vehicle a below
	jb .notmu // If it isn't and is below jump to next part
	cmp ecx, COLSCHEME_EMU-1 // Is the Vehicle a EMU
	ja .notmu // If it isn't match jump
	sub ecx, COLSCHEME_DMU-COLSCHEME_DIESEL // Move the item back to base
	jmp .ismu // Jump back to the start of the loop

.notmu:
	mov ch, byte [ebp+companycolors] // Get the primary Company Colour
	mov cl, ch // Make the second company colour equal the first
	bt dword [eax+player2.colschemes], 0 // Is there a second company colour defined
	jnc .skip
	mov cl, byte [eax+player2.col2] // Get Second Company Colour

.skip:
	mov edx, [esp] // Use the pushed counter to get the row to modify
	push eax // Preseve the Player2 array pointer
	movzx eax, dl // Copy the current row being checked
	imul eax, 12 // Make sure that the right number of elements is skipped

	push ebx
	sub bh, dl // Count how many checkboxes are left
	movzx edx, bh // Move the number of items to skip
	imul edx, 12 // Multiple the number of rows by 12 bytes
	add eax, edx // Create new pointer
	mov dh, bh // Store the number left
	pop ebx

	push ebx
	cmp dh, bh // If dx is zero then don't add any more bytes
	je .noextra
	sub dh, bh // Get the number of items over it is
	neg dh // Get a the possitive version
	mov bl, dh // Move it to be multipled
	movzx edx, bl // Move the number of items to skip
	imul edx, 24 // Multiple the number of rows by 24 bytes
	add eax, edx // Create new pointer
.noextra:
	pop ebx

	add eax, 1 // Move to colour part
	mov byte [esi+eax], ch // Apply Colour 1
	mov byte [esi+eax+12], cl // Apply Colour 2
	movzx edx, bh // Get the total number of elements
	imul edx, 24 // increase to the next sets
	add eax, edx // increase the pointer
	mov byte [esi+eax], ch // Apply Colour 1
	mov byte [esi+eax+12], cl // Apply Colour 2
	pop eax // Restore the player2 array pointer

	pop ecx // Restore the counter
	inc cl // Increase counter
	cmp cl, bh // loop until all items are recoloured
	jne .loop

	popa // Restore all registors
	ret

/****************************************** Window Timer *****************************************/
win_twoccgui_timer:
	ret // Nothing on the gui needs resetting

/************************************** Window Click Handler *************************************/
win_twoccgui_clickhandler:
	call dword [WindowClicked] // Has this window been clicked
	jns .click // Yes, then contine the subroutine, no then end
	ret

.click:
	cmp byte [rmbclicked],0 // Was it the right mouse button
	je .notrightclick // If not Right Click then continue
//	jmp win_twoccgui_clickright // If Right Click go to new subroutine
	ret // Use this until the Tooptip code can be fixed

.notrightclick:
	cmp ch, 0 // Is it a tab (Since the elements also start at 0)
	je .nottab
	jmp win_twoccgui_tabclickhandler // Use the tab click handler
	ret

.nottab:
	cmp cl, 0 // Was the Close Window Button Pressed
	jnz .notclosewindow
	pusha // Backup Registors (to avoid crash)
	mov edi, [esi+window.data] // Move the memory block for the tabs
	call dfree // Free the memory
	popa // Restore registors
	jmp dword [DestroyWindow] // Close the Window

.notclosewindow:
	cmp cl, 1 // Was the Title Bar clicked
	jnz .nottitlebar
 	jmp dword [WindowTitleBarClicked] // Allow moving of Window

.nottitlebar:
	cmp cl, 2 // Used to catch it before an error (Was main body clicked)
	jnz .notmainbody
	ret //  Abort to save errors

.notmainbody:
	cmp cl, 3
	jnz .notglobalone
	jmp globalcolourslist

.notglobalone:
	cmp cl, 4
	jnz .notglobaltwo
	jmp globalcolourslist

.notglobaltwo:
	cmp cl, 12 // Last tab button
	ja .nottabbutton
	pusha // Backup all registors
	movzx ecx, cl // Make all of ecx be the element number of the tab
	and dword [esi+window.activebuttons], 0xFFFF81FF // Reset all the active tab buttons
	bts dword [esi+window.activebuttons], ecx // Active the clicked Tab
	sub ecx, 5+numtabs // Remove first 4 elements and the actual tabs
	mov word [esi+window.selecteditem], cx // Set the bottom part of the tab
	movzx edx, byte [esi+window.company] // Get current company
	mov byte [edx+twoccguilasttabclicked], cl // Store the last tab to be clicked on
	mov cl, 63 // type of drop down menu
	xor dx, dx // ID of drop down menu
	call [FindWindow]
	call [DestroyWindow]
	popa // Restore all registors
	call redrawscreen
	ret

.nottabbutton:
	ret

// This handels clicks on the tabs
win_twoccgui_tabclickhandler:
	pusha // Backup all the registors

	sub ch, 1 // decrease the current tab pointer
	push ecx // Back up the ecx registor
	movzx ecx, ch // Allow this current tab to be used as a pointer
	mov bl, byte [twoccguitabbits+ecx] // Get starting point for the bits
	mov bh, byte [twoccguitabrows+ecx] // Get the number of elements on the tab
	imul ecx, 8 // Move to the data pointers
	mov edi, [esi+window.data] // Get the data dword pointers
	add edi, ecx // Move to tabs pointers
	pop ecx // Restore the old values

	movzx eax, byte [esi+window.company] // Get the current company
	imul eax, player2_size // Multiply the player pointer by the size of each player entry
	add eax, [player2array] // Move to the player2 array

	cmp cl, bh // Is the element a checkbox
	jae .notcheckbox
	jmp checkboxhandler // Run the special checkbox handler

.notcheckbox:
	push eax // Backup eax
	mov al, 3 // increase the value by this factor
	mul bh // increase bh by the number of elements before nothing clickable
	cmp cl, al // Is the element a checkbox
	pop eax // Restore the registors
	jae .notdropbutton
	jmp dropdownhandler // Jump to the code to use for the drop down buttons

.notdropbutton:
	popa // Restore all registors
	ret

// Handles the checkbox clicks
checkboxhandler:
	push ecx
	movzx ecx, cl // Allow whole of ecx to store the the clicked item
	add cl, bl // Move to the bit to set

	pusha
	movzx edi, byte [esi+window.company] // Set all the variables for the action handler
	shl edi, 8
	or edi, 2
	mov bh, cl // Store the element offset before it gets blanked later.
	xor eax, eax
	xor ecx, ecx
	mov bl, 1
	dopatchaction TwoCompanyColourChange // Change the company colour
	popa

	bt dword [eax+player2.colschemes], ecx // Is the element active
	pop ecx
	jc .activate // carry because will be active

	movzx ebx, bh // Move the total number of elements on the tab
	movzx ecx, cl // Make sure that this can be used for setting / clearing the bit
	btr dword [edi], ecx // Clear the bit in the active elements list
	imul ecx, 2 // two elements per item
	add ecx, ebx // move to the first dropdown
	bts dword [edi+4], ecx // Disable clicking of dropdown menus
	add ecx, 1 // Increase to next dropdown
	bts dword [edi+4], ecx // Disable clicking of dropdown menus
	jmp .end // Make sure it doesn't run the activate code

.activate:
	movzx ebx, bh // Move the total number of elements on the tab
	movzx ecx, cl // Make sure that this can be used for setting / clearing the bit
	bts dword [edi], ecx // Clear the bit in the active elements
	imul ecx, 2 // two elements per item
	add ecx, ebx // move to the first dropdown
	btr dword [edi+4], ecx // Allow clicking of dropdown menus
	add ecx, 1 // Increase to next dropdown
	btr dword [edi+4], ecx // Allow clicking of dropdown menus

.end:
	pusha // This subroutine does not preserve the registors
	mov cl, 63 // type of drop down menu
	xor dx, dx // ID of drop down menu
	call [FindWindow]
	call [DestroyWindow]
	call resetcolmapcache // Recolour the sprites
	popa
	call redrawscreen // Update the screen

	popa // Restore the registor
	ret

// This handles the buttons for the dropdowns in tabs
dropdownhandler:
	push ecx // We might need the tab number later
	movzx ecx, cl // Fill ecx completely with the actual element clicked

	bt dword [edi+4], ecx // IS the element disabled
	jc .end // If disabled, jump to end since dropdown list shouldn't be made

	push ecx // Back up the element selected
	push ebx // Preserve the bit and row offsets
	mov ebx, 0x00D1 // Move the first string location into ebx
	xor ecx, ecx // Make the counter 0
.loop:
	mov word [tempvar+ecx*2], bx // Add string into the list
	inc ebx // Move to next string
	inc ecx // Move to next colour
	cmp ecx, 16 // Loop for 16 times (16 colour schemes)
	jne .loop
	mov word [tempvar+32], 0xFFFF // End the list
	pop ebx // Restore the bits
	pop ecx

	push eax // Backup this registor
	movzx eax, byte [esi+window.company] // Get the company id
	imul eax, player2_size // Increase by the number of bytes per entry
	add eax, [player2array] // Move to the player2 array
	push ecx // Back up the element list

	push eax
	mov ch, [esp+(4*3)+1] // Get back the number of tabs
	sub cl, bh // Remove the extra elements form the value
	xor eax, eax // Blank these for the subroutine
	xor bh, bh
.moreoffset:
	cmp al, ch // Add up the bits on tabs before it
	je .notoffset
	add bh, [twoccguitabrows+eax]
	inc al
	jmp .moreoffset

.notoffset:
	add bh, bh // Double this, 2 elements a row
	add cl, bh // Fix the cl offset further
	pop eax
	movzx ecx, cl // Allow this to be used as a pointer
	movzx dx, byte [eax+player2.specialcol+ecx]
	pop ecx
	pop eax // Restore this registor

	pop ecx // Restore the element and on tab values
	inc ch // Make sure that the actual tab is stored
	xor ebx, ebx // No items are to be disabled
	pusha // Make sure the below subroutine doesn't destroy the registors
	call [GenerateDropDownMenu]
	popa // Restore the registors
	jmp .lend // To avoid a crash since ecx is poped earlier

.end:
	pop ecx // Restore the element and on tab values
	popa // To avoid crash
	ret

.lend:
	call redrawscreen // Show changes
	mov edi, esi // Back up the colour window's ptr


	push ecx // Backup the registors
	push edx

	mov cl, 0x3F // Move the correct details to find the drop down menu
	xor dx, dx
	call [FindWindow] // Find the ptr for the drop down menu

	pop edx // Restore the registors
	pop ecx

	cmp esi, 0 // If no pointer abort
	jnz .continue
	popa // To avoid crash
	ret

.continue:
	mov dx, word [edi+window.x] // Get the current window's x, y
	mov bx, word [edi+window.y]

	push edi // Backup the Company Window's id
	push esi // Backup the dropdown window's id
	mov esi, edi // Move the Company Colour Windows id into esi
	push dx // Backup this Registor
	mov dh, cWinDataTabs // Data to search for
	call FindWindowData // Find the tab data in the elemenet list
	pop dx
	pop esi // Restore the  dropdown windows id
	jc .failed // Couldn't find the data (VERY BAD)

	push edx
	push ecx // Preserve the element clicked
	dec ch // Decrease the tab clicked value
	mov edi, dword [edi] // Get pointer to the array of tab elements
	movzx ecx, ch // make the tab clicked fill ecx
	push ecx // Store the normal version
	imul ecx, 4 // 4 bytes per dword
	mov edi, dword [edi+ecx] // Get the location for the tab's elements
	pop ecx // Restore the normal version
	movzx edx, byte [twoccguitabrows+ecx] // Get the number of elements on this tab
	pop ecx // Restore the element clicked

	movzx eax, cl // Make the element clicked fill ecx
	add edx, edx // Double the number of elements
	imul eax, 0x0C // 12 bytes per elements
	imul edx, 0x0C // 12 bytes per elements
	add eax, edx // Add the number of elements between the pair
	pop edx // Restore this registor
	add eax, 2 // Move to the x part of the element entry

	mov cx, word [eax+edi] // Get the x offset of the item
	add cx, 1 // Dropdown menu should start one px to the right
	add dx, cx // Apply changes

	add eax, 6 // Increase to the y part
	mov cx, word [eax+edi] // Get the y offset of item
	add cx, 1
	add bx, cx

	mov word [esi+window.x], dx // Change Window x,y
	mov word [esi+window.y], bx
	mov word [esi+window.width], 72 // Change Window width

	mov eax, dword [esi+window.elemlistptr] // Get the Drop Down Manu's element list address
	add eax, 4 // Increase the the second x component
	mov word [eax], 71 // Move new width to element list item

.failed:
	pop edi
	call [BringWindowToForeground] // Make sure that it's at the front
	call redrawscreen // MAke sure that the screen display is updated
	popa
	ret

// Creates the drop down list for global colours one and two
globalcolourslist:
	cmp cl, 3 // Which global colour is it?
	push eax // Back up registors
	push ecx
	jnz .notglobalone // Second colour is in a different array

.globalcolourtwo:
	movzx eax, byte [esi+window.company] // Get the window's company
	mov ecx, player_size // Set the player Size
	mul ecx // increase the player offset
	add eax, dword [playerarrayptr] // Move to the player array entries
	movzx dx, byte [eax+player.colourscheme] // Get the First Company Colour
	jmp .continueone // Jump to next part of the subroutine

.notglobalone:
	movzx eax, byte [esi+window.company] // Get the window's company
	mov ecx, player2_size // Set the player Size
	mul ecx // increase the player offset
	add eax, dword [player2array] // Move to the player array entries
	bt dword [eax+player2.colschemes], 0 // Is the second colour enabled?
	jnc .globalcolourtwo // Make sure you get the first company colour
	movzx dx, byte [eax+player2.col2] // Get the second Company Colour

.continueone:
	pop ecx // Restore registors
	pop eax

	push ecx // Back up registors used in the loop
	push edx
	push eax

	xor ebx, ebx // Set all bits to 0, since these are the disable bits
	mov eax, ecx // Store the item selected from the loop counter
	xor ecx, ecx // Loop Starts at 0
	mov dx, 0x00D1 // First text string for colours
.loop:
	mov word [tempvar+ecx*2], dx // Store the string
	call globalcoloursdisable // This disables the colour if it's used by another company

	inc ecx // Increase the loop counter
	inc dx // Increase to the next string

	cmp ecx, 16 // It cannot go over 16 elements
	jne .loop

	mov word [tempvar+32], -1 // End the list

	pop eax // Restore registors
	pop edx
	pop ecx

	call MakeDropDownMenu // Used to make the drop down list (Hacks the x,y's of menu)
	ret

// Creates a Drop Down Menu at the points x, y of the element
MakeDropDownMenu:
	pusha
	pusha // Preserve all registors
	call [GenerateDropDownMenu] // Create the drop down list
	popa

	mov edi, esi // Back up the colour window's ptr

	push ecx // Backup the registors
	push edx

	mov cl, 0x3F // Move the correct details to find the drop down menu
	xor dx, dx
	call [FindWindow] // Find the ptr for the drop down menu

	pop edx // Restore the registors
	pop ecx

	cmp esi, 0 // If no pointer abort
	jnz .continue
	popa // To avoid crash
	ret

.continue:
	mov dx, word [edi+window.x] // Get the current window's x, y
	mov bx, word [edi+window.y]

	mov eax, [edi+window.elemlistptr] // Get element list address

	movzx ecx, cl // Calucate offset
	imul ecx, 0xC
	add ecx, 2
	add eax, ecx

	mov edi, 12*(2*numtabs+3) // Automaticly acounts for changes to the number of tabs

	mov cx, word [eax+edi] // Get the x offset of the item
	add cx, 1
	add dx, cx

	add edi, 6 // Increase to the y part

	mov cx, word [eax+edi] // Get the y offset of item
	add cx, 1
	add bx, cx

	mov word [esi+window.x], dx // Change Window x,y
	mov word [esi+window.y], bx
	mov word [esi+window.width], 72 // Change Window width

	mov eax, dword [esi+window.elemlistptr] // Get the Drop Down Manu's element list address
	add eax, 4 // Increase the the second x component
	mov word [eax], 71 // Move new width to element list item

	call [BringWindowToForeground] // Make sure that it's at the front
	call redrawscreen // MAke sure that the screen display is updated
	popa
	ret

// Calculates which colours are in use
globalcoloursdisable:
	cmp al, 3 // If it's not the first colour then nothing is to be disabled
	jnz .end

	push eax // Back up the registors
	push edx

	xor eax, eax // Set eax to 0 so that the loop will work correctly 

.loop:
	cmp al, byte [esi+window.company] // If it's the same company don't disable
	je .skip
	
	push eax // Store this registor
	mov edx, player_size // Multiple the counter by this value
	mul edx // increase eax to the number of bytes to skip
	mov edx, eax // Move the new offset out of the counter
	pop eax // Restore the counter
	add edx, [playerarrayptr] // Move to the player arraies
	cmp word [edx+player.name], 0 // IF the player doesn't exist don't disable a colour
	jz .skip

	cmp byte [edx+player.colourscheme], cl // Is it the same colour
	jnz .skip
	
	bts ebx, ecx // Set the bit for this colour

.skip:
	inc eax // increase loop counter
	add edx, player_size // Increase to the next player array entry
	cmp eax, 8 // Only loop 8 times (8 companies)
	jne .loop

	pop edx // Restore the Registors
	pop eax

.end:
	ret

/********************************* Drop Down List Click Handler **********************************/
win_twoccgui_dropdown:
	cmp ch, 0 // Is it the return for a tab drop down
	je .nottab
	jmp changetab

.nottab:
	cmp cl, 4 // Is it the global colours clicked
	ja .notglobal // if not global jump
	jmp changeglobal

.notglobal:
	ret

// Changes the global colours
changeglobal:
	push edi // Backup registors
	movzx edi, byte [esi+window.company] // Get company
	shl edi, 8 // Player company in top 8 bits
	or edi, 1
	mov dh, al // Store the colour for the action handler

	cmp cl, 3 // Is it the first colour
	jz .iscolourone
	mov bh, 1 // Denotes it being the second colour

.iscolourone:
	jmp changetab.ChangeColour

// Changes the colours stored where the tab is
changetab:
	push edi
	dec ch // Decrease tab value so it can be used as a multipler
	push ecx // Make sure the element clicked is preserved
	movzx ecx, ch // Move the tab clicked to the whole of ecx
	movzx edx, byte [twoccguitabbits+ecx] // Number of bits to offset by
	movzx ebp, byte [twoccguitabrows+ecx] // Get the number of elements before
	sub edx, 1 // Remove the first bit which is have global colour 2 defined
	add edx, edx // 2 bytes per bit colour slot wise

	movzx ecx, byte [esp] // Make the element completely fill ecx
	sub ecx, ebp // Remove the extra elements
	add ecx, edx // Add the colour bytes that come before it

	movzx edi, byte [esi+window.company] // Get the current company
	shl edi, 8 // This is in the top byte
	mov dh, al // Colour should be stored in dh for the actionhandler
	mov bh, cl // Item to change should be in here
	pop ecx

.ChangeColour:
	xor eax, eax
	xor ecx, ecx
	// Should theorically never fail, unless desyncing
	mov bl, 1
extern TwoCompanyColourChange_actionnum, actionhandler
	dopatchaction TwoCompanyColourChange // Change the company colour
	pop edi
	ret

/********************************* Change Colour Action Handler **********************************/
// This is required to make sure BOTH computers in multiplayer remain synced, otherwise it all works the same.
// Input:	edi - top byte company, low byte colour (global)
//		dh - colour
//		bh - colour to change (offset)
exported TwoCompanyColourChange
	test bl, 1
	jnz .Continue

	mov ebx, 0 // Always has no cost.
	ret

.Continue:
	test di, 1 // Global colours should be handled differently
	jnz .Global

	test di, 2 // Checkboxes are slightly less complicated but have different code
	jnz .Checkboxes

	shr edi, 8 // Make it a valid offset for below
	movzx ebx, bh // Used as the master offset later
	imul edi, player2_size // multiple by the number of bytes per player2 enrty
	add edi, [player2array] // Move to the player2 array

	mov byte [edi+player2.specialcol+ebx], dh // Apply new colour
	jmp .Done

.Checkboxes:
	shr edi, 8 // Make it a valid offset for below
	movzx ebx, bh // Used as the master offset later
	imul edi, player2_size // multiple by the number of bytes per player2 enrty
	add edi, [player2array] // Move to the player2 array

	xor edx, edx // Generate the right bit
	bts edx, ebx

	xor dword [edi+player2.colschemes], edx // Xor to create a toggle effect, Genius
	jmp .Done

.Global:
	shr edi, 8 // Make it a valid offset for below

	test bh, 1
	jnz .SecondColour

	mov [companycolors+edi], dh // Place the new company colour
	imul edi, player_size // Multiple the company by this value
	add edi, [playerarrayptr] // Move to the player array

	mov byte [edi+player.colourscheme], dh // Store the new company colour
	jmp .Done

.SecondColour:
	imul edi, player2_size // multiple by the number of bytes per player2 enrty
	add edi, [player2array] // Move to the player2 array

	mov byte [edi+player2.col2], dh // Store the new company colour
	bts dword [edi+player2.colschemes], 0 // Tell ttdpatch second colour is defined

.Done:
	pusha
	call resetcolmapcache // Recolour the sprites
	popa
	call redrawscreen // Update the screen
	ret


