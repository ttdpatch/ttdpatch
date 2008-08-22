
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
#include <grf.inc>

extern patchflags

uvard bridgespecificpropertiesttd, 1
#if 0
struct oldbridgedata
	.bridgeintrodate: resb NBRIDGES
	.bridgeminlength: resb NBRIDGES
	.bridgemaxlength: resb NBRIDGES
	.bridgecostfactor: resb NBRIDGES
endstruc
#endif
uvard bridgespritetablesttd, 1


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

// ID Management
uvard bridgeaction3, NNEWBRIDGES
uvarb bridgeloaded, (NNEWBRIDGES+7)/8

uvarb curgrfbridgelist, NNEWBRIDGES	// special handling

struc persbridgedata
	.grfid:	resd 1
	.setid:	resb 1
	.unused: resb 3
endstruc

uvard bridgepersistentdata, NNEWBRIDGES*2

uvarb bridgeflags, NNEWBRIDGES
uvarb bridgefallbacktyp, NNEWBRIDGES


uvard bridge2spritedata1, 4*7*8	// 7 tables (but only 4 used) * 8 route types with 4 entries each
uvard bridge2spritedata2,  4*7*8


exported bridgeresettodefaults
	testmultiflags newbridges
	jnz .setuptables
	ret
	
.setuptables:
	pusha
	
	// setup bridge sprite tables to table tables
	mov ecx, NNEWBRIDGES
	mov eax, bridgespritetablestables
	mov edi, bridgespritetables
.nextsetbaseentry:
	stosd	// create pointer list
	add eax, 7*4
	loop .nextsetbaseentry
	
// now loop over all bridges and reset the properties	
	xor edx, edx 
.nextentry:
	call bridgeslotresettodefault
	inc edx
	cmp edx, NNEWBRIDGES
	jb .nextentry
	
	popa
	ret

#if 0
	pusha
	mov edx, NBRIDGES
	
	mov esi, [bridgespecificpropertiesttd]
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
	rep movsw
	
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

	
// setup bridge sprite tables to table tables
	mov ecx, NNEWBRIDGES
	mov eax, bridgespritetablestables
	mov edi, bridgespritetables
.nextentry:
	stosd	// create pointer list
	add eax, 7*4
	loop .nextentry

// resets for each bridge the 7 tables
	xor ebx, ebx
.nextresettable:

	mov esi, [bridgespritetablesttd]
	mov esi, [esi+ebx*4]
	
	mov edi, bridgespritetables
	mov edi, [edi+ebx*4]
	
	mov ecx, 7
	rep movsd
	
	inc ebx
	cmp ebx, NBRIDGES
	jle .nextresettable
.variousos:
// reset various variables with different sizes
	mov edx, NNEWBRIDGES
	xor eax, eax
%macro resetbridgevarzero 2
	mov edi,%2
	mov ecx, edx
	rep stos%1
%endmacro

	resetbridgevarzero d,bridgeaction3
	
	testmultiflags longerbridges
	jz .notlonger

	mov byte [bridgemaxlength],127
	mov byte [bridgemaxlength+4],127
	mov byte [bridgemaxlength+5],127
	mov byte [bridgemaxlength+0xa],127

.notlonger:
	popa
	ret
#endif
	
// Reset one bridge slot to default, won't reset the grf gameid mapping however
// edx = slot
bridgeslotresettodefault:
	mov dword [bridgeaction3+edx*4], 0
	mov byte [bridgeflags+edx], 0
	mov byte [bridgefallbacktyp+edx], 0
	
	
	cmp edx, NBRIDGES
	jb near .old
	
	cmp edx, 0x0B
	je near .tubulargolden
	cmp edx, 0x0C
	je near .tubulargray
.new:
	push eax
	mov byte [bridgeintrodate+edx], 0
	mov byte [bridgeminlength+edx], 0
	mov byte [bridgemaxlength+edx], 0	
	mov byte [bridgecostfactor+edx], 0

	mov word [bridgemaxspeed+edx*2], dx
	
	mov ax, ourtext(grftextnotfound)
	mov word [bridgenames+edx*2], ax
	
	mov word [bridgerailnames+edx*2], ax
	mov word [bridgeroadnames+edx*2], ax
	
	mov dword [bridgeicons+edx*4], 0
	btr [bridgeloaded], edx	// disable slot
	pop eax
	ret
	
.tubulargolden:
	pusha
	mov byte [bridgeintrodate+edx], 2005-1920
	mov byte [bridgeminlength+edx], 2
	mov byte [bridgemaxlength+edx], 127
	mov byte [bridgecostfactor+edx], 255

	mov word [bridgemaxspeed+edx*2], 370
	
	mov word [bridgenames+edx*2], 0x5014
	
	mov word [bridgerailnames+edx*2], 0x5027
	mov word [bridgeroadnames+edx*2], 0x5028

	mov esi, [bridgespritetablesttd]
	mov ebp, [esi+0x0A*4]
	
	mov edi, bridge2spritedata1
	mov ebx, 801 << 16
	or ebx, 1<<15
	mov esi, [ebp]
	call .recolorbridgetable
	mov esi, [ebp+4]
	call .recolorbridgetable
	mov esi, [ebp+8]
	call .recolorbridgetable
	// endings
	mov ebx, 0
	mov esi, [ebp+6*4]
	call .recolorbridgetable
	
 
	mov edi, bridgespritetables
	mov edi, [edi+edx*4]
	mov eax, bridge2spritedata1
	stosd
	add eax, 0x80
	stosd
	add eax, 0x80
	stosd
	stosd
	stosd
	stosd
	add eax, 0x80
	stosd

	mov dword [bridgeicons+edx*4], 2600+0x3218000
	bts [bridgeloaded], edx
	popa
	ret

