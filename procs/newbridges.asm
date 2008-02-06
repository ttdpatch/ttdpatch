#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>
#include <grfdef.inc>

patchproc newbridges, patchnewbridges

begincodefragments

codefragment oldvehonbridge
	and esi,0xf0

codefragment newvehonbridge
	icall vehonbridge
	setfragmentsize 9

codefragment findpaBridgeNames
	dw 5012h,5013h
codefragment findpaRailBridgeNames
	dw 501Fh,5020h

endcodefragments

ext_frag findvariableaccess
extern variabletofind

patchnewbridges:
	patchcode vehonbridge
	mov word [edi+lastediadj-74],0x368d	// 2-byte nop

	extern paBridgeNames, paRailBridgeNames, waRailBridgeNames
	storeaddress paBridgeNames
	mov [variabletofind], edi
	extern waBridgeNames
	multipatchcode findvariableaccess, , 2, {mov DWORD [edi], waBridgeNames}
	
	storeaddress paRailBridgeNames
	sub edi, 8
	mov eax, waRailBridgeNames
	stosd
	add eax, NBRIDGES*2
	stosd
	ret
