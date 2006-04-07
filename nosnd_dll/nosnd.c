#include <windows.h>
 
__declspec(dllexport) BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fwReason, LPVOID lpvReserved)
{
	return TRUE;
}

__declspec(dllexport) void InitializeBankFile(void)
{
}

__declspec(dllexport) void ReleaseBankFile(void)
{
}

__declspec(dllexport) int SoundInit(HWND hwnd, int unk)
{
	return 0;	// success
}

__declspec(dllexport) void SoundShutDown(void)
{
}

__declspec(dllexport) void StartFx(int unk1, int unk2, int unk3)
{
}

__declspec(dllexport) void StopFx(int num)
{
}

