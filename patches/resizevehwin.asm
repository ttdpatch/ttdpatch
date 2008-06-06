#include <var.inc>
#include <window.inc>
#include <windowext.inc>


guiwindow newTrainWindow, 0FAh, 86h
guicaption cColorSchemeGrey, 882Eh
guiwinresize cColorSchemeGrey, w,,2048, h,,2048
guiele viewborder1,cWinElemSpriteBox, cColorSchemeGrey, x,0, x2,231, y,14, y2,121, data,0, sx2,1, sy2,1
guiele viewborder2,cWinElemPushedInBox, cColorSchemeGrey, x,1, x2,229, y,16, y2,119, data,0, sx2,1, sy2,1
guiele startstop,cWinElemSpriteBox, cColorSchemeGrey, x,0, x2,249-12, y,122, y2,133, sx2,1, sy,1, data,0
guiele eye,cWinElemSpriteBox, cColorSchemeGrey, x,232, x2,249, sx,1, y,14, y2,31, data,683
guiele depot,cWinElemSpriteBox, cColorSchemeGrey, x,232, x2,249, sx,1, y,32, y2,49, data,685
guiele ignoresignal,cWinElemSpriteBox, cColorSchemeGrey, x,232, x2,249, sx,1, y,50, y2,67, data,689
guiele turnrefit,cWinElemSpriteBox, cColorSchemeGrey, x,232, x2,249, sx,1, y,68, y2,85, data,715
guiele orders,cWinElemSpriteBox, cColorSchemeGrey, x,232, x2,249, sx,1, y,86, y2,103, data,690
guiele details,cWinElemSpriteBox, cColorSchemeGrey, x,232, x2,249, sx,1, y,104, y2,121, data,691
guiele sponge,cWinElemSpriteBox, cColorSchemeGrey, x,232, x2,249, sx,1, y,122, y2,121, sy2,1, data,0
endguiwindow

guiwindow newRVWindow, 0FAh, 74h
guicaption cColorSchemeGrey, 882Eh
guiwinresize cColorSchemeGrey, w,,2048, h,,2048
guiele viewborder1,cWinElemSpriteBox, cColorSchemeGrey, x,0, x2,231, y,14, y2,103, data,0, sx2,1, sy2,1
guiele viewborder2,cWinElemPushedInBox, cColorSchemeGrey, x,1, x2,229, y,16, y2,101, data,0, sx2,1, sy2,1
guiele startstop,cWinElemSpriteBox, cColorSchemeGrey, x,0, x2,249-12, y,104, y2,115, sx2,1, sy,1, data,0
guiele eye,cWinElemSpriteBox, cColorSchemeGrey, x,232, x2,249, sx,1, y,14, y2,31, data,683
guiele depot,cWinElemSpriteBox, cColorSchemeGrey, x,232, x2,249, sx,1, y,32, y2,49, data,686
guiele turnrefit,cWinElemSpriteBox, cColorSchemeGrey, x,232, x2,249, sx,1, y,50, y2,67, data,715
guiele orders,cWinElemSpriteBox, cColorSchemeGrey, x,232, x2,249, sx,1, y,68, y2,85, data,690
guiele details,cWinElemSpriteBox, cColorSchemeGrey, x,232, x2,249, sx,1, y,86, y2,103, data,691
guiele sponge,cWinElemSpriteBox, cColorSchemeGrey, x,232, x2,249, sx,1, y,104, y2,103, sy2,1, data,0
endguiwindow

global trainwindowsize,rvwindowsize,newShipWindow_elements
trainwindowsize equ 0xA9
rvwindowsize equ 0x9D
uvarb trainwindowrefit,trainwindowsize
uvarb rvwindowrefit,rvwindowsize
uvarb newAircraftWindow_elements,rvwindowsize*2
newShipWindow_elements equ newAircraftWindow_elements+rvwindowsize


exported settextloc
	mov ax, [esi+window.width]
	sub ax,12
	shr ax,1
	add cx,ax
	jmp short setflagloc.setheight

exported setflagloc
	add cx,2
.setheight:
	add dx,[esi+window.height]
	sub dx,11
	ret
