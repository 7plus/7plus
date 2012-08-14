// Explorer.cpp : Defines the exported functions for the DLL application.
//

#include "stdafx.h"

#include <tchar.h>
#include <windows.h>
#include <WinBase.h>
#include <shobjidl.h>
#include <shlobj.h>
#include <shlwapi.h>
#include <strsafe.h>
#include <propvarutil.h>

using namespace std;
//#define _WIN32_WINNT 0x0600
//#define _WIN32_IE 0x0700
//#define _UNICODE

#pragma comment(lib, "shlwapi.lib")
#pragma comment(lib, "ole32.lib")
#pragma comment(lib, "shell32.lib")
#pragma comment(lib, "propsys.lib")

#define INITGUID
#include <initguid.h>
#include <exdisp.h>
#include <shlguid.h>
#include <memory.h>
#include <Shellapi.h>
#include "Explorer.h"
#include "Filter.cpp"
// macros for walking PIDLs
#define _ILSkip(pidl, cb)       ((LPITEMIDLIST)(((BYTE*)(pidl))+cb))
#define _ILNext(pidl)           _ILSkip(pidl, (pidl)->mkid.cb)
#define SCRATCH_QCM_FIRST 1
#define SCRATCH_QCM_LAST  0x7FFF
HRESULT FreeResources(LPVOID pData);
HRESULT TestPidl(LPITEMIDLIST pidl);
LPITEMIDLIST PidlFromVARIANT(VARIANT* pvarLoc);
LPSAFEARRAY MakeSafeArrayFromData(LPBYTE pData,DWORD cbData);
HRESULT InitVARIANTFromPidl(LPVARIANT pVar, LPITEMIDLIST pidl);
UINT ILGetSize(LPITEMIDLIST pidl);

#define ShellExecuteW ShellExecute
#include "comutil.h"
#include <comdef.h>

/*
// This is an example of an exported variable
EXPLORER_API int nExplorer=0;

// This is an example of an exported function.
EXPLORER_API int fnExplorer(void)
{
	return 42;
}

// This is the constructor of a class that has been exported.
// see Explorer.h for the class definition
CExplorer::CExplorer()
{
	return;
}
*/
/*
int _stdcall RunAsUser(LPCWSTR Command, LPCWSTR WorkingDir)
{
	// OpenProcess - http://msdn.microsoft.com/en-us/library/windows/desktop/ms684320(v=vs.85).aspx 
	// PROCESS_QUERY_INFORMATION = 0x0400 
	HANDLE hProcess = OpenProcess(PROCESS_QUERY_INFORMATION, 0, GetCurrentProcessId());
	// OpenProcessToken - http://msdn.microsoft.com/en-us/library/windows/desktop/aa379295(v=vs.85).aspx 
	// TOKEN_ASSIGN_PRIMARY = 0x0001 
	// TOKEN_DUPLICATE = 0x0002 
	// TOKEN_QUERY = 0x0008 
	HANDLE hToken;
	BOOL result = OpenProcessToken(hProcess, TOKEN_ASSIGN_PRIMARY | TOKEN_DUPLICATE | TOKEN_QUERY, &hToken);
	// CreateRestrictedToken - http://msdn.microsoft.com/en-us/library/Aa446583 
	// LUA_TOKEN = 0x4 
	HANDLE hResToken;
	result = CreateRestrictedToken(hToken, LUA_TOKEN, 0, 0, 0, 0, 0, 0, &hResToken);
	
	STARTUPINFO sInfo;
	sInfo.cb = sizeof(STARTUPINFO);
	sInfo.lpDesktop = LPWSTR("winsta0\\default");
	PROCESS_INFORMATION pInfo;

	// CreateProcessAsUser - http://msdn.microsoft.com/en-us/library/ms682429 
	// NORMAL_PRIORITY_CLASS = 0x00000020
	result = CreateProcessAsUser(hResToken, 0, LPWSTR(Command), 0, 0, 0, NORMAL_PRIORITY_CLASS, 0, NULL, &sInfo, &pInfo);
	DWORD error = GetLastError();
	CloseHandle(hProcess);
	CloseHandle(hToken);
	CloseHandle(sInfo.hStdInput);
	CloseHandle(sInfo.hStdOutput);
	CloseHandle(sInfo.hStdError);
	CloseHandle(pInfo.hProcess);
	CloseHandle(pInfo.hThread);
	return error;
}
*/

#ifndef SECURITY_MANDATORY_HIGH_RID
	#define SECURITY_MANDATORY_UNTRUSTED_RID            (0x00000000L)
	#define SECURITY_MANDATORY_LOW_RID                  (0x00001000L)
	#define SECURITY_MANDATORY_MEDIUM_RID               (0x00002000L)
	#define SECURITY_MANDATORY_HIGH_RID                 (0x00003000L)
	#define SECURITY_MANDATORY_SYSTEM_RID               (0x00004000L)
	#define SECURITY_MANDATORY_PROTECTED_PROCESS_RID    (0x00005000L)
#endif
 
#ifndef TokenIntegrityLevel
	#define TokenIntegrityLevel ((TOKEN_INFORMATION_CLASS)25)
#endif

