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
#define AUX_LOADER 1	// TTDPatch loader (.exe or loader?.bin)
#define AUX_PROTCODE 2	// protected mode code (.exe or ttdprot?.bin)
#define AUX_RELOCOFS 3	// relocation data (.exe or reloc.bin)
#define AUX_PATCHDLL 4	// ttdpatch.dll (.exe or ttdpatch.dll)

#define AUX_FIRST 0	// first and
#define AUX_LAST 4	// last of the codes above

#define AUX_ALL -1	// special code for closing all files, not a specific one

#define AUX_NUM AUX_LAST+1	// number of aux files

#define LOADCODE "LoadCode"
#define PROTCODE "ProtCode"
#define LANGCODE "LangData"
#define RELOCOFS "RelocDat"
#define PATCHDLL "PatchDll"
#define CODELEN 8	// length of code word to find attachment

int findattachment(int auxnum, u32 *ofs, FILE **f);

int auxopen(int auxnum);
int auxclose(int auxnum);

void auxcloseall(void);

void setexename(char *cmdline);

#endif
