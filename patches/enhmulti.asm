// Enhance multiplayer in the Windows version (allow more players)
// Doesn't work perfectly yet

#include <std.inc>
#include <flags.inc>
#include <textdef.inc>
#include <station.inc>
#include <window.inc>
#include <player.inc>
#include <bitvars.inc>
#include <win32.inc>
#include <ptrvar.inc>

#if WINTTDX

extern CreateWindow,MPpacketnum,MPtimeout
extern MPtransferbuffer
extern closedirectplay,doallplayeractions,dorecbuffer,dosendbuffer,errorpopup
extern miscmodsflags,networktimeout,patchflags,recaction
extern receiveanddoactions,redrawscreen,restartgame,sendaction
extern transmitendofactionsfn



uvard playerids,8	// DirectPlay IDs of (up to 8) players

uvard isremoteplayer	// bit mask of remote human players in company array
uvard isremoteplayerid	// bit mask of remote human players in playerids
uvarb localplayeridnum	// index of local player in playerids
uvarb orighumanplayers	// bit mask of "genuine" human players, for subsidiaries support

uvarb playersfound
varb playersfoundbefore, 1
uvarb realplayernum	// Real number of players. Numplayers can't be used because TTD assumes it's either 1 or 2

#if DEBUGNETPLAY
uvard DebugMsg,1,s
#endif

// New callback function to enumerate players in the session
// (See DirectX SDK for further info)
global newenumplayers
newenumplayers:
	push ebx
	mov eax,[esp+8]
	movzx ebx,byte [playersfound]
	mov dword [playerids+ebx*4],eax
	inc byte [playersfound]
	pop ebx
	mov eax,1
	ret 0x14

// Record errors during sending and receiving data in MP

uvard lastpacketsender

// Called just after IDirectPlay.Receive
// eax contains the error number, write it to file
// we reset the notifying event here if needed as well, and record who sent the package
global recresult
recresult:
	mov [ebp-8],eax		// overwritten
	or eax,eax	// don't log success...
	jz .noerror

#if DEBUGNETPLAY
	cmp eax,0x887700be	// and "No message in quene", it'd just bloat our log
	jz .dontlog
	pusha
	mov cl,8
	mov edi, .num
extern hexnibbles
	call hexnibbles
	push .msg
	call [DebugMsg]
	popa
.dontlog:
#endif
	test byte [miscmodsflags+1],MISCMODS_NOTIMEGIVEAWAY>>8
	jnz .dontresetevent
	cmp eax,0x887700be
	jnz .dontresetevent
// Reset the event that notifies us about getting a packet if there's none left (see code below)
	pusha
	mov eax,[localplayereventhandle]
	or eax,eax
	jz .donthavehandle
	push eax
	call dword [ResetEvent]
.donthavehandle:
	popa
	jmp short .noerror
.dontresetevent:
.noerror:
	mov eax,[ebp-0xc]
	mov [lastpacketsender],eax
	test eax,eax
	ret

#if DEBUGNETPLAY
.msg: db "recresult: Unexpected error: 0x"
.num: times 8 db 0
db 0xd,0xa,0
#endif

uvarb lastpacketnum,1,s
uvarb transferattempts

// Called when TTD tries sending or receiving again.
// Give it up after 10 tries and fall back to single player.
global retrytransfer
retrytransfer:
	add eax,1000			// reproduce overwritten code
	mov ecx,[MPtimeout]
	mov [ecx],eax
	mov eax,[MPpacketnum]
	mov al,[eax]
	mov cl,[transferattempts]
	cmp al,[lastpacketnum]
#if DEBUGNETPLAY
	je .notnew_log
#else
	je .notnew
#endif
	xor cl,cl
	mov [lastpacketnum],al
.notnew:
	inc cl
	cmp cl,[networktimeout]

	ja .giveitup
	mov [transferattempts],cl
	ret

#if DEBUGNETPLAY
.notnew_log:
	pusha
	mov edi, .num
	mov cl,2
	call hexnibbles
	push .msg
	call [DebugMsg]
	popa
	jmp short .notnew
