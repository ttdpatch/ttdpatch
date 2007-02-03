#include <defs.inc>
#include <frag_mac.inc>
#include <vehtype.inc>

extern airankcheck.bestrankofs,isengine

global patchrailvehiclelist

begincodefragments

codefragment oldmonthlyengineloop,3
	jb short .noret
	ret
.noret:
	db 0xbe		// mov esi,offset enginestruct

codefragment newmonthlyengineloop
	call runindex(monthlyengineloop)
	setfragmentsize 8,1

codefragment oldvehphase2
	mov ax,[esi+vehtype.reliabmax]
	mov [esi+vehtype.reliab],ax

codefragment newvehphase2
	ijmp vehphase2

codefragment newvehphase3
	icall vehphase3
	setfragmentsize 8

codefragment oldskiprailvehsinwindow,3
	mov cl,[esi+1dh]
	bt [eax],bp

codefragment newskiprailvehsinwindow
	call runindex(skiprailvehsinwindow)
	jnc short $+2+2

codefragment oldcountrailvehtypes,27
	movzx edx,word [esi+2ah]

codefragment newcountrailvehtypes
	call runindex(countrailvehtypes)
	setfragmentsize 7

codefragment oldisrailvehonlist,-12
	pop cx
	jnc near $+6+0ebh

codefragment newisrailvehonlist
	call runindex(israilvehonlist)
	jmp short $+2+4			// skip over BT [EAX],CX to the POP CX above

codefragment newisrailvehonlist2
	call runindex(israilvehonlist2)

codefragment oldiswaggontypeb,4
	movzx ebx,byte [edi+veh.tracktype]

codefragment newiswaggontypeb
	bt [isengine],ax

codefragment oldcanaiusedualhead
	movzx eax,byte [edx+veh.tracktype]

codefragment newcanaiusedualhead
	call runindex(canaiusedualhead)
	jmp short $+20

codefragment oldisaipassengerservice
	cmp byte [esi+0x326],0

codefragment newisaipassengerservice
	mov bl,[esi+0x326]
	test bl,~2		// NZ if (BL<>0 & BL<>2)
	jz short $+0xC
	jmp short $+7

codefragment oldgethighestrailtype
	cmp dx,byte 27

codefragment newgethighestrailtype
	bt [isengine],dx
	jc short $+0x1C
	db 0xEB		// jc -> jmp

reusecodefragment oldadjustenginereliab,oldmonthlyengineloop,17

codefragment newadjustenginereliab
	bt [isengine],cx
	jmp $+2+26	// was jb
	jmp $+2+37

codefragment oldsetdurphase2
	imul bx,12

codefragment newsetdurphase2
	icall setdurphase2
	setfragmentsize 11

codefragment oldairankcheck,5
	mov al,[ailastairank]

codefragment newairankcheck
	icall airankcheck


endcodefragments

patchrailvehiclelist:
	multipatchcode oldskiprailvehsinwindow,newskiprailvehsinwindow,3
	mov esi,[edi+lastediadj-15]
	lodsd			// this is pointer to engine array (dsbase+0x751A2)
	mov edi,esi
	times 2 stosd		// copy it over the next 2 dwords
	xor eax,eax
	mov al,NTRAINTYPES
	times 3 stosb
	xor eax,eax
	stosd
	stosw
	mov eax,[edi+8]
	times 3 stosd
	xor eax,eax
	stosd
	stosw
	mov al,NTRAINTYPES
	times 3 stosw

	patchcode oldcountrailvehtypes,newcountrailvehtypes,1,2
	patchcode oldisrailvehonlist,newisrailvehonlist,1,1
	add edi,byte lastediadj+40
	storefragment newisrailvehonlist2
	mov byte [edi+lastediadj+0xD0],0x5D			// o16 -> pop ebp (see israilvehonlist2)
	patchcode oldiswaggontypeb,newiswaggontypeb,1,1
	multipatchcode oldcanaiusedualhead,newcanaiusedualhead,2
	patchcode oldisaipassengerservice,newisaipassengerservice,1,1
	patchcode oldgethighestrailtype,newgethighestrailtype,1,1
	patchcode oldadjustenginereliab,newadjustenginereliab,1,1
	stringaddress oldairankcheck
	mov eax,[edi+2]
	mov [airankcheck.bestrankofs],eax
	storefragment newairankcheck
	patchcode setdurphase2
	ret


// shares some code fragments
global patchpersistentengines
patchpersistentengines:
	patchcode oldmonthlyengineloop,newmonthlyengineloop,1,1
	patchcode vehphase2
	add edi,lastediadj+9
	storefragment newvehphase3
	ret
