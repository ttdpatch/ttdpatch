// More news items

#include <std.inc>
#include <flags.inc>
#include <textdef.inc>
#include <station.inc>
#include <veh.inc>
#include <town.inc>
#include <industry.inc>
#include <ptrvar.inc>
#include <window.inc>
#include <news.inc>
#include <grfdef.inc>

extern clearcrashedtrainpath,newsmessagefn,patchflags


// ********
// WARNING!
// ********

//
// When passing arguments to [newsmessagefn], either in registers or on
// the textrefstack or the newsitemparams, make sure NOT to use ourtext() or
// statictext() directly, because these IDs may change, causing news messages
// in the queue to change too, possibly causing crashes or other Bad Things.
//
// Instead, use the defnewstext() et.al. C preprocessor macros in textdef.ah
// to define a corresponding newstext() ID and use only that.
//
// (This feature can and should be used for any text IDs that may be stored
//  directly anywhere in savegames.)
//

// Here we actually store the text ID redirection strings as set it textdef.ah

%push ntxt_def
%assign %$ntxtnum 0
%assign %$thistext 0
%macro _defnewstext 0.nolist
%$text_%$ntxtnum:
	%ifndef PREPROCESSONLY
		%define %$thistext %$text_%$ntxtnum
	%endif
	%if %$ntxtnum>0
		%xdefine %$ntxts %$ntxts,%$thistext
	%else
		%xdefine %$ntxts %$thistext
	%endif

	// make a substring using 81 ID(W) 00
	dd (0 << 24) + (NTXT_ARG_ %+ %$ntxtnum << 8) + (0x81)

	%assign %$ntxtnum %$ntxtnum+1
%endmacro

	align 4

// use a macro in %rep so as not to clutter the listing file so much
%rep NTXT_NUM
	_defnewstext
%endrep

var ntxtptr, dd %$ntxts
%undef _defnewstext
%pop

#define newsdata(text,category) ( newstext(text) | (category<<16) )

// Generate a news report when a large UFO is destroyed
// in:	ESI -> XCOM aircraft
//	EDI -> UFO
// safe:(E)AX,EBX,CX,DX,EBP (well, we PUSHA anyway)
global largeufodestroynews
largeufodestroynews:
	mov	word [esi+veh.currorder],1		// overwritten by runindex call
	mov	edx,newsdata(ufodestroyed,2)
	call	newsmsgwithnearesttown
	ret
; endp largeufodestroynews

	// find the nearest town and store its name
	// this is about how TTD does it when a large UFO lands
	//
	// in:	ax=XY
pushnearesttownonrefstack:
	push	edi
	extcall findnearesttown
	mov	esi,textrefstack
	mov	ax,word [edi+town.citynametype]
	mov	[esi],ax
	mov	eax,dword [edi+town.citynameparts]
	mov	[esi+2],eax
	pop	edi
	ret


// Shows a news message with the given text centered on the given vehicle.
// textrefstack contains the closest town
// in:	edi: vehicle
//	dx: message ID
//	upper half of edx: message category
newsmsgwithnearesttown:
	pusha

	mov ax,[edi+veh.XY]
	call pushnearesttownonrefstack

	// now set coordinates and invoke the news/message handler
	movzx	eax,word [edi+veh.xpos]
	movzx	ecx,word [edi+veh.ypos]
	mov	ebx,eax
	shr	ebx,4
	shl	ecx,4
	mov	bh,ch
	shr	ecx,4
	mov	[newsitemparam],ebx
	mov	ebx,edx
	mov	bx,0x0502
	call	dword [newsmessagefn]

	popa
	ret

// Watching production of lumber mills works this way:
// We count the number of treecuts since the last unsuccessful one in a previously unused field.
// We notify the player only if there were at least four successful cuts before an unsuccessful one.
// This way we can avoid multiple warnings caused by cutting the few baby trees that grow sometimes
// in the otherwise empty area.

// Called at the end of tree-finding loop for lumber mills. If no trees were found, the procedure exits here.
// esi points to the lumber mill in the industry array
// safe:none

