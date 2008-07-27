#include <frag_mac.inc>
#include <patchproc.inc>
#include <industry.inc>

patchproc newindustries, patchnumindustries

begincodefragments
codefragment al5A_1, 1
	mov al, OLDNUMINDUSTRIES
	mul ah

codefragment al5A_2, 3
	inc al
	cmp al, OLDNUMINDUSTRIES

codefragment cl5A, 5
	dd industryarrayptr
	mov cl, OLDNUMINDUSTRIES

codefragment dl5A, 5
	dd industryarrayptr
	mov dl, OLDNUMINDUSTRIES

codefragment ah5A_1, 5
	dd industryarrayptr
	mov ah, OLDNUMINDUSTRIES

codefragment ah5A_2, 5
	mov cx, 546h
	mov ah, OLDNUMINDUSTRIES

codefragment ah5A_3, 1
	mov ah, OLDNUMINDUSTRIES
	mul ah

codefragment cx5A, 1
	db 0B9h, OLDNUMINDUSTRIES, 0	// matches both "mov ecx, 5Ah" and "mov cx, 5Ah"

#if WINTTDX
codefragment oldptr
	dd oldindustryarray
#endif
endcodefragments

patchnumindustries:
	push dword NEWNUMINDUSTRIES * industry_size
	extcall malloc
#if WINTTDX
	pop ebx
	mov [industryarrayptr], ebx
	stringaddress oldptr
	mov [edi], ebx
#else
	pop dword [industryarrayptr]
#endif
	mov bl, NEWNUMINDUSTRIES	//	Saves one byte per mov.
	stringaddress al5A_1
	mov byte [edi], bl
	stringaddress al5A_2
	mov byte [edi], bl
	multipatchcode cl5A,,6,{mov byte [edi], bl}
	multipatchcode dl5A,,3,{mov byte [edi], bl}
	stringaddress ah5A_1
	mov byte [edi], bl
	stringaddress ah5A_2
	mov byte [edi], bl
	multipatchcode ah5A_3,,7,{mov byte [edi], bl}
#if WINTTDX
	multipatchcode cx5A,,2,{mov byte [edi], bl}
#else
	stringaddress cx5A
	mov byte [edi], bl
#endif
	mov byte [numindustries], bl
	ret
