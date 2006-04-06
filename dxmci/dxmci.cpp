/*
 * MCI to DirectMusic wrapper
 *
 * This file contains the DirectMusic calls.
 *
 */



#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif

// for gcc, the GUIDs are available in a library instead
#ifndef __GNUC__
#define INITGUID
#endif

#include <windows.h>
#include <stdio.h>

#define VARIANT int

#include <dmksctrl.h>
#include <dmusici.h>
#include <dmusicc.h>
#include <dmusicf.h>

#define MSGBOX(output)  MessageBox(NULL,output,"dxmci",MB_OK);

// check if a command is successful, and if not record the error message
// for later (it's not safe to call MessageBox in fullscreen mode)
#define FAILWITHMESSAGE(command,message) \
	if (FAILED(command)) { dxmcierror="dxmci: " message; return false; };

#define MULTI_TO_WIDE( x,y )  MultiByteToWideChar( CP_ACP,MB_PRECOMPOSED, y,-1,x,_MAX_PATH);

// the performance object controls manipulation of  the segments
IDirectMusicPerformance *performance = NULL;

// the segment object is where the MIDI data is stored for playback
IDirectMusicSegment *segment = NULL;

// the loader object can load many types of DMusic related files
IDirectMusicLoader *loader = NULL;

// the underlying DirectMusic object used by the performance
IDirectMusic* dmusic = NULL;

// and the DirectMusicPort object with its properties
IDirectMusicPort* port = NULL;
DMUS_PORTPARAMS portparams;
DMUS_PORTCAPS portcaps;

// whether we've initialized COM or not (when deciding whether to shut down)
int COMInitialized = 0;

// whether there was an error in the initialization, and what the message was
LPSTR dxmcierror = NULL;

// Initialize COM and DirectMusic
bool InitDirectMusic (void)
{
	GUID portGUID;

	int portnum;

	if (NULL != performance)
		return true;

	// Initialize COM
	if (!COMInitialized) {
		CoInitialize (NULL);
		COMInitialized = 1;
	}

	// Create the performance object via CoCreateInstance
	FAILWITHMESSAGE(CoCreateInstance(
			(REFCLSID)CLSID_DirectMusicPerformance,
			NULL,
			CLSCTX_INPROC,
			(REFIID)IID_IDirectMusicPerformance,
			(LPVOID *)&performance),
		"Failed to create the performance object");

	// Initialize it
	FAILWITHMESSAGE(performance->Init(&dmusic, NULL, NULL),
		"Failed to initialize performance object");

	// Initialize the port capabilities structure
	ZeroMemory(&portcaps,sizeof(DMUS_PORTCAPS));
	portcaps.dwSize = sizeof(DMUS_PORTCAPS);

	// Find the Midi Mapper port, otherwise use the default port
	dmusic->GetDefaultPort(&portGUID);
	for (portnum=0; dmusic->EnumPort(portnum, &portcaps) == S_OK; portnum++) {
		if ( (portcaps.dwClass == DMUS_PC_OUTPUTCLASS) &&
		     (portcaps.dwType == DMUS_PORT_WINMM_DRIVER) ) {

			// found a suitable port
			portGUID = portcaps.guidPort;
			break;
		}
	}

	// Initialize the port params structure
	ZeroMemory(&portparams,sizeof(DMUS_PORTPARAMS));

	// Sets the params for this port
	portparams.dwSize=sizeof(DMUS_PORTPARAMS);
	portparams.dwValidParams=DMUS_PORTPARAMS_CHANNELGROUPS;
	portparams.dwChannelGroups=1;
				
	// The midi port is created here 
	port = NULL;
	FAILWITHMESSAGE(dmusic->CreatePort(portGUID,&portparams,&port,NULL),
		"Failed to create port");
	
	// We have to activate it
	FAILWITHMESSAGE(port->Activate(TRUE),
		"Failed to activate port");

	// Add the port to the performance
	FAILWITHMESSAGE(performance->AddPort(port),
		"Failed to add port");

	// And if it was the default port, get its caps
	FAILWITHMESSAGE(port->GetCaps(&portcaps),
		"Failed to get port capabilities");

	// Assigns a block of 16 performance channels to the performance 
	FAILWITHMESSAGE(performance->AssignPChannelBlock(0,port,1),
		"Failed to assign PChannel block");

	// now we'll create the loader object. This will be used to load the
	// midi file for our demo. Again, we need to use CoCreateInstance
	// and pass the appropriate ID parameters
	FAILWITHMESSAGE(CoCreateInstance ((REFCLSID)CLSID_DirectMusicLoader,
			NULL, CLSCTX_INPROC, 
			(REFIID)IID_IDirectMusicLoader,
			(LPVOID *)&loader),
		"Failed to create loader object");

	// that's it for initialization. If we made it this far we
	// were successful.
	return true;
}

