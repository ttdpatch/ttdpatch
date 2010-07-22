#ifndef _LANGUAGE_H
#define _LANGUAGE_H
//
// This file is part of TTDPatch
// Copyright (C) 1999 by Josef Drexler
//
// language.h: defines variables for multi-lingual support
//

//
// To add a string, insert a new identifier
// somewhere in enum langtextids before LANG_LASTSTRING.
// Don't assign explicit numbers to the enumeration constants!
//

#include <stdlib.h>

#include "types.h"

#ifndef C
#	define C	// for common.h
#endif

#include "common.h"

#if defined(IS_MAKELANG_CPP)
#	define ISEXTERN
#elif defined(IS_TTDSTART_CPP)
#	define ISEXTERN
#else
#	define ISEXTERN extern
#endif

// Magic code for the language data. In the actual file it'll be XOR'd
// with 32 (i.e., in lower case) so that the in-memory location isn't
// found while searching the exe file for the language data
#define LANGCODELEN 8		// number of bytes in magic code
#define LANGINFOSIZE 20		// size of each entry in the language info
#define LANGINGAMEOFS (LANGCODELEN+4)		// offset to in-game strings
#define LANGMAXSIZEOFS (LANGINGAMEOFS+2*4)	// offset to max.buffer sizes
#define LANGINFOOFFSET (LANGMAXSIZEOFS+2*4)	// offset of language info

#define LANG_MAX_COUNTRY 32	// maximum number of countries per language

// Structure of language.dat
// 	Offset	Length	Content
// 	0	8(a)	langcode[]	(a) LANGCODELEN really
//	8(a)	4	TTDPatch Version this language data is for
//	12	4	Offset to in-game string data
// 	16	4	Number of languages=#
//	20	4	Largest uncompressed buffer
//	24	4	Largest compressed buffer
//	28(b)	#*20(c)	Language info	(b) Better use LANGINFOOFFSET
//					(c) LANGINFOSIZE really
//
// Language info (starting at LANGINFOOFFSET)
//	RelOfs	Length	Content
//	0	4	Relative offset to language data, counted from
//			offset of langcode[]
//	4	4	Relative offset to country codes
//	8	4	Compressed size of language data (w/o country codes)
//	12	4	Uncompressed size of language data (w/o country codes)
//	16	4	Code page
//
// Language country code info (uncompressed):
//	RelOfs	Length	Content
//	0	4	Number of country codes for which to use this language
//	4	4*#	Country codes
//
// Language data: each string has the following format
//	RelOfs	Length	Content
//	0	1	Info*
//      ?	1	Extra length**
//	?	2	New code if not consecutive
//	?	*	String data without trailing zero
//
//	Info:	This is bit-encoded to save some space
//		Bits 0-5: lower 6 bits of the string length
//		Bit 6:	  if set, the code is not consecutive, and a new
//			  code is given (if present, after the extra length)
//		Bit 7:	  the length doesn't fit in 6 bits, the next eight
//			  bits are in the byte immediately following this one
//	Extra length:	  If Info has bit 7 set, this byte contains bits
//			  6 to 13 of the string length
//	New code:	  If the codes are not consecutive, i.e. if this code
//			  is not one higher than the previous one, then this
//			  contains the new code.
//
//	Note that the code sequence is assumed to start with LANGCODE_NAME(0)
//	containing the language name.  If this is the case, the first string
//	will not have bit 6 set.
//
// Arrays are prefixed with a two-byte number telling the number of entries
//
//
// In-Game Strings
//	RelOfs	Length	Content
//	0	4	Number of different languages
//	4	#*4	Offset for that language relative to language.dat
//
// In-Game Language Data
//	RelOfs	Length	Content
//	0	4	Number of .exe file sizes this language is for
//	4	4	Size of that language uncompressed
//	8	4	Size of that language compressed
//	12	#*4	The list of .exe file sizes
//	?	?	The compressed data
//


// Text language string numbers.  Do not use /* */ comments withing this enum.
// If you change the name of this enum type, you'll need to change langerr.pl too.
enum langtextids {

//-------------------------------------------
//  PROGRAM BLURBS
//-------------------------------------------

