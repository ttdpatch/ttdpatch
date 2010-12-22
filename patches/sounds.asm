// Functions dealing with new (and old) sound effects

#include <std.inc>
#include <proc.inc>
#include <textdef.inc>
#include <grf.inc>
#include <bitvars.inc>

extern curspriteblock,mostrecentspriteblock,newsoundsettings

uvard soundoverrides, NUMOLDSOUNDS

// new ambient sounds
extern miscgrfvar,randomfn,gettileterrain
extern curcallback,grffeature,getnewsprite,generatesoundeffect
exported AmbientSound
	push eax
	call [randomfn]
	cmp eax,0x1470000
	ja .nosound

	pusha
	mov esi,ebx
	mov edi,ebx	// for later
	mov bl,al
	mov bh,[landscape4(si,1)]
	call gettileterrain
	movzx eax,al
	shl ebx,16
	or eax,ebx
	mov ah,[landscape5(si,1)]
	mov [miscgrfvar],eax

	mov word [curcallback],0x144
	mov eax,0x8000000C	// feature 0C (newsounds) generic
	mov [grffeature],al
	xor esi,esi
	call getnewsprite
	jc .failed

	dec esi		// was 0, now -1 = tile sound
	mov ebx,edi
	mov ecx,edi
	shl ebx,4
	shr ecx,4
	and bx,0xff0
	and cx,0xff0
	call [generatesoundeffect]

.failed:
	xor eax,eax
	mov [curcallback],eax
	mov [miscgrfvar],eax
	popa

.nosound:
	pop eax
	ret

uvard oldclass0periodicproc
uvard oldclass4periodicproc

extern grfmodflags
exported Class0PeriodicProc
	test byte [grfmodflags],0x10
	jz .nonewsounds

	call AmbientSound

.nonewsounds:
	jmp [oldclass0periodicproc]

exported Class4PeriodicProc
	test byte [grfmodflags],0x10
	jz .nonewsounds

	call AmbientSound

.nonewsounds:
	jmp [oldclass4periodicproc]


#if WINTTDX
PlayCustomSound_dummy:

	ret

PrepareCustomSound_dummy:
	or eax,byte -1
	ret

	align 4
vard PlayCustomSound, PlayCustomSound_dummy
vard PrepareCustomSound, PrepareCustomSound_dummy
#endif

global generatesound
generatesound:
	cmp eax,NUMOLDSOUNDS
	jae .oursound
	mov esi,[soundoverrides+4*eax]
	or esi,esi
	jnz .gotsoundinfo
	imul bx,dx	// overwritten
	shr ebx,7	// ditto
	ret

.nosound:
	add dword [esp],23
	ret

.oursound:
	sub eax,NUMOLDSOUNDS
	mov esi,[mostrecentspriteblock]
	cmp ax,[esi+spriteblock.numsounds]
	ja .nosound
	mov esi,[esi+spriteblock.soundinfo]
	imul eax,soundinfo_size
	add esi,eax
.gotsoundinfo:
	cmp dword [esi+soundinfo.dataptr],0
	je .nosound
	add dword [esp],23
	movzx ebx,byte [esi+soundinfo.ampl]
	imul bx,dx
	shr ebx,7
	imul ebx,dword [dword 0]
ovar .zoomvolume,-4,$,generatesound
	shr ebx,8

#if WINTTDX
	push eax
	mov eax,[esi+soundinfo.prepfile]
	cmp eax,byte -1
	je .invalid

	test eax,eax
	jnz .haveprep

	push dword [esi+soundinfo.filename]
	push dword [esi+soundinfo.dataptr]
	call [PrepareCustomSound]
	test eax,eax
	jnz .notbadprep
	or eax,byte -1
.notbadprep:
	mov [esi+soundinfo.prepfile],eax
	cmp eax,byte -1
	pop eax		// pop PrepareCustomSound argument
	pop eax
	je .invalid