/*
#ifndef TOKEN_MANDATORY_LABEL
typedef struct
{
	SID_AND_ATTRIBUTES Label;
} TOKEN_MANDATORY_LABEL;
#endif
*/
typedef BOOL (WINAPI *defCreateProcessWithTokenW)
		(HANDLE,DWORD,LPCWSTR,LPWSTR,DWORD,LPVOID,LPCWSTR,LPSTARTUPINFOW,LPPROCESS_INFORMATION);


// Writes Integration Level of the process with the given ID into pu32_ProcessIL
// returns Win32 API error or 0 if succeeded
DWORD GetProcessIL(DWORD u32_PID, DWORD* pu32_ProcessIL)
{
	*pu32_ProcessIL = 0;
	
	HANDLE h_Process   = 0;
	HANDLE h_Token     = 0;
	DWORD  u32_Size    = 0;
	BYTE*  pu8_Count   = 0;
	DWORD* pu32_ProcIL = 0;
	TOKEN_MANDATORY_LABEL* pk_Label = 0;
 
	h_Process = OpenProcess(PROCESS_QUERY_INFORMATION, FALSE, u32_PID);
	if (!h_Process)
		goto _CleanUp;
 
	if (!OpenProcessToken(h_Process, TOKEN_QUERY, &h_Token))
		goto _CleanUp;
				
	if (!GetTokenInformation(h_Token, TokenIntegrityLevel, NULL, 0, &u32_Size) &&
		 GetLastError() != ERROR_INSUFFICIENT_BUFFER)
		goto _CleanUp;
						
	pk_Label = (TOKEN_MANDATORY_LABEL*) HeapAlloc(GetProcessHeap(), 0, u32_Size);
	if (!pk_Label)
		goto _CleanUp;
 
	if (!GetTokenInformation(h_Token, TokenIntegrityLevel, pk_Label, u32_Size, &u32_Size))
		goto _CleanUp;
 
	pu8_Count = GetSidSubAuthorityCount(pk_Label->Label.Sid);
	if (!pu8_Count)
		goto _CleanUp;
					
	pu32_ProcIL = GetSidSubAuthority(pk_Label->Label.Sid, *pu8_Count-1);
	if (!pu32_ProcIL)
		goto _CleanUp;
 
	*pu32_ProcessIL = *pu32_ProcIL;
	SetLastError(ERROR_SUCCESS);
 
	_CleanUp:
	DWORD u32_Error = GetLastError();
	if (pk_Label)  HeapFree(GetProcessHeap(), 0, pk_Label);
	if (h_Token)   CloseHandle(h_Token);
	if (h_Process) CloseHandle(h_Process);
	return u32_Error;
}
LPTSTR tcscasestr(LPCTSTR phaystack, LPCTSTR pneedle)
	// To make this work with MS Visual C++, this version uses tolower/toupper() in place of
	// _tolower/_toupper(), since apparently in GNU C, the underscore macros are identical
	// to the non-underscore versions; but in MS the underscore ones do an unconditional
	// conversion (mangling non-alphabetic characters such as the zero terminator).  MSDN:
	// tolower: Converts c to lowercase if appropriate
	// _tolower: Converts c to lowercase

	// Return the offset of one string within another.
	// Copyright (C) 1994,1996,1997,1998,1999,2000 Free Software Foundation, Inc.
	// This file is part of the GNU C Library.

	// The GNU C Library is free software; you can redistribute it and/or
	// modify it under the terms of the GNU Lesser General Public
	// License as published by the Free Software Foundation; either
	// version 2.1 of the License, or (at your option) any later version.

	// The GNU C Library is distributed in the hope that it will be useful,
	// but WITHOUT ANY WARRANTY; without even the implied warranty of
	// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	// Lesser General Public License for more details.

	// You should have received a copy of the GNU Lesser General Public
	// License along with the GNU C Library; if not, write to the Free
	// Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
	// 02111-1307 USA.

	// My personal strstr() implementation that beats most other algorithms.
	// Until someone tells me otherwise, I assume that this is the
	// fastest implementation of strstr() in C.
	// I deliberately chose not to comment it.  You should have at least
	// as much fun trying to understand it, as I had to write it :-).
	// Stephen R. van den Berg, berg@pool.informatik.rwth-aachen.de

	// Faster looping by precalculating bl, bu, cl, cu before looping.
	// 2004 Apr 08	Jose Da Silva, digital@joescat@com
{
	register const TBYTE *haystack, *needle;
	register unsigned bl, bu, cl, cu;
	
	haystack = (const TBYTE *) phaystack;
	needle = (const TBYTE *) pneedle;

	// Since ctolower returns TCHAR (which is signed in ANSI builds), typecast to
	// TBYTE first to promote characters \x80-\xFF to unsigned 32-bit correctly:
	bl = (TBYTE)ctolower(*needle);
	if (bl != '\0')
	{
		// Scan haystack until the first character of needle is found:
		bu = (TBYTE)ctoupper(bl);
		haystack--;				/* possible ANSI violation */
		do
		{
			cl = *++haystack;
			if (cl == '\0')
				goto ret0;
		}
		while ((cl != bl) && (cl != bu));

		// See if the rest of needle is a one-for-one match with this part of haystack:
		cl = (TBYTE)ctolower(*++needle);
		if (cl == '\0')  // Since needle consists of only one character, it is already a match as found above.
			goto foundneedle;
		cu = (TBYTE)ctoupper(cl);
		++needle;
		goto jin;
		
		for (;;)
		{
			register unsigned a;
			register const TBYTE *rhaystack, *rneedle;
			do
			{
				a = *++haystack;
				if (a == '\0')
					goto ret0;
				if ((a == bl) || (a == bu))
					break;
				a = *++haystack;
				if (a == '\0')
					goto ret0;
shloop:
				;
			}
			while ((a != bl) && (a != bu));

jin:
			a = *++haystack;
			if (a == '\0')  // Remaining part of haystack is shorter than needle.  No match.
				goto ret0;

			if ((a != cl) && (a != cu)) // This promising candidate is not a complete match.
				goto shloop;            // Start looking for another match on the first char of needle.
			
			rhaystack = haystack-- + 1;
			rneedle = needle;
			a = (TBYTE)ctolower(*rneedle);
			
			if ((TBYTE)ctolower(*rhaystack) == (int) a)
			do
			{
				if (a == '\0')
					goto foundneedle;
				++rhaystack;
				a = (TBYTE)ctolower(*++needle);
				if ((TBYTE)ctolower(*rhaystack) != (int) a)
					break;
				if (a == '\0')
					goto foundneedle;
				++rhaystack;
				a = (TBYTE)ctolower(*++needle);
			}
			while ((TBYTE)ctolower(*rhaystack) == (int) a);
			
			needle = rneedle;		/* took the register-poor approach */
			
			if (a == '\0')
				break;
		} // for(;;)
	} // if (bl != '\0')
foundneedle:
	return (LPTSTR) haystack;
ret0:
	return 0;
}