	LANG_STARTING,			// First line of output is something like "TTDPatch V1.5.1 starting.\n"
					// The program name and version are autogenerated, only put the " starting\n"
					// here
//-------------------------------------------
//  VERSION CHECKING
//-------------------------------------------

	LANG_SIZE,			// In the version identifier, this is for the file size

	LANG_KNOWNVERSION,		// Shown if the version is recognized


	LANG_WRONGVERSION,		// Warning if the version isn't recognized.  Be sure *not* to use tabs
					// in the text.  All but the last lines should end in *\n" \*

	LANG_YESKEYS,			// Keys which continue loading after the above warning. *MUST* be lower case.

	LANG_ABORTLOAD,			// Answering anything but the above keys gives this message.

	LANG_CONTINUELOAD,		// otherwise continue loading

	LANG_WARNVERSION,		// Warning if '-y' was used and the version is unknown

// -------------------------------------------
//    CREATING AND PATCHING TTDLOAD
// -------------------------------------------

	LANG_OVLNOTFOUND,		// TTDLOAD.OVL doesn't exist

	LANG_NOFILESFOUND,		// neither do tycoon.exe or ttdx.exe.  %s is TTDX.EXE

	LANG_WINDEFLANGEXE,		// default Windows language executable (american/english/french/german/spanish).exe

	LANG_SHOWCOPYING,		// Shown when copying tycoon.exe or ttdx.exe (first %s) to ttdload.ovl (2nd %s)

	LANG_COPYERROR_RUN,		// Error if running the copy command fails.  %s is the command.

	LANG_COPYERROR_NOEXIST,		// Error if command returned successfully, but nothing was copied.
					// %s=TTDLOAD.OVL

	LANG_INVALIDEXE,		// Invalid .EXE format

	LANG_VERSIONUNCONFIRMED,	// Version could not be determined

	LANG_PROGANDVER,		// Shows program name (1st %s) and version (2nd %s)

	LANG_TOOMANYNUMBERS,		// More than three numbers in the version string (not #.#.#)

	LANG_WRONGPROGRAM,		// .EXE is not TTD

	LANG_PARSEDVERSION,		// Displays the parsed version number

	LANG_ISDOSEXTEXE,		// The exe has been determined to be the DOS extended executable

	LANG_ISWINDOWSEXE,		// The exe has been determined to be the Windows executable

	LANG_ISUNKNOWNEXE,		// The exe is neither DOS extended nor Windows?

	LANG_NOTSUPPORTED,		// The exe is the wrong type i.e. DOS/Windows

	LANG_INVALIDSEGMENTLEN,		// If the original .exe segment length (%lx) is too large or too small

	LANG_INCREASECODELENGTH,	// When increasing the segment length

	LANG_WRITEERROR,		// Can't write to TTDLOAD.OVL

	LANG_INSTALLLOADER,		// Installing the code loader

	LANG_TTDLOADINVALID,		// TTDLOAD.OVL (%s) is invalid, needs to be deleted.

	LANG_TTDLOADOK,			// TTDLOAD.OVL was verified to be correct

//-----------------------------------------------
//   COMMAND LINE HELP (-h)
//-----------------------------------------------

	LANG_COMMANDLINEHELP,		// Introduction, prefixed with "TTDPATCH V<version> - "

	LANG_FULLSWITCHES,		// Text describing the switches with values.  The lines have to be shorter
                                        // than 79 chars, excluding the "\n".  Start new lines if necessary.

	LANG_HELPTRAILER,		// Referral to the docs, prefixed by "Copyright (C) 1999 by Josef Drexler.  "

//-----------------------------------------------
//  COMMAND LINE AND CONFIG FILE PARSING
//-----------------------------------------------


	LANG_UNKNOWNSTATE,		// if an on/off switch has a value other than the above (%s = wrong value)

	LANG_UNKNOWNSWITCH,		// switch is unknown.  First %c is '-' or '/' etc, 2nd is the switch char

	LANG_UNKNOWNSWITCHBIT,		// switch bit name is unknown.  First %s is bit name, 2nd is switch name

	LANG_UNKNOWNCFGLINE,		// cfg command %s is unknown

