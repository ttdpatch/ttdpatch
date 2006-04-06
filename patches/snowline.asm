// allow snow line on temperate

#include <std.inc>
#include <flags.inc>

extern patchflags

uvard temp_snowline	// the real snowline var is a byte, but action D supports dwords only
			// that's why we need a temporary var to store it, which will be
			// copied to the real var

uvard snowlinetableptr

global updatesnowline
updatesnowline:
	call $
ovar .oldfn,-4,$,updatesnowline
	mov ebp,[snowlinetableptr]
	test ebp,ebp
	jz .noupdate

	testflags tempsnowline
	jnc .nottempsnow
	cmp byte [climate],0
	je .update

.nottempsnow:
	cmp byte [climate],1
	jne .noupdate

.update:
	shl edx,5
	add edx,ebx
	mov cl,[ebp+edx]
	mov [snowline],cl
	shr edx,5
.noupdate:
	ret

global setsnowlinetable
setsnowlinetable:
	mov [snowlinetableptr],esi
	add esi,12*32
	clc
	ret

svard normaltreespritetableptr
svard snowytreespritetableptr
svard newtempsnowytreespritetable

global restoresnowytrees
restoresnowytrees:
	mov esi,[normaltreespritetableptr]
	test esi,esi
	js .skip
	mov edi,[snowytreespritetableptr]
	mov ecx,12*4
	rep movsd
.skip:
	ret

var numsnowytemptrees, dd 133
svarw snowytemptreespritebase

global applysnowytemptrees
applysnowytemptrees:
	mov esi,[snowytreespritetableptr]
	mov edi,[newtempsnowytreespritetable]

	movzx ebx,word [snowytemptreespritebase]
	sub ebx,1576
	mov ecx,12*4

.nextentry:
	mov eax,[esi]
	mov [esi],edi
	add esi,4

	mov edx,[eax]
	mov ebp,[eax+4]
	add edx,ebx
	add ebp,ebx
	mov [edi],edx
	mov [edi+4],ebp

	mov edx,[eax+8]
	mov ebp,[eax+12]
	add edx,ebx
	add ebp,ebx
	mov [edi+8],edx
	mov [edi+12],ebp

	add edi,16
	loop .nextentry

	ret
