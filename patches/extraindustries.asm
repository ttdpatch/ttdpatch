#include <ttdvar.inc>
#include <industry.inc>
#include <flags.inc>

extern patchflags, randomfn

// The actual size of the industry array.
varb maxindustries, OLDNUMINDUSTRIES

exported clearindustrydata
	extcall clearindustryincargos
	extcall clearindustry2array
	// jmp clearextraindustries	// fall through

exported clearextraindustries
	testmultiflags moreindustries
	jz .ret
	mov edi, [industryarrayptr]
	mov ecx, MAXNUMINDUSTRIES*industry_size
	xor eax, eax
	rep stosb
.ret:
	ret

exported copybackindustrydata
	push esi
	mov esi, [industryarrayptr]
	mov edi, oldindustryarray
	mov ecx, OLDNUMINDUSTRIES*industry_size
	rep movsb
	pop esi
	ret

exported initextraindustries
	mov esi, oldindustryarray
	mov edi, [industryarrayptr]
	mov ecx, OLDNUMINDUSTRIES*industry_size
	rep movsb
	ret

// Prohibit random new industries if too many already exist
// in:	esi->empty industry slot
// out: eax: random bits	( >=1C71h to prohibit)
// safe: all except esi
exported makerandomindu
	mov edi, [industryarrayptr]
	xor eax, eax
	xor ecx, ecx
	mov cl, MAXNUMINDUSTRIES
.loop:
	cmp word [edi], 0
	je .empty
	inc eax
.empty:
	add edi, industry_size
	loop .loop

	cmp al, [numindustries]
	jae .noslot
	jmp [randomfn]		// Overwritten
.noslot:
	or eax, byte -1
	ret

