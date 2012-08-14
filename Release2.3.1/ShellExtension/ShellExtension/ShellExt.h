// ShellExt.h: Deklaration von CShellExt

#pragma once
#include "resource.h"       // Hauptsymbole


#include <vector>
using namespace std;

#include "ShellExtension_i.h"

#include <shlobj.h>

#include <comdef.h>

#include <atlconv.h>

#if defined(_WIN32_WCE) && !defined(_CE_DCOM) && !defined(_CE_ALLOW_SINGLE_THREADED_OBJECTS_IN_MTA)
#error "Singlethread-COM-Objekte werden auf der Windows CE-Plattform nicht vollständig unterstützt. Windows Mobile-Plattformen bieten beispielsweise keine vollständige DCOM-Unterstützung. Definieren Sie _CE_ALLOW_SINGLE_THREADED_OBJECTS_IN_MTA, um ATL zu zwingen, die Erstellung von Singlethread-COM-Objekten zu unterstützen und die Verwendung eigener Singlethread-COM-Objektimplementierungen zu erlauben. Das Threadmodell in der RGS-Datei wurde auf 'Free' festgelegt, da dies das einzige Threadmodell ist, das auf Windows CE-Plattformen ohne DCOM unterstützt wird."
#endif

using namespace ATL;


// CShellExt

class ATL_NO_VTABLE CShellExt :
	public CComObjectRootEx<CComSingleThreadModel>,
	public CComCoClass<CShellExt, &CLSID_ShellExt>,
	public IShellExtInit,
	public IContextMenu
{
public:
	CShellExt();
	~CShellExt();
	HRESULT RecurseContextMenuEntries();
	STDMETHODIMP Initialize(LPCITEMIDLIST, LPDATAOBJECT, HKEY);
	STDMETHODIMP GetCommandString(UINT_PTR, UINT, UINT*, LPSTR, UINT);
	STDMETHODIMP InvokeCommand(LPCMINVOKECOMMANDINFO);
	STDMETHODIMP QueryContextMenu(HMENU, UINT, UINT, UINT, UINT);

DECLARE_REGISTRY_RESOURCEID(IDR_SHELLEXT)

DECLARE_NOT_AGGREGATABLE(CShellExt)

BEGIN_COM_MAP(CShellExt)
	COM_INTERFACE_ENTRY(IShellExtInit)
	COM_INTERFACE_ENTRY(IContextMenu)
END_COM_MAP()



	DECLARE_PROTECT_FINAL_CONSTRUCT()

	HRESULT FinalConstruct()
	{
		return S_OK;
	}

	void FinalRelease()
	{
	}
protected:
	struct ContextMenuEntry {
	  int ID;
	  wstring Name;
	  wstring Description;
	  wstring SubMenu;
	  vector<wstring> Extensions;
	  bool Directory;
	  bool DirectoryBackground;
	  bool Desktop;
	  bool SingleFileOnly;
	} ;
	vector<ContextMenuEntry> ContextMenuEntries;
	vector<unsigned int> MatchingEntries;
	vector<wstring> Files;
};

OBJECT_ENTRY_AUTO(__uuidof(ShellExt), CShellExt)