// Releases memory used by all of the initialized 
// DirectMusic objects in the program
void ReleaseSegment (void)
{
	if (NULL != segment) {
		segment->Release ();
		segment = NULL;
	}
}
void ShutdownDirectMusic (void)
{
	// release everything but the segment, which the performance 
	// will release automatically (and it'll crash if it's been 
	// released already)

	if (NULL != loader) {
		loader->Release ();
		loader = NULL;
	}

	if (NULL != performance)
	{
 		performance->CloseDown ();
		performance->Release ();
		performance = NULL;
	}

	if (COMInitialized) {
		CoUninitialize ();
		COMInitialized = 0;
	}
}

// Load MIDI file for playing 
bool LoadMIDI (char *directory, char *filename)
{
	DMUS_OBJECTDESC obj_desc;
	WCHAR w_directory[_MAX_PATH];	// utf-16 version of the directory name.
	WCHAR w_filename[_MAX_PATH];	// utf-16 version of the file name

	if (!performance || dxmcierror)
		return false;

	MULTI_TO_WIDE(w_directory,directory);

	FAILWITHMESSAGE(loader->SetSearchDirectory(
				(REFGUID) GUID_DirectMusicAllTypes,
				w_directory, FALSE),
		"LoadMIDI: SetSearchDirectory failed");

	// set up the loader object info
	ZeroMemory (&obj_desc, sizeof (obj_desc));
	obj_desc.dwSize = sizeof (obj_desc);

	MULTI_TO_WIDE(w_filename,filename);
	obj_desc.guidClass = CLSID_DirectMusicSegment;

	wcscpy (obj_desc.wszFileName,w_filename);
	obj_desc.dwValidData = DMUS_OBJ_CLASS | DMUS_OBJ_FILENAME;

	// release the existing segment if we have any
	if (NULL != segment)
		ReleaseSegment();

	// and make a new segment
	FAILWITHMESSAGE(loader->GetObject(&obj_desc, 
			(REFIID)IID_IDirectMusicSegment, 
			(LPVOID *) &segment),
		"LoadMIDI: Get object failed");

	// next we need to tell the segment what kind of data it contains. We do this
	// with the IDirectMusicSegment::SetParam function.
	FAILWITHMESSAGE(segment->SetParam((REFGUID)GUID_StandardMIDIFile,
			-1, 0, 0, (LPVOID)performance),
		"LoadMIDI: SetParam (MIDI file) failed");

	// finally, we need to tell the segment to 'download' the instruments
	FAILWITHMESSAGE(segment->SetParam((REFGUID)GUID_Download,
			-1, 0, 0, (LPVOID)performance),
		"LoadMIDI: Failed to download instruments");

	// at this point, the MIDI file is loaded and ready to play!
	return true;
}

// Start playing the MIDI file
int PlaySegment (void)
{
	if (!performance || dxmcierror)
		return false;

	FAILWITHMESSAGE(performance->PlaySegment(segment, 0, 0, NULL),
		"PlaySegment failed");

	return true;
}

// Stop playing
int StopSegment (void)
{
	if (!performance || !segment || dxmcierror)
		return false;

	FAILWITHMESSAGE(performance->Stop(segment, NULL, 0, 0),
		"StopSegment failed");

	return true;
}

// Find out whether playing has started or stopped
bool IsSegmentPlaying (void)
{
	if (!performance || !segment || dxmcierror)
		return FALSE;

	// IsPlaying return S_OK if the segment is currently playing
	return performance->IsPlaying(segment, NULL) == S_OK ? TRUE : FALSE;
}


#if defined(__GNUC__)
#define ALIGN_ESP   asm("movl %%esp,%0" : "=m" (savedesp) ); \
		    asm("andl $-4,%esp" );
#define RESTORE_ESP asm("movl %0,%%esp" : : "m" (savedesp) );
#else
#define ALIGN_ESP   _asm mov savedesp, esp; \
		    _asm and esp, not 3;
