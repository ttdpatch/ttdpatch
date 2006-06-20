#include <std.inc>
#include <airport.inc>

// Support for new airports supplyed by GRFs

uvard airportdataidtogameid, NUMAIRPORTS*2

struc airportgameid
	.grfid:		resd 1
	.setid:		resb 1
endstruc

uvarw airportsizes, NUMAIRPORTS

uvard airportlayoutptrs, NUMAIRPORTS

uvard airportmovementdataptrs, NUMAIRPORTS

uvarw airportstartstatuses, NUMAIRPORTS

uvarb airportspecialflags, NUMAIRPORTS

uvarb airportcallbackflags, NUMAIRPORTS

