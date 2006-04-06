#if WINTTDX

#include <defs.inc>
#include <frag_mac.inc>
#include <textdef.inc>
#include <window.inc>
#include <station.inc>

extern recnetack.bytetocheck,newenumplayers

global patchenhmulti
patchenhmulti:
	patchcode oldmaxplayernum,newmaxplayernum,1,1
	patchcode oldplayerenumerate,newplayerenumerate,1,1
	patchcode oldcheckcancel,newcheckcancel,1,1
	stringaddress oldrecnetack,1,1
	mov eax,[edi+2]
	mov [recnetack.bytetocheck],eax
	storefragment newrecnetack
	patchcode oldsendnetack,newsendnetack1,1,3
	patchcode oldsendnetack,newsendnetack1,1,2
	patchcode oldsendnetack,newsendnetack2,1,1
	patchcode oldinitclient,newinitclient,1,3
	patchcode oldinitserver,newinitserver,1,4
	multipatchcode oldcheckhuman2al,newcheckhuman2al,13
	patchcode oldcheckhuman2ah,newcheckhuman2ah,1,1
	multipatchcode oldcheckhuman2bl,newcheckhuman2bl,13
 	patchcode oldcheckhuman2bh,newcheckhuman2bh,1,1
	patchcode oldcheckhuman2cl,newcheckhuman2cl,1,1
	multipatchcode oldcheckhuman2dl,newcheckhuman2dl,6
	patchcode oldtickprocallcompanies,newtickprocallcompanies,1,1
	patchcode oldstartnewgame,newstartnewgame,1,2
	patchcode oldstartnewgame,newstartnewgame2,1,1
	patchcode oldloadtitlescreen,newloadtitlescreen,1,1
//	patchcode oldrandom,newrandom,1,1
	patchcode oldcreateplayermsgwindow,newcreateplayermsgwindow,1,1
	patchcode oldplayermsgtitle,newplayermsgtitle,1,1
	patchcode oldplayermsgface,newplayermsgface,1,1
	patchcode oldfindzeppelintarget,newfindzeppelintarget,1,1
	patchcode oldswitchbacktosingle,newswitchbacktosingle,1,1
	patchcode oldloadfilemask2pl,newloadfilemask2pl,1,1
	patchcode oldtransmitloadfail,newtransmitloadfail,1,1
	patchcode oldtransmitloadsuccess,newtransmitloadsuccess,1,1

	patchcode mainmenu2playerbutton
	patchcode mainmenu2playertooltip
	ret

begincodefragments

codefragment oldmaxplayernum,3
	mov dword [ebp-0x80],2

codefragment newmaxplayernum
	db 8

codefragment oldplayerenumerate,1
	push 0x401a64

codefragment newplayerenumerate
	dd addr(newenumplayers)

codefragment oldcheckcancel
	cmp dword [0x42026c],0

codefragment newcheckcancel
	setfragmentsize 20, 1

codefragment oldrecnetack,20
	pop ecx
	cmp eax,0
	je $+2-83

codefragment newrecnetack
	icall recnetack

codefragment oldsendnetack,5
	mov ecx,2
	push ecx

codefragment newsendnetack1
	icall sendnetack1
	setfragmentsize 9

codefragment newsendnetack2
	icall sendnetack2
	setfragmentsize 9

codefragment oldinitclient
	mov byte [human1],-2
	mov byte [human2],-1
	mov byte [mpcomputer],0

codefragment newinitclient
	icall initclient
	setfragmentsize 14

codefragment oldinitserver,7
	mov byte [mpcomputer],1
	mov byte [human1],-1
	mov byte [human2],-2

codefragment newinitserver
	icall initserver
	setfragmentsize 14

codefragment oldcheckhuman2al
	cmp al,[human2]

codefragment newcheckhuman2al
	icall checkhuman2al

codefragment oldcheckhuman2ah
	cmp ah,[human2]

codefragment newcheckhuman2ah
	icall checkhuman2ah

codefragment oldcheckhuman2bl
	cmp bl,[human2]

codefragment newcheckhuman2bl
	icall checkhuman2bl

codefragment oldcheckhuman2bh
	cmp bh,[human2]

codefragment newcheckhuman2bh
	icall checkhuman2bh

codefragment oldcheckhuman2cl
	cmp cl,[human2]

codefragment newcheckhuman2cl
	icall checkhuman2cl

codefragment oldcheckhuman2dl
	cmp dl,[human2]

codefragment newcheckhuman2dl
	icall checkhuman2dl

codefragment oldtickprocallcompanies,27
	cmp byte [gamemode],0
	je $+2+9
	cmp byte [gamesemaphore],0
	je $+2+0x6c

codefragment newtickprocallcompanies
	ijmp tickprocallcompanies

codefragment oldstartnewgame,-6
	mov ebx,6
	call dword [ebp+4]
	mov [human1],al

codefragment newstartnewgame
	icall startnewgame
	jmp short $+0x6a

codefragment newstartnewgame2
	icall startscenario
	jmp short $+0x6a

codefragment oldloadtitlescreen
	mov byte [human1],-2
	mov byte [human2],-1
	cmp byte [numplayers],1

codefragment newloadtitlescreen
	icall loadtitlescreen
	jmp short fragmentstart+0x2e

codefragment oldcreateplayermsgwindow,4
	mov dx,0x20
	mov ebp,3

codefragment newcreateplayermsgwindow
	icall createplayermsgwindow
	setfragmentsize 10

codefragment oldplayermsgtitle
	movzx eax,byte [human2]

codefragment newplayermsgtitle
	movzx eax,byte [esi+window.data]
	setfragmentsize 7

codefragment oldplayermsgface
	movzx ebx,byte [human2]

codefragment newplayermsgface
	movzx ebx,byte [esi+window.data]
	setfragmentsize 7

codefragment oldfindzeppelintarget
	cmp al,[edi+station.owner]
	jz $+2+5
	cmp ah,[edi+station.owner]

codefragment newfindzeppelintarget
	icall findzeppelintarget
	setfragmentsize 8

codefragment oldswitchbacktosingle
	mov byte [numplayers],1
	mov byte [human1],-2

codefragment newswitchbacktosingle
	icall switchbacktosingle
	setfragmentsize 7

codefragment oldloadfilemask2pl,7
	cmp byte [numplayers],2
	jnz $+2+4

codefragment newloadfilemask2pl
	icall loadfilemask2pl

codefragment oldtransmitloadfail
	cmp byte [mpcomputer],1
	jne $+2+0x13

codefragment newtransmitloadfail
	ijmp transmitloadfail

codefragment oldtransmitloadsuccess
	cmp byte [mpcomputer],1
	jne $+2+0x23

codefragment newtransmitloadsuccess
	ijmp transmitloadsuccess

codefragment oldmainmenu2playerbutton,10
	db 0x03, 0x0C, 0xA8, 0x00, 0x45, 0x01, 0x88, 0x00, 0x93, 0x00, 0x44, 0x01

codefragment newmainmenu2playerbutton
	dw ourtext(multiplayer)

codefragment oldmainmenu2playertooltip
	dw 0x300, 0x301, 0x302, 0x303, 0x305

codefragment newmainmenu2playertooltip
	dw ourtext(multiplayer_tooltip)

endcodefragments

#endif
