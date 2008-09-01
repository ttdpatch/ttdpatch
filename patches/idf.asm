#include <std.inc>
#include <flags.inc>
#include <proc.inc>
#include <idf.inc>
#include <grf.inc>

extern curspriteblock,grfstage

// creates a new gameid for a framework feature
// in:
// ebx = action based id
// edx = idf structure for the feature
// out:
// carry set = error, al = code why:  0 = already defined  1 = no more gameids free
// eax = gameid
// uses eax, edi
global idf_createnewgameid
proc idf_createnewgameid
	local gameid
	_enter
// now create a new gameid
	mov edi, [edx+idfsystem.curgrfidtogameidptr]
	movzx eax, word [edi+ebx*2]
	or ax,ax
	jnz .alreadyhasgameid
	mov edi, [edx+idfsystem.gameid_lastnumptr]
	movzx eax, word [edi]
	inc eax
	mov [%$gameid], eax
	cmp ax, word [edx+idfsystem.gameidcount]
	jb .foundgameid					// we still have gameids free
.toomany:
	mov eax, 1
	stc
	_ret
	
// reassign a gameid?
.alreadyhasgameid:
	mov eax, 0
	stc
	_ret

.foundgameid:
	// eax = gameid
	cmp byte [grfstage], 0
	je .dontrecord
	mov edi, [edx+idfsystem.gameid_lastnumptr]
	mov word [edi], ax							// and the new last index
.dontrecord:
	mov edi, [edx+idfsystem.curgrfidtogameidptr]
	mov word [edi+ebx*2], ax					// Record the new gameid
	
	mov edi, dword [edx+idfsystem.gameid_dataptr]	
	// reset the action3 for this slot	
	mov dword [edi+eax*idf_gameid_data_size+idf_gameid_data.act3info], 0	
	mov word [edi+eax*idf_gameid_data_size+idf_gameid_data.setid], bx
	
	//	call resetobjectgameidslot
	
	// resolve dataid to gameid mapping
	mov eax, [curspriteblock]
	mov eax, [eax+spriteblock.grfid]
	mov edi, dword [edx+idfsystem.dataid_dataptr]
	
	push ecx
	xor ecx, ecx
	
.finddataidslot:
	add edi, idf_dataid_data_size
	inc ecx
		
	cmp [edi+idf_dataid_data.grfid], eax
	jne .nextdataidslot

	cmp word [edi+idf_dataid_data.setid], bx
	je .founddateid

.nextdataidslot:
	cmp ecx, [edx+idfsystem.dataidcount]
	jb .finddataidslot
	jmp .done
	
.nomoredataids:
	pop ecx
	mov eax, 2
	stc
	_ret
	
.founddateid:
	movzx eax, word [%$gameid]
	mov edi, dword [edx+idfsystem.dataidtogameidptr]
	mov word [edi+ecx*2], ax
	mov edi, dword [edx+idfsystem.gameid_dataptr]
	mov word [edi+eax*idf_gameid_data_size+idf_gameid_data.dataid], cx
.done:
	mov eax, dword [%$gameid]
	pop ecx
	clc
	_ret
endproc


// in:
// ax = gameid
// out:
// ax = dataid or 0 if not possible
// edx = feature information struct
exported idf_getdataidbygameid
	movzx eax, ax
	push edi
	mov edi, [edx+idfsystem.gameid_dataptr]
	mov ax, word [edi+eax*idf_gameid_data_size+idf_gameid_data.dataid]
	pop edi
	ret

// in:
// edx = feature table
// ax = gameid
// out:
// ax = dataid or 0 if not possible
exported idf_increaseusage
	movzx eax, ax
	push edi
	push ebx
	mov edi, [edx+idfsystem.gameid_dataptr]
	movzx ebx, word [edi+eax*idf_gameid_data_size+idf_gameid_data.dataid]
	cmp ebx, 0
	jz .nodataid
	// ebx = dataid

.havedataid:
	mov edi, [edx+idfsystem.dataid_dataptr]
	inc word [edi+ebx*idf_dataid_data_size+idf_dataid_data.numtiles]

