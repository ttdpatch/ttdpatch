#include <defs.inc>
#include <frag_mac.inc>


extern convertwaittime,patchflags,signal1waitdays,signal1waittime
extern signal2waitdays
extern signal2waittime


global patchsignalwaittime
patchsignalwaittime:
	patchcode oldtrainwaitforgreen1,newtrainwaitforgreen1,1,1
	patchcode oldtrainwaitforgreen2,newtrainwaitforgreen2,1,1

	// convert days to internal time units
	pusha
	testflags setsignal1waittime
	jnc short .waittime1set

	movzx edx,byte [signal1waitdays]
	mov cx,0x297c
	call convertwaittime
	mov word [signal1waittime],ax

.waittime1set:
	testflags setsignal2waittime
	jnc short .waittime2set

	movzx edx,byte [signal2waitdays]
	mov cx,0xf8e
	call convertwaittime
	mov word [signal2waittime],ax

.waittime2set:
	popa
	ret



begincodefragments

codefragment oldtrainwaitforgreen1
	cmp word [esi+veh.loadtime],0xfe
	db 0xf,0x83		// jae near...

codefragment newtrainwaitforgreen1
	call runindex(trainwaitforgreen1)
	db 0xf,0x87		// jae->ja

codefragment oldtrainwaitforgreen2
	cmp word [esi+veh.loadtime],0xfe
	db 0x73			// jae short...

codefragment newtrainwaitforgreen2
	call runindex(trainwaitforgreen2)
	db 0x77			// jae->ja


endcodefragments
