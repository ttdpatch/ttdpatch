#include <defs.inc>
#include <frag_mac.inc>


extern AcceptsListDrawWidthPtr,AcceptsTextIdPtr
extern DrawPlannedStationAcceptsList


global patchlocomotiongui
patchlocomotiongui:
	patchcode oldopenrailconstrwindow,newopenrailconstrwindow,1,1
	storeaddress findDrawPlannedStationAcceptsList,DrawPlannedStationAcceptsList
	storeaddress findAcceptsListDrawWidth,AcceptsListDrawWidthPtr
	storeaddress findAcceptsTextId,AcceptsTextIdPtr

	patchcode oldcreaterailstationselectwindow,newcreaterailstationselectwindow,1,2
	ret


begincodefragments

codefragment oldopenrailconstrwindow
	push dx
	mov cl, 3

codefragment newopenrailconstrwindow
	icall openrailconstrwindow
	setfragmentsize 7

codefragment findDrawPlannedStationAcceptsList
	sub esp, 18h
	mov ebp, esp
	push ax

codefragment findAcceptsListDrawWidth,2
	mov bp, 144

codefragment findAcceptsTextId,3
	mov dword [edi], 81h + (0x000D << 8)

codefragment oldcreaterailstationselectwindow
	mov ebx, 148 + (185 << 16)
	mov dx, 28h

codefragment newcreaterailstationselectwindow
	icall createrailstationselectwindow
	setfragmentsize 9


endcodefragments
