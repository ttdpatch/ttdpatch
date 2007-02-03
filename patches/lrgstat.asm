
// larger stations, 7x7

#include <std.inc>
#include <flags.inc>
#include <station.inc>
#include <human.inc>

extern ctrlkeystate,curcallback,curselstationid,curstattiletype,getnewsprite
extern getplatforminfo.getccpp,grffeature,irrcheckistrainstation
extern irrsetstationsizeext,irrsetstationsizenew,ishumanplayer,miscgrfvar
extern newstationlayout,newstationpos,newstationtracks,patchflags
extern stationsizeofs
extern usenewstationlayout
extern stationarray2ofst,newstationspread



// JGR: Added word-sized platforms var to station2 to provide theoretical max of 255x255 limited by stationsize switch, total station size limited by spread switch
// bit 7 of station.flags is set to use this instead of old platform var
global maxrstationspread
uvarb maxrstationspread

// Oskar: I have hacked to provide bigger stations with 15x15
// TTD and TTDPatch 7x7 station uses this old format to store the byte:
// xxLLLTTT
// To get it most compatible we use now this format;
// TLLLLTTT
//
// This means you shouldn't use the sign bit anymore for any purporse.
// The current usage of the signbit seems to works...
// by Oskar (03/10/09)

// This is a weird proc structure; one of the ret's comes before the proc...
// (the reason being that otherwise I'd have to specify "short" or
// no short for all jumps, that's hard to maintain)

	// no carry says "station too close"
trainstationbad:
	clc

trainstationdone:
	popa
	leave
	ret

global checkistrainstation
checkistrainstation:
	// was mov al,gs:[di]; cmp al,0..7
	// now stc if ok; clc if not
	testflags irrstations
	jc near irrcheckistrainstation

	mov al,[landscape5(di)]
	cmp al,8
	jbe short .istrainstation

	// return, and combine this train station with the existing station
	stc
	ret

.istrainstation:
	enter 0,0
	pusha

	// now the stack is like this:
	//
	// ebp+10	org.ax
	// ebp+0e	org.cx
	// ebp+0c	org.dx
	// ebp+0a	mod.dx
	// ebp+08	org.di
	// ebp+04	ret.eip
	// ebp+00	org.ebp
	// (pusha...)
	// ebp-10	org.ebx (1=test only, 0=do it)
	// ebp-1c	org.esi=station being touched

	%define oldeax ebp+0x10
	%define oldebx ebp-0x10
	%define oldecx ebp+0xe
	%define oldedx ebp+0xc
	%define oldesi ebp-0x1c

	push byte PL_RETURNCURRENT
	call ishumanplayer
	jne trainstationbad

	// now cl=current player, ch=0 for first human, 1 for second human

		// touching station owned by the player?
	cmp byte [landscape1+edi],cl
	jne trainstationbad

		// did we check this new station already?
	or al,[oldedx]		// this does really test [oldedx],80h
	js near .isgoodextension

	movzx esi,byte [landscape2+edi]
	imul esi,station_size
	add esi,stationarray

	movzx eax,word [esi+station.railXY]

	mov bl,[landscape5(ax,1)]
	and bl,1			// now bl = old orientation
	cmp bl,[oldebx+1]
	jne trainstationbad		// different orientation won't work

	//mov bh,byte [esi+station.platforms]	// length of the platforms
	//shr bh,stationlengthshift
	//mov bl,byte [esi+station.platforms]	// number of the platforms
	//and bl,stationtracksand


	test BYTE [esi+station.flags], 80h
	jz .normgetstatlength
	mov eax, [stationarray2ofst]
	add eax, esi
	mov bx, [eax+station2.platforms]
	
	jmp .istoosmall
.normgetstatlength:
	mov al,byte [esi+station.platforms]
	call convertplatformsincargoacceptlist
	mov ebx, eax
.istoosmall:

		// calculate landscape offset of the new position
	mov eax,[oldecx]
	rol ax,8
	or ax,[oldeax]
	ror ax,4			// now ah=new x, al=new y

	push ebx
	testmultiflags newstations
	jz .nobuildover

		// check if we're building over an existing station
	mov ch,[oldedx]		// new length
	mov cl,[oldedx+1]	// new number of platforms

	mov edx,ebx
	test byte [oldebx+1],1	// orientation
	jnz .notflipped
	xchg dh,dl
	xchg ch,cl
