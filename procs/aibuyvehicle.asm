#include <defs.inc>
#include <frag_mac.inc>


extern canaibuyloco.gettraintype
extern patchflags


global patchaibuyvehicle
patchaibuyvehicle:
	mov ebx,patchflags
	testflagbase ebx

	stringaddress oldcanaibuyvehicle,1,4

	testmultiflags unifiedmaglev,newtrains,saveoptdata
	jz .nonewtrains

	storefragment newcanaibuyloco
	mov eax,[edi+lastediadj-19]
	mov [canaibuyloco.gettraintype],eax
	mov word [edi+lastediadj-24],0xCB8B				// mov ch,bh -> mov ecx,ebx

.nonewtrains:
	stringaddress oldcanaibuyvehicle,1,0

	testmultiflags newrvs
	jz .nonewrvs

	storefragment newcanaibuyrv
	add edi,lastediadj-52
	storefragment newaigetrvlist
	mov word [edi+lastediadj+12],0x06eb

.nonewrvs:
	stringaddress oldcanaibuyvehicle,1,0

	testmultiflags newplanes
	jz .nonewplanes

	storefragment newcanaibuyplane

.nonewplanes:
	stringaddress oldcanaibuyvehicle,1,0

	testmultiflags newships
	jz .nonewships

	storefragment newcanaibuyship
	add edi,lastediadj-60
	storefragment newaigetshiplist
	mov word [edi+lastediadj+20],0x06eb

.nonewships:
	testflagbase none
	ret



begincodefragments

codefragment oldcanaibuyvehicle
	movzx bp,byte [curplayer]

codefragment newcanaibuyloco
	icall canaibuyloco
	jnc short $+2+4			// skip over the BT [EDX],BP above

codefragment newcanaibuyrv
	icall canaibuyrv
	jnc short $+2+4

codefragment newaigetrvlist
	icall aigetrvlist

codefragment newcanaibuyplane
	icall canaibuyplane
	jnc short $+2+4

codefragment newcanaibuyship
	icall canaibuyship
	jnc short $+2+4

codefragment newaigetshiplist
	icall aigetshiplist


endcodefragments
