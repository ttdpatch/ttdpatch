#include <stdio.h>
#include <ctype.h>

#include <winsock2.h>
#include "asyncmpclient.h"

__declspec(dllexport) int ASNetworkStart()
{
	WSADATA wsaData;

	/* Open the Windows socket */
	if (WSAStartup(0x0002, &wsaData) != 0) {
		return -1;
	}
	return 0;
}


__declspec(dllexport) NetObj* ASClientConnect(char* ipaddressorhostname)
{
	unsigned long ip;
	SOCKADDR_IN sin;
	NetObj *pNetObj;
		
	sin.sin_family = AF_INET;
	sin.sin_port = htons(5555);
	
	ip = inet_addr(ipaddressorhostname);
	if (ip == INADDR_NONE) {
		HOSTENT* remoteHost;
		remoteHost = gethostbyname(ipaddressorhostname);
		/* Winsock doesn't seem to like to use compatible types, grr */
		ip = *((unsigned long*)remoteHost->h_addr_list[0]);
	}
	sin.sin_addr.s_addr = ip;
		
	pNetObj = malloc(sizeof(NetObj));
	if (!pNetObj) return NULL;
	pNetObj->error = 0;
	pNetObj->outbufferlen = 0;
	/* pNetObj->inbufferlen = 0; */
	pNetObj->inpackagelen = 0;
	
	pNetObj->socket = socket(AF_INET, SOCK_STREAM, 0);
	if (pNetObj->socket == INVALID_SOCKET) {
		pNetObj->error = WSAGetLastError();
		return pNetObj;
	}
	
	if (connect(pNetObj->socket, (SOCKADDR*) &sin, sizeof(sin)) == SOCKET_ERROR) {
		pNetObj->error = WSAGetLastError();
	}
	
	return pNetObj;
}

__declspec(dllexport) int ASClientDisconnect(NetObj *netobj)
{
	/* TODO: we should look for remaining data in the outbuffer atleast ! */
	if (netobj->socket != INVALID_SOCKET) {
		closesocket(netobj->socket);
		netobj->socket = INVALID_SOCKET;
	}
	return 0;
}
__declspec(dllexport) int ASClientFree(NetObj *netobj)
{
	/* Do try to free memory alloced by a dll in the main app, so we do it here... */
	free(netobj);
	return 0;
}

__declspec(dllexport) int ASClientSend(NetObj* netobj, char* buffer, int bufferlen)
{
	int res;
	if ( (netobj->outbufferlen + bufferlen) <= NetObjBufferSize) {
		memmove(netobj->outbuffer + netobj->outbufferlen, buffer, bufferlen);
		netobj->outbufferlen += bufferlen;
	} else {
		netobj->error = -1;
		return -1;
	}
	
	res = send(netobj->socket, netobj->outbuffer, netobj->outbufferlen, 0);
	if (res < 1) {
		netobj->error = WSAGetLastError();
		return -1;
	}
	
	if (netobj->outbufferlen - res > 0) {
		memmove(netobj->outbuffer, netobj->outbuffer+res, (netobj->outbufferlen - res) );
		netobj->outbufferlen -= res;
	} else {
		netobj->outbufferlen = 0;
	}
	return 0;
}

__declspec(dllexport) int ASClientSendDone(NetObj* netobj, int size, char* buffer)
{
	int res;
	/* Currently we send only our remaining data here */
	if (netobj->outbufferlen > 0) {
		while (netobj->outbufferlen > 0) {
			res = send(netobj->socket, netobj->outbuffer, netobj->outbufferlen, 0);
			if (res < 1) {
				netobj->error = WSAGetLastError();
				return -1;
			}
			if ((netobj->outbufferlen - res) > 0) {
				memmove(netobj->outbuffer, netobj->outbuffer+res, (netobj->outbufferlen - res));
				netobj->outbufferlen -= res;
			}
		}
		netobj->outbufferlen = 0;
	}
	return 0;
}

__declspec(dllexport) int ASClientReceive(NetObj* netobj, int buffersize, char* buffer)
{
	int recvret;
	int bufferpos = 0;
	
	if (netobj->inpackagelen < buffersize) {
		/* quite bad it seems host want more then data then it should */
		return -1;
	}
	while (bufferpos < buffersize) {
		recvret=recv(netobj->socket, buffer+bufferpos, buffersize-bufferpos, 0);
		if (recvret == SOCKET_ERROR) {
			netobj->error = WSAGetLastError();
			return -1;
		}
		if (recvret == 0) {
			/* The server left us */
			return -2;
		}
		bufferpos += recvret;
	}
	netobj->inpackagelen -= bufferpos; 
	if (netobj->inpackagelen < 1) return 0;	/* no more data to read */
	return netobj->inpackagelen;	/* return the remaining bytes */
}


__declspec(dllexport) int ASClientHasNewData(NetObj* netobj)
{
	TIMEVAL timeout; 
	fd_set fdSetRead;
	int selectret;
	int recvret;
	char buffer[sizeof(int)*2];	/* waste some bytes to not get a buffer overflow */
	int bufferpos = 0;
	/* first check if we have still data in an old package buffer, that would be a wrong use of API */
	if (netobj->inpackagelen > 0) return -1;

    timeout.tv_sec = 0; 
	timeout.tv_usec = 0;
	selectret = select(0,&fdSetRead,NULL,NULL,&timeout);
	if (selectret == SOCKET_ERROR) {
		netobj->error = WSAGetLastError();
		return -1;
	}
	if (selectret == 1) {
		/* we seem to have a new data package, get it's size */
		while (bufferpos < sizeof(int)) {
			recvret=recv(netobj->socket, buffer+bufferpos, sizeof(int) - bufferpos, 0);
			if (recvret == SOCKET_ERROR) {
				netobj->error = WSAGetLastError();
				return -1;
			}
			if (recvret == 0) {
				/* The server left us */
				return -2;
			}
			bufferpos += recvret;
		}
		netobj->inpackagelen = (int)buffer[0];
		return 1;
	}
	return 0;
}
