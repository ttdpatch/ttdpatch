
#include <std.inc>

uvard pdaTempStationPtrsInCatchArea
uvard pbaTempStationIdxsInCatchArea
uvard addcargotostation
uvarb totaldistr

//dh and ch are station id's of the top two rated stations
//dl and cl are ratings of the stations
uvard tmpratingsum
global distributecargo
distributecargo:
	mov byte [totaldistr], 0
	push eax
	push ebx
	
	push ecx
	push edx
	
	movzx bx, ah
	
	movzx edx, dl
	movzx ecx, cl
	mov eax, ecx
	add ecx, edx
	// ecx == (A+B) *256
	mov [tmpratingsum], ecx
	imul dx
	shr eax, 8
	// ax = (A*B) *256
	sub ecx, eax
	// ecx == (A+B-AB) *256
	mov eax, ecx
	imul bx
	// eax == C(A+B-AB) *256
	

	pop edx
	pop ecx
	pop ebx
	push ecx
	push eax
	
	push ebx
	
	movzx ebx, dl
	movzx esi, dh
	mov edx, ebx
	imul edx
	// eax == C(A+B-AB)*A *256*256
	mov ebx, [tmpratingsum]
	xor edx, edx
	idiv ebx
	// eax = C(A+B-AB)*A*256 / (A+B)*256 *256 == C(A+B-AB)/[A/(A+B)] *256
	shr eax, 8
	// eax == what we need
	mov edx, esi
	imul si, 8Eh
	add esi, stationarray
	mov ah, al
	add byte [totaldistr], ah
	pop ebx
	call [addcargotostation]


	pop eax
	pop ecx

	push ebx

	movzx ebx, cl
	movzx esi, ch
	mov edx, ebx
	imul edx
	mov ebx, [tmpratingsum]
	xor edx, edx
	idiv ebx
	shr eax, 8
	mov edx, esi
	imul si, 8Eh
	add esi, stationarray
	mov ah, al
	add byte [totaldistr], ah
	pop ebx
	call [addcargotostation]


	pop eax

	mov al, [totaldistr]
	ret
