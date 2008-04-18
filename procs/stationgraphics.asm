#include <defs.inc>
#include <frag_mac.inc>


extern drawstationtile
extern ttdstationspritelayout
extern drawstationimageinrailselectwin
extern ttdpatchstationspritelayout
extern paStationsNewLayouts

global patchstationgraphics

begincodefragments

codefragment_call newgetstationtracktrl, getstationtracktrl

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

codefragment olddrawstationimageinrailselectwin, 10
	add cx, 39
	add dx, 42
	mov bl, 2

codefragment newdrawstationimageinrailselectwin
	icall drawstationimageinrailselectwin
	setfragmentsize 36

endcodefragments

patchstationgraphics:
	patchcode oldgetstationspriteset,newgetstationspriteset,1,1
	patchcode olddisplaystationorient,newdisplaystationorient,1,1

	add edi,lastediadj+22
	mov eax,[edi+3]
	mov [ttdstationspritelayout],eax
	storefragment newgetstationdisplayspritelayout
	
	pusha
	push 256*4
	extcall malloccrit
	pop edi
	
	mov [ttdpatchstationspritelayout], edi
	mov esi, [ttdstationspritelayout]
	mov ecx, 0x53
	cld
	rep movsd
	mov esi, paStationsNewLayouts
	mov ecx, 8	// how many station layout we need to copy? 
	rep movsd
	popa
	
	mov byte [edi+lastediadj+25],0x7f

	add edi,lastediadj+50
	storefragment newgetstationtracktrl

	mov dword [getnewstationsprite_noelrails_indirect],addr(drawstationtile)

.notelectrified:
	patchcode drawstationimageinrailselectwin
	ret
