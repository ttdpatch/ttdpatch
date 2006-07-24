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
	pNetObj->inbufferlen = 0;
	
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

__declspec(dllexport) int ASClientReceive()
{
	
	return 0;
}
