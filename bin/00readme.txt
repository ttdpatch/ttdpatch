
This directory contains some batch files to run various steps of the
compilation.

ALLLOWER.BAT
	Convert all source code files to lower case filenames.  This is
	necessary for the dependencies to work.
MK.BAT
	Call make, and override the default DEBUG=1 if the first parameter
	is a capital "R".
SETALL.BAT
	Main environment variable definitions used almost everywhere
T.BAT
T2.BAT
	Run Far Commander with the correct environment etc.  Change this
	to suit your own development shell.
TOLOWER
	Bash script to convert files to lower case filenames.
TTDST_L.BAT
	Start TTDPatch set to a certain language
