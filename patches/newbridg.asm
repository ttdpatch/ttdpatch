
	//
	// special functions to handle bridge properties
	//
	// in:	eax=special prop-num
	//	ebx=offset (bridgeid)
	//	ecx=num-info
	//	
	//	esi=>data
	// out:	esi=>after data
	//	carry clear if successful
	//	carry set if error, then ax=error message
	// safe:eax ebx ecx edx edi

#include <std.inc>
#include <flags.inc>
#include <textdef.inc>
#include <grfdef.inc>

extern patchflags

extern bridgespritetablesttd

uvard bridgespritetables, NNEWBRIDGES
uvard bridgespritetablestables, NNEWBRIDGES*7

uvarb bridgeintrodate, NNEWBRIDGES
uvarb bridgeminlength, NNEWBRIDGES
uvarb bridgemaxlength, NNEWBRIDGES
uvarb bridgecostfactor, NNEWBRIDGES
uvarw bridgemaxspeed, NNEWBRIDGES

uvard bridgeicons, NNEWBRIDGES

uvarw bridgenames, NNEWBRIDGES
uvarw bridgerailnames, NNEWBRIDGES
uvarw bridgeroadnames, NNEWBRIDGES

extern bridgeflags
	
exported bridgeresettodefaults
	testmultiflags newbridges
	jnz .setuptables
	ret
	
.setuptables:
	pusha

// 
	mov edx, NBRIDGES
	
	mov esi, [specificpropertybase+6*4]
	mov edi, bridgeintrodate
	mov ecx, edx
	rep movsb
	
	mov edi, bridgeminlength
	mov ecx, edx
	rep movsb
	
	mov edi, bridgemaxlength
	mov ecx, edx
	rep movsb

// bridge cost factor
	mov edi, bridgecostfactor
	mov ecx, edx
	rep movsb

// bridge speeds
	mov esi, bridgespeedsttd
	mov edi, bridgemaxspeed
	mov ecx, edx
	rep movsb
// bridge icons
	mov esi, bridgeiconsttd
	mov edi, bridgeicons
	mov ecx, edx
	rep movsd
	
// bridge names
	mov esi, bridgenamesttd
	mov edi, bridgenames
	mov ecx, NBRIDGES
	rep movsw
	
	mov eax, ourtext(unnamedairporttype)
	mov cl, NNEWBRIDGES-NBRIDGES
	rep stosw

// rail bridge names	
	mov esi, 0
ovar paRailBridgeNames
	mov edi, bridgerailnames
	mov cl, NBRIDGES
	rep movsw
	
	mov eax, ourtext(unnamedairporttype)
	mov cl, NNEWBRIDGES-NBRIDGES
	rep stosw

// road bridge names
	mov esi, [paRailBridgeNames]
	add esi, NBRIDGES*2
	mov edi, bridgeroadnames
	mov cl, NBRIDGES
	rep movsw
	
	mov eax, ourtext(unnamedairporttype)
	mov cl, NNEWBRIDGES-NBRIDGES
	rep stosw

	
// setup bridge sprite tables
	mov esi, [bridgespritetablesttd]
	add esi, NBRIDGES*4
	
	mov edi, bridgespritetablestables
	mov ecx, NBRIDGES*7	// 7 dword entries per bridge
	rep movsd
	
	mov ecx, NNEWBRIDGES
	mov eax, bridgespritetablestables
	mov edi, bridgespritetables
.nextentry:
	stosd	// create pointer list
	add eax, 7*4
	loop .nextentry
	

	testmultiflags longerbridges
	jz .notlonger

	mov byte [bridgemaxlength],127
	mov byte [bridgemaxlength+4],127
	mov byte [bridgemaxlength+5],127
	mov byte [bridgemaxlength+0xa],127

.notlonger:
	popa
	ret


// Byte Data: TableID, Numtables, Data (80h*Numtables), [ TableID, Numtables, Data, ... ]
global alterbridgespritetable
alterbridgespritetable:
	mov edx, bridgespritetables
	lea edx, [edx+ebx*4]

.nextbridgeid:
	push ecx

	xor eax, eax
	lodsb				// Table ID
	cmp al, 6			// 0 till 6
	ja .bad
	mov edi, eax

	lodsb				// Num Tables to overwrite
	cmp al, 7			// max 7
	ja .bad

	mov ecx, eax
	jecxz .bad

	add eax, edi
	cmp eax, 7
	ja .bad

	mov eax, [edx]	// Current BridgeID Tables
	lea eax, [eax+edi*4]	// Table ID

.nextbridgespritetable:
	mov dword [eax], esi 
	sub esi,byte -80h
	add eax, 4
	loop .nextbridgespritetable
	
	pop ecx
	add edx, 4
	loop .nextbridgeid
	clc	// no error
	ret
.bad:
	pop ecx
	mov eax,(INVSP_BADID<<16)+ourtext(invalidsprite)
	stc
	ret

	// prop 0F: long introduction year
exported longintrodatebridges
	extern specificpropertybase
	mov edi,[specificpropertybase+6*4]
	add edi,ebx

.next:
	lodsd
	sub eax,1920
	jge .notbefore

	xor eax,eax

.notbefore:
	cmp eax,255
	jb .ok

	mov al,255

.ok:
	stosb
	loop .next
	clc
	ret