static int ConvertRunMode(LPTSTR aBuf)
// Returns the matching WinShow mode, or SW_SHOWNORMAL if none.
// These are also the modes that AutoIt3 uses.
{
	// For v1.0.19, this was made more permissive (the use of strcasestr vs. stricmp) to support
	// the optional word UseErrorLevel inside this parameter:
	if (!aBuf || !*aBuf) return SW_SHOWNORMAL;
	if (tcscasestr(aBuf, _T("MIN"))) return SW_MINIMIZE;
	if (tcscasestr(aBuf, _T("MAX"))) return SW_MAXIMIZE;
	if (tcscasestr(aBuf, _T("HIDE"))) return SW_HIDE;
	return SW_SHOWNORMAL;
}
// Creates a new process u16_Path with the integration level of the Explorer process (MEDIUM IL)
// If you need this function in a service you must replace FindWindow() with another API to find Explorer process
// The parent process of the new process will be svchost.exe if this EXE was run "As Administrator"
// returns Win32 API error or 0 if succeeded
DWORD _stdcall CreateProcessMediumIL(WCHAR* u16_CmdLine, WCHAR* u16_WorkingDir, WCHAR* aRunShowMode)
{
	HANDLE h_Process = 0;
	HANDLE h_Token   = 0;
	HANDLE h_Token2  = 0;
	PROCESS_INFORMATION k_ProcInfo    = {0};
	STARTUPINFOW        k_StartupInfo = {0};
	k_StartupInfo.dwFlags = STARTF_USESHOWWINDOW;
	k_StartupInfo.wShowWindow = (aRunShowMode && *aRunShowMode) ? ConvertRunMode(aRunShowMode) : SW_SHOWNORMAL;
	BOOL b_UseToken = FALSE;
 
	// Detect Windows Vista, 2008, Windows 7 and higher
	if (GetProcAddress(GetModuleHandleA("Kernel32"), "GetProductInfo"))
	{
		DWORD u32_CurIL;
		DWORD u32_Err = GetProcessIL(GetCurrentProcessId(), &u32_CurIL);
		if (u32_Err)
			return u32_Err;
 
		if (u32_CurIL > SECURITY_MANDATORY_MEDIUM_RID)
			b_UseToken = TRUE;
	}
 
	// Create the process normally (before Windows Vista or if current process runs with a medium IL)
	if (!b_UseToken)
	{
		if (!CreateProcessW(0, u16_CmdLine, 0, 0, FALSE, 0, 0, 0, &k_StartupInfo, &k_ProcInfo))
			return GetLastError();
 
		CloseHandle(k_ProcInfo.hThread);
		CloseHandle(k_ProcInfo.hProcess); 
		return ERROR_SUCCESS;
	}
 
	defCreateProcessWithTokenW f_CreateProcessWithTokenW = 
		(defCreateProcessWithTokenW) GetProcAddress(GetModuleHandleA("Advapi32"), "CreateProcessWithTokenW");
 
	if (!f_CreateProcessWithTokenW) // This will never happen on Vista!
		return ERROR_INVALID_FUNCTION; 
	
	HWND h_Progman = ::GetShellWindow();
 
	DWORD u32_ExplorerPID = 0;		
	GetWindowThreadProcessId(h_Progman, &u32_ExplorerPID);
 
	// ATTENTION:
	// If UAC is turned OFF all processes run with SECURITY_MANDATORY_HIGH_RID, also Explorer!
	// But this does not matter because to start the new process without UAC no elevation is required.
	h_Process = OpenProcess(PROCESS_QUERY_INFORMATION, FALSE, u32_ExplorerPID);
	if (!h_Process)
		goto _CleanUp;
 
	if (!OpenProcessToken(h_Process, TOKEN_DUPLICATE, &h_Token))
		goto _CleanUp;
 
	if (!DuplicateTokenEx(h_Token, TOKEN_ALL_ACCESS, 0, SecurityImpersonation, TokenPrimary, &h_Token2))
		goto _CleanUp;
	
	if (!f_CreateProcessWithTokenW(h_Token2, 0, 0, u16_CmdLine, 0, 0, (u16_WorkingDir && *u16_WorkingDir) ? u16_WorkingDir : 0, &k_StartupInfo, &k_ProcInfo))
		goto _CleanUp;
	SetLastError(0);
 
	_CleanUp:
	DWORD u32_Error = GetLastError();
	if (h_Token)   CloseHandle(h_Token);
	if (h_Token2)  CloseHandle(h_Token2);
	if (h_Process) CloseHandle(h_Process);
	CloseHandle(k_ProcInfo.hThread);
	CloseHandle(k_ProcInfo.hProcess);
	SetLastError(u32_Error);
	return k_ProcInfo.dwProcessId;
}

