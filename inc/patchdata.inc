
%assign L3MAGIC 0x70445454

// special TTDPatch data, saved at end of landscape3 array (offsets from landscape3)
struc ttdpatchdata
	.vehfactor:	resb 1	// 00h: vehicle array factor (0 if factor=1)
			resb 1	// 01h: unused
	.reserved:	resb 0xff00*2-$	// 02..0xff00*2: reserved (used by TTD)
				//
	.start:			// Start of the data at the end of landscape3.
				// Since landscape3 is located at 0x24cba it's best to keep
				// words and dwords aligned with landscape3+2.
				//
	.lastremoveddepotnumber:
			resb 1	// 0xff00*2+00h: Number of last removed depot;
				//	     Note: must be contiguous with lastremoveddepot{type,coord}
	.lastremoveddepottype:
			resb 1	// 0xff00*2+01h: Last removed depot type (10h/11h/12h=rail/road/ship; 00h=n/a)
	.lastremoveddepotcoord:
			resw 1	// 0xff00*2+02h: coordinates of last removed depot
	.lastrailclass:	resb 1	// 0xff00*2+04h: last rail class selected from rail construction menu (used as new default)
	.realcurrency:	resb 1  // 0xff00*2+05h: index of really used currency plus one for morecurrs
	.chtused:	resd 2	// 0xff00*2+06h: bits for Cht: Used
	.daysadd:	resd 1  // 0xff00*2+0eh: added to all dates when eternalgame is active, records days above 2070
	.yearsadd:	resw 1  // 0xff00*2+12h: year offset above 2070 (stops at 63465)
	.orgpl1:	resb 1	// 0xff00*2+14h: original player 1 company while managing
	.orgpl2:	resb 1	// 0xff00*2+15h: original player 2 company while managing (must be contiguous with .orgpl1)
	.lastsort:	resb 1	// 0xff00*2+16h: last used sort order
	.townnamegrfid:	resd 1	// 0xff00*2+17h: GRFID of the currently used new townnames
	.townnamesetid:	resb 1	// 0xff00*2+1bh: setid of the currently used new townnames
	.flags:		resb 1	// 0xff00*2+1ch: 1: veh.modflags+1 is valid
				//		 2: station cargo slots use the new format (for new cargo support)
	.remoteplayers:	resb 1	// 0xff00*2+1dh: bit mask of remote human players
	.orighumanplayers:
			resb 1	// 0xff00*2+1eh: bit mask of original human companies
	.disableddefindustries:
			resd 2	// 0xff00*2+1fh: bit mask of default industries disabled via prop 8 value FF
			resb 0x10000*2-0x100-$ // unused
	// Reserved for other tools
	.ttdxeditor:	resd 1	// 0xff00*2+100h: reserved for TTDX Editor
			resb 0x10000*2-6-$ // unused
	// Variables set by TTDPatch on save
	.magic:		resd 1	// 0xff00*2+1fah: magic value L3MAGIC (see above), indicates new format
	.extrachunks:	resw 1	// 0xff00*2+1feh: number of extra chunks at the end of a savegame
endstruc

// old format of special TTDPatch data, saved at beginning of landscape3 array
// for load compatibility only!
struc ttdpatchdataold
	.vehfactor:	resb 1	// 00h: veh.factor (0 if factor=1) (same position as in new format)
			resb 1	// 01h: unused
	.extrachunks:	resw 1	// 02h: number of extra chunks at the end of a savegame
	.chtused:	resd 1	// 04h: bits for Cht: Used
	.orgpl1:	resb 1	// 08h: original player 1 company while managing
	.orgpl2:	resb 1	// 09h: original player 2 company while managing
	.yearsadd:	resw 1  // 0ah: year offset above 2070 (stops at 63465)
	.daysadd:	resd 1  // 0ch: added to all dates when eternalgame is active, records days above 2070
	.realcurrency:	resb 1  // 10h: index of really used currency plus one for morecurrs
			resb 0x00ff*2+1-$ // unused
	.reserved:	resb 0xff00*2-$	// 0x0100*2..0xff00*2: reserved
	// The locations below are the same in old and new formats
	.lastremoveddepotnumber:
			resb 1	// 0xff00*2: Number of last removed depot
	.lastremoveddepottype:
			resb 1	// 0xff00*2+1: Last removed depot type (10h/11h/12h=rail/road/ship; 00h=n/a)
	.lastremoveddepotcoord:
			resw 1	// 0xff00*2+2: coordinates of last removed depot
	.lastrailclass:	resb 1	// 0xff00*2+4: last rail class selected from rail construction menu
				//	       (used as new default)
			resb 0x10000*2-$ // unused
endstruc

