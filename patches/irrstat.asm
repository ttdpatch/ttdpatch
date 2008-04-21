// Irregular Stations
// Copyright 2005 Oskar Eisemuth
//
// TODO:
// newsprit.asm (323): Check Cargo on platform display code
// tools.asm : randomstationtrigger

#include <std.inc>
#include <flags.inc>
#include <proc.inc>
#include <station.inc>
#include <human.inc>
#include <grf.inc>

extern checkvehiclesinthewayfn,cleartilefn,curplayerctrlkey,ishumanplayer
extern locationtoxy,newstationpos,newstationtracks,patchflags
extern stationidgrfmap,newstationspread
extern maxrstationspread


// in:	bl = action flags
//		bh = new station orientation
//		edi = (xy) a station tile being touched
// uses:	all
global irrcheckistrainstation
proc irrcheckistrainstation
	slocal orientation, byte
	
	extern adjflags
	test BYTE [adjflags], 2
	jnz .newst
	test BYTE [adjflags], 1
	jnz .istrainstation

	mov al,[landscape5(di)]
	cmp al,8
	jbe short .istrainstation

	// return, and combine this train station with the existing station
	stc
	ret
.joinstnorailexist:
	popa
	mov cl, [adjflags+2]
	leave
.newst:
	sub DWORD [esp], 8
.ret:
	stc
	ret
.istrainstation:
	_enter
	pusha

	// ebp+10	org.ax // new station precise x
	// ebp+0e	org.cx // new station precise y
	// ebp+0c	org.dx // dx[0] new station length, dx[1] new number of platforms
	// ebp+0a	mod.dx // ?
	// ebp+08	org.di // ?
	// ebp+04	ret.eip
	// ebp+00	org.ebp // by enter

	%define newstationeax ebp+0x10
	%define newstationecx ebp+0xE
	%define newstationlengthplatforms ebp+0xC	// not packed, sign bit used

	// bl = action flags
	// bh = new station orientation
	// edi = (xy) a station tile being touched

	mov [%$orientation], bh

	// check if it's a player
	push byte PL_RETURNCURRENT
	call ishumanplayer
	jne near .donebad
	
	mov esi, [adjflags]
	test esi, 1
	jz .nostjoin
	shr esi, 16
	imul esi, station_size
	add esi, stationarray
	test BYTE [esi+station.facilities], 1
	jz near .joinstnorailexist		//no train station
	cmp cl, [esi+station.owner]
	jne near .donebad
	jmp .gotstptr
.nostjoin:

	cmp byte [landscape1+edi],cl
	jne near .donebad

	movzx esi,byte [landscape2+edi]
	imul esi,station_size
	add esi,stationarray
	// now esi = old station

.gotstptr:
	// did we check this new station already?
	or al,[newstationlengthplatforms]	// this does really test [%$org.dx],80h
	js near .donegood	//.isgoodextension

	call getstationdimplatformslength

	movzx eax, word [newstationecx]
	and eax,byte ~15
	shl eax,8
	or ax, word [newstationeax]
	shr eax,4

	mov cl,[newstationlengthplatforms]		// new length
	mov ch,[newstationlengthplatforms+1]	// new number of platforms
	
	test byte [%$orientation],1	// orientation
	jz .notflipped
	xchg ch,cl
.notflipped:
	sub cx, 0x101
	add cl, al
	add ch, ah
	
	mov bx, word [irrgetstationinfoblock+irrgetstationinfo.minxy]
	mov dx, word [irrgetstationinfoblock+irrgetstationinfo.maxxy]
	
	// ax = new north
	// bx = old north
	// cx = new south
	// dx = old south
	
	// min function
	
	cmp al, bl
	jb .noswitchnorthx
	xchg al, bl
.noswitchnorthx:
	
	cmp ah, bh
	jb .noswitchnorthy
	xchg ah, bh
.noswitchnorthy:
	// now ax most north 
	
	// max function
	cmp cl, dl
	ja .noswitchsouthx
	xchg cl, dl
.noswitchsouthx:
	
	cmp ch, dh
	ja .noswitchsouthy
	xchg ch, dh
.noswitchsouthy:

	// now cx most south
	mov word [newstationxysouth], cx

	sub cl, al
	sub ch, ah

	add cx, 0x101

	cmp cl, [maxrstationspread]
	ja .donebad
	cmp ch, [maxrstationspread]
	ja .donebad

	cmp cl, [newstationspread]
	ja .donebad
	cmp ch, [newstationspread]
	ja .donebad

	// now check what direction our new station should get
	mov word [newstationpos],ax
	
	test byte [%$orientation],1	// orientation
	jnz .notflipped2
	xchg ch,cl
.notflipped2:

	// ch platform length
	// cl number of platforms 

