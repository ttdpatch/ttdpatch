//
// Loading and organisation of some alternate graphics
//

#include <std.inc>
#include <flags.inc>
#include <proc.inc>
#include <textdef.inc>
#include <grf.inc>
#include <systexts.inc>
#include <bitvars.inc>
#include <flagdata.inc>
#include <house.inc>

extern calloc,copyspriteinfofn,curfileofsptr,curspriteblock,decodespritefn
extern dummygrfid,exscurfeature,exsfeaturemaxspritesperblock
extern exsfeatureuseseparatesprites,exsnumactspritesindex
extern exsrealtofeaturespriteeax,firsttownnamestyle,getnotable,getsystextaddr
extern grfvarreinitalwaysstart,grfvarclearstart
extern grfswitchparam,int21handler,spritegrfidcheckofs,spritecache
extern lastgenericspritealloc,malloc,malloccrit,newgrfflags,newspritedata
extern newspritenum,numactsprites,numgrfswitchparam,numspriteactions
extern numgrfvarreinitalways,numgrfvarreinitzero,numgrfvarreinitsigned
extern openfilefn,patchflags,readspriteinfofn,readwordfn
extern removespritefromcache,spriteblockptr
extern tempvard,grfvarreinitgrmstart,numgrfvarreinitgrm
extern vehids,curextragrm,lastextragrm,ourtext_ptr,defcargotrans


uvard spriteerror	// holds pointer to spriteblock with error
uvard spriteerrorparam	// and a parameter (if any)
uvard totalnewsprites	// total number of new sprites loaded
uvard totalmem		// total memory used
uvarb spriteerrortype	// 1: generated by TTDPatch, 2: generated by action B
			// 5: generated by TTDPatch, no extra address lookup

var defnewgrfcfg
#if WINTTDX
	db "newgrfw.cfg",0
#else
	db "newgrf.cfg",0
#endif
var defnewgrfcfg_end

varb basegrfname
#if WINTTDX
	db "newgrf/ttdpbasew.grf",0
#else
	db "newgrf/ttdpbase.grf",0
#endif
endvar
%define BASEGRF_VERCODE 0xBD25
%define BASEGRF_VERNUM 2


uvard dummyspriteblock

// called from initialize, with EDI pointing to the first byte of
// the "load GRF file" function in TTD
// Gets all necessary file and graphics functions and variables
global initializegraphics
proc initializegraphics
	local hnd

	_enter

	pusha

	// since 2.0 beta 1, ship data is *only* in newships.grf
	// so we only reserve a sprite block, but no data

	// add "fake" sprite block at the beginning to hold new ship data
	// in case the ship graphics aren't loaded (we do this even if
	// newships is off, because then they'll just be ignored later, but
	// some other things are initialized properly only if we do this)

	// allocate memory to hold the block and 1 sprite (action 8)
	call makespriteblock
	jc .none	// no memory

	mov eax,esi

	push 4
	call malloc
	pop edi
	jc .none

	mov [spriteblockptr],eax
	mov [curspriteblock],eax
	mov [dummyspriteblock],eax

	and dword [eax+spriteblock.next],0

	// insert dummy action 8 so that we have at least one in the list
	mov [eax+spriteblock.spritelist],edi
	mov byte [eax+spriteblock.numsprites],1
	mov dword [eax+spriteblock.paramptr],grfswitchparam
	mov ebx,numgrfswitchparam	// needs to be 32 bit since it's an external symbol
	mov byte [eax+spriteblock.numparam],bl

	mov eax,dummygrfid
	stosd

	// process newgrf(w).cfg
	call processnewgrf
	testflags canmodifygraphics,bts

.none:

.fail:
	popa

	_ret
endproc initializegraphics

proc processnewgrf
	local txtbuf,txtofs,txtlen,numparam,hnd,prevspriteblock
	// countonly,

	_enter

	mov al,systext_OTHER_NEWGRFCFG
	call getsystextaddr
	mov edx,eax
	mov ax,0x3d40
	CALLINT21
	jc near .fail

	xchg eax,ebx

	// find the file length
	mov ax,0x4202
	xor ecx,ecx
	xor edx,edx

	CALLINT21
	jc .fail

	shl edx,16
	mov dx,ax
	push edx

	add edx,4
	push edx
	call malloc
	pop dword [%$txtbuf]
	jc .fail	// leave clears up the stack too

	// and rewind
	mov ax,0x4200
	xor ecx,ecx
	xor edx,edx
	CALLINT21

	pop ecx		// now ecx=file size
	mov [%$txtlen],ecx
	mov edx,[%$txtbuf]
	mov [%$txtofs],edx
	jc .fail

	// read entire file
	mov ah,0x3f
	CALLINT21
	jnc .ok

.fail:
	// can't read newgrf.cfg, show error message
	mov al,systext_OTHER_NEWGRFCFG
	call getsystextaddr

	// is this the default filename?
	mov esi,eax
	mov edi,defnewgrfcfg
	mov ecx,defnewgrfcfg_end-defnewgrfcfg
	repe cmpsb
	je .noerr	// don't show error message for default filename

	mov esi,tempvard-spriteblock.filenameptr
	mov [esi+spriteblock.filenameptr],eax
	mov [spriteerror],esi
	mov byte [spriteerrortype],0
	mov word [operrormsg2],ourtext(filenotfound)
.noerr:
	_ret

.ok:
	and dword [edx+eax],0	// make sure there's a stop mark

	mov ah,0x3e	// close file
	CALLINT21

	mov esi,[%$txtofs]
.initialspace:
	mov [%$txtofs],esi
	lodsb
	cmp al,32
	je .initialspace
	cmp al,9
	je .initialspace

