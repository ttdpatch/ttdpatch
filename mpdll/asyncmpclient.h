#include <winsock.h>
#include <winsock2.h>

#define NetObjBufferSize 2048
typedef struct {
	SOCKET socket;
	int error;
/*  currently we use the buffer from our host app
	char inbuffer[NetObjBufferSize+4];
	int inbufferlen;
*/
	int inpackagelen;
	char outbuffer[NetObjBufferSize+4];
	int outbufferlen;
} NetObj;
