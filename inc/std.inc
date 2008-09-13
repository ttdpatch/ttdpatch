// include standard variable definitions

#include <var.inc>
#include <ttdvar.inc>

ptrvardec landscape6
ptrvardec landscape7
ptrvardec landscape8
ptrvardec objectpool

%ifndef param_call
// call a procedure with parameters on the stack
%macro param_call 1-*.nolist	// params: target, params...
	%define target %1
	%rotate 1
	%rep %0-1
		push %1
		%rotate 1
	%endrep
	call target
	%undef target
%endmacro
%endif

