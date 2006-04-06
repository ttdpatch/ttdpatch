#include <defs.inc>
#include <frag_mac.inc>
#include <window.inc>
#include <patchproc.inc>

patchproc enhancegui, patchstickywindows

extern olddrawtitlebar,temp_drawwindow_active_ptr
extern winelemdrawptrs,drawtitlebar

begincodefragments

codefragment oldcloseallwindows
	cmp al, 24h
	db 0x74	// jz

codefragment newcloseallwindows
	icall closeallwindows

codefragment oldreplacewindow,-15
	cmp byte [esi+window.type],2
	je $+2+5

codefragment newreplacewindow
	icall replacewindow
	jmp newreplacewindow_start+30


endcodefragments


patchstickywindows:
	patchcode closeallwindows
	mov eax, dword [winelemdrawptrs+4*cWinElemTitleBar]
	mov [olddrawtitlebar], eax
	mov dword [winelemdrawptrs+4*cWinElemTitleBar], addr(drawtitlebar)
	mov ebx, dword [winelemdrawptrs+4*cWinElemSpriteBox]
	mov eax, [ebx+39]
	mov [temp_drawwindow_active_ptr], eax

	patchcode replacewindow
	ret
