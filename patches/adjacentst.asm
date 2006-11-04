#include <std.inc>
#include <veh.inc>
#include <textdef.inc>
#include <window.inc>
#include <misc.inc>
#include <station.inc>
#include <town.inc>
#include <imports/gui.inc>
#include <flags.inc>
#include <player.inc>

extern convertplatformsinremoverailstation,newstationspread,ishumanplayer,patchflags,stationarray2ofst,errorpopup

global adjflags

uvard adjflags
//bits: 0: attatch to station, 1: new station, 2: normal, 16-31: station id

uvard adjfunc
uvard adjblock,64
uvard adjblocklen
uvard adjdim
uvard adjtile

uvard stlist,256
//bits: 0-15=num of station, 16-23=displayidx, 24-31=type: 1=station, 2=norm, 3=new, 4=cancel
uvard numinlist

%assign numrows 12
%assign winwidth 358
%assign winheight numrows*10+36

varb adjstdlgwindowelements
	// Close button 0
	db cWinElemTextBox, cColorSchemeGrey
	dw 0, 10, 0, 13, 0x00C5

	// Title Bar 1
	db cWinElemTitleBar, cColorSchemeGrey
	dw 11, winwidth-1, 0, 13, ourtext(adjsttitle)

	// Status bar 2
	db cWinElemTextBox, cColorSchemeGrey
	dw 0, winwidth-12, winheight-13, winheight-1
	dw ourtext(adjstnumstsinrange)

	// Text Box 3
	db cWinElemTextBox, cColorSchemeGrey
	dw 0, winwidth-12, 14, winheight-14
	dw statictext(empty)

	// Slider 4
	db cWinElemSlider, cColorSchemeGrey
	dw winwidth-11, winwidth-1, 14, winheight-14,0

	// Window sizer 5
	db cWinElemSizer, cColorSchemeGrey
	dw winwidth-11, winwidth-1, winheight-13, winheight-1, 0

	// Sizer data 6
	db cWinElemExtraData, cWinDataSizer
	dd ASConstraints, ASSizes
	dw 0

	db 0xb
endvar

vard ASSizes
	dw winwidth, winwidth
	db 1, -1
	dw 0
	dw 2*10+36, 30*10+36
	db 10, 6
	dw 36
endvar

vard ASConstraints
	db 0
	db 0
	db 12
	db 8
	db 8
	db 12
	db 0
endvar


extern curplayerctrlkey

global adjacentstationcheck
//in:	eax=tile coord of north corner of new facility to be added
//	ebx=dimensions, lsb=x, 2nd lsb=y, msw=0
//	edx=address of function to call
//		Passed following parameters:
//		eax=tile coords as above
//		ebx=dimensions as above
//		edx=pointer to data block as below
//		ecx=length of above data block
//		esi=id of station to use or: -1 for normal processing, -2 for new station
//	esi=pointer to data block to be copied to internal buffer, the pointer to which will be passed to the function to call
//	ecx=length of above data block, max 256 bytes

//out:	eax=station id of station to add
//		0-255	= use this station id (won't happen/not implemented)
//		-1	= normal processing
//		-2	= error/cancel
//		-3	= delayed processing

//trashes: (eax)
adjacentstationcheck:
	cmp byte [curplayerctrlkey],1
	je .test
	xor eax, eax
	dec eax
ret
.test:
	pusha
	push byte 0
	call ishumanplayer
	jne .normret
	cmp ecx, 256
	ja .error
	or ecx, ecx
	jz .error
	mov [adjblocklen], ecx
	add ecx, 3
	shr ecx, 2
	cld
	mov edi, adjblock
	rep movsd
	mov [adjfunc], edx
	mov [adjdim], ebx
	mov [adjtile], eax
	
	call createwindow

	popa
	mov eax, -3
ret
.error:
	popa
	mov eax, -2
ret
.normret:
	popa
	mov eax, -1
ret


	//edi=window ptr, al=company
populatelist:
	pusha
	mov DWORD [numinlist], 3
	mov DWORD [stlist], 0x4000000
	mov DWORD [stlist+4], 0x3000000
	mov DWORD [stlist+8], 0x2000000
	push eax
	mov ecx, numstations
	mov esi, stationarray
