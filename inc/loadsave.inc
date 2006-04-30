
// Flags to indicate what switches were active when saving the L6 array
%assign L6_ABANROAD			0x1	// abandoned roads
%assign L6_NEWSTATIONS			0x2	// new station layouts
%assign L6_NEWHOUSES			0x4	// random bits for houses
%assign L6_PATHSIG			0x8	// path based signalling
%assign L6_NEWINDUSTRIES		0x10	// random triggers for industries

	// versions of TTDPatch before 2.0.1 alpha 10 have four bytes of
	// garbage after the L6 chunk.  if the following bit is set in the
	// L6 chunk flags, the patch knows that the chunk was saved correctly
	// for backwards compatibility (and compatibility with the TTDX Editor)
%assign L6_SIZECORRECT			1<<30	// size is saved correctly

// Flags to indicate what switches were active when saving the L7 array
%assign L7_HIGHERBRIDGES		0x1	// higher bridges
%assign L7_NEWHOUSES			0x2	// build years for houses
%assign L7_NEWINDUSTRIES		0x4	// random bits for industries
%assign L7_ONEWAYROADS			0x8	// oneway road flags
%assign L7_NEWSTATIONS			0x10	// animation state for station tiles

// Flags to indicate what switches were active when saving the station2 array
%assign S2_FIFOLOADING			0x1	// fifo loading
%assign S2_CATCHMENT			0x2	// catchment areas for stations
%assign S2_NEWCARGO			0x4	// extra cargo data for newcargos
%assign S2_IRRSTATIONS			0x8	// extra cargo data for newcargos


