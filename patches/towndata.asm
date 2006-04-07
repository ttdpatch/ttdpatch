//
// More town data for various patches
//

#include <std.inc>
#include <proc.inc>
#include <flags.inc>
#include <textdef.inc>
#include <house.inc>
#include <town.inc>
#include <ptrvar.inc>

extern RefreshTownNameSign,RefreshTownNameSignedi,cargotypenamesptr
extern drawtextfn,getdesertmap,gethouseidebpebx,housepartflags
extern housepopulations,istownbigger,patchflags,randomfn
extern tgractstationexist,tgractstations,tgractstationsweight
extern tgrfizzydrinksinoptim,tgrfizzydrinksinweight,tgrfoodinmin
extern tgrfoodinoptim,tgrfoodinweight,tgrgoodsinoptim,tgrgoodsinweight
extern tgrmailinoptim,tgrmailinweight,tgrmailoutweight,tgrpassinmax
extern tgrpassinweight,tgrpassoutweight,tgrsweetsinoptim,tgrsweetsinweight
extern tgrtownsizebase,tgrtownsizefactor,tgrwaterinmin,tgrwaterinoptim
extern tgrwaterinweight,townarray2ofst,townmaxgrowthrate,townmingrowthrate
extern townminpopulationdesert
extern townminpopulationsnow
extern cargotowngrowthtype,cargotowngrowthmulti



// A new town is being created:
// - initialize town array 2, if available
// - reset population and building counters (because town boundaries have changed)
// in:	ESI -> town
// safe:EAX,EBX,ECX,EDX,EDI,EBP
global initializetownex
initializetownex:
	and word [esi+town.waterlastmonth],0	// overwritten

	mov edi,[townarray2ofst]
	test edi,edi
	jz .notownarray2

	// zero all fields in the town array 2 entry
	add edi,esi
	xor ecx,ecx
	mov cl,town2_size

.clearloop:
	mov byte [edi],0
	inc edi
	loop .clearloop

	testflags newhouses
	jnc .noboundingrect

	mov edi,[townarray2ofst]
	add edi,esi

	mov dword [edi+town2.boundrectminx],0x0000FFFF		// min=(FF,FF), max=(0,0), so the first house will
								// always set all coordinates
.noboundingrect:
.notownarray2:

	call recalctownpopulations
	ret


// Keep an extended (32-bit) population counter

// A fully built house has been created in town -- increase population
// in:	ESI -> town
//	EDI = XY
//	EBP = house type
// out:	AX = new town population, limited to 16 bits (see codefragment newcompletehousecreated)
// safe:(E)AX,EBX,(E)CX,(E)DX
global completehousecreated
completehousecreated:
	mov eax,[housepopulations]
	movzx ebx,byte [eax+ebp]

	call RefreshTownNameSign
	mov eax,[townarray2ofst]
	add ebx,[esi+eax+town2.population]
	mov [esi+eax+town2.population],ebx
	call RefreshTownNameSign

	// limit the range on output
	mov eax,64000			// safeguard in case the game is played without the town2 array later
	cmp ebx,eax
	ja .done
	xchg eax,ebx

.done:
	ret

// Construction of a town building complete -- increase population
// in:	EDI -> town
//	EBX = house XY
//	EBP = house type = L2[EBX]
// out:	AX = new town population, limited to 16 bits (see codefragment newhouseconstrcomplete)
// safe:EAX,(E)DX,ESI
global houseconstrcomplete
houseconstrcomplete:
	push ebx
	mov esi,edi
	call completehousecreated
	pop ebx
	ret

// Town building removed -- decrease population
// in:	EDI -> town
//	EBP = house type
//	AX,CX = X,Y location
// out:	BX = new town population, limited to 16 bits (see codefragment newremovehousepopulation)
// safe:EDX,ESI?
global removehousepopulation
removehousepopulation:
	mov ebx,[housepopulations]
	movzx ebx,byte [ebx+ebp]

	call RefreshTownNameSignedi
	mov edx,[townarray2ofst]
	sub [edi+edx+town2.population],ebx
	mov ebx,[edi+edx+town2.population]
	call RefreshTownNameSignedi

	// limit the range on output
	mov edx,64000
	cmp ebx,edx
	jbe .done
	mov ebx,edx

.done:
	ret


// Auxiliary: recalculate populations and building counters of all towns
global recalctownpopulations
recalctownpopulations:
	pusha

	// clear the counters in all towns
	mov esi,townarray
	mov ecx,[townarray2ofst]
	xor ebx,ebx
	mov bl,numtowns