/*	shl cl,stationlengthshift
	// for realbigstations
	cmp ch, 8
	jb .dontneedextrabit
	add ch, (80h-8h)
.dontneedextrabit:

	or ch,cl
	*/
//	xchg cl, ch
	mov [newstationtracks],cx
	

	or byte [newstationlengthplatforms],0x80
.donegood:
	test BYTE [adjflags], 1
	jnz NEAR .joinstnorailexist
	stc
	jmp short .leave
.donebad:
	clc
.leave:
	popa
	_ret
	ret
endproc irrcheckistrainstation

uvarw newstationxysouth, 1

// in:	esi=station
//		bh=direction
//		dl=length, dh=tracks
// uses:	nothing
global irrsetstationsizenew
irrsetstationsizenew:
	push eax
	push edx
	sub dx, 0x101
	or bh, bh
	jz .noswitch
	xchg dl, dh
.noswitch:
	mov ax, word [esi+station.railXY]
	add al, dl
	add ah, dh
	mov word [esi+station2ofs+station2.railxysouth], ax
	pop edx
	pop eax
	ret

global irrsetstationsizeext
irrsetstationsizeext:
	push eax
	mov ax, [newstationxysouth]
	mov word [esi+station2ofs+station2.railxysouth], ax
	pop eax
	ret


// in:	esi=railstaion 
// out:	dx=south corner
// uses:	-
global irrgetrailxysouth
irrgetrailxysouth:
global irrconvertplatformsincargoacceptlist
irrconvertplatformsincargoacceptlist:
	cmp word [esi+station2ofs+station2.railxysouth], 0
	jz .needrecalc
	mov dx, word [esi+station2ofs+station2.railxysouth]
	ret
.needrecalc:
	call getstationdimplatformslength
	mov dx, word [irrgetstationinfoblock+irrgetstationinfo.maxxy]
	mov word [esi+station2ofs+station2.railxysouth], dx
	ret
;endp irrconvertplatformsincargoacceptlist

struc irrgetstationinfo
	.maxxy:
	.maxx: resb 1
	.maxy: resb 1
	.minxy:
	.minx: resb 1
	.miny: resb 1
	.dir: resb 2
endstruc

uvarb irrgetstationinfoblock, irrgetstationinfo_size

// in:	esi=station 
// out:	irrgetstationinfoblock
//		word irrgetstationinfoblock.dir = 0 no station found
// uses:	- 
getstationdimplatformslength:
	mov word [irrgetstationinfoblock+irrgetstationinfo.maxxy], 0
	mov word [irrgetstationinfoblock+irrgetstationinfo.minxy], 0xFFFF
	mov word [irrgetstationinfoblock+irrgetstationinfo.dir], 0

	push eax
	push ecx
	mov ecx, 0
.nexttile:
	mov al, [landscape4(cx,1)]
	and al, 0xF0
	cmp al, 0x50
	jne .checkdone

	mov al, byte [landscape5(cx,1)]
	cmp al, 7 // station
	ja .checkdone

	movzx eax,byte [landscape2+ecx]
	imul eax,station_size
	add eax,stationarray
	cmp eax, esi
	jne .checkdone
	
	cmp cl, byte [irrgetstationinfoblock+irrgetstationinfo.maxx]
	jb .maxnextx
	mov byte [irrgetstationinfoblock+irrgetstationinfo.maxx], cl
.maxnextx:
	cmp cl, byte [irrgetstationinfoblock+irrgetstationinfo.minx]
	ja .minnextx
	mov byte [irrgetstationinfoblock+irrgetstationinfo.minx], cl
.minnextx:
	
	cmp ch, byte [irrgetstationinfoblock+irrgetstationinfo.maxy]
	jb .maxnexty
	mov byte [irrgetstationinfoblock+irrgetstationinfo.maxy], ch
.maxnexty:
	cmp ch, byte [irrgetstationinfoblock+irrgetstationinfo.miny]
	ja .minnexty
	mov byte [irrgetstationinfoblock+irrgetstationinfo.miny], ch
.minnexty:

	xor eax, eax
	mov al, byte [landscape5(cx,1)]
	and al, 0x1
	inc byte [irrgetstationinfoblock+irrgetstationinfo.dir+eax]
	
.checkdone:
	inc ecx
	cmp ecx, 0xFFFF
	jb .nexttile
	
	pop ecx
	pop eax
	ret



// Helper function for irrremoverailstation
// in esi = station
proc fixstationplatformslength
	slocal maxx, byte 
	slocal maxy, byte
	slocal minx, byte
	slocal miny, byte
	slocal dir, byte, 2

	_enter
	
	mov byte [%$maxx], 0
	mov byte [%$maxy], 0
	mov byte [%$minx], 0xFF
	mov byte [%$miny], 0xFF
	mov word [%$dir], 0
	
	mov ecx, 0
