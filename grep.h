/*
 *  Grep.h - Implement a pattern search, in files and memory; header file
 *
 *  Copyright (C) 1999 by Josef Drexler, jdrexler@julian.uwo.ca
 *
 *  Copy freely as long as it is not modified and all copyright notices
 *  remain intact.
 *
 */

// Define GREP_BLKSIZE as block size for grepfile if you need a different
// value that the default (see below).  Has to be less than 65535-longest
// string

#include <stdio.h>
#include <string.h>

#define GREP_NOMATCH 0xffff
#define GREP_NOMATCHL 0xffffffffL

extern unsigned int grep_blksize;

extern char *grepalloc(unsigned int);
extern void grepfree(char *);

unsigned int grepmem(
		const void *memblock,
		unsigned int memsize,
		const void *search,
		unsigned int searchlen,
		unsigned int occurence
		);

unsigned long grepfile(
		FILE *f,
		const void *buf,
		unsigned int buflen,
		unsigned int occurence,
		unsigned long maxlen
		);
