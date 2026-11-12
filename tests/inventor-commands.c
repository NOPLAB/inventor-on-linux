/* SPDX-License-Identifier: MIT */
#define COBJMACROS
#include <windows.h>
#include <ole2.h>
#include <oleauto.h>
#include <stdio.h>
#include <wchar.h>
#include <string.h>
#include <stdlib.h>
static HRESULT call(IDispatch *obj,WCHAR *name,WORD flags,VARIANT *args,UINT count,VARIANT *out)
{
 DISPID id,put=DISPID_PROPERTYPUT; EXCEPINFO ex={0}; UINT bad=0; HRESULT hr;
 DISPPARAMS dp={args,flags&DISPATCH_PROPERTYPUT?&put:NULL,count,flags&DISPATCH_PROPERTYPUT?1:0};
 VariantInit(out);hr=IDispatch_GetIDsOfNames(obj,&IID_NULL,&name,1,LOCALE_USER_DEFAULT,&id);
 if(SUCCEEDED(hr)) hr=IDispatch_Invoke(obj,id,&IID_NULL,LOCALE_USER_DEFAULT,flags,&dp,out,&ex,&bad);
 if(FAILED(hr)) {char label[256],message[2048];WideCharToMultiByte(CP_UTF8,0,name,-1,label,sizeof(label),NULL,NULL);fprintf(stderr,"Invoke %s hr=%08lx arg=%u\n",label,hr,bad);if(ex.bstrDescription){WideCharToMultiByte(CP_UTF8,0,ex.bstrDescription,-1,message,sizeof(message),NULL,NULL);fprintf(stderr,"%s\n",message);}}
 SysFreeString(ex.bstrSource);SysFreeString(ex.bstrDescription);SysFreeString(ex.bstrHelpFile);return hr;
}
static IDispatch *object(IDispatch *obj,WCHAR *name,WORD flags,VARIANT *args,UINT count)
{
 VARIANT out;if(FAILED(call(obj,name,flags,args,count,&out)) || V_VT(&out)!=VT_DISPATCH || !V_DISPATCH(&out)){fprintf(stderr,"Missing object\n");exit(20);}return V_DISPATCH(&out);
}
static VARIANT number(LONG n){VARIANT v;VariantInit(&v);V_VT(&v)=VT_I4;V_I4(&v)=n;return v;}
static VARIANT real(double n){VARIANT v;VariantInit(&v);V_VT(&v)=VT_R8;V_R8(&v)=n;return v;}
static VARIANT reference(IDispatch *p){VARIANT v;VariantInit(&v);V_VT(&v)=VT_DISPATCH;V_DISPATCH(&v)=p;return v;}
static void box(IDispatch *app)
{
 VARIANT a[3],out;IDispatch *docs,*doc,*cd,*planes,*plane,*sketches,*sketch,*tg,*p1,*p2,*lines,*profiles,*profile,*features,*extrudes,*def;
 docs=object(app,L"Documents",DISPATCH_PROPERTYGET,NULL,0);
 VariantInit(&a[0]);V_VT(&a[0])=VT_BOOL;V_BOOL(&a[0])=VARIANT_TRUE;
 VariantInit(&a[1]);V_VT(&a[1])=VT_BSTR;V_BSTR(&a[1])=SysAllocString(L"");a[2]=number(12290);
 doc=object(docs,L"Add",DISPATCH_METHOD,a,3);
 cd=object(doc,L"ComponentDefinition",DISPATCH_PROPERTYGET,NULL,0);
 planes=object(cd,L"WorkPlanes",DISPATCH_PROPERTYGET,NULL,0);a[0]=number(3);plane=object(planes,L"Item",DISPATCH_PROPERTYGET,a,1);
 sketches=object(cd,L"Sketches",DISPATCH_PROPERTYGET,NULL,0);a[0]=reference(plane);sketch=object(sketches,L"Add",DISPATCH_METHOD,a,1);
 tg=object(app,L"TransientGeometry",DISPATCH_PROPERTYGET,NULL,0);a[0]=real(0);a[1]=real(0);p1=object(tg,L"CreatePoint2d",DISPATCH_METHOD,a,2);
 a[0]=real(1);a[1]=real(2);p2=object(tg,L"CreatePoint2d",DISPATCH_METHOD,a,2);
 lines=object(sketch,L"SketchLines",DISPATCH_PROPERTYGET,NULL,0);a[0]=reference(p2);a[1]=reference(p1);object(lines,L"AddAsTwoPointRectangle",DISPATCH_METHOD,a,2);
 profiles=object(sketch,L"Profiles",DISPATCH_PROPERTYGET,NULL,0);profile=object(profiles,L"AddForSolid",DISPATCH_METHOD,NULL,0);
 features=object(cd,L"Features",DISPATCH_PROPERTYGET,NULL,0);extrudes=object(features,L"ExtrudeFeatures",DISPATCH_PROPERTYGET,NULL,0);
 a[0]=number(20481);a[1]=reference(profile);def=object(extrudes,L"CreateExtrudeDefinition",DISPATCH_METHOD,a,2);
 a[0]=number(20993);a[1]=real(1);if(FAILED(call(def,L"SetDistanceExtent",DISPATCH_METHOD,a,2,&out)))exit(21);
 a[0]=reference(def);object(extrudes,L"Add",DISPATCH_METHOD,a,1);puts("Created unsaved diagnostic block (20 x 10 x 10 mm)");
}
int main(int argc,char **argv)
{
 CLSID cls;IUnknown *unk;IDispatch *app,*mgr,*defs;VARIANT v,c,n,item;HRESULT hr;LONG i,count;
 setvbuf(stdout,NULL,_IONBF,0);
 CoInitialize(NULL);CLSIDFromProgID(L"Inventor.Application",&cls);
 hr=GetActiveObject(&cls,NULL,&unk);if(FAILED(hr)){printf("GetActiveObject=%08lx\n",hr);return 2;}
 hr=IUnknown_QueryInterface(unk,&IID_IDispatch,(void**)&app);IUnknown_Release(unk);if(FAILED(hr))return 3;
 if(argc>1 && !strcmp(argv[1],"--save-all")){VARIANT count,n,out,path;IDispatch *docs=object(app,L"Documents",DISPATCH_PROPERTYGET,NULL,0);call(docs,L"Count",DISPATCH_PROPERTYGET,NULL,0,&count);for(LONG j=1;j<=V_I4(&count);j++){n=number(j);IDispatch *doc=object(docs,L"Item",DISPATCH_PROPERTYGET,&n,1);if(FAILED(call(doc,L"FullFileName",DISPATCH_PROPERTYGET,NULL,0,&path)) || V_VT(&path)!=VT_BSTR || !SysStringLen(V_BSTR(&path))){fprintf(stderr,"Unsaved document requires a filename\n");return 30;}if(FAILED(call(doc,L"Save",DISPATCH_METHOD,NULL,0,&out)))return 31;}IDispatch *active=object(app,L"ActiveDocument",DISPATCH_PROPERTYGET,NULL,0);if(SUCCEEDED(call(active,L"FullFileName",DISPATCH_PROPERTYGET,NULL,0,&path))){char text[2048];WideCharToMultiByte(CP_UTF8,0,V_BSTR(&path),-1,text,sizeof(text),NULL,NULL);printf("%s\n",text);}return 0;}
 if(argc>1 && !strcmp(argv[1],"--fit")){VARIANT out;IDispatch *view=object(app,L"ActiveView",DISPATCH_PROPERTYGET,NULL,0);call(view,L"Fit",DISPATCH_METHOD,NULL,0,&out);return FAILED(call(view,L"Update",DISPATCH_METHOD,NULL,0,&out));}
 if(argc>1 && !strcmp(argv[1],"--state")){VARIANT out;char text[1024];IDispatch *ui=object(app,L"UserInterfaceManager",DISPATCH_PROPERTYGET,NULL,0),*env=object(ui,L"ActiveEnvironment",DISPATCH_PROPERTYGET,NULL,0);if(SUCCEEDED(call(env,L"InternalName",DISPATCH_PROPERTYGET,NULL,0,&out))){WideCharToMultiByte(CP_UTF8,0,V_BSTR(&out),-1,text,sizeof(text),NULL,NULL);printf("Environment=%s\n",text);}IDispatch *doc=object(app,L"ActiveDocument",DISPATCH_PROPERTYGET,NULL,0);if(SUCCEEDED(call(doc,L"DisplayName",DISPATCH_PROPERTYGET,NULL,0,&out))){WideCharToMultiByte(CP_UTF8,0,V_BSTR(&out),-1,text,sizeof(text),NULL,NULL);printf("Document=%s\n",text);}return 0;}
 if(argc>2 && !strcmp(argv[1],"--save")){VARIANT a[2],out;WCHAR path[1024];MultiByteToWideChar(CP_UTF8,0,argv[2],-1,path,1024);IDispatch *doc=object(app,L"ActiveDocument",DISPATCH_PROPERTYGET,NULL,0);VariantInit(&a[0]);V_VT(&a[0])=VT_BOOL;V_BOOL(&a[0])=VARIANT_FALSE;VariantInit(&a[1]);V_VT(&a[1])=VT_BSTR;V_BSTR(&a[1])=SysAllocString(path);hr=call(doc,L"SaveAs",DISPATCH_METHOD,a,2,&out);printf("SaveAs=%08lx\n",hr);return FAILED(hr);}
 if(argc>1 && (!strcmp(argv[1],"--activate")||!strcmp(argv[1],"--activate-first"))){VARIANT count,n,out;IDispatch *docs=object(app,L"Documents",DISPATCH_PROPERTYGET,NULL,0);call(docs,L"Count",DISPATCH_PROPERTYGET,NULL,0,&count);printf("Documents=%ld\n",V_I4(&count));n=number(!strcmp(argv[1],"--activate-first")?1:V_I4(&count));IDispatch *doc=object(docs,L"Item",DISPATCH_PROPERTYGET,&n,1);return FAILED(call(doc,L"Activate",DISPATCH_METHOD,NULL,0,&out));}
 if(argc>1 && !strcmp(argv[1],"--show")){VARIANT a,out;VariantInit(&a);V_VT(&a)=VT_BOOL;V_BOOL(&a)=VARIANT_TRUE;return FAILED(call(app,L"Visible",DISPATCH_PROPERTYPUT,&a,1,&out));}
 if(argc>1 && !strcmp(argv[1],"--box")){box(app);return 0;}
 if(FAILED(call(app,L"CommandManager",DISPATCH_PROPERTYGET,NULL,0,&v)))return 4;mgr=V_DISPATCH(&v);
 if(FAILED(call(mgr,L"ControlDefinitions",DISPATCH_PROPERTYGET,NULL,0,&v)))return 5;defs=V_DISPATCH(&v);
 if(argc>1){
  WCHAR name[256];MultiByteToWideChar(CP_UTF8,0,argv[1],-1,name,256);VariantInit(&n);V_VT(&n)=VT_BSTR;V_BSTR(&n)=SysAllocString(name);
  if(FAILED(call(defs,L"Item",DISPATCH_PROPERTYGET,&n,1,&item)))return 6;
  if(SUCCEEDED(call(V_DISPATCH(&item),L"Enabled",DISPATCH_PROPERTYGET,NULL,0,&v)))printf("Enabled=%d\n",V_BOOL(&v));
  hr=call(V_DISPATCH(&item),L"Execute",DISPATCH_METHOD,NULL,0,&v);printf("Execute=%08lx\n",hr);return FAILED(hr);
 }
 if(FAILED(call(defs,L"Count",DISPATCH_PROPERTYGET,NULL,0,&c)))return 7;
 count=V_I4(&c);printf("Control definitions=%ld\n",count);
 for(i=1;i<=count;i++){
  VariantInit(&n);V_VT(&n)=VT_I4;V_I4(&n)=i;
  if(FAILED(call(defs,L"Item",DISPATCH_PROPERTYGET,&n,1,&item)))continue;
  if(SUCCEEDED(call(V_DISPATCH(&item),L"InternalName",DISPATCH_PROPERTYGET,NULL,0,&v))){
   char text[1024]; WideCharToMultiByte(CP_UTF8,0,V_BSTR(&v),-1,text,sizeof(text),NULL,NULL);
   if(strstr(text,"Stress")||strstr(text,"FEA")||strstr(text,"Fea")||strstr(text,"NewPart")||strstr(text,"Mesh")||strstr(text,"Simulate")) printf("%s\n",text);
   VariantClear(&v);
  } VariantClear(&item);
 }
 IDispatch_Release(defs);IDispatch_Release(mgr);IDispatch_Release(app);CoUninitialize();return 0;
}
