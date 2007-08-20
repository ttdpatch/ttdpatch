#include <defs.inc>
#include <frag_mac.inc>
#include <house.inc>
#include <town.inc>
#include <ptrvar.inc>

extern clearnewhousesafeguard,expandnewtown,expandnewtown.oldfn
extern findvariableaccess_add,findvariableaccess_len,findvariableaccess_start
extern malloccrit,housepartflags
extern newhouseoffsets,newhouseyears,orghouseoffsets,reloc
extern variabletofind
extern variabletowrite
extern newhousepartflags, newhouseflags, newhousemailprods, newhouseremoveratings
extern newhouseremovemultipliers, newhousenames, correctexactalt.chkslope

ptrvarall newhousedatablock

ext_frag findvariableaccess,newvariable

global patchnewhousedata

begincodefragments

codefragment oldaccesshouseyears,3
	cmp cl,[nosplit 2*ebp+0]
houseyearsoffset equ $-4

codefragment oldgeneratehousecargo,-8
	push ax
	push ebp
	shr al,3

codefragment newgeneratehousecargo
	icall generatehousecargo

codefragment oldgethouseaccept
	movzx ebx,byte [landscape2+edi]
	db 0x8a,0xa3		// mov ah,[ebx+...

codefragment newgethouseaccept
	ijmp gethouseaccept

codefragment oldgetrandomhousetype,-8
	bt si,bp
	jnb $+2+0xa

codefragment newgetrandomhousetype
	call runindex(getrandomhousetype)
	jmp short fragmentstart+44

codefragment oldgethouseidedxebx
	movzx edx,byte [landscape2+ebx]
	db 0x8a,0x92

codefragment newgethouseidedxebx
	call runindex(gethouseidedxebx)
	setfragmentsize 7

codefragment oldgethouseidebpebx13,1
	pop ebx
	movzx ebp,byte [landscape2+ebx]

codefragment newgethouseidebpebx134
	call runindex(gethouseidebpebx)
	setfragmentsize 7

codefragment oldgethouseidebpebx24
	movzx ebp,byte [landscape2+ebx]
	db 0xf6,0x85

codefragment newgethouseidebpebx2
	call runindex(gethouseidebpebx)
	call runindex(isoldhouseanimated)
	setfragmentsize 14

codefragment oldgethouseidedxedi1,4
	ror di,4
	movzx edx,byte [landscape2+edi]

codefragment newgethouseidedxedi
	call runindex(gethouseidedxedi)
	setfragmentsize 7

codefragment oldgethouseidedxedi2,6
	jz near fragmentstart+489
	movzx edx,byte [landscape2+edi]

codefragment newcanremovehouse
	call runindex(canremovehouse)
	setfragmentsize 7

codefragment oldgethouseidebpesi
	movzx ebp,byte [landscape2+esi]

codefragment newgethouseidebpesi
	call runindex(gethouseidebpesi)
	setfragmentsize 7

codefragment oldgethouseidecxedi
	movzx ecx,byte [landscape2+edi]
	db 0x66,0x8b

codefragment newgethouseidecxedi
	call runindex(gethouseidecxedi)
	setfragmentsize 7

codefragment oldgethouseidesiebx,2
	push dx
	movzx esi,byte [landscape2+ebx]

codefragment newgethouseidesiebx
	call runindex(gethouseidesiebx)
	setfragmentsize 7

codefragment oldtestcreatechurchorstadium
	cmp bp,0x5b
	jnz $+2+0xc

codefragment newtestcreatechurchorstadium
	call runindex(testcreatechurchorstadium)
	jc near fragmentstart-0x8c
	jnz near fragmentstart-0x8c
	jmp near fragmentstart+0x72

codefragment oldcreatechurchorstadium,4
	inc word [esi+town.buildingcount]
	cmp bp,0x5b

codefragment newcreatechurchorstadium
	call runindex(createchurchorstadium)
	jmp short fragmentstart+0x4d

codefragment oldremovechurchorstadium,2
	pop ax
	cmp bp,0x5b
	jnz $+2+5

codefragment newremovechurchorstadium
	call runindex(removechurchorstadium)
	jmp short fragmentstart+0x4d

codefragment oldputhousetolandscape,5
	or ch,ah
	shr eax,16

codefragment newputhousetolandscape
	call runindex(puthousetolandscape)
	jmp fragmentstart+0x152+0xc*WINTTDX

