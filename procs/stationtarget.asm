#include <defs.inc>
#include <frag_mac.inc>


extern prepareforrailroutecheck


global patchstationtarget

begincodefragments

codefragment oldistargetstation,
	je $+2+0x57
	db 0x66,0x3b,0x3d	// cmp di,[oldplatformarray]

codefragment newistargetstation
	icall istargetstation
	jmp fragmentstart+18

codefragment oldstoretargetstation,-53-9*WINTTDX	// ,9
	mov cx,1
	db 0xbf	// mov edi,[...]

codefragment newstoretargetstation
	mov dh,[esi+veh.currorder]
	and dh,0x1f
	cmp dh,1
	mov dh,0xff		// invalid station index
	jne .notstation
	mov dh,[esi+veh.currorder+1]
// FIXME	mov word [ebx-0xa4],0	// change [CurTraceRouteTarget] too
				// so we don't find the north xy tile
.notstation:
	mov [ebx],dh		// store target station index (FF if not station)
	mov byte [ebx+1],0	// make sure word at [ebx] is not a valid destination
	jmp newstoretargetstation_start+117+17*WINTTDX


endcodefragments

patchstationtarget:
	patchcode istargetstation
	mov word [edi+lastediadj-6],0x1d8b	// cmp di, -> mov bx
	patchcode oldstoretargetstation,newstoretargetstation,1,2
	mov word [edi+lastediadj-7],0x368d	// 2-byte nop
	mov byte [edi+lastediadj-5],0xbb	// mov word [] -> mov ebx,
	lea eax,[byte edi+lastediadj-30]
	mov [prepareforrailroutecheck],eax
	patchcode oldstoretargetstation,newstoretargetstation,2,2
	mov word [edi+lastediadj-7],0x368d	// 2-byte nop
	mov byte [edi+lastediadj-5],0xbb	// mov word [] -> mov ebx,
	ret


	// en-route time calculation if generalfixes or feederservice is on
