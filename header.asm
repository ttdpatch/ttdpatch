//
// header.asm - protected code header bytes
// 

#include <defs.inc>
#include <var.inc>
#include <vehtype.inc>
#include <textdef.inc>
#include <newvehdata.inc>
#include <flags.inc>
#include <veh.inc>

extern useknownaddress


global protectedstart
protectedstart:
	var protectedbase
	var magicbytes, dd MAGIC


	// These are the parameters passed to TTDPatch

var startflagdata
	// First the flags which patches are switched on/off
	var patchflags, times nflags dd 0

	// Note, the last dword above only contains "special" flags that are
	// never set by command line or config switches, but are instead set
	// internally.

        var flagdatasize, dd 0

	// the values that go with some of the patches are in flagdata.h
	// here we define the one-line macros needed

#define defbyte(name)		var name, db 0
#define defword(name)		var name, dw 0
#define deflong(name)		var name, dd 0
#define defbytes(name, count)	var name, times count+0 db 0
#define defwords(name, count)	var name, times count+0 dw 0
#define deflongs(name, count)	var name, times count+0 dd 0

var startflagvars

#include "flagdata.h"

var endflagdata

global flag_data_size,long_flags_end,word_flags_end,ubyte_flags_end
flag_data_size equ endflagdata-startflagvars
long_flags_end equ flags_long_end - startflagvars
word_flags_end equ flags_word_end - startflagvars
ubyte_flags_end equ flags_ubyte_end - startflagvars

	// then we undefine them so that they may be re-used

#undef defbyte
#undef defword
#undef deflong
#undef defbytes
#undef defwords
#undef deflongs


// The remaining variables go in .data*

// New actions (player operations that change the state of the simulation engine)
// In the two-player mode, if a human player induces an action, the other machine
// is notified and TTD invokes the same code there with [curplayer]=[human2]
// see also var actionhandler below
//
// To call an action, use the dopatchaction macro, with
// in:	ax,cx=x,y coordinates of action (be sure to them set to zero if none)
//	bl=construction code
//		bit 0: set = do the action, clear = check if the action is possible and return cost
//		bit 1: set = don't remove landscape structures in the process
//		bit 2: set = don't check if the current company has enough cash
//			     vehicle purchase actions: don't try to buy the vehicle,
//			     just return the cost
//		bit 3: set = don't build on water
//		bit 4: set = prevent builing of track junctions or crossings
//		bit 5: set = remove existing town houses and roads while building
//		bit 6: set = can remove houses even if the Local Authority rating is too low
//	rest of ebx, plus edx and edi can be used to pass parameters to the action
// out:	ebx=cost, or 0x80000000 if action failed
//
// WARNING: Do not pass vehicle pointers to these actions!!! If morevehicles is on, the new vehicle
// array may not be at the same address as on the remote machine, so the pointer may not be valid there.
// Instead, subtract [veharrayptr] from the pointer before passing it, and add [veharrayptr] back in
// the action code. This way, the pointer will be correct no matter where the veh. array is on the other
// machine. In general, pass pointers only if you're 100% sure that the address is valid on the other
// machine as well.

%macro startpatchactions 0
	%assign actionnum 0
	align 4
	vard ttdpatchactions
%endmacro

%macro patchaction 1.nolist
	global %1_actionnum
	extern %1
	dd %1
	%1_actionnum equ actionnum<<16 | 0x58
	%assign actionnum actionnum+1
%endmacro

	align 4
startpatchactions			// this is a macro, not a label...
	patchaction shareorders
	patchaction resetorders
	patchaction checkrandomseed
	patchaction setplayer
	patchaction actionmakewater
	patchaction actiongrfstat
	patchaction actionnewstations
	patchaction ai_buildrailvehicle
	patchaction ai_buildroadvehicle
	patchaction saverestorevehdata
	patchaction buildsignal
	patchaction cleararea
	patchaction builddiagtrackspan
	patchaction fundprospecting_newindu
	patchaction AlterSignalsByGUI
	patchaction CloneTrainBuild
	patchaction ConvertEngineType
	patchaction TwoCompanyColourChange
	patchaction AdjacentStationBuildNewStation
	patchaction MPRoutingRestrictionChange
	patchaction SetTTDpatchVar
	patchaction MenuStartNewGame
	patchaction actionrailvehmenu
	patchaction BuildObject

uvard newvehdata, newvehdatastruc_size/4
uvard persgrfdata, persgrfdatastruc_size/4

#include "patchflags.ah"

global patchflagsfixedmaplength,patchflagsunimaglevmode_d8,patchflagsunimaglevmode_a7
patchflagsfixedmaplength equ addr($)-patchflagsfixedmap
patchflagsunimaglevmode equ 50				// Important: (patchflagsunimaglevmode & 7) <> 7

patchflagsunimaglevmode_d8 equ patchflagsunimaglevmode/8
patchflagsunimaglevmode_a7 equ patchflagsunimaglevmode & 7
varb patchflagsunimaglevmode_a7_s3_n, ~(3 << (patchflagsunimaglevmode & 7))


#define __no_flag_data__ 1
#define __no_bit_vars__ 1
#define FROM_HEADER_ASM 1
	#define patchflags _patchflags
#include "globals.ah"
#undef patchflags

ptrvarall ttdvar_base

