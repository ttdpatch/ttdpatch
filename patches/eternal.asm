//
// Keep counting days and years above 2070; make getting Y,M,D from dates after 2070 work
//

#include <std.inc>
#include <flags.inc>
#include <veh.inc>
#include <patchdata.inc>
#include <industry.inc>
#include <newvehdata.inc>

extern getlongymd,getfullymd,getymd,patchflags,newvehdata



// Fix year 2070 problem with service intervals
// Called at the end of New Year processing if currentyear>=151 (i.e. year>=2071)
// Sets currentdate and currentyear back to 2070
//
// in:	nothing
// out:	nothing
// safe:everything except ESP
global limityear
limityear:
	movzx eax,word [currentdate]
	mov ebx,eax
	mov edx,0xD604			// the 'setback' point, 2070-1-1
	sub ebx,edx
	mov [currentdate],dx

	// check how many years we're above 2070
	push ebx
	call [getfullymd]		// must return EAX>150 unless something got very broken
	pop ebx
	xor edx,edx
	sub eax,0xFFFF-2070+150
	jbe short .limited
	xor eax,eax			// so that locations that use it as unsigned word won't overflow
.limited:
	add ax,0xFFFF-2070

	// now AX = actualyear-2070, EBX = date adjustment
	// record these
	add [landscape3+ttdpatchdata.daysadd],ebx
	mov [landscape3+ttdpatchdata.yearsadd],ax

	// subtract the adjustment values from all "last serviced" dates and "built" years
	mov esi,[veharrayptr]
.procnext:
	cmp byte [esi+veh.class],0x10
	jb .nextveh
	cmp byte [esi+veh.class],0x13
	ja .nextveh
	dec byte [esi+veh.yearbuilt]
	cmp dword [esi+veh.scheduleptr],byte -1
	je .nextveh

	sub [esi+veh.lastmaintenance],bx

.nextveh:
	sub esi,byte -vehiclesize
	cmp esi,[veharrayendptr]
	jb .procnext

	// currentyear is being set back, so decrement variables that are compared to it
	mov esi,[industryarrayptr]
	xor ecx,ecx
	mov cl,NUMINDUSTRIES
.nextind:
	dec byte [esi+industry.lastyearprod]
	add esi,industry_size
	loop .nextind

	testflags newhouses
	jnc .nonewhouses

	// New houses are on - we need to adjust the building year in landscape7,
	// so the age reported to the grf is still valid. The age is still capped
	// to 255, though, because we cannot go negative

	mov ecx,landscape7
	xor esi,esi

.houseloop:
	mov al,[landscape4(si)]
	shr al,4
	cmp al,3
	jne .nexttile

	cmp byte [ecx+esi],0
	je .nexttile

	dec byte [ecx+esi]

.nexttile:
	inc esi
	cmp esi,0x10000
	jb .houseloop

.nonewhouses:
	ret
; endp limityear


// Get year, with 4 years precision, from date, including eternalgame adjustment
// in:	EAX = date (says since year 0, may be negative)
// out: EAX = (year - 1920) & ~3
//	EDX = julian days since the year in EAX (0..1460)
// uses:EBX
// note: on return, the high 16 bits of EBX are guaranteed to be zero
//	unless the original date was negative (before 1920)
global getyear4fromdate
getyear4fromdate:
	xor edx,edx
	add eax,701265			// add days since 'year 0'
	add eax,[landscape3+ttdpatchdata.daysadd]
	adc edx,edx			// EDX was 0
	mov ebx,146097			// 400 years
	idiv ebx			// note: can't overflow

	shl eax,2
	shr ebx,2			// EBX = 36524
	cmp edx,ebx
	jbe short .century_ok		// the first of each four centuries is a leap century
	sub edx,ebx
	dec edx

.adjcentury:
	inc eax
	sub edx,ebx
	jnc short .adjcentury
	add edx,ebx
	cmp edx,byte 59			// not a leap century => the 0th year is not a leap year
	jb short .century_ok		// note that we count a century from xx00 to xx99
	inc edx
