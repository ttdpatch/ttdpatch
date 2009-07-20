#include <defs.inc>
#include <frag_mac.inc>
#include <window.inc>
#include <textdef.inc>
#include <patchproc.inc>

patchproc sortvehlist, patchsortvehlist
patchproc enhancegui,sortvehlist, patchdrawvehlist

extern vehlistwindowsizes,patchflags,vehlistwindowconstraints

extern TrainListDrawHandlerCountDec,TrainListDrawHandlerCountTrains,TrainListClickHandlerAddOffset,TrainListDrawHandlerCountDec.skip, RVListDrawHandlerCountDec.skip, ShipListDrawHandlerCountDec.skip,AircraftListDrawHandlerCountDec.skip

begincodefragments

codefragment oldfindlisttrains
	cmp al, [edi+veh.owner]
	jne .notours
	inc ah
.notours:

codefragment newfindlisttrains
	call runindex(findlisttrains)
	setfragmentsize 7
	add edi,vehiclesize
	call runindex(findlistvehs_next)

codefragment oldfindlistvehs
	cmp bl, [edi+veh.owner]
	jne .notours
	inc ax
.notours:

codefragment newfindlistvehs
	call runindex(findlistvehs)
	setfragmentsize 7
	add edi,vehiclesize
	call runindex(findlistvehs_next)

codefragment newfindnexttrain
	push edi
	call runindex(realtrain)
	jnz short .exit
	cmp bh,[edi+veh.owner]
	jnz short .exit
	mov edi,[edi+veh.veh2ptr]
	mov edi,[edi+veh2.sortvar]
	cmp edi,edi
	setfragmentsize 22
.exit:

codefragment oldnextveh
	add edi,vehiclesize
	cmp edi, [veharrayendptr]

codefragment newnextveh
	pop edi
	sub edi,byte -vehiclesize
	cmp edi,[veharrayendptr]
	setfragmentsize 12

codefragment oldfindnextrv,-9
	mov ax,[esi+window.id]
	cmp al,[edi+veh.owner]

codefragment newfindnextrv
	push edi
	mov al,0x11
	call runindex(vehiclevalid)
	setfragmentsize 16

reusecodefragment oldfindnextship,oldfindnextrv

codefragment newfindnextship
	push edi
	mov al,0x12
	call runindex(vehiclevalid)
	setfragmentsize 16

reusecodefragment oldfindnextaircraft,oldfindnextrv,-19

codefragment newfindnextaircraft
	push edi
	mov al,0x13
	call runindex(vehiclevalid)
	setfragmentsize 26

codefragment oldclicktrainlist,3
	mov ah,[esi+window.id]
	cmp byte [edi+veh.class],0x10

codefragment newclicktrainlist
	call runindex(clicklist_next_train)
	setfragmentsize 18
	db 0x72

codefragment oldclickrvlist,3
	mov ah,[esi+window.id]
	cmp byte [edi+veh.class],0x11

codefragment newclickrvlist
	call runindex(clicklist_next_rv)
	setfragmentsize 12
	db 0x72

codefragment oldclickshiplist,3
	mov ah,[esi+window.id]
	cmp byte [edi+veh.class],0x12

codefragment newclickshiplist
	call runindex(clicklist_next_ship)
	setfragmentsize 12
	db 0x72

codefragment oldclickaircraftlist,3
	mov ah,[esi+window.id]
	cmp byte [edi+veh.class],0x13

codefragment newclickaircraftlist
	call runindex(clicklist_next_aircraft)
	setfragmentsize 18
	db 0x72

codefragment oldemptybuttontrain,2
	dw 0x8815	// new vehicles
	db cWinElemSpriteBox
	db cColorSchemeGrey

codefragment oldemptybuttonroad,2
	dw 0x9004	// new vehicles
	db cWinElemSpriteBox
	db cColorSchemeGrey

codefragment oldemptybuttonship,2
	dw 0x9804	// new ships
	db cWinElemSpriteBox
	db cColorSchemeGrey

codefragment oldemptybuttonair,2
	dw 0xa003	// new aircraft
	db cWinElemSpriteBox
	db cColorSchemeGrey

codefragment oldclicktrainlistwindow
	js near $+6+0x33a+0x10*WINTTDX

codefragment newclicklistwindow
	call runindex(clicklistwindow)

codefragment oldlistwindowhint,-6
	movzx ebx,cx
	db 0x66, 0x8b, 0x04, 0x5d	// mov ax,[???+2*ebx]