.haveprep:
	push dword [esi+soundinfo.filename]
	push 0	// use frequency from .wav header
	push ebx
	shr ecx,1
	push ecx
	push dword [esi+soundinfo.prepfile]
	call [PlayCustomSound]
	add esp,5*4
.invalid:
	pop eax		// restore eax
#else
	push dword [esi+soundinfo.dataptr]
	push dword [esi+soundinfo.length]
	push ebx
	push ecx
	movzx eax,byte [esi+soundinfo.priority]
	push eax
	call playsound
#endif

	ret

	// in:	eax=special prop-num
	//	ebx=offset
	//	ecx=num-info
	//	edx->feature specific data offset
	//	esi=>data
	// out:	esi=>after data
	//	carry clear if successful
	//	carry set if error, then ax=error message
	// safe:eax ebx ecx edx edi

global setsoundvolume
setsoundvolume:
	sub ebx,NUMOLDSOUNDS
	jb .error
	mov edi,[curspriteblock]
	lea eax,[ebx+ecx]
	cmp ax,[edi+spriteblock.numsounds]
	ja .error

	imul ebx,byte soundinfo_size
	mov edi,[edi+spriteblock.soundinfo]
	add edi,ebx
.soundloop:
	lodsb
	mov [edi+soundinfo.ampl],al
	add edi,soundinfo_size
	loop .soundloop

	ret

.error:
	mov eax,(INVSP_BADID<<16)+ourtext(invalidsprite) 
	stc
	ret

global setsoundpriority
setsoundpriority:
	sub ebx,NUMOLDSOUNDS
	jb .error
	mov edi,[curspriteblock]
	lea eax,[ebx+ecx]
	cmp ax,[edi+spriteblock.numsounds]
	ja .error

	imul ebx,byte soundinfo_size
	mov edi,[edi+spriteblock.soundinfo]
	add edi,ebx
.soundloop:
	lodsb
	add al,'0'
	mov [edi+soundinfo.priority],al
	add edi,soundinfo_size
	loop .soundloop

	ret

.error:
	mov eax,(INVSP_BADID<<16)+ourtext(invalidsprite) 
	stc
	ret

global overrideoldsound
overrideoldsound:
	sub ebx,NUMOLDSOUNDS
	jb .error
	mov edi,[curspriteblock]
	lea eax,[ebx+ecx]
	cmp ax,[edi+spriteblock.numsounds]
	ja .error

	imul ebx,byte soundinfo_size
	mov edi,[edi+spriteblock.soundinfo]
	add edi,ebx
	xor eax,eax
.soundloop:
	lodsb
	cmp al,NUMOLDSOUNDS
	jae .error
	mov [soundoverrides+4*eax],edi
	add edi,soundinfo_size
	loop .soundloop

	ret

.error:
	mov eax,(INVSP_BADID<<16)+ourtext(invalidsprite) 
	stc
	ret

#if !WINTTDX

// This is how sound works in the original TTD:

// SOUNDRV.COM is a TSR sound card driver that sits on INT 0x66 and uses the DigPak API. It's updated whenever the
// sound card settings are changed via SETUP.EXE.

// SOUND.COM is a helper TSR that sits on INT 0x66 as well, and provides some easy-to-use functions to TTD (initialize
// sound card, play sound etc.) It caches samples from SAMPLE.CAT in the available DOS memory and does the mixing itself.
// It uses the functions provided by SOUNDRV.COM to access the sound card, so this file is hardware-independent.

// TTD uses the functions provided by SOUND.COM to do its sounds, by calling a DOS extender service to execute a real mode
// function (INT 0x66 entry point).

// The new sound code changes this: it doesn't load SOUND.COM, patches all INT 0x66 calls that would be sent to SOUND.COM,
// and implements those functions itself, calling DigPak functions directly if needed. SOUNDRV.COM is still a 16-bit
// program living in low DOS memory, so it's a bit cumbersome to use. We need to allocate some things in DOS memory
// for its sake, for example. Luckily, we can use selector 0x37 to access DOS memory (the offset part being a linear
// address), and there's a DOS extender function to allocate memory blocks there. There's another DOS extender function
// that allows us to call the real mode int 0x66 handler, so we have everything to deal with sound directly.

