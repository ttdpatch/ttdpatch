#include <windows.h>
 
__declspec(dllexport) BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fwReason, LPVOID lpvReserved)
{
	return TRUE;
}

LPSTR dxmcierror = NULL;
DWORD Volume = 0;

__declspec(dllexport) MMRESULT dxMidiGetVolume(HMIDIOUT hmo, LPDWORD pdwVolume)
{
	*pdwVolume = Volume;
	return 0;
}

__declspec(dllexport) MMRESULT dxMidiSetVolume(HMIDIOUT hmo, DWORD dwVolume)
{
	Volume = dwVolume;
	return 0;
}

#define STAT_SEEKING 0
#define STAT_PLAYING 1
#define STAT_STOPPED 2
char *status[] = { "seeking", "playing", "stopped" };

int playing = 0;
int seeking = 0;

__declspec(dllexport) MCIERROR dxMidiSendString(LPCTSTR lpstrCommand, LPTSTR lpstrReturnString, UINT uReturnLength, HWND hwndCallback)
{
	char command, *pos;

	command = lpstrCommand[0];

	// check only first character, it's unique
	switch(command) {
		case 'o':	// "open <fullpath> type sequencer alias MUSIC"
			break;
		case 'p':	// "play MUSIC from 0"
			playing = 1;
			seeking = 1;
			break;
		case 's':	// "status MUSIC mode"
			strcpy(lpstrReturnString, status
				[
				  !playing ?		STAT_STOPPED :
				  seeking ?		STAT_SEEKING :
							STAT_PLAYING
				] );

			if (playing && seeking)
				seeking = 0;
			break;
		case 'c':	// "close all"
			playing = seeking = 0;
			break;
	}

	return 0;
}

__declspec(dllexport) char **dxGetdxmcierrPtr(void)
{
	return &dxmcierror;
}