int _stdcall SetPath(HWND hWnd, LPCWSTR Path)
{
    IShellWindows* psw;
	HRESULT hr;
	LPITEMIDLIST pidl, pidl2 = NULL;
	VARIANT vPIDL = {0}, vDummy = {0};	
	IWebBrowser2 *pwb;
    IDispatch *pdisp;
	if (FAILED(OleInitialize(NULL)))
	{
		return 1;
	}
    if (SUCCEEDED(CoCreateInstance(CLSID_ShellWindows, NULL,  
        CLSCTX_LOCAL_SERVER, IID_PPV_ARGS(&psw))))
    {
        VARIANT v = { VT_I4 };
        if (SUCCEEDED(psw->get_Count(&v.lVal)))
        {
            // walk backwards to make sure the windows that close
            // don't cause the array to be re-ordered
            while (--v.lVal >= 0)
            {
                if (S_OK == psw->Item(v, &pdisp))
                {
                    if (SUCCEEDED(pdisp->QueryInterface(IID_PPV_ARGS(&pwb))))
                    {
						HWND _hWnd;
						if(SUCCEEDED(pwb->get_HWND(reinterpret_cast<SHANDLE_PTR*>(&_hWnd))) )
						{
							if(_hWnd==hWnd)
							{
								// Get the pidl for your favorite special folder,
								// in this case literally, the Favorites folder
								if(FAILED(hr = SHParseDisplayName(Path, NULL, &pidl, 0, NULL)))
								{
									goto Error;
								}

								// Pack the pidl into a VARIANT
								if (FAILED(hr = InitVARIANTFromPidl(&vPIDL, pidl)))
								{
									goto Error;
								}

								// Verify for testing purposes only that the pidl was packed
								// properly. Don't clean up pidl2 because it's a copy of the
								// pointer, not a clone of the id list itself
								pidl2 = PidlFromVARIANT(&vPIDL);
								if (FAILED(hr = TestPidl(pidl2)))
								{
									OutputDebugString(LPCWSTR("PIDL test failed"));
									goto Error;
								}
						
								// Show the browser, and navigate to the special location
								// represented by the pidl
								hr = pwb->Navigate2(&vPIDL, &vDummy, &vDummy,&vDummy, &vDummy);
								goto Error;
							}
						}
                        pwb->Release();
                    }
                    pdisp->Release();
                }
            }
        }
        psw->Release();
    }
	Error:
	// Clean up
	VariantClear(&vPIDL);

	if (pwb)
	{
		pwb->Release();
	}

	if (pidl)
	{
		FreeResources((LPVOID)pidl);
	}

	if(pdisp)
		pdisp->Release();

	if(psw)
		psw->Release();
	OleUninitialize();
	return hr;
}
 
// convert an IShellItem or IDataObject into a VARIANT that holds an IDList
// suitable for calling IWebBrowser2::Navigate2() with
 
HRESULT InitVariantFromObject(IUnknown *punk, VARIANT *pvar)
{
    VariantInit(pvar);
 
    PIDLIST_ABSOLUTE pidl;
    HRESULT hr = SHGetIDListFromObject(punk, &pidl);
    if (SUCCEEDED(hr))
    {
        hr = InitVariantFromBuffer(pidl, ILGetSize(pidl), pvar);
        CoTaskMemFree(pidl);
    }
    return hr;
}

// Exercise the PIDL by performing common operations upon it.
// 
HRESULT TestPidl(LPITEMIDLIST pidl)
{
   HRESULT hr;
   LPSHELLFOLDER pshfDesktop = NULL, pshf = NULL;
   DWORD uFlags = SHGDN_NORMAL;
   STRRET strret;

   if (!pidl)
   {
      return E_INVALIDARG;
   }

   hr = SHGetDesktopFolder(&pshfDesktop);
   if (!pshfDesktop)
   {
      return hr;
   }

   hr = pshfDesktop->BindToObject(pidl,
                NULL,
                IID_IShellFolder,
                (LPVOID*)&pshf);
   if (!pshf)
   {
      goto Error;
   }

   hr = pshfDesktop->GetDisplayNameOf(pidl, uFlags, &strret);
   if (STRRET_WSTR == strret.uType)
   {
      FreeResources((LPVOID)strret.pOleStr);
   }

   Error:
   if (pshf) pshf->Release();
   if (pshf) pshfDesktop->Release();
   return hr;
}

