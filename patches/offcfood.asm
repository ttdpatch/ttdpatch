
// Offices accept food

#include <defs.inc>
#include <ttdvar.inc>

	// this determines what a house etc. accepts.
	// Used to make pass+mail+food/goods houses make accept goods/food too
	// save to use: ax
global collectaccepts
collectaccepts:
	or ah,ah
	jz short .nothingaccepted
	mov dl,al
	shr ax,8
	push eax
//	add [edx*2+ebp],ax is what will be done on return
//	except sometimes it's edx*4, so we can't do it ourselves

	mov al,[climate]
	cmp al,0		// not for temperate (not food)
	je short .notoffice
	cmp al,3		// nor toyland
	je short .notoffice

	mov al,[esp]
	cmp dl,0		// accepts passengers?
	jne short .notoffice
	cmp bl,2		// accepts mail?
	jne short .notoffice
	cmp cl,5		// accepts goods?
	jne short .shopsnoffices

.isoffice:			// it's an office
	add al,ch		// add food
	shr ax,2		// amount = (passengers+goods)/4
	add [0xb*2+ebp],ax
	jmp short .notoffice
.shopsnoffices:
	cmp cl,0xb		// accepts food?
	jne short .notoffice
				// almost everything else...
	add al,ch
	shr ax,3		// almost always zero...
	add [5*2+ebp],ax	// add goods
.notoffice:
	pop eax
	stc
.nothingaccepted:
	ret
; endp collectaccepts 
