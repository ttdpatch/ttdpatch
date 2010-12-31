
struc spriteheader
	.flags:			resb 1
#define SPRITE_TRANS 1		//	bit 0=Color index 0 is transparent. 
#define SPRITE_LATEDECOMPRESS 2	//	bit 1=Sprite is decompressed when drawn
#define SPRITE_CTILE 8		//	bit 2=Sprite is tile compressed
#define SPRITE_SIZEREL 0x40	//	bit 6=The exact size of this sprite is significant
#define SPRITE_PSEUDO 0xFF	//	bit *=Pseudo Sprite
	.height:		resb 1
	.width:			resw 1
	.xoffset:		resw 1
	.yoffset:		resw 1
endstruc


// note, this is accessed in reverse order, add new entries infront
struc prespriteheader
	// new entries here
	.padding:		resb 3	
	.pseudoflag:		resb 1		// 0x58 = realsprite, 0x59 = pseudosprite
	// don't touch the follwing entries:
	.spritenumber:		resd 1
	.size:			resd 1
	.actionfeaturedata:	resd 1
endstruc


%define _prespriteheader(reg, prop) reg -prespriteheader_size+prespriteheader. %+ prop

// Old code may still access the actionfeaturedata directly, so better be safe
%if prespriteheader.actionfeaturedata != prespriteheader_size-4
	%error "prespriteheader.actionfeaturedata has moved, this is bad"
%endif