codefragment oldgethousegraphics
	shl dx,2
	or si,dx

codefragment newgethousegraphics
	call runindex(gethousegraphics)
	pop dx
	setfragmentsize 13

codefragment oldclass3periodicproc
	mov ax,[nosplit landscape3+2*ebx]
	and al,0xc0

codefragment newclass3periodicproc
	call runindex(class3periodicproc)
	setfragmentsize 8

codefragment oldmakenewtown,9
	pop ax
	shl ax,2

codefragment oldclass3animation
	mov al,[landscape2+ebx]
	cmp al,5

codefragment newclass3animation
	call runindex(class3animation)
	setfragmentsize 12

codefragment oldclass3drawfoundation,9
	and bx,0x0f
	add bx,989

codefragment newclass3drawfoundation
	mov ebp,edi
	add dl,8
	icall displayfoundation
	setfragmentsize 14

codefragment oldcheckhouseslopes_short,-12
	xor bl,bl
	test di,0xf

codefragment newcheckhouseslopes
	call runindex(checkhouseslopes)
	setfragmentsize 10

reusecodefragment oldcheckhouseslopes_long,oldcheckhouseslopes_short,-16

codefragment oldprocesshouseconstruction
	or al,al
	js $+2+0x12+2*WINTTDX
	mov ah,al

codefragment newprocesshouseconstruction
	call runindex(processhouseconstruction)
	jmp short fragmentstart+20

codefragment oldchangeconststate,2
	add al,0x40
	mov [nosplit landscape3+2*ebx],ax

codefragment newchangeconststate
	call runindex(changeconststate)
	setfragmentsize 8

codefragment oldplacerocks
	and dh,0xe3
	or dh,8

codefragment newplacerocks
	icall placerocks

codefragment oldremovehousetilefromlandscape,-12
	push esi
	push ebp
	rol cx,8

codefragment newremovehousetilefromlandscape
	icall removehousetilefromlandscape

codefragment oldfoundtileincatchment
	mov si,ax
	movzx edi,bx
	movzx ebp,si

codefragment_call newfoundtileincatchment,foundtileincatchment

extern operrormsg2
codefragment oldcanindustryreplacehouse_bigtown
	mov word [operrormsg2],0x029D	//...can only be built in towns with a population of at least 1200
	cmp bl,0x18

codefragment_call newcanindustryreplacehouse_bigtown,canindustryreplacehouse_bigtown,9

codefragment oldcanindustryreplacehouse
	mov word [operrormsg2],0x030D	//...can only be built in towns
	cmp bl,0x18

codefragment_call newcanindustryreplacehouse,canindustryreplacehouse,9

codefragment oldcanindustryreplacehouse_watertower
	mov word [operrormsg2],0x0316	//...can only be built in towns
	cmp bl,0x18

codefragment_call newcanindustryreplacehouse_watertower,canindustryreplacehouse_watertower,9

endcodefragments

patchnewhousedata:
	push newhousedata_size
	call malloccrit
	// leave on stack for reloc
	push newhousedatablock_ptr
	call reloc

	call clearnewhousesafeguard

// To allow more building types, we redirect the old TTD arrays to
// bigger ones
// Before doing that, save the offsets of the old arrays so we can
// access them later
	mov esi,housepartflags
	mov edi,orghouseoffsets
	xor ecx,ecx
	mov cl,12
	rep movsd
// Update offset vars defined in vars.ah, so all patch code uses the
// new arrays
	mov esi,newhouseoffsets
	mov edi,housepartflags
	mov cl,12
	rep movsd
// Now we need to replace all TTD references to house arrays to use the new
// ones.
//baHousePartFlags
	mov eax,[orghouseoffsets]
	mov [variabletofind],eax
	mov dword [variabletowrite],newhousepartflags
	multipatchcode findvariableaccess,newvariable,2
//baHouseFlags (also accessed with offsets -1,-2 and -3)
	mov eax,[orghouseoffsets+4*1]
	mov [variabletofind],eax
	mov dword [variabletowrite],newhouseflags
	multipatchcode findvariableaccess,newvariable,14
	dec dword [variabletofind]
	dec dword [variabletowrite]
	multipatchcode findvariableaccess,newvariable,2
	dec dword [variabletofind]
	dec dword [variabletowrite]
	patchcode findvariableaccess,newvariable,1,1
	dec dword [variabletofind]
	dec dword [variabletowrite]
	patchcode findvariableaccess,newvariable,1,1
