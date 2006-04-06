#include <defs.inc>
#include <frag_mac.inc>
#include <ptrvar.inc>
#include <player.inc>

extern dailyvehproc,dailyvehproc.oldrail,drawsplittextfn,drawtextfn
extern fnshowtrainsprites,movetrainvehicle,newbuyrailvehicle
extern newsellrailengine,nexttrainvehthreshold,oldbuyrailvehicle
extern oldsellrailengine,prevtrainveh
extern recordtraincrash,vehtickproc
extern vehtickproc.oldrail

#include <textdef.inc>

ext_frag oldtrainshipbreakdownsound,newbreakdownsound

global patchnewtrains,patchnewtrains.expandnewvehwindow

begincodefragments

codefragment olddisplaytraininfosprite,-3
	db 14
	add dx,6
	db 0xbf		// mov edi,imm32

codefragment newdisplaytraininfosprite
	call runindex(displaytraininfosprite)
	setfragmentsize 8

codefragment newshowactivetrainveh
	call runindex(showactivetrainveh)
	setfragmentsize 9

codefragment oldshowtraindetailssprite,1
	push edi
	mov al,1

codefragment newshowtraindetailssprite
	call runindex(showtraindetailssprite)
	setfragmentsize 7

codefragment oldfindtraindetailveh
	dec al
	jns $+2+0x58

codefragment newfindtraindetailveh
	call runindex(findtraindetailveh)

codefragment oldcounttrainslots
	mov di,[edi+veh.nextunitidx]
	inc cl

codefragment newcounttrainslots
	call runindex(counttrainslots)

codefragment olddisplaytraininfotext
	db 30
	add dx,2

codefragment newdisplaytraininfotext
	db 38

codefragment oldchoosetrainvehindepot
	dec al
	js $+2+0x1a

codefragment newchoosetrainvehindepot
	jmp runindex(choosetrainvehindepot)

codefragment oldtrainleavedepot,-7
	jne $+2+0x3e
	shr esi,1
	db 0x8a,0x96	// mov dl,[esi+...]

codefragment newtrainleavedepot
	call runindex(trainleavedepot)
	setfragmentsize 7

codefragment olddisplaytrainindepot
	add cx,0x1d
	mov di,[edi+veh.nextunitidx]

codefragment newdisplaytrainindepot
	call runindex(displaytrainindepot)
	setfragmentsize 8

codefragment oldtrainentersdepot
	or word [edi+veh.vehstatus],1
	db 0x80		// xor ...

codefragment newtrainentersdepot
	call runindex(trainentersdepot)
	setfragmentsize 9

codefragment findmovetrainvehicle,4
	or ah,ah
	jz $+2+0x36
	push ax

codefragment findrecordtraincrash,4
	cmp ax,6
	jae $+2+6

codefragment oldshowlocoinfo
	mov [textrefstack+0x16],ah

codefragment newshowlocoinfo
	call runindex(showlocoinfo)
	push esi
	mov bx,statictext(engineinfodisplay)

codefragment olddetachfromsoldengine,-6
	mov dx,[eax+veh.nextunitidx]
	push dx

codefragment newdetachfromsoldengine
	call runindex(detachfromsoldengine)
	push dx
	jc newdetachfromsoldengine_start+36
	setfragmentsize 12

codefragment oldsellnextenginepart,22
	mov si,[edx+veh.nextunitidx]

codefragment newsellnextenginepart
	jmp $-27

codefragment oldaichoosetracktype
	mov al,[esi+player.tracktypes]

codefragment newaichoosetracktype
	call newaichoosetracktype_start+19
	call runindex(aichoosetracktype)
	ret

codefragment oldaibuildrailwagon,11
	movzx ebx,word [ebx+edx*2]

codefragment newaibuildrailwagon
	call runindex(aibuildrailwagon)
	setfragmentsize 10

codefragment oldaibuyrailengine,2
	mov bl,1
	mov esi,0x80

codefragment newaibuyrailengine
	call runindex(aibuyrailengine)
	setfragmentsize 10

codefragment newaisellextrawagons
	call runindex(aisellextrawagons)
	jmp newaisellextrawagons_start+40

codefragment oldaigetrailenginecost,2
	mov bl,0
	mov esi,0x80

codefragment newaigetrailenginecost
	call runindex(aigetrailenginecost)
	setfragmentsize 10

codefragment newaireplacerailengine
	call runindex(aireplacerailengine)
	setfragmentsize 10

codefragment oldshowvehinfosprite,-2
	xchg bx,[edi+veh.cursprite]
	push ax

codefragment newshowvehinfosprite
	call runindex(showvehinfosprite)
	setfragmentsize 12

codefragment createnewtrainwindowsize,-4
	mov dx,0x80
	db 0xbd,4	// mov ebp,4

codefragment oldgentrainviseffect,4
	mov di,2
gentrainviseffecttype equ $-2
	db 0x8b,0x2d	// mov ebp,[ppOpClass14]

codefragment newgentrainviseffect
	icall gentrainviseffect


endcodefragments