.nextgrf:
	and dword [%$numparam],0

	mov esi,[%$txtofs]
	mov edi,vehids		// using it as temporary variable for the params
	call parseline
	jc .nextgrf		// file couldn't be opened
	jz .done		// end of newgrf.cfg

	mov [%$txtofs],esi
	movzx edi,byte [%$numparam]
	test edi,edi
	jz .noparams

	mov ecx,edi
	shl edi,3		//copy the data two times to preserve the original parameters, was: 2 
	push edi
	add [totalmem],edi
	call malloc
	pop edi
	jc .fail		// leave clears up the stack too
	
	push edi //copy the data two times to preserve the original parameters
	
	push ecx
	mov esi,vehids
	rep movsd
	pop ecx
	mov esi,vehids
	rep movsd
	pop edi
	
//	mov esi,vehids
//	push edi
//	rep movsd
//	pop edi

.noparams:
	mov eax,[curspriteblock]
	mov [%$prevspriteblock],eax

	mov eax,[%$numparam]
	call readgrffile
	jmp .nextgrf

.done:
	mov ebx,[%$hnd]
	_ret


// parse the newgrf.txt file pointed to by esi
//
// out:	edx = filename
//	zero = reached end of newgrf.txt
//	carry = file doesn't exist/can't be opened
parseline:

.restart:

.nextchar:
	lodsb

.tryagain:
	cmp al,0
	je .foundeol	// end of the buffer
	cmp al,32
	je .foundparam
	cmp al,9
	je .foundparam

	cmp al,13
	je .foundeol
	cmp al,10
	jne .nextchar

		// found filename terminator
		// see whether know if parameters follow
.foundeol:
	mov byte [esi-1],0

.linedone:

	// skip all trailing whitespace (cr/lf/tab/space)
.skipchar:
	lodsb
	cmp al,10
	je .skipchar
	cmp al,13
	je .skipchar
	cmp al,32
	je .skipchar
	cmp al,9
	je .skipchar
	dec esi

.nextline:
	mov edx,[%$txtofs]
	mov [%$txtofs],esi

	mov eax,edx
	sub eax,[%$txtbuf]
	sub eax,[%$txtlen]
	sbb eax,eax			// 0 if at or beyond end of data, -1 if not
	je .done

	cmp byte [edx],'#'
	stc
	je .done	// skip comments, indicate as "file not found"
			// but without error message

	// see if we can open the file
	mov ax,0x3d40
	push edx
	CALLINT21
	pop edx
	jc .fail

	// close it again
	mov bx,ax
	mov ah,0x3e

	push edx
	CALLINT21
	pop edx

	or al,1		// clear zero and carry
	jmp short .done

.fail:
	push esi
	call makespriteblock
	jc .outofmem

	// fail with error message
	mov [esi+spriteblock.filenameptr],edx	// store the file name
	mov ax,ourtext(filenotfound)
	call setspriteerror

.outofmem:
	pop esi
	stc

.done:
	_ret 0

.foundparam:
		// write filename terminator only once, not after any parameters
	mov byte [esi-1],0

	lodsb
	cmp al,'!'
	jne .notbang

	// has bang parameter, so turn off by default
	or byte [%$numparam+1],1

.skipspace:
	lodsb
.notbang:
	cmp al,9
	je .skipspace
	cmp al,' '
	je .skipspace
	jb .linedone

	sub al,'-'
	sete bh
	je .isneg

	sub al,'0' - '-'
	jb .skipparam
	cmp al,9
	ja .skipparam

.isneg:
	movzx edx,al

.nextdigit:
	xor eax,eax
	lodsb

	sub al,'0'
	jb .gotit
	cmp al,9
	ja .gotit
	imul edx,10
	add edx,eax
	loop .nextdigit

.gotit:
	test bh,bh
	jz .notneg

	neg edx

.notneg:
	xchg eax,edx
	stosd

	inc byte [%$numparam]

.skipparam:
	dec esi
	jmp .restart
endproc initializegraphics


#define PRESPRITESIZE 8

// in:	eax=number of parameters
//	edx=pointer to filename
//	edi->parameter data (0 if none)
// out:	esi=number of sprites loaded (0 or less if failed)
proc readgrffile
	local sprite,spriteptr,len,numsprites,filename,numparam,paramofs,pseudo,curptr
	local fileoffset

	_enter

	mov [%$numparam],eax
	mov [%$filename],edx
	mov [curgrffile],edx
	mov [%$paramofs],edi
	call dword [openfilefn]
	mov esi,0		// clear esi without disturbing flags
	jc near .fail		// file open failed

	mov [tempspritefilehandle],bx

	mov [curfileblocksize],si	//0

	mov eax,dword [curfileofsptr]
	mov dword [eax],esi	//0

	or dword [%$sprite],byte -1

.nextsprite:
	mov eax,[%$sprite]
	mov [curgrfsprite],eax

	call dword [readwordfn]
	movzx eax,ax	// to support sprite sizes > 32K
	mov [%$len],eax
	test eax,eax
	jz near .done

	mov edi,[curfileofsptr]
	mov edi,[edi]
	mov [%$fileoffset],edi

	// waste another 8 bytes for each sprite to store various data
	// for the sprite actions, plus the sprite number and pseudo/regular type

	add eax,PRESPRITESIZE
	push eax
	add [totalmem],eax
	call malloc
	pop edi
	jc near .outofmem

	add edi,PRESPRITESIZE

#ifdef DEBUGSPRITESTORE
	push dword [%$sprite]
	push dword [%$len]
	push edi
	call log_spritestore
#endif

	mov esi,[%$sprite]
	cmp esi,byte -1
	je .first

	cmp esi,[%$numsprites]
	jae near .toomany

	mov eax,[%$spriteptr]
	mov [eax+esi*4],edi

