#include <defs.inc>
#include <frag_mac.inc>


extern isengine
extern railvehspriteofs


global patchwaggoncheck
patchwaggoncheck:
	patchcode oldchecknewtrainisengine2,newchecknewtrainisengine2,1,1
	// this must be patched if multihead is set OR the waggon base IDs are modified
	patchcode oldiswaggontypea,newchecknewtrainisengine,1,2
	// the test we replace appears twice in the depot window handler,
	// so we patch both occurences even though the second one isn't required for multihead
	patchcode oldiswaggontypea,newiswaggontypea,1,1	// (don't use newchecknewtrainisengine here!)

	patchcode oldselliswaggon,newselliswaggon,1,1
	patchcode oldaisellnextwagon,newaisellnextwagon

	storeaddresspointer oldattachwaggon,1,1,railvehspriteofs,0,3
	storefragment newattachwaggon
	ret


	// allow many changes to the railway vehicle set
	// e.g. different numbers and order of railroad/monorail/maglev engines and waggons

begincodefragments

codefragment oldchecknewtrainisengine2,5
	mov edx,ebx
	shr edx,8

codefragment newchecknewtrainisengine2
	call runindex(checknewtrainisengine2)
	setfragmentsize 9,1

codefragment oldiswaggontypea
	db 66h,3bh,1ch,45h	// cmp bx,[eax*2+offset32]

codefragment newchecknewtrainisengine
	call runindex(checknewtrainisengine)
	setfragmentsize 8,1

codefragment newiswaggontypea
	bt [isengine],bx

codefragment oldselliswaggon
	cmp bp,byte 0x1b

codefragment newselliswaggon
	call runindex(selliswagon)
	jc newselliswaggon_start+20
	jmp newselliswaggon_start+42

codefragment oldaisellnextwagon
	mov dx,[esi]
	cmp dx,byte -1

codefragment newaisellnextwagon
	call runindex(aisellnextwagon)
	setfragmentsize 7

codefragment oldattachwaggon,4
	movzx esi,byte [edi+veh.spritetype]

codefragment newattachwaggon
	call runindex(attachwaggon)
	setfragmentsize 8


endcodefragments
