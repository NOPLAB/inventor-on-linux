/* SPDX-License-Identifier: MIT */
#include <windows.h>
#include <stdio.h>
typedef int (WINAPI *format_fn)(unsigned long long,char*,size_t,const char*,void*,__builtin_ms_va_list);
typedef void* (WINAPI *locale_fn)(int,const char*);
static int WINAPIV format(format_fn fn,unsigned long long options,char *out,size_t size,const char *fmt,void *locale,...)
{
 __builtin_ms_va_list args;int r;__builtin_ms_va_start(args,locale);r=fn(options,out,size,fmt,locale,args);__builtin_ms_va_end(args);return r;
}
int main(void)
{
 HMODULE dll=LoadLibraryA("ucrtbase.dll");format_fn fn=(void*)GetProcAddress(dll,"__stdio_common_vsprintf_s");locale_fn loc=(void*)GetProcAddress(dll,"_create_locale");void *locale=loc(0,"C");char b[30];int i,r;
 for(i=0;i<8;i++){b[0]=0;r=format(fn,i,b,sizeof(b),"%.8g",locale,0.01);printf("options=%d result=%d text=[%s]\n",i,r,b);}
 return 0;
}
