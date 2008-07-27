#include <ttdvar.inc>
#include <industry.inc>

// The actual size of the industry array.
varb numindustries, OLDNUMINDUSTRIES

exported clearextraindustries
	mov edi, [industryarrayptr]
	mov ecx, NEWNUMINDUSTRIES*industry_size
	xor eax, eax
	rep stosb
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

exported clearindustrydata
	extcall clearindustryincargos
	extcall clearindustry2array
	jmp clearextraindustries
