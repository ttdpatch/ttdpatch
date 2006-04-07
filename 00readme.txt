
Hi!

Congratulations on getting the TTDPatch source.

It is split into various directories, and each directory should have a 
00readme.txt file that tells you what it contains.  You just have to hope 
that this file isn't too outdated...

If you want to compile TTDPatch yourself, be sure to read 0compile.txt

If you want to actually modify TTDPatch, make sure that you know the phone
number of the nearest insane asylum.  The code is messy, convoluted, and
must be written in a very special way.  Be sure you have read, memorized,
and understood 0hackers.txt, before you even attempt to change anything.
Hey, it's not meant to be easy, so don't complain, OK?

--

This main directory has a few subdirectories.

BIN		Batch and Perl files used to start the compiler etc.
DOC		some documentation of TTD's internal structures, some of
		the screenshots of the web page and other stuff
DXMCI		The source code for dxmci.dll
HOST		When using a cross compiler, native object files and
		executables are put in this directory
LANG		The language source files, as C header files
NASM		Various diffs to apply to the Nasm source code to make it work 
		correctly with TTDPatch sources
PATCHES		The assembler code for the patch functions
PERL		Various Perl programs to generate some of the source files
SV1FIX		Source code for sv1fix and sv2flip
TEX		The Texinfo source of the manual
VERSIONS	This is where the .ver files containing the offset for the 
		various versions will go.  They're not included in the source
		distribution, to make them yourself just run ttdpatch -V

Description of the files you'll find here (not most of the generated ones,
those should be fairly obvious), also some obsolete files aren't listed

AUXFILES.C, .H
	Handles the files that are "attached" to the patch executable,
	like language data and (with USEPROTBIN) the protected mode code
BASHINIT
	Bash initialization file for use in the CygWin environment
CHECKEXE.C, .H
	Generates TTDLOAD.OVL and TTDLOADW.OVL and makes sure it's good
CODEPAGE.C, .H
	Handles conversion from DOS codepages to the Windows codepages,
	used for the Windows version only
COMMON.H
	Defines common to both the assembler and C sources
COPYING
	The GNU General Public License, which is the license of TTDPatch
DOS.C
	DOS-specific code
ERROR.C, .H
	abort with an error message
EXEC*.*
	A library to swap out DOS programs, precompiled for Borland C++ (BCL)
	and OpenWatcom (OWL), as well as the source code
FLAGDATA.H
	Definitions of switch parameters
FRAGMENT.AH
	fragments of code that TTDPatch searches for to do the patching, as
	well as their replacements.
GREP.C, .H
	a simple, but fast grep-like function I made. Can search memory and
	large files
GREPDEF.C
	default definitions for grep, can be overridden by other code
INIT.AH
	initialization of the protected mode part of TTDPatch
LANGUAGE.H
	defines the CFG_xxx constants and other stuff
LANGUAGE.DAT (not included)
	generated file contains the language texts in compressed form. This
	file is appended to the end of the TTDPatch executables
LANGUAGE.UCD
	same as language.dat but uncompressed
LIBZ.A
	libz (see zlib below) pre-compiled for the Windows version
LOADER.AH
	the code that runs before TTD's initialization to install the patch code
LOADLNG.C, .H
	used to decode the language.dat file
LOADVER.H
	incoporate the version information into the exe file
MAKEFILE
	Is it a bird?  Is it a plane?  No, it's the... Makefile!
MAKEFILE.DEP
	Makefile dependencies
MAKELANG.C
	Main program to generate language.dat
MAKELANG.ERR
	Error messages from Makelang
MEMSIZE.H
	Generated file containing the in-memory size of the DOS TTDPatch
MKPTTXT.*
	A program to generate ttdpttxt.*, which contain custom in-game strings
MYALLOC.C, .H
	will eventually replace C's memory allocation with something better
OPIMM8.MAC
	Nasm macros that force the use of imm8 operands for simple instructions
	where possible (e.g. xor eax,8)
OSFUNC.H
	header file for DOS.C and WINDOWS.C
PATCHES.AH
	contains the procs that do the actual patching
PROC.MAC
	Macros for NASM to simplify argument and local variable handling
PROCLANG.C
	This compiles the data of a single language
RELOC.INC
	Relocations for the Windows version
SMARTPAD.MAC
	Pads with no-op code with the smallest number of instructions
SW_LIST.H
	Definition for all command line and cfg file switches
SWITCHES.C, .H
	process the command line and the config file, set the switch states
SYSTEXTS.H
	List of texts from language.dat passed to the protected mode code
TEXTS.ASM, TEXTS.INC, TEXTS.LST
	The new in-game text strings in all five TTD languages
TTDPATC*.ICO
	Icons to be used with TTDPatch
TTDPATCH.C
	TTDPatch main program.
TTDPATCHW.RC
	Resource file that includes the icons and sets version info
TTDPROT.AH
	Include file for TTDPROT.ASM. Defines a few structures and macros
TTDPROT.ASM
	Main assembler program containing the protected mode code. Mostly
	consists of #include statements
TTDPROT*.LST
	Listing of the most recent compilation, for finding error locations
TYPES.H
	Define some OS-independent integers, e.g. S32 for a signed 32bit int
VARS.AH
	global variables of the protected mode code
VERSION.DEF
	Defines the current version
VERSIONS.H
	same as above for the C code
WINDOWS.C
	Windows-specific functions
X?.ASM (not included)
	Generated by passing TTDPROT.ASM through a C pre-processor. This has
	all #include statements processed and C++ style comments removed.
ZLIB*.*
	A compression library by Jean-loup Gailly and Mark Adler, used for
	compressing the language data.  Pre-compiled for Borland C++ (BCL)
	and OpenWatcom (OWL).
