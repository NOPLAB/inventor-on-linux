/* SPDX-License-Identifier: MIT */
#include <windows.h>
#include <stdio.h>

typedef HRESULT (WINAPI *factory_fn)(unsigned int, void **);
typedef HRESULT (WINAPI *stream_fn)(const WCHAR *, BOOL, void **);
typedef HRESULT (WINAPI *reader_fn)(void *, void *, void **);

int main(int argc, char **argv)
{
    WCHAR dll[32768], package[32768];
    HMODULE module;
    factory_fn factory;
    stream_fn stream;
    reader_fn read_package;
    void *f = NULL, *s = NULL, *reader = NULL;
    HRESULT hr;
    if (argc != 3) { fprintf(stderr, "Usage: msix-probe <Windows DLL path> <Windows ADIX path>\n"); return 10; }
    if (!MultiByteToWideChar(CP_UTF8, 0, argv[1], -1, dll, 32768) ||
        !MultiByteToWideChar(CP_UTF8, 0, argv[2], -1, package, 32768)) return 11;
    module = LoadLibraryW(dll);
    if (!module) { printf("LoadLibrary error=%lu\n", GetLastError()); return 12; }
    factory = (factory_fn)GetProcAddress(module, "CoCreateAppxFactory");
    stream = (stream_fn)GetProcAddress(module, "CreateStreamOnFileUTF16");
    if (!factory || !stream) return 13;
    hr = factory(0, &f); /* Default signature validation; no skip flags. */
    printf("Factory HRESULT=%08lx\n", hr);
    if (hr) return 1;
    hr = stream(package, TRUE, &s);
    printf("Stream HRESULT=%08lx\n", hr);
    if (hr) return 2;
    read_package = (reader_fn)((*(void ***)f)[4]);
    hr = read_package(f, s, &reader);
    printf("CreatePackageReader HRESULT=%08lx\n", hr);
    return hr ? 3 : 0;
}
