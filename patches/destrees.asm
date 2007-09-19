//-------------------------------------------------------
//	DESERT REVEGETATION, etc...(TM) :)
//-------------------------------------------------------
// by Steven Hoefel.
//
//  Uses var 9E bits 0, 1, 2
//
//  hacks into numerous places to allow:
//	--'normal'+'desert' trees in desert tiles (bit 0)
//	--'normal'+'desert' to REGROW in the desert (bit 0)
//	--fields to be planted in the desert (bit 0)
//	--fields to have a 'height' (bounding box) (bit 2)
//	--pavement(+ lights/trees) in 'big' desert towns (bit 1)
//-------------------------------------------------------

#include <std.inc>

extern grfmodflags, getdesertmap, addgroundsprite, addsprite, invalidatetile


//-----------------------------------------------------------------------------------
global addtreesindesert
addtreesindesert:
	cmp	al, 0
	jz	.checknormal	; normal land
	cmp	al, 1
	jz	.checkdesert	; desert
	xor	ch, ch
	imul	cx, 7
	shr	cx, 8
	add	cl, 14h
	pop	eax
	retn
	
.checknormal:
	test 	byte [grfmodflags],1
	jz	.plantnormaltrees
	jmp	short .planttreeindesertandnormal

.checkdesert:
	test 	byte [grfmodflags],1
	jz	.plantdeserttrees

.planttreeindesertandnormal:
	xor	ch, ch			//normal land [and now desert!]
	imul	cx, 4h			//specify the upper and lower range of the tree IDs
	shr	cx, 8
	add	cl, 1Bh
	pop	eax
	retn
	
.plantnormaltrees:			//original code follows [for use when this is all disabled]
	xor	ch, ch			// normal land
	imul	cx, 4
	shr	cx, 8
	add	cl, 1Ch
	pop	eax
	retn

.plantdeserttrees:
	cmp	cl, 0Ch			// desert
	ja	.plantnuttin
	mov	cx, 1Bh
	pop	eax
	retn

.plantnuttin:
	mov	cx, 0FFFFh
	pop	eax
	retn

//-----------------------------------------------------------------------------------
global plantmoretreesindesert
plantmoretreesindesert:
	call	[getdesertmap]
	test 	byte [grfmodflags], 1
	jz	.runnormal
	mov	al, 0
.runnormal:
	retn
//-----------------------------------------------------------------------------------

exported treespreadindesert
	mov	al,[landscape5(bx)]	// overwritten
	and	al,0x1c			// ditto
	cmp	al,0x14
	jne	.nodesert
	test	byte [grfmodflags], 1
	jz	.runnormal
	mov	al, 0x10		// mimic snowy land for deserts - the code will work for both snowy and desert trees
.nodesert:
.runnormal:
	ret

//-----------------------------------------------------------------------------------	
global keepfieldsinthedesert
keepfieldsinthedesert:

	call	[getdesertmap]
	test 	byte [grfmodflags], 1
	jz	.killfieldsindesert
	cmp	dh, 07h			//special case.. we don't want "rough land tiles" in our deserts...
	jnz	.donttrashvalue
	cmp	al, 1
	jnz	.donttrashvalue
	mov	byte [landscape5(bx)], 17h
	mov	dh, 17h
	
.donttrashvalue:
	and	dh, 05h
	jmp short .returntoclass0proc	//sorry, this method is nasty, but i needed a pointer to return
					//past the next hack (since keepfields..2 is patched in a few bytes later)

.killfieldsindesert:
	and	dh, 1Ch

.returntoclass0proc:
	retn
//-----------------------------------------------------------------------------------

//-----------------------------------------------------------------------------------
global keepfieldsinthedesert2
keepfieldsinthedesert2:
	test 	byte [grfmodflags], 1		//normal code said if tile=normal,desert
	jz	.dontplantfieldsindesert	//just REVERT, don't care.
	cmp	dh, 05h				//now we set a new bit mask of 05 to take in 0F as well
	jz	.exitthisreality
	mov	byte [landscape5(bx)], 15h	//15h = partial desert.
	jmp	short .continuerefreshing

