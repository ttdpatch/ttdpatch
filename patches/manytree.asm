//
// allow planting trees in a rectangular region
// allow planting more than one tree on a tile
//

#include <std.inc>
#include <bitvars.inc>

extern curplayerctrlkey,normalplant,randomfn,treenum,treeplantfn
extern treeplantmode
extern treestart

uvard pickrandomtreefn

// Parameters of treeplantfn:
// ax: x coordinate *16 (lower 4 bits must be clear)
// cx: y coordinate *16 (lower 4 bits must be clear)
// bh: type of tree
// bl: bit 0 is clear if checking cost only
// returns
// ebx: cost of plant or 0x80000000 if there's an error
// destroys: edi

uvarw lasttreepos,9	// position of last planted tree
uvarb lasttreetype,9	// type of last planted tree
uvard plantcost		// cost of the action
uvarb fieldsdestroyed	// set if fields were destroyed by the plant

// planttree1 is called when computing the index of the given field
// after the two overwritten instructions, di will contain this index
// safe: none
global planttree1
planttree1:
	or di,ax	// overwritten by the
	ror di,4	// runindex call

	cmp byte [normalplant],1
	jne .doit

.end:
	ret

.doit:
	and dword [plantcost],0
	test byte [treeplantmode],plantmanytrees_rectangular
	jz .end

	// Resetting plantcost here is the safest way, because this code will surely run, unlike others that
	// don't run if an error occured. It should be reset even for treeplants without ctrl.

	// put current user into ebp or 8 if non-player
	movzx ebp,byte [curplayer]
	cmp ebp,8
	jb .ok
	mov ebp,8
.ok:
	cmp byte [curplayerctrlkey],1
	je .isctrl

	test bl,1	 // we don't store the positions if checking cost only
	je .dontsave

	mov [lasttreepos+ebp*2],di
	mov [lasttreetype+ebp],bh

.dontsave:
	ret

.isctrl:
	pusha
	mov ax,[lasttreepos+ebp*2]
	mov si,ax

	mov cx,di

	test ax,ax
	jnz .isset

	mov ax,cx

.isset:
	cmp ah,ch
	jb .noswap1
	xchg ah,ch

.noswap1:
	cmp al,cl
	jb .noswap2
	xchg al,cl

.noswap2:
	// dx now contains the upper left corner and cx the lower right corner of the rectangle
	cmp bh,[lasttreetype+ebp]
	je .notrandom

	mov bh,-1

.notrandom:
	xchg eax,edx
	call planttreearea
	popa
	ret


// plant trees in a rectangle
//
// in:  cx=lower right corner (highest x, y coordinates)
//	dx=upper left corner (lowest x, y coordinates)
//	bl has bit 0 clear if checking cost, set if actually planting
//	bh=tree type or bit 7 set for random trees
//	si, di squares to exclude
// out:	total cost in ebx
// uses:al,dx
global planttreearea
planttreearea:
	mov byte [normalplant],1	//to avoid endless recursive calls
	and dword [plantcost],0
	// this is unnecessary if called from planttree1, but not if called from somewhere else
	// it won't hurt, anyway
	mov al,dl

	// loop to plant trees to all tiles inside the rectangle
	// inside the loop, dx is the position of the next tree to plant
.loop:
	// we don't plant where the user clicked to yet because this tree will be planted
	// in the remaining part of treeplantfn

	cmp dx,di
	je .nexttile

	// don't plant in the other corner either, there's a tree already

	cmp dx,si
	je .nexttile

	pusha
	test bh,bh
	jns .norandom

	push ebx
.random:
	call dword [randomfn]
	movzx ebx,dx
	mov cl,al
	call [pickrandomtreefn]
	test cx,cx
	js .random
	pop ebx
	cmp cl,0x1b	// plant cactii sparsely in the desert
	jne .notcactus
	cmp ah,0x10
	ja .noadd
.notcactus:
	mov bh,cl

.norandom:
	movzx eax,dl	//create the parameters of treeplantfn from dx
	movzx ecx,dh
	shl eax,4
	shl ecx,4
	call dword [treeplantfn]
	cmp ebx,0x80000000 //we ignore errors
	je .noadd
	add [plantcost],ebx
.noadd:
	popa

.nexttile:
	inc dl
	jz .nextline
	cmp dl,cl
	jbe .loop

.nextline:
	mov dl,al
	inc dh
	jz .done
	cmp dh,ch
	jbe .loop

.done:
	mov byte [normalplant],0	// further treeplants can be in the patched form
	mov ebx,[plantcost]
	ret


// called when treeplantfn decides whether a tree can be planted to a tile where there is already one
// zero flag is set if it's allowed
// safe: ax, cx
global checkmultitree
checkmultitree:
	test byte [treeplantmode],plantmanytrees_morethanonerectangular
	jnz .allowmultiplant

	cmp byte [normalplant],1
	je .notallow	// don't allow multi-tree planting in automatic plant loops

.allowmultiplant:
	cmp byte [gamemode],2
// In editor, allow it because it won't cost, but if not, check the number of trees.
	jne .mayallow
	ret

.notallow:
	or edi,edi
	ret

.mayallow:
	mov al,[landscape5(di)]		// we check the number of trees in the tile
	mov ah,al
	and al,0xc0
	cmp al,0xc0-1
	ja .done	// If it's already 4, we don't allow planting more (exit with ZF=0)
			// If we did, the player would pay for nothing.

	and ah,0x0f			// check how old the current tree is

	// if it's already grown up, planting a small tree next to it will cost the normal price
	cmp ah,3
	jae .normalcost

	push eax
	// If it's small, it'll grow up instantly, and the player will pay quadruple cost for
	// planting a big tree. We add only triple cost because planttree2 will add treeplantcost to it.
	mov eax,[treeplantcost]
	lea eax,[2*eax+eax]
	add dword [plantcost],eax
	pop eax

.normalcost:
	test bl,1
	jz .dontmakesmall //don't hurt the landscape array if checking cost only
	and byte [landscape5(di)],0xf0 //else the newly planted tree will be small

.dontmakesmall:
	cmp ah,ah //we allow planting by setting zero flag

.done:
	ret

// Called to check whether a tree can be placed on a class 0 tile
// Record planting on fields so we can adjust the cost later on
// (Not paying the farmers for destroying their crops is unfair isn't it? :-)
global checkforrocks
checkforrocks:
	mov al,[landscape5(di)]		// overwritten
	and al,0x1f
	cmp al,0xf
	jne .notfields
	mov byte [fieldsdestroyed],1
.notfields:
	and al,0x1c			// ditto
	ret

// called when there's no error and computing the cost
// must return the cost in ebx
// safe: none
global planttree2
planttree2:
	mov ebx,[treeplantcost]
	cmp byte [fieldsdestroyed],0
	jz .nofields
	mov byte [fieldsdestroyed],0
	add ebx,[fieldsremovecost]
.nofields:
	cmp byte [normalplant],1
	je .end
	add ebx,[plantcost] //we return [plantcost]+[treeplantcost]
.end:
	ret