#endif

.giveitup:
	pop eax
	mov eax,[MPtransferbuffer]
	mov byte [eax],-2
	mov byte [numplayers],1
	mov byte [human2],-1
	mov byte [lastpacketnum],-1
	pusha
	mov bx,ourtext(neterror1)
	mov dx,ourtext(neterror2)
	xor ax,ax
	xor cx,cx
	call dword [errorpopup]
	call dword [closedirectplay]
	popa
	call redrawscreen
	ret

#if DEBUGNETPLAY
.msg: db "retrytransfer: Retrying packet 0x"
.num: db 0,0
db 0xd,0xa,0
#endif

// Make TTDWin multiplayer not eat 100% CPU time while listening for packets.
// DirectPlay can provide a Windows event object that becomes signalled if the player gets a message.
// WinTTD doesn't ask for this handle but loops on Receive instead, making the program inefficient.
// Fix this by using a proper Windows waiting method.

uvard localplayereventhandle
uvard WaitForSingleObject
uvard ResetEvent
uvard MsgWaitForMultipleObjects

// Called before a sender player is created.
// Push our pointer instead of the old zero.
global createsenderplayer
createsenderplayer:
	pop ebx
	push localplayereventhandle
	lea eax,[ebp-0x1c]		// overwritten
	push eax			// ditto
	jmp ebx

// The same for receiver players
global createreceiverplayer
createreceiverplayer:
	pop ebx
	push localplayereventhandle
	lea eax,[ebp-0x20]		// overwritten
	push eax			// ditto
	jmp ebx

// Called before calling IDirectPlay.Receive.
// Call a waiting function before trying to receive anything, so Windows can run other tasks.
// The event will be reset if necessary in recresult (see above).
global recbuffer
recbuffer:
	pusha
// Wait 100 ms for a message to arrive

	push 100
	push dword [localplayereventhandle]
	call dword [WaitForSingleObject]	// WaitForSingleObject(localplayereventhandle,100)

#if DEBUGNETPLAY
	cmp eax,0x102				// WAIT_TIMEOUT
	jne .good
	mov al,[curplayer]
	or al,al
	jns .notneg
	not al
.notneg:
	add al,'0'
	mov [.num],al
	push .foo
	call [DebugMsg]
.good:
#endif
// We get here if either the wait has timed out or there's a message in the quene.
// We don't really care about which one happened, so we can ignore the return value
	popa
	pop ebx
	push 1			// overwritten
	lea eax,[ebp-4]		// by the
	push eax		// runindex call
	jmp ebx

// Also reduce CPU demand while waiting for the other player to join.
// While waiting, TTD does two things in a loop: looks for messages and enumerates players.

#if DEBUGNETPLAY
.foo: db "It takes too much for player "
.num: db 0," to answer!",0x0d,0x0a,0
#endif
// Called instead of PeekMessage in the first part.
// return with eax=0 to skip message processing
global waitforconnection1
waitforconnection1:
	pop dword [tempvar]		// remove our return address from the stack
	call dword [PeekMessage]		// call PeekMessage
	or eax,eax			// nonzero result means messages available, so don't wait
	jnz .exit
// Wait until either a window message or a DirectPlay message arrives
	push 0x1ff
	push -1
	push 0
	push localplayereventhandle
	push 1
	call dword [MsgWaitForMultipleObjects]	// MsgWaitForMultipleObjects(1,&localplayereventhandle,FALSE,INFINITE,QS_ALLINPUT)
	xor eax,eax
.exit:
// when we get there, the loop really has something to do
	jmp dword [tempvar]

uvarb temprecbuffer,54

varb startstring, "TTDPatchStartMulti"

varb PlayernumStr,  0," player(s) connected.",0

varb StartStr, "Start",0

varb CancelStr, "Cancel",0

