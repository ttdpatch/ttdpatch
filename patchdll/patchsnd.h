
// The following ifdef block is the standard way of creating macros which make exporting 
// from a DLL simpler. All files within this DLL are compiled with the TTDSOUND_EXPORTS
// symbol defined on the command line. this symbol should not be defined on any project
// that uses this DLL. This way any other project whose source files include this file see 
// TTDSOUND_API functions as being imported from a DLL, wheras this DLL sees symbols
// defined with this macro as being exported.

#define WIN32_LEAN_AND_MEAN


#ifdef TTDSOUND_EXPORTS
#define TTDSOUND_API __declspec(dllexport)
#else
#define TTDSOUND_API __declspec(dllimport)
#endif

#define TTD_TRUE 0
#define MAX_SOUNDS 128

// only defined for DX<7.0, so define it ourselves for later versions
#ifndef DSBCAPS_CTRLDEFAULT
#define DSBCAPS_CTRLDEFAULT (DSBCAPS_CTRLFREQUENCY | DSBCAPS_CTRLPAN | DSBCAPS_CTRLVOLUME)
#endif


typedef struct tagBUFFERINFO
{
	LPDIRECTSOUNDBUFFER	lpDSBSingle;
	struct tagBUFFERINFO	*next;
} BUFFERINFO, *LPBUFFERINFO;

typedef struct tagWAVEFILE
{
	DWORD		cbSize;			// Size of file
	LPWAVEFORMATEX	pwfxInfo;		// Wave Header
	LPBYTE		pbData;			// Wave Bits
	char		desc[64];
	bool		isLoaded;
	struct tagWAVEFILE *next;
	BUFFERINFO	Buffers;
} WAVEFILE, *LPWAVEFILE;

extern "C" TTDSOUND_API DWORD InitializeBankFile(char* bankFilePath);
extern "C" TTDSOUND_API void ReleaseBankFile(void);
extern "C" TTDSOUND_API DWORD SoundInit(HWND mainWindow, int dontKnow);
extern "C" TTDSOUND_API void StartFx(int sampleNo, int volume, int panning, int frequency);
extern "C" TTDSOUND_API void SoundShutDown(void);
extern "C" TTDSOUND_API LPWAVEFILE PrepareCustomSample(LPVOID sample, char *filename);
extern "C" TTDSOUND_API void PlayCustomSample(LPWAVEFILE file, int panning, int volume, int frequency, char *filename);

HWND local;

LPDIRECTSOUND			lpDirectSound;
WAVEFILE			WaveFile[MAX_SOUNDS];
LPWAVEFILE			WaveFileList = NULL;

int				totalSounds;
int				numttdsamples;
int				numcustomsamples;

BUFFERINFO BufferHead = { NULL, NULL };


DWORD LoadSamples(char *bankFilePath);
void ClearAllBuffers();
void ClearBuffers(LPWAVEFILE file);
void PlayBuffer(LPDIRECTSOUNDBUFFER lpDSBSingle, int volume, int panning, int frequency);
LPDIRECTSOUNDBUFFER CreateBuffer(LPWAVEFILE file, int volume, int panning, int frequency);
void PlayWaveFile(LPWAVEFILE file, int volume, int panning, int frequency, int sampleNo);
BOOL wave_ParseWaveMemory (LPVOID lpChunkOfMemory, LPWAVEFILE lpWaveFile);

#ifdef __GNUC__
// enable compile time attribute argument checking of the format string
void WriteLogData(char *logData, ...) __attribute__ ((format (printf, 1, 2)));
#else
// non-gcc doesn't know the "format" attribute
void WriteLogData(char *logData, ...);
#endif

void ClearLogFile();
void CloseLogFile();

// for realigning the stack so system calls don't fail due to it
#define ALIGN_ESP	DWORD savedesp; \
			asm("movl %%esp,%0" : "=m" (savedesp) : : "%esp" ); \
			asm("andl $-4,%esp");
#define RESTORE_ESP	asm("movl %0,%%esp" : : "m" (savedesp) : "%esp" );
