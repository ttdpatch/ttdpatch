// TTDSound.cpp : Defines the entry point for the DLL application.
//
//  Created by Steven Hoefel (stevenhoefel@hotmail.com)
//  The DirectSound code was stolen from some website and heavily manipulated.
//

#include <stdio.h>
#include <stdarg.h>
#include <windows.h>
#include <windowsx.h>
#include <dsound.h>
#include <mmsystem.h>
#include <errno.h>

#define TTDSOUND_EXPORTS
#include "patchsnd.h"

BOOL APIENTRY DllMain( HANDLE hModule,DWORD ul_reason_for_call,LPVOID lpReserved)
{
	switch (ul_reason_for_call) {
		case DLL_PROCESS_ATTACH:
		case DLL_THREAD_ATTACH:
		case DLL_THREAD_DETACH:
		case DLL_PROCESS_DETACH:
			break;
	}
	return TRUE;
}

//initialise the sound-layer
TTDSOUND_API DWORD SoundInit(HWND mainWindow, int dontKnow)
{
	ALIGN_ESP

	//really not much to do here... we want to grab the HWND
	//so we can spit messages boxen (now writing to log file!)
	local = mainWindow;

	RESTORE_ESP

	return 0;
}

TTDSOUND_API DWORD InitializeBankFile(char* bankFilePath)
{
	ALIGN_ESP

	// need to call another function, or else the
	// stack cleanup would get too complicated
	// what with all the "return" statements etc.

	DWORD ret = LoadSamples(bankFilePath);

	RESTORE_ESP

	return ret;
}