// SOUND.CFG is used to store sound/music configuration. Its format is not entirely known, but the fields actually used
// by SOUND.COM are defined here.
struc soundcfg
	.initinfo	resw 1		// ??? if it's 3, sound functions are effectively disabled
			resb 0xc-$
	.numsoundchans	resw 1		// number of sound channels
	.reversestereo	resw 1		// if nonzero, left and right must be swapped
	.signedsample	resw 1		// if nonzero, the device needs signed bytes in the buffer
endstruc

varb SoundCfgName, "SOUND.CFG",0

// data from SOUND.CFG is loaded here during initialization
uvarb SoundCfgData,soundcfg_size

// SAMPLE.CAT is loaded into memory as-is during patching, and the address of the block is stored here
uvard SampleCatDataPtr,1,s

// if zero, there was an error while loading SAMPLE.CAT, so the sound driver shouldn't use it
uvarb SampleCatLoadedOK

// These arrays contain some data extracted from SAMPLE.CAT to make things easier
uvard OldSoundOffsets,NUMOLDSOUNDS	// points to the beginning of the RIFF header
uvard OldSoundLengths,NUMOLDSOUNDS	// length of sample, including the RIFF header
uvarb OldSoundPriorities,NUMOLDSOUNDS	// priority of the sample

%define SOUNDBUFSIZE 2048		// must be multiple of 16, preferably power of 2
					// must not be larger than 32K
					// the larger it is, the more delayed sound effects will be

// Sound structure used for communication with the sound driver.
// The actual memory will be allocated during initialization because it must be in DOS memory

struc digpaksndstruc
	.soundptr	resd 1		// 16-bit pointer to sound buffer (segment:offset)
	.sndlen		resw 1		// length of buffer in bytes
	.isplayingptr	resd 1		// 16-bit pointer to play status (segment:offset)
	.frequency	resw 1		// frequency of sound
endstruc

// The following four are linear addresses into the DOS memory area, and therefore
// must be used with the selector 0x37!
uvard SndStrucPtr	// linear offset of DigPak sound structure
uvard SoundPendingPtr	// linear offset of a word that is 1 if there's a pending sound
uvard SoundSemaphorePtr	// linear offset of a word that is 1 if DigPak is busy
			// (only useful during hardware interrupts; DigPak functions
			//  cannot be used while this is 1)
uvard OutputBufferOfst	// linear offset of the playback buffer (it must be below 16MB,
			// so we alloc it in DOS memory to be sure)


uvard BufferWriteOfst	// offset inside the playback buffer where the next packet needs to be written

// Helper structure needed for the DOS extender call that calls real mode interrupts
// see INT 0x21/AX=0x2511 in Ralph Brown's Interrupt List for details
struc pharlapintparamblock
	.intno		resw 1
	.realDS		resw 1
	.realES		resw 1
	.realFS		resw 1
	.realGS		resw 1
	.EAXval		resd 1
	.EDXval		resd 1
endstruc

uvarb RealIntParams,pharlapintparamblock_size

%define MAXSOUNDBUFFS 8

uvard PlaybackPtrs,MAXSOUNDBUFFS			// points to the beginning of the unplayed part of the sample
uvard PlaybackRemainingBytes,MAXSOUNDBUFFS		// how many bytes are remaining from the sample
uvarb PlaybackPriorities,MAXSOUNDBUFFS			// priority of the sample
uvarb PlaybackShrValues,MAXSOUNDBUFFS			// (mono playback only) volume lowering factor for the sample
uvarb PlaybackLeftShrValues,MAXSOUNDBUFFS		// (stereo playback only) volume lowering factor for the left channel
uvarb PlaybackRightShrValues,MAXSOUNDBUFFS		// (stereo playback only) volume lowering factor for the right channel
uvarb SampleNeedsUpsampling,MAXSOUNDBUFFS

// this var is zero until the first play request, signaling that mixing is not needed yet
uvarb SoundPlaying

