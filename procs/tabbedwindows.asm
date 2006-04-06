#include <defs.inc>
#include <frag_mac.inc>
#include <window.inc>
#include <patchproc.inc>

patchproc locomotiongui, patchtabbedwindows


extern CloseDropDownMenu.ddmParentWinIdPtr1
extern CloseDropDownMenu.ddmParentWinIdPtr2
extern winelemdrawptrs,DrawWinElemTab,DrawWinElemTabButton

begincodefragments

codefragment oldclosedropdownmenu
	btr dword [esi+window.activebuttons], ecx
	db 0x66, 0x8b

codefragment newclosedropdownmenu
	icall CloseDropDownMenu
	setfragmentsize 11

codefragment oldgeneratedropdownmenu1,-3
	btr dword [esi+window.activebuttons], ecx
	pushfw

codefragment newgeneratedropdownmenu1
	icall DropDownMenuResetActiveButtons
	setfragmentsize 7

codefragment oldgeneratedropdownmenu2
	bts dword [esi+window.activebuttons], ecx
	mov bx, [esi+window.id]

codefragment newgeneratedropdownmenu2
	icall DropDownMenuSetActiveButtons
	setfragmentsize 8

codefragment oldgeneratedropdownmenu3
	mov ebp, ecx
	imul ebp, 0Ch
	add ebp, [esi+window.elemlistptr]

codefragment newgeneratedropdownmenu3
	icall DropDownMenuGetElements
	setfragmentsize 8


endcodefragments


patchtabbedwindows:
	mov dword [winelemdrawptrs+4*cWinElemTab], addr(DrawWinElemTab)
	mov dword [winelemdrawptrs+4*cWinElemTabButton], addr(DrawWinElemTabButton)
	stringaddress oldclosedropdownmenu
	mov eax, [edi+7]
	mov [CloseDropDownMenu.ddmParentWinIdPtr1], eax
	mov [CloseDropDownMenu.ddmParentWinIdPtr2], eax
	storefragment newclosedropdownmenu
	patchcode oldgeneratedropdownmenu1,newgeneratedropdownmenu1
	patchcode oldgeneratedropdownmenu2,newgeneratedropdownmenu2
	patchcode oldgeneratedropdownmenu3,newgeneratedropdownmenu3
	ret
