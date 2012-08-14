// test.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include <windows.h>

int _tmain(int argc, _TCHAR* argv[])
{
	SetErrorMode(1);
	WCHAR sThisDir[MAX_PATH]; // in atlstr.h
	/*
	WNDCLASSEX wcex;
    memset(&wcex, 0, sizeof(WNDCLASSEX));
    wcex.cbSize = sizeof(WNDCLASSEX);
    wcex.lpfnWndProc    = TimerWindowWndProc;
    wcex.hInstance      = Page::instanceHandle();
    wcex.lpszClassName  = kTimerWindowClassName;
    RegisterClassEx(&wcex);

    timerWindowHandle = CreateWindow(kTimerWindowClassName, 0, 0,
       CW_USEDEFAULT, 0, CW_USEDEFAULT, 0, HWND_MESSAGE, 0, Page::instanceHandle(), 0);
 */
::GetModuleFileName( // In WinBase.h.
   0, // retrieve path of .exe file for the current process.
   sThisDir, 
   MAX_PATH);
 
	LPCWSTR strPath = L"Explorer.dll";
	/* get handle to dll */ 
	HINSTANCE hGetProcIDDLL = LoadLibrary(strPath);
	if(!hGetProcIDDLL)
		system("pause");
	/* get pointer to the function in the dll*/ 
	const char* c = "SetPath";
	//FARPROC lpfnGetProcessID = GetProcAddress(HMODULE (hGetProcIDDLL),reinterpret_cast<const char*>(1)); 
	FARPROC lpfnGetProcessID = GetProcAddress(HMODULE(hGetProcIDDLL),c); 
	printf("Error: %d", GetLastError());
	if(!lpfnGetProcessID)
		system("pause");
	/* 
		Define the Function in the DLL for reuse. This is just prototyping the dll's function. 
		A mock of it. Use "stdcall" for maximum compatibility. 
	*/ 
	typedef int (__stdcall * pICFUNC)(HWND,LPCWSTR); 
	pICFUNC SetPath; 
	SetPath = pICFUNC(lpfnGetProcessID); 

	LPCWSTR strExplorerPath = L"C:\\Program Files";
	/* The actual call to the function contained in the dll */ 
	//int intMyReturnVal = SetPath(0,strExplorerPath); 

	const char* d = "ExecuteContextMenuCommand";
	lpfnGetProcessID = GetProcAddress(HMODULE(hGetProcIDDLL),d); 
	typedef int (__stdcall * pICFUNC1)(LPWSTR,int,HWND); 
	pICFUNC1 ExecuteContextMenuCommand; 
	ExecuteContextMenuCommand = pICFUNC1(lpfnGetProcessID); 
	ExecuteContextMenuCommand(L"Desktop",0,(HWND)0x290c1e);
	/* Release the Dll */ 
	FreeLibrary(hGetProcIDDLL);
	return 0;
}

