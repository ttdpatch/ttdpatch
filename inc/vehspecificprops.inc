// sizes of each entry in the vehicle specific data tables
// (the layout in memory)
// format: total, sizes...

%push defveh	// so we don't need to undef all these temporary identifiers

%define %$s_B 1
%define %$s_W 2
%define %$s_P 4

%macro defvehdata 1-*.nolist	// params: name,arraysizes...
	%assign %$totalsize 0
	%rotate 1
	%rep %0-1
		%assign %$totalsize %$totalsize+%$s_ %+ %1
		%rotate 1
	%endrep
	%assign %1_totalsize %$totalsize
%endmacro

defvehdata spectraindata, B,W,W,B,P,B,B,B,B,B,B,B	// 08..18

defvehdata specrvdata, B,B,P,B,B,B,B,B			// 08..12

defvehdata specshipdata, B,B,B,B,B,W,B,B		// 08..10

defvehdata specplanedata, B,B,B,B,B,B,B,W,B,B		// 08..12

defvehdata specbridgedata, B,B,B,B			// 08..0B

%undef defvehdata

%pop