uvarb StereoEnabled
//uvarb SixteenBitEnabled
uvarb DMAAutoInitEnabled

// called once to initialize sound
global initsounddriver
initsounddriver:
	pusha
	mov word [SoundCfgData+soundcfg.initinfo],3	// if reading sample.cat or sound.cfg fails, we disable everything
	cmp byte [SampleCatLoadedOK],0
	je .exit

// read SOUND.CFG
	mov ax,0x3d00		// open file, read only
	mov edx,SoundCfgName	// pointer to filename
	int 0x21
	jc .soundcfgdone

	mov ebx,eax		// file handle
	mov ah,0x3f		// read from file
	mov ecx,soundcfg_size	// number of bytes to read
	mov edx,SoundCfgData	// pointer to buffer
	int 0x21

	mov ah,0x3e		// close file
				// handle is still in bx
	int 0x21
.soundcfgdone:

	cmp word [SoundCfgData+soundcfg.initinfo],3
	jne .continue

.exit:
	popa
	ret

.allocerror:
	mov word [SoundCfgData+soundcfg.initinfo],3
	jmp short .exit

.continue:
// allocate a small DOS memory block for the DigPak param structure
// (it has to be under 1MB)

	mov ax,0x25c0				// DOS extender - allocate DOS memory block
	mov bx, (digpaksndstruc_size+15)/16	// number of 16-byte paragraphs to allocate
	int 0x21
	jc .allocerror

// set up some fields of the interrupt param struc
// the interrupt number will always be 0x66
	mov word [RealIntParams+pharlapintparamblock.intno],0x66
// whenever DS is used, it has to be the segment of the DigPak structure
	mov [RealIntParams+pharlapintparamblock.realDS],ax

	movzx eax,ax
	shl eax,4
	mov [SndStrucPtr],eax

// allocate the playback buffer
// it has to be below 1MB so DigPak can access it, and it shouldn't cross a 64K boundary
// to statisfy the second condition, we alloc twice the buffer size, and use
// the "good" part only (there can't be two 64K boundaries in a <=64K block)

	mov ax,0x25c0			// DOS extender - allocate DOS memory block
	mov bx,(2*SOUNDBUFSIZE)/16	// number of 16-byte paragraphs to allocate
	int 0x21
	jc .allocerror

// create linear address from segment
	movzx eax,ax
	shl eax,4
	lea ebx,[eax+SOUNDBUFSIZE-1]	// calculate the address of the last used byte

// if the buffer doesn't cross a 64K boundary, the upper word of the beginning and the end
// must be the same
	rol eax,16
	rol ebx,16
	cmp ax,bx
	je .bufferok

// buffer not OK - jump to the beginning of the next 64K block
	movzx eax,ax
	inc eax

.bufferok:
	rol eax,16	// now eax is a good linear start address

	mov [OutputBufferOfst],eax

// the offset part will always be zero - either because the old address was OK
// and it was paragraph-aligned, or because we cleared the bottom 16 bits to zero
// calculate the segment part
	shr eax,4

	mov edx,es		// save old ES into DX (the upper half of EDX is undefined)

	mov bx,0x37		// set up ES to access the DOS memory
	mov es,ebx
	mov ebx,[SndStrucPtr]
	and word [es:ebx+digpaksndstruc.soundptr],0			// offset part=0
	mov [es:ebx+digpaksndstruc.soundptr+2],ax			// segment part
	mov word [es:ebx+digpaksndstruc.sndlen],SOUNDBUFSIZE/2
	mov word [es:ebx+digpaksndstruc.frequency],11025
	test byte [newsoundsettings],NEWSOUNDS_HIGHFREQUENCY
	jz .nohighfreq
	mov word [es:ebx+digpaksndstruc.frequency],22050
.nohighfreq:

#if 0
//not really needed, keepsoundplaying will sweep the buffer clean before using it anyway
	mov edi,[OutputBufferOfst]
	mov ecx,SOUNDBUFSIZE/4
	rep stosd
