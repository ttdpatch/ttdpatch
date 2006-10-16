
// definitions of various text IDs


//
// ourtext(): custom texts that can be translated via mkpttxt

#define ourtext(n) (ourtext_ ## n)
%include "inc/ourtext.inc"

// mild hack to get the dependencies right
%if 0
#include <inc/ourtext.inc>
%endif

//
// statictext(): custom texts that are language-independent
//
// IDs are defined in stat_txt.ah (plus a few special ones in texthnd.asm)
//
#define statictext(n) ( ( (STXT_ ## n) & 0x7ff) | 0xfe00)
#define stxt __stxt
#define stxt_cont __stxt_cont
%macro stxt 2+.nolist
	STXT_%1 equ %$stxtnum
	%assign %$stxtnum %$stxtnum+1
%endmacro
%macro stxt_cont 1+.nolist
%endmacro
%push stxtdef
%assign %$stxtnum 0
STXT_first equ %$stxtnum
#include <stat_txt.inc>
#undef stxt
#undef stxt_cont

// define four special texts that can be modified by writing
// the text address to specialtext1..specialtext4
// and using statictext(special1/2)
// WARNING: do not use special# strings in error messages
//          error messages must use specialerr#

STXT_special1 equ %$stxtnum
STXT_special2 equ %$stxtnum+1
STXT_special3 equ %$stxtnum+2
STXT_special4 equ %$stxtnum+3
STXT_specialerr1 equ %$stxtnum+4
STXT_specialerr2 equ %$stxtnum+5
STXT_specialerr3 equ %$stxtnum+6
STXT_specialerr4 equ %$stxtnum+7
STXT_last equ %$stxtnum+8
%pop

//
// newstext(): like ourtext() but with permanently fixed IDs
//
// IDs are defined below in this file
//
#define newstext(n) ( ( (NTXT_ID_ ## n) & 0x7ff) | 0xe800)


// nasm macro used by the below C preprocessor macros, just collects data
// for eventual use in morenews.asm
%macro _defnewstext 3.nolist
	%if %1 <> %$ntxtnum
		%define ntxtname %1
		%error "Incorrect order of news text entries for ntxtname"
	%endif
	NTXT_ID_%2 equ %$ntxtnum
	%define NTXT_ARG_%$ntxtnum %3
	%assign %$ntxtnum %$ntxtnum+1
%endmacro

%push ntxt_def
%assign %$ntxtnum 0

//
// usage:
//	defnewstext(ID,identifier)	to make a news alias for ourtext()
//	statnewstext(ID,identifier)	to make a news alias for statictext()
//	dummynewstext(ID,identifier)	to make a dummy entry (to keep IDs constant)
//
// Never change either ID or identifier in any entry
//
// (the identifier may be changed only if the corresponding text format
//  is 100% compatible, i.e. same placeholders in the same order)
//
// If you ever need to remove or change a string here, make a new entry
// and leave a dummy in the old spot, either using dummynewstext if
// the original string had no placeholders (like 0x80 or 0x7B etc.), or
// using a statictext that pops the same number of words (using 0x85) if it did.
//
// Reusing an ID is only safe if there are NO savegames in existence in
// which a news message using this ID is currently in the message queue.
//

#define defnewstext(i,n) _defnewstext i,n,ourtext(n)
#define statnewstext(i,n) _defnewstext i,n,statictext(n)
#define dummynewstext(i,n) _defnewstext i,n,6


defnewstext(0,lmilloutoftrees)
defnewstext(1,ufodestroyed)
defnewstext(2,zeppelincleared)
defnewstext(3,aircraftcleared)
defnewstext(4,traincleared)
defnewstext(5,eurointroduced)
defnewstext(6,vehobsolete)
defnewstext(7,vehiclelost)
defnewstext(8,cantreverse)


%undef _defnewstext
%assign NTXT_NUM %$ntxtnum
%pop
