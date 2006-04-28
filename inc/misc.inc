//
// Miscellaneous, rarely used definitions
//


// expense types for [currentexpensetype]
%assign expenses_construction	4*0
%assign expenses_newvehs	4*1
%assign expenses_trainruncosts	4*2
%assign expenses_rvruncosts	4*3
%assign expenses_aircrruncosts	4*4
%assign expenses_shipruncosts	4*5
%assign expenses_propmaint	4*6
%assign expenses_trainincome	4*7
%assign expenses_rvincome	4*8
%assign expenses_aircrincome	4*9
%assign expenses_shipincome	4*10
%assign expenses_loaninterest	4*11
%assign expenses_other		4*12

// starts at 452ch
struc depot
	.XY: 		resw 1	// 00h:location (landscape index)
	.townptr: 	resd 1	// 02h:city pointer
endstruc

	// gamespeed settings
#if WINTTDX
%define GS_WAITBASE 27
#else
%define GS_WAITBASE 8
#endif

GS_DEFAULTFACTOR equ 3


// subsidy structures, start at 76da4, end at 76dc3
struc subsidy
	.cargo: 	resb 1	// 00h: subsidised cargo type
	.age: 		resb 1	// 01h: age of the subsidy offer in months (0..11: offered, 12..23: awarded)
	.from: 		resb 1	// 02h: industry # (if offered)/station # (if awarded) of source
	.to: 		resb 1	// 03h: ...and the target
endstruc

// signs
struc sign
	.text:		resw 1	// 00h:text ID
	.x:		resw 1	// 02h:X
	.y:		resw 1	// 04h:Y landscape coords
	.z:		resb 1	// 06h:Z
			resb 1	// 07h:?
	.width:		resb 1	// 08h:width zoomed in
	.widthsmall:	resb 1	// 09h:width zoomed out
	.posX:		resw 1	// 0Ah:X
	.posY:		resw 1	// 0Bh:Y pixel coords
endstruc

// vehicles used by AI to transport each cargo type, start at 0x77068
struc aicargovehtable
	.railway:	resw 12	// railway waggons
	.monorail:	resw 12	// monorail waggons
	.maglev:	resw 12	// maglev waggons
	.roadbase:	resw 12	// road vehicle base type
	.roadnum:	resb 12	// number of types from roadbase up
	.shipbase:	resw 12	// ship base type
	.shipnum:	resb 12	// number of types from shipbase up
endstruc

// rising text effect
struc texteffect
	.text:		resw 1	// text ID
	.pos:		resw 4	// X1 X2 Y1 Y2
	.timer:		resw 1	// countdown timer, expires on wraparound
	.params:	resb 8	// parameters for text ID
endstruc

// ai cargo vehicle table
struc aicargovehicle
	.railway:	resw 12	// railway wagons for each cargo
	.monorail:	resw 12	// monorail
	.maglev:	resw 12 // maglev
	.road:		resw 12 // first road vehicle ID for each cargo
	.roadnum:	resb 12 // number of road vehicles	-"-
	.ship:		resw 12	// first ship ID for each cargo
	.shipnum:	resb 12	// number of ships	-"-
endstruc

struc graphdata
	.values			resd 384	// 000h: values to be graphed
	.colors			resb 16		// 600h: color for each series
	.serieshidden		resd 1		// 610h: bit set: series not displayed
	.nseries		resb 1		// 614h
	.maxpoints		resb 1		// 615h
	.startmonth		resb 1		// 616h
	.startyear		resb 1		// 617h
	.hasnegvalues		resb 1		// 618h
	.vgridlines		resb 1		// 619h
	.firstarg		resw 1		// 61Ah
	.argstep		resw 1		// 61Ch
	.X			resw 1		// 61Eh
	.Y			resw 1		// 620h
	.height			resw 1		// 622h
	.vlabelstext		resw 1		// 624h
	.labelcolor		resw 1		// 626h
	.gridline0colorscheme	resw 1		// 628h
	.gridlinescolorscheme	resw 1		// 62Ah
	.maxvalue		resd 1		// 62Ch
	.vdiv			resd 1		// 630h
	.prevpointX		resw 1		// 634h
	.prevpointY		resw 1		// 636h
endstruc

// the maximum road vehicle speed is increased by 1 << maxrvspeedshift
// "large" numbers will slow down the game and make RV movement jerky
%assign maxrvspeedshift 2

%assign MAXDROPDOWNENTRIES	19	// maximum number of entries in a dropdown list


// Structure for managing the heap
// [heapptr] is a pointer to the first in the linked list of these structures
struc heap
	.left:	resd 1	// 00h: how many bytes left in this chunk
	.ptr:	resd 1	// 04h: current end of used piece of this chunk
	.next:	resd 1	// 08h:	pointer to next, zero if last one
endstruc



struc spritedesc
	.sprite:	resd 1	// 00h
	.pixelX1:	resw 1	// 04h
	.pixelY1:	resw 1	// 06h
	.pixelX2:	resw 1	// 08h
	.pixelY2:	resw 1	// 0ah
	.X1:		resw 1	// 0ch
	.Y1:		resw 1	// 0eh
	.Z1:		resb 1	// 10h
	.Z2:		resb 1	// 11h
	.X2:		resw 1	// 12h
	.Y2:		resw 1	// 14h
	.flags:		resw 1	// 16h
	.linked:	resd 1	// 18h
endstruc

struc scrnblockdesc
	.buffer:	resd 1	// 00h
	.buffersel:	resw 1	// 04h
	.x:		resw 1	// 06h
	.y:		resw 1	// 08h
	.width:		resw 1	// 0ah
	.height:	resw 1	// 0ch
	.nextlineofs:	resw 1	// 0eh
	.zoom:		resw 1	// 10h
endstruc

%macro dopatchaction 1-2 call
	mov esi,%1_actionnum
	%2 dword [actionhandler]
%endmacro



#if WINTTDX
// Windows version
#define KEY_Ctrl	0x11
#else
// DOS version
#define KEY_LShift	0x2a
#define KEY_RShift	0x36
#define KEY_LCtrl	0x1d
#define	KEY_RCtrl	0x9d
#define KEY_LAlt	0x38
#define KEY_RAlt	0xb8
#define KEY_CapsLock	0x3a
#define KEY_NumLock	0x45
#define KEY_ScrollLock	0x46
#endif
