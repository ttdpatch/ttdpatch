; vim: syntax=nasm
;
; NASM macros to generate procs with local variables and arguments
; in Pascal calling convention
;
;
; Usage:
; proc foo
;	local local1,local2,local3
;	arg arg1,arg2,arg3
;	slocal localword,word
;	slocal fourdwords,dword,4
;	sarg argword,word
;
;	_enter	; make the stack frame
;
;	mov eax,[%$local1]
;	lea esi,[%$fourdwords]		; mov esi,%$fourdwords isn't valid
;	add word [%$argword],15
;
;	_ret	; remove stack frame and return
; endproc
;
;	push thisarg1
;	push thisarg2
;	push thisarg3
;	call foo
;
; You can use several arg or local statements.  For arg and local, the
; size is assume to be DWORDs.  For sarg and slocal, the size is the
; second parameter, and the number of elements is the optional third
; parameter.  Note that this only specifies how much memory is reserved
; (in the case of slocal) or assumed to be on the stack (for sarg).
; To access the variable, you still need to specify the memory size,
; either explicitly, or implicitly through a register size.
;
; Calling _ret is also optional.  If no _ret is present in the proc, endproc
; will generate one.  To assemble a ret without removing the stack frame,
; use "_ret <imm16>".
;
;
;-------------------------------------
;
; carry out all arg and local definitions
; (necessary because initially we don't know the total size of the args and locals)
%macro dodef 0-*.nolist
	%rep %0
		%xdefine %$%1 %$addr_%1
		%rotate 1
	%endrep
%endmacro


; Build stack frame using the acculumated number of local variables
; Redefine "ret" to give an error (must use _ret instead)
%macro _enter 0.nolist
	%ifnctx proc
		%error "Cannot use _enter outside of proc"
	%endif

	; use "enter" instruction if there are locals, otherwise
	; the other way is shorter
	%if %$locals
		enter %$locals,0
	%elif %$args
		push ebp
		mov ebp,esp
	%endif
	; define local variables if we haven't yet
	%ifndef %$didenter
		%assign %$args %$args+4
		dodef %$defs
		%define %$didenter
	%endif
%endmacro


; Restore stack frame and return, removing arguments from stack
%macro _ret 0.nolist
	%ifnctx proc
		%error "Cannot use _ret outside of proc"
	%endif
	%if %$locals || %$args
		leave
	%endif
	%if %$args<>4
		ret %$args-4
	%else
		ret
	%endif
	%define %$didret
%endmacro


; When called with an argument, _ret overrides the above _ret
; to allow assembling a specific ret instruction
%macro _ret 1.nolist
	%if %1
		ret %1
	%else
		ret
	%endif
%endmacro


; begin a procedure definition
%imacro proc 1.nolist
	%ifctx proc
		%error "Already in proc definition (started at %$procstart)"
		%pop
		%push proc
	%else
		%push proc
	%endif
	global %1
%1:

	%assign %$args 0
	%assign %$locals 0
	%xdefine %$procstart __FILE__:__LINE__
%endmacro

; store the name of a symbol that was %define'd in this proc's args or locals
%macro adddef 1.nolist
	%ifdef %$defs
		%xdefine %$defs %$defs,%1
	%else
		%xdefine %$defs %1
	%endif
%endmacro

%define dword_size 4
%define word_size 2
%define byte_size 1

%macro checkprocarg 3.nolist
	%ifndef %2_size
		%error "Unknown size %2"
	%endif
	%ifnctx proc
		%error "Proc variable definition outside of proc"
	%endif
	%ifdef %$didenter
		%error "Proc variable definition after _enter"
	%endif
	%ifnum %1
		%error Numerical variable name %1, did you want to use %3?
	%endif
	%ifdef %1_size
		%error Variable name is %1, did you want to use %3?
	%endif
%endmacro

; remember definitions of new arguments on the stack
; use %xdefine to get current value of %$args but leave actual
; definition relative to final value of %$args (to be expanded
; by dodef
%imacro sarg 1-3.nolist dword,1
	checkprocarg %1,%2,sarg
	adddef %1
	%xdefine %$arg_%1 %$args
	%define %$addr_%1 ebp+%$args-%$arg_%1
	%assign %$args %$args+%2_size*%3
%endmacro
%imacro arg 1-*.nolist
	%rep %0
		sarg %1
		%rotate 1
	%endrep
%endmacro

; remember definition of new local variables on the stack
%imacro slocal 1-3.nolist dword,1
	checkprocarg %1,%2,slocal
	adddef %1
	%xdefine %$local_%1 %$locals
	%define %$addr_%1 ebp-%$locals+%$local_%1
	%assign %$locals %$locals+%2_size*%3
%endmacro
%imacro local 1-*.nolist
	%rep %0
		slocal %1
		%rotate 1
	%endrep
%endmacro

; close the procedure
; do an automatic _ret if no _ret was called before
; make "ret" a normal instruction again
%imacro endproc 0-*.nolist
	%ifnctx proc
		%error endproc without proc
	%else
		%ifndef %$didret
			_ret
		%endif
		%pop
	%endif
%endmacro
