#include <defs.inc>
#include <frag_mac.inc>


extern aicargovehinittables,electrtextreplace,gettextandtableptrs
extern gettextintableptr,gettrackspriteset.tracktypetemp,monorailtextreplace
extern newgraphicssetsenabled,numelectrtextreplace,nummonorailtextreplace
extern realtracktypes,tracktypes
extern unimaglevmode


global patchelectrifiedrail

begincodefragments

codefragment oldgettrackspriteset
	imul bp,byte 82

codefragment newgettrackspriteset
	call runindex(gettrackspriteset)
	setfragmentsize 11

codefragment oldgetcrossingspriteset
	imul si,byte 12

codefragment newgetcrossingspriteset
	call runindex(getcrossingspriteset)
	setfragmentsize 7

codefragment oldgettunnelspriteset
	and ebx,byte 0xF
	imul bx,byte 8

codefragment newgettunnelspriteset
	call runindex(gettunnelspriteset)
	setfragmentsize 7

codefragment oldgetbridgespriteset
	and si,byte 0xF
	jz short $+2+2

codefragment newgetbridgespriteset
	call runindex(getbridgespriteset)

codefragment oldgetunderbridgespriteset,-3
	imul si,byte 82

codefragment newgetunderbridgespriteset
	call runindex(getunderbridgespriteset)
	setfragmentsize 7

codefragment finddisplayoptions,25
	mov bx,1009
	db 0x66,3	// add bx...

reusecodefragment olddisplaytrackdetails,finddisplayoptions,23

codefragment newdisplaytrackdetails
	call runindex(displtrackdetails)
	setfragmentsize 7

codefragment olddrawcrossing
	mov esi,ebx
	mov bx,1371

codefragment newdrawcrossing
	call runindex(drawcrossing)

codefragment oldistrackrighttype,-8
	and al,0xF
	cmp al,[esi+veh.tracktype]

codefragment newistrackrighttype
	call runindex(istrackrighttype)
	setfragmentsize 8


endcodefragments

patchelectrifiedrail:
	mov byte [tracktypes+1],1
	mov al,[unimaglevmode]
	inc eax
	mov [tracktypes+2],al
	mov byte [realtracktypes+1],1
	mov al,[realtracktypes+3]
	mov [realtracktypes+2],al

	stringaddress oldgettrackspriteset,1,2
	mov eax,[edi+7]
	mov [gettrackspriteset.tracktypetemp],eax
	storefragment newgettrackspriteset
	patchcode oldgettrackspriteset,newgettrackspriteset,1,0
	patchcode oldgetcrossingspriteset,newgetcrossingspriteset,1,1
	patchcode oldgettunnelspriteset,newgettunnelspriteset,1,1
	patchcode oldgetbridgespriteset,newgetbridgespriteset,1,1
	patchcode oldgetunderbridgespriteset,newgetunderbridgespriteset,1,1

	patchcode olddisplaytrackdetails,newdisplaytrackdetails,1,1
	patchcode olddrawcrossing,newdrawcrossing,1,1

	// conversion of types is now done in tools.asm/postinfoapply.typeconversion

	// tell AI to use type=0 waggons for type=1 railways
	mov esi,[aicargovehinittables]
	mov eax,[esi-12]
	mov [esi-8],eax

	patchcode oldistrackrighttype,newistrackrighttype,1,1

	or byte [newgraphicssetsenabled],1 << 5

	// change menu texts etc.

	cmp byte [unimaglevmode],1
	jne .notmonorail

	mov esi,monorailtextreplace
	mov ecx,nummonorailtextreplace
	call .nextelectrtext

.notmonorail:
	mov esi,electrtextreplace
	mov ecx,numelectrtextreplace

.nextelectrtext:
	lodsd		// now ax=new text ID, [esi-2]=text ID to replace
	call gettextandtableptrs
	push edi
	mov eax,[esi-2]
	call gettextintableptr
	pop dword [eax+edi*4]
	loop .nextelectrtext

	sub [eax+edi*4],eax	// was an ourtext() ID which is relative
	ret
