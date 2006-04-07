// This file is part of TTDPatch
//
// systexts.h: List of language-specific texts
// passed to the assembly code
//

// This will be included both in C and assembly code, therefore we
// define each list item with a special one-line macro systxt(textid),
// where textid is a member of enum langtextids (see language.h).

systxt(LANG_PMOUTOFMEMORY)

#if WINTTDX
systxt(LANG_PMIPCERROR)
#else
systxt(LANG_PRESSESCTOEXIT)
#endif

systxt(OTHER_NEWGRFCFG)
