
// Version data structure

struc version
	.ttdversion: 	resd 1	// version number for which this is valid
	.size: 		resd 1	// and the file size of the executable
	.numoffsets:	resd 1	// how many offsets follow below
	.offsets:		// variable size array of DWORDs
endstruc

