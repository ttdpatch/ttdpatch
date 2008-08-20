#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>
#include <grfdef.inc>
#include <ptrvar.inc>
#include <op.inc>

begincodefragments

codefragment oldvehonbridge
	and esi,0xf0

codefragment newvehonbridge
	icall vehonbridge
	setfragmentsize 9

codefragment findwaRailBridgeNames
	dw 501Fh,5020h

codefragment findtemporarybridgelists, -16
	xor al, al
	mov di, -1

codefragment oldbridgelistcount, 2
	inc al
	cmp al, 0x0B
	db 0x72	// jb ...
		
codefragment newbridgelistcount
	cmp al, NNEWBRIDGES
	
	
codefragment oldbridgelistpasstype
	shl al, 4
	or bh, al
	
codefragment_call newbridgelistpasstype,bridgelistpasstype,5
	
codefragment oldcreatebridgeaccesstypeforyear, -22
	ja $+2-55
	mov ax, di
	sub al, dl

codefragment newcreatebridgeaccesstypeforyear
	extern createbridgeaccesstypeforyear
	icall createbridgeaccesstypeforyear
	setfragmentsize 22
	jc $+2-55

codefragment oldcreatebridgecalcecost, -16
	shl eax, 0x18
	mul edx
	mov ebx, edx
	
codefragment newcreatebridgecalcecost
	extern tempbridgetypenew
	movzx ebx, byte [tempbridgetypenew]
	setfragmentsize 10

endcodefragments

ext_frag findvariableaccess
extern variabletofind

exported patchnewbridges
	patchcode vehonbridge
	mov word [edi+lastediadj-74],0x368d	// 2-byte nop
	
	extern waRailBridgeNames, bridgerailnames, bridgeroadnames
	storeaddress waRailBridgeNames
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
	extern bridgespecificpropertiesttd
	mov edi, [bridgespecificpropertiesttd]
	
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

	
// find the temporary tables holding bridge list while building

	// rail lists
	extern temprailbridgelist, temprailbridgecostlist
	stringaddress findtemporarybridgelists,1,2
	
	mov edi, [edi]
	mov [variabletofind], edi
	multipatchcode findvariableaccess, , 4, {mov dword [edi], temprailbridgelist}
	
	add dword [variabletofind], 11
	multipatchcode findvariableaccess, , 2, {mov dword [edi], temprailbridgecostlist}
	
	// road lists
	extern temproadbridgelist, temproadbridgecostlist
	stringaddress findtemporarybridgelists,2,2
	
	mov edi, [edi]
	mov [variabletofind], edi
	multipatchcode findvariableaccess, , 4, {mov dword [edi], temproadbridgelist}
	
	add dword [variabletofind], 11
	multipatchcode findvariableaccess, , 2, {mov dword [edi], temproadbridgecostlist}

	
	
	extcall bridgeresettodefaults	// so grfs can be successfully loaded
	
	multipatchcode oldbridgelistcount, newbridgelistcount, 2
	
	multipatchcode oldbridgelistpasstype,newbridgelistpasstype, 4

	patchcode createbridgeaccesstypeforyear
	
	stringaddress oldcreatebridgecalcecost
	
	patchcode createbridgecalcecost
	
	
	mov eax, [opclass(9)]
	mov eax, [eax+op.ActionHandler]
	mov edi, [eax+9]
	mov eax, [edi+1*4]
	extern oldclass9createbridgenew, createbridgenew
	
	mov dword [oldclass9createbridgenew], eax
	mov dword [edi+1*4], createbridgenew
	ret