	LANG_OUTOFRANGE,			// switch %s value out of range

	LANG_CFGFILENOTFOUND,		// A cfg file (%s) could not be found and is ignored.

	LANG_CFGFILENOTWRITABLE,	// Couldn't write the config file

	LANG_CFGLINETOOLONG,		// A non-comment line is longer than 32 chars, rest ignored.

	LANG_SWITCHOBSOLETE,		// An obsolete switch is used

//----------------------------------------------------
//   SWITCH DISPLAY ('-v')
//----------------------------------------------------

	LANG_SWWAITFORKEY,		// Wait for a key before displaying the table

	LANG_SHOWSWITCHINTRO,		// Introduction

	LANG_SWTABLEVERCHAR,		// Char to be put between the two columns of switches.
					// Shouldn't be changed unless your codepage is weird.

	LANG_SWONEWAY,			// Specify the new train wait times on red signals
	LANG_SWTWOWAY,

	LANG_TIMEDAYS,			// Train wait time is either in days or infinite
	LANG_INFINITETIME,

	LANG_SCROLLKEYS,		// Keyboard reference displayed in switch table
	LANG_SCROLLABORTKEY,

	LANG_SWSHOWLOAD,		// Shows the load options for ttdload.
					// %s is the given parameters to be passed to ttdload

	LANG_SWABORTLOAD,	

//---------------------------------------
//  STARTUP AND REPORTING
//---------------------------------------


	LANG_INTERNALERROR,		// Internal error in TTDPatch

	LANG_REGISTRYERROR,		// Error fixing HDPath registry entry
	LANG_TRYINGNOREGIST,		// Trying no-registry file
	LANG_NOREGISTFAILED,		// no-registry file failed

	LANG_NOTENOUGHMEMTTD,		// DOS reports no memory available

	LANG_NOTENOUGHMEM,		// memory allocation failed

	LANG_SWAPPING,			// Shown when swapping TTDPatch out

	LANG_RUNTTDLOAD,		// Just before running ttdload, show this.  1st %s is ttdload.ovl, 2nd is the options

	LANG_RUNERROR,			// Error executing ttdload.  1st %s is ttdload.ovl, 2nd %s is the error message from the OS

	LANG_CRPROCESSFAIL,		// Failed to create the new process for ttdloadw.ovl

	LANG_IPCEXISTS,			// Another instance of TTDPatch is already running

	LANG_STRINGCONVFAIL,		// Failed to convert language strings to Unicode

	LANG_RUNRESULT,			// Show the result after after running, %s is one of these strings
	LANG_RUNRESULTOK,
	LANG_RUNRESULTERROR,

	LANG_PRESSANYKEY,		// Press any key to continue

	LANG_PRESSESCTOEXIT,		// Press Esc to exit, any other key to continue

	LANG_DELETEOVL,			// Give suggestion to delete the OVL file

	LANG_LOADCUSTOMTEXTS,		// Installing custom in-game texts
	LANG_CUSTOMTXTINVALID,

//---------------------------------------
//  MESSAGES DISPLAYED BY TTDLOAD
//---------------------------------------

// Messages in this category will have "TTDPatch: " prefixed
// and "\r\n" suffixed when displayed by the DOS version.

	LANG_PMOUTOFMEMORY,		// Out of memory (in protected mode)