.resetloop:
	and word [esi+town.population],0
	and word [esi+town.buildingcount],0
	call RefreshTownNameSign
	jecxz .resetnext
	and dword [esi+ecx+town2.population],0

.resetnext:
	add esi,byte town_size
	dec ebx
	jnz .resetloop

	// now find all town buildings and add them to their towns
	xor esi,esi

	// process all tiles; ESI holds the XY of the currently processed tile
.findhousesloop:
	mov al,[landscape4(si,1)]
	and al,0xf0
	cmp al,0x30
	jnz .nexttile

	mov ebp,[ophandler+(3*8)]
	xor ebx,ebx
	mov bl,1
	xchg eax,esi
	call dword [ebp+4]		// returns the nearest town ptr in EDI and distance in BP; scrambles BX,ESI
	xchg eax,esi

	testflags newhouses
	jnc .nonewhouses

	gethouseid ebp,esi
	jmp short .gotid

.nonewhouses:
	movzx ebp,byte [landscape2+esi]
.gotid:
	mov ebx,[housepartflags]
	test byte [ebx+ebp],8	// don't count large buildings multiply
	jz .addpopulation
	inc word [edi+town.buildingcount]

.addpopulation:
	mov al,[landscape3+esi*2]
	and al,0xc0
	cmp al,0xc0
	jne .nexttile			// only fully constructed houses have population

	mov ebx,[housepopulations]
	movzx ebx,byte [ebx+ebp]
	movzx eax,word [edi+town.population]
	add eax,ebx
	jecxz .gotpopulation
	add [edi+ecx+town2.population],ebx
	mov eax,[edi+ecx+town2.population]

.gotpopulation:
	// limit range to within 16 bits
	mov bx,64000			// note: previous value of EBX was in 0..255
	cmp eax,ebx
	jbe .wordpopulation
	xchg eax,ebx

.wordpopulation:
	mov [edi+town.population],ax
	push esi
	mov esi, edi
	call RefreshTownNameSign
	pop esi

.nexttile:
	inc si
	jnz .findhousesloop

	popa
	ret


// Enhanced, customizable town growth rate calculation
// proceeding from the monthly ratings update; town flags bit 0 (growth) cleared
// in:	ESI -> town
//	CH = number of active stations in the transport zone
// out:	CF set = town can expand in the next month
//	CL = inverse expansion rate (to be put in town.expansionrate) if CF=1
// safe:everything except ESI
global newcalctowngrowthrate
proc newcalctowngrowthrate
	local ratediff,sumweights,notenoughfoodwater
	_enter

	mov edi,[townarray2ofst]
	add edi,esi

	movzx ebx,word [townmaxgrowthrate]
	movzx eax,byte [townmingrowthrate]
	sub ebx,eax
	jae .ratediffgood
	xor ebx,ebx

.ratediffgood:
	mov [%$ratediff],ebx
	and dword [%$sumweights],0
	and dword [%$notenoughfoodwater],0
	xor ebx,ebx				// accumulate component*weight values in EBX

	// First add up all the weighted rate terms

	// Number of active stations:

	xor eax,eax
	test ch,ch
	jz .actstationsnottoohigh
	mov al,[tgractstations]
	mul ch
	movsx edx,byte [tgractstationexist]
	add eax,edx
	jns .actstationsnotnegative
	xor eax,eax
.actstationsnotnegative:
	imul eax,10
	cmp eax,[%$ratediff]
	jbe .actstationsnottoohigh
	mov eax,[%$ratediff]
.actstationsnottoohigh:
	movzx edx,byte [tgractstationsweight]
	add [%$sumweights],edx
	mul edx				// max. result imaginable = 65535*255, so EDX=0

	// value/weight is in the range 0..[%$ratediff]
	// normalize it to 0..255 before adding to the sum
	test eax,eax
	jz .actstationszero		// protect from division by zero (if %$ratediff==0 then eax==0 too)
	imul eax,255
	div dword [%$ratediff]
	add ebx,eax
