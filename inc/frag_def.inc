//
// Fragment definition and search macros
//


// macros to define the code fragments
%macro begincodefragments 0.nolist
	%assign fragmentendvalue 0
%endmacro

%macro endcodefragments 0.nolist
	%if fragmentendvalue <> 0
		fragmentend:
		fragmentlen equ fragmentend-fragmentstart
		fragmentadj equ fragmentstart-fragmentend
		%if fragmentlen > 255
			%error Fragment length > 255 not supported
		%endif
	%endif
%endmacro

%macro codefragment 1-3.nolist // params: name[,addedi,addediw]
	endcodefragments

	%define curfragment %1
	%define fragmentstart %1_start
	%define fragmentend %1_end
	%define fragmentlen %1_len
	%define fragmentadj %1_adj
//	%assign %1_ispadded 0

	// correct position is different by addedi or addediw
	// remember this value for later use
#if WINTTDX
	%ifnidn {},{%3}
		%define addedi %3
	%elifnidn {},{%2}
#else
	%ifnidn {},{%2}
#endif
		%define addedi %2
	%else
		%define addedi 0
	%endif

	%1_add equ addedi
	%undef addedi

	%assign fragmentendvalue 1

	fragmentstart:
%endmacro

// don't use this one directly...
%macro mk_cj_codefragment 4.nolist
	%ifdef %1_isglobal
		%error "call/jmp fragment cannot be global"
	%endif
	%if %3<5
		%error "size must be a minimum of 5"
	%endif
	%define %1_cj_type %4
	%define %1_target %2
	%assign %1_len %3
	%assign %1_adj -%3
	extern %2
%endmacro

// use these instead

// store a call to procname and pad to size
%macro codefragment_call 2-3.nolist 6	// params: fragname,procname [,size]
	mk_cj_codefragment %1,%2,%3,0xe8	// E8 = call rel32
%endmacro

// store a jmp to procname and pad to size
%macro codefragment_jmp 2-3.nolist 6	// params: fragname,procname [,size]
	mk_cj_codefragment %1,%2,%3,0xe9	// E9 = jmp rel32
%endmacro

// check if fragment is available in the right size
%macro testsize 2.nolist	; params: name, size
	%ifnum %1_ispadded
		%ifnnum %1_size_%2
			%define testsize_bad_fragment %1
			%define testsize_bad_size %2
			%error "Fragment not available in right size!"
			%error "  (testsize_bad_fragment, size testsize_bad_size)"
		%endif
	%endif
%endmacro


// reuses an existing code fragment, making it possible to give it a different adjustment and/or size
%macro reusecodefragment 2-6.nolist ; params: name,oldname[,addedi,size,addediw,sizew]

	endcodefragments

	%ifdef %2_isextern
		%error "Old fragment must not be external"
	%endif
	%ifdef %2_cj_type
		%error "Old fragment must not be call/jmp fragment"
	%endif

	%define fragmentstart %1_start
	%define fragmentend %1_end
	%define fragmentlen %1_len
	%define fragmentadj %1_adj

	%define oldfragmentstart %2_start
	%define oldfragmentend %2_end

#if WINTTDX
	%ifnidn {},{%5}
		%assign addedi %5
	%elifnidn {},{%3}
#else
	%ifnidn {},{%3}
#endif
		%assign addedi %3
	%else
%ifndef PREPROCESSONLY
		%assign addedi %2_add
%endif
	%endif

#if WINTTDX
	%ifnidn {},{%6}
		%assign newsize %6
	%elifnidn {},{%4}
#else
	%ifnidn {},{%4}
#endif
		%assign newsize %4
	%else
%ifndef PREPROCESSONLY
		%assign newsize %2_end - %2_start
%else
		%define newsize (%2_end - %2_start)
%endif
	%endif

	%1_add equ addedi

%ifndef PREPROCESSONLY
	%if newsize > %2_end - %2_start
		%error "Reused fragment larger than original!"
	%endif
	testsize %2,newsize