// Use the shell's IMalloc implementation to free resources
HRESULT FreeResources(LPVOID pData)
{
   HRESULT hr;
   LPMALLOC pMalloc = NULL;

   if (SUCCEEDED(hr = SHGetMalloc(&pMalloc)))
   {
      pMalloc->Free((LPVOID)pData);
      pMalloc->Release();
   }

   return hr;
}

// Given a VARIANT, pull out the PIDL using brute force
LPITEMIDLIST PidlFromVARIANT(LPVARIANT pvarLoc)
{
   if (pvarLoc)
   {
      if (V_VT(pvarLoc) == (VT_ARRAY|VT_UI1))
      {
         LPITEMIDLIST pidl = (LPITEMIDLIST)pvarLoc->parray->pvData;
         return pidl;
      }
   }
   return NULL;
}

// Pack a PIDL into a VARIANT
HRESULT InitVARIANTFromPidl(LPVARIANT pvar, LPITEMIDLIST pidl)
{
   if (!pidl || !pvar)
   {
      return E_POINTER;
   }

   // Get the size of the pidl and allocate a SAFEARRAY of
   // equivalent size
   UINT cb = ILGetSize(pidl);
   LPSAFEARRAY psa = MakeSafeArrayFromData((LPBYTE)pidl, cb);
   if (!psa)
   {
      VariantInit(pvar);
      return E_OUTOFMEMORY;
   }

   V_VT(pvar) = VT_ARRAY|VT_UI1;
   V_ARRAY(pvar) = psa;
   return NOERROR;
}

// Allocate a SAFEARRAY of cbData size and pack pData into it
LPSAFEARRAY MakeSafeArrayFromData(LPBYTE pData, DWORD cbData)
{
   LPSAFEARRAY psa;

   if (!pData || 0 == cbData)
   {
      return NULL;  // nothing to do
   }

   // create a one-dimensional safe array of BYTEs
   psa = SafeArrayCreateVector(VT_UI1, 0, cbData);

   if (psa)
   {
      // copy data into the area in safe array reserved for data
      // Note we party directly on the pointer instead of using locking/ 
      // unlocking functions.  Since we just created this and no one
      // else could possibly know about it or be using it, this is okay.
      memcpy(psa->pvData,pData,cbData);
   }

   return psa;
}

// Get the size of the PIDL by walking the item id list
UINT ILGetSize(LPITEMIDLIST pidl)
{
   UINT cbTotal = 0;
   if (pidl)
   {
      cbTotal += sizeof(pidl->mkid.cb);       // Null terminator
      while (pidl->mkid.cb)
      {
         cbTotal += pidl->mkid.cb;
         pidl = _ILNext(pidl);
      }
   }

   return cbTotal;
}

/*Context Menu code below*/
int _stdcall ExecuteContextMenuCommand(LPWSTR strPath, int idn, HWND hWnd)
{
	#define MIN_SHELL_ID 1
	#define MAX_SHELL_ID 0x7FFF
	IShellFolder *psf = NULL;
	IContextMenu *pCM = NULL;
	if (wcscmp(strPath,L"Desktop") == 0) //if in desktop directory
	{
		//Get IShellFolder
		if(!SUCCEEDED(SHGetDesktopFolder(&psf)))
		{
			OutputDebugString(L"SHGetDesktopFolder failed");
			return 0;
		}
		if(!SUCCEEDED(psf->CreateViewObject(0,IID_IContextMenu,(void**)&pCM)))
		{
			OutputDebugString(L"CreateViewObject failed");
			return 0;
		}
	}
	else
		GetUIObjectOfFile(hWnd,strPath, IID_IContextMenu, (void**)&pCM);

	if(psf != NULL)
		psf->Release();
	else if(pCM == NULL)
		return 0;

	HMENU hmenu = CreatePopupMenu();
	if (hmenu) 
	{
		if (SUCCEEDED(pCM->QueryContextMenu(hmenu, 0, MIN_SHELL_ID, MAX_SHELL_ID, CMF_NORMAL))) 
		{
			if(idn == 0)
			{
				POINT ptCursorPos;
				GetCursorPos(&ptCursorPos);
				idn = TrackPopupMenuEx(hmenu, TPM_RETURNCMD, ptCursorPos.x, ptCursorPos.y, hWnd, NULL);
			}
			if(idn!=0)
			{
				CMINVOKECOMMANDINFOEX info = { 0 };
				info.cbSize = sizeof(info);
				info.fMask = CMIC_MASK_UNICODE;
				info.hwnd = hWnd;
				info.lpVerb  = MAKEINTRESOURCEA(idn - MIN_SHELL_ID);
				info.lpVerbW = MAKEINTRESOURCEW(idn - MIN_SHELL_ID);
				info.nShow = SW_SHOWNORMAL;
				pCM->InvokeCommand((LPCMINVOKECOMMANDINFO)&info);
			}
		}
		DestroyMenu(hmenu);
	}

	if(pCM != NULL)
		pCM->Release();
	else
		return 0;

	return 1;
}