.tubulargray:
	pusha
	mov byte [bridgeintrodate+edx], 2010-1920
	mov byte [bridgeminlength+edx], 2
	mov byte [bridgemaxlength+edx], 127
	mov byte [bridgecostfactor+edx], 255

	mov word [bridgemaxspeed+edx*2], 400
	
	mov word [bridgenames+edx*2], 0x5014
	
	mov word [bridgerailnames+edx*2], 0x5027
	mov word [bridgeroadnames+edx*2], 0x5028

	mov esi, [bridgespritetablesttd]
	mov ebp, [esi+0x0A*4]
	
	mov edi, bridge2spritedata2
	mov ebx, 803 << 16
	or ebx, 1<<15
	mov esi, [ebp]
	call .recolorbridgetable
	mov esi, [ebp+4]
	call .recolorbridgetable
	mov esi, [ebp+8]
	call .recolorbridgetable
	// endings
	mov esi, [ebp+6*4]
	call .recolorbridgetable
	
	
	mov edi, bridgespritetables
	mov edi, [edi+edx*4]
	mov eax, bridge2spritedata2
	stosd
	add eax, 0x80
	stosd
	add eax, 0x80
	stosd
	stosd
	stosd
	stosd
	add eax, 0x80
	stosd
	
	mov dword [bridgeicons+edx*4], 2600+0x3238000
	bts [bridgeloaded], edx
	popa
	ret

.old:
	pusha
	mov esi, [bridgespecificpropertiesttd]
	add esi, edx
	mov al, [esi]
	mov byte [bridgeintrodate+edx], al
	mov al, [esi+NBRIDGES]
	mov byte [bridgeminlength+edx], al
	mov al, [esi+NBRIDGES*2]
	mov byte [bridgemaxlength+edx], al
	mov al, [esi+NBRIDGES*3]
	mov byte [bridgecostfactor+edx], al

	mov ax, [bridgespeedsttd+edx*2]
	mov word [bridgemaxspeed+edx*2], ax
	
	mov eax, dword [bridgeiconsttd+edx*4]
	mov dword [bridgeicons+edx*4], eax
	
	mov ax, [bridgenamesttd+edx*2]
	mov word [bridgenames+edx*2], ax
// rail bridge names	
	mov esi, [waRailBridgeNames]
	mov ax, [esi+edx*2]
	mov [bridgerailnames+edx*2], ax

// road bridge names
	mov ax, [esi+edx*2+NBRIDGES*2]
	mov [bridgeroadnames+edx*2], ax
	
	testmultiflags longerbridges
	jz .notlonger

	cmp edx, 0
	je .longer
	cmp edx, 4
	je .longer
	cmp edx, 5
	je .longer
	cmp edx, 0xa
	jne .notlonger

.longer:
	mov byte [bridgemaxlength+edx], 127

.notlonger:

// restore the sprite tables for this bridge
	mov esi, [bridgespritetablesttd]
	mov esi, [esi+edx*4]
	
	mov edi, bridgespritetables
	mov edi, [edi+edx*4]
	
	mov ecx, 7
	rep movsd
	
	bts [bridgeloaded], edx
	popa
	ret

// in:
//  esi = source
//  edi = dest
//  ebx = recolor table << 16
.recolorbridgetable:
	mov ecx, 32	// 8*4 entries*4 
.settable:
	lodsd
	and eax, 0xFFFF
	cmp eax, 0
	je .emptytableslot
	or eax, ebx
.emptytableslot:
	stosd
	loop .settable
	ret

	
uvard waRailBridgeNames, 1

	
exported postbridgeapply
	pusha
	testmultiflags newbridges
	jnz .newdata
	
// make sure at least one bridge is available before 1930, when newbridges is off
	mov edi, [bridgespecificpropertiesttd] 

	jmp .setupavailyears
.newdata:

// make sure at least one of the first bridges is available before 1930
	mov edi, bridgeintrodate
	
.setupavailyears:
	mov ecx, NBRIDGES 
	xor eax, eax
	repne scasb	// is any bridge available from 1920 up? 
	je .skipbridgedate 
	mov byte [edi-11], 0     // no -- set wooden bridge's start year to 1920 
.skipbridgedate:
	popa
	ret
	
// Special handling for bridge grf translation table, to point to the first default entries
exported bridgeresetbeforegrf
	pusha
	xor eax, eax
	mov edi, curgrfbridgelist
	mov ecx, NNEWBRIDGES
	rep stosb
	
	xor eax, eax
	mov edi, curgrfbridgelist
