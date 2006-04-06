// allow snow line on temperate

#include <std.inc>


uvard temp_snowline	// the real snowline var is a byte, but action D supports dwords only
			// that's why we need a temporary var to store it, which will be
			// copied to the real var
