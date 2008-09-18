
#ifndef __C_SOURCE__
#include <var.inc>

ptrvardec ttdvar_base

// TTD variables are fixed offsets into the data segment.  If USEORG is
// given, we make them relocations by taking the address relative to the
// start of this segment, otherwise they're absolute addresses.
%macro getttdvar 2.nolist
	%if %1<=0x7f9e7 || (WINTTDX && (%1>0xa12b2) && (%1<0xc12b4))
		%define %2 %1
	%elif %1<=0x9f80e
		// in WINTTDX each array has 4896 entries, in DOS only 4890
		%if %1<=0x9c458
			%assign %%arrnum (%1-0x7f9e8)/4890
		%else
			%assign %%arrnum 24	// past sprite arrays
		%endif
		%define %2 %1+WINTTDX*6*%%arrnum
	%else
		%error "Invalid parameter to ttdvar: only 0..0x9f80e supported."
		%define %2 %1	// to prevent a second error message about an undefined identifier
	%endif
%endmacro
%macro ttdvar 2.nolist
#if WINTTDX
	getttdvar %2,%%ttdvarofs
	%1 equ ttdvar_base+%%ttdvarofs
#else
	%1 equ %2
#endif
	%define %1_abs %2
%endmacro

#define ttdvar(a,b) ttdvar a,b
#endif

// ----------------------------------
//  Define variables in TTD's memory
// ----------------------------------

ttdvar(datastart,0x0)			// only useful for the Windows version, where it points to the start of the TTD data segment

ttdvar(landscape1,0x4cba)
ttdvar(landscape2,0x14cba)
ttdvar(landscape3,0x24cba)
ttdvar(desertmap,0x44cba)

#if WINTTDX
	ttdvar(landscape4base,0xb12b3)
	ttdvar(landscape5base,0xa12b3)
#endif

#ifndef __C_SOURCE__
#if WINTTDX
	%define landscape4(reg) (landscape4base+ e %+ reg)
	%define landscape4(reg,large) (landscape4base+ e %+ reg)
	%define landscape5(reg) (landscape5base+ e %+ reg)
	%define landscape5(reg,large) (landscape5base+ e %+ reg)
	%define landscape4_2(reg,reg2) (landscape4base+ e %+ reg + e %+ reg2)
	%define landscape4_2(reg,reg2,large) (landscape4base+ e %+ reg + e %+ reg2)
	%define landscape5_2(reg,reg2) (landscape5base+ e %+ reg + e %+ reg2)
	%define landscape5_2(reg,reg2,large) (landscape5base+ e %+ reg + e %+ reg2)

	%define searchend __image_base__	// where to stop searching
#else
	%define landscape4(reg) fs:reg
	%define landscape4(reg,large) fs:e %+ reg
	%define landscape5(reg) gs:reg
	%define landscape5(reg,large) gs:e %+ reg
	%define landscape4_2(reg,reg2) fs:reg+reg2
	%define landscape4_2(reg,reg2,large) fs:e %+ reg + e %+ reg2
	%define landscape5_2(reg,reg2) gs:reg+reg2
	%define landscape5_2(reg,reg2,large) gs:e %+ reg + e %+ reg2

	%define searchend [ttdmemsize]
#endif
#endif


ttdvar(enginebasevalue,0x4b8e)
ttdvar(waggonbasevalue,0x4b94)
ttdvar(roadvehbasevalue,0x4ba0)
ttdvar(shipbasevalue,0x4ba6)
ttdvar(aircraftbasevalue,0x4b9a)

ttdvar(texteffects,0x4)
ttdvar(texteffects_end,0x4+30*20)	// 20=texteffect_size; break preprocessing though

ttdvar(costs,0x4b34)
ttdvar(trackcost,0x4b3a)
ttdvar(tracksale,0x4bd6)
ttdvar(signalplacecost,0x4b46)
ttdvar(signalremovecost,0x4bdc)
ttdvar(treeplantcost,0x4bac)
ttdvar(remplatformcost,0x4c06)
ttdvar(housermbasecost,0x4c24)
ttdvar(raiselowercost,0x4bb2)
ttdvar(fundingbasecost,0x4c54)
ttdvar(roadbuildcost,0x4b40)
ttdvar(roadremovecost,0x4c2a)
ttdvar(fieldsremovecost,0x4bca)
ttdvar(clearwatercost,0x4c00)
ttdvar(fundingcost,0x4C54)

