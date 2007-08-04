//
// Make things work right over a wider range of start years
//

#include <defs.inc>
#include <player.inc>
#include <vehtype.inc>
#include <textdef.inc>
#include <ttdvar.inc>
#include <window.inc>
#include <misc.inc>

extern haverailengines,isengine,newsmessagefn

// Auxiliary function: convert pointer to vehtype to index, check if it's an engine
// in:	EAX->vehtype
// out:	EAX=vehtype index
//	CF set if engine, clear if waggon
// uses:ECX,EDX
getvehtypeidx:
	sub eax,vehtypearray
	xor edx,edx
	xor ecx,ecx
	mov cl,vehtype_size
	div ecx

	bt [isengine],eax
	ret


#if 0
// Make all default waggons available at game initialization
// in:	ESI->vehtypeinfo
//	EDI->vehtype being initialized
//	BX=introdate
// out:	CF=ZF=0 (cc=A) if it's too early
// safe:AX (not EAX)
initvehtypeavail:
	pusha
	xchg eax,edi
	call getvehtypeidx
	cmc
	jnc .engine

		// waggons available only if they don't have new graphics
	cmp dword [vehids+eax*4],1
		// now carry is set if it was at default settings

.engine:
	popa
	jc .done			// waggon -> exit with CF=1

	sub bx,[currentdate]		// overwritten

.done:
	ret
; endp initvehtypeavail
#endif


// Prevent new waggons from updating player.tracktypes
// when a new type becomes available
// in:	ESI->vehtype
//	CX=vehtype index
//	EDX->player
//	AH=vehtype.enginetraintype
// safe:EBX,EDI
global updaterailtype1
updaterailtype1:
	bt [isengine],cx
	jnc .done
	mov [edx+player.tracktypes],ah
.done:
	ret

// ...and when a vehicle type becomes available exclusively
// in:	ESI->vehtype
//	EBX->player
//	AL=vehtype.enginetraintype
// safe:EBX,?
global updaterailtype2
updaterailtype2:
	pusha
	xchg eax,esi
	call getvehtypeidx
	popa
	jnc .done
	mov [ebx+player.tracktypes],al
.done:
	ret


// Don't display "New <wagon type> available" message
// if there are no engines for the corresponding track type
// in:	ESI->vehtype
//	DX=vehtype index
//	AX,EBX,CX set for the news message fn
// safe:EDI
global gennewrailvehtypemsg
gennewrailvehtypemsg:
	push edx
	mov dl,[esi+vehtype.enginetraintype]
	call haverailengines			// in patches/unimagl.asm
	pop edx
	jnc .done

	mov dh,1			// DX must be nonzero (upper byte cleared in codefragment newgetrailengclassname)
	call [newsmessagefn]

.done:
	ret


// Prevent waggons from being expired at the init time
// i/o:	ESI->vehtype
global expirevehtype
expirevehtype:
	pusha
	xchg eax,esi
	call getvehtypeidx
	popa
//	jnc .done
	and word [esi],byte 0		// make unavailable
.done:
	ret
; endp expirevehtype


; Attempt to hack the Game options window real good!
global gameoptionsnewstartyear
gameoptionsnewstartyear:
	db cWinElemFrameWithText, cColorSchemeGrey
	dw 10, 179, 146, 181, ourtext(newstartyear)
	db cWinElemPushedInBox, cColorSchemeGrey
	dw 20, 169, 160, 171, 6
	db cWinElemTextBox, cColorSchemeGrey
	dw 21, 31, 161, 170, 0x225
	db cWinElemTextBox, cColorSchemeGrey
	dw 158, 168, 161, 170, 0x224
	db cWinElemLast
	
extern StartYearDataPointers, yeartodate, startyear, drawcenteredtextfn, DrawWindowElements
global gameoptionsstartyrtredraw
gameoptionsstartyrtredraw:
	mov word [textrefstack + 0x0A], ax ; do the old code before anything else
	call [DrawWindowElements] ; Must do this before drawing the date
	
	pusha
	movzx ax, byte [startyear] ;  Fetch the current start year
	add ax, 1920 ; The year is relative to 1920
	mov word [textrefstack], ax ; Store this for the text handler later
	mov cx, [esi + window.x] ; The place is relative to the window's x, y
	mov dx, [esi + window.y]
	add cx, ((157 - 32) / 2) + 32 ; Correct the placement to be where it should on the window
	add dx, 162
	mov bx, ourtext(newstartyearprint) ; Custom string, basically black pring word
	call dword [drawcenteredtextfn] ;Draw it centrally aligned woot.
	popa
	ret
	
global gameoptionsstartyrtclick
gameoptionsstartyrtclick:
	push eax ; We don't want to reck this yet
	mov al, 1 ; We can only change by one year per tick
	
	cmp cl, 26 ;  Is it the decrease button?
	je .decrease

	cmp cl, 27 ; Is it the increase button?
	je .increase	

	pop eax ; No so restore this and quit
	ret

.decrease:
	neg al ; Make this effectively -1
	
.increase:
	pusha ; action handler has a bad habbit of trashing everything despite my best efforts
	movzx ecx, cl
	bt [esi+window.activebuttons], ecx
	jc .done	
	
	bts dword [esi+window.activebuttons], ecx
	or byte [esi+window.flags],5
	
	add al, byte [startyear] ; Add the current starting year to it
	jnz .good ; If it is at 0 then we have a problem
	mov al, 1 ; Minium starting date
	
.good:
	mov edi, eax ; Now swap the registores
extern startyear_varnum, SetTTDpatchVar_actionnum, actionhandler, redrawscreen
	mov ebx, 1 + startyear_varnum ; Set the variable (on both machines)
	dopatchaction SetTTDpatchVar
	call redrawscreen ; Update the screen!
	
.done:
	popa ; Restore these since we don't want a crash
	pop eax
	mov byte [rmbclicked - 1], 0
	ret

global usenewstartyear
usenewstartyear:
	pusha
	movzx eax, byte [startyear] ; Get the currently saved year
	mov byte [currentyear], al ; Store it in the date part
	call yeartodate ; Calculate the exact date
	mov dword [currentdate], ebx ; Store the new date
	popa
	ret
	