.actstationszero:

	// Fraction of passengers transported this month:

	movzx edx,word [esi+town.actpassacc]
	movzx ecx,word [esi+town.maxpassacc]
	mov eax,tgrpassoutweight
	call .getcargotransfraction

	// Fraction of mail transported this month:

	movzx edx,word [esi+town.actmailacc]
	movzx ecx,word [esi+town.maxmailacc]
	mov eax,tgrmailoutweight
	call .getcargotransfraction

	// Number of passengers received this month:

	movzx edx,word [edi+town2.passthismonth]
	movzx ecx,word [tgrpassinmax]
	mov eax,tgrpassinweight
	call .getcargotransfraction

	// Mail received this month:

	movzx ecx,word [edi+town2.mailthismonth]
	mov edx,tgrmailinoptim
	mov eax,tgrmailinweight
	call .getcargoneedfraction

	// Goods received this month:

	cmp byte [climate],3
	je near .toylandgoods

	movzx ecx,word [edi+town2.goodsthismonth]
	mov edx,tgrgoodsinoptim
	mov eax,tgrgoodsinweight
	call .getcargoneedfraction

	// Food received this month:

	cmp byte [climate],0
	je near .gotallcomponents

	call .isinsnow
	jnc .needsminimumfood
	call .isindesert
	jz .checkminimumfood

.needsminimumfood:
	// town has a minimum food requirement, get the amount in EAX
	movzx ecx,byte [tgrfoodinmin]
	call .getcargorequiredfraction

.checkminimumfood:
	movzx ecx,word [esi+town.foodthismonth]
	sub ecx,eax
	jnc .haveminimumfood
	or byte [%$notenoughfoodwater],1
	xor ecx,ecx

.haveminimumfood:
	mov edx,tgrfoodinoptim
	mov eax,tgrfoodinweight
	call .getcargoneedfraction

	// Water received this month:

	cmp byte [climate],2
	jne .gotallcomponents

	call .isindesert
	jz .checkminimumwater

	// town has a minimum water requirement, get the amount in EAX
	movzx ecx,byte [tgrwaterinmin]
	call .getcargorequiredfraction

.checkminimumwater:
	movzx ecx,word [esi+town.waterthismonth]
	sub ecx,eax
	jnc .haveminimumwater
	or byte [%$notenoughfoodwater],2
	xor ecx,ecx

.haveminimumwater:
	mov edx,tgrwaterinoptim
	mov eax,tgrwaterinweight
	call .getcargoneedfraction

	jmp short .gotallcomponents

.toylandgoods:

	// Sweets received this month:

	movzx ecx,word [edi+town2.goodsthismonth]
	mov edx,tgrsweetsinoptim
	mov eax,tgrsweetsinweight
	call .getcargoneedfraction

	// Fizzy drinks received this month:

	movzx ecx,word [esi+town.foodthismonth]
	mov edx,tgrfizzydrinksinoptim
	mov eax,tgrfizzydrinksinweight
	call .getcargoneedfraction

.gotallcomponents:

	// Now EBX = sum of component*weight values, where 0<=component<=255
	// we shift it 32 bits to the left and then divide by the sum of weights * 255
	// to get a 32-bit normalized result
	mov edx,ebx
	imul ebx,[%$sumweights],255
	or eax,byte -1		// overflow-case result
	cmp edx,ebx
	jae .sumoverflow	// (EDX>EBX should never happen, but...  EDX==EBX may happen, though)
	inc eax			// EAX=0
	div ebx
.sumoverflow:

	// now EAX = base growth rate as a normalized fraction of the maximum delta
	// calculate the influence of the number of buildings
	push eax
	movzx ebx,byte [tgrtownsizefactor]
	// first the town-size-dependent part
	movzx eax,word [esi+town.buildingcount]
	shl eax,8
	xor edx,edx
	movzx ecx,byte [tgrtownsizebase]
	jecxz .townsizebaseis0
	div ecx
.townsizebaseis0:
	// now EAX = town size/base as a 16,8 bit fixed point value
	mul ebx			// the factor in EBX may be viewed as (fraction of 255)*255
	mul dword [esp]
	mov ecx,edx
	// now ECX = town-size-dependent part * 255 as a 24,8 bit fixed point value
	// now the town-size-independent part
	not bl			// EBX = 255-EBX
	shl ebx,8		// convert to 16,8 fixed point
	pop eax
	mul ebx
	// now EDX = town-size-independent part * 255 as a 16,8 bit fixed point value
	// now add both parts
	lea eax,[edx+ecx]	// can't overflow... check it yourself if you don't believe me :-) -- Marcin

	// time to convert it to the real value and put the upper limit
	mul dword [%$ratediff]
	jc .ratedeltatoobig
	mov ecx,(255*256/2)-1	// -1 to account for roundoff errors
	add eax,ecx		// we're rounding to nearest this time
	jc .ratedeltatoobig
	shr eax,1
	div ecx			// note, we know we got CF=0 after the MUL above, so EDX must be 0

	cmp eax,[%$ratediff]
	jbe .ratedeltagood	// not more than the maximum