ttdvar(townarray,0x264)
ttdvar(depotarray,0x452c)
ttdvar(stationarray,0x48cba)
ttdvar(customstringarray,0x6f0f2)	// Player-entered strings, 32 bytes for each string
ttdvar(vehtypearray,0x751a2)		// Vehicle type data (see struc vehtype in ttdprot.ah)
ttdvar(subsidyarray,0x76da4)
ttdvar(vehnameindex,0x76e68)		// text indices for all vehicles (8000+x if default, 7800+x if custom)

ttdvar(datasaveend,0x77179)		// End of the part of the TTD data segment that goes into savegames

ttdvar(stationarrayptr,0x77908)		// Pointer to the station array
ttdvar(industryarrayptr,0x7790c)	// Pointer to the industry array
ttdvar(oldindustryarray,0x51766)	// TTD's original industry array
ttdvar(playerarrayptr,0x77914)		// Pointer to the company array

ttdvar(veharrayptr,0x77918)		// This location holds the pointer to the vehicle array
ttdvar(veharrayendptr,0x7791c)		// Pointer to the end of the vehicle array
ttdvar(oldveharray,0x547f2)		// and this is the old value of the pointer

ttdvar(currentdate,0)			// W: Current date, in days since 1919 (0=1/1/1920)
ttdvar(datefract,2)			// W: Fraction of current date, incremented in 0x375 steps
ttdvar(currentyear,0x770fe)		// B: Current year, 0=1920
ttdvar(currentmonth,0x770ff)		// B: Current month, 0=Jan, 1=Feb, ...

ttdvar(randomseed1,0x25c)		// D:
ttdvar(randomseed2,0x260)		// D:

ttdvar(animcounter,0x4b30)		// W: counter for animation, incremented every tick

ttdvar(trainpurchasecostbase,0x4b8e)	// D,W: inflation-adjusted cost base for train engine purchases
ttdvar(wagonpurchasecostbase,0x4b94)	// D,W: inflation-adjusted cost base for train wagon purchases
ttdvar(planepurchasecostbase,0x4b9a)	// D,W: inflation-adjusted cost base for aircraft purchases

ttdvar(scheduleheap,0x1c18)		// W[5000]: schedule heap
ttdvar(scheduleheapend,0x4328)		// First byte after the schedule array
ttdvar(scheduleheapfree,0x4528)		// P: pointer to free space at the end of the schedule heap
ttdvar(soldvehorderbuff,0x7f970)		// W[82]: orders of the last sold vehicle are stored here
ttdvar(soldvehorderxy, 0x7f9c2)		// W: XY of depot where last vehicle was sold; -1 if above orders not valid
ttdvar(dayprocnextveh,0x76da2)		// W: index of next vehicle for daily processing
ttdvar(companycolors,0x77100)		// B[8]: color mappings for the 8 companies
ttdvar(airportavailmask,0x7710b)		// B: available airport types, bits 0/1/2=small/large/heliport
ttdvar(roadtrafficside,0x7710c)		// B: side of road for vehicles to drive on: 0=left, 10h=right; +80h=may be changed
ttdvar(numberofindustries,0x77114)      // W: 0 = low, 1 = medium, 2 = high\sphericalangle
ttdvar(climate,0x77131)			// B: 0=temperate, 1=arctic, 2=tropic, 3=toyland
ttdvar(snowline,0x77134)			// B: altitude of the snow line in the arctic climate
ttdvar(randomindustrytypes,0x77135)	// B[32]: table of industry types to be randomly created
ttdvar(noftowns,0x77112)			// W: Number of towns to generate
ttdvar(interestrate,0x77118)		// W: Interest rate in percent
ttdvar(terraintype, 0x77126)		// The Type of land to generate
ttdvar(quantityofwater, 0x77128)	// The 'amount' of sea to be on the map
ttdvar(economy,0x7712a)			// W: Economy difficulty setting
ttdvar(disasters,0x7712e)		// W: Disasters difficulty setting
ttdvar(difficultylevel,0x77130)			// B: Overall difficulty setting
ttdvar(currency,0x770fb)			// B: currency used in display: 0=pound, 1=dollar, ...
ttdvar(measuresys,0x770fc)			// B: measurement system: 0=imperial, 1=metric

