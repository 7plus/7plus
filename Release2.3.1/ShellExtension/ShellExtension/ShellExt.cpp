// ShellExt.cpp: Implementierung von CShellExt

#include "stdafx.h"
#include "ShellExt.h"

#include "resource.h"
#include <iostream>
#include <string>
#include <sstream>
#include <algorithm>
#include <iterator>
#include <stdio.h>
#include <map>
#include <sys/types.h>
#include <sys/stat.h>
using namespace std;

bool DirectoryExists(LPCWSTR lpszDirectoryPath)
{
  struct _stat buffer;
  int   iRetTemp = 0;

  memset ((void*)&buffer, 0, sizeof(buffer));

  iRetTemp = _wstat(lpszDirectoryPath, &buffer);

  if (iRetTemp == 0)
  {
   if (buffer.st_mode & _S_IFDIR)
   {
      return true;
   }
   else
   {
      return false;
   }
  }
  else
  {
    return false;
  }
}

/// <summary>Returns the path to the system's temporary directory</summary>
/// <returns>The full path to the system's temporary directory</returns>
wstring GetTempFolderPath() 
{
	DWORD result = ::GetTempPath(0, L"");
	if(result == 0)
		throw std::runtime_error("Could not get system temp path");

	std::vector<WCHAR> tempPath(result /* + 1 */); // return value in the overflow case includes the terminating L'\0'
	result = ::GetTempPath(static_cast<DWORD>(tempPath.size()), &tempPath[0]);
	if((result == 0) || (result > /*=*/ tempPath.size())) // return value in the non-overflow case does not include the terminating L'\0'
		throw std::runtime_error("Could not get system temp path");

	return wstring( tempPath.begin(), tempPath.begin() + static_cast<std::size_t>(result) );
}

// =====================================================================================
HRESULT RegGetString(HKEY hKey, LPCWSTR szValueName, LPWSTR * lpszResult) {

	// Given a HKEY and value name returns a string from the registry.
	// Upon successful return the string should be freed using free()
	// eg. RegGetString(hKey, TEXT("my value"), &szString);

	DWORD dwType=0, dwDataSize=0, dwBufSize=0;
	LONG lResult;

	// Incase we fail set the return string to null...
	if (lpszResult != NULL) *lpszResult = NULL;

	// Check input parameters...
	if (hKey == NULL || lpszResult == NULL) return E_INVALIDARG;

	// Get the length of the string in bytes (placed in dwDataSize)...
	lResult = RegQueryValueEx(hKey, szValueName, 0, &dwType, NULL, &dwDataSize );

	// Check result and make sure the registry value is a string(REG_SZ)...
	if (lResult != ERROR_SUCCESS) return HRESULT_FROM_WIN32(lResult);
	else if (dwType != REG_SZ)    return DISP_E_TYPEMISMATCH;

	// Allocate memory for string - We add space for a null terminating character...
	dwBufSize = dwDataSize + (1 * sizeof(WCHAR));
	*lpszResult = (LPWSTR) malloc(dwBufSize);

	if (*lpszResult == NULL) return E_OUTOFMEMORY;

	// Now get the actual string from the registry...
	lResult = RegQueryValueEx(hKey, szValueName, 0, &dwType, (LPBYTE) *lpszResult, &dwDataSize );

	// Check result and type again.
	// If we fail here we must free the memory we allocated...
	if (lResult != ERROR_SUCCESS) { free(*lpszResult); return HRESULT_FROM_WIN32(lResult); }
	else if (dwType != REG_SZ)    { free(*lpszResult); return DISP_E_TYPEMISMATCH; }

	// We are not guaranteed a null terminated string from RegQueryValueEx.
	// Explicitly null terminate the returned string...
	(*lpszResult)[(dwBufSize / sizeof(WCHAR)) - 1] = TEXT('\0');

	return NOERROR;
}


