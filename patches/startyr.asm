//
// Make things work right over a wider range of start years
//

#include <defs.inc>
#include <player.inc>
#include <vehtype.inc>
#include <ttdvar.inc>

extern haverailengines,isengine,newsmessagefn

// Auxiliary function: convert pointer to vehtype to index, check if it's an engine
// in:	EAX->vehtype
// out:	EAX=vehtype index
//	CF set if engine, clear if waggon
// uses:ECX,EDX
getvehtypeidx:
	sub eax,vehtypearray
	xor edx,edx
	xor ecx,ecx
	mov cl,vehtype_size
	div ecx

	bt [isengine],eax
	ret


#if 0
// Make all default waggons available at game initialization
// in:	ESI->vehtypeinfo
//	EDI->vehtype being initialized
//	BX=introdate
// out:	CF=ZF=0 (cc=A) if it's too early
// safe:AX (not EAX)
initvehtypeavail:
	pusha
	xchg eax,edi
	call getvehtypeidx
	cmc
	jnc .engine

		// waggons available only if they don't have new graphics
	cmp dword [vehids+eax*4],1
		// now carry is set if it was at default settings

.engine:
	popa
	jc .done			// waggon -> exit with CF=1

	sub bx,[currentdate]		// overwritten

.done:
	ret
; endp initvehtypeavail
#endif


// Prevent new waggons from updating player.tracktypes
// when a new type becomes available
// in:	ESI->vehtype
//	CX=vehtype index
//	EDX->player
//	AH=vehtype.enginetraintype
// safe:EBX,EDI
global updaterailtype1
updaterailtype1:
	bt [isengine],cx
	jnc .done
	mov [edx+player.tracktypes],ah
.done:
	ret

// ...and when a vehicle type becomes available exclusively
// in:	ESI->vehtype
//	EBX->player
//	AL=vehtype.enginetraintype
// safe:EBX,?
global updaterailtype2
updaterailtype2:
	pusha
	xchg eax,esi
	call getvehtypeidx
	popa
	jnc .done
	mov [ebx+player.tracktypes],al
.done:
	ret


// Don't display "New <wagon type> available" message
// if there are no engines for the corresponding track type
// in:	ESI->vehtype
//	DX=vehtype index
//	AX,EBX,CX set for the news message fn
// safe:EDI
global gennewrailvehtypemsg
gennewrailvehtypemsg:
	push edx
	mov dl,[esi+vehtype.enginetraintype]
	call haverailengines			// in patches/unimagl.asm
	pop edx
	jnc .done

	mov dh,1			// DX must be nonzero (upper byte cleared in codefragment newgetrailengclassname)
	call [newsmessagefn]

.done:
	ret


// Prevent waggons from being expired at the init time
// i/o:	ESI->vehtype
global expirevehtype
expirevehtype:
	pusha
	xchg eax,esi
	call getvehtypeidx
	popa
//	jnc .done
	and word [esi],byte 0		// make unavailable
.done:
	ret
; endp expirevehtype
