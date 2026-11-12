/* SPDX-License-Identifier: MIT */
#define COBJMACROS
#include <windows.h>
#include <ole2.h>
#include <oleauto.h>
#include <initguid.h>
#include <msxml2.h>
#include <stdio.h>
#include <string.h>
static int run(const WCHAR *progid,int replacement)
{
 CLSID cls;IXMLDOMDocument2 *doc;IXMLDOMElement *root;IXMLDOMNamedNodeMap *attrs;IXMLDOMAttribute *attr;IXMLDOMNode *out=NULL;VARIANT value;VARIANT_BOOL loaded;BSTR xml,name;char text[512];HRESULT hr;
 CoInitialize(NULL);CLSIDFromProgID(progid,&cls);
 hr=CoCreateInstance(&cls,NULL,CLSCTX_INPROC_SERVER,&IID_IXMLDOMDocument2,(void**)&doc);if(FAILED(hr)){printf("CoCreate=%08lx\n",hr);return 2;}
 xml=SysAllocString(replacement ? L"<contactsSettings tolerance=\"\"/>" : L"<contactsSettings/>");IXMLDOMDocument2_loadXML(doc,xml,&loaded);SysFreeString(xml);
 IXMLDOMDocument2_get_documentElement(doc,&root);IXMLDOMElement_get_attributes(root,&attrs);
 name=SysAllocString(L"tolerance");IXMLDOMDocument2_createAttribute(doc,name,&attr);SysFreeString(name);
 hr=IXMLDOMNamedNodeMap_setNamedItem(attrs,(IXMLDOMNode*)attr,&out);printf("setNamedItem=%08lx returned=%s\n",hr,out?"node":"NULL");
 if(out){VariantInit(&value);V_VT(&value)=VT_BSTR;V_BSTR(&value)=SysAllocString(L"0.0001");IXMLDOMNode_put_nodeValue(out,value);VariantClear(&value);IXMLDOMNode_Release(out);}
 IXMLDOMDocument2_get_xml(doc,&xml);WideCharToMultiByte(CP_UTF8,0,xml,-1,text,sizeof(text),NULL,NULL);printf("%s\n",text);
 int ok=strstr(text,"tolerance=\"0.0001\"")!=NULL;SysFreeString(xml);IXMLDOMAttribute_Release(attr);IXMLDOMNamedNodeMap_Release(attrs);IXMLDOMElement_Release(root);IXMLDOMDocument2_Release(doc);CoUninitialize();return ok?0:1;
}

int main(void)
{
 int failed=0;
 const WCHAR *versions[]={L"Msxml2.DOMDocument.3.0",L"Msxml2.DOMDocument.6.0"};
 for(int i=0;i<2;i++)for(int replacement=0;replacement<2;replacement++){printf("MSXML %d: %s attribute\n",i?6:3,replacement?"replace":"insert");failed |= run(versions[i],replacement);}
 return failed;
}
