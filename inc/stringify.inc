//
// Provide a macro to stringify its arguments
//


// stringify prefix,args...,postfix
// expands to  <prefix " arg " postfix> for each argument
[warning -]	// disable "unterminated string" warning due to the lone quote below
%macro stringify 3-*.nolist
	%define %%quote "
	%define %%prefix %1
	%rotate %0-1
	%define %%postfix %1
	%rotate 1
	%rep %0-2
		%%prefix %%quote %2 %%quote %%postfix
		%rotate 1
	%endrep
%endmacro
[warning +]

