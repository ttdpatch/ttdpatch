// noregist.c : Wrap some ADVAPI32 functions into ones that don't use the registry
//
// used both by patch loader (windows.c) and patch code (patches/noregist.asm)
//
// Copyright (C) 2006 by Josef Drexler, distributed under GPL
//

#include <stdio.h>
#include <ctype.h>

#include <windows.h>
#include <shlwapi.h>

int numkeys = 0;
char *keys[32];

const char *bases[] = { "CR", "CU", "LM", "U", "PD", "CC", "DD" };

char *filename = NULL;
const char *basefilename = "registry.ini";

int makefilename(HANDLE module)
{
	char dllname[1024];

	GetModuleFileName(module, dllname, 1022-strlen(basefilename));
	PathRemoveFileSpec(dllname);
	strcat(dllname, "/");
	strcat(dllname, basefilename);
	filename = strdup(dllname);
	return 1;
}

char *getreginifilename()
{
	if (!filename) makefilename(NULL);
	return filename;
}

__declspec(dllexport) LONG WINAPI fake_RegCloseKey(HKEY key)
{
	return ERROR_SUCCESS;
}

__declspec(dllexport) LONG WINAPI fake_RegOpenKeyA(HKEY key, LPCSTR subkey, PHKEY result)
{
	int i;
	int keylen;
	char *keyname;

	if ((numkeys >= 32) | (key < HKEY_CLASSES_ROOT) | (key > HKEY_DYN_DATA))
		return ERROR_ACCESS_DENIED;

	keylen = 6 + strlen(subkey);
	keyname = malloc(keylen + 1);
	snprintf(keyname, keylen, "HK%s_%s", bases[(int)key-(int)HKEY_CLASSES_ROOT], subkey);

	for (i=0; keyname[i]; i++) {
		if (!isalnum(keyname[i]))
			keyname[i] = '_';
	}

	keys[numkeys] = keyname;
	*result = (void*) numkeys++;
	return ERROR_SUCCESS;
}

__declspec(dllexport) LONG WINAPI fake_RegQueryValueExA(HKEY key, LPCSTR value,
			LPDWORD reserved, LPDWORD type, LPBYTE data, LPDWORD cbdata)
{
	char keyval[1024];
	DWORD val;
	int ret;
	int len;

	if (!filename) makefilename(NULL);
	ret = GetPrivateProfileString(keys[(int)key], value, NULL, keyval, 1024, filename);
	if (!ret)
		return ERROR_ACCESS_DENIED;

	switch (keyval[0]) {
		case 'D':
			val = atol(keyval+1);
			len = 4;
			if (data) {
				memcpy(data, &val, *cbdata);
				if (*cbdata > 4) *cbdata = 4;
			} else if (cbdata)
				*cbdata = 4;
			if (type)
				*type = REG_DWORD;
			break;

		case 'S':
			if (data) {
				strncpy(data, keyval+1, *cbdata);
				*cbdata = strlen(data)+1;
			} else if (cbdata)
				*cbdata = strlen(keyval)+1;
			if (type)
				*type = REG_SZ;
			break;

		default:
			return ERROR_ACCESS_DENIED;		
	}

	return ERROR_SUCCESS;
}

__declspec(dllexport) LONG WINAPI fake_RegSetValueExA(HKEY key,LPCSTR value,
			DWORD reserved, DWORD type, const BYTE* data ,DWORD cbdata)
{
	char keyval[1024];
	int ret;

	switch (type) {
		case REG_DWORD:
			snprintf(keyval, 1023, "D%ld", *(PDWORD) data);
			break;

		case REG_SZ:
			snprintf(keyval, 1023, "S%s", data);
			break;

		default:
			return ERROR_ACCESS_DENIED;
	}

	ret = WritePrivateProfileString(keys[(int)key], value, keyval, filename);
	if (!ret)
		return ERROR_ACCESS_DENIED;

	return ERROR_SUCCESS;
}