codefragment newlistwindowhint
	call runindex(listwindowhint)

codefragment oldclickrvlistwindow
	js near $+6+0x310+0x9*WINTTDX

codefragment oldclickshiplistwindow
	js near $+6+0x3e1+0xc*WINTTDX

codefragment oldclickaircraftlistwindow
	js near $+6+0x3e5+0xb*WINTTDX

codefragment oldemptyhinttrain,2
	dw 0x883e
	dw 0
	db 3,14

codefragment newemptyhint
	dw ourtext(sorthint)

codefragment oldemptyhintroad,2
	dw 0x901b
	dw 0
	db 3,14

codefragment oldemptyhintship,2
	dw 0x9824
	dw 0
	db 3,14

codefragment oldemptyhintair,2
	dw 0xa020
	dw 0
	db 3,7

codefragment oldlistguitimer,5
	pop dx
	cmp dl,5
	jne $+2+0x17
	btr dword [esi+window.activebuttons],4

codefragment newlistguitimer
	call runindex(listguitimer)
	setfragmentsize 9

codefragment oldsetvehlisttext,3
	mov ax,[ebx]
	mov [textrefstack],ax
	mov eax,[ebx+2]
	mov [textrefstack+2],eax
	db 0xe8	// call DrawWindowElements

codefragment newsetvehlisttext
	call runindex(setvehlisttext)

codefragment oldislistwindowhuman,2
	push dx
	cmp dl,[human1]

codefragment newislistwindowhuman
	setfragmentsize 8

codefragment oldcreatelistwindow1,2
	pop dx
	mov [esi+window.id],dx
	mov [esi+window.company],dl
	mov byte [esi+window.itemsvisible],7

codefragment newcreatelistwindow
	extern createlistwindow
	push createlistwindow
	setfragmentsize 7

codefragment oldcreatelistwindow2,2
	pop dx
	mov [esi+window.id],dx
	mov [esi+window.company],dl
	mov byte [esi+window.itemsvisible],4

codefragment olddelveharrayentry,11
	push ebp
	mov ax,[esi+veh.name]

codefragment newdelveharrayentry
	call runindex(delveharrayentry_sort)
	setfragmentsize 8

codefragment oldnewveharrayentry
	mov word [esi+0x2a],0x8000

codefragment newnewveharrayentry
	call runindex(newveharrayentry_sort)

// --- End of vehicle list sorting fragments ---

// --- Start of more than 256 trains in list fragments

codefragment trainlistfragment
	//Std address: American: DOS:_CS:001645A9,Win:005765C0
	db 0x72, 0xE0, 0x88, 0x66, 0x01, 0x2A, 0x66, 0x02, 0x73, 0x02, 0x32, 0xE4, 0x3A, 0x66, 0x03, 0x73, 0x03, 0x88, 0x66, 0x03, 0x0F, 0xB7, 0x5E, 0x06, 0x66, 0x69, 0xDB, 0xB2, 0x03
codefragment newTrainListDrawHandlerCountDecFunc
	icall TrainListDrawHandlerCountDec
	setfragmentsize 8
codefragment newTrainListDrawHandlerCountTrains
	icall TrainListDrawHandlerCountTrains
	setfragmentsize 6
//codefragment newTrainListDrawHandlerCountTrainsInc
//	inc ebx
//	setfragmentsize 2
codefragment newTrainListDrawHandlerCountTrainsXor
	xor ebx, ebx
	setfragmentsize 2
codefragment newTrainListClickHandlerAddOffset
	icall TrainListClickHandlerAddOffset
	setfragmentsize 9
//codefragment newTrainListClickHandlerAddOffsetDec
//	dec edx
//	setfragmentsize 2

// --- Start of more than 256 RVs in list fragments
codefragment rvlistfragment
	//Std address: American: DOS:_CS:00166890,Win:0053DCD5
	//also at 0057DE89, ship

	db 0x72, 0xE6, 0x88, 0x46, 0x01, 0x2A, 0x46, 0x02, 0x73, 0x02, 0x32, 0xC0, 0x3A, 0x46, 0x03, 0x73, 0x03, 0x88, 0x46, 0x03, 0x0F, 0xB7, 0x5E, 0x06, 0x66, 0x69, 0xDB, 0xB2, 0x03
codefragment newRVListDrawHandlerCountVehs
	icall RVListDrawHandlerCountVehs
	setfragmentsize 6
codefragment newRVListDrawHandlerCountDecFunc
	icall RVListDrawHandlerCountDec
	setfragmentsize 8