.nexttile:
	mov al, [landscape4(cx,1)]
	and al, 0xF0
	cmp al, 0x50
	jne .checkdone

	mov al, byte [landscape5(cx,1)]
	cmp al, 7	// station
	ja .checkdone

	movzx eax,byte [landscape2+ecx]
	imul eax,station_size
	add eax,stationarray
	cmp eax, esi
	jne .checkdone
	
	cmp cl, byte [%$maxx]
	jb .maxnextx
	mov byte [%$maxx], cl
.maxnextx:
	cmp cl, byte [%$minx]
	ja .minnextx
	mov byte [%$minx], cl
.minnextx:
	
	cmp ch, byte [%$maxy]
	jb .maxnexty
	mov byte [%$maxy], ch
.maxnexty:
	cmp ch, byte [%$miny]
	ja .minnexty
	mov byte [%$miny], ch
.minnexty:

	xor eax, eax
	mov al, byte [landscape5(cx,1)]
	and al, 0x1
	inc byte [%$dir+eax]


.checkdone:
	inc ecx
	cmp ecx, 0xFFFF
	jb .nexttile
	
	// now we have minx, maxx, miny, maxy, 
	// dir[0] how many x direction, 
	// dir[1] how many y direction
	cmp word [%$dir], 0
	jz .notilesleft
	mov dl, byte [%$minx]
	mov dh, byte [%$miny]
	mov word [esi+station.railXY], dx

	mov bl, byte [%$maxx]
	mov bh, byte [%$maxy]

	mov word [esi+station2ofs+station2.railxysouth], bx

	sub bl, dl
	sub bh, dh
	add bx, 0x0101
	
	mov dx, word [%$dir]
	cmp dl, dh
	jae .noswitch
	xchg bl, bh
.noswitch:

	test bx, 0xF0F0
	jnz .bigstation

	mov dl, bl
	shl dl, stationlengthshift
	cmp bh, 8
	jb .dontneedextrabit2
	add bh, (80h-8h)
.dontneedextrabit2:
	or dl, bh
	mov byte [esi+station.platforms], dl
	and BYTE [esi+station.flags], ~0x80
	jmp short .done
	
.bigstation:
	or BYTE [esi+station.flags], 0x80
	xchg bl, bh
	mov [esi+station2ofs+station2.platforms], bx
	jmp short .done

.notilesleft:
	mov word [esi+station.railXY], 0
	and byte [esi+station.facilities], 0xFE
	mov byte [esi+station.platforms], 0
	and BYTE [esi+station.flags], ~0x80
.done:
	_ret
	ret
endproc fixstationplatformslength
	
// in:	esi = station
uvard irrremoverailstationcost, 1
global irrremoverailstation
irrremoverailstation:
	//we can't know if the station platforms/length are stored, because 
	//esi+station.railXY could be a non platform or later changedin direction
	mov dword [irrremoverailstationcost], 0
	movzx edi, word [esi+station.railXY]
	
	push byte PL_RETURNCURRENT
	call ishumanplayer
	jne near .normal
	
	cmp byte [curplayerctrlkey],1
	jnz .removeplatform
	
	push esi
	mov ax, [esp+6]
	mov cx, [esp+4]
	call locationtoxy
	mov edi, esi
	pop esi

	mov dl, 1	//x
	mov dh, 1	//y
	xor eax, eax
	mov al, dl
	jmp .nexttile

// ----------------------------------------
.removeplatform:
	push esi
	mov ax, [esp+6]
	mov cx, [esp+4]
	call locationtoxy
	mov edi, esi
	pop esi
	
	mov ecx, edi
	
	xor edx, edx
	xor eax, eax
	mov dl,1
	mov ah,[landscape5(di,1)]
	and ah,1
	jz .removeplatformstart
	mov edx, eax
.removeplatformstart:
	neg edx
	
.removeplatformnexttile:
	add edi, edx
	mov al, [landscape4(di,1)]
	and al, 0xF0
	cmp al, 0x50
	jne .gotend1
	
	mov al,[landscape5(di,1)]
	cmp al, 7	// train station 
	ja .gotend1
	and al, 1
	cmp al, ah
	jne .gotend1
	
	call removestationtile
	jc .errorvehicle
	jmp .removeplatformnexttile
	
.gotend1:
	mov edi, ecx
	neg edx
	
.removeplatformnexttile2:
	mov al, [landscape4(di,1)]
	and al, 0xF0
	cmp al, 0x50
	jne .gotend2
	
	mov al,[landscape5(di,1)]
	cmp al, 7	// train station 
	ja .gotend2
	and al, 1
	cmp al, ah
	jne .gotend2
	
	call removestationtile
	jc .errorvehicle
	add edi, edx
	jmp .removeplatformnexttile2