.ratedeltatoobig:
	mov eax,[%$ratediff]

.ratedeltagood:

	movzx ecx,byte [townmingrowthrate]
	add ecx,eax

	// now ECX = real growth rate
	// this is yet to be affected by building funds etc.

	// check if a town fund is active (just as TTD does)
	cmp byte [esi+town.buildingfund],0
	jz .nobuildingfund
	dec byte [esi+town.buildingfund]
	add ecx,600
.nobuildingfund:

	// double the rate for towns supposed to be bigger
	mov eax,esi
	sub eax,townarray
	mov bl,town_size
	div bl
	call istownbigger
	jnz .notbigger
	add ecx,ecx
.notbigger:

	// check if the town lacks food or water
	// if so, the town won't grow unless its population is less than a lower limit
	call .isinsnow
	jc .snow_ok
	test byte [%$notenoughfoodwater],1
	jz .snow_ok
	movzx eax,byte [townminpopulationsnow]
	cmp [edi+town2.population],eax
	jnb .done
.snow_ok:

	call .isindesert
	jz .water_ok
	test byte [%$notenoughfoodwater],3
	jz .water_ok
	movzx eax,byte [townminpopulationdesert]
	cmp [edi+town2.population],eax
	jnb .done
.water_ok:

	// Whew! Now ECX = final growth rate, approx. in houses per 100 years.
	// We convert it to inverse growth rate (number of days between house building actions)
	// and set the town fields like TTD does.

	test ecx,ecx
	jz .done		// CF=0

	mov eax,38400
	xor edx,edx
	div ecx			// 0<=EAX<=38400

	cmp ax,255
	jbe .gotinvrate

	// number of days is too big to fit in a byte
	// reduce it and randomly disable growth to have the same effect on the average
	mov ecx,0xAAAB			// (we sort of simulate TTD behaviour here)
	mul cx				// now DX = 2/3 of the actual inverse rate
					// this way town growth will be switched off less frequently than if we used 1/2
.ratereductionloop:
	cmp dx,255
	jbe .gotredrate
	shr dx,1
	shr ecx,1
	jmp .ratereductionloop

.gotredrate:
	call [randomfn]
	cmp ax,cx
	jnb .done

	xchg eax,edx

.gotinvrate:
	xchg ecx,eax			// result in CL
	stc

.done:
	_ret

	// local aux. subroutines follow
	// common registers (must not change): ESI -> town, EDI -> town2, EBP -> stack frame

	// get fraction of some cargo transported in or out of the town this month;
	// add to the growth rate (in EBX) with weighting
	// in:	ECX = maximum cargo transported this month
	//	EDX = actual cargo transported this month
	//	EAX -> byte: weight of this transport term in the rate calculation
	// uses:EAX,EDX
.getcargotransfraction:
	push eax
	xor eax,eax
	jecxz .gotfractcargotransnorm

.calcfractcargotrans:
	dec eax				// EAX=-1 (overflow-case result)
	cmp edx,ecx
	jae short .gotfractcargotrans
	inc eax				// EAX=0 again
	div ecx

.gotfractcargotrans:
	shr eax,24

.gotfractcargotransnorm:
	pop edx
	movzx edx,byte [edx]
	add [%$sumweights],edx
	mul dl
	add ebx,eax
	ret


	// get fraction of some cargo wanted this month
	// add to the growth rate (in EBX) with weighting
	// in:	ECX = amount of this cargo type received this month (0..65535)
	//	EDX -> byte: population per 2 units resulting in optimal growth (inverse requirement)
	//	EAX -> byte: weight of this transport term in the rate calculation
	// uses:EAX,ECX,EDX
.getcargoneedfraction:
	push eax
	xor eax,eax
	jecxz .gotfractcargotransnorm
	mov al,byte [edx]
	mul ecx				// ECX<0x10000, so the product always fits in 32 bits, hence EDX=0 now
	xchg eax,edx			// now EAX=0
	mov ecx,[edi+town2.population]
	add ecx,ecx
	jmp .calcfractcargotrans


	// get amount of some cargo required this month
	// in:	ECX = population per 2 units needed as a minimum (inverse of the cargo requirement)
	// out:	EAX = amount of this cargo type needed
	// uses:EDX
