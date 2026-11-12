/* SPDX-License-Identifier: MIT */
#include <windows.h>
#include <wintrust.h>
#include <softpub.h>
#include <stdio.h>
#include <string.h>

typedef LONG (WINAPI *verify_fn)(HWND, GUID *, void *);

int main(int argc, char **argv)
{
    const int expect_success = argc == 2 && !strcmp(argv[1], "--expect-success");
    GUID action = WINTRUST_ACTION_GENERIC_VERIFY_V2;
    WINTRUST_FILE_INFO file = { sizeof(file) };
    WINTRUST_DATA data = { sizeof(data) };
    const WCHAR path[] = L"C:\\inventor-unsigned-test.txt";
    HMODULE module = LoadLibraryW(L"wintrust.dll");
    verify_fn verify, verify_ex;
    HANDLE output;
    DWORD written;
    LONG result, result_ex;
    if (!module) return 10;
    verify = (verify_fn)GetProcAddress(module, "WinVerifyTrust");
    verify_ex = (verify_fn)GetProcAddress(module, "WinVerifyTrustEx");
    if (!verify || !verify_ex) return 11;
    output = CreateFileW(path, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, 0, NULL);
    if (output == INVALID_HANDLE_VALUE) return 12;
    if (!WriteFile(output, "unsigned test\n", 14, &written, NULL)) return 13;
    CloseHandle(output);
    file.pcwszFilePath = path;
    data.dwUIChoice = WTD_UI_NONE;
    data.dwUnionChoice = WTD_CHOICE_FILE;
    data.pFile = &file;
    data.dwStateAction = WTD_STATEACTION_IGNORE;
    result = verify(NULL, &action, &data);
    result_ex = verify_ex(NULL, &action, &data);
    printf("Unsigned file: WinVerifyTrust=%08lx WinVerifyTrustEx=%08lx\n", result, result_ex);
    DeleteFileW(path);
    if (expect_success) return result || result_ex ? 1 : 0;
    return result && result_ex ? 0 : 2;
}
