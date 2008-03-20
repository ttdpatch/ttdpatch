#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>
#include <ptrvar.inc>

patchproc onewayroads, patchonewayroads


extern Class2DrawLandOneWay,Class2DrawLandOneWay.origfn,FailIsRoadPieceBuild
extern GetClass2RouteMap,RVGetRouteOvertakeing,newgraphicssetsenabled
extern roadroutetable
extern oldclass2roadconstrhandler, Class2RoadConstrHandler

begincodefragments

codefragment oldroadroutemapreturn, 8
	cmp ah, 6
	jnb $+2+0x0C
	and eax, 0Fh

codefragment olddrawgroundspriteroad, 9
	cmp dh, 1
	jbe $+2+0x04
	add bx, byte -19

codefragment oldfailisroadpiecebuild, 6
	and dl, dh
	db 0x38, 0xFA // cmp dl, bh
	pop bx

codefragment findrvgetrouteovertakeing, 5
	mov ax, 2
	push esi
	db 0xE8


endcodefragments


patchonewayroads:
	stringaddress oldroadroutemapreturn
	mov eax, [edi+2]
	mov [roadroutetable], eax
	storefunctionjump GetClass2RouteMap

	stringaddress olddrawgroundspriteroad
	chainfunction Class2DrawLandOneWay,.origfn, 1

	stringaddress oldfailisroadpiecebuild
	changereltarget 2, addr(FailIsRoadPieceBuild)

	stringaddress findrvgetrouteovertakeing,1,2
	storefunctioncall RVGetRouteOvertakeing

	stringaddress findrvgetrouteovertakeing,1,0
	storefunctioncall RVGetRouteOvertakeing

	or byte [newgraphicssetsenabled+1],1 << (9-8)

	mov eax, [ophandler+0x2*8]
	mov eax, [eax+1*4]
	mov edi, [eax+3]
	mov eax, [edi+1*4]
	mov dword [oldclass2roadconstrhandler], eax
	mov dword [edi+1*4], addr(Class2RoadConstrHandler)

	ret
