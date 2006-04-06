#include <defs.inc>
#include <frag_mac.inc>
#include <ptrvar.inc>


extern ai_buildroadvehicle_actionnum,callrefitship,dailyvehproc
extern dailyvehproc.oldrv,normalrvwindowptr
extern vehtickproc
extern vehtickproc.oldrv


ext_frag newvehstartsound

rvwindowsize equ 0x8d
uvarb rvwindowrefit,rvwindowsize

global patchnewrvs
patchnewrvs:
	stringaddress oldcreatervwindow,1,1
	mov eax,[edi+3]
	mov [normalrvwindowptr],eax
	lea esi,[edi+7]
	mov cl,18
	rep movsb
	storefragment newcreatervwindow

	mov esi,eax
	mov edi,rvwindowrefit
	mov ecx,rvwindowsize
	rep movsb
	mov word [rvwindowrefit+0x5e],0x2b4

	patchcode oldrvwindowfunc,newrvwindowfunc,1+WINTTDX,3
	patchcode oldrvreverse,newrvreverse,1,1
	stringaddress dorefitship,4+WINTTDX,5
	storerelative callrefitship,edi+48

	patchcode oldcheckindock,newcheckindock,1,1

	stringaddress oldaibuyrv,1,2
	mov dword [edi],ai_buildroadvehicle_actionnum

	stringaddress oldaigetrvcost
	mov dword [edi],ai_buildroadvehicle_actionnum

	stringaddress oldaibuyrv,1,0
	mov dword [edi],ai_buildroadvehicle_actionnum

	mov esi,vehtickproc
	mov eax,[ophandler+0x11*8]	// rv vehicle class
	xchg esi,[eax+0x14]		// vehtickproc
	mov [vehtickproc.oldrv],esi

	mov esi,dailyvehproc
	xchg esi,[eax+0x1c]		// dailyvehproc
	mov [dailyvehproc.oldrv],esi

	patchcode oldrvstartsound,newvehstartsound
	patchcode oldrvbreakdownsound,newbreakdownsound
	patchcode rventertunnel
	ret



begincodefragments

codefragment oldcreatervwindow,14
	mov dx,0x88
	db 0xbd,2	// mov ebp,2

codefragment newcreatervwindow
	call runindex(creatervwindow)
	setfragmentsize 7

codefragment oldrvwindowfunc,-26
	or edx,0xc0

codefragment newrvwindowfunc
	call runindex(rvwindowfunc)
	setfragmentsize 13

codefragment oldrvreverse
	test word [edx+veh.vehstatus],3

codefragment newrvreverse
	call runindex(rvreverse)
	jc $+37
	setfragmentsize 13

codefragment dorefitship
	bt dword [esi+0x1e],7
	db 0x0f,0x82	// jb near ...

codefragment oldcheckindock
	and al,0xf0
	cmp al,0x60
	jnz $+2+0x63+WINTTDX

codefragment newcheckindock
	call runindex(checkindock)
	jc $+25+WINTTDX
	setfragmentsize 15+WINTTDX

codefragment oldaibuyrv,3
	mov bl,1
	mov esi,0x88

codefragment oldaigetrvcost,3
	mov bl,0
	mov esi,0x88

codefragment oldrvstartsound,5
	mov eax,0x18

codefragment oldrvbreakdownsound,-11
	mov eax,13

glob_frag newbreakdownsound
codefragment newbreakdownsound
	icall breakdownsound
	jmp fragmentstart+39

codefragment oldrventertunnel,13
	mov [edi+veh.XY],bx
	mov byte [edi+veh.movementstat],-1

codefragment newrventertunnel
	ijmp rventertunnel


endcodefragments
