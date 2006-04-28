
// structure for pre-signal stuff
struc presignalstack
	.signalrun: 	resb 1	// 0=first in loop, otherwise bit coded:
				// 1=in loop, 2=check other dir from single,
				// 4=recursive setting of pre-signal block
				// 8=check setup of the multi side only
				// 10=called after manually modifying pre-signal
				// 20=called after modifying track setup
				// 40=need to recurse into exits
				// 80=recursive call
	.othersidetype: resb 1	// 0=no pre-signals, 1=one two-way, at most one one-way (exit block)
				// 2=multiple two-ways, at least one one-way (pre-block)
	.mustsetstate: 	resb 1	// 0=all normal, 1=all special
				// -1=all normal except green combined signals; those special
	.specialchangeop:resb 1	// 0=set to green, 1=set to red

	.signaltypecount: resb 2
		// 0:one-way this dir,  1:two-way this dir,
		// 2:one-way other dir, 3:two-way other dir

	.signalchangeop: resb 1	// 0=setting to green, 1=setting to red
	.twowaysignalbits:resb 1// bits to be changed in the two way signal

		align 4
	.signalsbase: 	resd 1	// ebp value of first entry in signal loop
	.signalscount: 	resw 1	// number of signals in this loop
	.unused:	resw 1	// unused for now

		align 4
	.twowaysignalpos:resd 1	// position of the two-way signal we want to check in the other direction
				// also while in recursion it indicates which
				// signal triggered the recursion
	.previousstack: resd 1	// previous stack frame
endstruc