.done:
	mov eax, ebx
	pop ebx
	pop edi
	ret

.nodataid:
	push esi
	// edi = idf_gameid_data
	mov esi, [edx+idfsystem.dataid_dataptr]
	xor ebx, ebx

.nextentry:
	inc ebx
	add esi, idf_dataid_data_size			// the first entry is invalid
	cmp dword [esi+idf_dataid_data.grfid], 0
	je .foundemptyslot

	cmp ebx, [edx+idfsystem.dataidcount]
	jb .nextentry
	
	// no more dataids, bad :/
	
	xor ebx, ebx
	pop esi
	jmp .done

.foundemptyslot:
	// eax = gameid
	// ebx = dataid to be used
	// esi = idf_dataid_data+idf_dataid_data_size*ebx
	// edi = idf_gameid_data
	// now we need to fill some data
	
	push ecx
	mov cx, word [edi+eax*idf_gameid_data_size+idf_gameid_data.setid]
	mov word [esi+idf_dataid_data.setid], cx
	
	mov ecx, dword [edi+eax*idf_gameid_data_size+idf_gameid_data.act3info]
	mov ecx, dword [ecx+action3info.spriteblock]
	mov ecx, dword [ecx+spriteblock.grfid]

	mov dword [esi+idf_dataid_data.grfid], ecx
	pop ecx
	
	// ebx = dataid
	mov word [edi+eax*idf_gameid_data_size+idf_gameid_data.dataid], bx
	
	// store the gameid in the dataidtogameid array
	mov esi, [edx+idfsystem.dataidtogameidptr]
	mov word [esi+ebx*2], ax
	
	pop esi
	jmp near .havedataid

// in:
// ax = dataid
exported idf_decreaseusage
	movzx eax, ax
	cmp ax, 0
	je .notvalid
	push edi
	mov edi, [edx+idfsystem.dataid_dataptr]
	dec word [edi+eax*idf_dataid_data_size+idf_dataid_data.numtiles]
	cmp word [edi+eax*idf_dataid_data_size+idf_dataid_data.numtiles], 0
	jnz .ok
	
	push esi
	push ebx
	// clear entry
	mov dword [edi+eax*idf_dataid_data_size], 0
	mov dword [edi+eax*idf_dataid_data_size+4], 0
	
	// do we have a gameid for this dataid?
	xor ebx, ebx
	mov esi, [edx+idfsystem.dataidtogameidptr]
	xchg bx, word [esi+eax*2]
	cmp ebx, 0
	jz .nogameid
	// ebx = gameid
	mov esi, [edx+idfsystem.gameid_dataptr]
	// clear dataid <-> gameid binding
	mov word [esi+ebx*idf_gameid_data_size+idf_gameid_data.dataid], 0
.nogameid:
	pop esi
	pop ebx
.ok:
	pop edi
.notvalid:
	ret

// in:	eax=n-id unmodified (bit 7 set for livery override)
//	ebx=0 if GRFID != FFFFFFFF, ebx=-1 if GRFID=FFFFFFFF
//	ecx=n-id & 7F
//	edx= idf structure for the feature
//	ebp->action3info struct (pointer value to store)
//	esi->action 3 id list
// out:	esi->action 3 num-cid
// uses: eax ecx edx
extern globalidoffset
exported idf_bindaction3togameids
	push edi
	push ebx
	mov edi, [edx+idfsystem.gameid_dataptr]
	mov edx, [edx+idfsystem.curgrfidtogameidptr]
.nextaction3:
	xor eax, eax
	lodsb 
	add eax, [globalidoffset]
	movzx ebx, word [edx+eax*2]
	test ebx, [edi+ebx*idf_gameid_data_size+idf_gameid_data.act3info]
	jnz .skip
	mov dword [edi+ebx*idf_gameid_data_size+idf_gameid_data.act3info], ebp
	
	push eax
	sub eax, dword [globalidoffset]
	cmp word [edi+ebx*idf_gameid_data_size+idf_gameid_data.setid], ax
	je .setidok
	ud2
.setidok:
	pop eax
.skip:
	loop .nextaction3
	pop ebx
	pop edi
	ret
