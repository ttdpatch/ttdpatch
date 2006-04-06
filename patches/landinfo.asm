#include <std.inc>
#include <window.inc>
#include <textdef.inc>

extern DrawWindowElements,gettileinfoshort,drawcenteredtextfn,drawsplitcenteredtextfn
extern ourtext,landareainfoheight

uvard tilealtitude

global patchtotallandwindowsize
patchtotallandwindowsize:
	mov dword [tilealtitude],esi  	//store esi which is the short form of XY for tileinfo
	mov ebx, 620118h 				//resize the landinfosizewindow
	mov dx, -1						//...old code
	ret

global patchlandwindowboxsizes	
patchlandwindowboxsizes:
	mov     ebp, [esi+window.elemlistptr]						//grab the window pointer
	mov		dword [ebp+(windowbox_size*2)+windowbox.y2], 62h	//62 is the new height we need to add
	call	[DrawWindowElements]								//do the original code
	mov     cx, [esi+window.x]									//shift the new co-ords
	mov     dx, [esi+window.y]
	ret
	
global addlandinfoheightstring
addlandinfoheightstring:
	jz		short .noCargoText					//no cargo text? skip
	push	ecx
	push	dx
	add		dx, 0Bh								//switcharoo! we want this at the bottom of the window
	mov     bp, 276								//the original code...
	call	[drawsplitcenteredtextfn]			//draw it
	pop		dx
	pop		ecx	
	
.noCargoText:
	sub		dx, 05h								//move back up the page
	mov 	bx, ourtext(landareainfoheight)		//grab our text string from memory
	push	ecx
	push	edx
	push	ebx
	push	esi
	push	edi
	movzx	esi, word [tilealtitude]			//grab the stored tileXY
	call	[gettileinfoshort]					//re-get the altitude
	mov		[textrefstack], dl					//push onto string
	pop		edi
	pop		esi
	pop		ebx
	pop		edx
	pop		ecx
	call	[drawcenteredtextfn]				//draw it.
	retn
