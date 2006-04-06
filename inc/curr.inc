
// Macro to get the real currency if using the morecurrencies patch.
// The parameter is the register to put the currency in
%macro getcurr 1
	movzx %1, byte [landscape3+ttdpatchdata.realcurrency]
	or %1,%1
	jz %%usedefault
	dec %1
	jmp short %%foundcurr
%%usedefault:
	movzx %1, byte [currency]
%%foundcurr:
%endmacro


// count of currencies for morecurrencies
%assign currcount 19

// define indices into the currency arrays
%define CURR_POUND 0
%define CURR_DOLLAR 1
%define CURR_FRANC 2
%define CURR_DEUTSCHMARK 3
%define CURR_YEN 4
%define CURR_PESETA 5
%assign CURR_EURO currcount-1 // **MUST** always be last, or it can't be introduced later!

// %define firstcuscurrtext ourtext(curr_pound)	// Text for the first new currency

