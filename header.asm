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

extern actiongrfstat,actionmakewater,actionnewstations,ai_buildrailvehicle
extern ai_buildroadvehicle,builddiagtrackspan,buildsignal,checkrandomseed
extern cleararea,fundprospecting,fundprospecting_newindu,resetorders
extern saverestorevehdata,setplayer,useknownaddress
extern shareorders


section .text

protectedfunc:

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

	// compatibility labels

global curvetype,mountaintype,signal1waitdays,signal2waitdays
	curvetype	equ mctype
	mountaintype	equ mctype+1
	signal1waitdays	equ signalwaittimes
	signal2waitdays	equ signalwaittimes+1

	align 4
var auxdatapointers
	var versiondataptr, dd 0	// where the loader stored the version data
	var customtextptr, dd 0		// and the custom text data
	var systemtextptr, dd 0		// and the system text data
	var relocofsptr, dd 0		// and the relocation offsets

%macro defbitvar 2.nolist	// argument: patchflag,variablename
	%push bitvar
	%xdefine %$curbitvar %2
%endmacro
%macro defbit 2.nolist		// argument: bitname,bitnumber
	global %1_VAR,%1_NUM,%1
	%1_VAR equ %$curbitvar
	%xdefine %1_NUM %2
	%assign %1 1<<%2
%endmacro
%macro enddefbits 0.nolist
	%pop
%endmacro
#include "bitnames.ah"
%undef defbitvar
%undef defbit
%undef enddefbits

// The remaining variables go in .data
section .data

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
	var ttdpatchactions
%endmacro

%macro patchaction 1.nolist
	global %1_actionnum
	dd addr(%1)
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
	patchaction fundprospecting
	patchaction ai_buildrailvehicle
	patchaction ai_buildroadvehicle
	patchaction saverestorevehdata
	patchaction buildsignal
	patchaction cleararea
	patchaction builddiagtrackspan
	patchaction fundprospecting_newindu


uvard newvehdata, newvehdatastruc_size/4

var newrefitvars
	dd newvehdata+newvehdatastruc.refit2,newvehdata+newvehdatastruc.refit1
	dd newvehdata+newvehdatastruc.refit1,newvehdata+newvehdatastruc.refit2

	// Multi-line variable definitions (those shouldn't go in global.ah)

var newbridgelenmult
	db 0,1,2,3,5,7,10,13,16,20,24,28,32,36,40,45,50,55,60,65	// 0..19
	db 70,78,86,94,102,109,115,122,128,134,139,144,149,154,159	// 20..34
	db 163,167,171,175,179,182,186,189,192,195,197,200,203,205	// 35..48
	db 207,209,212,214,215,217,219,221,222,224,225,226,228,229	// 49..62
	db 230,231,232,233,234,235,236,237,238,239,240,241,242,243	// 63..76
	db 244,245,246,246,247,247,248,248,249,249,250,250,251,251	// 77..90
	db 251,252,252,252,253,253,253,253,254,254,254,254,254,254	// 91..104
	times 255-100 db 255