global lmillcuttree1
lmillcuttree1:
	sub bx,0x101	// owerwritten
	cmp cl,41	// by the runindex call
	jnb .outoftrees
	ret		// haven't finished the loop yet

.outoftrees:
	cmp byte [esi+industry.badtreecuts],4
	jbe .notenough
 
	push eax
	push ebx
	push ecx

	mov ecx,textrefstack

	// fill the text stack with the needed information
	// first the city name
	mov eax, [esi+industry.townptr]
	mov bx, [eax+town.citynametype]
	mov [ecx],bx
	mov eax, [eax+town.citynameparts]
	mov [ecx+2],eax

	// then the industry name
	movzx ax, byte [esi+industry.type]
	add ax, 0x4802
	mov [ecx+6],ax

	// make parameters for newsmessagefn
	movzx ebx,word [esi+industry.XY]
	movzx eax,bl
	movzx ecx,bh
	mov [newsitemparam],ebx
	shl eax,4
	shl ecx,4
	add eax,16
	add ecx,16
	mov ebx,0x40502		// category 4 = "economy changes"
	mov dx,newstext(lmilloutoftrees)

	// and show the message
	call dword [newsmessagefn]
	pop ecx
	pop ebx
	pop eax
	
.notenough:
	and byte [esi+industry.badtreecuts],0	// reset counter
	clc	// need to clear carry to exit the loop
	ret

// Called after successfully cutting a tree.
// safe: none
global lmillcuttree2
lmillcuttree2:
	add word [esi+industry.amountswaiting],45	// overwritten
	jae .noprodoverflow				// by the

	mov word [esi+industry.amountswaiting],0xffff	// runindex call

.noprodoverflow:
	add byte [esi+industry.badtreecuts],1	// inc wouldn't set the flags
	jae .nocutcountoverflow

	mov byte [esi+industry.badtreecuts],0xff

.nocutcountoverflow:
	ret

// News message when a crashed Zeppelin has been cleared from an airport
// in:	esi -> Zeppelin about to be cleared
//	edi -> station where the Zeppelin is
// safe: eax,ebx,ecx,edx

global clearzeppelin
clearzeppelin:
	btr word [edi+station.airportstat],7 // overwritten by the call
	mov dl, [edi+station.owner]
	cmp dl, [human1]
	jne .exit

	mov edx,newsdata(zeppelincleared,5)
	mov ebx,edi
	call newsmsgwithstation
.exit:
	ret

// The same with crashed aircrafts
// in:	esi -> aircraft to be cleared
//	ebx -> station where the aircraft is
// safe: eax,ebx,ecx,edx

global clearcrashedaircraft
clearcrashedaircraft:
	btr word [ebx+station.airportstat],ax // overwritten by the call
	mov dl, [ebx+station.owner]
	cmp dl, [human1]
	jne .exit

	mov edx,newsdata(aircraftcleared,5)
	call newsmsgwithstation
.exit:
	ret

// Shows a news message with the given text centered on the given vehicle
// textrefstack contains the name of the given station
// in:	ebx -> station
//	dx: message ID
//	esi -> vehicle
// destroys eax,ebx,ecx,edx
newsmsgwithstation:
	push edx
	mov edx,textrefstack
	mov eax,[ebx+station.name]
	mov [edx],eax
	mov ecx,[ebx+station.townptr]
	mov eax,[ecx+town.citynametype]
	mov [edx+2],eax
	mov eax,[ecx+town.citynameparts]
	mov [edx+4],eax
	movzx eax,word [esi+veh.xpos]
	movzx ecx,word [esi+veh.ypos]
	mov ebx,eax
	shr ebx,4
	shl ecx,4
	mov bh,ch
	shr ecx,4
	mov [newsitemparam],ebx
	pop edx
	mov ebx,edx
	mov bx,0x0502
	call dword [newsmessagefn]
	ret

uvarw lastcleardate	// used to prevent multiple news messages when multiple trains are cleared

// called for every wagon of the crashed train being cleared
// in:	esi -> wagon being cleared
//	edi -> wagon before [esi] in the consist
// safe: eax,ecx,edx,ebp
global clearcrashedtrain
clearcrashedtrain:
	testflags pathbasedsignalling
	jnc .nopathsig

	call clearcrashedtrainpath

