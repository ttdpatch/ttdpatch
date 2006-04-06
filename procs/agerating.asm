#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc newagerating, patchagerating

patchagerating:
	patchcode oldsetagerating,newsetagerating,1,1
	ret



begincodefragments

codefragment oldsetagerating,4
	mov al,[byte ebx+esi+0x23]

// The new code is smaller than the old one, so I din't make a runindex call for it.
// The old code gave a maximum of 33 points, we redistribute it to be more fair:
// vehicles newer than five years get maximum, and lose two points per every year
// after the fifth, until they get no increase at all after the age of 21 years.
//
// In: al: age of the last vehicle entering the station for this cargo
//	 dx: cargo rating so far
//
// Out: dx: adjusted rating
//
// Safe: ax, ???
codefragment newsetagerating
	cmp al,21
	ja short .end
	add dx,33
	sub al,5
	jbe .end
	shl al,1
	xor ah,ah
	sub dx,ax
	setfragmentsize 24
.end:


endcodefragments
