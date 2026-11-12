/* SPDX-License-Identifier: MIT */
#include <windows.h>
#include <stdio.h>
/* Wine's COM-server activation-context data begins with size, flags, model. */
int main(void)
{
    static const GUID clsid={0xe4e2fe54,0x5a90,0x4006,{0xac,0x58,0x9e,0x11,0xde,0x19,0x81,0x7b}};
    WCHAR manifest[MAX_PATH];
    ACTCTXW ctx={sizeof(ctx)};
    ACTCTX_SECTION_KEYED_DATA data={sizeof(data)};
    HANDLE handle; ULONG_PTR cookie; DWORD model;
    if (!GetFullPathNameW(L"tests\\free-threaded.manifest", MAX_PATH, manifest, NULL)) return 5;
    ctx.lpSource=manifest;
    handle=CreateActCtxW(&ctx);
    if(handle==INVALID_HANDLE_VALUE) { printf("CreateActCtx error=%lu\n",GetLastError());return 2; }
    if(!ActivateActCtx(handle,&cookie)) return 3;
    if(!FindActCtxSectionGuid(0,NULL,ACTIVATION_CONTEXT_SECTION_COM_SERVER_REDIRECTION,&clsid,&data)) return 4;
    model=((DWORD*)data.lpData)[2];
    printf("lowercase threadingModel=free resolves to %lu (expected 2)\n",model);
    DeactivateActCtx(0,cookie);ReleaseActCtx(handle);
    return model==2 ? 0 : 1;
}
