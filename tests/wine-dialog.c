/* SPDX-License-Identifier: MIT */
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static void text_utf8(HWND h,char *out,int size){WCHAR w[512];SendMessageW(h,WM_GETTEXT,512,(LPARAM)w);WideCharToMultiByte(CP_UTF8,0,w,-1,out,size,NULL,NULL);}
static BOOL CALLBACK child(HWND h,LPARAM unused){char title[2048],cls[128];text_utf8(h,title,sizeof(title));GetClassNameA(h,cls,sizeof(cls));printf(" child=%p id=%d class=%s text=%s\n",h,GetDlgCtrlID(h),cls,title);return TRUE;}
static BOOL CALLBACK window(HWND h,LPARAM unused){char title[2048],cls[128];if(!IsWindowVisible(h))return TRUE;GetClassNameA(h,cls,sizeof(cls));if(strcmp(cls,"#32770") && !GetDlgItem(h,IDOK))return TRUE;text_utf8(h,title,sizeof(title));printf("DIALOG=%p title=%s\n",h,title);EnumChildWindows(h,child,0);return TRUE;}
int main(int argc,char **argv){
 if(argc==1){EnumWindows(window,0);return 0;}
 if(argc<4)return 2;HWND h=(HWND)(ULONG_PTR)strtoull(argv[2],NULL,16);HWND control=GetDlgItem(h,atoi(argv[3]));if(!control)return 3;
 if(!strcmp(argv[1],"click")){SendMessageW(control,BM_CLICK,0,0);return 0;}
 if(!strcmp(argv[1],"set")&&argc==5){WCHAR value[1024];MultiByteToWideChar(CP_UTF8,0,argv[4],-1,value,1024);SendMessageW(control,WM_SETTEXT,0,(LPARAM)value);return 0;}
 return 4;
}
