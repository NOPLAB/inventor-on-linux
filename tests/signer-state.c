/* SPDX-License-Identifier: MIT */
#include <windows.h>
#include <wintrust.h>
#include <softpub.h>
#include <stdio.h>

typedef LONG (WINAPI *verify_fn)(HWND, GUID *, void *);
typedef CRYPT_PROVIDER_DATA *(WINAPI *state_fn)(HANDLE);
typedef CRYPT_PROVIDER_SGNR *(WINAPI *signer_fn)(CRYPT_PROVIDER_DATA *, DWORD, BOOL, DWORD);

int main(int argc, char **argv)
{
    WCHAR path[32768];
    GUID action = WINTRUST_ACTION_GENERIC_VERIFY_V2;
    WINTRUST_FILE_INFO file = {sizeof(file)};
    WINTRUST_DATA data = {sizeof(data)};
    HMODULE module = LoadLibraryW(L"wintrust.dll");
    verify_fn verify;
    state_fn state;
    signer_fn signer;
    CRYPT_PROVIDER_DATA *provider;
    CRYPT_PROVIDER_SGNR *signed_by;
    LONG hr;
    int valid;
    if (argc != 2 || !module) return 10;
    if (!MultiByteToWideChar(CP_UTF8, 0, argv[1], -1, path, 32768)) return 11;
    verify = (verify_fn)GetProcAddress(module, "WinVerifyTrust");
    state = (state_fn)GetProcAddress(module, "WTHelperProvDataFromStateData");
    signer = (signer_fn)GetProcAddress(module, "WTHelperGetProvSignerFromChain");
    if (!verify || !state || !signer) return 12;
    file.pcwszFilePath = path;
    data.dwUIChoice = WTD_UI_NONE;
    data.dwUnionChoice = WTD_CHOICE_FILE;
    data.pFile = &file;
    data.dwStateAction = WTD_STATEACTION_VERIFY;
    hr = verify(NULL, &action, &data);
    provider = data.hWVTStateData ? state(data.hWVTStateData) : NULL;
    signed_by = provider ? signer(provider, 0, FALSE, 0) : NULL;
    valid = !hr && signed_by && signed_by->csCertChain && signed_by->pasCertChain[0].pCert;
    printf("WinVerifyTrust=%08lx provider=%p signer=%p certificates=%lu\n",
           hr, provider, signed_by, signed_by ? signed_by->csCertChain : 0);
    data.dwStateAction = WTD_STATEACTION_CLOSE;
    verify(NULL, &action, &data);
    return valid ? 0 : 1;
}