HRESULT GetUIObjectOfFile(HWND hwnd, LPCWSTR pszPath, REFIID riid, void **ppv)
{
  *ppv = NULL;
  HRESULT hr;
  LPITEMIDLIST pidl;
  SFGAOF sfgao;
  if (SUCCEEDED(hr = SHParseDisplayName(pszPath, NULL, &pidl, 0, &sfgao))) {
    IShellFolder *psf;
    LPCITEMIDLIST pidlChild;
    if (SUCCEEDED(hr = SHBindToParent(pidl, IID_IShellFolder,
                                      (void**)&psf, &pidlChild))) {
      hr = psf->GetUIObjectOf(hwnd, 1, &pidlChild, riid, NULL, ppv);
      psf->Release();
    }
    CoTaskMemFree(pidl);
  }
  return hr;
}
/*
// StExBar - an explorer toolbar

// Copyright (C) 2007-2010 - Stefan Kueng

// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software Foundation,
// 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//#include "stdafx.h"
//#include "SRBand.h"
#include "StringUtils.h"
#include <regex>

#define MIDL_DEFINE_GUID(type,name,l,w1,w2,b1,b2,b3,b4,b5,b6,b7,b8) \
    const type name = {l,w1,w2,{b1,b2,b3,b4,b5,b6,b7,b8}}

MIDL_DEFINE_GUID(IID, IID_IShellFolderView,0x37A378C0, 0xF82D, 0x11CE,0xAE,0x65,0x08,0x00,0x2B,0x2E,0x12,0x62);


BOOL CALLBACK EnumChildProc(HWND hwnd, LPARAM lParam)
{
    TCHAR cName[100];
    HWND * hwndListView = (HWND*)lParam;
    if (GetClassName(hwnd, cName, 100))
    {
        if (_tcscmp(cName, _T("SysListView32")) == 0)
        {
            *hwndListView = hwnd;
            return FALSE;
        }
        if (_tcscmp(cName, _T("DirectUIHWND")) == 0)
        {
            *hwndListView = hwnd;
            return FALSE;
        }
    }
    *hwndListView = NULL;
    return TRUE;
}

HWND GetListView32(IShellView * shellView)
{
    HWND parent = NULL;
	HWND hWndListView = NULL;
    if (SUCCEEDED(shellView->GetWindow(&parent)))
    {
        EnumChildWindows(parent, EnumChildProc, (LPARAM)&hWndListView);
        return hWndListView;
    }
    return NULL;
}

bool CheckDisplayName(IShellFolder * shellFolder, LPITEMIDLIST pidl, LPCTSTR filter, bool bUseRegex)
{
    STRRET str;
    if (SUCCEEDED(shellFolder->GetDisplayNameOf(pidl,
        // SHGDN_FORPARSING needed to get the extensions even if they're not shown
        SHGDN_INFOLDER|SHGDN_FORPARSING,
        &str)))
    {
        TCHAR dispname[MAX_PATH];
        StrRetToBuf(&str, pidl, dispname, MAX_PATH);

        if (bUseRegex)
        {

            try
            {
                const tr1::wregex regCheck(&filter[1], tr1::regex_constants::icase | tr1::regex_constants::ECMAScript);
                wstring s = dispname;

                return tr1::regex_search(s, regCheck);
            }
            catch (exception)
            {
            }
        }
        else
        {
            // we now have the display name of the item
            // i.e. the way the item is shown
            // since the windows file system is case-insensitive
            // we have to force the display name to lowercase
            // so the filter matches case-insensitive too
            TCHAR * pString = dispname;
            while (*pString)
            {
                *pString = _totlower(*pString);
                pString++;
            }
            // check if the item name matches the text of the edit control
            return (_tcsstr(dispname, filter) != NULL);
        }
    }
    return false;
}


std::vector<LPITEMIDLIST>   m_noShows;  ///< list of pidls which didn't match a filter
LPITEMIDLIST    m_currentFolder;    ///< pidl of the current folder
bool _stdcall Filter(LPTSTR filter, HWND hWnd)
{
    bool bReturn = false;
	IShellWindows* psw;
    IDispatch *pdisp;
	IDispatch *pdisp2;
	if (FAILED(OleInitialize(NULL)))
	{
		return 1;
	}
    if (SUCCEEDED(CoCreateInstance(CLSID_ShellWindows, NULL,  
        CLSCTX_LOCAL_SERVER, IID_PPV_ARGS(&psw))))
    {
        VARIANT v = { VT_I4 };
        if (SUCCEEDED(psw->get_Count(&v.lVal)))
        {
            // walk backwards to make sure the windows that close
            // don't cause the array to be re-ordered
            while (--v.lVal >= 0)
            {
                if (S_OK == psw->Item(v, &pdisp))
                {
					IWebBrowser2 *pwb;
                    if (SUCCEEDED(pdisp->QueryInterface(IID_PPV_ARGS(&pwb))))
					{
						HWND _hWnd;
						if(SUCCEEDED(pwb->get_HWND(reinterpret_cast<SHANDLE_PTR*>(&_hWnd))) )
						{
							if(_hWnd==hWnd)
							{
								if(SUCCEEDED(pwb->get_Document(&pdisp2)))
								{
									IServiceProvider * pServiceProvider = NULL;
									if(SUCCEEDED(pdisp2->QueryInterface(IID_IServiceProvider, (LPVOID*)&pServiceProvider)))
									{
										IShellBrowser * pShellBrowser = NULL;
										if(SUCCEEDED(pServiceProvider->QueryService(SID_STopLevelBrowser,IID_IShellBrowser,(LPVOID*)&pShellBrowser)))
										{
											IShellView * pShellView = NULL;
											if(SUCCEEDED(pShellBrowser->QueryActiveShellView((IShellView**)&pShellView)))
											{
												IFolderView * pFolderView;
												if (SUCCEEDED(pShellView->QueryInterface(IID_IFolderView, (LPVOID*)&pFolderView)))
												{
													// hooray! we got the IFolderView interface!
													// that means the explorer is active and well :)
													IShellFolderView * pShellFolderView;
													if (SUCCEEDED(pShellView->QueryInterface(IID_IShellFolderView, (LPVOID*)&pShellFolderView)))
													{
														int x = 0;
													}
												}
											}
										}
									}
									IShellView * pShellView;
									if (SUCCEEDED(pwb->QueryInterface(IID_IShellView, (LPVOID*)&pShellView)))
									{
										IFolderView * pFolderView;
										if (SUCCEEDED(pShellView->QueryInterface(IID_IFolderView, (LPVOID*)&pFolderView)))
										{
											// hooray! we got the IFolderView interface!
											// that means the explorer is active and well :)
											IShellFolderView * pShellFolderView;
											if (SUCCEEDED(pShellView->QueryInterface(IID_IShellFolderView, (LPVOID*)&pShellFolderView)))
											{
												// the first thing we do is to deselect all already selected entries
												pFolderView->SelectItem(NULL, SVSI_DESELECTOTHERS);

												// but we also need the IShellFolder interface because
												// we need its GetDisplayNameOf() method
												IPersistFolder2 * pPersistFolder;
												if (SUCCEEDED(pFolderView->GetFolder(IID_IPersistFolder2, (LPVOID*)&pPersistFolder)))
												{
													LPITEMIDLIST curFolder;
													pPersistFolder->GetCurFolder(&curFolder);
													if (ILIsEqual(m_currentFolder, curFolder))
													{
														CoTaskMemFree(curFolder);
													}
													else
													{
														CoTaskMemFree(m_currentFolder);
														m_currentFolder = curFolder;
														for (size_t i=0; i<m_noShows.size(); ++i)
														{
															CoTaskMemFree(m_noShows[i]);
														}
														m_noShows.clear();
													}
													IShellFolder * pShellFolder;
													if (SUCCEEDED(pPersistFolder->QueryInterface(IID_IShellFolder, (LPVOID*)&pShellFolder)))
													{
														// our next task is to enumerate all the
														// items in the folder view and select those
														// which match the text in the edit control

														bool bUseRegex = (filter[0] == '\\');

														try
														{
															const tr1::wregex regCheck(&filter[1], tr1::regex_constants::icase | tr1::regex_constants::ECMAScript);
														}
														catch (exception)
														{
															bUseRegex = false;
														}

														if (!bUseRegex)
														{
															// force the filter to lowercase
															TCHAR * pString = filter;
															while (*pString)
															{
																*pString = _totlower(*pString);
																pString++;
															}
														}

														int nCount = 0;
														if (SUCCEEDED(pFolderView->ItemCount(SVGIO_ALLVIEW, &nCount)))
														{
															pShellFolderView->SetRedraw(FALSE);
															HWND listView = GetListView32(pShellView);
															LRESULT viewType = 0;
															if (listView)
															{
																// inserting items in the list view if the list view is set to
																// e.g., LV_VIEW_LIST is painfully slow. So save the current view
																// and set it to LV_VIEW_DETAILS (which is much faster for inserting)
																// and restore the view after we're done.
																viewType = SendMessage(listView, LVM_GETVIEW, 0, 0);
																SendMessage(listView, LVM_SETVIEW, LV_VIEW_DETAILS, 0);
															}
															std::vector<LPITEMIDLIST> noShows;
															for (int i=0; i<nCount; ++i)
															{
																LPITEMIDLIST pidl;
																if (SUCCEEDED(pFolderView->Item(i, &pidl)))
																{
																	if (CheckDisplayName(pShellFolder, pidl, filter, bUseRegex))
																	{
																		// remove now shown items which are in the no-show list
																		// this is necessary since we don't get a notification
																		// if the shell refreshes its view
																		for (std::vector<LPITEMIDLIST>::iterator it = m_noShows.begin(); it != m_noShows.end(); ++it )
																		{
																			if (HRESULT_CODE(pShellFolder->CompareIDs(SHCIDS_CANONICALONLY, *it, pidl))==0)
																			{
																				m_noShows.erase(it);
																				break;
																			}
																		}
																		CoTaskMemFree(pidl);
																	}
																	else
																	{
																		UINT puItem = 0;
																		if (pShellFolderView->RemoveObject(pidl, &puItem) == S_OK)
																		{
																			i--;
																			nCount--;
																			noShows.push_back(pidl);
																		}
																	}
																}
															}
															// now add all those items again which were removed by a previous filter string
															// but don't match this new one
															//pShellFolderView->SetObjectCount(5000, SFVSOC_INVALIDATE_ALL|SFVSOC_NOSCROLL);
															for (size_t i=0; i<m_noShows.size(); ++i)
															{
																LPITEMIDLIST pidlNoShow = m_noShows[i];
																if (CheckDisplayName(pShellFolder, pidlNoShow, filter, bUseRegex))
																{
																	m_noShows.erase(m_noShows.begin() + i);
																	i--;
																	UINT puItem = (UINT)i;
																	pShellFolderView->AddObject(pidlNoShow, &puItem);
																	CoTaskMemFree(pidlNoShow);
																}
															}
															for (size_t i=0; i<noShows.size(); ++i)
															{
																m_noShows.push_back(noShows[i]);
															}
															if (listView)
															{
																SendMessage(listView, LVM_SETVIEW, viewType, 0);
															}

															pShellFolderView->SetRedraw(TRUE);
														}
														pShellFolder->Release();
													}
													pPersistFolder->Release();
												}
												pShellFolderView->Release();
											}
											pFolderView->Release();
										}
										pShellView->Release();
									}
									pdisp2->Release();
								}
							}
						}
						pwb->Release();
					}
				}
            }            
        }
		psw->Release();
    }
    return bReturn;
}
*/
// THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF
// ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
// PARTICULAR PURPOSE.
//
// Copyright (c) Microsoft Corporation. All rights reserved