// Called after the second part.
// Call dorecbuffer to remove waiting DirectPlay system messages and reset our notify event
// in: zf set if enumerating was successful
// return 0x14 bytes farther if zf was clear
//
// if enhancemultiplayer is on, modify the loop to allow more players to join
// useful variables:
//	[ebp+8]: 	type of window showing (0x69 - host waiting; 0x6a - guest waiting)
//	[ebp-0x80]: 	handle of window showing
//	[ebp-0x7c]: 	if this is nonzero, the loop ends and indicates success
//	[0x420268]: 	becomes nonzero if the button was pressed in the window
//			this ends the loop as well, indicating failure
global waitforconnection2
waitforconnection2:
	jnz .error
// Check if we have any DirectPlay messages waiting, and if so, remove them
	push 0
	push dword [localplayereventhandle]
	call dword [WaitForSingleObject]	// WaitForSingleObject(localplayereventhandle,0)
	cmp eax,0x102				// WAIT_TIMEOUT
	je .nomsgwaiting
// Call dorecbuffer until it reports failure
	pusha
	push 54
	push temprecbuffer
.loop:
	call dword [dorecbuffer]
	or eax,eax
	jz .finishedloop
	testflags enhancemultiplayer
	jnc .loop
	cmp dword [ebp+8],0x69
	je .loop
	mov ecx,18				// did we get a game start message?
	mov edi,temprecbuffer
	mov esi,startstring
	repe cmpsb
	jne .loop
	mov dword [ebp-0x7c],1			// yep, we can start
	mov byte [playersfoundbefore],1
.finishedloop:
	add esp,8
	popa
.nomsgwaiting:
	testflags enhancemultiplayer
	jc .enhanced
.exit:
	ret

.error:
	pop eax
	add eax,0x14
	jmp eax

.enhanced:
	mov al,[playersfound]
	cmp al,[playersfoundbefore]
	je .noplayernumchange
	mov [playersfoundbefore],al		// number of players has changed - update window 
	dec al					// by calling SetDlgItemTextA for the label and the button
	add al,'0'
	mov [PlayernumStr],al
	push PlayernumStr
	push 1011
	push dword [ebp-0x80]
	call dword [SetDlgItemTextA]
	mov eax,CancelStr
	cmp dword [ebp+8],0x69
	jne .cannotstart
	cmp byte [playersfound],1
	je .cannotstart
	mov eax,StartStr
.cannotstart:
	push eax
	push 2
	push dword [ebp-0x80]
	call dword [SetDlgItemTextA]
.noplayernumchange:
	cmp dword [0x420268],0
	jne .buttonclicked
	mov byte [playersfound],0		// next enumeration should count from zero again
	ret

.buttonclicked:
	cmp dword [ebp+8],0x69
	jne .cancel
	cmp byte [playersfound],1
	je .cancel
	push 0				// start the game
	mov eax,[DPlayInterface]
	push eax
	mov eax,[eax]
	call dword [eax+0x28]		// IDirectPlay.EnableNewPlayers(FALSE)
	mov dword [RemotePlayerID],0	// send everyone a start message
	push 18
	push startstring
	call dword [dosendbuffer]
	add esp,8
	or eax,eax
	jz .exit
	mov dword [ebp-0x7c],1		// the window should close now
	mov al,[playersfound]
	mov [realplayernum],al
	jmp short .closewindow
.cancel:
	mov byte [realplayernum],1	// the button pressed was Cancel - fall back to single player
	and dword [isremoteplayer],0
.closewindow:
	mov byte [playersfound],0	// reset values so they have their initial value when the window opens next time
	mov byte [playersfoundbefore],1
	pop eax
	add eax,0x14
	jmp eax

uvard acknowledges

uvard lastgoodpacketsender

// Called after receiving an acknowledge packet
// don't allow SendAction to return until everyone acknowledges the packet
global recnetack
recnetack:
	cmp al,[dword 0]
ovar .bytetocheck,-4,$,recnetack
	jne .exit
	cmp dword [RemotePlayerID],0		// is this a broadcast message?
	jne .success
	mov eax,[lastpacketsender]		// find whose message it was
	mov ecx,8
	mov edi,playerids
	repne scasd
	sub edi,playerids
	shr edi,2
	dec edi
	cmp edi,8
	jae .wrongplayer
	bts dword [acknowledges],edi		// record the acknowledge
