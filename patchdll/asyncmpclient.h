#include <winsock.h>
#include <winsock2.h>

#define NetObjBufferSize 2048
typedef struct {
	SOCKET socket;
	int error;
	char inbuffer[NetObjBufferSize+4];
	int inbufferlen;
	char outbuffer[NetObjBufferSize+4];
	int outbufferlen;
} NetObj;
