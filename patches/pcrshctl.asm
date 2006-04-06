//
// check additional plane crash conditions
//

#include <std.inc>
#include <bitvars.inc>

extern planecrashctrl

extern randomfn


// in:	 ESI -> vehicle struct
//	 EBX -> station the plane is landing on
//	 CX = crash probability
// out:	 CF=ZF=0 (A) if no crash is going to happen
// safe: EAX, ECX, EDX, EDI

global controlplanecrashes
controlplanecrashes:
	mov	al,byte [planecrashctrl]

	cmp	cx,pplanecrashjetonsmall
	jz	short .jetonsmall
// normal crash rate...
	test	al,pcrashctrl_normoff
	jnz	short .nocrash
	test	al,pcrashctrl_normdis
	jz	short .continue

.testdisasters:
//	cmp	word ptr [disasters],0
	cmp word [disasters],byte 0
	jnz	short .continue

.nocrash:
	or	al,1		// force CF=ZF=0
	ret

// jet-on-small crash rate...
.jetonsmall:
	test	al,pcrashctrl_jetsoff
	jnz	short .nocrash
	test	al,pcrashctrl_jetssamerate
	jz	short .jetsprobset
	mov	cx,pplanecrashnorm	// reduce crash probability to normal
.jetsprobset:
	test	al,pcrashctrl_jetsdis
	jnz	short .testdisasters

.continue:
	test	al,pcrashctrl_normbrdown
	jz	short .callrandom
	cmp	cx,byte pplanecrashnorm
	jnz	short .callrandom
	cmp	byte [esi+0x4b],1	// is broken down?
	jnz	short .nocrash
	shl	cx,2			// increase crash probability

.callrandom:
	call	dword [randomfn]
	cmp	ax,cx		// from the original code
	ret
; endp controlplanecrashes 
