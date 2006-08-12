/*
 *  Grep.c - Implement a pattern search, in files and memory
 *
 *  Copyright (C) 1999 by Josef Drexler, jdrexler@julian.uwo.ca
 *
 *  Copy freely as long as it is not modified and all copyright notices
 *  remain intact.
 *
 */

//#define DEBUG

#include <stdlib.h>
#include "grep.h"

#if defined(DEBUG) && DEBUG
#	include <conio.h>
#	include <errno.h>
#	include <string.h>
#endif

//
// grepmem: search a memory block for a string of bytes (including 0!)
//
// memblock: pointer to the memory block
// memsize:  number of bytes in the block
// search:   pointer to search string (not null-terminated)
// searchlen:number of bytes in search string
// occurence:search how often; 1=find first occurence; 2=find second etc.
//
// returns GREP_NOMATCH if error in parameters or nothing found
// returns offset into grepmem if found
//
unsigned int grepmem(
		const void *memblock,
		unsigned int memsize,
		const void *search,
		unsigned int searchlen,
		unsigned int occurence
		)
{
  unsigned int remain = memsize;
  const char *found = (const char *) memblock;

  while (occurence && remain && found) {

	found = memchr(found, *(const char *) search, remain);

	if (found) {
		unsigned int offset = (unsigned int) (found - (const char *) memblock);
		remain = memsize - offset;
		if (searchlen > remain) return GREP_NOMATCH;
		if (!memcmp(found, search, searchlen))
			if ( (--occurence) == 0)
				return offset;

		found++;
	}

  };

  return GREP_NOMATCH;
}

//
// grepfile: search a random access binary file for a string of
//           bytes (including 0!)
//
// f:        file to search.  Search starts at current ftell() position and
//           goes on till  the end of the file
// buf:      pointer to search string (not null-terminated)
// buflen:   number of bytes in search string
// occurence:search how often; 1=find first occurence; 2=find second etc.
// maxlen:   maximum number of bytes looked at to limit the range (-1 for unlimited)
//
// returns GREP_NOMATCHL if error in parameters or nothing found
// returns file offset into grepmem if found, counting from 0, i.e. do a
//         fseek(f, grepfile(), SEEK_SET, 1, -1) to seek to that position
//
// File position is undefined when grepfile returns.
//

unsigned long grepfile(
		FILE *f,
		const void *buf,
		unsigned int buflen,
		unsigned int occurence,
		unsigned long maxlen
		)
{
  char *curdata, *data;
  unsigned int block, blockeff, blocksize;
  unsigned long foundofs, found, posi, rest;
  size_t bytesread;

  if (!f || !buf || !buflen || !occurence)
	return GREP_NOMATCHL;

  if (!grep_blksize)
	grep_blksize = 32768;

  data = malloc(grep_blksize + buflen);
  if (!data)
	return GREP_NOMATCHL;

  posi = ftell(f);
  fseek(f, 0, SEEK_END);
  rest = ftell(f) - posi;

  if (maxlen) if (rest > maxlen) rest = maxlen;

  do {
	curdata = data;

	fseek(f, posi, SEEK_SET);

	if (rest < grep_blksize)
		block = rest;
	else
		block = grep_blksize;

	blockeff = block + (unsigned long) buflen;

	if (blockeff > rest)
		blockeff = rest;

	foundofs = posi;

	bytesread = fread(curdata, 1, blockeff, f);
	if (bytesread != blockeff) {
//#if defined(DEBUG) && DEBUG
//		cprintf("??  Wanted %d, got %ld.  %s\n\r",
//			blockeff, bytesread, strerror(errno));
//#else
		return GREP_NOMATCHL;
//#endif
	}

	do {

		found = grepmem(curdata, blockeff, buf, buflen, 1);
		if (found != GREP_NOMATCH) {
			curdata += found + 1;
			blockeff -= found + 1;
			foundofs += found;
			if (--occurence)
				foundofs++;
		}

	} while ( (found != GREP_NOMATCH) && occurence);
	posi += block;
	rest -= block;
  } while ( rest && (found == GREP_NOMATCH) && occurence);

  free(data);

  if (found == GREP_NOMATCH)
	return GREP_NOMATCHL;
  else
	return foundofs;
}
