%assign NOBJECTS	400
%assign NOBJECTSCLASSES	100 // We don't show more so we best not allow more
%assign NACTIVEOBJECTS	4096
%assign NOBJECTTYPE	0x5

// Defined object bits for proerpty 0F
#define OF_SCENERIOEDITOR	   0x1	// Only available in the Scenario Editor.
#define OF_UNREMOVALABLE	   0x2	// Irremovable (normal classA behaviour, ctrl remove works but charges 25* as much).
#define OF_ANYREMOVE		   0x4	// Anything can remove (owned land behaviour).
#define OF_ALLOWBUILDWATER	   0x8	// Allow building the object on water.
#define OF_REMOVALINCOME	  0x10	// Removing gives money (owned land behaviour, value / 2).
#define OF_NOFOUNDATIONS	  0x20	// Do not display foundations if on a slope.
#define OF_ANIMATED		  0x40	// Enables the animation counter, needed for sprite layout animations.
#define OF_NEEDSOWNER		  0x80	// Needs an owner (only avialable in normal game play)
#define OF_TWOCC		 0x100	// Allows the object to recieve two company colours mapping
#define OF_NOBUILDLAND		 0x200	// Disallows construction on land
#define OF_DRAWWATER		 0x400	// Draw water tile under the object (only valid with build on water)

#define OF_BUILDWATER		 0x208	// Bitmask of the two options around construction on water

// new obbject pool structure (allows for expansion of their properties later)
// Remember to buffer this structure always
struc object
	.origin:	resw 1 // (00) Word with the x,y corrdinate of the northen tile
	.buildyear:	resw 1 // (02) Word with the build year from 1921
	.dataid:	resw 1 // (04) Word specifying the object's data id
	.animation:	resb 1 // (06) Byte which allows for anumation
	.flags:		resw 1 // (07) Dword which contains the flags of the object (cached)
	.colour:	resb 1 // (08) Colour for non-company owned objects (Two nibbles for 2cc)
			resb 2 // Buffer to dwords
endstruc

// Additional notes:
// - The object pools flags are copied at construction time and
//     should be used over the grf's flags
