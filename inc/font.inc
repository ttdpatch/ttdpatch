// Definitions for UTF-8 font support

// this holds the info about a font glyph
struc fontinfo
	.width:		resb 1	// width of the character
	.unused:	resb 1	// unused, needed to make SIB size
	.sprite:	resw 1	// sprite holding the glyph, 0 if none
endstruc_32