// use the shell view for the desktop using the shell windows automation to find the
// desktop web browser and then grabs its view
//
// returns:
//      IShellView, IFolderView and related interfaces

HRESULT GetShellViewForDesktop(REFIID riid, void **ppv)
{
    *ppv = NULL;

    IShellWindows *psw;
    HRESULT hr = CoCreateInstance(CLSID_ShellWindows, NULL, CLSCTX_LOCAL_SERVER, IID_PPV_ARGS(&psw));
    if (SUCCEEDED(hr))
    {
        HWND hwnd;
        IDispatch* pdisp;
        VARIANT vEmpty = {}; // VT_EMPTY
        if (S_OK == psw->FindWindowSW(&vEmpty, &vEmpty, SWC_DESKTOP, (long*)&hwnd, SWFO_NEEDDISPATCH, &pdisp))
        {
            IShellBrowser *psb;
            hr = IUnknown_QueryService(pdisp, SID_STopLevelBrowser, IID_PPV_ARGS(&psb));
            if (SUCCEEDED(hr))
            {
                IShellView *psv;
                hr = psb->QueryActiveShellView(&psv);
                if (SUCCEEDED(hr))
                {
                    hr = psv->QueryInterface(riid, ppv);
                    psv->Release();
                }
                psb->Release();
            }
            pdisp->Release();
        }
        else
        {
            hr = E_FAIL;
        }
        psw->Release();
    }
    return hr;
}