ttdvar(human1,0x770f8)			// B: Player number of human player
ttdvar(human2,0x770f9)			// B: and of other player if multiplayer, ff if none

ttdvar(aicargovehicles,0x77068)		// table of vehicle types AI uses to transport cargo
// see below for all cargo tables
//ttdvar(cargotypenames,0x76dd8)		// table of names of all 12 cargo types

ttdvar(overflowreturn,0x771f2)		// for div/idiv overflow handler
ttdvar(tempvar,0x7717a)
ttdvar(textrefstack,0x774da)		// text handler's reference stack
ttdvar(windowstack_default, 0x772C0)		// the window stack
ttdvar(windowstacktop,0x774C8)		// window stack top
ttdvar(viewsarray_default, 0x77230)

ttdvar(screenrefreshminx,0x778F0)	// left,top,right,bottom coordinates
ttdvar(screenrefreshminy,0x778F2)	// of screen area that needs redrawing
ttdvar(screenrefreshmaxx,0x778F4)
ttdvar(screenrefreshmaxy,0x778F6)

ttdvar(tracertdistance,0x778F8)
ttdvar(tracertturns,0x778FA)
ttdvar(tracertresult,0x778FB)

ttdvar(operrormsg2,0x774fc)		// W: popup error message (text ID), second line
ttdvar(operrormsg1,0x774fe)		// W: ...and first line (used by various place/remove routines)
ttdvar(currnewsitem,0x776f4)		// currently displayed news item
ttdvar(wgraphicssemaphore,0x778ee)	// W: 
ttdvar(newsitemparam,0x778ea)		// W: used by the news message function
ttdvar(customtxtptr,0x7793c)		// P: pointer to area where custom strings are stored
ttdvar(ttdsystriggers,0x7f9c4)		// W: trigger TTD functions: bit 1="Quit" window, bit 2=autosave, bit 3=pause
ttdvar(curmousecursor,0x771b0)		// D:sprite data for current mouse cursor
ttdvar(curmousetooltype,0x771c0)	// B: current mouse tool type
ttdvar(curmousetoolwintype,0x771c1)	// B: current mouse tool window type
ttdvar(curmousetoolwinid, 0x771c2)	// W: current mouse tool window id

ttdvar(mousecursorspritedata,0x9f17a)	// B/B/W: first 4 bytes of sprite info
ttdvar(selectedtool,0x771cc)		// W: current tool
ttdvar(mousetoolclicklocxy,0x771c8)	// W: XY location of mouse click
ttdvar(mousetoolclicklocfinex,0x771ca)	// B: fine x location of mouse click
ttdvar(mouseflags,0x771be)		// W: bit 0: mouse installed, bit 1: view drag mode, bit 2: landsacpe markers area, bit 3: dot landscape markers, bit 4: red landscape marker

ttdvar(flashtilex,0x771e6)		// W: Exact X location where to flash red, if -1 no old flash
ttdvar(flashtiley,0x771e8)		// W: Exact Y location where to flash red
ttdvar(landscapemarkerorigx,0x771ce)	// W: Exact X location
ttdvar(landscapemarkerorigy,0x771d0)	// W: Exact Y location
ttdvar(highlightareainnerxsize,0x771d2)	// W:
ttdvar(highlightareainnerysize,0x771d4)	// W:
ttdvar(landscapemarkerareaouterxoffs,0x771da)	// W:
ttdvar(landscapemarkerareaouteryoffs,0x771dc)	// W:
ttdvar(highlightareaouterxsize,0x771de)	// W:
ttdvar(highlightareaouterysize,0x771e0)	// W:
ttdvar(dragtoolstartx,0x771ea)		// W:
ttdvar(dragtoolstarty,0x771ec)		// W:
ttdvar(dragtoolendx,0x771ee)		// W: Exact X location of end of dragtool
ttdvar(dragtoolendy,0x771f0)		// W: Exact Y location of end of dragtool

ttdvar(wcurrentstationsize,0x7794c)	// W:current selection of station size and orientation

					// arrays of sprite information
					// 4890 entries in DOS, 4896 in Windows