#endif

	mov es,edx		// restore old ES

	mov ax,0x2511		// DOS extender - invoke real-mode interrupt
	mov edx,RealIntParams
	mov word [edx+pharlapintparamblock.EAXval],0x699	// report addresses
	int 0x21

	movzx edx,word [edx+pharlapintparamblock.EDXval]
	shl edx,4
	movzx eax,ax
	add eax,edx
	mov [SoundPendingPtr],eax
	movzx ebx,bx
	add ebx,edx
	mov [SoundSemaphorePtr],ebx

	mov ax,0x2511		// DOS extender - invoke real-mode interrupt
	mov edx,RealIntParams
	mov word [edx+pharlapintparamblock.EAXval],0x68c	// AudioCapabilities
	int 0x21
	mov ebx,eax
	test bl,0x80
	jz .nostereo

	mov ax,0x2511		// DOS extender - invoke real-mode interrupt
	mov word [edx+pharlapintparamblock.EAXval],0x698	// SetPlayMode
	mov word [edx+pharlapintparamblock.EDXval],1		// 8-bit stereo
	int 0x21
	test ax,ax
	jz .nostereo

	mov byte [StereoEnabled],1
	mov dword [mixbuffer], addr(mixstereosoundtobuffer)
	mov dword [maxsamplelen], SOUNDBUFSIZE/2/2
	mov dword [mixbuffer.upsample], addr(mixstereosoundtobuffer_upsample)
	mov dword [maxsamplelen_upsample], SOUNDBUFSIZE/2/4

#if 0
	test ebx,0x800
	jz .no16bit

	mov ax,0x2511		// DOS extender - invoke real-mode interrupt
	mov word [edx+pharlapintparamblock.EAXval],0x698	// SetPlayMode
	mov word [edx+pharlapintparamblock.EDXval],3		// 16-bit stereo
	int 0x21
	test ax,ax
	jz .no16bit

	mov byte [SixteenBitEnabled],1
	mov dword [mixbuffer], addr(mix16bitsoundtobuffer)
	mov dword [maxsamplelen], SOUNDBUFSIZE/2/4
	mov dword [mixbuffer.upsample], addr(mix16bitsoundtobuffer_upsample)
	mov dword [maxsamplelen_upsample], SOUNDBUFSIZE/2/8

.no16bit:
#endif
.nostereo:

	test ebx,0x200
	jz .nobackfill

	mov ax,0x2511		// DOS extender - invoke real-mode interrupt
	mov word [edx+pharlapintparamblock.EAXval],0x69c	// SetDMABackfillMode
	mov word [edx+pharlapintparamblock.EDXval],1		// ON
	int 0x21
	test ax,ax
	jz .nobackfill

	mov dword [needrefill],addr(checkDMAcounter)
	mov dword [postsound],addr(postDMAsound)
	mov byte [DMAAutoInitEnabled],1

.nobackfill:
// the whole sample.cat file is already loaded into the memory verbatim.
// find the beginning and the length of each sample, then pre-process sample
// data before it gets played
	xor ebx,ebx
	mov esi,[SampleCatDataPtr]
.sampleloop:
	lodsd
	add eax,[SampleCatDataPtr]
	mov cl,[eax+1]				// priority (or first character of description if the Win sample.cat)
	mov [OldSoundPriorities+ebx],cl
	movzx ecx,byte [eax]			// length of priority/description
	lea eax,[eax+ecx+1]
	mov [OldSoundOffsets+ebx*4],eax		// now, EAX should point to the beginning of the RIFF header
	push eax
	lodsd
	mov [OldSoundLengths+ebx*4],eax
	push eax
	call MassageSoundData
	inc ebx
	cmp ebx,NUMOLDSOUNDS
	jb .sampleloop

	popa
	ret

// convert unsigned sample data to signed; mixing is done with signed data
proc MassageSoundData
	arg ptr,length

	_enter
	pusha

	mov esi,[%$ptr]
	add esi,44	// skip header
	mov edi,esi
	mov ecx,[%$length]
	sub ecx,44
	jz .done

