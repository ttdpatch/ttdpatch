#include <defs.inc>
#include <frag_mac.inc>


extern settowngrowthlimit.townsizefactorvarptr


global patchtowngrowthfactor

begincodefragments

codefragment oldsettownzones
	cmp bx,88

codefragment newsettownzones
	call runindex(settownzones)
	jb short $+4
	ret

codefragment oldsettowngrowthlimit,4
	mov bl,0x5E
	div bl,0	// ,0 to disable div-by-zero handling code
	or al,0x80

codefragment newsettowngrowthlimit
	call runindex(settowngrowthlimit)
	setfragmentsize 7


endcodefragments

patchtowngrowthfactor:
	patchcode oldsettownzones,newsettownzones,1,1
	mov eax,[edi+lastediadj+19]	// get address of TTD's town zone table
	add eax,18*5*2			// change the transport zone radii in the last 5 entries
	mov bx,100
	mov word [eax],bx		// write reasonable values there instead of the original zeros
	mov word [eax+1*5*2],bx		// so that transport continues to boost growth
	mov bl,121
	mov word [eax+2*5*2],bx
	mov word [eax+3*5*2],bx
	mov word [eax+4*5*2],144

	patchcode oldsettowngrowthlimit,newsettowngrowthlimit,1,1
	mov eax,[edi+lastediadj-16]
	mov [settowngrowthlimit.townsizefactorvarptr],eax
	ret