.notflipped:
		// X start within station?
		// check newx>=oldx
	mov bx,[esi+station.railXY]
	cmp al,bl
	jb .nobuildover

		// X end within station?
		// check newX+newlength<=oldX+oldlength
		// (length and platforms switch if direction bit set)
	add bl,dl	// oldX+oldlength
	add cl,al	// newX+newlength
	sub cl,bl
	ja .nobuildover

		// same for Y
	cmp ah,bh
	jb .nobuildover

	add bh,dh	// oldY+oldnumplat
	add ch,ah	// newY+newnumplat
	sub ch,bh
	ja .nobuildover

	pop ebx

		// so we're building over, just keep current position and size
	mov ax,[esi+station.railXY]
	mov [newstationpos],ax

	mov al,[esi+station.platforms]
	call convertplatformsincargoacceptlist
	mov [newstationtracks],ax

	or byte [oldedx],0x80
	stc
	jmp trainstationdone

.nobuildover:
	pop ebx
	mov ecx,eax

		// depending on the orientation, either the x or y coordinates
		// must be the same, to add more platforms or make them longer

	cmp byte [oldebx+1],0	// orientation?
	je short .isinxdir

	// in y dir
	cmp al,[esi+0xa]
	je short .makelongerx		// y coordinates match -> make longer
	cmp ah,[esi+0xb]
	jne trainstationbad		// x coordinates don't match

	// x coordinates match, add platforms
.correctx:
	mov ah,[esi+0xa]
	jmp short .checkrightpos

.isinxdir:
	cmp ah,[esi+0xb]		// x coordinates match -> make longer
	je short .makelongery
	cmp al,[esi+0xa]
	jne trainstationbad		// y coordinates don't match

	mov al,ah
	mov ah,[esi+0xb]

.checkrightpos:
		// we come here to add more platforms
		//
		// now al=new pos; ah=old pos; old dh=new size, bl=old size
		//
		// check oldpos+oldsize=newpos, or newpos+newsize=oldpos -> more tracks

	cmp bh,[oldedx]		// first check that the new length is the same
	jne trainstationbad

	mov bh,ah		// is oldpos+oldsize = newpos ?
	add bh,bl
	cmp bh,al
	je short .isrightpos

	mov bh,al		// no, but maybe newpos+newsize = oldpos ?
	add bh,[oldedx+1]
	cmp bh,ah
	jne trainstationbad	// no...


		// position matches, qualifies as an extension
.isrightpos:
	add bl,[oldedx+1]
	// cmp bl, stationtracksmax		// to many tracks?

	cmp bl, [maxrstationspread]	// for realbigstations
	ja trainstationbad

	cmp bl, [newstationspread]
	ja trainstationbad

		// all right, extend the station!
	mov bh,[oldedx]

	cmp al,ah
	jna short .keepposition	// don't switch positions unless new one is smaller
.switchpos:
	mov cx,[esi+0xa]
.keepposition:

	// everything is good, we join all train station platforms

	// bx contains the new platform length (bh) and number of platforms (bl)
	// cx contains the new train facility position

	mov word [newstationpos],cx

/*	shl bh,stationlengthshift
	// for realbigstations
	cmp bl, 8
	jb .dontneedextrabit
	add bl, (80h-8h)
.dontneedextrabit:

	or bl,bh
*/
	mov [newstationtracks],bx

	// set bit 7 in the platform length so that later
	// we'll know we're changing the right station
	or byte [oldedx],0x80

.isgoodextension:
	stc
	jmp trainstationdone


	// we come here if the x or y coordinates don't match, but have
	// same x coord and in y dir, or same y coord and in x dir
	// --> could be trying to make it longer
.makelongerx:

	// swap x and y for convenience
	mov al,ah
	mov ah,[esi+0xb]
	jmp short .makelonger

.makelongery:
	mov ah,[esi+0xa]

.makelonger:
	// here: al=new pos; ah=old pos; old dl=new length, bh=old size
	// check oldpos+oldsize=newpos, or newpos+newsize=oldpos -> more tracks

	cmp bl,[oldedx+1]	// same number of platforms?
	jne trainstationbad

	mov bl,ah		// is oldpos+oldsize = newpos ?
	add bl,bh
	cmp bl,al
	je short .isrightlength

	mov bl,al		// no, but maybe newpos+newsize = oldpos ?
	add bl,[oldedx]
	cmp bl,ah
	jne trainstationbad	// no...

		// position matches, qualifies for making station longer