.first:
	mov [%$curptr],edi
	mov eax,[%$len]
	mov [edi-4],eax
	inc esi
	mov [edi-8],esi
	call dword [copyspriteinfofn]
	test ax,ax
	setz [%$pseudo]		// mark as regular or pseudo sprite
	call dword [decodespritefn]

	cmp dword [%$sprite],byte -1
	jne short .notspritenum

	call makespriteblock
	jc .outofmem

	// first sprite in the file, tells us how many sprites there are
	mov eax,[%$filename]
	mov [esi+spriteblock.filenameptr],eax
	mov eax,[%$paramofs]
	mov [esi+spriteblock.paramptr],eax
	mov eax,[%$numparam]
	shl eax, 2
	add eax,[%$paramofs]
	mov [esi+spriteblock.orgparamptr],eax
	mov eax,[%$numparam]
	mov [esi+spriteblock.numparam],al
	mov [esi+spriteblock.orgnumparam],al

	mov [esi+spriteblock.flags],ah

	cmp dword [%$len],4
	jne .notttdpatchgrf

	sub edi,[%$len]		// edi-%$len = sprite data
	mov eax,[edi]		// = number of sprites

	cmp eax,0x7fff
	ja .notttdpatchgrf

	mov [%$numsprites],eax
	shl eax,2
	push eax
	add [totalmem],eax
	call malloc
	pop eax
	mov [%$spriteptr],eax
	mov [esi+spriteblock.spritelist],eax
	jc .outofmem

.notspritenum:
	mov esi,[%$curptr]
	mov al,[%$pseudo]
	add al,0x58	// set pseudo/real sprite code and a marker that this is actual sprite data
	mov [esi-6],al

	inc dword [%$sprite]
	jmp .nextsprite

.toomany:
	mov ax,ourtext(toomanysprites)
	jmp short .error

.notttdpatchgrf:
	mov ax,ourtext(notttdpatchgrf)
	jmp short .error

.outofmem:
	mov ax,ourtext(outofmemory)

.error:
	call setspriteerror

.done:
	mov ah,0x3e		// close file
	mov bx,[tempspritefilehandle]
	CALLINT21

	mov esi,[%$sprite]
	mov eax,[curspriteblock]
	mov [eax+spriteblock.numsprites],si

	cmp esi,1
	jl .fail

	add [totalnewsprites],esi

.fail:
	and dword [curgrffile],0
	_ret

endproc // readgrffile

#ifdef DEBUGSPRITESTORE
#include <win32.inc>
proc log_spritestore
	arg num,len,addr

	_enter

	mov dword [log_sprite.type],'Load'
	call log_sprite

	_ret
endproc

proc log_spriteread
	arg num,len,addr

	_enter

	mov dword [log_sprite.type],'Read'
	call log_sprite

	_ret

log_sprite:
	pusha
	inc dword [%$num]
	cmp dword [.hnd],0
	jne .gothnd

	extern hexdwords,hexwords

	push 0			// hTemplateFile
	push 128		// dwFlagsandAttributes = FILE_ATTRIBUTE_NORMAL
	push 2			// dwCreationDisposition = CREATE_ALWAYS
	push 0			// lpSecurityAttributes
	push 0			// dwShareMode
	push 0x40000000		// dwDesiredAccess = GENERIC_WRITE
	push .filename		// lpFilename
	call [CreateFile]
	cmp eax,byte -1
	je .fail

	mov [.hnd],eax

.gothnd:
	mov edx,[curgrffile]
	test edx,edx
	jle .nogrffile

	mov edi,edx
	mov al,0
	or ecx,byte -1
	repne scasb
	neg ecx
	dec ecx
	dec ecx

	push 0
	push .written
	push ecx
	push edx
	push dword [.hnd]
	call [WriteFile]

.nogrffile:
	lea esi,[%$addr]
	mov ebx,1
	mov edi,.addr
	call hexdwords
	sub edi,byte (.addr+10)-.size
	inc ebx
	call hexwords
	sub edi,byte (.size+10)-.sprite
	inc ebx
	call hexwords

	push 0
	push .written
	push byte .end-.text
	push .text
	push dword [.hnd]
	call [WriteFile]

.fail:
	popa
	_ret 0

noglobal varb .filename, "spriteio.log",0
noglobal uvard .hnd
noglobal uvard .written

noglobal varb .text
	db ": "
.type:	db "####ing sprite "
.sprite:db		  "#### size "
.size:	db 			    "#### at "
.addr:	db				    "########",13,10
.end:
endvar
endproc
#endif

makespriteblock:
	push byte spriteblock_size
	add dword [totalmem],byte spriteblock_size
	call calloc
	pop esi
	jc .outofmem

	push eax
	mov eax,esi
	xchg eax,[curspriteblock]
	test eax,eax
	jle .noprev

	mov [eax+spriteblock.next],esi

.noprev:
	or eax,byte -1
	mov [esi+spriteblock.grfid],eax
	mov [esi+spriteblock.cursprite],ax
	mov [esi+spriteblock.spritelist],eax
	mov [esi+spriteblock.paramptr],eax
	mov dword [esi+spriteblock.cargotransptr],defcargotrans
	pop eax

.outofmem:
	ret

// set/record a sprite error message
//
// in:	eax(0:15)=error text
//	eax(16:31)=error parameter (currently only used by "invalid sprite" message)
//	ebx->error parameter (for grfbefore/grfafter message)
//	edi->first byte in sprite generating error
// out:	eax->spriteblock
//
global setspriteerror
setspriteerror:
	call settempspriteerror
	mov byte [eax+spriteblock.active],0x80
	ret

// same, but only aborts loading instead of marking it as bad
settempspriteerror:
	push edx
	mov edx,[curspriteblock]

	push eax
	shr eax,16
	mov ah,0
	mov [edx+spriteblock.errparam],ax
	or eax,byte -1
	cmp di,[edx+spriteblock.numsprites]
	ja .outofrange
	cmp edi,0x10000
	ja .outofrange
	mov eax,[edx+spriteblock.spritelist]
	mov eax,[eax+(edi-1)*4]
	sub eax,esi
	neg eax
.outofrange:
	mov [edx+spriteblock.errparam+2],ax
	pop eax

	cmp ax,ourtext(grfbefore)
	je .beforeafter
	cmp ax,ourtext(grfafter)
	jne .notbeforeafter

.beforeafter:
	mov [edx+spriteblock.errparam],ebx

