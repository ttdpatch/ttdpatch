
	//
	// special functions to handle bridge properties
	//
	// in:	eax=special prop-num
	//	ebx=offset (bridgeid)
	//	ecx=num-info
	//	edx->feature specific data offset
	//	esi=>data
	// out:	esi=>after data
	//	carry clear if successful
	//	carry set if error, then ax=error message
	// safe:eax ebx ecx edx edi

#include <std.inc>
#include <textdef.inc>
#include <grfdef.inc>

extern bridgespritetables


// Byte Data: TableID, Numtables, Data (80h*Numtables), [ TableID, Numtables, Data, ... ]
global alterbridgespritetable
alterbridgespritetable:
	mov edx, dword [bridgespritetables]
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

	// prop 0F: long introduction date
exported longintrodatebridges
	extern specificpropertybase
	mov edi,[specificpropertybase+6*4]
	add edi,ebx

.next:
	lodsd
	sub eax,701265	// 1920
	jge .notbefore

	xor eax,eax

.notbefore:
	cmp eax,93503	// 256 years minus one day
	jb .ok

	mov eax,93503

.ok:
	extern getfullymd
	call [getfullymd]
	stosb
	loop .next
	clc
	ret