	LANG_PMIPCERROR,		// Interprocess communication failed (WinTTDX only)

//---------------------------------------------------
//   CONFIG FILE COMMENTS (for '-W')
//---------------------------------------------------

// This is the intro at the start of the config file.  No constraints on line lengths.
	CFG_INTRO,

// Line before previously unset switches
	CFG_NEWSWITCHINTRO,

// Line before previously unset switches
	CFG_NEWBITINTRO,

// No command line option available
	CFG_NOCMDLINE,

// Definitions of the cfg file comments.
// All can have a place holder %s to stand for the actual setting name,
// and all but CFG_CDPATH can have another %s *after* the %s for the command
// line switch.
// They will have the "comment" char and a space prefixed.
//
	CFG_SHIPS,
	CFG_CURVES,
	CFG_SPREAD,
	CFG_TRAINREFIT,
	CFG_SERVINT,	
	CFG_NOINFLATION,	
	CFG_LARGESTATIONS,
	CFG_MOUNTAINS,	
	CFG_NONSTOP,	
	CFG_PLANES,	
	CFG_LOADTIME,
	CFG_ROADVEHS,	
	CFG_SIGNCHEATS,
	CFG_TRAINS,	
	CFG_VERBOSE,	
	CFG_PRESIGNALS,	
	CFG_MOREVEHICLES,
	CFG_MAMMOTHTRAINS,	
	CFG_FULLLOADANY,	
	CFG_SELECTGOODS,	
	CFG_DEBTMAX,	
	CFG_OFFICEFOOD,	
	CFG_ENGINESPERSIST,	
	CFG_CDPATH,			// Note- CFG_CDPATH has no command line switch, so don't give the second %s!
	CFG_KEEPSMALLAP,	
	CFG_LONGBRIDGES,	
	CFG_DYNAMITE,	
	CFG_MULTIHEAD,
	CFG_RVQUEUEING,	
	CFG_LOWMEMORY,	
	CFG_GENERALFIXES,	
	CFG_MOREAIRPORTS,	
	CFG_BRIBE,
	CFG_PLANECRCTRL,	
	CFG_SHOWSPEED,	
	CFG_AUTORENEW,	
	CFG_CHEATSCOST,	
	CFG_EXTPRESIGNALS,
	CFG_FORCEREBUILDOVL,	
	CFG_DISKMENU,	
	CFG_WIN2K,	
	CFG_FEEDERSERVICE,	
	CFG_GOTODEPOT,
	CFG_NEWSHIPS,	
	CFG_SUBSIDIARIES,
	CFG_GRADUALLOADING,	
	CFG_MOVEERRORPOPUP,	
	CFG_SIGNAL1WAITTIME,
	CFG_SIGNAL2WAITTIME,
	CFG_DISASTERS,
	CFG_FORCEAUTORENEW,
	CFG_MORENEWS,
	CFG_UNIFIEDMAGLEV,
	CFG_BRIDGESPEEDS,
	CFG_ETERNALGAME,
	CFG_SHOWFULLDATE,
	CFG_NEWTRAINS,
	CFG_NEWRVS,
	CFG_NEWPLANES,
	CFG_SIGNALSONTRAFFICSIDE,
	CFG_ELECTRIFIEDRAIL,
	CFG_STARTYEAR,
	CFG_ERRORPOPUPTIME,
	CFG_LARGERTOWNS,
	CFG_TOWNGROWTHLIMIT,
	CFG_MISCMODS,
	CFG_LOADALLGRAPHICS,
	CFG_SAVEOPTDATA,
	CFG_MOREBUILDOPTIONS,
	CFG_SEMAPHORES,
	CFG_MOREHOTKEYS,
	CFG_MANYTREES,
	CFG_MORECURRENCIES,
	CFG_ENHANCEGUI,
	CFG_MANCONVERT,
	CFG_NEWAGERATING,
	CFG_TOWNGROWTHRATEMODE,
	CFG_TOWNGROWTHRATEMIN,
	CFG_TOWNGROWTHRATEMAX,
	CFG_TGRACTSTATIONEXIST,
	CFG_TGRACTSTATIONS,
	CFG_TGRACTSTATIONSWEIGHT,
	CFG_TGRPASSOUTWEIGHT,
	CFG_TGRMAILOUTWEIGHT,
	CFG_TGRPASSINMAX,
	CFG_TGRPASSINWEIGHT,
	CFG_TGRMAILINOPTIM,
	CFG_TGRMAILINWEIGHT,
	CFG_TGRGOODSINOPTIM,
	CFG_TGRGOODSINWEIGHT,
	CFG_TGRFOODINMIN,
	CFG_TGRFOODINOPTIM,
	CFG_TGRFOODINWEIGHT,
	CFG_TGRWATERINMIN,
	CFG_TGRWATERINOPTIM,
	CFG_TGRWATERINWEIGHT,
	CFG_TGRSWEETSINOPTIM,
	CFG_TGRSWEETSINWEIGHT,
	CFG_TGRFIZZYDRINKSINOPTIM,
	CFG_TGRFIZZYDRINKSINWEIGHT,
	CFG_TGRTOWNSIZEBASE,
	CFG_TGRTOWNSIZEFACTOR,
	CFG_TOWNMINPOPULATIONSNOW,
	CFG_TOWNMINPOPULATIONDESERT,
	CFG_MORETOWNSTATS,
	CFG_BUILDONSLOPES,
	CFG_EXPERIMENTALFEATURES,
	CFG_TRACKTYPECOSTDIFF,
	CFG_PLANESPEED,
	CFG_BUILDONCOASTS,
	CFG_FASTWAGONSELL,
	CFG_NEWRVCRASH,
	CFG_STABLEINDUSTRY,
	CFG_NEWPERF,
	CFG_SORTVEHLIST,
	CFG_NEWSPAPERCOLOUR,
	CFG_SHAREDORDERS,
	CFG_SHOWPROFITINLIST,
	CFG_MORESTEAM,
	CFG_ABANDONEDROADS,
	CFG_NEWSTATIONS,
	CFG_BUILDWHILEPAUSED,
	CFG_TRAINLOSTTIME,
	CFG_RVLOSTTIME,
	CFG_SHIPLOSTTIME,
	CFG_AIRCRAFTLOSTTIME,
	CFG_MAPREFRESH,
	CFG_NETWORKTIMEOUT,
	CFG_TOYLANDFEATURES,
	CFG_STRETCHWINDOW,
	CFG_CANALS,
	CFG_FREIGHTTRAINS,
	CFG_GAMESPEED,
	CFG_HIGHERBRIDGES,
	CFG_NEWGRFCFG,
	CFG_MOUSEWHEEL,
	CFG_MOREWINDOWS,
	CFG_ENHANCEDDIFFICULTYSETTINGS,
	CFG_NEWBRIDGES,
	CFG_NEWHOUSES,
	CFG_NEWTOWNNAMES,
	CFG_MOREANIMATION,
	CFG_NEWSHISTORY,
	CFG_WAGONSPEEDLIMITS,
	CFG_TOWNBUILDNOROADS,
	CFG_PATHBASEDSIGNALLING,
	CFG_AICHOOSECHANCES,
	CFG_AIBUILDRAILCHANCE,
	CFG_AIBUILDRVCHANCE,
	CFG_AIBUILDAIRCHANCE,
	CFG_CUSTOMBRIDGEHEADS,
	CFG_NEWCARGODISTRIBUTION,
	CFG_WINDOWSNAP,
	CFG_RESOLUTIONWIDTH,
	CFG_RESOLUTIONHEIGHT,
	CFG_NEWINDUSTRIES,
	CFG_LOCOMOTIONGUI,
	CFG_FIFOLOADING,
	CFG_TEMPSNOWLINE,
	CFG_TOWNROADBRANCHPROB,
	CFG_NEWCARGOS,
	CFG_ENHMULTI,
 	CFG_ONEWAYROADS,
	CFG_NEWSOUNDS,
	CFG_IRRSTATIONS,
	CFG_MORESTATS,
	CFG_AUTOREPLACE,
	CFG_AUTOSLOPE,	
	CFG_FOLLOWVEHICLE,
	CFG_TRAMS,
	CFG_ENHANCETUNNELS,
	CFG_FORCEGAMEOPTIONS,
	CFG_SHORTRVS,
	CFG_ARTICULATEDRVS,
	CFG_NEWAIRPORTS,
	CFG_NEWROUTES,
	CFG_CLONETRAIN,
	CFG_TRACERESTRICT,
	CFG_STATIONSIZE,
	CFG_ADJSTATIONS,
	CFG_NEWSIGNALS,
	CFG_NEWOBJECTS,
	CFG_VRUNCOSTS,
	CFG_MORETRANSOPTS,
	CFG_PSIGNALS,
	CFG_MISCMODS2,
	CFG_TSIGNALS,
	CFG_ISIGNALS,
	CFG_ADVORDERS,
	CFG_RVOVERTAKEPARAMS,
	CFG_ADVZFUNCTIONS,
	CFG_MOREINDUSTRIES,
	CFG_CARGODEST,
	CFG_CDSTRTCMPFACTOR,
	CFG_CDSTRTCOSTEXPRTHRSHLD,
	CFG_CDSTCARGOPACKETINITTTL,
	CFG_CDSTCARGOCLASSGENTYPE,
	CFG_CDSTUNROUTEDSCORE,
	CFG_CDSTNEGDISTFACTOR,
	CFG_CDSTNEGDAYSFACTOR,
	CFG_CDSTROUTEDINITSCORE,
	CFG_CDSTRTDIFFMAX,
	CFG_CDSTOPTS,
	CFG_CDSTWAITMULT,
	CFG_CDSTWAITSLEW,

//---------------------------------------------------
//   END OF LANGUAGE TEXTS
//---------------------------------------------------