.getcargorequiredfraction:
	mov eax,[edi+town2.population]
	add eax,eax
	jecxz .gotrequiredcargo		// division-by-zero protection
	xor edx,edx
	add eax,ecx			// have the result rounded UP
	dec eax
	div ecx
.gotrequiredcargo:
	ret


	// check if the town is above the snow line in sub-arctic climate
	// out:	CF clear if in snow, set otherwise
.isinsnow:
	cmp byte [climate],1
	stc
	jne .checkedinsnow

	movzx eax,word [esi+town.XY]
	mov al,[landscape4(ax,1)]
	and al,0xf
	shl al,3
	cmp al,[snowline]

.checkedinsnow:
	ret

	// similar for desert areas in sub-tropical climate
	// out:	EAX = 0 if not in desert, nonzero otherwise; ZF set according to EAX
.isindesert:
	cmp byte [climate],2
	clc
	jne .checkedindesert

	push ebx
	movzx ebx,word [esi+town.XY]
	call [getdesertmap]
	pop ebx
	dec eax
	sub al,1			// CF=1 if and only if [getdesertmap] returned AL=1

.checkedindesert:
	sbb eax,eax			// EAX=-1 if CF was set, otherwise 0
	ret

endproc ; newcalctowngrowthrate


// Record extended town statistics at the end of a month;
// process other extended data if necessary
// in:	ESI -> town
//	AX = bags of mail transported last month
// out:	EBX=ESI
// safe:everything except ESI
global recordtownextstats
recordtownextstats:
	mov [esi+town.actmailtrans],ax	// overwritten

	mov edi,[townarray2ofst]
	add edi,esi

	xor eax,eax
	xchg eax,[edi+town2.passthismonth]	// copy .passthismonth and .mailthismonth at once
	mov [edi+town2.passlastmonth],eax
	xor eax,eax
	xchg eax,[edi+town2.goodsthismonth]	// copy .goodsthismonth and the next field (curr. reserved) at once
	mov [edi+town2.goodslastmonth],eax

	xor ecx,ecx
	mov cl,8

.companiesloop:
	cmp byte [edi+town2.companiesunwanted+ecx-1],0
	jz .nextcompany
	dec byte [edi+town2.companiesunwanted+ecx-1]

.nextcompany:
	loop .companiesloop

	mov ebx,esi
	ret


// Add cargo accepted at a station to town statistics, with overflow protection
// in:	ESI -> source station
//	EDI -> current station
//	EBX -> current station's town
//	CH = cargo type
//	AX = amount
//	DL = transit time
// safe:EAX,EBX
global townacceptedcargo
townacceptedcargo:
	push eax
	push ecx
	push edx

	testflags newcargos
	jnc .nonewcargos

// pretend that this cargo is the one given in its "town growth substitute", and adjust the amount if needed
	movzx eax,ax
	movzx edx,ch
	mov ch, [cargotowngrowthtype+edx]
	movzx edx, word [cargotowngrowthmulti+edx*2]
	imul eax,edx
	shr eax,8

.nonewcargos:
	cmp ch,11
	jne .fooddone
	add [ebx+town.foodthismonth],ax
	jnc .fooddone
	or word [ebx+town.foodthismonth],byte -1
.fooddone:

	cmp ch,9		// water?
	jne .waterdone
	add [ebx+town.waterthismonth],ax
	jnc .waterdone
	or word [ebx+town.waterthismonth],byte -1
.waterdone:

	add ebx,[townarray2ofst]
	cmp ch,0		// passengers?
	jne .passdone
	add [ebx+town2.passthismonth],ax
	jnc .passdone
	or word [ebx+town2.passthismonth],byte -1
.passdone:

	cmp ch,2		// mail?
	jne .maildone
	add [ebx+town2.mailthismonth],ax
	jnc .maildone
	or word [ebx+town2.mailthismonth],byte -1
.maildone:

	cmp ch,5		// goods?
	jne .goodsdone
	add [ebx+town2.goodsthismonth],ax
	jnc .goodsdone
	or word [ebx+town2.goodsthismonth],byte -1
.goodsdone:

	pop edx
	pop ecx
	pop eax
	ret


