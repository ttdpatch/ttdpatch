#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc autoslope, patchautoslope

extern tempraiseloweraffectedtilearray
extern tempraiseloweraffectedtilearraycount,tempraiseloweraffectedtilearraycount2
extern bTempRaiseLowerDirection_ptr,bTempRaiseLowerCorner_ptr
extern reloc,canraiselowertrack.done

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
	ret



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


endcodefragments