	LANG_LASTSTRING,

	// Text that needs to be copied but neither translated nor converted
	// to wide characters

	OTHER_FIRSTSTRING,

	OTHER_NEWGRFCFG,

	OTHER_LASTSTRING,

	// Obsolete strings here, so that they don't causes error messages
	// when present anyway

	LANG_REALLYLASTSTRING		// Must be the last, used below to determine how many entries we need

};


#define CFG_COMMENT "// "

				// number of switch in verbose display
#define SWITCHNUMT (lastbitdefaultoff+1)
#define SWITCHNUMA (lastbitdefaulton+1)
#define SWITCHNUMB (lastbitdefaultoff-firstbitdefaultoff+1)
#define SWITCHSTARTB (firstbitdefaultoff)

#define TRAINTYPENUM 4		// number of train types for -mc display

#define BITSWITCHNUM 16		// number of bit switches

// Index numbers of the strings in language.dat file. Must be increasing.
#define LANGCODE_NAME(i) (-0x4000-(i))
#define LANGCODE_TEXT(i) (0x400+(i))
#define LANGCODE_SWITCHES(i,j) (-0x2000-((i)*2+(j)))
#define LANGCODE_HALFLINES(i) (0x1200+(i))
#define LANGCODE_TRAINTYPES(i) (0x1400+(i))
#define LANGCODE_BITSWITCH(i,j) (0x1600+((i)*32)+(j))
#define LANGCODE_END(i) (0x7F00+(i))
#define LANGCODE_RESERVED -0x7fff	// may never be used otherwise