// --- Start of more than 256 Ships in list fragments
codefragment newShipListDrawHandlerCountDec
	icall ShipListDrawHandlerCountDec
	setfragmentsize 8

// --- Start of more than 256 Aircraft in list fragments
codefragment aircraftlistfragment
	//Std address: American: DOS:_CS:0016EC28,Win:53A7FE
	db 0x72, 0xE0, 0x88, 0x46, 0x01, 0x2A, 0x46, 0x02, 0x73, 0x02, 0x32, 0xC0, 0x3A, 0x46, 0x03, 0x73, 0x03, 0x88, 0x46, 0x03, 0x0F, 0xB7, 0x5E, 0x06, 0x66, 0x69, 0xDB, 0xB2, 0x03
codefragment newAircraftListDrawHandlerCountDec
	icall AircraftListDrawHandlerCountDec
	setfragmentsize 8

endcodefragments

ext_frag oldfindnexttrain

patchsortvehlist:


//JGR more than 256 trains in listing
	stringaddress trainlistfragment
	mov ebx, edi
	xor ecx, ecx
	add edi, 0x576635-0x5765C0
	copyrelative TrainListDrawHandlerCountDec.skip
	sub edi, 4
	storefragment newTrainListDrawHandlerCountDecFunc
	lea edi, [ebx+0x5765C2-0x5765C0]
	storefragment newTrainListDrawHandlerCountTrains
	//sub edi, 16
	//storefragment newTrainListDrawHandlerCountTrainsInc
	//sub edi, 22
	lea edi, [ebx+0x57659A-0x5765C0]
	storefragment newTrainListDrawHandlerCountTrainsXor
	lea edi, [ebx+0x57655F-0x5765C0]
	storefragment newTrainListClickHandlerAddOffset
	//add edi, 28
	//storefragment newTrainListClickHandlerAddOffsetDec
//ENDS
//JGR more than 256 RVs in listing
	stringaddress rvlistfragment, 1, 2
	mov ebx, edi
	xor ecx, ecx
	add edi, 0x53DD41-0x53DCD5
	copyrelative RVListDrawHandlerCountDec.skip
	sub edi, 4
	storefragment newRVListDrawHandlerCountDecFunc
	lea edi, [ebx+0x53DCD7-0x53DCD5]
	storefragment newRVListDrawHandlerCountVehs
	lea edi, [ebx+0x53DC7F-0x53DCD5]
	storefragment newTrainListClickHandlerAddOffset
//ENDS
//JGR more than 256 Ships in listing
	stringaddress rvlistfragment
	mov ebx, edi
	xor ecx, ecx
	add edi, 0x53DD41-0x53DCD5
	copyrelative ShipListDrawHandlerCountDec.skip
	sub edi, 4
	storefragment newShipListDrawHandlerCountDec
	lea edi, [ebx+0x53DCD7-0x53DCD5]
	storefragment newRVListDrawHandlerCountVehs
	lea edi, [ebx+0x53DC7F-0x53DCD5]
	storefragment newTrainListClickHandlerAddOffset
//ENDS
//JGR more than 256 Ships in listing
	stringaddress aircraftlistfragment
	mov ebx, edi
	xor ecx, ecx
	add edi, 0x53A874-0x53A7FE
	copyrelative AircraftListDrawHandlerCountDec.skip
	sub edi, 4
	storefragment newAircraftListDrawHandlerCountDec
	lea edi, [ebx+0x53A800-0x53A7FE]
	storefragment newRVListDrawHandlerCountVehs
	lea edi, [ebx+0x53A79C-0x53A7FE]
	storefragment newTrainListClickHandlerAddOffset
//ENDS

// do the ordering if necessary
	patchcode oldfindlisttrains,newfindlisttrains,1,1
	multipatchcode oldfindlistvehs,newfindlistvehs,3

// find the next vehicle to show in vehicle lists
	patchcode oldfindnexttrain,newfindnexttrain,1,1
	patchcode oldnextveh,newnextveh,1,0
	patchcode oldfindnextrv,newfindnextrv,1+WINTTDX,3
	patchcode oldnextveh,newnextveh,1,0
	patchcode oldfindnextship,newfindnextship,1+WINTTDX,2
	patchcode oldnextveh,newnextveh,1,0
	patchcode oldfindnextaircraft,newfindnextaircraft,1,1
	patchcode oldnextveh,newnextveh,1,0