.isrightlength:
	add bh,[oldedx]

	cmp bh, [maxrstationspread] //15 // for realbigstations / otherwise 7		// too long?
	ja trainstationbad

	cmp bh, [newstationspread]
	ja trainstationbad

		// all right, extend the station!
	mov bl,[oldedx+1]

	cmp al,ah
	jna .keepposition	// don't switch positions unless new one is smaller
	jmp .switchpos

; endp checkistrainstation

global hastrainstation
hastrainstation:
	// was cmp word ptr [esi+0ah],0

	or dl,dl
	js short .extendedstation

	cmp word [esi+0xa],byte 0
	ret
.extendedstation:
	xor edx,0x80000080	// clear sign bit from dl and set it on edx
				// because dl must contain correct value

	cmp al,al		// = set zf
	ret
; endp hastrainstation 

global setstationsize
setstationsize:
	// was mov al,dl; shl al,3; or al,dh
	// now add old size; fix position if edx has sign bit set
	
	//dl=len, dh=tracks
	
	or edx,edx
	js short .extendedstation

.normal:
	push edx	// we need dh,dl, so don't destroy them...
/*	mov al,dl
	shl al,stationlengthshift
	// for realbigstations
	cmp dh, 8
	jb .dontneedextrabit2
	add dh, (80h-8h)
.dontneedextrabit2:
	or al,dh */
	call calcplatformsfornewstation
	pop edx
	testflags irrstations
	jc near irrsetstationsizenew
	ret

.extendedstation:
	mov ax,word [newstationpos]
	mov [esi+0xa],ax

	testflags irrstations
	jc near irrsetstationsizeext
	push edx
	mov dx, [newstationtracks]	// new number and length of tracks
	xchg dh, dl
	call calcplatformsfornewstation
	pop edx
	ret
; endp setstationsize 

#if 0
clearplatformarray:
	push ecx
	mov ecx,(15+1)/2	// (number of platforms+1)/2
.clearnext:
	or dword [newplatformarray+(ecx-1)*4],byte -1
	loop .clearnext
	pop ecx
	ret
; endp clearplatformarray

readplatformarray:
	push ecx
	mov ecx,15+1
.checknext:
	cmp di,[newplatformarray+(ecx-1)*2]
	loopne .checknext
	pop ecx
	ret
; endp readplatformarray
#endif

	// called when checking whether current tile is the train route target
	//
	// in:	al=station index, FF if target isn't station
	//	bx=target tile (north corner of station if station)
	//	edi=tile index to check
	// out:	ZF set if is target, clear if not
	// safe:ax bx
exported isroutetarget
	cmp al,0xff
	jne .station

	cmp di,bx
	ret

	// for station don't check target tile, it might not be part of the
	// station (for irregular stations)
.station:
	mov bl,al
	mov al,[landscape4(di,1)]
	and al,0xf0
	cmp al,0x50
	jne .done	// not a station

	cmp bl,[landscape2+edi]
	jne .done	// wrong station

	cmp byte [landscape5(di,1)],7
	ja .done	// not rail station tile (ZF is clear)

	test al,0
.done:
	ret


	// called when a new # of tracks is selected in station dialog
	//
	// in:  cx=#tracks+5
	// out: cx=#tracks shl 8
	// safe:-
global tracknumsel
tracknumsel:
	sub cl,5
	push byte CTRL_MP
	call ctrlkeystate
	jnz short .notpressed
	add cl,3
.notpressed:
	shl cx,8
	ret
; endp tracknumsel 

	// called when a new platform length is selected in station dialog
	//
	// in:  cx=#tracks+5
	// out: cx=#tracks shl 8
	// safe:-
global tracklensel
tracklensel:
	sub cl,9
	push byte CTRL_MP
	call ctrlkeystate
	jnz short .notpressed
	add cl,2
.notpressed:
	push edi
	mov edi,dword [stationsizeofs]
	and word [edi],0xff00
	pop edi
	ret
; endp tracklensel 

// layout of the stations
uvarb largestationlayout,16*16

createplatformsingle:
	mov al,0
	push ecx
	rep stosb
	pop ecx

	lea eax,[ecx-1]
	shr eax,1
	sub eax,ecx
	mov byte [edi+eax],2
	ret

createplatformmulti:
	push ecx
	rep stosb
	pop ecx

	cmp ecx,byte 4
	jbe .done

	mov eax,ecx
	neg eax
	mov byte [edi+eax],0
	mov byte [edi-1],0

.done:
	ret