DWORD LoadSamples(char* bankFilePath)
{
	int ret;

	ClearLogFile();

	WriteLogData(
		"Starting\n"
		"------------------------------=========--------------------------------\n"
		"Starting MPSSND_C.DLL/PATCHSND.DLL (Initially created by Steven Hoefel)\n"
		"           [email or msn me @ stevenhoefel@hotmail.com]\n"
		"    MANY THANKS to Josef and the Team at TTDPATCH for help on this!\n"
		"------------------------------=========--------------------------------\n\n\n"
		);
	//now comes fun.
	//----------Start DSOUND
	ret = DirectSoundCreate(NULL, &lpDirectSound, NULL);
	if (DS_OK != ret) {
		lpDirectSound = NULL;
		WriteLogData("Creating the initial DirectSound object failed: %x\n", ret);
		return 1;
	}
	ret = lpDirectSound->SetCooperativeLevel(local, DSSCL_NORMAL);
	if (DS_OK != ret) {
		WriteLogData("Setting the cooperative level on the DirectSound object failed: %x\n", ret);
		return 1;
	}
	//----------------------


	//------------------------------------LOAD SAMPLE.CAT
	FILE * pFile;
	pFile = fopen (bankFilePath, "rb");
	if (pFile==NULL) {
		WriteLogData("Could not read %s: %s\n", bankFilePath, strerror(errno));
		return 1;
	}

	bool success = true;
	int numSounds = 0;
	long currentPos=0;
	char desc[64];
	char strlength;
	LPVOID dataStart;


	while (success==true) {
		//first read one byte:
		//it has to be a dword
		DWORD offset, length;

		fread (&offset,sizeof(DWORD),1,pFile);
		fread (&length,sizeof(DWORD),1,pFile);

		if (((int)offset) > 9999999)
			success = false;
		else {
			//grab the current pos, we're in the MAIN HEADER where the offsets are listed.
			currentPos = ftell(pFile);
			//now we want to bolt off to the location that we just read in.
			fseek(pFile,offset,SEEK_SET);
			//the first byte is the length of the desc
			fread (&strlength,1,1,pFile);
			//read the desc
			fread (&desc,1,strlength,pFile);
			//allocate data for the wave
			dataStart = malloc(length);
			//read it in.
			fread (dataStart,length,1,pFile);

			//we don't need to 'parse' wave data for the PlayCustomSample Routine.
			//play clapping and 'ooooooohing' at the start of the game.
			//if (numSounds==30) PlayCustomSample(dataStart,-100,128,11025);
			//if (numSounds==29) PlayCustomSample(dataStart,319,128,11025);
			//if (numSounds==33) PlayCustomSample(dataStart,319,128,11025);

			if (numSounds == 33) {
				//ladies and gents... when FiSHUK or whoever they are compiled the sample.cat.. they broke it!
				//here is a hack to get the construction sound working again....

				//lets use the last files header... we don't really care about it. (the frequency is correct)
				WaveFile[numSounds].pwfxInfo = WaveFile[numSounds - 1].pwfxInfo;
				//we have a chunk of raw wave data, no header, so use the location we have
				WaveFile[numSounds].pbData = (LPBYTE) dataStart;
				//the length is the whole chunk, so go from start to end
				WaveFile[numSounds].cbSize = length;

				WaveFile[numSounds].isLoaded = true;
				//tada! we're back!!
				WriteLogData(
					"Loaded & fixed [%d]\tOffset: %ld,\tLength: %ld,\tDescription: %s at %p\n"
					,numSounds,offset,length,desc, &WaveFile[numSounds]);
			} else {
				//try parse the new chunk of memory we have written.
				if (!wave_ParseWaveMemory(dataStart,
						&WaveFile[numSounds])) {
					//failed, write big log message.
					WriteLogData(
						"FAILED LOADING FILE! "
						"[[%d] Offset: %ld,Length: %ld,Description: %s]\n"
						,numSounds,offset,length,desc);
					WaveFile[numSounds].isLoaded = false;
				} else {
					//success... write little log message.
					strcpy(WaveFile[numSounds].desc,desc);
					WriteLogData(
						"Loaded [%d]\tOffset: %ld,\tLength: %ld,\tDescription: %s at %p\n"
						,numSounds,offset,length,desc, &WaveFile[numSounds]);
					WaveFile[numSounds].isLoaded = true;
				}
			}
			// insert in list so we can release it later
			WaveFile[numSounds].next = WaveFileList;
			WaveFileList = &WaveFile[numSounds];
			WaveFile[numSounds].Buffers.lpDSBSingle=NULL;
			WaveFile[numSounds].Buffers.next=NULL;

			//seek back to the start of the file where the offsets are
			fseek(pFile,currentPos,SEEK_SET);
			numSounds++;
		}

	}
	//clean up... write logs.
	totalSounds = numSounds;
	WriteLogData(
		"\n"
		"--------------------------------\n"
		"Successfully loaded %d sounds\n"
		"--------------------------------\n"
		"Starting to Play sounds:\n"
		"--------------------------------\n"
		,totalSounds);
	//---------------------------------------------------

	fclose(pFile);

	return 0;
}

TTDSOUND_API void StartFx(int sampleNo, int volume, int panning, int frequency)
{
	ALIGN_ESP

#ifdef LOGPLAY
	WriteLogData(
		"Playing TTD sound sample %d [Address: %p,Panning: %d, Volume: %d, Hz: %d]; Size: %ld, Format: %p\n"
		,sampleNo,&WaveFile[sampleNo],panning,volume,frequency,WaveFile[sampleNo].cbSize,WaveFile[sampleNo].pwfxInfo);
#endif

	// play a standard TTD sound.
	// is it loaded??
	if (WaveFile[sampleNo].isLoaded) {
		PlayWaveFile(&WaveFile[sampleNo], volume, panning, frequency, sampleNo);
		numttdsamples++;
	} else
		WriteLogData("Attempted to play non-loaded sample %d!\n",sampleNo);

	RESTORE_ESP
}

TTDSOUND_API void SoundShutDown(void)
{
	ALIGN_ESP

	//stop all playback.
	ClearAllBuffers();

	RESTORE_ESP
}