// =====================================================================================
HRESULT RegGetDWord(HKEY hKey, LPCTSTR szValueName, DWORD * lpdwResult) {

	// Given a value name and an hKey returns a DWORD from the registry.
	// eg. RegGetDWord(hKey, TEXT("my dword"), &dwMyValue);

	LONG lResult;
	DWORD dwDataSize = sizeof(DWORD);
	DWORD dwType = 0;

	// Check input parameters...
	if (hKey == NULL || lpdwResult == NULL) return E_INVALIDARG;

	// Get dword value from the registry...
	lResult = RegQueryValueEx(hKey, szValueName, 0, &dwType, (LPBYTE) lpdwResult, &dwDataSize );

	// Check result and make sure the registry value is a DWORD(REG_DWORD)...
	if (lResult != ERROR_SUCCESS) return HRESULT_FROM_WIN32(lResult);
	else if (dwType != REG_DWORD) return DISP_E_TYPEMISMATCH;

	return NOERROR;
}

std::vector<wstring>::size_type split( const WCHAR* str, const WCHAR* delim, std::vector<wstring>& results, bool empties = true)
{
	const WCHAR* pstr = str;
	const WCHAR* r = wcsstr(pstr, delim);
	std::size_t dlen = wcslen(delim);
	while( r )
	{
		if( empties || r > pstr )
			results.push_back(wstring(pstr, wstring::size_type(r - pstr)));
		pstr = r + dlen;
		r = wcsstr(pstr, delim);
	}
	if( empties || wcslen(pstr) > 0)
		results.push_back(wstring(pstr));
	return results.size();
}



// CShellExt
CShellExt::CShellExt()
{
}

CShellExt::~CShellExt()
{
	ContextMenuEntries.clear();
	MatchingEntries.clear();
	Files.clear();
}

HRESULT CShellExt::RecurseContextMenuEntries()
{
	DWORD dwIdx=0;
	WCHAR szKeyName[1024];
	DWORD dwSize=1024;
	FILETIME fTime;
	HKEY hKey;
	ContextMenuEntries.clear();
	if(RegOpenKeyEx(HKEY_CURRENT_USER, TEXT("Software\\7plus\\ContextMenuEntries"), 0, KEY_ALL_ACCESS, &hKey) != ERROR_SUCCESS)
		return E_FAIL;
	int result = 0;
	while((result = RegEnumKeyEx(hKey, dwIdx, szKeyName, &dwSize, NULL, NULL, NULL, &fTime)) == ERROR_SUCCESS)
	{
		dwIdx++;
		dwSize = 1024;
		HKEY hSubKey;
		if (RegOpenKeyEx(hKey, szKeyName, 0, KEY_READ, &hSubKey) == ERROR_SUCCESS)
		{
			bool failed = false;
			ContextMenuEntry cme;
			DWORD id;
			LPWSTR szName;
			LPWSTR szDescription;
			LPWSTR szExtensions;
			LPWSTR szSubmenu;
			DWORD Directory;
			DWORD DirectoryBackground;
			DWORD Desktop;
			DWORD SingleFileOnly;

			if(FAILED(RegGetDWord(hSubKey, TEXT("ID"), &id)))
				failed = true;

			if(FAILED(RegGetString(hSubKey, TEXT("Name"), &szName)))
				failed = true;

			if(FAILED(RegGetString(hSubKey, TEXT("Description"), &szDescription)))
				failed = true;

			if(FAILED(RegGetString(hSubKey, TEXT("Submenu"), &szSubmenu)))
				failed = true;

			if(FAILED(RegGetString(hSubKey, TEXT("Extensions"), &szExtensions)))
				failed = true;
			
			if(FAILED(RegGetDWord(hSubKey, TEXT("Directory"), &Directory)))
				failed = true;

			if(FAILED(RegGetDWord(hSubKey, TEXT("DirectoryBackground"), &DirectoryBackground)))
				failed = true;
			
			if(FAILED(RegGetDWord(hSubKey, TEXT("Desktop"), &Desktop)))
				failed = true;

			if(FAILED(RegGetDWord(hSubKey, TEXT("SingleFileOnly"), &SingleFileOnly)))
				failed = true;

			if(!failed)
			{
				cme.ID = id;
				cme.Name = szName;
				cme.Description = szDescription;
				cme.SubMenu = szSubmenu;
				cme.Directory = Directory > 0;
				cme.DirectoryBackground = DirectoryBackground > 0;
				cme.Desktop = Desktop > 0;
				cme.SingleFileOnly = SingleFileOnly > 0;
				wstring extensions = wstring(szExtensions);
				vector<wstring> vExtensions;		  
				split(extensions.c_str(),L",",vExtensions,false);
				cme.Extensions = vExtensions;
				ContextMenuEntries.push_back(cme); //Creates a copy of cme, should be valid
				RegCloseKey(hSubKey);
				free(szName);
				free(szDescription);
				free(szSubmenu);
				free(szExtensions);
				ATLTRACE(L"Error in context menu registry entries\n");
			}
		}
	}
	if(hKey != NULL)
		RegCloseKey(hKey);
	return 0;
}
/////////////////////////////////////////////////////////////////////////////
// CShellExt IShellExtInit methods