#ifdef IS_MAKELANG_CPP
#define LANGTEXT_ENTRIES LANG_REALLYLASTSTRING
#else
#define LANGTEXT_ENTRIES (LANG_LASTSTRING+1)	// obsolete entries are not stored in language.dat
#endif

#define OTHER_NUM (OTHER_LASTSTRING-OTHER_FIRSTSTRING-1)

// the name of this language
ISEXTERN const char *langname;

// the ISO-3166 country code of this language
ISEXTERN const char *langcode;

// and the encoding names for DOS and Windows
ISEXTERN const char *dosencoding, *winencoding;

// All output lines that aren't in one of the other arrays
ISEXTERN const char *langtext[LANGTEXT_ENTRIES];
ISEXTERN int langtext_isvalid;	// nonzero if langtext has valid data

// Lines of help for all on/off switches, each at most 38 chars long.
// If you need more chars just insert another line.
ISEXTERN const char **halflines;
ISEXTERN int numhalflines;

// Names of the switches for the '-v' options
// First string is shown always, second only if set and with the given
// value of the switch in %d.
// These lines (both parts) are limited to 36 chars, also consider how large
// the expansion of the %d can be for that switch.
ISEXTERN const char *switchnames[SWITCHNUMT*2];

// Bit switch descriptions
ISEXTERN const char *bitswitchdesc[BITSWITCHNUM][33];

// Array of country IDs for which this language is the right one
ISEXTERN u16 *countries;

// Default DOS codepage for the strings of this language
ISEXTERN u32 codepage;

// Non-translated texts that need to be passed to the protected mode
// (not const because it's modified by cmdline/cfgfile)
ISEXTERN char *othertext[OTHER_NUM];


#undef ISEXTERN
#endif // _LANGUAGE_H