.notbeforeafter:
	push ax
	cmp dword [spriteerror],0
	jne .alreadyhaveerror
	mov [operrormsg2],ax
	mov [spriteerror],edx
	mov byte [spriteerrortype],0
	mov eax,[edx+spriteblock.errparam]
	mov [spriteerrorparam],eax
.alreadyhaveerror:
	xchg eax,edx
	pop word [eax+spriteblock.errsprite]
	pop edx
	ret

#if !WINTTDX
global allocspritecache
allocspritecache:
	mov eax,0x400000	// start with 4 MB
	testflags lowmemory
	jnc .tryalloc
	mov eax,0xc8000		// or only 800 KB (TTD minimum) if lowmemory on

.tryalloc:
	push eax
	call malloccrit
	pop dword [spritecache]
	mov [spritecachesize],eax
	ret

global clearspritecacheblock
clearspritecacheblock:
	mov byte [es:esi+4],0
	mov esi,[spritecache]
	ret
#endif

global translatesprite
translatesprite:
	cmp bx,4890+6*WINTTDX
	jnb .notttdsprite

		// may sometimes be called with a different DS so use ss:
	mov bx,[ss: newttdsprites+ebx*2]

.notttdsprite:
	mov [ss: 0xffff+ebx*2],si
ovar storespritelastrequestnum,-4
	ret



// read and resolve all references in each sprite block
global resolvesprites
resolvesprites:
	pusha

	// process each block individually, so that it can
	// adjust its sprite numbers to the real sprite numbers
	mov eax,PROCALL_LOADED
	call procallsprites
	mov eax,PROCALL_INITIALIZE
	call procallsprites
	popa
	ret

	// no base graphics loaded, try adding file to the list or else complain
exported forceloadbasegrf
	pusha

	// see if we can open the file
	mov ax,0x3d40
	mov edx,basegrfname
	CALLINT21
	jc .notloaded

	// close it again
	mov bx,ax
	mov ah,0x3e
	CALLINT21

	xor eax,eax
	mov edx,basegrfname
	xor edi,edi
	call readgrffile

	cmp esi,1
	jl .notloaded

	// need to to the LOADED and INITIALIZE stages for this file only
	mov edx,[curspriteblock]
	or byte [edx+spriteblock.flags],1<<4
	xchg edx,[spriteblockptr]
	push edx
	call resolvesprites
	pop esi
	xchg esi,[spriteblockptr]
	mov edx,esi

	test byte [grfmodflags+3],0x80
	jnz .done
	mov ax,ourtext(wronggrfversion)
	jmp short .notvalid

.notloaded:
	call makespriteblock
	mov ax,ourtext(filenotfound)
	or byte [esi+spriteblock.flags],1<<4
.notvalid:
	mov edx,esi
	and dword [spriteerror],0		// this error overrides all others
	mov dword [esi+spriteblock.filenameptr],basegrfname
	call setspriteerror

.done:
	// move to beginning of list
	mov eax,edx				// eax=edx=base grf
	mov ebx,[spriteblockptr]
	xchg eax,[ebx+spriteblock.next]		// now eax=original first link
	xchg eax,[edx+spriteblock.next]		// store as base grf's next, get original next
	mov ebx,edx
.next:						// then find end of chain
	cmp [ebx+spriteblock.next],edx
	je .found
	mov ebx,[ebx+spriteblock.next]
	test ebx,ebx
	jg .next
	ud2					// this can't happen
.found:
	mov [ebx+spriteblock.next],eax		// store base grf's original next at end of chain
	popa
	ret


// set all grf files to "will be (in)active
global setwillbeactive
setwillbeactive:
	mov eax,[spriteblockptr]
.next:
	or byte [eax+spriteblock.active],2
	jns .ok
	mov byte [eax+spriteblock.active],0x80
.ok:
	mov eax,[eax+spriteblock.next]
	test eax,eax
	jnz .next
	ret

uvard curgrffile	// for crash logger
uvard curgrfsprite

uvard curmiscgrf

uvard lastskip
uvard lastsprite

uvard spritehandlertable
uvard procallclear

uvarb procallsprites_noreset
uvarb procallsprites_replaygrm
uvard procall_type

global procallsprites
procallsprites:
	mov [procall_type],eax
	mov edx,[procall_clear+eax*4]
	mov [procallclear],edx
	mov eax,[procall_handlers+eax*4]
	mov [spritehandlertable],eax
	mov edx,[spriteblockptr]

	test edx,edx
	jle near .done

	mov edi,grfvarreinitalwaysstart
	mov ecx,numgrfvarreinitalways

	cmp byte [procallsprites_replaygrm],0
	jne .replay

	mov edi,grfvarreinitgrmstart
	mov ecx,numgrfvarreinitgrm

.replay:
	xor eax,eax
	rep stosd

.procblock:
	mov edi,grfvarclearstart
	xor eax,eax
	mov ecx,numgrfvarreinitzero
	rep stosd

	dec eax
	mov ecx,numgrfvarreinitsigned
	rep stosd

	mov esi,curextragrm
	mov edi,lastextragrm
	mov ecx,GRM_EXTRA_NUM
	rep movsd

	mov edi,[procallclear]
	test edi,edi
	jz .noclearproc

	call edi

.noclearproc:
	mov edi,[grfmodflags]
	push edi
	call procgrffile
	pop edi

	cmp byte [edx+spriteblock.active],0x80	// had other errors?
	je .nextblock

	xor edi,[grfmodflags]	// if bit 31 has changed, grf claims to
	jns .notbasegrf		// be our base grf, validate that

	call checkbasegrf

.notbasegrf:
	cmp dword [edx+spriteblock.grfid],0
	jne .nextblock

	mov eax,[spritehandlertable]
	cmp dword [eax+spritegrfidcheckofs],byte -1
	je .nextblock	// just scanning

	mov ax,ourtext(wronggrfversion)
	call setspriteerror

