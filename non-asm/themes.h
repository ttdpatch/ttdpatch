#ifndef __THEMES_H__
#define __THEMES_H__

/*
* Adam Kadlubek 2006
* Terrain Generator for TTD
* under GPL license
* version written in C, not protable
* to C++
*/

/*
* in all cases this_ is the pointer to a result
*/

#include "gridArray.h"
#include <ttdvar.h>

/*
* creates freeform terrain (no desert)
* par1 - amount of hills
* par2 - amount of water
*/

void freeForm (int hills, int water, uint8_t forced, gridArray** desert_,  gridArray** this_);

/*
* creates a classic arctic/tropic terrain (half one thing, half another)
*/

#if 0	// never used
void classic (uint8_t forced, gridArray** desert_, gridArray** this_);
#endif

/*
* creates a valley themed terrain
* par1 - width of the river inside
*/

void valley (int width, uint8_t  forced, gridArray** desert_, gridArray** this_);

/*
* creates a mountain range through the terrain
* par 1 - width of the shores
*/

void mountains (int width, uint8_t forced, gridArray** desert_, gridArray** this_);

/*
* creates a shoreline - ie mountains at one edge and sea on the other
* par1 - max height
* par2 - angle
*/
#if 0	// never used
void shoreline (int height, int angle, uint8_t forced, gridArray** desert_, gridArray** this_);

/*
* creates an atol - ie an island circular in shape
* note - no desert will be created!
*/

void atolTheme ( uint8_t forced, gridArray** this_);

/*
* creates a longmap - ie a twisty S shaped map
* par1 - amout of hilliness
*/

void longmap (int hills,  uint8_t forced, gridArray** desert_, gridArray** this_);
#endif

#endif
