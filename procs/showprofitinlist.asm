#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc showprofitinlist, patchshowprofitinlist


extern gettextintableptr
extern malloc


patchshowprofitinlist:
	mov ax,0x198		// get the textarray entry
	call gettextintableptr
	lea ebx,[eax+edi*4]	// and the text itself
	mov edi,[ebx]
	push edi
	xor ecx,ecx		// get its length
	dec ecx
	xor eax,eax
	repnz scasb		// ecx is -length-1 now
	neg ecx
	inc ecx			// we need length+3
	inc ecx
	push ecx		// allocate space for the new text
	call malloc
	pop dword [ebx]		// update pointer
	mov edi,[ebx]		// copy the string
	pop esi
	mov bl,0x98		// bl= the last coloring character so far
	mov bh,2		// which 0x7f to change
.copyloop:
	lodsb

	cmp al,0x88
	jb .nocolor
	cmp al,0x98
	ja .nocolor

	mov bl,al

.nocolor:
	cmp al,0x7f
	jne .noinsert

	dec bh			// insert new chars only if bh becomes zero
	jnz .noinsert

	mov [edi],word 0x7f80	// put a 0x80 and the old 0x7f
	inc edi
	inc edi
	mov al,bl		// restore the old color

.noinsert:
	stosb			
	or al,al
	jnz .copyloop
	dec edi
	mov word [edi],0x0080

	multipatchcode oldshowprofitdata,newshowprofitdata,4
	ret



begincodefragments

codefragment oldshowprofitdata
	mov eax,[edi+veh.profit]
	mov [textrefstack],eax
	mov eax,[edi+veh.previousprofit]
	mov [textrefstack+4],eax

codefragment newshowprofitdata
	call runindex(showprofitdata)
	setfragmentsize 16


endcodefragments