.nextblock:
	and dword [curgrffile],0

	mov edx,[edx+spriteblock.next]
	test edx,edx
	jnz .procblock

.done:
	mov byte [procallsprites_noreset],0
	mov byte [procallsprites_replaygrm],0
	ret
; endp procallsprites

extern PROCALL_HANDLERS
vard procall_handlers, PROCALL_HANDLERS
vard procall_clear, PROCALL_CLEAR

	// called before every infoapply, and once for each file
	// during initialization
exported resetgrm
	pusha

	extern clearstationgameids,clearhousedataids,lastextrahousedata
	extern disabledoldhouses,lasthousedataid,lastindustiledataid
	extern clearindustiledataids,lastextraindustiledata,industileoverrides

	call clearstationgameids	// clear station game ids; they'll get
					// the right value by infoapply
	testflags newhouses
	jnc .nonewhouses
	call clearhousedataids
	mov byte [lastextrahousedata],0
	xor eax,eax			// clear house overrides
	mov edi,houseoverrides
	lea ecx,[eax+110]
	rep stosb

	and dword [disabledoldhouses+0],0
	and dword [disabledoldhouses+4],0
	and dword [disabledoldhouses+8],0
	and dword [disabledoldhouses+12],0
.nonewhouses:

	call clearindustiledataids
	mov byte [lastextraindustiledata],0
	xor eax,eax			// clear industry tile overrides
	mov edi,industileoverrides
	lea ecx,[eax+0xAF]
	rep stosb

	cmp dword [procall_type],PROCALL_INITIALIZE
	ja .noidreset
	mov byte [lasthousedataid],0
	mov byte [lastindustiledataid],0
.noidreset:
	popa
	ret

extern grfmodflags
checkbasegrf:
	cmp dword [edx+spriteblock.grfid],byte -1
	jne .notvalid
	cmp byte [edx+spriteblock.numparam],4
	jb .notvalid
	mov edi,[edx+spriteblock.paramptr]
	cmp word [edi+4*4+2],BASEGRF_VERCODE
	jne .notvalid
	cmp word [edi+4*4],BASEGRF_VERNUM
	jae .done

.notvalid:
	and dword [spriteerror],0		// this error overrides all others
	mov ax,ourtext(wronggrfversion)
	call setspriteerror
	and byte [grfmodflags+3],~0x80		// clear bit, grf was not right
.done:
	ret


global procgrffile
procgrffile:
	xor edi,edi
	mov [curspriteblock],edx

	cmp byte [edx+spriteblock.active],0x80
	je near .blockdone

	cmp byte [procallsprites_noreset],0
	jne .noreset

	mov [edx+spriteblock.errsprite],di	// clear error if it's good again
	and byte [edx+spriteblock.flags],~2	// clear bit 1

.noreset:
	movzx ecx,word [edx+spriteblock.numsprites]
	jecxz .blockdone

	mov eax,[edx+spriteblock.spritelist]
	test eax,eax
	jle short .blockdone

	mov esi,[edx+spriteblock.filenameptr]
	mov [curgrffile],esi

.nextsprite:
	lea esi,[edi+1]
	mov [curgrfsprite],esi

	cmp di,[edx+spriteblock.numsprites]
	jnl short .blockdone		// "less" because numsprites can be -1

	mov word [edx+spriteblock.cursprite],di

	mov esi,[eax+edi*4]
	inc edi

	test esi,esi
	jle short .skipsprite		// signed or zero = bad value

.notinds:
	pusha

	call pseudospriteaction

	pop eax			// original EDI
	mov ecx,[esp+0x14]	// original ECX
	mov edx,[esp+0x10]	// original EDX

	lea ebx,[eax-1]
	mov [lastsprite],ebx

	sub edi,eax		// adjust by how many sprites have been skipped
	jz short .nottoomuch

	mov [lastskip],ebx

	jns .dontskiprestofgrf	// regular forward jump, if anything
	jc .nottoomuch		// was a backward jump to a label
				// jmp to end of sprites
.skiprestofgrf:
	lea edi,[ecx-1]

	test byte [edx+spriteblock.active],2	// did we skip action 8?
	jz short .dontskiprestofgrf

	// yes: mark it as inactive
	mov byte [edx+spriteblock.active],0

.dontskiprestofgrf:
	cmp ecx,edi
	jbe short .skiprestofgrf

.nottoomuch:
	sub [esp+0x14],edi
	add eax,edi
	push eax

	popa

.skipsprite:
	loop .nextsprite

.blockdone:
	ret


// do one pseudo-sprite action
// in:	eax=sprite action
//	esi=remaining pseudo-sprite data
pseudospriteaction:
	mov cl,INVSP_ISREAL
	cmp byte [esi-6],0x59	// are we trying to read a real sprite as a pseudo-sprite?
	jne .invalid

	xor eax,eax
	lodsb
	mov ecx,eax
	cmp eax,numspriteactions
	jb .goodaction

.badaction:
	mov cl,INVSP_BADACTION

.invalid:
	shrd eax,ecx,16		// set eax(16:23)=cl
	mov ax,ourtext(invalidsprite)
	call setspriteerror
	or edi,byte -1
	ret

.goodaction:
	mov ebx,[spritehandlertable]
	bt [ebx+spritegrfidcheckofs],eax	// do we need to check action 8?
	mov ebx,[ebx+eax*4]
	jc .action8ok

	cmp dword [edx+spriteblock.action8],0
	je .badaction
	cmp dword [edx+spriteblock.grfid],0
	je .badaction

.action8ok:
	test ebx,ebx
	jnle short .good

.done:
	ret

.good:
	lodsb

	extern docheckfeature
	bt [docheckfeature],ecx
	jnc .always	// non-vehicle specific actions are always carried out

	cmp eax,0x48
	mov cl,INVSP_BADFEATURE
	ja .invalid

	movzx ecx,byte [newgrfflags+eax]
	testflags ecx	// all others only if enabled
	jnc short .done

.always:
	imul ecx,eax,4
	jmp ebx



