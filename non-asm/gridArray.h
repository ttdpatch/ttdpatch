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

typedef struct {

	double** data; /* data array */
        
        ulong size_x; /* size of the array */
        ulong size_y; /* size of the array */
} gridArray;

void snipArray (gridArray* source_,ulong  size_x_,ulong  size_y_,gridArray** this_);
/* copy constructor for creating the array from another
   array with its sub-cutted elements */

void makeArray (ulong size_x_, ulong size_y_,uint (*randomizer)(void), gridArray** this_);
/* construct an array of a given size */

ulong size_x(gridArray* this_);

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

ulong size_x(gridArray* this_);
/* returns the size of the array in the x vector */

ulong size_y(gridArray* this_);
/* returns the size of the array in the y vector */

double val (ulong indice_x, ulong indice_y, gridArray* this_);
/* return the height data at the x, y */

void insert (long double val,ulong indice_x, ulong indice_y, gridArray* this_);
/* insert a value into the array */

void test (long* current, long* prev);
/* check if the value is between -1 and 1
   needed for the "ttsation" of the original
   long double array */

int recursiveTest(ulong range, ulong x, ulong y, gridArray* this_);
/* recursive test of whether a tile can be a desert tile
	 needs an improvement to seek a circual pattern and not
	 a 'star' like currently */

int dist(ulong otherSize, ulong other, ulong mySize, ulong indice, gridArray* this_);
/* distance of the points when scaling to a larger size */
#endif
