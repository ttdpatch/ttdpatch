// macro to get the real house id if newhouses is on
%macro gethouseid 2		// params: destination, index; both must be dword regs
%ifidni %1,ebp
%elifidni %2,ebp
%else
	push ebp
%endif
%ifidni %1,ebx
%elifidni %2,ebx
%else
	push ebx
%endif
%ifnidni %2,ebx
	mov ebx,%2
%endif
	call gethouseidebpebx
%ifnidni %1,ebp
	mov %1,ebp
%endif
%ifidni %1,ebx
%elifidni %2,ebx
%else
	pop ebx
%endif
%ifidni %1,ebp
%elifidni %2,ebp
%else
	pop ebp
%endif
%endmacro

ptrvardec newhousedatablock

struc newhousedata

// Substitute building types for new types. This value will be placed in L2, so it is automatically
// used if this switch isn't on.
ptrvarofs substbuilding,newhousedatablock,$
resb 256

// House callback flags.
// Bit 0 - use callback 17 to decide wether the house can be built on a given tile
// Bit 1 - use callback 1A to decide the following frame of the animations.
// Bit 2 - use callback 1B to periodically start/stop the animation
// Bit 3 - use callback 1C to change animation state when the construction state changes
// Bit 4 - use callback 1E to decide the color of the building
// Bit 5 - use callback 1F to decide cargo acceptance
// Bit 6 - use callback 20 to decide speed of animation
// Bit 7 - use callback 21 to decide if the building must be removed
ptrvarofs housecallbackflags,newhousedatablock,$
resb 256

// Second set of callback flags
// Bit 0 - use callback 2A to decide the three cargo types accepted
ptrvarofs housecallbackflags2,newhousedatablock,$
resb 256

// If the corresponding byte for an old building type is nonzero in this array, all buildings of
// the old type is considered to be this new type instead, and no houses of the old type are
// built anymore
ptrvarofs houseoverrides,newhousedatablock,$
resb 110

alignb 4

// Contains how many periodic processings take place between two activations of triggers 1 and 2
ptrvarofs houseprocessintervals,newhousedatablock,$
resb 256

// Array for pseudo-random building colors used if recoloring is requested, but no recolor
// sprite is specified. This is in fact a 256*4 array of bytes.

ptrvarofs housecolors,newhousedatablock,$
resd 256

// Relative probablity of a new house to appear. Old house types are assumed to have a probablity
// of 16, and this is the default for new types as well.
ptrvarofs houseprobabs,newhousedatablock,$
resb 256

// Extra flags for new types
// bit 0: appears only while generating a town, but not later
// bit 1: towns and AI players can't remove this
// bit 2: callback 1B is called at the same time for every tile of the building, not independently
// bit 3: callback 1A needs random bits
ptrvarofs houseextraflags,newhousedatablock,$
resb 256

// Number of animation frames
ptrvarofs houseanimframes,newhousedatablock,$
resb 256

// Speed of animation
ptrvarofs houseanimspeeds,newhousedatablock,$
resb 256

// Class information
// Every entry has 4 bytes for GRFID and one byte for class
// Buildings that don't have thieir class set have zero in both fields
ptrvarofs houseclasses,newhousedatablock,$
resb 256*5

// Accepted cargo types, the fourth byte is always ignored
// FFFFFFFF means the default (pass, mail, goods/food)
ptrvarofs houseaccepttypes,newhousedatablock,$
resd 256

// New arrays instead of the old 110-element-long ones. The bottom 128 slots are reserved for
// the old data (it is copied over here), the remaining 256 slots are for the new data, but
// only entries between 129 and 128+[lastextrahousedata] (inclusive) are valid. This layout
// allows redirecting the old TTD functions to use these arrays, and all we need to do
// to make TTD process our new data is adding 128 to a gameid.
// The house sprite array isn't redirected because it'd need an awful lot of memory, and
// new houses use the better newgrf mechanism to select their appearance anyway.

ptrvarofs newhousepartflags,newhousedatablock,$
resb 128+256
// RemoveHouse may read three bytes before baHouseFlags and assumes these bytes
// being zero, so we define a 3-byte block that is never acessed and always remains zero
.safeguard:	resb 3
ptrvarofs newhouseflags,newhousedatablock,$
resb 128+256

alignb 4

ptrvarofs newhouseyears,newhousedatablock,$
resw 128+256
ptrvarofs newhousepopulations,newhousedatablock,$
resb 128+256
ptrvarofs newhousemailprods,newhousedatablock,$
resb 128+256
ptrvarofs newhousepassaccept,newhousedatablock,$
resb 128+256
ptrvarofs newhousemailaccept,newhousedatablock,$
resb 128+256
ptrvarofs newhousefoodorgoodsaccept,newhousedatablock,$
resb 128+256
ptrvarofs newhouseremoveratings,newhousedatablock,$
resw 128+256
ptrvarofs newhouseremovemultipliers,newhousedatablock,$
resb 128+256
ptrvarofs newhousenames,newhousedatablock,$
resw 128+256
ptrvarofs newhouseavailmasks,newhousedatablock,$
resw 128+256

// graphics data for the extra houses, indexed by gameid.
// Note that these may be zero if the user didn't set custom graphics for the ID
// Only enties between 1 and [lastextrahousedata] (inclusive) are valid
ptrvarofs extrahousegraphdataarr,newhousedatablock,$
resd 256

// array to assign gameids to dataids. This array is saved in savegames and allows
// restoring all houses to their old gameid. Only enties between 1 and [lasthousedataid]
// (inclusive) are valid.

ptrvarofs housedataidtogameid,newhousedatablock,$
resd 2*256

ptrvarofs globalhousecounts,newhousedatablock,$
resw 128+256

ptrvarofs newhousespriteblock,newhousedatablock,$
resd 256

endstruc_32