#if DEBUGNETPLAY
	jnc .notagain
	pusha
	mov eax,edi
	mov cl,1
	mov edi, .num
	call hexnibbles
	push .msg
	call [DebugMsg]
	popa
.notagain:
#endif
.wrongplayer:
	mov eax,[acknowledges]		// has everyone answered?
	not eax
	test eax,[isremoteplayerid]
	jnz .exit
.success:
	and dword [acknowledges],0
.exit:
	ret

#if DEBUGNETPLAY
.msg: db "Player "
.num: db 0
db " acknowledged a packet twice!",0xd,0xa,0
#endif

// send an acknowledge packet to the sender of the last correct message
// sendnetack2 is called after a successful receive, so the last sender is the last good sender
global sendnetack2
sendnetack2:
	mov eax,[lastpacketsender]
	mov [lastgoodpacketsender],eax

global sendnetack1
sendnetack1:
	push dword [RemotePlayerID]		// send the acknowledge to the sender only, but save RemotePlayerID first
	mov eax,[lastgoodpacketsender]
#if DEBUGNETPLAY
	or eax,eax
	jnz .good
	pusha
	push .msg
	call [DebugMsg]
	popa
.good:
#endif
	mov [RemotePlayerID],eax
	push ecx
	push esi
	call dword [dosendbuffer]
	pop esi
	pop ecx
	pop dword [RemotePlayerID]
	ret

#if DEBUGNETPLAY
.msg: db "Lastgoodsender uninitialized!",0xd,0xa,0
#endif
// Called on the host machine after the game has started
// initialize some important data here
global initserver
initserver:
	pusha
	movzx eax,byte [realplayernum]		// clear junk from the end of playerids
.resetloop:
	cmp al,8
	jae .exitloop
	and dword [playerids+4*eax],0
	inc al
	jmp short .resetloop
.exitloop:
	mov edi,[MPtransferbuffer]		// send local copy of playerids to the clients
	mov esi,playerids
	mov ecx,8
	rep movsd
	call initplayerdata			// process player data
	and dword [RemotePlayerID],0		// this message (and further ones) should be broadcasted
	mov eax,[MPpacketnum]
	mov byte [eax],0
	call dword [sendaction]
	popa
	ret

// Same with guest machine
global initclient
initclient:
	pusha
	mov eax,[MPpacketnum]			// wait for the player list...
	mov byte [eax],0
	call dword [recaction]
	mov esi,[MPtransferbuffer]		// ...save it...
	mov edi,playerids
	mov ecx,8
	rep movsd
	call initplayerdata			// ...and process it
	popa
	ret

uvarb temphuman1

// auxiliary: set realplayernum, human1 and isremoteplayer according to playerids
initplayerdata:
	xor ebx,ebx
	and dword [isremoteplayer],0
	and byte [realplayernum],0
.ishumanloop:
	mov ecx,[playerids+ebx*4]
	or ecx,ecx			// zero means no player
	jz .next
	inc byte [realplayernum]
	cmp ecx,[LocalPlayerID]
	jne .notlocal
	mov al,bl			// this is the local player
#if DEBUGNETPLAY
	pusha
	add al,'0'
	mov [.num],al
	push .msg
	call [DebugMsg]
	popa
#endif
	mov [localplayeridnum],al
	not al				// we'll go to the title screen, where all humans have negative numbers
	mov [human1],al
	jmp short .next
.notlocal:
	bts dword [isremoteplayer],ebx
.next:
	inc bl
	cmp bl,8
	jb .ishumanloop
	mov al,[human1]
	mov [temphuman1],al		// some TTD code destroys human1, so make a second copy
	mov eax,[isremoteplayer]	// at the beginning, the player id mask is the same as the player mask
	mov [isremoteplayerid],eax
	ret

