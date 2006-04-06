// No-Registry stuff
#if WINTTDX

#include <defs.inc>
#include <var.inc>
#include <win32.inc>
#include <frag_def.inc>

varb aPatchDll, "ttdpatch.dll", 0
varb afake_RegOpenKeyA, "fake_RegOpenKeyA@12", 0
varb afake_RegQueryValueExA, "fake_RegQueryValueExA@24", 0
varb afake_RegCloseKey, "fake_RegCloseKey@4", 0

uvard HndPatchDll

exported getpatchdll
	mov eax,[HndPatchDll]
	test eax,eax
	jnz .done

#if 0
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
#endif
	push dword aPatchDll
	call [LoadLibraryA]
	mov [HndPatchDll],eax
	test eax,eax
.done:
	ret

global initnoregist
initnoregist:
	CALLINT3
	call getpatchdll
	jz .bad
	push afake_RegOpenKeyA
	push eax
	call [GetProcAddress]
	test eax,eax
	jz .bad

	push eax	// fake_RegOpenKeyA

	push afake_RegQueryValueExA
	push dword [HndPatchDll]
	call [GetProcAddress]
	pop ebx		// fake_RegOpenKeyA
	test eax,eax
	jz .bad

	push ebx	// fake_RegOpenKeyA
	push eax	// fake_RegQueryValueExA

	push afake_RegCloseKey
	push dword [HndPatchDll]
	call [GetProcAddress]
	pop ecx		// fake_RegQueryValueExA
	pop ebx		// fake_RegOpenKeyA
	test eax,eax	// fake_RegCloseKey
	jz .bad

	mov [RegOpenKeyA],ebx
	mov [RegQueryValueExA],ecx
#if 0
	storerelative do_RegCloseKey.ofs,eax
	mov dword [RegCloseKey],do_RegCloseKey
#else
	mov [RegCloseKey],eax
#endif
.bad:
	ret

badregcall:
	ud2

#if 0
	// unload ttdpatch.exe when TTD closes the registry
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

#endif
