// dllmain.cpp : Implementierung von DllMain.

#include "stdafx.h"
#include "resource.h"
#include "ShellExtension_i.h"
#include "dllmain.h"

CShellExtensionModule _AtlModule;

// DLL-Einstiegspunkt
extern "C" BOOL WINAPI DllMain(HINSTANCE hInstance, DWORD dwReason, LPVOID lpReserved)
{
	hInstance;
	return _AtlModule.DllMain(dwReason, lpReserved); 
}
