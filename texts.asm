;
; NASM-specific code and macros to define the in-game texts contained
; in texts.inc
;

%ifdef DOS
%define doalign 	;; only align in flat model
%define ofs(a) dw a	;; offsets are words in DOS code
%define definesegment segment _data public align=16 class=DATA USE16
%define skipsegment
%else
%define doalign align 4
%define ofs(a) dd a	;; ...and dwords in Windows code
%ifdef WIN
%define definesegment segment _data public align=16 class=DATA USE32
%define skipsegment
%else
%define definesegment section .data		;; for coff output
%define skipsegment section .debug$S		;; mark as debug info so the linker drops it
%endif
%endif

definesegment

global _ingamelang_num,_ingamelang_ptr
global ingamelang_num,ingamelang_ptr
;,_ingamelang_maxsize

;
; -------------------------------------
;     Macro definitions
; -------------------------------------
;

%assign i 0
%macro entry 1	; entryname
	%ifdef entries
		%xdefine entries entries %+ ,%1
	%else
		%define entries %1
	%endif

	; for perl/texts.pl
	%1 equ i
	%assign i i+1
%endmacro

%assign langnum 0
%assign maxsize 0

%macro setend 1 ; nextlang
	%ifdef lastlang

		lastlang %+ end :

;		%define cursize lastlang %+ end - lastlang %+ start
		%ifndef PREPROCESSONLY
;			%if cursize > vardatasize
;				%error "Increase vardatasize!"
;			%endif
;			%if cursize > maxsize
;				%define maxsize cursize
;			%endif

			checkall lastlang,entries
		%endif
	%endif
	%define lastlang %1
%endmacro


%macro allentries 3-* ; name,short,entries...
	%define thisname %1
	%define thisshort %2
	%rotate 2
	%rep %0-2
		ofs(thisshort %+ _%1 - thisname %+ start)
		%rotate 1
	%endrep
%endmacro

%macro checkall 2-* ; name,entries...
	%define thisname %1
	%rotate 1
	%assign lastofs 0
	%rep %0-1
		%assign thisofs thisshort %+ _%1 - $$
		%if thisofs < lastofs
			%define thisofsname %1
			%error "thisname thisofsname is in wrong order!"
		%endif
		%assign lastofs thisofs
		%rotate 1
	%endrep
%endmacro
	

%macro newlanguage 3+ ; name,short,numsizes,sizes...

	setend %1

	doalign

	lang %+ langnum:
	%assign langnum langnum+1

	ofs(%1start)
	ofs(%1end - %1start)
	dd %3

	%1start:
	allentries %1,%2,entries
%endmacro


%macro setvardatasize 1 ; size
	%assign vardatasize %1

	; for perl/texts.pl
	VARDATASIZE equ %1
%endmacro

%macro secondlanguage 0
	%ifdef ONLYFIRST
		setend nothing
		skipsegment
		%define resumesegment
		%define newlanguage skiplanguage
	%endif
%endmacro

%macro skiplanguage 3+
%endmacro

; -----------------------------------
;	Language data
; -----------------------------------

%include "texts.inc"

nothingstart:
nothingend:

%ifdef resumesegment
	definesegment
%else
	setend nothing
%endif

; ---------------------------------------
;	Exported array pointers
; ---------------------------------------

	doalign

ingamelang_num:
_ingamelang_num dd langnum

; _ingamelang_maxsize dd maxsize

ingamelang_ptr:
_ingamelang_ptr:

%assign i 0
%rep langnum
	ofs(lang %+ i)
	%assign i i+1
%endrep
