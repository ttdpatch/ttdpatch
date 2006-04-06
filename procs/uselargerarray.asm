#include <defs.inc>
#include <frag_mac.inc>

global oldveharraysize,oldvehicles
oldveharraysize equ 0x1a900		// Original size of train data structure
oldvehicles equ oldveharraysize / vehiclesize
%assign oldspecialvehicles 0xa0
%assign oldnormalvehicles oldvehicles - oldspecialvehicles
%assign oldnormalvehsize oldnormalvehicles*vehiclesize


extern initializeveharraysizeptr,newnormalvehicles,newnormalvehsize
extern newspecialvehicles,newvehicles,datasize
extern vehicledatafactor

global newveharraysize
newveharraysize equ 40*oldveharraysize

global patchuselargerarray
patchuselargerarray:
#if WINTTDX
	patchcode oldfixcommandaddr,newfixcommandaddr,1,1
	movzx eax,word [newvehicles]
	mov dword [edi+lastediadj-4],eax
#endif

	mov edi,[initializeveharraysizeptr]
	movzx eax,byte [vehicledatafactor]
	mov ebx,eax
	imul eax,dword [edi]
	imul bx,word [edi+0x2b-6*WINTTDX]
	mov [edi],eax
	mov [edi+0x2b-6*WINTTDX],bx

	// patch the default filenames for loading and saving
	stringaddress oldloadfilemask,1,1
	mov byte [edi+5],'?'	// load TR???.SV1 not TRT??.SV1

	// fix the undead vehicles, age veh's after #888
	stringaddress doagevehicles,1,1
	mov al,byte [vehicledatafactor]
	mul byte [edi]	// result is in ax
	mov word [edi],ax

	// patch the total number of vehicles
	changeloadedvalue createnewvehiclea,1,1,w,newnormalvehicles
	changeloadedvalue createnewvehicleb,1,1,w,newnormalvehicles
	changeloadedvalue createnewvehiclec,1,1,d,newnormalvehsize
	mov ax,word [newspecialvehicles]
	mov [edi+6],ax
	changeloadedvalue createnewvehicled,1,1,d,newnormalvehsize
	changeloadedvalue createnewvehiclee,1,1,w,newvehicles
	multichangeloadedvalue createnewvehiclef,7,w,newvehicles
	ret


global setvehiclearraysize
setvehiclearraysize:
	movzx eax,byte [vehicledatafactor]
	imul ecx,eax,oldspecialvehicles
	mov [newspecialvehicles],ecx

	imul ecx,eax,oldvehicles
	mov [newvehicles],ecx
	sub ecx,[newspecialvehicles]
	mov [newnormalvehicles],ecx
	shl ecx,7
	mov [newnormalvehsize],ecx

	imul ecx,eax,oldveharraysize
	mov [datasize],ecx
	add ecx,[veharrayptr]
	mov [veharrayendptr],ecx
	ret
; endp setvehiclearraysize

global cleardata
cleardata:
	// this part is what has been overwritten

	// do the original initialization
	mov esi,[veharrayptr]
	mov ecx,[veharrayendptr]
	sub ecx,esi
.init1:
	mov byte [esi],0
	inc esi
	loop .init1
	mov esi,[veharrayptr]
	xor ecx,ecx
.init2:
	mov [esi+4],cx
	sub esi,byte -vehiclesize	//add esi,vehiclesize
	inc ecx
	cmp esi,[veharrayendptr]
	jb .init2

	ret
; endp cleardata


begincodefragments


#if WINTTDX
glob_frag oldfixcommandaddr
codefragment oldfixcommandaddr,5
	mov ecx,oldvehicles
	db 0xbe		// mov esi,oldveharray

codefragment newfixcommandaddr
	mov esi,[veharrayptr]
	jmp runindex(bcfixcommandaddr)	// 1.7 compatibility fix
#endif

glob_frag oldloadfilemask
codefragment oldloadfilemask
	mov dword [esi+1],"TRT?"

codefragment doagevehicles,2
	mov cx,12
	push cx

codefragment createnewvehiclea,2
	mov cx,oldnormalvehicles
	db 0x66		// would be xor ax,ax

codefragment createnewvehicleb,2
	mov cx,oldnormalvehicles
	db 0xf6		// test bl,2

codefragment createnewvehiclec,2	// and ,8
	add esi,oldnormalvehsize
	mov cx,oldspecialvehicles

codefragment createnewvehicled,2
	add esi,oldnormalvehsize
	xor bx,bx

codefragment createnewvehiclee,2
	cmp ax,oldvehicles

codefragment createnewvehiclef,2
	mov dx,oldvehicles


endcodefragments