.nextslot:
	mov byte [edi], al
	inc eax
	inc edi
	cmp eax, 0x0D // NBRIDGES
	jb .nextslot
	popa
	ret

// Clean the grf+datatid to gameid mapping and any other persistent data for each gameid slot
exported clearbridgepersdata
	pusha
	xor eax, eax
	mov edi, bridgepersistentdata
	mov ecx, NNEWBRIDGES*2
	rep stosd
	popa
	ret


//	Bridge GameID recycling
//	As we don't have any fancy way (usage count of a bridge) we try to find for each gameid a proper action3
//	if we can't find an action3 the grf hasn't loaded or had an error, so we will reset the mapping to nothing
exported bridgerecycleunusedids
	popa
	xor ecx, ecx
.nextslot:
	bt [bridgeloaded], ecx
	jc .slotused
//	cmp dword [bridgeaction3+ecx*4], 0
//	jne .slotused
	mov dword [bridgepersistentdata+ecx*8], 0
	mov dword [bridgepersistentdata+ecx*8+4], 0
.slotused:
	cmp ecx, NNEWBRIDGES
	jb .nextslot
	pusha
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
	mov edi, bridgeintrodate
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


// prop 00: failback type 
exported bridgesetfailback
.next:
	xor edx,edx
	mov dl,[curgrfbridgelist+ebx]		// Do we have a gameid yet?
	or dl,dl
	jnz near .alreadyhasoffset

	extern curspriteblock
	mov eax,[curspriteblock]
	mov eax,[eax+spriteblock.grfid]
	mov edx, NBRIDGES
	
	// Pass 1, try to find the right slot
.nextslot:
	cmp dword [bridgepersistentdata+edx*8+persbridgedata.grfid], 0
	je .emptyslot
	cmp [bridgepersistentdata+edx*8+persbridgedata.grfid], eax
	jne .wrongslot
	cmp [bridgepersistentdata+edx*8+persbridgedata.setid], bl
	je .foundslot
.wrongslot:
	inc edx
	cmp edx,NNEWBRIDGES
	jb .nextslot
	
	// Pass 2, try to find an empty slot
	
	mov edx, NBRIDGES
.nextslotfindempty:
	cmp dword [bridgepersistentdata+edx*8+persbridgedata.grfid], 0
	je .emptyslot
	inc edx
	cmp edx, NNEWBRIDGES
	jb .nextslotfindempty
	
	// no more room, we should display some meaningfull error message now
	CALLINT3
	
	mov ax, ourtext(invalidsprite)
	stc
	ret
	
.emptyslot:
	// reset bridge slot to defaults
	mov [bridgepersistentdata+edx*8+persbridgedata.grfid],eax
	mov dword [bridgepersistentdata+edx*8+4], 0
	mov [bridgepersistentdata+edx*8+persbridgedata.setid],bl

.foundslot:
	mov [curgrfbridgelist+ebx],dl

.alreadyhasoffset:

.doproperty:
	call bridgeslotresettodefault
	lodsb
	mov [bridgefallbacktyp+edx],al

	dec ecx
	jnz .next

	clc
	ret

	
// GUI 
uvarb temprailbridgelist, NNEWBRIDGES
uvarb temproadbridgelist, NNEWBRIDGES
uvard temprailbridgecostlist, NNEWBRIDGES
uvard temproadbridgecostlist, NNEWBRIDGES


// Building a Bridge
// DX = end XY
//	BH = bits 3..0: 0=railway, 2=road
//     	bits 7..4: bridge type
//	DI = track type if BH=0
// new: ebx = 31..16 = new type if bridge type is 0xF

uvarb tempbridgetypenew, 1
uvard oldclass9createbridgenew, 1
exported createbridgenew
	cmp bh, 0xF0
	jb .oldtype
	push eax
	mov eax, ebx
	shr eax, 16
	mov byte [tempbridgetypenew], al
	mov al, byte [bridgefallbacktyp+eax]
	shl al, 4
	and bh, 0x0F
	or bh, al
	pop eax
	jmp [oldclass9createbridgenew]
.oldtype:
	push eax
	mov al, bh
	and al, 0xF0
	shr al, 4
	mov byte [tempbridgetypenew], al
	pop eax
	jmp [oldclass9createbridgenew]
	
exported createbridgeaccesstypeforyear
	movzx ebp, byte [tempbridgetypenew]
	bt [bridgeloaded], ebp
	jnc .fail
	mov al, [bridgeintrodate+ebp]
	cmp al, byte [currentyear]
	ja .fail
.ok:
	clc
	ret
.fail:
	stc
	ret

	
// in al = bridge type
// bl = build flags
// out: ebx = bridge type+buildflags merged in new format
exported bridgelistpasstype
	and ebx, 0xFFF
	and eax, 0xFF
	cmp al, 0x0D
	jb .old
	shl eax, 16
	or ah, 0xF0
	or ebx, eax
	ret
.old:
	shl al, 4
	or bh, al
	ret
