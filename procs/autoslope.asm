#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc autoslope, patchautoslope

extern tempraiseloweraffectedtilearray
extern tempraiseloweraffectedtilearraycount,tempraiseloweraffectedtilearraycount2
extern bTempRaiseLowerDirection_ptr,bTempRaiseLowerCorner_ptr
extern reloc,canraiselowertrack.done
extern correctlandscapeonraiselower,correctlandscapeonraiselower.oldfn
extern correctlandscapeonraiselower2,correctlandscapeonraiselower2.oldfn

begincodefragments

codefragment findtempraiselowerdirection, -10
	sub esp, 0x6C0

glob_frag oldcanraiselowertrack
codefragment oldcanraiselowertrack,-18,-20
	cmp ah,2
	jb short $+2+0xe
	jz short $+2+0x12

reusecodefragment findtempraiselowercorner,oldcanraiselowertrack,-8

codefragment oldtunneltryremovewhenterraform
	jz $+2+0x36
	cmp bp, di

codefragment newtunneltryremovewhenterraform
	jz $+2+0x0E
	cmp bp, di

codefragment oldtunneltryremovewhenterraform2
	jz $+2+0x3A
	cmp bp, di

codefragment newtunneltryremovewhenterraform2
	jz $+2+0x12
	cmp bp, di

codefragment oldremoveeverythingontileraiseland,-73-(WINTTDX*7)	//584194 (5841E4), _CS:0013E750 (_CS:0013E799)
mov	 ax, [ebp+0]
push	 cx
push	 ebp
rol	 ax, 4
mov	 cx, ax
rol	 cx, 8
and	 ax, 0FF0h
and	 cx, 0FF0h
//call	 sub_401E15
db 0xE8

codefragment newincvalfixfudgefrag
	jb $+2+0xB-4
	ret



endcodefragments

patchautoslope:
	stringaddress findtempraiselowerdirection

	mov eax, dword [edi+0x1E]
	mov dword [tempraiseloweraffectedtilearray], eax

	mov eax, dword [edi+0x32]
	mov dword [tempraiseloweraffectedtilearraycount], eax
	mov dword [tempraiseloweraffectedtilearraycount2], eax

	mov eax, dword [edi]
	param_call reloc, eax, bTempRaiseLowerDirection_ptr
	
	stringaddress findtempraiselowercorner
	mov eax, dword [edi]
	param_call reloc, eax, bTempRaiseLowerCorner_ptr

	mov byte [canraiselowertrack.done], 0x90

	patchcode oldtunneltryremovewhenterraform,newtunneltryremovewhenterraform,1,1
	patchcode oldtunneltryremovewhenterraform2,newtunneltryremovewhenterraform2,1,1
	stringaddress oldremoveeverythingontileraiseland
	chainfunction correctlandscapeonraiselower,.oldfn
	add edi,101+(WINTTDX*7)
	chainfunction correctlandscapeonraiselower2,.oldfn
	add edi, 0x58425A-0x584200
	storefragment newincvalfixfudgefrag
	ret