%endif

	fragmentstart equ oldfragmentstart
	fragmentend equ oldfragmentstart + newsize
	fragmentlen equ fragmentend - fragmentstart
	fragmentadj equ fragmentstart - fragmentend

	%undef addedi
	%undef newsize

	begincodefragments
%endmacro

// use codefragment of an extern patchproc
%macro ext_frag 1-*.nolist
	%rep %0
		extern %1_start,%1_len,%1_add,%1_adj
		%define %1_isextern
		%rotate 1
	%endrep
%endmacro

// then it needs to be defined with glob_frag there
%macro glob_frag 1-*.nolist
	%rep %0
		global %1_start,%1_len,%1_add,%1_adj
		%define %1_isglobal
		%rotate 1
	%endrep
%endmacro

// sets the size of a fragment, and jumps to the end if necessary
// dojump indicates that a jump is *possible*, but it may be better to NOP
%macro getfraglen 1.nolist	// param: size
	%assign curfraglen $ - fragmentstart
	%assign fillbytes %1-curfraglen
%endmacro

%macro rememberpad 2.nolist
	%ifnnum %1_ispadded
		%define %1_ispadded 1
	%endif
	%ifnnum %1_size_%2
		%define %1_size_%2 1
	%endif
%endmacro

%macro setfragmentsize 1-2.nolist 0 // params: size [,dojump]
	%assign wantfraglen %1

%ifndef PREPROCESSONLY
	getfraglen wantfraglen
	%if %2 & 1
		%if fillbytes > 14
			jmp short %%jumptohere	// jump only if >14 NOP (with smartpad.mac)
			getfraglen wantfraglen	// adjust size for the jmp
		%endif
	%endif

	%if fillbytes < 0
		%error "Fragment curfragment is too long already! Is curfraglen want wantfraglen"
	%else
		pad fillbytes
		rememberpad curfragment,wantfraglen
	%endif
%%jumptohere:
	%undef wantfraglen
%endif

%endmacro

// determine the address where a call/jump has to go to run the specified function
// this is a naughty preprocessor hack to make call runindex(bla) into call_indirect bla
// so we don't have to change all 500 uses...
%define runindex(index) %+ _indirect index

// old way of defining indirect call/jmp uses these through the runindex() call
%define jmp_indirect use_indirect jmp,
%define call_indirect use_indirect call,

// the new, improved way uses these directly (i for indirect)
%define ijmp use_indirect jmp,
%define icall use_indirect call,
%define iparam_call use_indirect_arg param_call,

// append entries to the end of the list
%macro def_indirect 1.nolist
	%ifndef %1_isindirect
		%define %1_isindirect
		[section .indrct]
		%1_indirect: dd %1
		__SECT__
	%endif
%endmacro

%macro use_indirect 2.nolist
	extern %2
	def_indirect %2
	%1 [%2_indirect]
%endmacro

%macro use_indirect_arg 3+.nolist
	extern %2
	def_indirect %2
	%1 [%2_indirect],%3
%endmacro

%ifndef param_call
// call a procedure with parameters on the stack
%macro param_call 1-*.nolist	// params: target, params...
	%define target %1
	%rotate 1
	%rep %0-1
		push %1
		%rotate 1
	%endrep
	call target
	%undef target
%endmacro
%endif

#ifndef RELEASE
#ifndef __no_extern__
extern lastsearchfragmentname
#endif
[warning -]	// disable "unterminated string" warning due to the lone quote below
%macro usesearchfragment 1
	%define quote "
	noglobal varb %%_stringaddress_%1_name, quote %1 quote,0
	mov dword [lastsearchfragmentname], %%_stringaddress_%1_name
%endmacro
[warning +]
%macro donesearchfragment 0
	and dword [lastsearchfragmentname], 0
%endmacro
#else
%macro usesearchfragment 1.nolist
%endmacro
%define donesearchfragment ;
#endif


