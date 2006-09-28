#ifndef __GRIDARRAY_H__
#define __GRIDARRAY_H__

/*
* Adam Kadlubek 2006
* Terrain Generator for TTD
* under GPL license
* version written in C, not protable
* to C++
*
* This is actually a refactor of a C++ class
* that is why all ex-methods have the explicit
* 'this_' pointer
*/

typedef unsigned long ulong;
typedef unsigned  int uint;

#define NOBMP /* undefining this requires
compliation as C++ as BMP is a class */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

typedef struct {

	double** data; /* data array */
        
        ulong size_x; /* size of the array */
        ulong size_y; /* size of the array */
} gridArray;

#ifdef __GNUC__
	#define INLINE static inline
	#define INLINE_DEF
#else
	#define INLINE
#endif

void snipArray (gridArray* source_,ulong  size_x_,ulong  size_y_,gridArray** this_);
/* copy constructor for creating the array from another
   array with its sub-cutted elements */

void makeArray (ulong size_x_, ulong size_y_,uint32_t (*randomizer)(void), gridArray** this_);
/* construct an array of a given size */

void destroyArray(gridArray** this_);
/* destructor of the array */

void mulScalar (double scalar, gridArray* this_);
/* scalar multiply operator */

void addArray(gridArray* _source, gridArray* this_);
/* addition of two arrays */

void addScalar(double scalar, gridArray* this_);
/* addition of a value to all array elements */

void scale(ulong newSize_x, ulong newSize_y, gridArray** this_);
/* scale the given array to a new size */

void filter(ulong iterations, gridArray** this_);
/* smooth the given array by x times using bilinear filtering */

void go(ulong iterations, gridArray** this_);
/* do the generation using the iterations set by the user */

void normalize(double low, double hi, gridArray* this_);
/* normalize the array to the low-hi range */

#ifndef NOBMP
void image(const char* filename, gridArray* this_);
/* inputs the map as a bmp image */
#endif

void ttMap(ulong cutDown, ulong cutUp, gridArray* this_);
/* change the map to fulfill the Transport
   Tycoon requirements for the vertex data */

void ttDesert(gridArray* target, ulong min, ulong max, ulong range, gridArray* this_);
/* make TT desert */

void print (gridArray* this_);
/* print the contents of the array */

int recursiveTest(ulong range, ulong x, ulong y, gridArray* this_);
/* recursive test of whether a tile can be a desert tile
	 needs an improvement to seek a circual pattern and not
	 a 'star' like currently */

/*
*
* return size of the array
*
*/

#ifdef INLINE_DEF
INLINE ulong size_x(gridArray* this_)
{
  return this_->size_x;
}

/*
*
* likewise
*
*/

INLINE ulong size_y(gridArray* this_)
{
  return this_->size_y;
}

/*
*
* return value under indices
*
*/

INLINE double val (ulong i_x, ulong i_y, gridArray* this_)
{

  if (size_x(this_) <= i_x || size_y(this_) <= i_y)
    return -1000000.0;

  return this_->data[i_x][i_y];
}

/*
*
* insert value under indices
*
*/

INLINE void insert (long double val,ulong i_x, ulong i_y, gridArray* this_)
{
  if (size_x(this_) > i_x && size_y(this_) > i_y)
    this_->data[i_x][i_y] = val;
}

/*
*
* test if one of values is bigger than another
*
*/

INLINE void test (long* current, long* prev)
{
  if (*current > *prev)
    *current = *prev + 1;
  if (*current < *prev)
    *current = *prev - 1;
}

/*
*
* check if two verices are close/far away.
* needed for scaling
*
*/

INLINE int dist(ulong otherSize, ulong other, ulong mySize, ulong indice, gridArray* this_) {

  double len = 0.0;
  double my = indice *1.0 /mySize;
  double ot = other  *1.0 /otherSize;

  len = (ot-my)*mySize*1.0;
  return (len < 1.0);
}
#else
INLINE ulong size_x(gridArray* this_);
INLINE ulong size_y(gridArray* this_);
INLINE double val (ulong i_x, ulong i_y, gridArray* this_);
INLINE void insert (long double val,ulong i_x, ulong i_y, gridArray* this_);
INLINE void test (long* current, long* prev);
INLINE int dist(ulong otherSize, ulong other, ulong mySize, ulong indice, gridArray* this_);
#endif

#endif