//////////////////////////////////////////////////////////////////////////
//
// Function:    Initialize()
//
// Description:
//  Reads in the list of selected folders and stores them for later use.
//
//////////////////////////////////////////////////////////////////////////
HRESULT CShellExt::Initialize ( LPCITEMIDLIST pidlFolder, LPDATAOBJECT pDO, HKEY hProgID )
{
	WCHAR     szFile[MAX_PATH];
	UINT      uNumFiles;
	HDROP     hdrop;
	FORMATETC etc = { CF_HDROP, NULL, DVASPECT_CONTENT, -1, TYMED_HGLOBAL };
	STGMEDIUM stg = { TYMED_HGLOBAL };
	bool      bChangedDir = false;

	//Check if 7plus is running
	wstring TempPath = GetTempFolderPath();//test this for leak
	FILE * pFile;
	wstring test = TempPath + L"7plus\\hwnd.txt";
	errno_t err;
	err = _wfopen_s(&pFile,(TempPath + L"7plus\\hwnd.txt").c_str(), L"r");
	if (pFile == NULL) return E_INVALIDARG; //7plus not running
	fclose(pFile);

    // Read the list of folders from the data object.  They're stored in HDROP
    // form, so just get the HDROP handle and then use the drag 'n' drop APIs
    // on it.
	if(pDO != NULL) //Might be NULL on DirectoryBackground
	{
		if ( FAILED( pDO->GetData ( &etc, &stg ) ))
			return E_INVALIDARG;

		// Get an HDROP handle.
		hdrop = (HDROP) GlobalLock ( stg.hGlobal );

		if ( NULL == hdrop )
		{
			ReleaseStgMedium ( &stg );
			return E_INVALIDARG;
		} 
		// Determine how many files are involved in this operation.
		uNumFiles = DragQueryFile ( hdrop, 0xFFFFFFFF, NULL, 0 );
	}
	else
		uNumFiles = 1;

	//check the registry and load context menu entries that should be shown
	RecurseContextMenuEntries();

	if(ContextMenuEntries.size() == 0)
		return E_INVALIDARG;

	MatchingEntries.clear();
	//look for matching extensions
	bool FirstIteration = true;
	for(unsigned int i = 0; i < ContextMenuEntries.size(); i++)
	{
		if(ContextMenuEntries[i].SingleFileOnly && uNumFiles > 1)
			continue;
		bool Show = true;
		//Check if all files match
		for ( UINT uFile = 0; uFile < uNumFiles; uFile++ )
		{
			bool Background = false;
			// Get the next filename.
			if ( pDO != NULL)
			{
				if ( 0 == DragQueryFile ( hdrop, uFile, szFile, MAX_PATH ) )
					continue;
			}
			else	//Check for directory background
			{
				 if (pidlFolder == NULL || !SHGetPathFromIDList(pidlFolder, szFile) )
					continue;
				 Background = true;
				 if(i==0)
					Files.push_back(szFile);
			}
			if(FirstIteration && !Background)
				Files.push_back(szFile);
			//ContextMenu on directory
			bool Directory = DirectoryExists(szFile);
			if(Directory && !Background && ContextMenuEntries[i].Directory)
				continue;

			//ContextMenu on directory background
			if(Background && ContextMenuEntries[i].DirectoryBackground)
				continue;

			//ContextMenu on desktop background
			LPITEMIDLIST pidlDesktop;
			SHGetFolderLocation(NULL,CSIDL_DESKTOP,0,0,&pidlDesktop);
			//SHGetKnownFolderIDList(FOLDERID_Desktop,0,NULL, &pidlDesktop);
			WCHAR szDesktop[MAX_PATH];
			SHGetPathFromIDList(pidlDesktop,szDesktop);
			if(_wcsicmp(szDesktop, szFile) == 0 && ContextMenuEntries[i].Desktop)
				continue;

			//ContextMenu on files
			WCHAR szFolder[MAX_PATH];
			lstrcpyn ( szFolder, szFile, countof(szFolder) );
			PathRemoveFileSpec ( szFolder );
			WCHAR * szExtension = PathFindExtension(szFile);
			//Check for file extensions, case insensitive	
			if(!Directory)
			{
				bool found = false;
				for(unsigned int j = 0; j < ContextMenuEntries[i].Extensions.size(); j++)
				{
					if(ContextMenuEntries[i].Extensions.size() > 0 && (_wcsicmp(ContextMenuEntries[i].Extensions[j].c_str(),L"*") == 0 || _wcsicmp((L"." + ContextMenuEntries[i].Extensions[j]).c_str(),szExtension) == 0))
					{
						found = true;
						break;
					}
				}
				if(found)
					continue;
			}
			//if we arrive here, nothing matched and this context menu extension shouldn't be shown
			Show = false;
		}		
		FirstIteration = false;
		if(Show)
			MatchingEntries.push_back(i);      
    }

    // Release resources.
    GlobalUnlock ( stg.hGlobal );
    ReleaseStgMedium ( &stg );

    // If we found any files we can work with, return S_OK.  Otherwise,
    // return E_INVALIDARG so we don't get called again for this right-click
    // operation.
    return (MatchingEntries.size() > 0) ? S_OK : E_INVALIDARG;
}