TTDSOUND_API void ReleaseBankFile(void)
{
	ALIGN_ESP

	//stop and kill all buffers
	ClearAllBuffers();

	//kill DSOUND reference
	if (lpDirectSound != NULL) {
		lpDirectSound->Release();
		lpDirectSound = NULL;
	}

	WriteLogData(
		"Shutting down. Played %d TTD samples and %d custom samples.\n"
		,numttdsamples,numcustomsamples);
	CloseLogFile();

	RESTORE_ESP
}

TTDSOUND_API LPWAVEFILE PrepareCustomSample(LPVOID sample, char *filename)
{
	ALIGN_ESP

	LPWAVEFILE lpWaveFile = (LPWAVEFILE) malloc(sizeof(WAVEFILE));

#ifdef LOGPLAY
	WriteLogData(
			"PrepareCustomSample(Address: %p, Filename: %s) called, using lpWaveFile = %p\n"
			,sample, filename, lpWaveFile);
#endif

	if (lpWaveFile) {
		lpWaveFile->Buffers.next = NULL;
		lpWaveFile->Buffers.lpDSBSingle = NULL;

		if (!wave_ParseWaveMemory(sample, lpWaveFile)) {
			WriteLogData(
				"FAILED PREPARING FILE! [Address: %p]\n"
				,sample);
			free(lpWaveFile);
			lpWaveFile = NULL;
		} else {
			lpWaveFile->isLoaded = true;
			lpWaveFile->next = WaveFileList;
			WaveFileList = lpWaveFile;
		}
	}

	RESTORE_ESP

	return lpWaveFile;
}

TTDSOUND_API void PlayCustomSample(LPWAVEFILE file, int panning, int volume,
				int frequency, char *filename)
{
	ALIGN_ESP

#ifdef LOGPLAY
	WriteLogData(
		"Playing custom sound sample %s [Address: %p,Panning: %d, Volume: %d, Hz: %d]; Size: %ld, Format: %p\n"
		,filename,file,panning,volume,frequency,file->cbSize,file->pwfxInfo);
#endif

	if (file->isLoaded) {
		PlayWaveFile(file, volume, panning, frequency, -1);
		numcustomsamples++;
	} else
		WriteLogData("Attempted to play non-loaded custom sample %p!\n", file);

	RESTORE_ESP
}

void PlayBuffer(LPDIRECTSOUNDBUFFER lpDSBSingle, int volume, int panning, int frequency)
{
	if (!lpDSBSingle)
		return;

	//set the specific properties for the buffer/sound.
	panning = (panning-160)*10;
	if (panning<-10000) panning = -10000;
	if (panning>10000) panning = 10000;
	volume = 2400*(volume-128)/128; // (volume-128) * 60;

	lpDSBSingle->SetPan(panning);
	lpDSBSingle->SetVolume(volume);
	if (frequency != 0) lpDSBSingle->SetFrequency(frequency);
	lpDSBSingle->SetCurrentPosition(0);
	//play it.
	lpDSBSingle->Play(0,0,0);
}

void PlayWaveFile(LPWAVEFILE file, int volume, int panning, int frequency,
		int sampleNo)
{
	int ret;
	LPDIRECTSOUNDBUFFER lpDSBSingle = NULL;
	LPBUFFERINFO info;

	if (!lpDirectSound)
		return;

	// find existing buffer that's done playing
	for (info = file->Buffers.next; info; info = info->next) {
		DWORD status;
		info->lpDSBSingle->GetStatus(&status);
		if (!(status & DSBSTATUS_PLAYING)) {
			lpDSBSingle = info->lpDSBSingle;
#if defined(LOGPLAY) && LOGPLAY>1
			WriteLogData("Using existing buffer %p for sample %p\n",lpDSBSingle, file);
#endif
			break;
		}
	}

	// if none exist, make a new one
	if (!lpDSBSingle) {
		// if we have a buffer, make a duplicate of it, else make a new one
		if (file->Buffers.next) {
			ret = lpDirectSound->DuplicateSoundBuffer(file->Buffers.next->lpDSBSingle, &lpDSBSingle);
			if (ret != DS_OK) {
				WriteLogData(
					"FAILED Duplicating sound buffer %p for %p: %x"
					,file->Buffers.next->lpDSBSingle,file,ret);
				return;
			}
#if defined(LOGPLAY) && LOGPLAY>1
			WriteLogData("Duplicated buffer %p for sample %p as %p\n",
				file->Buffers.next->lpDSBSingle,file,lpDSBSingle);
#endif
		} else {
			lpDSBSingle = CreateBuffer(file, volume, panning, frequency);
			if (!lpDSBSingle)
				return;
		}

		info = (LPBUFFERINFO) malloc(sizeof(BUFFERINFO));
		info->next = file->Buffers.next;
		file->Buffers.next = info;
		info->lpDSBSingle = lpDSBSingle;
	}

	PlayBuffer(lpDSBSingle,volume,panning,frequency);
}

