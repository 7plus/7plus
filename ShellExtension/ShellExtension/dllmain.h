// dllmain.h : Deklaration der Modulklasse.

class CShellExtensionModule : public ATL::CAtlDllModuleT< CShellExtensionModule >
{
public :
	DECLARE_LIBID(LIBID_ShellExtensionLib)
	DECLARE_REGISTRY_APPID_RESOURCEID(IDR_SHELLEXTENSION, "{BC14DE6F-AEFC-4916-A0D6-64EB7B1FAB6C}")
};

extern class CShellExtensionModule _AtlModule;