.nextbyte:
	lodsb
	xor al,0x80
	sar al,1
	stosb
	dec ecx
	jnz .nextbyte

.done:
	popa
endproc

// some parts of the playback need to be changed for stereo playback and auto-init DMA
// instead of conditional jumps, we do indirect calls to addresses stored here
vard mixbuffer
		dd addr(mixmonosoundtobuffer)
.upsample:	dd addr(mixmonosoundtobuffer_upsample)
endvar

vard needrefill, addr(checkaudiopending)
vard postsound, addr(postnormalsound)

// maximum number of sample bytes that can be used in one go
vard maxsamplelen, SOUNDBUFSIZE/2
vard maxsamplelen_upsample, SOUNDBUFSIZE/2/2

// set to 1 when the sound card actually starts playing
uvarb PlaybackStarted

// called every 6ms to update buffers and keep the sound playing
global keepsoundplaying
keepsoundplaying:
	pusha
	push es

	cmp word [SoundCfgData+soundcfg.initinfo],3
	je .exit

	cmp byte [SoundPlaying],0	// don't do anything until there's a request
	je .exit

	mov ax,0x37			// set up ES to access the DOS memory
	mov es,eax

	mov eax,[SoundSemaphorePtr]	// we're in a hardware interrupt (timer int), so DigPak may be active
	cmp word [es:eax],0		// we shouldn't bother it in this case
	jnz .exit

	cmp byte [PlaybackStarted],0	// if the card isn't playing yet, needrefill won't work
	jz .continue

	call [needrefill]
	jz .continue

.exit:
	pop es
	popa
	ret

.continue:
	mov ebx,[OutputBufferOfst]
	add ebx,[BufferWriteOfst]
// now ebx points to the linear address we need to write to
// clear it before using
	mov edi,ebx
	xor eax,eax
	mov ecx,SOUNDBUFSIZE/2/4
	rep stosd

// mix the samples into the buffer
// the actual work is done in the called proc
	xor ebp,ebp

.nextsampleslot:

	movzx ecx,byte [SampleNeedsUpsampling+ebp]

	mov edi,ebx
	mov edx,[PlaybackRemainingBytes+ebp*4]
	test edx,edx
	jz .sampledone
	cmp edx,[maxsamplelen+ecx*4]
	jbe .dontlimit
	mov edx,[maxsamplelen+ecx*4]
.dontlimit:
	sub [PlaybackRemainingBytes+ebp*4],edx
	mov esi,[PlaybackPtrs+ebp*4]

	call [mixbuffer+ecx*4]

	mov [PlaybackPtrs+ebp*4],esi
.sampledone:
	inc ebp
	cmp bp,[SoundCfgData+soundcfg.numsoundchans]
	jb .nextsampleslot

//	cmp byte [SixteenBitEnabled],0
//	jnz .dontmassage

// for those sound cards that expect unsigned data, we need to convert the buffer
	cmp word [SoundCfgData+soundcfg.signedsample],0
	jnz .dontmassage

	mov edi,ebx
	mov ecx,SOUNDBUFSIZE/2/4
.next4:
	xor dword [es:edi],0x80808080
	add edi,4
	dec ecx
	jnz .next4

.dontmassage:
// post the sound for playing
	call [postsound]

// jump to the other half (the offset is either 0 or SOUNDBUFSIZE/2, so XOR is OK to toggle)
	xor dword [BufferWriteOfst],SOUNDBUFSIZE/2
	mov byte [PlaybackStarted],1

	pop es
	popa
	ret

checkaudiopending:
// check if a new packet needs to be posted - it needs checking a word only
	mov eax,[SoundPendingPtr]
	cmp word [es:eax],0
	ret

checkDMAcounter:
// check if a new packet needs to be posted in auto-init DMA mode
// if the play pointer isn't in the same half as the write pointer, we can write a new packet
	mov ax,0x2511			// DOS extender - invoke real-mode interrupt
	mov edx,RealIntParams
	mov word [edx+pharlapintparamblock.EAXval],0x69D	// ReportDMACCount
	int 0x21

	cmp ax,SOUNDBUFSIZE/2
	jbe .secondhalf

	cmp dword [BufferWriteOfst],SOUNDBUFSIZE/2
	ret

