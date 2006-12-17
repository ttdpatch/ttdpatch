// for each feature a structure that holds all information needed
struc idfsystem
	.dataid_dataptr: resd 1
	.dataid_lastnumptr: resd 1			// to a dword var used as word
	.dataidtogameidptr: resd 1			// to a word array, maps dataids to gameids	// no room in dataid_dataptr
	.gameid_dataptr: resd 1
	.gameid_lastnumptr: resd 1			// to a dword var used as word
	.curgrfidtogameidptr: resd 1		// to an array of words
	.dataidcount: resd 1				// how many dataids we can have max (zero counts aswell)
	.gameidcount: resd 1				// how many gameids we can have max (zero counts aswell)
endstruc

struc idf_dataid_data
	.grfid:		resd 1	// permanent in savegame
	.setid:		resw 1	// permanent in savegame
	.numtiles:	resw 1	// permanent in savegame
endstruc

struc idf_gameid_data
	.act3info:	resd 1
	.setid:		resw 1
	.dataid:	resw 1
endstruc
