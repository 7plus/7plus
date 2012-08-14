// The following ifdef block is the standard way of creating macros which make exporting 
// from a DLL simpler. All files within this DLL are compiled with the EXPLORER_EXPORTS
// symbol defined on the command line. This symbol should not be defined on any project
// that uses this DLL. This way any other project whose source files include this file see 
// EXPLORER_API functions as being imported from a DLL, whereas this DLL sees symbols
// defined with this macro as being exported.
//#ifdef EXPLORER_EXPORTS
//#define EXPLORER_API __declspec(dllexport)
//#else
//#define EXPLORER_API __declspec(dllimport)
//#endif

// This class is exported from the Explorer.dll
/*
class EXPLORER_API CExplorer {
public:
	CExplorer(void);
	// TODO: add your methods here.
};

extern EXPLORER_API int nExplorer;

EXPLORER_API int fnExplorer(void);
*/

DWORD _stdcall CreateProcessMediumIL(WCHAR* u16_CmdLine, WCHAR* u16_WorkingDir, WCHAR* aRunShowMode);
// int _stdcall RunAsUser(LPWSTR Command, LPCWSTR WorkingDir);
int _stdcall SetPath(HWND hWnd, LPCWSTR Path);
int _stdcall ExecuteContextMenuCommand(LPWSTR strPath, int idn, HWND hWnd);
bool _stdcall Filter(LPTSTR filter, HWND hWnd);
HRESULT GetUIObjectOfFile(HWND hwnd, LPCWSTR pszPath, REFIID riid, void **ppv);
/// returns the explorer list view control
HWND                    GetListView32(IShellView * shellView);

// Some source code from AHK
// Locale independent ctype (applied to the ASCII characters only)
// isctype/iswctype affects the some non-ASCII characters.
inline int cisctype(TBYTE c, int type)
{
	return (c & (~0x7F)) ? 0 : _isctype(c, type);
}
#define cisupper(c)		cisctype(c, _UPPER)
#define cislower(c)		cisctype(c, _LOWER)
inline TCHAR ctoupper(TBYTE c)
{
	return cislower(c) ? (c & ~0x20) : c;
}
inline TCHAR ctolower(TBYTE c)
{
	return cisupper(c) ? (c | 0x20) : c;
}