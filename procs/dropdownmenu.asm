#include <defs.inc>
#include <frag_mac.inc>


extern newoptionentryfns,newoptionentrytxts,numnewoptionentries,patchflags
extern toolbarelemlisty2,win_etoolbox_create,do_win_grfstat_create

#include <textdef.inc>

global patchdropdownmenu

begincodefragments

codefragment olddropdownmenustrings
	test si,1

codefragment newdropdownmenustrings
	call runindex(dropdownmenustrings)
	setfragmentsize 9

codefragment oldtoolbardropdown,-14
	mov ebx,160 + (92 << 16)

codefragment newtoolbardropdown
	call runindex(toolbardropdown)
	mov eax,22 + (22 << 16)
	mov bx,160
	push ecx
	setfragmentsize 19

codefragment newsettoolbarnum
	pop ecx
	mov [esi+0x2a],cx
	setfragmentsize 6

codefragment oldselecttool
	or dx,dx
	jz $+2+0x3a

codefragment newselecttool
	call runindex(selecttool)
	jb $+2+0x37
	setfragmentsize 9


endcodefragments

patchdropdownmenu:
	patchcode olddropdownmenustrings,newdropdownmenustrings,1,1
	stringaddress oldtoolbardropdown,1,1
	mov eax,[edi+3]
	mov [toolbarelemlisty2],eax
	storefragment newtoolbardropdown
	add edi,lastediadj+50
	storefragment newsettoolbarnum
	patchcode oldselecttool,newselecttool,1,1

	xor eax,eax
	testflags enhancegui
	jnc .noenhancegui
	mov word [newoptionentrytxts+eax*2],ourtext(txtetoolboxmenu)
	mov dword [newoptionentryfns+eax*4],addr(win_etoolbox_create)
	inc eax
.noenhancegui:
	testflags canmodifygraphics
	jnc .nonewgraphics
	mov word [newoptionentrytxts+eax*2],ourtext(grfstatusmenu)
	mov dword [newoptionentryfns+eax*4],addr(do_win_grfstat_create)
	inc eax
.nonewgraphics:
	mov [numnewoptionentries],eax
	ret
