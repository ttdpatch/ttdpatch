#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>
#include <grfdef.inc>

begincodefragments

codefragment oldvehonbridge
	and esi,0xf0

codefragment newvehonbridge
	icall vehonbridge
	setfragmentsize 9

codefragment findpaRailBridgeNames
	dw 501Fh,5020h

endcodefragments

ext_frag findvariableaccess
extern variabletofind

exported patchnewbridges
	patchcode vehonbridge
	mov word [edi+lastediadj-74],0x368d	// 2-byte nop


	

	

	
	extern paRailBridgeNames, bridgerailnames, bridgeroadnames
	storeaddress paRailBridgeNames
	sub edi, 8
	mov eax, bridgerailnames
	stosd
	mov eax, bridgeroadnames
	stosd


// based on ttdvar	
	mov dword [variabletofind], bridgeiconsttd
	extern bridgeicons
	multipatchcode findvariableaccess, , 2, {mov DWORD [edi], bridgeicons}
	
	mov dword [variabletofind], bridgenamesttd
	extern bridgenames
	multipatchcode findvariableaccess, , 2, {mov DWORD [edi], bridgenames}

	mov dword [variabletofind], bridgespeedsttd
	extern bridgemaxspeed
	multipatchcode findvariableaccess, , 3, {mov DWORD [edi], bridgemaxspeed}
	
// based on specificpropertybase (set by dogeneralpatching)
	extern specificpropertybase
	mov edi, [specificpropertybase+6*4]
	
	extern bridgeintrodate
	mov [variabletofind], edi
	stringaddress findvariableaccess
	mov dword [edi], bridgeintrodate
	
	extern bridgeminlength
	add dword [variabletofind], NBRIDGES
	stringaddress findvariableaccess
	mov dword [edi], bridgeminlength
	
	extern bridgemaxlength
	add dword [variabletofind], NBRIDGES
	stringaddress findvariableaccess
	mov dword [edi], bridgemaxlength
	
	extern bridgecostfactor
	add dword [variabletofind], NBRIDGES
	stringaddress findvariableaccess
	mov dword [edi], bridgecostfactor
// the sprite table
	extern bridgespritetablesttd, bridgespritetables
	
	mov edi, [bridgespritetablesttd]
	mov [variabletofind], edi
	multipatchcode findvariableaccess, , 2, {mov DWORD [edi], bridgespritetables}

	extcall bridgeresettodefaults	// so grfs can be successfully loaded
	ret