// this macro finds the address of a code fragment
// see the function dofindstring for details
%macro stringaddress 1-3 1,1	// params: fragment,occurence,maxcount

	%define _size %1_len
	%define _add %1_add
	%ifndef PREPROCESSONLY
		%ifndef %1_isextern
			%xdefine _size byte %1_len
			%xdefine _add byte %1_add
		%endif
	%endif

	usesearchfragment %1

	%%_stringaddress_%1_:
	param_call calldofindstring, %1_start, _size, %2, %3, _add

	donesearchfragment

	%undef _size
	%undef _add

	%define lastediadj 0

%endmacro

// stores a fragment at edi
%macro storefragment 1.nolist	// param: fragment

	%%_storefragment_%1_:
	%ifdef %1_cj_type
		param_call store_cj_fragment,%1_target+(%1_cj_type<<24),%1_len
	%else
	// then write the new code to it
	mov esi,%1_start

	%define lastfraglen %1_len
	%ifdef %1_isextern
		mov ecx,lastfraglen
	%elif lastfraglen < 0xff
		mov cl,lastfraglen	// assumes ecx=0 before
	%else
		mov ecx,lastfraglen
	%endif
	%undef lastfraglen

	rep movsb
	%endif

	%define lastediadj %1_adj
%endmacro

#ifndef __no_extern__
extern dopatchcode,calldofindstring,store_cj_fragment
#endif

// this is a macro to patch an element of code
// preserves: EBX,EBP
// sets ECX=0, ESI->oldcode-lastediadj, EDI->newcode-lastediadj
%macro patchcode 4.nolist	// params: oldcode,newcode,occurence,maxcount
	%%patchcode_%1_%2_:
	%define callpatchcode param_call dopatchcode
	%ifdef %2_cj_type
		%define %%addr2 %2_target+(%2_cj_type<<24)
	%else
		%define %%addr2 %2_start
	%endif

	usesearchfragment %1

%ifdef %1_isextern
	callpatchcode, %1_start, %%addr2, %1_len, %3, %4, %1_add, %2_len
%elifdef %2_isextern
	callpatchcode, %1_start, %%addr2, 0+%1_len, %3, %4, 0+%1_add, %2_len
%else
	callpatchcode, %1_start, %%addr2, 0+%1_len, %3, %4, 0+%1_add, 0+%2_len
%endif

	donesearchfragment

	%define lastediadj %2_adj
	%undef callpatchcode
%endmacro

// simplest version of the above, expands to patchcode old<code>,new<code>,1,1
%macro patchcode 1.nolist	// params: code (with fragments named old<code> and new<code>
	patchcode old%1,new%1,1,1
%endmacro

// other versions
%macro patchcode 2.nolist	// params: oldcode,newcode
	patchcode %1,%2,1,1
%endmacro
%macro patchcode 3.nolist	// params: code,occurence,maxcount
	patchcode old%1,new%1,%2,%3
%endmacro



// also a version that takes extra parameters
// beforepatch, if specified, must be one command;
// if you need more, define them as a macro and pass its name
// (ECX,EDX,EDI must *not* be modified; EBX,EBP retain values they had on entry)
// patchcondition is useful if the patch should be applied conditionally:
// beforepatch sets flags, and then the patch is applied if patchcondition is true
// (the string search must be always performed)
%macro patchcode 5-7 // params: oldcode,newcode,occurence,maxcount,extraadjustment [,beforepatch,patchcondition]

	%%patchcode_%1_%2_:
	// first find the address
	stringaddress %1,%3,%4

	%ifnidn {},{%5}
		%if %5 > 0
			add edi,0+(%5)
		%endif
		%if %5 < 0
			sub edi,0-(%5)
		%endif
	%endif

	%6
	%ifnidn {},{%7}
		j%-7 %%patchcodedontwrite
	%endif

	// then write the new code
	storefragment %2
%%patchcodedontwrite:
%endmacro

// patch multiple code occurences
// afterpatch and beforepatch, if specified, must be one command each;
// if you need more, define them as a macro and pass its name
%macro multipatchcode 3-6 // params: oldcode,newcode,count [,afterpatch,beforepatch,patchcondition]
	%%multipatchcode_%1_%2_:
	%if %3
		%if %3 <= 0xFF
			xor eax,eax
			mov al,%3
		%else
			mov eax,%3
		%endif
	%else
		%error "Patch count is zero"
	%endif
	mov ecx,eax