// From a shell view object gets its automation interface and from that gets the shell
// application object that implements IShellDispatch2 and related interfaces.

HRESULT GetShellDispatchFromView(IShellView *psv, REFIID riid, void **ppv)
{
    *ppv = NULL;

    IDispatch *pdispBackground;
    HRESULT hr = psv->GetItemObject(SVGIO_BACKGROUND, IID_PPV_ARGS(&pdispBackground));
    if (SUCCEEDED(hr))
    {
        IShellFolderViewDual *psfvd;
        hr = pdispBackground->QueryInterface(IID_PPV_ARGS(&psfvd));
        if (SUCCEEDED(hr))
        {
            IDispatch *pdisp;
            hr = psfvd->get_Application(&pdisp);
            if (SUCCEEDED(hr))
            {
                hr = pdisp->QueryInterface(riid, ppv);
                pdisp->Release();
            }
            psfvd->Release();
        }
        pdispBackground->Release();
    }
    return hr;
}

HRESULT ShellExecInExplorerProcess(LPCTSTR pszFile, LPCTSTR pszArgs, LPCTSTR pszWorkingDir)
{
    IShellView *psv;
    HRESULT hr = GetShellViewForDesktop(IID_PPV_ARGS(&psv));
    if (SUCCEEDED(hr))
    {
        IShellDispatch2 *psd;
        hr = GetShellDispatchFromView(psv, IID_PPV_ARGS(&psd));
        if (SUCCEEDED(hr))
        {
            BSTR bstrFile = SysAllocString(pszFile);
            hr = bstrFile ? S_OK : E_OUTOFMEMORY;
            if (SUCCEEDED(hr))
            {
                VARIANT vtEmpty = {}; // VT_EMPTY
				_variant_t vtArgs = pszArgs;
				_variant_t vtDir = pszWorkingDir;
                hr = psd->ShellExecute(bstrFile, vtArgs, vtDir, vtEmpty, vtEmpty);
                SysFreeString(bstrFile);
            }
            psd->Release();
        }
        psv->Release();
    }

    return hr;
}