#if DEBUGNETPLAY
.msg: db "Got PlayerID "
.num: db 0,0x0d,0x0a,0
#endif

// Here comes the main trick of enhancedmultiplayer: make TTD handle all remote players
// The most common solution for checking human players is something like this:
//	cmp xx,[human1]
//	j(n)e .somewhere
//	cmp xx,[human2]
//	j(n)e .somewhere
//
// We overwrite the second check with our runindex call, which sets zf if the register contains a remote
// human player, so TTD will handle every remote player like human2.
// We have only six bytes to overwrite, so every register needs a separate function

global checkhuman2al
checkhuman2al:
	push eax
	movsx eax,al
	jmp short checkhuman2

global checkhuman2ah
checkhuman2ah:
	push eax
	movsx eax,ah
	jmp short checkhuman2

global checkhuman2bl
checkhuman2bl:
	push eax
	movsx eax,bl
	jmp short checkhuman2

global checkhuman2bh
checkhuman2bh:
	push eax
	movsx eax,bh
	jmp short checkhuman2

global checkhuman2cl
checkhuman2cl:
	push eax
	movsx eax,cl
	jmp short checkhuman2

global checkhuman2dl
checkhuman2dl:
	push eax
	movsx eax,dl

checkhuman2:
// now we have the player number in eax
	or eax,eax
	jns .notitlescreen
	cmp byte [gamemode],0
	jne .cantbehuman
	not eax				// on the title screen, humans have negative numbers; turn the to positive ones
.notitlescreen:
	cmp eax,8
	jae .cantbehuman
	bt dword [isremoteplayer],eax
	setnc al				// put cf into zf
	test al,al
	pop eax
	ret

.cantbehuman:
	or eax,eax			// clear zf (eax can't be zero here)
	pop eax
	ret

varb sync_packet, 5

exported transmitendofactions_enhmulti
	call $
ovar .oldfn,-4,$,transmitendofactions_enhmulti
	cmp byte [numplayers],1
	je .nomulti
	pusha
	push 1
	push sync_packet
	call dword [dosendbuffer]
	add esp,8
	popa
.nomulti:
	ret

exported receiveanddoactions_enhmulti
	call $
ovar .oldfn,-4,$,receiveanddoactions_enhmulti
	pusha
	push 1
	mov esi,[MPtransferbuffer]
	push esi
.wait:
	call dword [dorecbuffer]
	test eax,eax
	jz .wait
	add esp,8
#if DEBUGNETPLAY
	cmp eax,1
	jne .bad
	mov esi,[MPtransferbuffer]
	cmp byte [esi],5
	je .notbad
.bad:
	mov al,[curplayer]
	add al,'0'
	mov [.num],al
	mov eax,[MPtransferbuffer]
	mov al,[eax]
	mov edi,.num2
	mov cl,2
	call hexnibbles
	push .msg
	call [DebugMsg]
.notbad:
#endif
	popa
	ret

#if DEBUGNETPLAY
.msg: db "Bad sync packet from player "
.num: db 0,"!",0x0d,0x0a
db "It starts with "
.num2: db 0,0,0xd,0xa,0
#endif

// The old TickProcAllCompanies behaves badly when the game is paused or is in the title screen
// Replace this part with a more general solution
global tickprocallcompanies
tickprocallcompanies:
	cmp byte [numplayers],1
	jne .multi
	mov al,[human1]
	mov [curplayer],al
	call dword [doallplayeractions]
	ret

.multi:
	xor eax,eax
.loop:
	cmp byte [gamemode],0
	jne .nottitlescreen1
	not eax
.nottitlescreen1:
	mov [curplayer],al
	cmp al,[human1]
	jne .notlocal
	push eax
	call dword [doallplayeractions]			// now it's our turn - do and transmit all local actions
	call dword [transmitendofactionsfn]
	pop eax
.notlocal:
	cmp byte [gamemode],0
	jne .nottitlescreen2
	not eax