.century_ok:

	// now EAX=century, EDX=days since the start of century (as if it were a leap century)
	imul eax,byte 100
	push eax
	xchg eax,edx
	xor edx,edx
	mov ebx,1461
	div ebx				// can't overflow either

	shl eax,2
	xchg eax,ebx			// so that EBX{16..31} is zero
	pop eax
	add eax,ebx

	// now EAX=year & ~3, EDX=remaining days
	sub eax,1920
	ret
; endp getyear4fromdate


// For locations that display year as an unsigned word, put an upper bound on the value returned by getyear4fromdate
// i/o: EAX = year (1920-based)
// safe:-
global reduceyeartoword
reduceyeartoword:
	cmp eax,0xFFFF-1920
	jbe short .nottoohigh
	mov eax,0xFFFF-1920
.nottoohigh:
	ret

// For locations that use year as a byte value, put an upper bound on the value returned by getyear4fromdate
// i/o: EAX = year (1920-based), assuming it's been already limited by reduceyeartoword
// safe:-
global reduceyeartobyte
reduceyeartobyte:
	cmp ax,150
	jbe short .nottoohigh
	mov ax,150		// the internal maximum is 2070, everything else is in display only
.nottoohigh:
	ret


// When eternalgame is enabled, we need a different method of figuring out if year has changed
// in:	AX = year returned by [getymd]
// out:	ZF clear if it's new year
//	AL = year to be written to [currentyear] if ZF=0
// safe:everything else except ESP
global isnewyear
isnewyear:
	mov eax,[currentdate]	// the modified getfullymd clears the high word anyway
	call [getfullymd]	// we need to know if the year is above 2070
	or bl,dl		// day=month=0 means 1 Jan
	jz short .newyear	// Note: this won't trigger if date is changed into the middle of another year
	xor bl,bl		// STZ
	ret

.newyear:
	cmp eax,151
	jb short .yearok	// ZF=0 if CF=1
	xor eax,eax		// if year >=2071 we reduce it to 2071 to make sure it triggers limityear()
	or al,151		// ZF=0

.yearok:
	ret
; endp isnewyear


// Fake current year when checking for disaster time
// out:	AL = year-1920, not larger than 234
//	EBX = 0
// safe:EAX{8:31},ECX,EDX,EDI
global getdisasteryear
getdisasteryear:
	mov eax,[currentdate]	// getymd ignores the high word anyway
	call [getfullymd]
	cmp eax,234
	jbe short .yearok
	mov al,234
.yearok:
	xor ebx,ebx
	ret
; endp getdisasteryear


// get vehicle type's year of introduction
// in:	EBX = vehtype offset
//	AX = vehtype.introduced
// out:	AX = year (full)
// safe:EBX,EDX,EDI
global getvehintroyear
getvehintroyear:
	movzx eax,ax
	test eax,eax
	jz .getlong
	cmp ax,byte -1
	jne .notoutofrange
.getlong:
	xchg eax,ebx
	mov bl,vehtype_size
	div bl
	mov eax,[vehlongintrodate+eax*4]
	test eax,eax
	jz .notoutofrange
	sub eax,701265	// 1920
.notoutofrange:
	xor edi,edi
	xchg edi,[landscape3+ttdpatchdata.daysadd]	// those years are all below 2070
	call [getlongymd]
	xchg edi,[landscape3+ttdpatchdata.daysadd]
	add ax,1920
	ret
; endp getvehintroyear


// correct years for graphs
// in:	SI = year (full, i.e. value from an earlier getymd call + 1920)
// out:	SI = corrected year
global getgraphstartyear
getgraphstartyear:
	add si,[landscape3+ttdpatchdata.yearsadd]
	mov bl,[ebp+0x615]			// overwritten by runindex call
	ret
; endp getgraphstartyear


// correct the year a vehicle was built in
// in:	EDI -> vehicle struct
// out:	AX = year (full)
// safe:BX,ESI,EDI
global showyearbuilt
showyearbuilt:
	movzx ax,[edi+veh.yearbuilt]
	add ax,1920
	add eax,[landscape3+ttdpatchdata.yearsadd]	// upper word is not relevant
	ret
; endp showyearbuilt