patchnewtrains:
	patchcode olddisplaytraininfosprite,newdisplaytraininfosprite,1,1
	add edi,lastediadj+44
	storefragment newshowactivetrainveh

	stringaddress oldshowtraindetailssprite
	copyrelative fnshowtrainsprites,3
	storefragment newshowtraindetailssprite

	patchcode oldfindtraindetailveh,newfindtraindetailveh
	patchcode oldcounttrainslots,newcounttrainslots

	patchcode olddisplaytraininfotext,newdisplaytraininfotext,1,1
	patchcode oldchoosetrainvehindepot,newchoosetrainvehindepot,1,1
	mov word [edi+lastediadj-18],0xc38b	// mov eax,ebx instead of mov al,bl

	stringaddress oldtrainleavedepot,1,1
	mov eax,[edi+3]
	mov [nexttrainvehthreshold],eax
	storefragment newtrainleavedepot
	patchcode olddisplaytrainindepot,newdisplaytrainindepot,1,1
	patchcode oldtrainentersdepot,newtrainentersdepot,1,1

	storeaddress findmovetrainvehicle,1,1,movetrainvehicle,65
	mov eax,[edi-8]
	mov [prevtrainveh],eax
	storeaddress findrecordtraincrash,1,1,recordtraincrash

	patchcode oldshowlocoinfo,newshowlocoinfo,1,1
	mov eax,[drawsplittextfn]
	sub eax,[drawtextfn]
	add [edi+lastediadj+0x11],eax

	mov eax,[ophandler+0x10*8]		// class 10: rail vehicles
	mov eax,[eax+0x10]			// 	action handler
	mov esi,[eax+9]				// 	action handler table

	mov eax,addr(newbuyrailvehicle)
	xchg eax,[esi]
	mov [oldbuyrailvehicle],eax

	mov eax,addr(newsellrailengine)
	xchg eax,[esi+1*4]
	mov [oldsellrailengine],eax

	patchcode olddetachfromsoldengine,newdetachfromsoldengine
	patchcode oldsellnextenginepart,newsellnextenginepart,1+WINTTDX,2
	mov byte [edi+lastediadj-20],0x76	// mov si,[*esi*+veh.nextunitidx]

	patchcode oldaichoosetracktype,newaichoosetracktype
	patchcode oldaibuildrailwagon,newaibuildrailwagon
	patchcode oldaibuyrailengine,newaibuyrailengine,1,2
	add edi,lastediadj+30
	storefragment newaisellextrawagons
	patchcode oldaigetrailenginecost,newaigetrailenginecost
	patchcode oldaibuyrailengine,newaireplacerailengine,1,0
	patchcode oldshowvehinfosprite,newshowvehinfosprite,1+2*WINTTDX,4

	mov esi,vehtickproc
	mov eax,[ophandler+0x10*8]	// rail vehicle class
	xchg esi,[eax+0x14]		// vehtickproc
	mov [vehtickproc.oldrail],esi

	mov esi,dailyvehproc
	xchg esi,[eax+0x1c]		// dailyvehproc
	mov [dailyvehproc.oldrail],esi

#if 0
	push dword [newvehicles]
	call malloc
	pop dword [trainpowercacheptr]
	jnc .gotpowercache

	// could not allocate memory, disable callback for power
	and byte [validvehcallbacks+0],~1

.gotpowercache:
	push dword [newvehicles]
	call malloc
	pop dword [loadamountcacheptr]
	jnc .gotloadamountcache

	// could not allocate memory, disable callbacks for load amount
	and dword [validvehcallbacks+0],~0x04040404

.gotloadamountcache:
	// resolve cache pointers in the callbackinfo strucs
.nextvehclass:
	mov esi,[cachedvehcallbacks+ecx*4]

.nextcallback:
	lodsb
	cmp al,0xff
	je .classdone

	lodsb
	lodsd
	mov eax,[eax]
	mov [esi-4],eax
	lodsd
	jmp .nextcallback

.classdone:
	inc ecx
	cmp ecx,4
	jb .nextvehclass
#endif

	// increase width of the new railway vehs window to accomodate for longer names
	mov cl,2		// ECX=0 after the patchcode above
.crntwsizeloop:
	push ecx
	stringaddress createnewtrainwindowsize,ecx,2
	xor ebx,ebx
	mov bl,240		// min. X size
	sub bx,[edi]
	jns .gotntwsizeinc
	xor ebx,ebx		// window already larger -- no change
.gotntwsizeinc:
	add [edi],ebx
	add word [edi+2],60
	pop ecx
	loop .crntwsizeloop
	call .expandnewvehwindow
	// also make the info box longer by six lines
	mov ebx,(60 << 16)+60
	add [edi+56],bx
	add [edi+66],ebx
	add [edi+78],ebx

	patchcode oldtrainshipbreakdownsound,newbreakdownsound,1,2

	patchcode gentrainviseffect
	mov byte [gentrainviseffecttype],4
	patchcode gentrainviseffect,1,2
	patchcode gentrainviseffect,1,0
	mov byte [gentrainviseffecttype],6
	patchcode gentrainviseffect
	ret

	// this subproc is common for new train and ship windows
.expandnewvehwindow:
	mov edi,[edi+21]
	add [edi+12*1+4],ebx
	add [edi+12*2+4],ebx
	add [edi+12*3+2],ebx
	add [edi+12*3+4],ebx
	add [edi+12*4+4],ebx
	add [edi+12*6+4],ebx
	shr ebx,1
	add [edi+12*5+4],ebx
	add [edi+12*6+2],ebx
	ret
