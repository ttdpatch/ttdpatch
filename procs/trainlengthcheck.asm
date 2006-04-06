#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc mammothtrains,newtrains,manualconvert, patchtrainlengthcheck

patchtrainlengthcheck:
	patchcode oldlimittrainlength,newlimittrainlength,1,1
	ret



begincodefragments

codefragment oldlimittrainlength,-9
	cmp al,9
	db 0x76,0x10	// jbe somewhere
	db 0x8b,0x3d	// mov edi,[somewhere]

codefragment newlimittrainlength
	call runindex(limittrainlength)
	setfragmentsize 11


endcodefragments