.nopathsig:
	mov word [edi+veh.nextunitidx],-1	// overwritten by the runindex call
	mov al,[esi+veh.owner]
	cmp al,[human1]
	jne .exit
	cmp esi,edi
	jne .exit
	mov ax,[lastcleardate]
	add ax,3
	mov cx,[currentdate]
	cmp ax,cx
	ja .exit

	mov [lastcleardate],cx

	mov	edx,newsdata(traincleared,5)
	call	newsmsgwithnearesttown
.exit:
	ret

// Called at the beginning of each year if morenews is on
// Check if any new bridge has been introduced this year, and generate news messages for them
// Safe: all
exported checkfornewbridges
	xor edi,edi
	testflags newbridges
	jc .newbridges_on

extern bridgespecificpropertiesttd
	mov esi,[bridgespecificpropertiesttd]
.nextold:
	mov al, [currentyear]
	cmp [esi+edi],al	// compare intro year with current year
	jne .skipold
	call .gen
.skipold:
	inc edi
	cmp edi,NBRIDGES
	jb .nextold
	ret

.newbridges_on:
.nextnew:
extern bridgeloaded
	bt [bridgeloaded],edi
	jnc .skipnew
	mov al, [currentyear]
extern bridgeintrodate
	cmp [bridgeintrodate+edi],al
	jne .skipnew
	call .gen
.skipnew:
	inc edi
	cmp edi,NNEWBRIDGES
	jb .nextnew
	ret

.gen:
	mov ebx, 0x060003	// category=new vehicles, type=custom
	mov ax, 0x0a*8		// class offset of handler function
extern newbridgenewshandler_funcnum
	mov ecx, newbridgenewshandler_funcnum
	mov edx,edi
	jmp dword [newsmessagefn]

// Draw the bare minimum required for a news message window - can be used in custom news handlers
// (The code is mostly lifted from TTD custom news handlers)
// in:	esi->window to draw
//	edi->screen update block descriptor
// preserves: esi, edi
extern fillrectangle
drawdefaultnewswindow:
	// draw the white background
	mov ax, [esi+window.x]
	mov cx, [esi+window.y]
	mov bx, [esi+window.width]
	mov dx, [esi+window.height]
	add bx, ax
	add dx, cx
	dec bx
	dec dx
	mov bp, 0x0F
	call [fillrectangle]

	// draw the 1px border by four fillrectangle calls
	push ebx
	mov ebx,eax
	mov bp,1
	call [fillrectangle]
	pop ebx

	push eax
	mov eax,ebx
	mov bp,1
	call [fillrectangle]
	pop eax

	push edx
	mov edx,ecx
	mov bp,1
	call [fillrectangle]
	pop edx

	push ecx
	mov ecx,edx
	mov bp,1
	call [fillrectangle]
	pop ecx

	push esi
	mov edx,ecx
	mov ecx,eax
	add ecx,2
	inc edx
	mov bx, 0x00c6	// TextID for the close button
extern drawtextfn
	call [drawtextfn]
	pop esi

	ret

// Custom news handler for the "New bridge available" message
// Can be called in two ways:
// edi=0: drawn in the status bar or in the news history window
//	currstatusnewsitem stores our news structure
//	must return a textId in eax and fill the text ref. stack accordingly
//	safe: esi, ???
// edi!=0: draw full news message
//	edi->window to draw
//	currnewsitem stores our news structure
//	safe: all
extern currscreenupdateblock, bridgenames, drawsplitcenteredtextfn, bridgeicons
exported newbridgenewshandler
	test edi,edi
	jnz .full

	// summary mode, just return the textid in ax
	mov word [textrefstack], ourtext(news_newbridge)
	movzx esi,word [currstatusnewsitem+newsitem.item]
	mov ax,[bridgenamesttd+esi*2]
	testflags newbridges
	jnc .statusnameok
	mov ax,[bridgenames+esi*2]
.statusnameok:
	mov [textrefstack+2],ax
	mov ax, 0x2b6	// prints two texts separated by a hyphen
	ret