// Create station layout
// in:	DH=number of platforms
//	DL=platform length
//	EBP->layout buffer
//	ES=DS
// safe:everything (see codefragment newgetstationlayout)
global getstationlayout
getstationlayout:
	mov edi,ebp
	movzx eax,byte [curplayer]
	movzx eax,byte [curselstationid+eax]
	push eax
	call .getlayout		// fill [ebp] with layout data

	mov edi,ebp
	xor ebx,ebx

.nexttile:
	mov al,[edi]
	mov [curstattiletype],al
	shrd eax,edx,16		// eax=NNLLxxxx
	mov ax,bx		// eax=NNLLCCPP
	call getplatforminfo.getccpp	// kills ecx
	mov [miscgrfvar],eax

	mov byte [curcallback],0x24
	mov byte [grffeature],4
	pop eax
	push eax
	xor esi,esi
	call getnewsprite
	mov byte [curcallback],0
	mov [miscgrfvar],esi	// esi=0
	jc .nooverride
	cmp eax,8
	jae .nooverride
	mov [edi],al
.nooverride:
	inc edi
	inc bl
	cmp bl,dl
	jb .nexttile
	mov bl,0
	inc bh
	cmp bh,dh
	jb .nexttile
	pop eax
	ret

.getlayout:
	mov esi,[newstationlayout+eax*4]
	test esi,esi
	jz .defaultlayout
	call usenewstationlayout
	jz .defaultlayout
	ret

.defaultlayout:
	movzx ecx,dh
	cmp dl,1
	je .single

	mov ebx,ecx
	movzx ecx,dl
	cmp dh,1
	je .single

	shr ebx,1
	jnc .multiloop

	// the odd platform of a multi-platform layout
	call createplatformsingle

.multiloop:
	dec ebx
	js .done

	mov al,4
	call createplatformmulti
	mov al,6
	call createplatformmulti
	jmp .multiloop

.single:
	call createplatformsingle

.done:
	ret

// Fix the various rail station functions to support new format
global calcplatformsfornewstation
calcplatformsfornewstation:
	// in: dl = length, dh = tracks, esi = station ptr
	// dx is needed, so don't change content
	// out: al = platforms as in station array, also sets station ptr value
	push edx
	cmp dl, 15
	ja .bigstation
	cmp dh, 15
	ja .bigstation
	mov al,dl
	shl al, 3
	cmp dh, 8
	jb .dontneedextrabit
	add dh, (80h-8h)
.dontneedextrabit:
	or al,dh
	pop edx
	and BYTE [esi+station.flags], ~0x80
	ret
.bigstation:
	or BYTE [esi+station.flags], 0x80
	mov eax, [stationarray2ofst]
	add eax, esi
	xchg dl, dh
	mov [eax+station2.platforms], dx
	xor eax, eax
	pop edx
ret

;endp calcplatformsfornewstation


global convertplatformsinremoverailstation
convertplatformsinremoverailstation:
	//  in: dl = platforms as in station array, esi = station ptr
	// out: dh = length, dl = tracks
	test BYTE [esi+station.flags], 0x80
	jnz .bigstation
	mov dh, dl
	and dx, 7887h	// Bitmask: 1111000 10000111
	shr dh, 3
	cmp dl, 80h
	jb .issmall
	sub dl, (80h - 8h)
.issmall:
	ret
.bigstation:
	mov edx, [stationarray2ofst]
	add edx, esi
	mov dx, [edx+station2.platforms]
	ret

global convertplatformsincargoacceptlist
convertplatformsincargoacceptlist:
	//  in: al = platforms as in station array, esi = station ptr
	// out: ah = length, al = tracks
	test BYTE [esi+station.flags], 0x80
	jnz .bigstation
	mov ah, al
	and ax, 7887h	// Bitmask: 1111000 10000111
	shr ah, 3
	cmp al, 80h
	jb .issmall
	sub al, (80h - 8h)
.issmall:
	ret
.bigstation:
	mov eax, [stationarray2ofst]
	add eax, esi
	mov ax, [eax+station2.platforms]
	ret
	
global convertplatformsinecx
convertplatformsinecx:
	//  in: cl = platforms as in station array, esi = station ptr
	// out: ch = length, cl = tracks
	test BYTE [esi+station.flags], 0x80
	jnz .bigstation
	mov ch, cl
	and cx, 7887h	// Bitmask: 1111000 10000111
	shr ch, 3
	cmp cl, 80h
	jb .issmall
	sub cl, (80h - 8h)
.issmall:
	ret
.bigstation:
	mov ecx, [stationarray2ofst]
	add ecx, esi
	mov cx, [ecx+station2.platforms]
	ret