// find GRF ID and return sprite block
//
// in:	eax=GRF ID
// out:	ebx->corresponding sprite block
//	carry set and ebx=0 if GRF ID not found
// uses:
global findgrfid
findgrfid:
	mov ebx,[spriteblockptr]
	jmp short .checkit

.nextgrf:
	mov ebx,[ebx+spriteblock.next]

.checkit:
	test ebx,ebx
	jle .notfound

	cmp eax,[ebx+spriteblock.grfid]
	jne .nextgrf
	// carry is clear
	ret

.notfound:
	stc
	ret

// insert active action 1 or action 5 sprites into TTD's sprite number space
//
// in:	ecx=number of sprites
//	edx=>current sprite block
//	edi=number of first sprite following action 1 or 5 in this block
// out:	eax=real number of first sprite
//	edi adjusted properly
//
// sets spriteerror and returns edi=-1 on error
//

global insertactivespriteblockaction1
insertactivespriteblockaction1:
	test dword [miscmodsflags],MISCMODS_SMALLSPRITELIMIT
	jz .exsenabled
	jmp insertactivespriteblock
.exsenabled:
	movzx eax, byte [exscurfeature]	// get the feature ID, stored before

	push edi
	mov edi, eax

	movzx esi,byte [exsnumactspritesindex+edi]
	mov eax, [numactsprites+esi*4]
	add eax, ecx
	cmp eax, [exsfeaturemaxspritesperblock+edi*4]
	jnb short .toomany

#if 0
	bt [exsfeatureuseseparatesprites],edi
	jc .notbase

	// in case the next action D runs out of sprites, show this GRF file
	mov [lastgenericspritealloc],edx

.notbase:
#endif
	movzx edi,byte [exsnumactspritesindex+edi]
	xchg eax, [numactsprites+edi*4]
	pop edi

	push eax

// copied otherwise the stack goes fuzzy, see below
.replnextaction1:
	pusha
	mov esi,[edx+spriteblock.spritelist]
	mov esi,[esi+edi*4]
	mov edi,[esi-4]		// sprite size
	xchg eax,edi
	call overridesprite
	popa
	inc edi
	inc eax
	loop .replnextaction1

	movzx eax, byte [exscurfeature]
	mov [curextragrm+GRM_EXTRA_SPRITES*4+eax*4],edx

	pop eax
	jmp exsrealtofeaturespriteeax

.toomany:
	mov eax,edi
	add eax,GRM_EXTRA_SPRITES
	pop edi

	// fall through

// mark grf as having conflict with other file
//
// in:	al=GRM_EXTRA_* code
// out:	returns appropriately for grf handler
exported failwithgrfconflict
	cmp dword [procall_type],PROCALL_INITIALIZE
	jbe .badness
	call setgrfconflict
	jnz .haveit

	mov ax,ourtext(toomanyspritestotal)
	call settempspriteerror
.haveit:
	or edi,byte -1
	ret
.badness:
	ud2

// same as above, but to be called from an action 0 prop handler
exported failpropwithgrfconflict
	cmp dword [procall_type],PROCALL_INITIALIZE
	jbe .badness
	call setgrfconflict
	mov ax,ourtext(toomanysprites)
	jz .haveit
	mov ax,0
.haveit:
	stc
	ret
.badness:
	ud2

setgrfconflict:
	movzx eax,al
	mov esi,[lastextragrm+eax*4]
	mov edx,[curspriteblock]
	test esi,esi
	jnz .haveit

	// first grf using this resource
	// if this happens when starting a new game, conflict must be with itself
	// (make a fake sprite block whose .nameptr points to the given ourtext entries)
	mov esi,ourtext_ptr+(ourtext(conflict_itself)-ourtext(base))*4-spriteblock.nameptr

	cmp byte [activatetype],0
	je .haveit

	// otherwise it's most likely a conflict with pre-existing game data
	// (e.g. station IDs etc. that use the needed slots)
	mov esi,ourtext_ptr+(ourtext(conflict_preexist)-ourtext(base))*4-spriteblock.nameptr

.haveit:
	// show conflict with previous succesful action 1 grf
	or byte [edx+spriteblock.flags],2
	mov [edx+spriteblock.errparam],esi
	not eax
	mov [edx+spriteblock.errparam+4],ax
	mov ax,[curgrfsprite]
	mov [edx+spriteblock.errparam+6],ax
	test esp,esp
	ret

global insertactivespriteblock
insertactivespriteblock:
	mov eax,[numactsprites]
	add eax,ecx
	cmp ah,0x40
	jb .nottoomany

	mov al,GRM_EXTRA_SPRITES
	jmp failwithgrfconflict

.nottoomany:
	mov [curextragrm+GRM_EXTRA_SPRITES*4],edx
	xchg eax,[numactsprites]

	push eax

.replnext:		// copied to insertactivespriteblockaction1
	pusha
	mov esi,[edx+spriteblock.spritelist]
	mov esi,[esi+edi*4]
	mov edi,[esi-4]		// sprite size
	xchg eax,edi
	call overridesprite
	popa
	inc edi
	inc eax
	loop .replnext

	mov [curextragrm+GRM_EXTRA_SPRITES*4],edx
	pop eax
	ret


// load sprite header
// TTD normally respects the "immutable" flag, which fixes the sprite cache
// position of a sprite. However, everytime a new game is started, it resets
// all sprites, even immutable ones.  We need to preserve those.
// Note: TTD doesn't ever set the immutable flag itself.
//
// Don't load header if returning with carry set.
//
// in:	ax=sprite X size from file
//	esi=sprite number
// out:	set spritexsize[esi*2] to ax if appropriate
// safe:-
global loadspriteheader
loadspriteheader:
	push edx
	imul edx,[newspritenum],19
	add edx,[newspritedata]
	cmp byte [edx+esi],1		// is the immutable flag set?
	cmc
	jc .done

	imul edx,[newspritenum],6
	add edx,[newspritedata]
	mov [edx+esi*2],ax

