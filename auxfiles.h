#ifndef AUXFILES_H
#define AUXFILES_H
//
// This file is part of TTDPatch
// Copyright (C) 1999-2003 by Josef Drexler
//
// C++ to C conversion by Marcin Grzegorczyk
//
// auxfiles.h: definitions for auxfiles.c
//

#include <stdio.h>
#include "types.h"

// supported auxiliary files
#define AUX_LANG 0	// language data (.exe or language.dat)
#define AUX_PROTCODE 1	// protected mode code (.exe or ttdprot?.bin)
#define AUX_RELOCOFS 2	// relocation data (.exe or reloc.bin)
#define AUX_PATCHSND 3	// patchsnd.dll (.exe or patchsnd.dll)

#define AUX_FIRST 0	// first and
#define AUX_LAST 3	// last of the codes above

#define AUX_ALL -1	// special code for closing all files, not a specific one

#define AUX_NUM AUX_LAST+1	// number of aux files

#define PROTCODE "ProtCode"
#define LANGCODE "LangData"
#define RELOCOFS "RelocDat"
#define PATCHSND "PatchSnd"
#define CODELEN 8	// length of code word to find attachment

int findattachment(int auxnum, u32 *ofs, FILE **f);

int auxopen(int auxnum);
int auxclose(int auxnum);

void auxcloseall(void);

void setexename(char *cmdline);

#endif
