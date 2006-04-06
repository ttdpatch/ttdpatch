; NASM macros that use the imm8 form of an instruction if possible
; these only work with a recent enough version of NASM, in which the
; preprocessor recognizes and terminates otherwise recursive definitions
;
; these macros don't recognize numeric expressions unless they start with a
; number

%macro makeopsize 1.nolist
	%define opsize
	%ifnum %1
		%ifndef PREPROCESSONLY
			%if (%1>=-0x80)&&(%1<=0x7f)
				%define opsize byte
			%endif
		%endif
	%endif
%endmacro

%macro adc 2.nolist
	makeopsize %2
	adc %1,opsize %2
%endmacro

%macro add 2.nolist
	makeopsize %2
	add %1,opsize %2
%endmacro

%macro and 2.nolist
	makeopsize %2
	and %1,opsize %2
%endmacro

%macro cmp 2.nolist
	makeopsize %2
	cmp %1,opsize %2
%endmacro

%macro imul 2.nolist
	makeopsize %2
	imul %1,opsize %2
%endmacro

%macro imul 3.nolist
	makeopsize %3
	imul %1,%2,opsize %3
%endmacro

%macro or 2.nolist
	makeopsize %2
	or %1,opsize %2
%endmacro

%macro push 1.nolist
	makeopsize %1
	push opsize %1
%endmacro

%macro sbb 2.nolist
	makeopsize %2
	sbb %1,opsize %2
%endmacro

%macro sub 2.nolist
	makeopsize %2
	sub %1,opsize %2
%endmacro

%macro xor 2.nolist
	makeopsize %2
	xor %1,opsize %2
%endmacro
