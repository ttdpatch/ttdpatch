#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>
#include <window.inc>
#include <ptrvar.inc>
#include <station.inc>

extern createrailstactionhook,createrailstactionhook.oldfn,patchflags,createairportactionhook,createdockactionhook
extern createbusstactionhook,createlorrystactionhook,busstcheckadjtilehookfunc,lorrystcheckadjtilehookfunc
extern class5vehenterleavetilestchngecheckpatch,buslorrystationbuilt, createbuoyactionhook,createbuoyactionhook.oldfn
extern createbuoymergehook

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

codefragment oldcreateairport1, -10
push    ax
push    bx
push    cx
rol     cx, 8
mov     di, cx
rol     cx, 8
or      di, ax
ror     di, 4
mov     ax, di
db 0x8B, 0x2D	//mov     ebp, ppOpClass3

codefragment oldcreatedocks1, -23
loc_150E82 equ $+0x150E82-0x150E51
pop     bx
xor     dl, dl
cmp     di, 3
jz      short loc_150E82
inc     dl
cmp     di, 9
jz      short loc_150E82
inc     dl
cmp     di, 0Ch
jz      short loc_150E82
inc     dl
cmp     di, 6
jz      short loc_150E82
db 0x66, 0xC7

codefragment oldcreatebuoy1, -86-WINTTDX*2
/*
or      esi, esi
jnz     short loc_150BEF
retn    
loc_150BEF:
push    ax
push    bx
push    cx
push    esi
rol     cx, 8
mov     di, cx
rol     cx, 8
or      di, ax
ror     di, 4
mov     ax, di
db 0x8B		//mov     ebp, ppOpClass3         ; Towns
*/


mov     ebx, 1
call    dword [ebp+4]       // FindNearestTown
pop     esi
pop     cx
pop     bx
pop     ax
mov     [esi+station.townptr], edi
mov     BYTE [esi+station.namewidth], 0
rol     cx, 8
mov     di, cx
rol     cx, 8
or      di, ax
ror     di, 4
db 0xC6

codefragment newcheckadjsttilebus1
icall busstcheckadjtilehookfunc
setfragmentsize 6+WINTTDX*2

codefragment newcheckadjsttilelorry1
icall lorrystcheckadjtilehookfunc
setfragmentsize 6+WINTTDX*2

codefragment newcheckadjsttileairport1
icall airportstcheckadjtilehookfunc
setfragmentsize 6+WINTTDX*2

codefragment newcheckadjsttiledocks1
icall dockstcheckadjtilehookfunc
setfragmentsize 6+WINTTDX*2

codefragment newclass5vehenterleavetilestchngecheckfunc1
icall class5vehenterleavetilestchngecheckpatch
setfragmentsize 6+WINTTDX*1

codefragment newbuslorrystationbuiltcondfunc1
icall buslorrystationbuiltcondfunc
setfragmentsize 7

codefragment newbuoymergehookfrag1
icall createbuoymergehook
setfragmentsize 7

codefragment oldbuslorrystationbuilt1
dw 0
push    eax
push    esi
mov     esi, 0FFFFFFFFh
push    ebx
mov     bx, ax
mov     eax, 1Dh

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

stringaddress oldcreateairport1
storerelative edi, createairportactionhook
add edi, 0x189+WINTTDX*2
storefragment newcheckadjsttileairport1

stringaddress oldcreatedocks1
storerelative edi, createdockactionhook
add edi, 0x198+WINTTDX*2
storefragment newcheckadjsttiledocks1

stringaddress oldcreatebuoy1
chainfunction createbuoyactionhook, .oldfn
add edi, 0x49+WINTTDX*2
storefragment newbuoymergehookfrag1

mov eax, [ophandler+5*8]
mov edi, [eax+40]
add edi, 0x49+(0x1E*WINTTDX)
storefragment newclass5vehenterleavetilestchngecheckfunc1

stringaddress oldbuslorrystationbuilt1, 1, 2
add edi, 2
mov [buslorrystationbuilt], edi
storefragment newbuslorrystationbuiltcondfunc1

ret