.stloop:
	cmp WORD [esi+station.XY], 0
	je .endloop
	push eax
	mov al, [esi+station.owner]
	cmp al, 16
	je .noowner
	cmp al, [esp+4]
	jne NEAR .endlooppop
.noowner:
	pop eax
	call getstationextent
	mov edx, [adjtile]
	call addcoord
	add edx, [adjdim]
	sub edx, 0x101
	call addcoord
	sub ebx, eax
	mov al, [newstationspread]
	cmp bl, al
	ja .endloop
	cmp bh, al
	ja .endloop
	mov eax, [numinlist]
	lea edx, [ecx-numstations]
	neg edx
	movzx ebx, BYTE [esi+station.displayidx]
	or ebx, 0x100
	shl ebx, 16
	or edx, ebx
	mov [stlist+eax*4], edx
	inc DWORD [numinlist]
.endloop:
	add esi, station_size
	loop .stloop
	mov al, [numinlist]
	mov byte [edi+window.itemstotal], al
	sub al, [edi+window.itemsvisible]
	cmp [edi+window.itemsoffset], al
	jnae .nomvdn
	mov [edi+window.itemsoffset], al
.nomvdn:
	mov ecx, [numinlist]
	sub ecx, 3
	mov eax, stlist+12
	call listalphaqsort
	pop eax
	popa
ret
.endlooppop:
	pop eax
	jmp .endloop
	
//eax=address of first dword from stlist
//ecx=number
//trashes ebx, edx, ebp, esi, edi
listalphaqsort:
	cmp ecx, 1
	jle .endnow
	push eax
	push ecx
	lea edx, [ecx*4]
	sub esp, edx
	mov ebx, [eax]
	push ebx
	and ebx, 0x1ff0000
	xor ebp, ebp
	dec ecx
	mov edi, ecx
.loop:
	mov esi, [eax+ecx*4]
	cmp esi, ebx
	ja .more
	mov [esp+4+ebp*4], esi
	inc ebp
	loop .loop
	jmp .afterloop
.more:
	mov [esp+4+edi*4], esi
	dec edi
	loop .loop
.afterloop:

	cmp edi, ebp
	je .nodie
	int3			//screw up if edi and ebp not equal
	.nodie:
	
	mov ecx, [esp+4+edx]
	sub ecx, edi
	dec ecx
	lea eax, [esp+8+edi*4]
	push edx
	push edi
	call listalphaqsort

	mov ecx, [esp]
	lea eax, [esp+12]
	
	call listalphaqsort
	pop edi
	pop edx

	pop ebx
	mov [esp+edi*4], ebx
	mov ecx, [esp+edx]
	mov edi, [esp+edx+4]
	mov esi, esp
	cld
	rep movsd

	add esp, edx
	pop ecx
	pop eax
.endnow:
ret

global getstationextent
getstationextent:	//esi=station
			//rets: eax=north corner, ebx=south corner, edx=extent or zero if station has no facilities
	mov eax, 0xffff
	xor ebx, ebx
	test BYTE [esi+station.facilities], 1
	jz .norail
	movzx edx, WORD [esi+station.railXY]
	call addcoord

	push eax
	push edx
	testflags irrstations
	jc near .irr
.notirr:
	movzx edx, BYTE [esi+station.platforms]
	call convertplatformsinremoverailstation
	// dh = length, dl = tracks
	pop eax
	test BYTE [landscape5(ax,1)], 1
	jnz .noswap
	xchg dl, dh
	.noswap:
	sub edx, 0x101
	add edx, eax
	pop eax
	call addcoord
	jmp .norail
.irr:
	mov edx, esi
	add edx, [stationarray2ofst]
	movzx edx, WORD [edx+station2.railxysouth]
	or edx, edx
	jz .notirr
	pop eax
	pop eax
	call addcoord
.norail:
	test BYTE [esi+station.facilities], 2
	jz .nolorry
	movzx edx, WORD [esi+station.lorryXY]
	call addcoord
.nolorry:
	test BYTE [esi+station.facilities], 4
	jz .nobus
	movzx edx, WORD [esi+station.busXY]
	call addcoord
