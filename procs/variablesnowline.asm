#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

extern updatesnowline,updatesnowline.oldfn
extern normaltreespritetableptr,snowytreespritetableptr,newtempsnowytreespritetable
extern newgraphicssetsenabled,malloccrit

patchproc canmodifygraphics, patchvariablesnowline

begincodefragments

codefragment oldstartnewday,10
	call [ebp+4]
	mov ax,[currentdate]

codefragment findtreespritetables
	cmp bp, 0xA0
	jz $+2+9
endcodefragments

patchvariablesnowline:
	stringaddress oldstartnewday,1,1
	chainfunction updatesnowline, .oldfn
	stringaddress findtreespritetables,1,1
	mov eax,[edi+10]
	mov [normaltreespritetableptr],eax
	mov eax,[edi+19]
	mov [snowytreespritetableptr],eax
	push 12*4*4*4
	call malloccrit
	pop dword [newtempsnowytreespritetable]

	or byte [newgraphicssetsenabled+1], 1<<(12-8)
	ret
