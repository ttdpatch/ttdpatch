#include <defs.inc>
#include <frag_mac.inc>


extern patchflags

#include <textdef.inc>

ext_frag newshowvehinfo

global patchrvinfowindow

begincodefragments

codefragment oldrvpurchaseinfo
	push esi
	mov bx,0x9008

codefragment newrvpurchaseinfo
	call runindex(showrvweightpurchase)

codefragment oldinitrvpurchasewindow,-5
	mov dx,0x88
	db 0xbd,5	// mov ebp,5


endcodefragments

patchrvinfowindow:
	xor ebx,ebx
	stringaddress oldrvpurchaseinfo
	testmultiflags rvpower
	jz .notrvpower

	mov ebx,0xa000a
	sub edi,6
	storefragment newrvpurchaseinfo
	mov word [edi+lastediadj+9],ourtext(rvweightpurchasewindow)

.notrvpower:
	testmultiflags newrvs
	jz .notnewrvs
	inc edi
	storefragment newshowvehinfo
	add ebx,(50 << 16)+50

.notnewrvs:
	// make both windows larger by 10/50/60 pixels
	stringaddress oldinitrvpurchasewindow,1,2
	add [edi+3],bl
	stringaddress oldinitrvpurchasewindow,2,2
	mov eax,[edi+22]
	add [edi+3],bl
	add [eax+0x38],bl
	add [eax+0x42],ebx
	add [eax+0x4e],ebx
	ret
