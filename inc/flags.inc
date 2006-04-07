
#include "../common.h"

// Allow convenient access to a range of variables through a register
// Note that if the variables are too far apart (more than +127/-128 bytes
// from the base), the access will access the wrong variable
%macro setbase 1-3.nolist	// params: base-register or "none",base-variable,dont-load-register
	%ifidni %1,none
		%undef BASE
	%else
		%if %0 < 3
			mov %1,%2
		%endif
		%define BASE byte %1-(%2)+
	%endif
%endmacro
// same but is needed when the base-variable is extern
// register must contain address of base-variable but will be modified
%macro setextbase 1-2.nolist
	%ifidni %1,none
		%undef BASE
	%else
		sub %1,%2
		%define BASE %1+
	%endif
%endmacro

	//
	// set the base register to use for flag tests
	// use this if you'll do several test[multi]flags in a row
	// 1) assign register = patchflags
	// 2) use testflagbase register
	// 3) do the test[multi]flags
	// 4) use testflagbase none
	//
	// this just saves a couple of bytes in the bt/test instructions :)
	//

%macro testflagbase 0-1.nolist none  // params: [a register name that points to patchflags]
	%ifidni %1,none
		%define patchflagmem patchflags
		%define patchflagmemabs 0
	%else
		%define patchflagmem %1
		%define patchflagmemabs 1
	%endif
%endmacro

testflagbase none

// test a patch flag
%macro testflags 1-2.nolist bt	// params: bitnum [,instruc]
	%ifnum %1
		%2 dword [patchflagmem+4*(%1 >> 5)],(%1) & 31
	%else
		%2 dword [patchflagmem],%1
	%endif
%endmacro

// same as above but test several flags at once using "test"
%macro testmultiflags 1-*.nolist // params: bit1,bit2,...
	%assign %%test_highestbyte (%1) >> 3
	%assign %%test_lowestbyte %%test_highestbyte
	%assign %%test_mask 1 << ( (%1) & 7)

	%rotate 1

	%rep (%0 -1)
		%assign %%thisbyte (%1) >> 3
		%if %%thisbyte < %%test_lowestbyte
			%assign %%test_mask %%test_mask<<(8*(%%test_lowestbyte-%%thisbyte))
			%assign %%test_lowestbyte %%thisbyte
		%elif %%thisbyte > %%test_highestbyte
			%assign %%test_highestbyte %%thisbyte
		%endif
		%if (%%test_highestbyte-%%test_lowestbyte)>3
			%error "Bits too far from each other"
			%exitrep
		%endif
		%assign %%test_mask %%test_mask | (1 << ( ( (%1) & 7)+(%%thisbyte-%%test_lowestbyte)*8))
		%rotate 1
	%endrep
	%if %%test_highestbyte==%%test_lowestbyte
		test byte [patchflagmem+%%test_lowestbyte],%%test_mask
	%else
		test dword [patchflagmem+%%test_lowestbyte],%%test_mask
	%endif
%endmacro

#if 0
%macro testmultiflags 1-*.nolist  // params: bit1,bit2,...
	%assign %%test_mask 0
	%assign %%test_bmask 0
	%assign %%test_byte -1
	%assign %%test_dword -1
	%assign %%test_size 1

	%rep %0
		%assign %%thisbyte (%1) >> 3
		%assign %%thisdword (%1) >> 5
		%if (%%test_dword <> -1) & (%%thisdword <> %%test_dword)
			%error "Not all bits in the same DWORD"
		%endif
		%if (%%test_byte <> -1) & (%%thisbyte <> %%test_byte)
			%%assign %%test_size 4
		%endif
		%assign %%test_byte %%thisbyte
		%assign %%test_dword %%thisdword
		%assign %%test_mask %%test_mask | (1 << ( (%1) & 31) )
		%assign %%test_bmask %%test_bmask | (1 << ( (%1) & 7) )
		%rotate 1
	%endrep
	%if %%test_size == 1
		test byte [patchflagmem+%%test_byte],%%test_bmask
	%else
		test dword [patchflagmem+4*%%test_dword],%%test_mask
	%endif
%endmacro
#endif

