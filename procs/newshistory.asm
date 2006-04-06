#include <defs.inc>
#include <frag_mac.inc>
#include <news.inc>
#include <textdef.inc>

extern malloccrit,newshistoryptr
extern newsmessagefn

global patchnewshistory
patchnewshistory:
	// allocate memory for the news history
	push dword NEWS_HISTORY_SIZE*newsitem_size
	call malloccrit
	pop dword [newshistoryptr]

	// change the text in the menu
	stringaddress findMessageMenu,1,1
	mov word [edi+28], ourtext(newshistory)

	// change the code executed when the item is selected
	stringaddress findpulldownmenuwindowhandler,1,1
	add edi, 26
	mov eax, [edi+2]
	add edi, eax
	add edi, 6
	add edi, 5
	storefragment newPullDownMenuWindowHandler

	// add capturing newsmessages
	mov edi, [newsmessagefn]
	cmp byte [edi], 0xE9 // jmp
	jne .found
	mov eax, [edi+1]
	lea edi, [edi+eax+5]
.found:
	inc edi
	storefragment newNewsMessageFn
	ret


begincodefragments

codefragment findMessageMenu
	db 0x66, 0x81, 0x66, 0x04, 0x7F, 0xFE
	db 0x66, 0xC7, 0x46, 0x2A, 0x02, 0x00
	db 0x66, 0xC7, 0x46, 0x2C, 0x00, 0x00
	db 0x66, 0xC7, 0x46, 0x2E, 0x18, 0x00
	db 0x66, 0xC7, 0x46, 0x30, 0x00, 0x02
	db 0x66, 0xC7, 0x46, 0x32, 0x00, 0x00

codefragment findpulldownmenuwindowhandler
	db 0x66, 0x8b, 0xd9
	db 0x8b, 0xf7
	db 0x80, 0xfa, 0x01
	db 0x0f, 0x84, 0x35, 0xff, 0xff, 0xff
	db 0x80, 0xfa, 0x08

codefragment newPullDownMenuWindowHandler
	call runindex(NewsMenuWindowHandler)
	setfragmentsize 8

codefragment newNewsMessageFn
	icall addnewsmessagetohistory
	setfragmentsize 7


endcodefragments