.done:
	pop edx
	ret


// overridesprite: replace a TTD sprite with a new sprite
//
// in:	eax=sprite data size including header
//	edi=sprite number
//	esi=>sprite data
// out: esi=>after sprite data
// uses:all
//
// NOTE!! If you use overrideembeddedsprite, make sure the corresponding
//	patch flag is added to the patchsetspritecache line in patches.ah
//
// overrideembeddedsprite: same, but size and number are stored at esi:
//	W spritenum
//	W spritesize (as stored in TTD's cache)
//	B[spritesize] spritedata
// also:cx=minimum size, will be overwritten only if smaller. (or 0 for no check)

global overrideembeddedsprite,overridesprite
overrideembeddedsprite:
	xor eax,eax
	mov ch,0
	lodsw
	mov edi,eax
	lodsw
	stc
	jmp short overridesprite.do

overridesprite:
	clc
.do:
	mov ebx,[newspritedata]
	mov ebp,[newspritenum]

	jnc .overwrite

	cmp cx, 0
	je .overwrite
	lea edx,[ebx+ebp*4]
	cmp [edx+edi*2],cx	// sprite size
	jb .overwrite		// too small = not present, overwrite it

	add esi,eax		// don't overwrite, just skip it
	ret

.overwrite:
	cmp dword [ebx+edi*4],0	// is it currently in the cache?
	je .notincache

	imul ecx,ebp,19
	add ecx,edi
	cmp byte [ebx+ecx],0	// was it immutable (i.e. one of ours)?
	jne .notincache

#if !WINTTDX
		// load the right selector in case we have no new graphics
	push es
	mov es,[spritecacheselector]
#endif
	push esi
	mov ecx,edi
	call [removespritefromcache]
	pop esi
#if !WINTTDX
	pop es
#endif

.notincache:
	mov [ebx+edi*4],esi	// set cache offset

	call setspriteinfo

	imul ebp,7
	add ebx,ebp
	mov byte [ebx+edi],1	// set immutable

	add esi,ecx
	ret

// reload sprite info of sprite that had override
//
// in:	edi=sprite number
//
global reloadspriteheaders
reloadspriteheaders:
	mov ebx,[newspritedata]
	mov ebp,[newspritenum]

	imul ecx,ebp,18
	add ecx,ebx
	movzx edx,byte [ecx+edi]

	mov esi,[curfileofsptr]
	sub esi,8
	push esi

	mov ax,[esi-8+edx*2]
	mov [tempspritefilehandle], ax

	mov byte [curdecoderuntype],0
	mov word [curfileblocksize],0

	push ebx
	imul ecx,ebp,14
	add ecx,ebx
	mov edx,[ecx+edi*4]
	sub edx,2
	mov ecx,edx
	shr ecx,10h
	mov ax,4200h
	mov bx,[tempspritefilehandle]
	CALLINT21

	call dword [readwordfn]
	pop ebx
	lea ecx,[ebx+ebp*4]
	mov [ecx+edi*2],ax
	push eax

	mov ax,8
	call dword [readspriteinfofn]

	pop eax
	pop esi

setspriteinfo:
	lea ebx,[ebx+ebp*4]

	mov [ebx+edi*2],ax	// set data size
	lea ebx,[ebx+ebp*2]
	lea ecx,[eax-8]		// data size minus header

#ifdef DEBUGSPRITESTORE
	movzx eax,ax
	push edi
	push eax
	push esi
	call log_spriteread
#endif

	test ecx,ecx
	js .pseudo

	xor eax,eax
	lodsb			// skip sprite type (compression code)
	lodsb
	mov edx,eax
	lodsw
	mov [ebx+edi*2],ax	// set x size
	lea ebx,[ebx+ebp*2]

	mov [ebx+edi*2],dx	// set y size
	lea ebx,[ebx+ebp*2]

	lodsw
	mov [ebx+edi*2],ax	// set x offset
	lea ebx,[ebx+ebp*2]

	lodsw
	mov [ebx+edi*2],ax	// set y offset
.pseudo:
	ret


	// make a list of grf IDs, or add new IDs to the existing list
	//
	// make sure all sprite blocks have .active set correctly; it will
	// be copied into the list for any new IDs if dh=1 or to the
	// default if dh=0
global makegrfidlist
makegrfidlist:
	pusha

	xor ebx,ebx
	lea ecx,[ebx+5]
	xchg ebx,[grfidlistnum]
	call makegrfidlistsize		// make sure the pointer is valid
	jc .done

	mov esi,[spriteblockptr]

.nextblock:
	mov eax,[esi+spriteblock.grfid]
	test eax,eax
	jz .gotit	// skip null IDs

	cmp eax,byte -1
	je .gotit	// and GRFIDs of -1

	mov edi,[grfidlist]

	mov ecx,ebx
	jecxz .notfound

.next:
	scasd
	je .gotit

	scasb	// skip "activated" byte
	loop .next

	// ID was not found; add it to the list
.notfound:
	lea ecx,[ebx*5+5]
	call makegrfidlistsize
	jc .done

	lea edi,[ebx*5]		// need to calculate again in case makegrfidlistsize
	add edi,[grfidlist]	// moved it because it was too small
	stosd
	mov al,[esi+spriteblock.active]
	test dh,1
	jnz .notdefault
	mov al,[esi+spriteblock.flags]
	not al
	and al,[activatedefault]
.notdefault:
	stosb
	inc ebx

.gotit:
	mov esi,[esi+spriteblock.next]
	test esi,esi
	jnz .nextblock

	mov [grfidlistnum],ebx

.done:
	popa
	ret

uvard grfidlistsize	// size in bytes of memory allocated to the list
uvard grfidlist		// pointer to the list
uvard grfidlistnum	// number of entries in the list (5 bytes each)
uvarb activatedefault	// whether to activate by default or not
varb activatetype, 1	// 1=existing game, 0=new game


	// make sure the grfidlist has a minimum size (given by ecx)