/////////////////////////////////////////////////////////////////////////////
// CShellExt IContextMenu methods

//////////////////////////////////////////////////////////////////////////
//
// Function:    QueryContextMenu()
//
// Description:
//  Adds our items to the supplied menu.
//
//////////////////////////////////////////////////////////////////////////

HRESULT CShellExt::QueryContextMenu ( HMENU hmenu, UINT uMenuIndex, UINT uidFirstCmd, UINT uidLastCmd, UINT uFlags )
{
    // If the flags include CMF_DEFAULTONLY then we shouldn't do anything.
    if ( uFlags & CMF_DEFAULTONLY )
        return MAKE_HRESULT ( SEVERITY_SUCCESS, FACILITY_NULL, 0 );
	map<wstring,HMENU> submenus;
	int count = 0;
	for(unsigned int i = 0; i < MatchingEntries.size(); i++)
	{
		if(_wcsicmp(ContextMenuEntries[MatchingEntries[i]].SubMenu.c_str(), L"") != 0)
		{
			if(submenus.find(ContextMenuEntries[MatchingEntries[i]].SubMenu) == submenus.end())
			{
				submenus[ContextMenuEntries[MatchingEntries[i]].SubMenu] = CreatePopupMenu();
				//Create submenu
				InsertMenu(hmenu, uMenuIndex, MF_STRING | MF_BYPOSITION | MF_POPUP,(UINT_PTR) submenus[ContextMenuEntries[MatchingEntries[i]].SubMenu], ContextMenuEntries[MatchingEntries[i]].SubMenu.c_str());
				uMenuIndex++;
			}
			InsertMenu(submenus[ContextMenuEntries[MatchingEntries[i]].SubMenu], -1, MF_STRING | MF_BYPOSITION, uidFirstCmd + count, ContextMenuEntries[MatchingEntries[i]].Name.c_str());
			count++;
		}
		else
		{
			// Add the menu item
			InsertMenu ( hmenu, uMenuIndex, MF_STRING | MF_BYPOSITION, uidFirstCmd + count, ContextMenuEntries[MatchingEntries[i]].Name.c_str() );
			uMenuIndex++;
			count++;
		}
	}
	
    // The return value tells the shell how many top-level items we added.
    return MAKE_HRESULT ( SEVERITY_SUCCESS, FACILITY_NULL, count );
}