// Record generated and transported passengers or mail, with overflow protection
// (limit to signed amounts to avoid problems with the way TTD handles these)
// in:	EBX = XY of the house that produces the cargo
//	EDI -> nearest town
//	CX = amount of passengers or mail generated
//	AX = amount of passengers or mail transported
// safe:EAX,ECX,EDX,ESI,EBP
global recordtransppassmail
recordtransppassmail:
	movzx edx,dl
	add [edi+town.maxpassacc+edx],cx
	jno .added1
	mov word [edi+town.maxpassacc+edx],0x7fff

.added1:
	add [edi+town.actpassacc+edx],ax
	jno .added2
	mov word [edi+town.actpassacc+edx],0x7fff

.added2:
	ret


// Make town window display the 32-bit population counter
// in:	EBX -> town
// safe:EAX,ESI,EBP
global display32bitpopulation
display32bitpopulation:
	mov eax,[townarray2ofst]
	mov eax,[eax+ebx+town2.population]
	mov [textrefstack],eax
	ret

// Same but in the town directory
// in:	ESI -> town
// safe:EBX,EBP
global display32bitpopulation2
display32bitpopulation2:
	mov ebx,[townarray2ofst]
	mov ebx,[ebx+esi+town2.population]
	mov [textrefstack+6],ebx
	ret


// Display extended statistics in a town window
// in:	EDI -> current screen block descriptor
//	on stack: saved ESI -> window, CX,DX = screen X,Y pos., EBX -> town
// safe:EAX,(E)BX,(E)DX,EBP,EDI
global displayexttownstats
displayexttownstats:
	pop eax		// return address
	pop esi		// replicate the overwritten code
	pop dx
	pop cx
	pop ebx
	push eax	// push the address back

	mov ebp,[townarray2ofst]
	add ebp,ebx
	add edx,10
	pusha
	mov bx,ourtext(townlastmonthaccepted)
	call [drawtextfn]
	popa

	add edx,10
	pusha
	mov ebx,[cargotypenamesptr]
	mov esi,textrefstack
	mov eax,[ebx+0*2]
	mov [esi],eax
	movzx eax,word [ebp+town2.passlastmonth]
	mov [esi+2],eax
	mov eax,[ebx+2*2]
	mov [esi+6],eax
	movzx eax,word [ebp+town2.maillastmonth]
	mov [esi+8],eax
	mov eax,[ebx+5*2]
	mov [esi+12],eax
	movzx eax,word [ebp+town2.goodslastmonth]
	mov [esi+14],eax
	mov bx,statictext(towncargo3typesandamounts)
	call [drawtextfn]
	popa

	cmp byte [climate],0
	je .nomoretypes

	add edx,10
	pusha
	mov ebx,[cargotypenamesptr]
	mov esi,textrefstack
	mov eax,[ebx+11*2]
	mov [esi],eax
	mov eax,[ebx+9*2]
	mov [esi+6],eax
	mov ebx,[esp+16]	// saved ebx->town
	movzx eax,word [ebx+town.foodlastmonth]
	mov [esi+2],eax
	movzx eax,word [ebx+town.waterlastmonth]
	mov [esi+8],eax
	mov bx,statictext(towncargo2typesandamounts)
	cmp byte [climate],2
	je .drawthesecondline
	mov bx,statictext(towncargo1typeandamount)

.drawthesecondline:
	call [drawtextfn]
	popa

.nomoretypes:
	ret


// Set height of a town window when it's being created
// in:	CX = 7 (window type)
//	EBX = width + (height<<16), original
// out:	EBX = width + (height<<16), modified
//	DX = 0x18 (class offset)
//	EBP = 5 (index of the handler function)
// safe:EAX,ESI,EDI
global settownwindowsize
settownwindowsize:
	// get the window height increase
	xor eax,eax
	mov al,20
	cmp byte [climate],0
	je .temperate
	add al,10
.temperate:

	ror ebx,16
	mov edx,ebx
	sub edx,13
	add bx,ax
	rol ebx,16
	add ax,dx

	// extend the stats display area
	mov esi,[esp]
	mov esi,[esi+17-6]
	mov [esi+4*12+8],ax

	// move window elements that are below the stats area
	imul eax,0x10001	// propagate to the upper 16 bits
	add eax,1+(12<<16)

.elementsloop:
	add esi,12
	cmp byte [esi],11
	je .endofelements
	cmp [esi+6],dx
	jb .elementsloop
	mov [esi+6],eax
	jmp .elementsloop

.endofelements:
	mov dx,0x18
	mov ebp,5
	ret