LPDIRECTSOUNDBUFFER CreateBuffer(LPWAVEFILE file, int volume, int panning, int frequency)
{
	int ret;
	VOID *pbData;
	DWORD dwLength;
	DSBUFFERDESC dsbdSingle;
	LPDIRECTSOUNDBUFFER lpDSBSingle;

	if (!lpDirectSound)
		return NULL;

	//we need to create the struct to hold the required sound data
	memset(&dsbdSingle, 0, sizeof(DSBUFFERDESC));
	dsbdSingle.dwSize		= sizeof(DSBUFFERDESC);
	dsbdSingle.dwFlags		= DSBCAPS_CTRLDEFAULT | DSBCAPS_STATIC;
	dsbdSingle.dwBufferBytes	= file->cbSize;
	dsbdSingle.lpwfxFormat		= file->pwfxInfo;	// Must be a PCM format!

	//now we rebuild the buffer to hold the sound data
	ret = lpDirectSound->CreateSoundBuffer(&dsbdSingle,&lpDSBSingle,NULL);
	if (DS_OK != ret) {
		WriteLogData(
			"FAILED Creating sound buffer: %x "
			"[Sample: %p, Panning: %d, Volume: %d, Hz: %d]\n"
			,ret,file,panning,volume,frequency);
		return NULL;
	}

#if defined(LOGPLAY) && LOGPLAY>1
	WriteLogData("Created buffer %p for sample %p\n",lpDSBSingle,file);
#endif

	//now we lock the buffer and fill it.
	ret = lpDSBSingle->Lock(0,file->cbSize,&pbData,&dwLength,NULL,NULL,0);	// Flags
	if (DS_OK == ret) {
		memcpy(pbData, file->pbData, dwLength);			// Copy first chunk
		ret = lpDSBSingle->Unlock(pbData, dwLength, NULL, 0);
		if (DS_OK != ret) {
			WriteLogData(
				"Obtaining Unlock failed on playback: %x "
				"[Sample: %p,Panning: %d, Volume: %d, Hz: %d]\n"
				,ret,file,panning,volume,frequency);	// Unlock the buffer
			return NULL;
		}
	} else {
		WriteLogData(
				"Obtaining Lock failed on playback: %x "
				"[Sample: %p,Panning: %d, Volume: %d, Hz: %d]\n"
				,ret,file,panning,volume,frequency);
		return NULL;
	}

	return lpDSBSingle;
}

void ClearAllBuffers()
{
	for (LPWAVEFILE file = WaveFileList; file; file = file->next)
		ClearBuffers(file);
}

void ClearBuffers(LPWAVEFILE file)
{
	LPBUFFERINFO info, prev;

	prev = &file->Buffers;
	for (info = prev->next; info; prev = info, info = info->next) {
#if defined(LOGPLAY) && LOGPLAY>1
		WriteLogData("Clearing buffer %p for sample %p\n",info->lpDSBSingle, file);
#endif

		info->lpDSBSingle->Stop();
		info->lpDSBSingle->Release();

		// remove info from chain
		prev->next = info->next;
		free(info);
		info = prev;
	}
}