.secondhalf:
	cmp dword [BufferWriteOfst],0
	ret

// mixer functions are called with
//	DS:ESI->source
//	ES:EDI->destination
//	EDX=number of source bytes to mix
// ESI must point to the remaining sample data on exit
// EAX,ECX,EDX and EDI can be modified

mixmonosoundtobuffer:
	mov cl,[PlaybackShrValues+ebp]

.nextbyte:
	lodsb
	sar al,cl
	add [es:edi],al
	inc edi
	dec edx
	jnz .nextbyte
	ret

mixmonosoundtobuffer_upsample:
	mov cl,[PlaybackShrValues+ebp]

.nextbyte:
	lodsb
	sar al,cl
	add [es:edi],al
	add [es:edi+1],al
	add edi,2
	dec edx
	jnz .nextbyte
	ret

mixstereosoundtobuffer:
	mov cl,[PlaybackLeftShrValues+ebp]
	mov ch,[PlaybackRightShrValues+ebp]

.nextbyte:
	lodsb
	mov ah,al
	sar al,cl
	xchg cl,ch
	sar ah,cl
	xchg cl,ch
	add [es:edi],al
	add [es:edi+1],ah
	add edi,2
	dec edx
	jnz .nextbyte

	ret

mixstereosoundtobuffer_upsample:
	mov cl,[PlaybackLeftShrValues+ebp]
	mov ch,[PlaybackRightShrValues+ebp]

.nextbyte:
	lodsb
	mov ah,al
	sar al,cl
	xchg cl,ch
	sar ah,cl
	xchg cl,ch
	add [es:edi],al
	add [es:edi+1],ah
	add [es:edi+2],al
	add [es:edi+3],ah
	add edi,4
	dec edx
	jnz .nextbyte

	ret

#if 0
mix16bitsoundtobuffer:
	mov cl,[PlaybackLeftShrValues+ebp]
	mov ch,[PlaybackRightShrValues+ebp]

	push ebx
.nextbyte:
	xor al,al
	mov ah,[esi]
	mov bx,ax
	sar ax,cl
	xchg cl,ch
	sar bx,cl
	xchg cl,ch
	mov [es:edi],ax
	mov [es:edi+2],bx
	inc esi
	add edi,4
	dec edx
	jnz .nextbyte

	pop ebx
	ret
#endif

postnormalsound:
// normal playback - use the PostAudioPending function, alternating between the two halves of the buffer
	mov ax,0x2511		// DOS extender - invoke real-mode interrupt
	mov edx,RealIntParams
	mov word [edx+pharlapintparamblock.EAXval],0x695	// PostAudioPending
	xor esi,esi
	int 0x21

	mov eax,[SndStrucPtr]
	xor word [es:eax+digpaksndstruc.soundptr],SOUNDBUFSIZE/2
	ret

postDMAsound:
// in auto-init DMA mode, we need to start the sound once only, by specifying the whole buffer
// the sound card will restart reading from the beginning after finishing the buffer
	cmp byte [PlaybackStarted],0
	jnz .done

	mov eax,[SndStrucPtr]
	mov word [es:eax+digpaksndstruc.sndlen],SOUNDBUFSIZE

	mov ax,0x2511		// DOS extender - invoke real-mode interrupt
	mov edx,RealIntParams
	mov word [edx+pharlapintparamblock.EAXval],0x688	// PlaySound
	xor esi,esi
	int 0x21
.done:
	ret

// called before exiting to shut down sound and restore old hardware state
global stopsound
stopsound:
	pusha
	cmp word [SoundCfgData+soundcfg.initinfo],3
	je .exit

	mov ax,0x2511		// DOS extender - invoke real-mode interrupt
	mov edx,RealIntParams
	mov word [edx+pharlapintparamblock.EAXval],0x68f	// StopSound
	int 0x21

	cmp byte [StereoEnabled],0
	jz .nostereo

	mov ax,0x2511		// DOS extender - invoke real-mode interrupt
	mov word [edx+pharlapintparamblock.EAXval],0x698	// SetPlayMode
	mov word [edx+pharlapintparamblock.EDXval],0		// 8-bit mono
	int 0x21