ttdvar(spritedata,0x7f9e8)		// D[*]: offset in sprite cache, 0 if not in cache
ttdvar(spritesize,0x84650)		// W[*]: size of sprite data
ttdvar(spritexsize,0x86c84)		// W[*]: x dimension of sprite
ttdvar(spriteysize,0x892b8)		// W[*]: y dimension of sprite
ttdvar(spritexoffset,0x8b8ec)		// W[*]: x offset of sprite
ttdvar(spriteyoffset,0x8df20)		// W[*]: y offset of sprite
ttdvar(spriteoffsetinfile,0x90554)	// D[*]: where sprite data starts in .grf file
ttdvar(spritefile,0x951bc)		// B[*]: open file handle with sprite data (index into array at edea0)
ttdvar(spritedataimmutable,0x964d6)	// B[*]: sprite data is immutable, cannot be moved in or removed from the cache
ttdvar(spritetickssinceused,0x977f0)	// W[*]: engine ticks since this sprite was displayed (for cache expiry)
ttdvar(spritelastrequestnum,0x99e24)	// W[*]: num of last request which displayed this sprite
ttdvar(spriteinfoend,0x9c458)		// only to be used as pointer

ttdvar(spriterequestssincelasttick,0x9c458) // W: how many sprites were drawn since last engine tick
ttdvar(spritecacheselector,0x9c45a)	// W: selector of sprite cache
ttdvar(spritecachesize,0x9c468)		// D: size of sprite cache
ttdvar(tempspritefilehandle,0x77208)	// W: temporary sprite file handle

ttdvar(curdecoderuntype,0x9c581)		// B: current LZ77 run type
ttdvar(curfileblocksize,0x7722e)		// W: size of current file buffer

ttdvar(keypresstable,0x9c476)		// Array for all keys; 0=pressed, 80h=not pressed
ttdvar(shiftedkeyasciitable,0x9f70f)	// Array of ASCII codes to generate for each key, with shift
ttdvar(regkeyasciitable,0x9f78f)	// Array of ASCII codes to generate for each key, without shift
ttdvar(curplayer,0x9ea35)		// B: Current player
ttdvar(displayoptions,0x9ea37)		// B: Bits for each of the display options
ttdvar(gamesemaphore,0x9ea38)		// B: Game progress semaphore, nonzero=paused
ttdvar(currentexpensetype,0x9ed31)	// B: Current type of expenses, see the expenses_* constants below
ttdvar(numplayers,0x9ed32)		// B: 1=single player, 2=multi player
ttdvar(gamemode,0x9ed33)		// B: 0=title screen, 1=normal game, 2=scenario editor
ttdvar(scenarioeditmodeactive,0x9ea36)	// B: 
ttdvar(mpcomputer,0x9ed37)		// B: 1=is host computer, 0=is client computer (only valid in multiplayer)
ttdvar(currenttextcolor,0x9ed39)	// W: current text colours
ttdvar(buslorrystationorientation, 0x9ED3B)	// B: orientation of road station
ttdvar(showcatchmentarea, 0x9EDEB) 			// B: 0=disabled 1=enabled
ttdvar(actionnestlevel,0x9edec)		// B: nesting level of [actionhandler] calls (see below)

ttdvar(newroadtrafficside,0x9eded)		// B: side of road for vehicles to drive on at a new game: 0=left, 10h=right; +80h=can be changed, always set!
ttdvar(newtownnamestyle,0x9edee)		// B: town name style 0=English, 1=French, 2=German, 3=American, 4=Latin American, 5=Silly

ttdvar(uiflags,0x9f1e6)			// W: bit 10: edit control active; other bits=??


ttdvar(scurrspriteheader,0x9f186)	// 8B: current sprite header used in when drawing sprite
ttdvar(baTempBuffer1,0x9f1e8)		// 256B: tempbuffer1 for various TTD functions
ttdvar(baTempBuffer2,0x9f2e8)		// 256B: tempbuffer2 for various TTD functions
ttdvar(baTextInputBuffer,0x9f629)	// 64B
ttdvar(bTextInputMaxLength,0x9ecdf)	// B: max. number of bytes in input string
ttdvar(bTextInputMaxWidth,0x9ece0)	// B: max. width in pixels of input string
ttdvar(bTextInputInputChar,0x9ece1)	// B: current text input character, 0 if none
ttdvar(bEditedWindowText, 0x9ede1)	// B: distinguish between text update events
ttdvar(temprecolormapsprite,0x9f18E)	// 6B: pointer to recolor spritedata
ttdvar(initialspriteline, 0x9F1AC)	// W: initialspriteline when drawing tile compressed sprite
ttdvar(sFullScreenUpdateBlock, 0x9F1B0)	// structure of screendescriptor




