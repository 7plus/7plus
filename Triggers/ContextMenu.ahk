Class CContextMenuTrigger Extends CTrigger
{
	static Type := RegisterType(CContextMenuTrigger, "Context menu")	
	static Category := RegisterCategory(CContextMenuTrigger, "Explorer")
	static __WikiLink := "ContextMenu"
	static Name := "Context menu entry"
	static Description := "Context menu entry description"
	static SubMenu := ""
	static Directory := false
	static DirectoryBackground := false
	static Desktop := false
	static Computer := false
	static SingleFileOnly := false
	static FileTypes := "*"
	
	Enable(Event)
	{
		if(A_IsCompiled)
			ahk_path:="""" A_ScriptDir "\7plus.exe"""
		else
			ahk_path := """" A_AhkPath """ """ A_ScriptFullPath """"
		id := Event.ID
		RegWrite, REG_DWORD, HKCU, Software\7plus\ContextMenuEntries\%id%, ID, %id%
		RegWrite, REG_SZ, HKCU, Software\7plus\ContextMenuEntries\%id%, Name, % this.Name
		RegWrite, REG_SZ, HKCU, Software\7plus\ContextMenuEntries\%id%, Description, % this.Description
		RegWrite, REG_SZ, HKCU, Software\7plus\ContextMenuEntries\%id%, Submenu, % this.Submenu
		RegWrite, REG_SZ, HKCU, Software\7plus\ContextMenuEntries\%id%, Extensions, % this.FileTypes
		RegWrite, REG_DWORD, HKCU, Software\7plus\ContextMenuEntries\%id%, Directory, % this.Directory
		RegWrite, REG_DWORD, HKCU, Software\7plus\ContextMenuEntries\%id%, DirectoryBackground, % this.DirectoryBackground
		RegWrite, REG_DWORD, HKCU, Software\7plus\ContextMenuEntries\%id%, Desktop, % this.Desktop
		RegWrite, REG_DWORD, HKCU, Software\7plus\ContextMenuEntries\%id%, SingleFileOnly, % this.SingleFileOnly

		if(this.Computer)
		{
			if(this.SubMenu = "")
				key := "shell\" this.Name "\command"
			else
			{
				key := "shell\" this.SubMenu
				RegWrite, REG_SZ, HKCR, CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}\%key%,subcommands,
				key := "shell\" this.SubMenu "\shell\" this.Name
				RegWrite, REG_SZ, HKCR, CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}\%key%,, %name%
			}
			RegWrite, REG_SZ, HKCR, CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}\%key%,, %ahk_path% -ContextID:%id%
		}
	}
	Disable()
	{
		RegDelete, HKCU, Software\7plus\ContextMenuEntries
		if(this.Computer)
		{
			if(this.SubMenu = "")
			{
				key := "CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}\shell\" this.Name
				RegDelete, HKCR, %key%
			}
			else
			{
				key := "CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}\shell\" this.SubMenu "\shell\" this.Name
				RegDelete, HKCR, %key%
				key := "CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}\shell\" this.SubMenu "\shell"
				found := false
				Loop, HKCR , %key%, 2, 0
				{
					found := true
					break
				}
				if(!found)
				{
					key := "CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}\shell\" this.SubMenu
					RegDelete, HKCR, %key%
				}
			}
		}
	}
	;When ContextMenu is deleted, it needs to be removed from ContextMenuarrays
	Delete()
	{
		this.Disable()
	}

	Matches(Filter, Event)
	{
		return false ;Match is handled in Eventsystem.ahk through trigger event
	}

	DisplayString()
	{
		return "Context menu: " this.Name
	}

	GuiShow(GUI)
	{
		this.AddControl(GUI, "Text", "tmpText", "This trigger allows you to add context menu entries.")
		this.AddControl(GUI, "Edit", "Name", "", "", "Name:")
		this.AddControl(GUI, "Edit", "Description", "", "", "Description:")
		this.AddControl(GUI, "Edit", "SubMenu", "", "", "Submenu:")
		this.AddControl(GUI, "Edit", "FileTypes", "", "", "File types:", "", "", "", "", "File extensions separated by comma")
		this.AddControl(GUI, "Checkbox", "Directory", "Show in directory context menus")
		this.AddControl(GUI, "Checkbox", "DirectoryBackground", "Show in directory background context menus")
		this.AddControl(GUI, "Checkbox", "Desktop", "Show in desktop context menu")
		this.AddControl(GUI, "Checkbox", "Computer", "Show in ""My Computer"" context menus")
		this.AddControl(GUI, "Checkbox", "SingleFileOnly", "Don't show with multiple files selected")
		this.AddControl(GUI, "Button", "Register", "Register context menu shell extension", "RegisterShellExtension", "")
		this.AddControl(GUI, "Button", "Unregister", "Unregister context menu shell extension", "UnregisterShellExtension", "")
	}
}
RegisterShellExtension:
RegisterShellExtension(0)
return
UnregisterShellExtension:
Msgbox, 4, Unregister Shell Extension?, WARNING: If you unregister the shell extension, 7plus will not be able`n to show context menu entries. Do this only if you have problems with the shell extension.`nDo you really want to do this?
IfMsgbox Yes
	UnregisterShellExtension(0)
return

RegisterShellExtension(Silent=1)
{
	if(!ApplicationState.IsPortable)
	{
		if(WinVer >= WIN_Vista)
			uacrep := DllCall("shell32\ShellExecute", uint, 0, str, "RunAs", str, "regsvr32", str, "/s """ A_ScriptDir "\ShellExtension.dll""", str, A_ScriptDir, int, 1)
		else
			run regsvr32 /s "%A_ScriptDir%\ShellExtension.dll"
		If(uacrep = 42 || WinVer < WIN_Vista) ;UAC Prompt confirmed, application may run as admin
		{
			if(!Silent)
				MsgBox Shell extension successfully installed. Context menu entries defined in 7plus should now be visible.
		}
		else ;Always show error
			MsgBox Unable to install the context menu shell extension. Please grant Admin permissions!
	}
	else if(!Silent)
		MsgBox Context menu shell extension can only be used in non-portable mode for now.
}
UnregisterShellExtension(Silent=1)
{
	if(!ApplicationState.IsPortable)
	{
		if(WinVer >= WIN_Vista)
			uacrep := DllCall("shell32\ShellExecute", uint, 0, str, "RunAs", str, "regsvr32", str, "/s /u """ A_ScriptDir "\ShellExtension.dll""", str, A_ScriptDir, int, 1)
		else
			run regsvr32 /s /u "%A_ScriptDir%\ShellExtension.dll"
		If(uacrep = 42 || WinVer < WIN_Vista) ;UAC Prompt confirmed, application may run as admin
		{
			if(!Silent)
				MsgBox Shell extension successfully deinstalled. All 7plus context menu entries should now be gone.
		}
		else ;Always show error
			MsgBox Unable to deinstall the context menu shell extension. Please grant Admin permissions!
	}
	else if(!Silent)
		MsgBox Context menu shell extension can only be used in non-portable mode for now.
}