.gotend2:
	jmp .checkbuildflags

// ----------------------------------------
.normal:
	mov dl, 15	//x
	mov dh, 15	//y
	xor eax, eax
	mov al, dl

.nexttile:
	call removestationtile
	jc .errorvehicle
	
	inc edi
	dec dl
	jnz .nexttile

	sub edi, eax
	add edi, 0x100

	mov dl, al
	dec dh
	jnz .nexttile

.checkbuildflags:
	test bl, 1
	jz .updatestationdone
	pusha
	call fixstationplatformslength
	popa
	//mov word [esi+station.railXY], 0
	//and byte [esi+station.facilities], 0xFE
	
.updatestationdone:
	mov ebx, [irrremoverailstationcost]
	push ebx
	jmp near $
ovar .origfn, -4, $,irrremoverailstation

.errorvehicle:
	pop cx
	pop ax
	mov ebx, 0x80000000
	ret

removestationtile:
	push eax
	push ecx
	// check tile for station
	mov al, [landscape4(di)]
	and al, 0xF0
	cmp al, 0x50
	je .isstationtile

	// to make jmps from below shorter
.done:
.notremoving:
	pop ecx
	pop eax
	clc
	ret

.remerrorvehicle:
	pop ecx
	pop eax
	stc
	ret
	
.isstationtile:
	mov al, byte [landscape5(di,1)]
	cmp al, 7	// station
	ja  .notremoving

	movzx eax,byte [landscape2+edi]
	imul eax,station_size
	add eax,stationarray
	cmp eax, esi
	jne .notremoving

	call dword [checkvehiclesinthewayfn]
	jnz .remerrorvehicle

	// could do a callback here to have different prices for removeing
	mov eax, dword [remplatformcost]
	add dword [irrremoverailstationcost], eax

	test bl,1
	jz .notremoving

	// adjust newstation tile count
	// (must do this before cleartile which deletes L3)
	testflags newstations
	jnc .nonewstation

	movzx eax,byte [landscape3+edi*2+1]
	test eax,eax
	jz .nonewstation
	dec word [stationidgrfmap+eax*8+stationid.numtiles]

.nonewstation:
	// fix var 41 of surrounding tiles (if they're station tiles)
	mov eax,1
	test [landscape5(cx,1)],al
	jz .havedir
	xchg al,ah
.havedir:
	sub edi,eax
	mov cl,0x40
	call .fixvar41		// edi-1length
	lea edi,[edi+eax*2]
	mov cl,0x10
	call .fixvar41		// edi+1length
	sub edi,eax
	xchg al,ah
	sub edi,eax
	mov cl,0x80		// edi-1plat
	call .fixvar41
	lea edi,[edi+eax*2]
	mov cl,0x20
	call .fixvar41		// edi+1plat
	sub edi,eax		// restore edi

	// try to remove tile
	rol di,4
	mov eax,edi
	mov ecx,edi
	ror di,4
	rol cx,8
	and ax,0xff0
	and cx,0xff0
	// will remove L6, L7 via fixmisc aswell
	call dword [cleartilefn]
	jmp .done

.fixvar41:
	mov ch,[landscape4(di,1)]
	and ch,0xf0
	cmp ch,0x50
	jne .nofix

	cmp byte [landscape5(di,1)],8
	jae .nofix

	or [landscape6+edi],cl
.nofix:
	ret


// get length of current platform
// in:	esi=tile XY of one tile of the platform
// out:	eax=platform length (0 if current tile is not a station tile)
//	esi=tile XY of beginning of platform
// uses:
global getirrplatformlength
getirrplatformlength:
	push edx
	push esi

	xor eax,eax

	lea edx,[eax+1]		// now edx=1
	mov ah,[landscape5(si,1)]
	and ah,1	// orientation
	jz .nexttile

	mov edx,eax		// eax = 0x100

.nexttile:
	mov al,[landscape4(si,1)]
	and al,0xf0
	cmp al,0x50
	jne .gotend	// not a station tile

	mov al,[landscape5(si,1)]
	cmp al, 7
	ja .gotend

	and al,1
	cmp al,ah
	jne .gotend	// wrong direction

	add esi,edx
	add eax,0x10000
	jmp .nexttile

.gotend:
	test edx,edx
	js .done

	mov esi,[esp]
	cmp eax,0x10000
	jb .done	// no station tile at all

	sub esi,edx	// continue in other direction
	neg edx
	jmp .nexttile

.done:
	sub esi,edx	// adjust esi to lowest valid station tile
	shr eax,16
	pop edx		// clear esi off the stack
	pop edx
	ret
