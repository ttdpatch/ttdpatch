// Sprite Description used for sorting and drawing in correct order
// Note: The real used struct sizes may vary by patch usage, so don't use _size

struc spritedesc
	.sprite:	resd 1	// 00h
	.pixelX1:	resw 1	// 04h
	.pixelY1:	resw 1	// 06h
	.pixelX2:	resw 1	// 08h
	.pixelY2:	resw 1	// 0ah
	.X1:		resw 1	// 0ch
	.Y1:		resw 1	// 0eh
	.Z1:		resb 1	// 10h
	.Z2:		resb 1	// 11h
	.X2:		resw 1	// 12h
	.Y2:		resw 1	// 14h
	.flags:		resw 1	// 16h
	.linked:	resd 1	// 18h
	.exsfeature:	resw 1	// 0x1C //only valid with spritelimit patch
endstruc

struc linkedspritedesc
	.sprite:	resd 1	// 0x00
	.x:		resw 1	// 0x04
	.y:		resw 1	// 0x06
	.z:		resw 1	// 0x08
	.unused:	resw 1	// 0x09
	.next:		resd 1	// 0x0A
	.exsfeature:	resw 1	// 0x0E //only valid with spritelimit patch
endstruc

struc relspritedesc
	.sprite:	resd 1	// 0x00
	.xoffset:	resw 1	// 0x04
	.yoffset:	resw 1	// 0x06
	.next:		resd 1	// 0x08
	.exsfeature:	resw 1	// 0x0C //only valid with spritelimit patch
endstruc
	
struc groundspritedesc
	.sprite:	resd 1	// 0x00
	.next:		resd 1	// 0x04
	.x:		resw 1	// 0x08
	.y:		resw 1	// 0x0A
	.z:		resb 1	// 0x0C
	.unused:	resb 1	// 0x0D
	.exsfeature:	resw 1	// 0x0E //only valid with spritelimit patch
endstruc
