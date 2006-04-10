// GRF stuff

#include <grfdef.inc>

	// data recorded for each entry in newgrf(w).txt
	// this is linked list starting at spriteblockptr and
	// linked via .next
struc spriteblock
	.spritelist:	resd 1	// pointer to sprite list
	.grfid:		resd 1	// GRF ID of this block
	.filenameptr:	resd 1	// Pointer to filename
	.paramptr:	resd 1	// Pointer to sprite parameters
	.nameptr:	resd 1	// Pointer to name from action 8 (or filename if no name given)
	.next:		resd 1	// Pointer to next spriteblock
	.action8:	resd 1	// Pointer to action 8 data
	.miscstr:	resd 1	// Pointer to list of miscellaneous texts
	.errparam:	resd 2	// Parameters for sprite error message, if any
	.soundinfo:	resd 1	// If defined, pointer to array of soundinfo structures
	.cargotransptr:	resd 1	// Pointer to cargo translation struct, if defined
	.numsprites:	resw 1	// number of sprites in this block
	.cursprite:	resw 1	// number of the current sprite (for error messages)
	.errsprite:	resw 1	// number with the first action 0B error message
				// or text ID for error message if signed
	.numsounds:	resw 1	// number of entries in soundinfo array
	.version:	resb 1	// GRF version from action 8
	.numparam:	resb 1	// number of parameters given for this block
	.active:	resb 1	// 0=not active, 1=active in current game,
				// 2=will be not active, 3=will be active,
				// +4=forced active
				// 80=faulty (will be skipped)
				// (2,3: is in list, but not processed yet)
	.newactive:	resb 1	// new active status that should be set via grf status window
	.flags:		resb 1	// Bit mask of flags
				// bit 0: off by default
				// bit 1: off because of resource conflict
				// bit 2: did reserve extra action A sprites
				// bit 3: needs to import sounds from other GRF
endstruc_32

%macro checkfeaturesize 2.nolist
%ifndef PREPROCESSONLY
	%assign %%num (addr($)-%1)/%2
	%if %%num <> NUMFEATURES
		%define checkfeaturesize_bad_var %1
		%define hasnum %%num
		%define needsnum NUMFEATURES
		%error "checkfeaturesize_bad_var has hasnum not needsnum entries!"
	%endif
%endif
%endmacro

%macro grfcalltable 1-2+.nolist	// params: name[,databeforedefinition...]

	[section .datad]
	align 4
		%2 ;
	vard %1
	%1_table:
		dd addr(.gettrains),addr(.getrvs),addr(.getships),addr(.getplanes)
		dd addr(.getstations),addr(.getcanals),addr(.getbridges),addr(.gethouses)
		dd addr(.getgeneric),addr(.getindustiles),addr(.getindustries),addr(.getcargos),addr(.getsounds)
	endvar
%endmacro

struc action3info
	.spriteblock:	resd 1	// pointer to sprite block
	.prev:		resd 1	// previous action 3 info for last vehicle of this definition
	.overrideptr:	resd 1	// pointer to list of override action3infos
	.spritenum:	resw 1	// sprite-num: number of this sprite for crash log
//	.numveh:	resb 1	// num-veh: number of vehicles in this definition, with bit 7 clear
//	.numoverrides:	resb 1	// num-overrides: 0x80 + number of wagon overrides that follow or 0x00

	align 2
	.cargolist:
	.nodefcargoid:	resw 1	// -2: cargoid to use instead of default (if this is defined)
	.nocargocid:	resw 1	// -1: cargoid to use if no vehicle data available
	.cargo:		resw NUMCARGOS	// cargoids to use for each cargo type (not bit!)
	.defcid:	resw 1	// default cargoid
	%ifndef PREPROCESSONLY
		%assign NUMACTION3CARGOS ($-.cargolist)/2
	%endif
endstruc_32

	// cargo translation table
struc cargotrans
	.fromslot:	resb NUMCARGOS	// translation value associated with cargo slot
	.frombit:	resb NUMCARGOS	// and cargo bit
	.supported:	resd 1		// bit mask of supported cargo bits (MUST follow last bit)
	.tableptr:	resd 1		// pointer to translation table
	.numtrans:	resb 1		// number of entries in translation table
endstruc_32

struc namepartlist			// stores the choices for a name part
	.partcount:	resb 1		// how many name parts are in the list
	.bitstart:	resb 1		// the lowest bit that is checked for randomizing this part
	.bitcount:	resb 1		// how many bits are used from the seed
	.maxprob:	resw 1		// the sum of all probablility values
	.next:		resd 1		// pointer to the next part to insert or zero if none
// the following fields are set for root nodes only
	.grfid:		resd 1		// GRFID of the file of this definition
	.setid:		resb 1		// ...and setid
	.active:	resb 1		// nonzero if the definition is active
	.nextstyle:	resd 1		// pointer to root of the next town name style
	.name:		resd 1		// pointer to name of the style
	.nameparts:			// the parts themselves start from this
endstruc_32

struc namepart
	.ptr:		resd 1		// pointer to either a name part (if bit 7 of probablity is clear),
					// or to another namepartlist struc (if bit 7 of probablity is set)
	.probablity:	resb 1		// relative probablity of the part to appear in the bottom 7 bits
	.reserved:	resb 3		// to set the size to 8
endstruc_32

%define NUMOLDSOUNDS 73

struc soundinfo
	.dataptr:	resd 1	// memory ptr to sound data
	.length:	resd 1	// length of data in bytes
	.prepfile:	resd 1	// prepared, parsed sound data
	.filename:	resd 1	// pointer to filename for logging
	.priority:	resb 1	// sample priority
	.ampl:		resb 1	// amplification factor
endstruc_32

// -------------------
// new station structs
// -------------------

// provides a mapping from dataid to grfid/gameid/setid
// the first entry is always empty; a dataid of zero is reserved for plain
// TTD stations
// other entries are empty if .numtiles is zero
struc stationid
	.grfid:		resd 1	// grfid (permanent)
	.numtiles:	resw 1	// how many tiles use this ID (permanent)
	.setid:		resb 1	// setid (permanent)
	.gameid:	resb 1	// gameid (temporary; gets new value after loading a game)
endstruc_32

// provides a mapping from gameid to graphics and setid
struc stsetid
	.act3info:	resd 1	// action 3 info for this gameid
//	.spriteblock:	resd 1	// spriteblock for same -- no longer needed, now in action3info
	.setid:		resb 1	// corresponding setid
endstruc_32

