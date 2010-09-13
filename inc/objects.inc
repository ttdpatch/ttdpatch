%assign NOBJECTS	400
%assign NOBJECTSCLASSES	100 // We don't show more so we best not allow more
%assign NACTIVEOBJECTS	4096
%assign NOBJECTTYPE	0x5

// Defined object bits for property 0F (Word)
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
#define OF_BUILDUNDERBRIDGE	 0x800	// Reserved for OpenTTD as we do not support proper tiles under bridges
#define OF_ANIMATEDRANDBITS	0x1000	// Random bits available in callback 0x158 (Next Animation Frame)

#define OF_BUILDWATER		 0x208	// Bitmask of the two options around construction on water

// Defined object animation triggers for property 13 (Byte)
#define OA_CONSTRUCTION		   0x1	// Upon construction (whole object)
#define OA_PERIODICTILE		   0x2	// Periodic tileloop (per tile)
#define OA_WHOLEOBJECT		   0x4	// Every 250? ticks (whole object)

#define OA_FORALLTILES		   0x5	// Used to detect which triggers are for the whole object

// Defined object callback flags for property 15 (Word)
#define OC_SLOPECHECK		   0x1	// Callback 157 (Build - custom check slope)
#define OC_ANIM_NEXTFRAME	   0x2	// Callback 158 (Decide next animation frame)
#define OC_ANIM_SPEED		   0x4	// Callback 159 (Decide animation speed)
#define OC_BUILDCOLOUR		   0x8	// Callback 15B (Decide object colour)
#define OC_DIAPLAYDETAILS	  0x10	// Callback 15C (Display additional text in buy menu)
#define OC_AUTOSLOPE		  0x20	// Callback 15D (Autoslope decide)

// new obbject pool structure (allows for expansion of their properties later)
// Remember to buffer this structure always
struc object
	.origin:	resw 1 // (00) Word with the x,y corrdinate of the northen tile
	.builddate:	resd 1 // (02) Dword storing date the object was built
	.dataid:	resw 1 // (06) Word specifying the object's data id
	.townptr:	resd 1 // (08) Dword (Pointer) to closest town
	.colour:	resb 1 // (0C) Colour for non-company owned objects (Two nibbles for 2cc)
			resb 3 // Buffer to dwords
endstruc

// Used to attempt to translate the data from the old format to the newer one
struc oldobject
	.origin:	resw 1 // (00) Word with the x,y corrdinate of the northen tile
	.buildyear:	resw 1 // (02) Word with the build year from 1921
	.dataid:	resw 1 // (04) Word specifying the object's data id
	.animation:	resb 1 // (06) Byte which allows for animation
	.flags:		resw 1 // (07) Word which contains the flags of the object (cached)
	.colour:	resb 1 // (09) Colour for non-company owned objects (Two nibbles for 2cc)
			resb 2 // Buffer to dwords
endstruc

// Additional notes: (now redudant)
// - The object pools flags are copied at construction time and
//     should be used over the grf's flags
