/* SPDX-License-Identifier: MIT */
#define COBJMACROS
#include <windows.h>
#include <oleauto.h>
#include <stdio.h>
#include <string.h>
int main(void)
{
 ITypeLib *lib;UINT count,i;HRESULT hr;int found=0,ok=0;
 hr=LoadTypeLibEx(L"C:\\Program Files\\Autodesk\\Inventor 2027\\Bin\\RxInventorImpl.impl",REGKIND_NONE,&lib);
 if(FAILED(hr)){printf("LoadTypeLibEx=%08lx\n",hr);return 2;}
 count=ITypeLib_GetTypeInfoCount(lib);
 for(i=0;i<count;i++){
  BSTR name=NULL;char text[512];ITypeInfo *info;TYPEATTR *attr;UINT j;
  if(FAILED(ITypeLib_GetDocumentation(lib,i,&name,NULL,NULL,NULL)))continue;
  WideCharToMultiByte(CP_UTF8,0,name,-1,text,sizeof(text),NULL,NULL);SysFreeString(name);
  if(strcmp(text,"PartDocument"))continue;
  ITypeLib_GetTypeInfo(lib,i,&info);ITypeInfo_GetTypeAttr(info,&attr);
  for(j=0;j<attr->cFuncs;j++){
   FUNCDESC *fn;if(FAILED(ITypeInfo_GetFuncDesc(info,j,&fn)))continue;
   BSTR fname=NULL; char ftext[512]={0};
   ITypeInfo_GetDocumentation(info,fn->memid,&fname,NULL,NULL,NULL);
   if(fname){WideCharToMultiByte(CP_UTF8,0,fname,-1,ftext,sizeof(ftext),NULL,NULL);SysFreeString(fname);}
   if(fn->memid==0x5000102 && fn->invkind==INVOKE_PROPERTYGET){
    TYPEDESC *td=fn->cParams ? &fn->lprgelemdescParam[0].tdesc : &fn->elemdescFunc.tdesc;int depth=0;
    printf("PartDocument.ComponentDefinition return type:");found=1;
    while(td && depth++<6){printf(" %u",td->vt);if(td->vt!=VT_PTR)break;td=td->lptdesc;}
    puts("");ok=td&&(td->vt==VT_USERDEFINED||td->vt==VT_DISPATCH);
   } ITypeInfo_ReleaseFuncDesc(info,fn);
  } ITypeInfo_ReleaseTypeAttr(info,attr);ITypeInfo_Release(info);break;
 }
 ITypeLib_Release(lib);return found&&ok?0:1;
}