global makegrfidlistsize
makegrfidlistsize:
	cmp [grfidlistsize],ecx
	jb .makelarger
	ret

.makelarger:
	pusha
	add ecx,1023
	and ecx,-1024	// allocate in chunks of 1024 bytes

	push ecx
	call malloc
	pop edi
	jc .done	// out of memory

	mov esi,edi

	xchg ecx,[grfidlistsize]
	xchg esi,[grfidlist]

	rep movsb

.done:
	popa
	ret


	// go through all sprite blocks and choose which
	// ones to activate from the list in the grf ID list
	// also update the active byte in the list
global setactivegrfs
setactivegrfs:
	pusha

	mov ebx,[grfidlistnum]
	mov esi,[spriteblockptr]

.nextblock:
	mov eax,[esi+spriteblock.grfid]
	cmp byte [esi+spriteblock.active],0x80
	je .skipblock

	test eax,eax
	jz .notfound

	cmp eax,byte -1
	je .alwaysactive

	mov edi,[grfidlist]

	mov ecx,ebx
	jecxz .notfound

.next:
	scasd
	je .gotit

	scasb	// skip "activated" byte
	loop .next

.notfound:
	// ID was not found; use default
	mov al,[esi+spriteblock.flags]
	not al
	and al,[activatedefault]
	jmp short .gotactive

.alwaysactive:
	// ID is a special ID that is always active
	mov al,1
	jmp short .gotactive

.gotit:
	mov al,[edi]
	cmp al,2
	jb .gotactive

	mov al,[esi+spriteblock.flags]
	not al
	and al,[activatedefault]
	mov [edi],al

.gotactive:
	add al,2
	mov [esi+spriteblock.active],al

.skipblock:
	mov esi,[esi+spriteblock.next]
	test esi,esi
	jnz .nextblock

// update .active in town name part lists
// we can't depend on default activation because we need the town name list
// to have correct activation information on the title screen, where no
// new GRFs are activated. On the title screen, assume every correct
// GRFs with "off by default" bit clear active; during the game, use
// actual activation information.
	mov esi,[spriteblockptr]
.nextspriteblock:
	xor al,al
	cmp byte [gamemode],0
	jz .titlescreen

	cmp byte [esi+spriteblock.active],3
	jne .setit
	inc al
	jmp short .setit

.titlescreen:
	cmp byte [esi+spriteblock.active],0x80
	je .setit
	test byte [esi+spriteblock.flags],1
	jnz .setit
	inc al

.setit:
// now al is the new activation state - apply it to all items with current GRFID
	mov ebx,[esi+spriteblock.grfid]
	mov edi,[firsttownnamestyle]

.nextstyle:
	or edi,edi
	jz .stylesfinished
	cmp ebx,[edi+namepartlist.grfid]
	jnz .skipstyle
	mov [edi+namepartlist.active],al
.skipstyle:
	mov edi,[edi+namepartlist.nextstyle]
	jmp short .nextstyle

.stylesfinished:
	mov esi,[esi+spriteblock.next]
	or esi,esi
	jnz .nextspriteblock
	
	popa

	ret


	// set one GRFID to be active or inactive
	// in:	eax=GRFID (-1 for all)
	//	dl=00 deactivate
	//	dl=01 activate
	//	dl=02 set to default
	//	dl=FF flip active/inactive
	// out:	dh=1 if GRFID was found in list
	//	dh=0 if GRFID was not found
	// uses:ecx edi
global setgrfidact
setgrfidact:
	mov dh,1
	call makegrfidlist	// make sure all new .grfs are in the list

	mov edi,[grfidlist]
	mov ecx,[grfidlistnum]
	mov dh,0

.nextblock:
	cmp eax,byte -1
	je .allgrf

	cmp [edi],eax
	jne .skipblock

.allgrf:
	mov dh,1

	test dl,dl
	js .flip
	mov [edi+4],dl
	jmp short .skipblock

.flip:
	xor byte [edi+4],1

.skipblock:
	add edi,5
	loop .nextblock
	ret


	// handle setting misc grf texts (textids d000+x)
	//
	// in:	edi=textID&7ff
	// out:	eax->string table
	//	edi=index into table
	//	carry set if eax has to be added to value in table
global getmiscgrftable
getmiscgrftable:
	test edi,0x400
	jz .setstr

	and edi,0x3ff
	mov eax,[curmiscgrf]
	test eax,eax
	jz .failed

	mov eax,[eax+spriteblock.miscstr]
	test eax,eax
	jnz .notfailed

.failed:
	jmp getnotable

.notfailed:
	cmp edi,[eax-4]
	jae .failed

	clc
	ret

.setstr:
	push esi
	mov eax,[curspriteblock]
	mov esi,[eax+spriteblock.miscstr]
	test esi,esi
	jz .neednew

	cmp edi,[esi-4]
	jb .gottable

.neednew:
	push edi
	add edi,33	// +1 because the list is zero-based
			// +1 for the length
			// +31 to round up
	and edi,byte ~31
	push edi
	shl edi,2
	push edi
	call malloccrit
	pop edi
	pop dword [edi]	// store size
	dec dword [edi] // the stored size shouldn't include the size field
	add edi,4
	mov [eax+spriteblock.miscstr],edi

	test esi,esi
	jz .nocopy

	push ecx
	mov ecx,[esi-4]
	rep movsd
	pop ecx

.nocopy:
	mov esi,[eax+spriteblock.miscstr]
	pop edi

.gottable:
	mov eax,esi
	clc
	pop esi
	ret


// replacement table for TTD sprites
// contents for each original sprite:
//	   0..131A = new TTD sprite
//	2000..7FFF = new TTDPatch sprite
//	8000+x	   = call runindexbase+4*x with eax=old sprite; should return
//			ebx=new sprite (possible values 0..131A or 2000..7FFF)
uvarw newttdsprites, totalsprites

uvard setcharwidthtablefn,1,s	// TTD function to set character width table based on the sprite data
				// has to be called again if characters are changed via the new .GRF files
