
// Refit info

struc refitinfo
	// NOTE: don't rearrange the fields, the first four bytes always
	// must be what distinguishes cargos and subcargos
	.type:		resb 1	// cargo type (climate independent)
	.ctype:		resb 1	// climate-dependent cargo type
	.suffix:	resw 1	// cargo name suffix
	.cycle:		resb 1	// refit cycle to use
	.block:		resd 1	// sprite block for cargo name suffix
endstruc

