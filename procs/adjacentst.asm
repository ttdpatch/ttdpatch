// New clearer hook code redone by Lakie
#include <defs.inc> 
#include <frag_mac.inc> 
#include <patchproc.inc>
#include <window.inc>
#include <ptrvar.inc>
#include <station.inc>

begincodefragments

patchproc adjacentstation, patchadjst

begincodefragments

codefragment oldadjstactioncall, 5 // point to the call on the next line
db 0xBE, 0x28, 0x00 // Mov esi, 0x00tt0028 (uniquie to station functions)

codefragment newadjstactioncall
icall AdjacentStationHook
setfragmentsize 11
		
codefragment oldcreatelorrybusstation1, -20+0xE5+WINTTDX*2
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

codefragment oldcreateairport1, -10+0x189+WINTTDX*2
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

codefragment oldcreatedocks1, -23+0x198+WINTTDX*2
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

codefragment oldcreatebuoy1, -86+0x49
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

codefragment newbuoymergehookfrag1
icall createbuoymergehook
setfragmentsize 7

endcodefragments

// This is the hard part, honest
patchadjst: 
	// First three are player create station points on DOS and WINDOWS 
	patchcode oldadjstactioncall, newadjstactioncall, 1, 18
	patchcode oldadjstactioncall, newadjstactioncall, 2, 18
	patchcode oldadjstactioncall, newadjstactioncall, 3, 18
	// Last four vary in location between DOS and WINDOWS versions 
#if WINTTDX
	patchcode oldadjstactioncall, newadjstactioncall, 4, 18
	patchcode oldadjstactioncall, newadjstactioncall, 12, 18
	patchcode oldadjstactioncall, newadjstactioncall, 13, 18
#else
	patchcode oldadjstactioncall, newadjstactioncall, 16, 18
	patchcode oldadjstactioncall, newadjstactioncall, 17, 18
	patchcode oldadjstactioncall, newadjstactioncall, 18, 18
#endif

patchcode oldcreatelorrybusstation1, newcheckadjsttilebus1, 1, 2
patchcode oldcreatelorrybusstation1, newcheckadjsttilelorry1, 2, 2
patchcode oldcreateairport1, newcheckadjsttileairport1
patchcode oldcreatedocks1, newcheckadjsttiledocks1
patchcode oldcreatebuoy1, newbuoymergehookfrag1

mov eax, [ophandler+5*8]
mov edi, [eax+40]
add edi, 0x49+(0x1E*WINTTDX)
storefragment newclass5vehenterleavetilestchngecheckfunc1

ret