//////////////////////////////////////////////////////////////////////////
//
// Function:    GetCommandString()
//
// Description:
//  Sets the flyby help string for the Explorer status bar.
//
//////////////////////////////////////////////////////////////////////////

HRESULT CShellExt::GetCommandString ( UINT_PTR uCmdID, UINT uFlags, UINT* puReserved, LPSTR szName, UINT cchMax )
{
	USES_CONVERSION;
	LPCWSTR szPrompt; //test this for leak

    if ( uFlags & GCS_HELPTEXT )
    {
		if(uCmdID < MatchingEntries.size() && MatchingEntries[uCmdID] < ContextMenuEntries.size())
			szPrompt = ContextMenuEntries[MatchingEntries[uCmdID]].Description.c_str();//test this for leak
		else
			szPrompt = L"No Description found??";
        // Copy the help text into the supplied buffer.  If the shell wants
        // a Unicode string, we need to cast szName to an LPCWSTR.
        if ( uFlags & GCS_UNICODE )
            lstrcpynW ( (LPWSTR) szName, szPrompt, cchMax );//test this for leak
        else
            lstrcpynA ( szName, W2CA(szPrompt), cchMax );//test this for leak
    }
    else if ( uFlags & GCS_VERB )
    {
        // Copy the verb name into the supplied buffer.  If the shell wants
        // a Unicode string, we need to case szName to an LPCWSTR.
		
		WCHAR wbuffer[50];
		char buffer[50];
		if(uCmdID < MatchingEntries.size() && MatchingEntries[uCmdID] < ContextMenuEntries.size())
		{
			swprintf_s (wbuffer, 50, L"7plus%d", ContextMenuEntries[MatchingEntries[uCmdID]].ID);
			sprintf_s(buffer, 50, "7plus%d", ContextMenuEntries[MatchingEntries[uCmdID]].ID);
		}
		else
		{
			swprintf_s(wbuffer, 50, L"7plus");
			sprintf_s(buffer, 50, "7plus");
		}
		if ( uFlags & GCS_UNICODE )
            lstrcpynW ( (LPWSTR) szName, wbuffer , cchMax );//test this for leak
        else
            lstrcpynA ( szName, buffer, cchMax );//test this for leak
    }

    return S_OK;
}


//////////////////////////////////////////////////////////////////////////
//
// Function:    InvokeCommand()
//
// Description:
//  Carries out the selected command.
//
//////////////////////////////////////////////////////////////////////////

HRESULT CShellExt::InvokeCommand ( LPCMINVOKECOMMANDINFO pInfo )
{
    // If lpVerb really points to a string, ignore this function call and bail out.  
    if ( 0 != HIWORD( pInfo->lpVerb ) )
        return E_INVALIDARG;

    // Check that lpVerb is one of our commands
	if(LOWORD(pInfo->lpVerb) < MatchingEntries.size() && MatchingEntries[LOWORD(pInfo->lpVerb)] < ContextMenuEntries.size())
	{
		wstring TempPath = GetTempFolderPath();//test this for leak

		FILE * pFile;
		char buffer [100];
		wstring test = TempPath + L"7plus\\hwnd.txt";
		errno_t err;
		err = _wfopen_s(&pFile,(TempPath + L"7plus\\hwnd.txt").c_str(), L"r");
		if (pFile == NULL) return S_OK; //7plus not running
		else
		{
			if( ! feof (pFile) ) //read hwnd stored in %TEMP%\\7plus\\hwnd.txt
			{
				fgets(buffer, 100, pFile);
				HWND hwnd;
				sscanf_s(buffer,"%X",&hwnd);
				WINDOWPLACEMENT wp;
				if(GetWindowPlacement(hwnd,&wp))
				{
					FILE * pFiles;
					_wfopen_s(&pFiles, (TempPath + L"7plus\\files.txt").c_str(), L"w");
					if (pFiles!=NULL)
					{
						for(unsigned int i = 0; i < Files.size(); i++)
							fputws((Files[i]  + L"\n").c_str(), pFiles);
						fclose(pFiles);
						SendMessage(hwnd, 55555, ContextMenuEntries[MatchingEntries[LOWORD(pInfo->lpVerb)]].ID, 1);
					}						
				}
			}
			fclose (pFile);
		}
	}
	return S_OK;
}