.dontplantfieldsindesert:
	cmp	dh, 14h				//bitmask 14 only skipped for 15,17 (ie. no process, just continue)
	jz	.exitthisreality
	mov	byte [landscape5(bx)], 15h

.continuerefreshing:
	push	ebx
	rol	bx, 4
	mov	ax, bx
	mov	cx, bx
	rol	cx, 8
	and	ax, 0FF0h
	and	cx, 0FF0h
	call	[invalidatetile]
	pop	ebx

.exitthisreality:
	retn
//-----------------------------------------------------------------------------------


//-----------------------------------------------------------------------------------
global keepfieldsinthedesert3
keepfieldsinthedesert3:
	test 	byte [grfmodflags], 1		//this is just a hack to tie it into
	jz	.dontplantfieldsindesert	//the above function for the desert tiles
	cmp	dh, 05h
	jz	keepfieldsinthedesert2.exitthisreality
	mov	byte [landscape5(bx)], 17h
	jmp short keepfieldsinthedesert2.continuerefreshing

.dontplantfieldsindesert:
	cmp	dh, 14h
	jz	keepfieldsinthedesert2.exitthisreality
	mov	byte [landscape5(bx)], 17h
	jmp short keepfieldsinthedesert2.continuerefreshing
//-----------------------------------------------------------------------------------


//-----------------------------------------------------------------------------------
global addgroundspritewithbounds
addgroundspritewithbounds:
	add	ebx, esi
	test 	byte [grfmodflags], 4
	jz	.dontchangeboundingbox
	
	push	di			//remember old vals..
	push	si
	mov	di, 10h			//
	mov	si, 10h			// --> sets up bounding box.
	mov	dh, 1h			//
	push	ebp
	call	[addsprite]		//this used to be addgroundsprite which doesnt
	pop	ebp			//care for bounding boxen
	pop	si
	pop	di			//put em back!
	retn
	
.dontchangeboundingbox:
	call	[addgroundsprite]	//do normal, old code.
	retn
//-----------------------------------------------------------------------------------

//-----------------------------------------------------------------------------------
global allowpavementindesert
allowpavementindesert:
	je	.normalpavement
	add	bx, 13h			//shift the sprite pointer +13 (grass->barE)
	test 	byte [grfmodflags], 2
	jz	.dontapplyfilter
	cmp	dh, 1
	jbe	.dontapplyfilter
	sub	bx, 13h			//shift back to concrete... IF dh = 1 or something
	add	bx, 0FFEDh		//this is the command that gives pavement... 
	jmp short .dontapplyfilter	//skip normal code.
	
.normalpavement:			//normal code.
	cmp	dh, 1
	jbe	.dontapplyfilter
	add	bx, 0FFEDh

.dontapplyfilter:
	retn
//-----------------------------------------------------------------------------------
global changedesertlevelcrossings
changedesertlevelcrossings:
	test	byte [landscape3+esi*2+1],80h
	jz	.segment2
	
	mov	dh, [landscape2+esi]
	and	dh, 7
	cmp	dh, 6
	jnz	.dontmoveone
	mov	dh, 1
.dontmoveone:
	or	dh, dh
	cmp	dh, 1
	jbe	.dontapplyfilter
	add	bx, 4
	jmp short .finalise

.dontapplyfilter:
	add	bx, 8
	jmp short .finalise

.segment2:
	mov	dh, [landscape2+esi]
	and	dh, 7
	jnz	.segment3
	and	ebx, 0FFFFh
	or	ebx, 3178000h
.segment3:
	cmp	dh, 1
	jbe	.finalise
	add	bx, 4


.finalise:
	retn
//-----------------------------------------------------------------------------------
