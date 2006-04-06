#include <defs.inc>
#include <frag_mac.inc>
#include <bitvars.inc>
#include <station.inc>

extern morebuildoptionsflags


global patchmorebuildoptions
patchmorebuildoptions:
	mov bl, [morebuildoptionsflags]	// we let the preprocessor do the work... *eg*
	patchcode oldcrosstunnel,newcrosstunnel,1,1,,{test bl,MOREBUILDOPTIONS_CTUNNEL},nz
	patchcode oldbuildonlyone,newbuildonlyone,1,1,,{test bl,MOREBUILDOPTIONS_MOREINDUSTRIES},nz
	patchcode oldbuildonlynearmapedge, newbuildonlynearmapedge,1,1,,{test bl,MOREBUILDOPTIONS_OILREFINERY},nz
	patchcode oldremoveindustrydeny,newremoveindustrydeny,1,1,,{test bl,MOREBUILDOPTIONS_REMOVEINDUSTRY},nz
	patchcode oldremoveindustrydeny2,newremoveindustrydeny2,1,1,,{test bl,MOREBUILDOPTIONS_REMOVEINDUSTRY},nz
	patchcode oldplacebuoy,newplacebuoy,1,1,,{test bl,MOREBUILDOPTIONS_ENHANCEDBUOYS},nz
	patchcode oldremovetracksignals,newremovetracksignals,1,1,,{test bl,MOREBUILDOPTIONS_BULLDOZESIGNALS},nz
	ret



begincodefragments

codefragment oldcrosstunnel
	or al,al
	pop si

codefragment newcrosstunnel
	and al,0

codefragment oldbuildonlyone, -13
	db 0xFE,0xC9
	db 0x75,0xE9
	db 0xF8
	db 0xC3

codefragment newbuildonlyone
	call runindex(industryallowedtobuild)
	nop
	nop
	db 0x72	// turn jz into jc

codefragment oldbuildonlynearmapedge, 14
	cmp ah, 0xEE
	ja $+2+0x0B

codefragment newbuildonlynearmapedge
	clc
	
codefragment oldremoveindustrydeny, 21
	ror si, 4
	movzx esi,byte [landscape2+esi]
	imul si, 36h

codefragment newremoveindustrydeny
	call runindex(removeindustry)
	nop
	// db 0xEB	// je -> jmp
	db 0x72	// turn je into jc

codefragment oldremoveindustrydeny2, 18
	db 0x74, 0xD7 
	test bl, 1
	db 0x74, 0x0B

codefragment newremoveindustrydeny2
	mov ebx, edi

//codefragment findremoveindustryinesi, 11
//	db 0x74, 0xD7 
//	test bl, 1
//	db 0x74, 0x0B

codefragment oldplacebuoy
	mov byte [esi+station.owner],0x10
	xor al,al

codefragment newplacebuoy
	icall placebuoy

codefragment oldremovetracksignals
	movzx ebx,bh
	bsf bx,bx

codefragment newremovetracksignals
	icall removetracksignals
	jmp newremovetracksignals_start+21


endcodefragments
