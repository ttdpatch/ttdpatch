#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>
#include <ptrvar.inc>
#include <textdef.inc>
#include <misc.inc>
#include <vehtype.inc>

extern rvCollisionPointX, rvCollisionPointY

patchproc shortrvs, patchshortenedrvs

begincodefragments
	codefragment oldSetVehicleBoundsX, -26
		neg	ax
		cmp	ax, dx

	codefragment oldSetVehicleBoundsY, -25
		neg	cx
		cmp	cx, dx

	codefragment newSetVehicleBoundsX
		icall adjustVehicleOffsetsForShortVehiclesX
		setfragmentsize 8

	codefragment newSetVehicleBoundsY
		icall adjustVehicleOffsetsForShortVehiclesY
endcodefragments

patchshortenedrvs:
	stringaddress oldSetVehicleBoundsX, 1, 1
	mov	edi, [edi+4]
	mov	dword [rvCollisionPointX], edi
	patchcode oldSetVehicleBoundsX, newSetVehicleBoundsX, 1, 1
	stringaddress oldSetVehicleBoundsY, 1, 1
	mov	edi, [edi+2]
	mov	dword [rvCollisionPointY], edi
	patchcode oldSetVehicleBoundsY, newSetVehicleBoundsY, 1, 1
	retn
