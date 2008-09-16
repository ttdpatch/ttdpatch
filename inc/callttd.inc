// A collection of macros for getting the linker to perform some of the
// relocation work for runtime-defined rel32s


// There are six versions, with arguments as follows:
// callttd/chaincall FuncName [, .oldfn]	Unconditional call to target
// jmpttd/chainjmp FuncName [, .oldfn]		Unconditional jump to target
// jmpttd/chainjmp FuncName [, [.oldfn], cond]	Conditional jump to target


// All define FuncName.oldfn. This must be resolved (usually in a procs file)
// before the instruction can be successfully executed, as follows:

// To resolve callttd and jmpttd, add the target's address to FuncName.oldfn
// To resolve chaincall and chainjmp, add the address and value of a rel32
// that points to the target.
//	chainttdfunction and/or copyttdrelative will automate this procedure.


%macro callttd 1-2 .oldfn
	extcall _absolute_0_
ovar %2, -4, $, %1
%endmacro

%macro jmpttd 1-2 .oldfn
	extjmp _absolute_0_
ovar %2, -4, $, %1
%endmacro

%macro jmpttd 3
	extern _absolute_0_
	j%+3 _absolute_0_
	%ifidn {%2},{}
		ovar .oldfn, -4, $, %1
	%else
		ovar %2, -4, $, %1
	%endif
%endmacro

%macro chaincall 1-2 .oldfn
	extcall _absolute_4_
ovar %2, -4, $, %1
%endmacro

%macro chainjmp 1-2 .oldfn
	extjmp _absolute_4_
ovar %2, -4, $, %1
%endmacro

%macro chainjmp 3
	extern _absolute_4_
	j%+3 _absolute_4_
	%ifidn {%2},{}
		ovar .oldfn, -4, $, %1
	%else
		ovar %2, -4, $, %1
	%endif
%endmacro

