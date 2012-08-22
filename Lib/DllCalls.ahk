/*
HICON WINAPI ExtractIcon(
  __reserved  HINSTANCE hInst,
  __in        LPCTSTR lpszExeFileName,
  __in        UINT nIconIndex
);
*/
; ExtractIcon(hInst, lpszExeFileName, nIconIndex)
; {
	; return DllCall("ExtractIcon", "Ptr", hInst, "str", lpszExeFileName, "uint", nIconIndex, "Ptr")
; }

/*
int ImageList_ReplaceIcon(
  __in  HIMAGELIST himl,
  __in  int i,
  __in  HICON hicon
);
*/
ImageList_ReplaceIcon(himl, i, hicon)
{
	return DllCall("ImageList_ReplaceIcon", "Ptr", himl, Int, i, "Ptr", hicon)
}

/*

Gets an icon associated with a file(type). The icon needs to be destroyed after usage.
HICON WINAPI ExtractAssociatedIcon(
  __reserved  HINSTANCE hInst,
  __inout     LPTSTR lpIconPath,
  __inout     WORD *lpiIcon
);
*/
ExtractAssociatedIcon(hInst, lpIconPath, ByRef lpiIcon)
{
  LogAddRef("hIcon")
  VarSetCapacity(Path, 260 * 2) ;MAXPATH
  Path := lpIconPath
	return DllCall("Shell32\ExtractAssociatedIcon", "Ptr", hInst, "Str", Path, "UShortP", lpiIcon, "Ptr")
 }
 
 /*
 HMODULE WINAPI GetModuleHandle(
  __in_opt  LPCTSTR lpModuleName
);
 */
 GetModuleHandle(lpModuleName)
{
	return DllCall("GetModuleHandle", "Str", lpModuleName, "Ptr")
}

/*
FARPROC WINAPI GetProcAddress(
  __in  HMODULE hModule,
  __in  LPCSTR lpProcName
);
*/
GetProcAddress(hModule, lpProcName)
{
	return DllCall("GetProcAddress", "Ptr", hModule, "AStr", lpProcName)
}

/*
HWND WINAPI GetParent(
  __in  HWND hWnd
);
*/
GetParent(hWnd)
{
	return DllCall("GetParent", "Ptr", hWnd, "Ptr")
}

/*
HWND WINAPI GetWindow(
  __in  HWND hWnd,
  __in  UINT uCmd
);
*/
GetWindow(hWnd,uCmd)
{
	return DllCall( "GetWindow", "Ptr", hWnd, "uint", uCmd, "Ptr")
}

/*
HWND WINAPI GetForegroundWindow(void);
*/
GetForegroundWindow()
{
	return DllCall("GetForeGroundWindow", "Ptr")
}

/*
BOOL WINAPI IsWindowVisible(
  __in  HWND hWnd
);
*/
IsWindowVisible(hWnd)
{
	return DllCall("IsWindowVisible","Ptr",h)
}

/*
DWORD WINAPI GetWindowThreadProcessId(
  __in       HWND hWnd,
  __out_opt  LPDWORD lpdwProcessId
);
*/
GetWindowThreadProcessId(hWnd)
{
	DllCall("GetWindowThreadProcessId", "Ptr", hWnd, "UIntP", lpdwProcessId)
	return lpdwProcessId
}