#define RESTORE_ESP _asm mov esp, savedesp;
#endif

#if defined(__cplusplus)
extern "C"
{
#endif


__declspec(dllexport) BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fwdReason, LPVOID lpvReserved)
{

	switch (fwdReason) {
	case DLL_PROCESS_ATTACH:
//		asm("int3");
//		//MSGBOX("Process Attach");
		break;
	case DLL_PROCESS_DETACH:
//		asm("int3");
		if (COMInitialized)
			ShutdownDirectMusic();
		//MSGBOX("Process Detach");
		break;
	}
	return TRUE;
}

__declspec(dllexport) MMRESULT dxMidiGetVolume(HMIDIOUT hmo, LPDWORD pdwVolume)
{
	DWORD savedesp;

	ALIGN_ESP

	if (dxmcierror)
		return 0;

	if (NULL == performance)
		InitDirectMusic();

	if (!(portcaps.dwFlags & DMUS_PC_SOFTWARESYNTH)) {
		// TTD only needs to know the volume to restore it when exiting
		// (for software synths it doesn't need to know)
		midiOutGetVolume(hmo, pdwVolume);
	}

	RESTORE_ESP

	return 0;
}

__declspec(dllexport) MMRESULT dxMidiSetVolume(HMIDIOUT hmo, DWORD dwVolume)
{
	DWORD savedesp;

	ALIGN_ESP

	if (dxmcierror)
		return 0;

	if (NULL == performance)
		InitDirectMusic();

	if (portcaps.dwFlags & DMUS_PC_SOFTWARESYNTH) {
		// map dwVolume from 0..0xffffffff to -5000..0
		dwVolume = (((dwVolume >> 16) * 5000) >> 16) - 5000;
		performance->SetGlobalParam(GUID_PerfMasterVolume, &dwVolume, sizeof(dwVolume));
	} else {
		// hardware synths don't support changing the master volume,
		// do it in the mixer instead
		midiOutSetVolume(hmo, dwVolume);
	}

	RESTORE_ESP

	return 0;
}

#define STAT_SEEKING 0
#define STAT_PLAYING 1
#define STAT_STOPPED 2
char *status[] = { "seeking", "playing", "stopped" };

bool seeking = 0;

__declspec(dllexport) MCIERROR dxMidiSendString(LPCTSTR lpstrCommand, LPTSTR lpstrReturnString, UINT uReturnLength, HWND hwndCallback)
{
	DWORD savedesp;
	char command, *pos;
	char dir[_MAX_PATH+1];
	char file[_MAX_PATH+1];

	if (dxmcierror)
		return 0;

	ALIGN_ESP

	command = lpstrCommand[0];
	if (NULL == performance) {
		// initialize DirectMusic, unless this is either
		// a "close all" or a "status" command.  Skip the "close all".
		if (command == 'c')
			command = 'i';	// for "ignore" :)
		else if (command != 's')
			InitDirectMusic();
	}

	// check only first character, it's unique
	switch(command) {
		case 'o':	// "open <fullpath> type sequencer alias MUSIC"

			// split full path into directory and file components
			strncpy(dir, lpstrCommand + 5, _MAX_PATH);
			pos = strrchr(dir, '\\') + 1;
			strncpy(file, pos, _MAX_PATH);
			strchr(file, ' ')[0] = 0;
			*pos = 0;
			LoadMIDI(dir, file);
			break;
		case 'p':	// "play MUSIC from 0"
			PlaySegment();
			seeking = 1;
			break;
		case 's':	// "status MUSIC mode"

			// if a segment has been defined, and it was "seeking",
			// check whether it's done seeking yet
			if (segment && seeking && IsSegmentPlaying())
				seeking = false;

			// then return the appropriate result
			strcpy(lpstrReturnString, status
				[
				  !segment ?		STAT_STOPPED :
				  seeking ?		STAT_SEEKING :
				  IsSegmentPlaying() ?	STAT_PLAYING :
							STAT_STOPPED
				] );
			break;
		case 'c':	// "close all"
			StopSegment ();
			break;
	}

	RESTORE_ESP

	return 0;
}

__declspec(dllexport) char **dxGetdxmcierrPtr(void)
{
	return &dxmcierror;
}


#if defined(__cplusplus)
}
#endif 
