#include <defs.inc>
#include <frag_mac.inc>
#include <window.inc>
#include <view.inc>
#include <patchproc.inc>

patchproc morewindows, patchmorewindows

extern malloccrit,newwindowcount,viewsarray
extern windowstack

begincodefragments

codefragment loadwindowstack_esi,1
	mov esi,windowstack_default

codefragment loadwindowstack_edi,1
	mov edi,windowstack_default

codefragment comparewindowstack_esi,2
	cmp esi,windowstack_default

codefragment comparewindowstack_edi,2
	cmp edi,windowstack_default

codefragment emptywindowstackss,7
	mov dword [ss:windowstacktop],windowstack_default

codefragment emptywindowstack,6
	mov dword [windowstacktop],windowstack_default

codefragment loadwindowstack_negative,1
	mov edi,windowstack_default-window_size

codefragment coparewindowstack_almosttop,2
	cmp esi,windowstack_default+9*window_size

codefragment coparewindowstack_top,2
	cmp esi,windowstack_default+10*window_size

codefragment preparesavewindows,1
	mov ecx,10*window_size
	sub esp,ecx

codefragment preparerestorewindows,1
	mov ecx,10*window_size
	mov edx,ecx

codefragment viewcount1,7
	mov esi,viewsarray_default
	mov cx,8

codefragment viewcount2,9
	mov esi,viewsarray_default
	push cx
	mov cx,8

codefragment preparesaveviews,1
	mov ecx,8*view_size
	sub esp,ecx

codefragment preparerestoreviews,1
	mov ecx,8*view_size
	mov edx,ecx

codefragment loadviewstack_esi,1
	mov esi,viewsarray_default

codefragment loadviewstack_edi,1
	mov edi,viewsarray_default


endcodefragments


patchmorewindows:
	movzx ebx,byte [newwindowcount]
	imul ebp,ebx,window_size
	push ebp
	call malloccrit
	pop dword [windowstack]
	multichangeloadedvalue loadwindowstack_esi,19,d,windowstack
	multichangeloadedvalue loadwindowstack_edi,4,d,windowstack
	multichangeloadedvalue comparewindowstack_esi,7,d,windowstack
	changeloadedvalue comparewindowstack_edi,2,2,d,windowstack
	changeloadedvalue emptywindowstackss,1,1,d,windowstack
	changeloadedvalue emptywindowstack,1,1,d,windowstack
	push dword [windowstack]
	sub dword [esp],window_size
	changeloadedvalue loadwindowstack_negative,1,1,d,esp
	add [esp],ebp
	changeloadedvalue coparewindowstack_almosttop,1,1,d,esp
	add dword [esp],window_size
	changeloadedvalue coparewindowstack_top,1,1,d,esp
	mov [esp],ebp
	changeloadedvalue preparesavewindows,1,1,d,esp
	changeloadedvalue preparerestorewindows,1,1,d,esp
	sub ebx,2
	imul ebp,ebx,view_size
	push ebp
	call malloccrit
	pop dword [viewsarray]
	mov [esp],ebx
	multichangeloadedvalue viewcount1,2,w,esp
	changeloadedvalue viewcount2,1,1,w,esp
	mov [esp],ebp
	changeloadedvalue preparesaveviews,1,1,d,esp
	changeloadedvalue preparerestoreviews,1,1,d,esp
	mov ebp,[viewsarray]
	add [esp],ebp
	changeloadedvalue comparewindowstack_edi,1,1,d,esp
	pop eax
	multichangeloadedvalue loadviewstack_esi,5,d,viewsarray
	changeloadedvalue loadviewstack_edi,1,1,d,viewsarray
	ret
