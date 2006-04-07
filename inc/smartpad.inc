;
; usage:
;	pad <size>
;
; pad a block of <size> bytes with as few no-op instructions as possible
;
; uses the minimum number of the following instructions, in various forms:
; lea esi,[esi+0]	(3, 4, 6 or 7 bytes)
; lea si,[si+0]		(5 bytes)
; lea esi,[esi]		(2 bytes)
; xchg eax,eax		(1 byte)
;
; or combinations thereof for all other sizes
;
; you can avoid the use of the 5-byte lea si,[si+0] by defining pad_no_prefix
; in that case, two instructions are used to pad 5 bytes.
;
; this macro assumes a 32-bit section
;

%macro pad 1.nolist
	%if %1<=0
		;
	%elif %1<8
		db __pad_%1
	%else
		%push pad
		%assign %$remain %1
		%rep %1
			%if %$remain<15 && %$remain>0
				%assign %$this %$remain
			%elif %$remain>0
				%assign %$this 7
			%else
				%exitrep
			%endif
			%assign %$remain %$remain-%$this
			db __pad_ %+ %$this
		%endrep
		%pop
	%endif
%endmacro

%define __pad_1  0x90				; nop = xchg eax,eax
%define __pad_2  0x8d,0x36			; lea esi,[esi]
%define __pad_3  0x8d,0x76,0			; lea esi,[esi+byte 0]
%define __pad_4  0x8d,0x74,0x26,0		; lea esi,[byte 0+1*esi]
%define __pad_5  0x66,0x67,0x8d,0x74,0		; lea  si,[si+byte 0]
%define __pad_6  0x8d,0xb6,0,0,0,0		; lea esi,[esi+dword 0]
%define __pad_7  0x8d,0xb4,0x26,0,0,0,0		; lea esi,[dword 0+1*esi]
%define __pad_8  __pad_4,__pad_4		; combinations of the above,
%define __pad_9  __pad_6,__pad_3		; avoiding __pad_5
%define __pad_10 __pad_6,__pad_4
%define __pad_11 __pad_7,__pad_4
%define __pad_12 __pad_6,__pad_6
%define __pad_13 __pad_7,__pad_6
%define __pad_14 __pad_7,__pad_7

; prefixes can cause partial register stall, you can define pad_no_prefix
; to use two instructions for 5-byte pad instead of a single one with prefixes
%ifdef pad_no_prefix
	%define __pad_5 __pad_3,__pad_2
%endif
