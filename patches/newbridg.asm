
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
	mov ax, ourtext(invalidsprite)
	stc
	ret
