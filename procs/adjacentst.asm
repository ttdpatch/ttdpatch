#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>
#include <window.inc>
#include <ptrvar.inc>

extern createrailstactionhook,createrailstactionhook.oldfn,patchflags
extern createbusstactionhook,createlorrystactionhook,busstcheckadjtilehookfunc,lorrystcheckadjtilehookfunc
extern class5vehenterleavetilestchngecheckpatch

begincodefragments

codefragment oldcreatestfrag1, -20
/*
_CS:0014E056 66 50                                   push    ax
_CS:0014E058 66 51                                   push    cx
_CS:0014E05A 66 52                                   push    dx
_CS:0014E05C 66 C1 C1 08                             rol     cx, 8
_CS:0014E060 66 8B F9                                mov     di, cx
_CS:0014E063 66 C1 C1 08                             rol     cx, 8
_CS:0014E067 66 0B F8                                or      di, ax
_CS:0014E06A 66 C1 CF 04                             ror     di, 4
_CS:0014E06E 0A FF                                   or      bh, bh
_CS:0014E070 74 02                                   jz      short loc_14E074
_CS:0014E072 86 D6                                   xchg    dl, dh
_CS:0014E074
_CS:0014E074                         loc_14E074:                                     ; CODE XREF: CreateRailwayStation+3Dj ...
_CS:0014E074 66 52                                   push    dx
_CS:0014E076 66 57                                   push    di*/

push    ax
push    cx
push    dx
rol     cx, 8
mov     di, cx
rol     cx, 8
or      di, ax
ror     di, 4
or      bh, bh
jz      short $+4
xchg    dl, dh
push    dx
push    di

codefragment oldcreatelorrybusstation1, -20
mov     dx, 101h
push    ax
push    cx
push    dx
rol     cx, 8
mov     di, cx
rol     cx, 8
or      di, ax
ror     di, 4
push    dx
push    di
db 0xE8 //call    sub_402031

codefragment newcheckadjsttilebus1
icall busstcheckadjtilehookfunc
setfragmentsize 6+WINTTDX*2

codefragment newcheckadjsttilelorry1
icall lorrystcheckadjtilehookfunc
setfragmentsize 6+WINTTDX*2

codefragment newclass5vehenterleavetilestchngecheckfunc1
icall class5vehenterleavetilestchngecheckpatch
setfragmentsize 7

endcodefragments

patchproc adjacentstation, patchadjst

patchadjst:

stringaddress oldcreatestfrag1
chainfunction createrailstactionhook,.oldfn
stringaddress oldcreatelorrybusstation1, 1, 2
storerelative edi, createbusstactionhook
add edi, 0xE5+WINTTDX*2
storefragment newcheckadjsttilebus1
stringaddress oldcreatelorrybusstation1, 2, 2
storerelative edi, createlorrystactionhook
add edi, 0xE5+WINTTDX*2
storefragment newcheckadjsttilelorry1

mov eax, [ophandler+5*8]
mov edi, [eax+40]
add edi, 0x4B+(0x1C*WINTTDX)
storefragment newclass5vehenterleavetilestchngecheckfunc1