%%patchloop:
	push ecx

	%ifidn {%2},{}
		stringaddress %1,1,eax
	%elif %0 <= 4
		patchcode %1,%2,1,eax		// on the first search the number of occurences is checked
	%else
		patchcode %1,%2,1,eax,,{%5},%6
	%endif
	%define ediadj lastediadj

	%4

%ifndef %1_isextern
	%if %1_add<0
		add edi,byte -%1_add	// make sure we find the next occurence, not this one again
	%endif
%else
	mov eax,%1_add
	test eax,eax
	jge %%notneg
	sub edi,eax
%%notneg:
%endif

	%undef ediadj
	pop ecx
	xor eax,eax		// continue searches
	loop %%patchloop
%endmacro

%macro multipatchcode 2	// params: code,count
	multipatchcode old%1,new%1,%2
%endmacro

// finds and stores an address in the variable.
%macro storeaddress 4-5 0 // params: fragment,occurence,maxcount,variable [,adjustment]

	// find the address
	stringaddress %1,%2,%3

	%if %5 > 0
		add edi,byte %5
	%endif
	%if %5 < 0
		sub edi,byte -%5
	%endif

	mov [%4],edi
%endmacro

// same as above but assuming occurence=maxcount=1
%macro storeaddress 2
	storeaddress %1,1,1,%2
%endmacro

// searches find<var>, stores in [var]
%macro storeaddress 1
	storeaddress find%1,1,1,%1
%endmacro

// find and store an address pointed to by the code at the fragment
%macro storeaddresspointer 4-6 0,0 // params: fragment,occurence,maxcount,variable [,adjustment,[offset]]

	// find the address
	stringaddress %1,%2,%3

	mov eax,[edi+%6]	// find the address it''s pointing to

	%if %5 > 0
		add eax,byte %5
	%endif
	%if %5 < 0
		sub eax,byte -%5
	%endif

	mov [%4],eax
%endmacro

%macro storeaddresspointer 2	// params: fragment,variable
	storeaddresspointer %1,1,1,%2
%endmacro

%macro storeaddresspointer 1	// params: variable (fragment is find<variable>)
	storeaddresspointer find%1,1,1,%1
%endmacro

// find and store an address pointed to by the pointer at the fragment offset
%macro storeaddresspointerpointer 4-6 0,0 // params: fragment,occurence,maxcount,variable [,adjustment,adjustment2]

	// find the address
	stringaddress %1,%2,%3

	mov eax,[edi]		// find the address it's pointing to

	// now find the address *that* value is pointing to
	mov eax,[eax+%5]

	%if %6 > 0
		add eax,byte %6
	%endif
	%if %6 < 0
		sub eax,byte -%6
	%endif

	mov [%4],eax
%endmacro

%macro storeaddresspointerpointer 2	// params: fragment,variable
	storeaddresspointerpointer %1,1,1,%2
%endmacro

%macro storeaddresspointerpointer 1	// params: variable
	storeaddresspointerpointer find%1,1,1,%1
%endmacro

// store the target of a function call or jump located at edi
%macro storefunctiontarget 2-3 0 // params: relofs,variable [,isshort]
	%if %3
		movsx eax,byte [edi+%1]
		%define instrsize 1
	%else
		mov eax,[edi+%1]
		%define instrsize 4
	%endif
	lea eax,[edi+eax+instrsize+%1]
	%undef instrsize

	mov [%2],eax
%endmacro

// store a relative jmp/call.  This is useful if you have a near jump or call, like this:
// 	jmp near something	or	call something
//	jmpdest = $-4
// then storerelative jmpdest,newtarget will store the displacement to newtarget in jmpdest
//
// target is the location where to store the relative address
// newdest is the destination address
%macro storerelative 2-3 eax // params: target,newdest[,reg]
		// figure out relative jump distance
	;lea %3,[%2-(%1+4)]
	lea %3,[%2-4]
	sub %3,%1
	mov [%1],%3
%endmacro

// same as above, but copy from a destination in the TTD code
// relofs is relative to edi where the source is
// isbyte can be 1 to say that the source is byte sized, not dword sized
%macro copyrelative 1-3 0,0 // params: target [,relofs,isbyte]
	%if %3
		movsx eax,byte [edi+%2]
		%define instrsize 1
	%else
		mov eax,[edi+%2]
		%define instrsize 4
	%endif
	storerelative %1,eax+edi+%2+instrsize
	%undef instrsize
%endmacro

// like storerelative, but target is in TTD code
%macro changereltarget 2-3 edi	// params: targetofs,newdest [,targetreg]
	%ifidni %3,eax
		%error "EAX not allowed as targetreg"
	%endif

	mov eax,%2-(%1+4)
	sub eax,%3
	mov [%3+%1],eax
%endmacro




// find and store the target of a function call. Search has to find the first
// byte of the relative address in a call statement
%macro storefunctionaddress 4	// params: fragment,occurence,maxcount,variable

	// find the address
	stringaddress %1,%2,%3
	storefunctiontarget 0,%4
%endmacro

%macro storefunctionaddress 2	// params: fragment,variable
	storefunctionaddress %1,1,1,%2
%endmacro
%macro storefunctionaddress 1	// params: variable (fragment is find<variable>)
	storefunctionaddress find%1,1,1,%1
%endmacro

// store a call to our function (not an indirect entry) at edi+offset (overwrite 5 bytes)
// note: a better way may be using a codefragment_call and storefragment, especiall
//	 if you need to pad the fragment
%macro storefunctioncall 1-2 0	// param: label [,offset]
	mov byte [edi+%2],0xe8		// CALL imm
	changereltarget 1+%2,%1
%endmacro

// same as above but store a jump instead of call
%macro storefunctionjump 1-3 0,edi	// param: label [,offset [, offset reg]]
	mov byte [%3+%2],0xe9		// JMP near
	changereltarget 1+%2,%1,%3
%endmacro

// have our function called before or after the original code
// typically used with code like this:
//	newcode:
//	; ... our new code to execute before the original call ...
//		call dummy
//	ovar newcode_oldfn,-4
//	; or
//	ovar .oldfn,-4,$,newcode
//	; ... our new code to execute after the original call ...
//	ret
// then chainfunction newcode,.oldfn will make a call at edi point to newcode
// and make the dummy call point to the original function
// this also works with near jumps instead of calls
//
// relofs is relative to edi where the original offset is
// global is nonzero if orgoffvar is a global label,
// otherwise it's a local label (associated with newcode)
%macro chainfunction 1-4 .oldfn,0,0	// params: newfn,orgoffvar [,relofs,global]
	%if %4
		%define %%target %2
	%else
		%define %%target %1 %+ %2
	%endif
	copyrelative %%target,%3
	changereltarget %3,%1
%endmacro


// change the value loaded into a register
%macro changeloadedvalue 5-6 0 // params: fragment,occurence,maxcount,size,newvalue [,ofs]

	// find the address
	stringaddress %1,%2,%3

	%ifidni %4,b
		%define reg al
	%elifidni %4,w
		%define reg ax
	%elifidni %4,d
		%define reg eax
	%else
		%define invsize %4
		%error "Invalid size: invsize"
	%endif

	mov reg,[%5+%6]
	mov [edi],reg

	%undef reg
%endmacro

// same here, but for multiple occurences of the same fragment
%macro multichangeloadedvalue 4 // params: fragment,count,size,newvalue
	%if %2
		%if %2 <= 0xFF
			xor eax,eax
			mov al,%2
		%else
			mov eax,%2
		%endif
	%else
		%error "Patch count is zero"
	%endif
	mov ecx,eax

%%patchloop:
	push ecx

	changeloadedvalue %1,1,eax,%3,%4	// on the first search, the number of occurences is checked

	pop ecx
	xor eax,eax		// continue searches
	loop %%patchloop
%endmacro