// find the correct vehicle when clicking on an entry
	patchcode oldclicktrainlist, newclicktrainlist,1,1
	patchcode oldclickrvlist, newclickrvlist,1,1
	patchcode oldclickshiplist, newclickshiplist,1,1
	patchcode oldclickaircraftlist, newclickaircraftlist,1,1

// Modify the empty button in the veh. list windows to show our text
	mov ebx, vehlistwindowsizes
	stringaddress oldemptybuttontrain
	call .patchemptybutton
	stringaddress oldemptybuttonroad
	call .patchemptybutton
	stringaddress oldemptybuttonship
	call .patchemptybutton
	stringaddress oldemptybuttonair
	call .patchemptybutton

// Change the event handler so we can respond to clicking the new button
// The hint handler should also be modified
	patchcode oldclicktrainlistwindow,newclicklistwindow,1,1
	patchcode oldlistwindowhint,newlistwindowhint,1,0
	patchcode oldclickrvlistwindow,newclicklistwindow,1,1
	patchcode oldlistwindowhint,newlistwindowhint,1,0
	patchcode oldclickshiplistwindow,newclicklistwindow,1,1
	patchcode oldlistwindowhint,newlistwindowhint,1,0
	patchcode oldclickaircraftlistwindow,newclicklistwindow,1,1
	patchcode oldlistwindowhint,newlistwindowhint,1,0

// Change hints for the formerly empty button
	patchcode oldemptyhinttrain,newemptyhint,1,1
	patchcode oldemptyhintroad,newemptyhint,1,1
	patchcode oldemptyhintship,newemptyhint,1,1
	patchcode oldemptyhintair,newemptyhint,1,1

// install our timing routine
	multipatchcode oldlistguitimer,newlistguitimer,4
// fill textrefstack correctly to supply the caption of the new button
	multipatchcode oldsetvehlisttext,newsetvehlisttext,4
// show the two buttons on the bottom even for AI player windows...
	multipatchcode oldislistwindowhuman,newislistwindowhuman,4
//	(finished in patchdrawvehlist)

// make sure lists are reordered when deleting/creating vehicles
	patchcode olddelveharrayentry,newdelveharrayentry,1,1
	patchcode oldnewveharrayentry,newnewveharrayentry,1,1
	ret

// Create two buttons instead of the old empty button
// Since the second window (without buttons) is no longer used, we can use
// its space for the extra button.
.patchemptybutton:
	mov byte [edi+windowbox.type],cWinElemTextBox	// Change the empty button to a text button
	mov word [edi+windowbox.text],statictext(vehlist_sortbutton)	// set its caption
	mov ecx,0xd	// make a second copy of this button (copy the end marker, too)
.copyloop:
	mov al,[edi+ecx-1]
	mov [edi+ecx+0xc-1],al
	loop .copyloop

	mov ax,[edi+windowbox.x2]		// x2 of the old button
	sub ax,16
	mov [edi+windowbox.x2],ax		// make it 16 pixels shorter
	inc ax
	mov [edi+0xc+windowbox.x1],ax	// the new button goes to the remaining part
	mov word [edi+0xc+windowbox.text],statictext(vehlist_menubutton)	// Caption (downward pointing triangle)

	testmultiflags enhancegui
	jz .noresize
	mov byte [edi+2*12+windowbox.type], cWinElemSizer
	mov byte [edi+2*12+windowbox.bgcolor], cColorSchemeGrey
	add ax, 5
	mov word [edi+2*12+windowbox.x1], ax
	add ax, 10
	mov word [edi+2*12+windowbox.x2], ax
	mov ax, [edi+windowbox.y1]
	mov word [edi+2*12+windowbox.y1], ax
	mov ax, [edi+windowbox.y2]
	mov word [edi+2*12+windowbox.y2], ax
	sub word [edi+windowbox.x2], 11
	sub word [edi+12+windowbox.x1], 11
	sub word [edi+12+windowbox.x2], 11
	mov byte [edi+3*12+0], cWinElemExtraData
	mov byte [edi+3*12+1], cWinDataSizer
	mov dword [edi+3*12+2], vehlistwindowconstraints
	mov eax, [ebx]
	mov dword [edi+3*12+6], eax
	add ebx, 4
	mov byte [edi+4*12+windowbox.type], cWinElemLast
.noresize:
	ret

// ...but disable the "New Vehicles" button. Then apply the last selected
// sorting method and start the timer.
patchdrawvehlist:
	multipatchcode oldcreatelistwindow1,newcreatelistwindow,4
	multipatchcode oldcreatelistwindow2,newcreatelistwindow,4
	ret
