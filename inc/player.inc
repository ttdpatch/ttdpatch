// starts at offset given in [77914] (normally 52a62)
struc player
	.name: 		resw 1	// 00h:name text ID; 0 for non-existing players
	.nameparts:	resd 1	// 02h:text ref stack argument for name text ID
			resw 1	// 06h:?
			resd 1	// 08h:?
			resd 1	// 0ah:?
	.cash: 		resd 1	// 10h:	cash of player	(use [addexpenses] to modify for overflow protection)
			resb 0x19-$
	.cashfract:	resb 1	// 19h: fraction of cash, for subtracting sub-dollar amounts
			resb 0x26-$
	.thisyearexpenses:resd 12//26h: several types of expenses in this year
			resb 0xc2-$
	.thisquarterincome:resd 1//c2h: income in this quarter
			resb 0xd6-$
	.lastquarterincome:
			resd 1	// d6h:	income in last quarter
			resb 0x2b6-$
	.inaugurated:	resw 1	// 2b6h:year the company was launched (full, not 1920-based)
			resb 0x2bb-$
	.aiaction:	resb 1	// 2bbh:current AI action
			resb 0x3a3-$
	.tracktypes:	resb 1	// 3a3h:number of track types available for building
	.hqlocation: 	resw 1	// 3a4h:location of headquarters
	.shareowners:	resb 4	// 3a6h:owners of the four shares
			resb 0x3b2-$
endstruc_32

// bit numbers for the bits in player2.colschemes
#define COLSCHEME_HAS2CC 0	// is 2nd company colour defined?
#define COLSCHEME_SPECIAL 1	// special colours for...
#define COLSCHEME_STEAM 1	// ...steam engines	
#define COLSCHEME_DIESEL 2	// ...diesel engines
#define COLSCHEME_ELECTRIC 3	// ...electric engines
#define COLSCHEME_MR_MAGLEV 4	// ...monorail/maglev engines
//#define COLSCHEME_MONORAIL 4	// ...monorail engines (not used (yet?))
//#define COLSCHEME_MAGLEV 5	// ...maglev engines (not used (yet?))
#define COLSCHEME_MU 6		// ...DMU/EMU
//#define COLSCHEME_DMU 6		// ...DMU (not used (yet?))
//#define COLSCHEME_EMU 7		// ...EMU (not used (yet?))
#define COLSCHEME_PASS 8	// ...passenger wagons
#define COLSCHEME_FREIGHT 9	// ...freight wagons
#define COLSCHEME_BUS 10	// ...busses/trams
#define COLSCHEME_TRUCK 11	// ...trucks
#define COLSCHEME_SHIP 12	// ...ships
#define COLSCHEME_AIRCRAFT 13	// ...aircraft

#define COLSCHEME_NUM 13	// total number of special colours above

// WARNING: If you use this, you must add your switch to the patchproc
// in procs/player2.asm
// NOTE: Don't rearrange fields here, only add new fields beyond the end,
//	 otherwise old savegames need adjusting after load
struc player2
	.colschemes:	resd 1	// bit mask of COLSCHEME_# flags above
	.col2:		resb 1	// 2nd company colour
	.specialcol:	resb 2*COLSCHEME_NUM	// special colours, 1st and 2nd
	ALIGNB 4		// make struct size a multiple of 4
endstruc_32