.nostereo:

	cmp byte [DMAAutoInitEnabled],0
	jz .noDMAautoinit

	mov ax,0x2511		// DOS extender - invoke real-mode interrupt
	mov word [edx+pharlapintparamblock.EAXval],0x69c	// SetDMABackfillMode
	mov word [edx+pharlapintparamblock.EDXval],0		// OFF

.noDMAautoinit:
.exit:
	popa
	ret

global uninstallsound
uninstallsound:
// The old code released memory and restored interrupt vectors here.
// We can't free memory and didn't modify the interrupt vectors, so nothing to do here (yet?).
	ret

// called at the end of GenerateSoundEffect to play an old TTD sound
// just pass the request to our general sound player function
global playorigsound
playorigsound:
	push dword [OldSoundOffsets+eax*4]
	push dword [OldSoundLengths+eax*4]
	push ebx
	push ecx
	movzx eax,byte [OldSoundPriorities+eax*4]
	push eax
	call playsound
	ret

// Called to play a given sample. Actually, it doesn't start output, just adds the sound to the list so
// the next keepsoundplaying call will start playing it. The pointer must point to the beginning of a
// RIFF header, the data must be already converted to signed and it shouldn't be changed during playback.
// Destroys all general-purpose registers
proc playsound
	arg soundptr,soundlen,volume,panning,priority

	_enter

// first, find a slot for the sound

// try finding an empty one first
	xor edx,edx
.nextempty:
	cmp dword [PlaybackRemainingBytes+edx*4],0
	je .foundslot
	inc edx
	cmp dx,[SoundCfgData+soundcfg.numsoundchans]
	jb .nextempty

// try kicking out a lower priority sound
	xor edx,edx
	mov al,[%$priority]
.nextlowpri:
	cmp [PlaybackPriorities+edx],al
	ja .foundslot
	inc edx
	cmp dx,[SoundCfgData+soundcfg.numsoundchans]
	jb .nextlowpri

// no slot found, give up
	_ret

.foundslot:
	mov al,[%$priority]
	mov [PlaybackPriorities+edx],al
	mov eax,[%$soundptr]
	test byte [newsoundsettings],NEWSOUNDS_HIGHFREQUENCY
	jz .neverupsample
	cmp word [eax+24],11025
	setz byte [SampleNeedsUpsampling+edx]
.neverupsample:
	add eax,44		//skip RIFF header
	mov [PlaybackPtrs+edx*4],eax
	mov eax,[%$soundlen]
	sub eax,44
	mov [PlaybackRemainingBytes+edx*4],eax

// The given volume is in the range 0..128, but we in fact have only 9 volumes
// (shifting right by 0..8 bits). Convert volume to shift value using the formula
// ShrVal=7-(volume/16)
	mov al,[%$volume]
	sar al,4
	neg al
	add al,7
	mov [PlaybackShrValues+edx],al

// In stereo, panning can modify the volume of a channel. Both channels start with the
// shift value calculated above, and can be made quiteter by panning
	movzx ecx,byte [%$panning]
	mov bl,[PanningLeftShrVals+ecx]
	mov bh,[PanningRightShrVals+ecx]
	add bl,al
	add bh,al
	cmp word [SoundCfgData+soundcfg.reversestereo],0
	jz .noreverse
	xchg bl,bh
.noreverse:
	mov [PlaybackLeftShrValues+edx],bl
	mov [PlaybackRightShrValues+edx],bh

	mov byte [SoundPlaying],1
	_ret
endproc

varb PanningLeftShrVals, 0,0,0,0,0,1,2,4,8
varb PanningRightShrVals, 8,4,2,1,0,0,0,0,0

#endif
