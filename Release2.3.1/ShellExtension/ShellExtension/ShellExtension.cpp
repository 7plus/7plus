// ShellExtension.cpp : Implementierung von DLL-Exporten.


#include "stdafx.h"
#include "resource.h"
#include "ShellExtension_i.h"
#include "dllmain.h"
#include <atlbase.h>
#include "ShellExt.h"
#include <initguid.h>

// Wird verwendet, um festzustellen, ob die DLL von OLE entladen werden kann.
STDAPI DllCanUnloadNow(void)
{
			return _AtlModule.DllCanUnloadNow();
	}

// Gibt eine Klassenfactory zurück, um ein Objekt vom angeforderten Typ zu erstellen.
STDAPI DllGetClassObject(REFCLSID rclsid, REFIID riid, LPVOID* ppv)
{
		return _AtlModule.DllGetClassObject(rclsid, riid, ppv);
}

// DllRegisterServer - Fügt der Systemregistrierung Einträge hinzu.
STDAPI DllRegisterServer(void)
{
	 // If we're on NT, add ourselves to the list of approved shell extensions.

    // Note that you should *NEVER* use the overload of CRegKey::SetValue with
    // 4 parameters.  It lets you set a value in one call, without having to 
    // call CRegKey::Open() first.  However, that version of SetValue() has a
    // bug in that it requests KEY_ALL_ACCESS to the key.  That will fail if the
    // user is not an administrator.  (The code should request KEY_WRITE, which
    // is all that's necessary.)

    if ( 0 == (GetVersion() & 0x80000000UL) )
        {
        CRegKey reg;
        LONG    lRet;

        lRet = reg.Open ( HKEY_LOCAL_MACHINE,
                          _T("Software\\Microsoft\\Windows\\CurrentVersion\\Shell Extensions\\Approved"),
                          KEY_SET_VALUE );

        if ( ERROR_SUCCESS != lRet )
            return E_ACCESSDENIED;

        lRet = reg.SetStringValue ( _T("7plus Shell extension"), 
                              _T("{F547E0EF-E87C-4639-B831-2DE08AD102E9}") );

        if ( ERROR_SUCCESS != lRet )
            return E_ACCESSDENIED;
        }

	// Registriert Objekt, Typelib und alle Schnittstellen in Typelib.
	HRESULT hr = _AtlModule.DllRegisterServer(FALSE);
		return hr;
}

// DllUnregisterServer - Entfernt Einträge aus der Systemregistrierung.
STDAPI DllUnregisterServer(void)
{
	 // If we're on NT, remove ourselves from the list of approved shell extensions.
    // Note that if we get an error along the way, I don't bail out since I want
    // to do the normal ATL unregistration stuff too.
    if ( 0 == (GetVersion() & 0x80000000UL) )
    {
		CRegKey reg;
		LONG    lRet;

		lRet = reg.Open ( HKEY_LOCAL_MACHINE, _T("Software\\Microsoft\\Windows\\CurrentVersion\\Shell Extensions\\Approved"), KEY_SET_VALUE );

		if ( ERROR_SUCCESS == lRet )
			lRet = reg.DeleteValue ( _T("{F547E0EF-E87C-4639-B831-2DE08AD102E9}") );
    }
	HRESULT hr = _AtlModule.DllUnregisterServer(FALSE);
		return hr;
}

// DllInstall - Fügt der Systemregistrierung pro Benutzer pro Computer Einträge hinzu oder entfernt sie.
STDAPI DllInstall(BOOL bInstall, LPCWSTR pszCmdLine)
{
	HRESULT hr = E_FAIL;
	static const wchar_t szUserSwitch[] = L"user";

	if (pszCmdLine != NULL)
	{
		if (_wcsnicmp(pszCmdLine, szUserSwitch, _countof(szUserSwitch)) == 0)
		{
			ATL::AtlSetPerUserRegistration(true);
		}
	}

	if (bInstall)
	{	
		hr = DllRegisterServer();
		if (FAILED(hr))
		{
			DllUnregisterServer();
		}
	}
	else
	{
		hr = DllUnregisterServer();
	}

	return hr;
}