BOOL wave_ParseWaveMemory (LPVOID lpChunkOfMemory, LPWAVEFILE lpWaveFile)
{
	//---------------------------------------------------------------------------
	//this code was borrowed from the DirectExPerience...
	//and i've lost the URL
	//
	//...here it is: http://www.geocities.com/SiliconValley/Way/3390/mnoise.html
	//®1998 Adam Perer. All rights reserved [mailto:perer@lm.com]
	//---------------------------------------------------------------------------

    LPDWORD pdw,pdwEnd;
    DWORD   dwRiff,dwType,dwLength;

    if (!lpWaveFile)
	return FALSE;

    // Set defaults to NULL or zero
    lpWaveFile->pwfxInfo = NULL;
    lpWaveFile->pbData = NULL;
    lpWaveFile->cbSize = 0;

    // Set up DWORD pointers to the start of the chunk of memory.
    pdw = (DWORD *)lpChunkOfMemory;

    // Get the type and length of the chunk of memory
    dwRiff = *pdw++;
    dwLength = *pdw++;
    dwType = *pdw++;

    // Using the mmioFOURCC macro (part of Windows SDK), ensure that this is a RIFF WAVE chunk of memory
    if (dwRiff != mmioFOURCC('R', 'I', 'F', 'F')) return FALSE;      // not even RIFF
    if (dwType != mmioFOURCC('W', 'A', 'V', 'E')) return FALSE;      // not a WAV

    // Find the pointer to the end of the chunk of memory
    pdwEnd = (DWORD *)((BYTE *)pdw + dwLength-4);

    // Run through the bytes looking for the tags
    while (pdw < pdwEnd) {
	dwType   = *pdw++;
	dwLength = *pdw++;
	switch (dwType) {

		case mmioFOURCC('f', 'm', 't', ' '):

			// Found the format part
			if (dwLength < sizeof(WAVEFORMAT))
				return FALSE; // something's wrong! Not a WAV

			// Set the lplpWaveHeader to point to this part of the memory chunk
			lpWaveFile->pwfxInfo = (LPWAVEFORMATEX)pdw;

			// Check to see if the other two items have been filled out yet (the bits and the size of the
			// bits). If so, then this chunk of memory has been parsed out and we can exit
			if (lpWaveFile->pbData && lpWaveFile->cbSize)
				return TRUE;

			break;

		case mmioFOURCC('d', 'a', 't', 'a'):

			// Found the samples
			// Point the samples pointer to this part of the chunk of memory.
			lpWaveFile->pbData = (LPBYTE)pdw;

			// Set the size of the wave
			lpWaveFile->cbSize = dwLength;

			// Make sure we have our header pointer set up. If we do, we can exit
			if (lpWaveFile->pwfxInfo)
				return TRUE;

			break;
	} // End case

	pdw = (DWORD *)((BYTE *)pdw + ((dwLength+1)&~1)); // Move the pointer through the chunk of memory
    }

    // Failed! If we made it here, we did not get all the peices of the wave
    return FALSE;
}

static FILE *logFile = NULL;
void ClearLogFile()
{
	CloseLogFile();
	logFile = fopen ("patchsnd.log" , "wt");
	if (logFile) {
		fclose(logFile);
		logFile = NULL;
	}
}

static int showedbox = 0;
void WriteLogData(char *logData, ...)
{
	va_list args;

	va_start(args, logData);
	if (!logFile)
		logFile = fopen ("patchsnd.log" , "at");
	if (logFile) {
		fprintf(logFile, "%7d.%03d ", GetTickCount()/1000, GetTickCount()%1000);
		vfprintf(logFile, logData, args);
		fflush(logFile);
	} else {
		if (!showedbox)
			MessageBox(local, strerror(errno), "Can't append patchsnd.log", MB_OK);
		showedbox = 1;
	}
	va_end(args);
}

void CloseLogFile()
{
	if (logFile) {
		fclose(logFile);
		logFile = NULL;
	}
}