// Mapping of common.h bits to patchflagsfixed
// Don't change the position of any entry, only replace the 'noflag' ones
// or add new ones at the end of the list
var patchflagsfixedmap
	times 12 db noflag
	db keepsmallairports	// 12
	db noflag
	db morestationtracks	// 14
	db longerbridges	// 15
	db improvedloadtimes	// 16
	db noflag
	db presignals		// 18
	db extpresignals	// 19
	times 2 db noflag
	db persistentengines	// 22
	times 4 db noflag
	db multihead		// 27
	db noflag
	db lowmemory		// 29
	db generalfixes		// 30
	times 8 db noflag
	db moreairports		// 39
	db mammothtrains	// 40
	db allowtrainrefit	// 41
	db noflag
	db subsidiaries		// 43
	db gradualloading	// 44
	times 5 db noflag
	db unifiedmaglev	// 50 (unimaglevmode bit 0)
	db unifiedmaglev	// 51 (unimaglevmode bit 1)
	db newbridgespeeds	// 52
	db noflag
	db eternalgame		// 54
	db newtrains		// 55
	db newrvs		// 56
	db newships		// 57
	db newplanes		// 58
	db signalsontrafficside	// 59
	db electrifiedrail	// 60
	times 4 db noflag
	db loadallgraphics	// 65
	db noflag
	db semaphoresignals	// 67
	times 7 db noflag
	db enhancegui		// 75
	db newagerating		// 76
	db buildonslopes	// 77
	db noflag
	db planespeed		// 79
	db moreindustriesperclimate // 80
	db moretoylandfeatures	// 81
	db newstations		// 82
	db tracktypecostdiff	// 83
	db manualconvert	// 84
	db buildoncoasts	// 85
	db canals		// 86
	db newstartyear		// 87
	db freighttrains	// 88
	db newhouses		// 89
	db newbridges		// 90
	db newtownnames		// 91
	db moreanimation	// 92
	db wagonspeedlimits	// 93
	db newshistory		// 94
	db custombridgeheads	// 95
	db newcargodistribution	// 96
	db windowsnap		// 97
	db townbuildnoroads	// 98
	db pathbasedsignalling	// 99
	db aichoosechances	// 100
	db resolutionwidth	// 101
	db resolutionheight	// 102
	db newindustries	// 103
	db fifoloading		// 104
	db townroadbranchprob	// 105
	db tempsnowline		// 106
	db newcargos		// 107
	db enhancemultiplayer	// 108
	db onewayroads		// 109
	db irrstations		// 110
	db morestats		// 111
	db newsounds		// 112
	db autoreplace		// 113
	db autoslope		// 114

	times 127-(addr($)-patchflagsfixedmap) db noflag
	db anyflagset		// 127

global patchflagsfixedmaplength,patchflagsunimaglevmode_d8,patchflagsunimaglevmode_a7
patchflagsfixedmaplength equ addr($)-patchflagsfixedmap
patchflagsunimaglevmode equ 50				// Important: (patchflagsunimaglevmode & 7) <> 7

patchflagsunimaglevmode_d8 equ patchflagsunimaglevmode/8
patchflagsunimaglevmode_a7 equ patchflagsunimaglevmode & 7
var patchflagsunimaglevmode_a7_s3_n, db ~(3 << (patchflagsunimaglevmode & 7))


// List of vehicles the should be made eternal
// first+second list if persistenengines is on
// second list otherwise (makes train wagons eternal)
var eternalvehicleslist
	// start with ranges (number, increment, start ID)
	db  3,1,24	// SH.40, TIM and Asiastar
	db  3,1,54	// X2001, Z1, Z99
	db  3,1,86	// Pegasus, Chimera, Rocketeer
	db 29,3,119	// 29 Road vehicles, one per cargo type
	db  2,2,205	// Oil tanker and Ferry
	db  4,2,208	// Hovercraft, Toyland Ferry, Cargo ships (reg.&toyland)
	db  2,1,246	// Dinger 200,1000
	db  2,1,250	// Toyland planes
	db  2,1,254	// Regular and Toyland helicopters
var eternalvehicleslistwagons
	db 27,1,27	// Rail wagons
	db 27,1,57	// Monorail wagons
	db 27,1,89	// Maglev wagons
	// end of list
	db 0

#define __no_flag_data__ 1
#define __no_bit_vars__ 1
#define FROM_HEADER_ASM 1
	#define patchflags _patchflags
#include "globals.ah"
#undef patchflags

ptrvarall ttdvar_base

	// at the end of everything else we load the version info,
	// the custom texts and relocation info

	// then follows the vehicle array (unless lowmemory&&vehfactor==1)
	// and the heap

section .aux nobits align=4
global currentversion
currentversion:
section .text

#if 0

%macro getsectsize 1.nolist
	section %1
	resb ($$-$) & 3		// align to DWORD
	section%1.end:
	section%1.size equ section%1.end-section%1.start
%endmacro


getsectsize .bss
getsectsize .bss2
getsectsize .bss1
getsectsize .ptr
getsectsize .sbss
getsectsize .sbss2
getsectsize .sbss1
getsectsize .aux

// calculate total memory size of initialized and uninitialized data
// we can't take differences across sections (like setion.aux.start-section.code.start)
// so we need to add the sizes of all bss sections manually
bss_size equ section.bss.size+section.bss2.size+section.bss1.size+section.ptr.size
sbss_size equ section.sbss.size+section.sbss2.size+section.sbss1.size

protectedcodeend equ protectedcoderealend+bss_size+sbss_size+section.aux.size
#endif
