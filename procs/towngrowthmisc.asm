#include <defs.inc>
#include <frag_mac.inc>
#include <bitvars.inc>

extern towngrowthratemode,miscmodsflags

global patchtowngrowthmisc

begincodefragments

codefragment oldsettowngrowthrate,2
	mov ch,5
	movzx ecx,ch

codefragment newsettowngrowthrate
	or cl,cl			// save space by placing it here
	call runindex(settowngrowthrate)
	setfragmentsize 9

codefragment newgottownfood
	call runindex(gottownfood)

//codefragment oldgottownfoodandwater,-7
//	cmp word [esi+town.waterlastmonth],0

codefragment newgottownfoodandwater
	call runindex(gottownfoodandwater)
	setfragmentsize 12

codefragment newxcalctowngrowthrate	// replaces the whole growth rate calculation code
	call runindex(newcalctowngrowthrate)
	jc $+0x71+7*WINTTDX
	ret

//codefragment oldgottownfood
//	cmp al,[snowline]

codefragment oldremovehouse
	and bl,0xC0
	cmp bl,0xC0

codefragment newremovehouse
	call runindex(fixremovehouse)

codefragment oldexpandtownstreet
	mov bl,0xB
	mov esi,0x10

codefragment newexpandtownstreet
	call runindex(expandtownstreetflags)
	setfragmentsize 7

codefragment oldbuildnewtownhouse
	mov bl,0xB
	mov esi,0x18

codefragment newbuildnewtownhouse
	call runindex(buildnewtownhouseflags)
	setfragmentsize 7


endcodefragments

patchtowngrowthmisc:
	patchcode oldsettowngrowthrate,newsettowngrowthrate,1,1
	%xdefine settowngrowthrate_lastediadj lastediadj		// we'll need this value later
	mov al,[towngrowthratemode]
	cmp al,2
	je .brandnewcalcfn
	cmp al,0
	jne .notmode0

	// mode 0: fix a TTD bug by limiting the number of active stations to 4
	// (the original limit is 5 but TTD's table has only 4 entries)
	mov byte [edi+lastediadj-1],4
	mov byte [edi+lastediadj-5],4

.notmode0:
	cmp al,1
	jne .populationlimits

	// mode 1: leave the limit of active stations at 5 (explicitly supported in patches/bigcity.asm)
	// also use a second table when a building fund is active
	mov byte [edi+lastediadj-27],0x13	// redirect a short jump to our new codefragment

.populationlimits:
	// population lower limits in snow and desert, active in both modes 0 and 1
	// after storing newsettowngrowthrate, EDI must remain unchanged up to this point!
	add edi,byte settowngrowthrate_lastediadj+30+7*WINTTDX	// 0+expr to trigger the macro in opimm8.mac
	storefragment newgottownfood
	add edi,byte lastediadj+36				// note: this is a new lastediadj
	storefragment newgottownfoodandwater
	jmp short .ratecalcpatched

.brandnewcalcfn:
	// mode 2: replace the whole growth rate calculation with our function
	// (so patches done in .populationlimits are not needed)
	add edi,byte settowngrowthrate_lastediadj-0x27
	storefragment newxcalctowngrowthrate

.ratecalcpatched:

	patchcode oldremovehouse,newremovehouse,1,1
	mov byte [edi+15],0x85		// kill the original DEC; the most space-efficient way is to change it into a TEST CX

	stringaddress oldexpandtownstreet
	test byte [miscmodsflags],MISCMODS_NOBUILDONBANKS
	pushf
	jnz .skip1
	storefragment newexpandtownstreet
.skip1:
	stringaddress oldbuildnewtownhouse
	popf
	jnz .skip2
	storefragment newbuildnewtownhouse
.skip2:
	ret