.nobus:
	test BYTE [esi+station.facilities], 8
	jz .noair
	movzx edx, WORD [esi+station.airportXY]
	call addcoord
	cmp BYTE [esi+station.airporttype], 2
	jae .noair
	cmp BYTE [esi+station.airporttype], 1
	je .small
	add edx, 0x505
	call addcoord
	jmp .noair
.small:
	add edx, 0x302
	call addcoord
.noair:
	test BYTE [esi+station.facilities], 16
	jz .nosea
	movzx edx, WORD [esi+station.dockXY]
	call addcoord
.nosea:
	cmp ax, 0xffff
	je .fret
	mov edx, ebx
	sub edx, eax
	add edx, 0x101
ret
.fret:
	xor edx, edx
ret

addcoord:		//edx=coord
	cmp dl, al
	jnb .nxb
	mov al, dl
	.nxb:
	cmp dh, ah
	jnb .nyb
	mov ah, dh
	.nyb:
	cmp dl, bl
	jna .nxa
	mov bl, dl
	.nxa:
	cmp dh, bh
	jna .nya
	mov bh, dh
	.nya:
ret

createwindow:
	mov cx, 6//cWinTypeStationList
	movzx dx, [curplayer]
	add dx, 32
	push dx
	call dword [BringWindowToForeground]
	jnz NEAR .alreadywindowopen
	mov eax, (640-winwidth)/2 + (((480-winheight)/2) << 16) // x, y
	mov cx, 6//cWinTypeStationList
	mov ebx, winwidth+(winheight<<16)
	mov dx, -1
	mov ebp, windowhandler
	call dword [CreateWindow]
.alreadywindowopen:
	mov DWORD [esi+window.elemlistptr], adjstdlgwindowelements
	pop dx
	mov [esi+window.id], dx
	sub dx, 32
	mov [esi+window.company], dl
	mov byte [esi+window.itemsvisible], numrows
	mov byte [esi+window.itemsoffset],0

	mov edi, esi
	mov al, [curplayer]
	jmp populatelist

windowhandler:

 	mov esi, edi

	cmp dl, cWinEventRedraw
	jz drawhandler

	cmp dl, cWinEventClick
	jz NEAR clickhandler
ret

drawhandler:
	movzx edx, BYTE [esi+window.company]
	imul edx, player_size
	add edx, [playerarrayptr]
	mov ax, [edx+player.name]
	mov [textrefstack], ax
	mov eax, [edx+player.nameparts]
	mov [textrefstack+2], eax
	mov ax, [numinlist]
	sub ax, 3
	mov [textrefstack+6], ax
	call dword [DrawWindowElements]
	movzx eax, BYTE [esi+window.itemsvisible]
	movzx ebp, BYTE [esi+window.itemsoffset]
	mov edx, [numinlist]
	sub edx, ebp
	jz NEAR .ret
	cmp edx, eax
	ja .next
	mov eax, edx
.next:
	lea ebp, [stlist+ebp*4]
	movzx edx, WORD [esi+window.y]
	movzx ecx, WORD [esi+window.x]
	//mov edi, esi
	shl ecx, 16
	lea esi, [ecx+edx+0x20010]
	push eax
.printloop:
	push ebp
	mov eax, [ebp]
	movzx ebp, ax
	shr eax, 24
	dec eax
	mov bx, statictext(empty)
	js .print
	jne .notst
	imul ebp, station_size
	add ebp, stationarray
	mov ax, [ebp+station.name]
	mov [textrefstack], ax
	mov al, [ebp+station.facilities] ; 1=rail, 2=lorry, 4=bus, 8=air, 10h=dock
	mov [textrefstack+8], al
	mov ebp, [ebp+station.townptr]
	mov ax, [ebp+town.citynametype]
	mov [textrefstack+2], ax
	mov eax, [ebp+town.citynameparts]
	mov [textrefstack+4], eax
	mov bx, 0x3049
	jmp .print
.notst:
	dec eax
	jne .notnorm
	mov bx, ourtext(adjstnormstmergealgtxt)
	jmp .print
.notnorm:
	dec eax
	jne .notnew
	mov bx, ourtext(adjstnewsttxt)
	jmp .print
.notnew:
	dec eax
	jne .print
	mov bx, 0x12E