//baHouseAvailYears
	mov eax,[orghouseoffsets+4*2]
	mov [variabletofind],eax
	mov [houseyearsoffset],eax
	mov dword [variabletowrite],newhouseyears
	patchcode oldaccesshouseyears,newvariable,1,1
	mov eax, newhouseyears+1
	mov [edi+lastediadj+9],eax
//baHousePopulations
// 3 of the 4 accesses are overwritten by patchmoretowndata
// the remaining one needs to be overwritten for the production
// callback anyway
	patchcode generatehousecargo
//baHouseMailGens
	mov eax,[orghouseoffsets+4*4]
	mov [variabletofind],eax
	mov dword [variabletowrite],newhousemailprods
	patchcode findvariableaccess,newvariable,1,1
// Accept maps
	patchcode oldgethouseaccept,newgethouseaccept
//waHouseRemoveRatings
	mov eax,[orghouseoffsets+4*8]
	mov [variabletofind],eax
	mov dword [variabletowrite],newhouseremoveratings
	patchcode findvariableaccess,newvariable,1,1
//baHouseRemoveCostMultipliers
	mov eax,[orghouseoffsets+4*9]
	mov [variabletofind],eax
	mov dword [variabletowrite],newhouseremovemultipliers
	patchcode findvariableaccess,newvariable,1,1
//waTownBuildingNames
	mov eax,[orghouseoffsets+4*10]
	mov [variabletofind],eax
	mov dword [variabletowrite],newhousenames
	patchcode findvariableaccess,newvariable,1,1
//waHouseAvailMaskTable is accessed from one place only and we need to
//overwrite it anyway
	patchcode oldgetrandomhousetype,newgetrandomhousetype,1,1

//	patchcode oldclass3init,newclass3init,1,1

// Now patch codes that assume the house ID being in L2 to use our
// gameid function instead
	patchcode oldgethouseidedxebx,newgethouseidedxebx,1,1
	multipatchcode oldgethouseidebpebx13,newgethouseidebpebx134,2
	patchcode oldgethouseidebpebx24,newgethouseidebpebx2,1,2
	patchcode oldgethouseidebpebx24,newgethouseidebpebx134,1,1
	patchcode oldgethouseidedxedi1,newgethouseidedxedi,1,1
	patchcode oldgethouseidedxedi2,newcanremovehouse,1,1
	patchcode oldgethouseidebpesi,newgethouseidebpesi,1,1
	patchcode oldgethouseidecxedi,newgethouseidecxedi,1,1
	patchcode oldgethouseidesiebx,newgethouseidesiebx,1,1

	patchcode oldtestcreatechurchorstadium,newtestcreatechurchorstadium,1,1
	patchcode oldcreatechurchorstadium,newcreatechurchorstadium,1,1
	patchcode oldremovechurchorstadium,newremovechurchorstadium,1,1

	patchcode oldputhousetolandscape,newputhousetolandscape,1,1
	patchcode oldgethousegraphics,newgethousegraphics,1,1
	patchcode oldclass3periodicproc,newclass3periodicproc
	stringaddress oldmakenewtown,1,2
	chainfunction expandnewtown,.oldfn
	patchcode oldclass3animation,newclass3animation,1,1
	patchcode oldclass3drawfoundation,newclass3drawfoundation,1+WINTTDX,2
	patchcode oldcheckhouseslopes_short,newcheckhouseslopes,1,4
	patchcode oldcheckhouseslopes_long,newcheckhouseslopes,2,4
	patchcode oldcheckhouseslopes_short,newcheckhouseslopes,3,4
	patchcode oldcheckhouseslopes_long,newcheckhouseslopes,4,4
	patchcode oldprocesshouseconstruction,newprocesshouseconstruction,1,1
	patchcode oldchangeconststate,newchangeconststate,1,1

	patchcode placerocks

	patchcode removehousetilefromlandscape

	// fix the ground alt. correction code for houses
	mov ebp,[ophandler+3*8]
	mov dword [ebp+0x14],correctexactalt.chkslope

extern stationarray2ofst
	patchcode oldfoundtileincatchment,newfoundtileincatchment,1,2,,{cmp dword [stationarray2ofst],0},nz

	patchcode canindustryreplacehouse_bigtown
	patchcode canindustryreplacehouse
	patchcode canindustryreplacehouse_watertower
	ret