.nottitlescreen2:
	bt dword [isremoteplayer],eax
	jnc .nextplayer
	push eax					// it's a remote player's turn - receive and do his/her actions
	call dword [receiveanddoactions]
	pop eax
.nextplayer:
	inc eax
	cmp eax,8
	jb .loop
	ret

// Called after a premade map has been loaded
// Human1 was overwritten, but was saved before in oldhuman1 (see loadsave.asm)
global startscenario
startscenario:
	mov al,[oldhuman1]
	mov [temphuman1],al

// Called after generating a new random map.
// Map all human players to a new company number, and create their companies at the same time
// TTD destroyed human1 by now, so use our second copy
global startnewgame
startnewgame:
	cmp byte [numplayers],1
	jne .multi
	call .makenewhuman
	mov [human1],al
	ret

.multi:
	and dword [isremoteplayer],0		// isremoteplayer is invalid now
	mov byte [orighumanplayers],0
	xor ecx,ecx
	mov al,[temphuman1]			// we're coming from the title screen, so invert negative player number
	not al
	mov [temphuman1],al
// ecx contains who we are creating the company for
.loop:
	call .makenewhuman
	cmp cl,byte [temphuman1]
	jne .notlocal
	mov [human1],al				// this will be our company
	jmp short .next
.notlocal:
	movzx eax,al
	bts [isremoteplayer],eax		// this is a remote company
.next:
	inc ecx
	cmp cl,byte [realplayernum]
	jb .loop
	mov al,[human1]
	mov [temphuman1],al
	ret

// creates a new player, then deletes random manager name
// returns the number of new company in al
.makenewhuman:
	mov ebp,[ophandler+0xd*8]
	mov ebx,6
	push ecx
	call dword [ebp+4]
	pop ecx
	movzx edx,al
	bts [orighumanplayers],edx
	imul dx,player_size
	add edx,[playerarrayptr]
	mov word [edx+10],6
	ret

// Called when exiting a game and going back to the title screen.
// Map humans to new negative numbers
// human1 is destroyed, so use temphuman1
global loadtitlescreen
loadtitlescreen:
	cmp byte [numplayers],1
	jne .multi
	mov byte [human1],-2
	mov byte [human2],-1
	ret

.multi:
	mov al,[temphuman1]	// temporarily turn negative number to positive
	or al,al
	jns .correct
	not al
	mov [temphuman1],al
.correct:
	xor eax,eax		// goes through all company slots
	xor ebx,ebx		// contains next available human slot on the titlescreen
	xor ecx,ecx		// new bit mask of remote players
	xor edx,edx		// contains the new value of human1
.loop:
	cmp [temphuman1],al
	jne .notlocal
	mov dl,bl
	not dl
	jmp short .human
.notlocal:
	bt dword [isremoteplayer],eax
	jnc .next
	bts ecx,ebx
.human:
	inc ebx
.next:
	inc eax
	cmp eax,8
	jb .loop
	mov [isremoteplayer],ecx
	mov byte [orighumanplayers],0
	mov [human1],dl
	mov [temphuman1],dl
	ret

// Called when creating a player message window.
// The old code always used human2 for the sender, which isn't correct anymore.
// Store the sender in the window structure so it can be used later in the window handler.
global createplayermsgwindow
createplayermsgwindow:
	mov ebp,3
	call dword [CreateWindow]
	mov al,[curplayer]
	mov [esi+window.data],al
	ret

// Creating Zeppelins uses a different method to check for human players.
// in:	al: human1
//	ah: human2 (contains junk with enhancemultiplayer)
// out:	zf set if the station is owned by a human
global findzeppelintarget
findzeppelintarget:
	mov ah,[esi+station.owner]
	cmp al,ah
	jne near checkhuman2ah
	ret

// Called when switching back to single-player mode.
// Reset our new variables.
global switchbacktosingle
switchbacktosingle:
	mov byte [numplayers],1
	and dword [isremoteplayer],0
	mov byte [realplayernum],1
	ret