.print:
	mov dx, si
	mov ecx, esi
	shr ecx, 16
	add esi, 10
	push esi
	call [drawtextfn]
	pop esi
.loopend:
	pop ebp
	add ebp, 4
	dec DWORD [esp]
	jnz .printloop
	add esp, 4
.ret:
ret

clickhandler:
	call dword [WindowClicked] // Has this window been clicked
	js NEAR .tret

	cmp byte [rmbclicked],0 // Was it the right mouse button
	jne NEAR .tret
	
	or cl,cl // Was the Close Window Button Pressed
	jnz .notdestroywindow // Close the Window
	jmp dword [DestroyWindow]
.notdestroywindow:

	cmp cl, 1 // Was the Title Bar clicked
	jne .notwindowtitlebarclicked
	jmp dword [WindowTitleBarClicked] // Allow moving of Window
.notwindowtitlebarclicked:

	cmp cl, 3 // Text box clicked
	jne NEAR .tret
	mov cx, ax
	mov ax, bx
	sub cx, [esi+window.x]
	js NEAR .tret
	sub ax, [esi+window.y]
	sub ax, 14
	js NEAR .tret
	mov ebp, 10
	xor edx, edx
	movzx eax, ax
	div ebp
	movzx ecx, BYTE [esi+window.itemsoffset]
	add eax, ecx
	cmp eax, [numinlist]
	jae NEAR .tret
	mov ecx, [stlist+eax*4]
	mov edx, ecx
	shr edx, 24
	push esi
	dec edx
	js .fret
	je .st
	sub edx, 2
	js .norm
	jnz .fret
//	jz .new
.new:
	mov esi, -2
	jmp .doit
.st:
	movzx esi, cx
	jmp .doit
.norm:
	mov esi, -1
	jmp .doit
.doit:
	mov eax, [adjtile]
	mov ebx, [adjdim]
	mov edx, adjblock
	mov ecx, [adjblocklen]
	call [adjfunc]
.fret:
	pop esi
	jmp dword [DestroyWindow]
.tret:
ret

global createrailstactionhook,createrailstactionhook.oldfn
createrailstactionhook:
	testflags irrstations
	jnc .end
	cmp DWORD [adjflags], 0
	jne .end
	pusha

	rol cx, 8
	mov di, cx
	rol cx, 8
	or  di, ax
	ror di, 4
	movzx eax, di
	//dl=len,dh=tracks
	or bh, bh
	jz .next
	xchg dl, dh
.next:
	movzx ebx, dx
	mov edx, adjstrailstfunc
	mov ecx, 32
	mov esi, esp
	call adjacentstationcheck
	cmp eax, -2
	jle .delay
	popa
.end:
	jmp DWORD $
ovar .oldfn, -4, $,createrailstactionhook
.delay:
	popa
	xor ebx, ebx
	add esp, 4
ret

adjstrailstfunc:
	cmp ecx, 32
	jne NEAR .ret

	cmp esi, -1
	jl .new
	jg .st
.norm:
	push DWORD .end
	mov DWORD [adjflags], 4
	jmp .doit
.new:
	mov DWORD [adjflags], 2
	jmp .fudge
.st:
	shl esi, 16
	or esi, 1
	mov [adjflags], esi
.fudge:
//ugly hack approaching...
//make sure that irrcheckistrainstation gets called by fudging temporarily L5 value
	mov bl, 0x50
	xchg [landscape4(ax,1)-0x101], bl
	push ebx
	push eax
	push DWORD .next
.doit:
	mov edi, [edx]
	mov esi, 0x28
	mov ebp, [edx+8]
	mov ebx, [edx+16]
	mov ecx, [edx+24]
	mov eax, [edx+28]
	mov edx, [edx+20]
	extern actionhandler
	call DWORD [actionhandler]
	cmp ebx, 0x80000000
	jne .inret
	mov bx, [operrormsg1]
	mov dx, [operrormsg2]
	xor ax, ax
	xor cx, cx
	jmp dword [errorpopup]
.inret:
ret

.next:
	pop eax
	pop ebx
	mov [landscape4(ax,1)-0x101], bl
.end:
	mov DWORD [adjflags], 0
.ret:
ret
