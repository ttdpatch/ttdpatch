#include <defs.inc>
#include <frag_mac.inc>


extern drawstationtile
extern ttdstationspritelayout
extern drawstationimageinrailselectwin

ext_frag newgetstationtracktrl

global patchstationgraphics

begincodefragments

codefragment oldgetstationspriteset
	and ebp,byte 0xF
	imul ebp,byte 82

codefragment newgetstationspriteset
	call runindex(getnewstationsprite_noelrails)

codefragment olddisplaystationorient
	movzx eax,al
	imul eax,82

codefragment newdisplaystationorient
	call runindex(getstationselsprites)

codefragment newgetstationdisplayspritelayout
	call runindex(getstationdisplayspritelayout)
	setfragmentsize 7
#if 0
codefragment olddrawstationimageinrailselectwin, 10
	add cx, 39
	add dx, 42
	mov bl, 2

codefragment newdrawstationimageinrailselectwin
	icall drawstationimageinrailselectwin
	setfragmentsize 36
#endif

endcodefragments

patchstationgraphics:
	patchcode oldgetstationspriteset,newgetstationspriteset,1,1
	patchcode olddisplaystationorient,newdisplaystationorient,1,1

	add edi,lastediadj+22
	mov eax,[edi+3]
	mov [ttdstationspritelayout],eax
	storefragment newgetstationdisplayspritelayout

	mov byte [edi+lastediadj+25],0x7f

	add edi,lastediadj+50
	storefragment newgetstationtracktrl

	mov dword [getnewstationsprite_noelrails_indirect],addr(drawstationtile)

.notelectrified:
#if 0
	patchcode drawstationimageinrailselectwin
#endif
	ret