// Called while creating the file mask for the game load window.
// in:	esi -> file mask
//	flags from cmp [numplayers],2
global loadfilemask2pl
loadfilemask2pl:
	jne .leaveitalone

	mov ah,[realplayernum]
	add ah,'0'
	mov [esi+9],ah
.leaveitalone:
	ret

// Called if loading a game failed.
// Receive other's state and send the failure message
// We can't use localplayerid because it might have changed on computers that succeeded with loading
global transmitloadfail
transmitloadfail:
	push eax
	xor eax,eax
.loop:
	bt dword [isremoteplayerid],eax
	jnc .notremote
	push eax
	call dword [recaction]
	pop eax
	jmp short .next
.notremote:
	cmp [localplayeridnum],al
	jne .next
	push eax
	mov eax,[MPtransferbuffer]
	mov byte [eax],1
	call dword [sendaction]
	pop eax
.next:
	inc eax
	cmp eax,8
	jb .loop
	pop eax
	ret

uvarb oldhuman1

// the same, but called after a successful loading
// listen for other's states, and restart game if anyone failed
global transmitloadsuccess
transmitloadsuccess:
	push eax
	push ebx
	xor eax,eax
	xor bl,bl
.loop:
	bt dword [isremoteplayerid],eax
	jnc .notremote
	push eax
	push ebx
	call dword [recaction]
	pop ebx
	mov eax,[MPtransferbuffer]
	mov al,[eax]
	or bl,al
	pop eax
	jmp short .next
.notremote:
	cmp [localplayeridnum],al
	jne .next
	push eax
	push ebx
	mov eax,[MPtransferbuffer]
	mov byte [eax],0
	call dword [sendaction]
	pop ebx
	pop eax
.next:
	inc eax
	cmp eax,8
	jb .loop
	or bl,bl
	jz .exit

	mov al,[oldhuman1]
	mov [temphuman1],al
	jmp dword [restartgame]
.exit:
	pop ebx
	pop eax
	ret

#endif //WINTTDX

#if DEBUGNETPLAY
uvarb lograndom_enabled

noglobal uvarw lograndom_filehandle

extern int21handler

// safe: eax, ebx
exported lograndomcaller
	cmp byte [lograndom_enabled],0
	je .nolog
	push ecx
	push edx
	mov ah,0x40	//write to file or device
	mov bx,[lograndom_filehandle]
	mov ecx,4
// get the return address of randomfn from the stack
	lea edx,[esp+2*4+4+4]	// we pushed 2 registers, 4 bytes for our return address
				// and 4 again because the caller pushed ebx before calling us
	CALLINT21
	pop edx
	pop ecx

.nolog:
	mov ebx,[randomseed2]		// overwritten
	ret

noglobal varb randomlogfilename, "random.log", 0

// enable random generator logging
// cf is set on exit if there was an error
exported enable_lograndom
	cmp byte [lograndom_enabled],0
	jne .done

	push eax
	push ecx
	push edx
	mov ah,0x3c		// create or truncate file
	xor ecx,ecx		// no special attributes
	mov edx,randomlogfilename	// filename

	CALLINT21
	jc .error
	mov byte [lograndom_enabled],1
	mov [lograndom_filehandle],ax
.error:
	pop edx
	pop ecx
	pop eax
.done:
	ret

exported disable_lograndom
	cmp byte [lograndom_enabled],0
	je .done

	push eax
	push ebx

	mov ah, 0x3E	// close file
	mov bx,[lograndom_filehandle]

	CALLINT21

	mov byte [lograndom_enabled],0

	pop ebx
	pop eax

.done:
	ret

//clean all existing entries from the random log if logging is enabled
exported truncate_random_log
	cmp byte [lograndom_enabled],0
	je .nologging

// Unfortunately, we can't truncate the file directly.
// Writing 0 bytes via int21 would only work on DOS, the int21 wrapper
// of the Windows version doesn't translate it correctly
// The best thing we can do is closing the file then reopening it

	call disable_lograndom
	call enable_lograndom

.nologging:
	ret
	
#endif //DEBUGNETPLAY