#if !WINTTDX
ttdvar(kbdflags,0x9ed3d)			// B: Keyboard flags (not meaningful in WINTTDX): +1=got ext.key prefix, +2=NumLock
#endif					//   (TTDPatch: +4=CapsLock, +8=ScrollLock)
ttdvar(rmbclicked,0x9e584)		// B: Right mouse button clicked; 0=no, 1=yes
ttdvar(lmbstate,0x9c57b)			// B: 0=not pressed, -1=pressed
ttdvar(rmbstate,0x9c57c)			// B: 0=not pressed, -1=pressed
ttdvar(mousecursorscrx,0x771a6)		// W: mouse cursor screen x coordinate
ttdvar(mousecursorscry,0x771a8)		// W: mouse cursor screen y coordinate

ttdvar(mousecursorupdatescrx,0x9F16A)		// W: 
ttdvar(mousecursorupdatescry,0x9F16C)		// W: 
ttdvar(mousecursorupdatescrwidth,0x9F166)		// W:
ttdvar(mousecursorupdatescrheight,0x9F168)		// B!!!:

ttdvar(currentfont,0x77938)		// W: current font base character (0, 224, 448)
ttdvar(charwidthtables,0x9ea39)		// B: 3 tables of 224 chars widths each for three different font sizes

ttdvar(keypressedscan,0x9c577)		// B: scancode of the last pressed key
ttdvar(counter17ms,0x9c579)		// B: counter for 17ms ticks

ttdvar(cargopricefactors,0x4C5A)	// W: table of price factors of all 12 cargo types

ttdvar(cargotypenames,0x76DD8)		// W: table of names of all 12 cargo types
ttdvar(cargounitnames,0x76DF0)		// W:
ttdvar(cargoamount1names,0x76E08)	// W:
ttdvar(cargoamountnnames,0x76E20)	// W:
ttdvar(cargoshortnames,0x76E38)	// W:
ttdvar(cargoicons,0x76E50)		// W:

ttdvar(aicargovehicletable,0x77068)	// 7*12 bytes list of vehicles per cargo for each vehicle class (see struct aicargovehicle)
ttdvar(ailastrailengineaiflags, 0x9eddf)// B: AI flags of last rail loco buy attempt
ttdvar(ailastairank,0x9ede0)		// B: AI rank of last rail loco buy attempt

ttdvar(cargounitweights,0x77155)	// B:
ttdvar(cargodelaypenaltythresholds1,0x77161)	// B:
ttdvar(cargodelaypenaltythresholds2,0x7716D)	// B:

ttdvar(demomode,0x9ede3)			// B: nonzero if demo mode is running
ttdvar(animatedtilelist, 0x4328)		// W[256]: list of tiles being animated
ttdvar(colorschememap, 0x9ed5f)		// B[8*16]: 8 color shades for each of the 16 color schemes

ttdvar(newgameclimate, 0x9f159)		// B: selected climate for new game
ttdvar(currconstrtooltracktype,0x9f15a)	// B: current track type for railway construction
ttdvar(autosavesetting, 0x9ef2C)		// B: autosave setting 0=off, 1=3Months, 2=6Months, 3=12Months

ttdvar(selectedairporttype, 0x9ede2)	// B: currently selected airport type
ttdvar(airporttypeavailmask, 0x7710b)	// B: bit mask of available old airport types


ttdvar(bridgeiconsttd, 0x9f6b7)		// D[11]: Bridge Icons (with recolor flags) (note newbridges has an own bigger array)
ttdvar(bridgenamesttd, 0x9f6e3)		// W[11]: Bridge Names (note newbridges has an own bigger array)
ttdvar(bridgespeedsttd, 0x9f6f9)		// W[11]: Bridge Speeds (note newbridges has an own bigger array)

ttdvar(firstVehInBBlockArray, 0x72F72)	// W[1000h]:
