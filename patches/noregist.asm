// No-Registry stuff
#if WINTTDX

#include <defs.inc>
#include <var.inc>
#include <win32.inc>
#include <frag_def.inc>

//varb aPatchExe, "ttdpatchw.exe", 0
varb afake_RegOpenKeyA, "fake_RegOpenKeyA@12", 0
varb afake_RegQueryValueExA, "fake_RegQueryValueExA@24", 0
varb afake_RegCloseKey, "fake_RegCloseKey@4", 0

uvard HndPatchExe

global initnoregist
initnoregist:
	call [GetCommandLine]
	// skip ovl filename and EXE:
.next:
	cmp byte [eax],0
	je .bad
	cmp dword [eax],"EXE:"
	je .gotit
	inc eax
	jmp .next

.bad:
	ret

.gotit:
	add eax,4
	push eax
	call [LoadLibraryA]
	mov [HndPatchExe],eax
	test eax,eax
	jz .bad

	push afake_RegOpenKeyA
	push eax
	call [GetProcAddress]
	test eax,eax
	jz .bad

	push eax	// fake_RegOpenKeyA

	push afake_RegQueryValueExA
	push dword [HndPatchExe]
	call [GetProcAddress]
	pop ebx		// fake_RegOpenKeyA
	test eax,eax
	jz .bad

	push ebx	// fake_RegOpenKeyA
	push eax	// fake_RegQueryValueExA

	push afake_RegCloseKey
	push dword [HndPatchExe]
	call [GetProcAddress]
	pop ecx		// fake_RegQueryValueExA
	pop ebx		// fake_RegOpenKeyA
	test eax,eax	// fake_RegCloseKey
	jz .bad

	mov [RegOpenKeyA],ebx
	mov [RegQueryValueExA],ecx
	storerelative do_RegCloseKey.ofs,eax
	mov dword [RegCloseKey],do_RegCloseKey
	ret

badregcall:
	ud2

	// unload ttdpatchw.exe when TTD closes the registry
do_RegCloseKey:
	push dword [esp+4]
	call $+0	// fake_RegCloseKey
.ofs equ $-4
	push eax

	push dword [HndPatchExe]
	call [FreeLibrary]

	mov eax,badregcall
	mov [RegOpenKeyA],eax
	mov [RegQueryValueExA],eax
	mov [RegCloseKey],eax

	pop eax
	ret 4
#endif