.full:
	// full mode - EDI points to a window that needs to be drawn
	mov esi, edi
	mov edi, [currscreenupdateblock]
	call drawdefaultnewswindow

	// Draw the title
	mov bx, ourtext(news_newbridge)
	mov cx, [esi+window.width]
	shr cx,1
	add cx, [esi+window.x]
	mov dx, [esi+window.y]
	add dx, 20
	mov bp, [esi+window.width]
	sub bp, 2
	push esi
	call dword [drawsplitcenteredtextfn]
	pop esi

	// Draw a background rectangle inside the window, mimicking the new vehicle window
	mov bp, 0x0a
	testflags newspapercolour
	jnc .gotbgcolor
extern coloryear
	movzx ax,[currentyear]
	add ax,1920
	cmp ax,[coloryear]
	jb .gotbgcolor
	mov bp,103	// greenish background color

.gotbgcolor:
	mov ax, [esi+window.x]
	mov cx, [esi+window.y]
	mov bx, [esi+window.width]
	mov dx, [esi+window.height]
	add dx, cx
	add bx, ax
	add ax, 25
	sub bx, 25
	add cx, 56
	sub dx, 2
	call [fillrectangle]

	// Display the name of the bridge
	movzx ecx, word [currnewsitem+newsitem.item]
	mov ax, [bridgenamesttd+ecx*2]
	testflags newbridges
	jnc .nameok
	mov ax, [bridgenames+ecx*2]
.nameok:
	mov [textrefstack],ax
	mov bx, 0x885A		// print text in big black letters
	mov cx,[esi+window.width]
	shr cx,1
	add cx,[esi+window.x]
	mov dx,[esi+window.y]
	add dx,57
	mov bp,[esi+window.width]
	sub bp,2
	push esi
	call dword [drawsplitcenteredtextfn]
	pop esi

	// draw the icon
	movzx ecx, word [currnewsitem+newsitem.item]
	mov ebx,[bridgeiconsttd+ecx*4]
	testflags newbridges
	jnc .iconok
	mov ebx,[bridgeicons+ecx*4]
.iconok:
	testflags newspapercolour
	jnc .greyicon
	movzx ax,[currentyear]
	add ax,1920
	cmp ax,[coloryear]
	jae .coloredicon
.greyicon:
	// replace color translation with grey translation
	and ebx,0x3fff
	or ebx,0x3238000
.coloredicon:
	mov ebp,ebx
	and ebp,0x3fff
	add ebp,ebp
extern newspritexsize
	add ebp,[newspritexsize]	// now ebp points to the width of the icon
	mov cx,[esi+window.width]
	sub cx,[ebp]			// subtract its width before dividing by two, so it ends up centered
	shr cx,1
	add cx,[esi+window.x]
	mov dx,[esi+window.y]
	add dx,83
extern drawspritefn
	push esi
	push edi
	call dword [drawspritefn]
	pop edi
	pop esi

	// Draw stats
	movzx eax, word [currnewsitem+newsitem.item]
	testflags newbridges
	jc .newdetails
	mov bx, [bridgespeedsttd+eax*2]
	mov [textrefstack],bx
	mov ecx, [bridgespecificpropertiesttd]
	movzx bx, byte [ecx+NBRIDGES+eax]		// min. length
	mov [textrefstack+2],bx
	movzx bx, byte [ecx+2*NBRIDGES+eax]		// max. length
	mov [textrefstack+4],bx
	jmp short .gotstats
.newdetails:
extern bridgemaxspeed, bridgeminlength, bridgemaxlength
	mov bx, [bridgemaxspeed+eax*2]
	mov [textrefstack],bx
	movzx bx, byte [bridgeminlength+eax]
	mov [textrefstack+2],bx
	movzx bx, byte [bridgemaxlength+eax]
	mov [textrefstack+4],bx
.gotstats:
	movzx ecx, word [esi+window.width]
	lea ebp, [ecx-52]
	shr ecx,1
	add cx,[esi+window.x]
	mov dx,[esi+window.y]
	add dx,131
	mov bx,ourtext(news_newbridge_details)
	push esi
	call [drawsplitcenteredtextfn]
	pop esi

	ret
