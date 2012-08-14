Class CRegistryPlugin extends CAccessorPlugin
{
	;Register this plugin with the Accessor main object
	static Type := CAccessor.RegisterPlugin("Registry", CRegistryPlugin)
	
	Description := "This plugin allows to quickly open registry keys in RegEdit.`nThe easiest way is to select a registry key in another application,`nopen Accessor and press Enter to open the key."
	
	AllowDelayedExecution := false
	
	Column1Text := "Registry Key"
	Column2Text := "Action"
	
	Class CSettings extends CAccessorPlugin.CSettings
	{
		Keyword := "reg"
		KeywordOnly := true
		MinChars := 4
		CloseRegedit := true
		UseSelectedText := true
	}

	Class CResult extends CAccessorPlugin.CResult
	{
		Class CActions extends CArray
		{
			DefaultAction := new CAccessor.CAction("Open Key", "OpenKey")
			__new()
			{
			}
		}
		Type := "Registry"
		Actions := new this.CActions()
		Priority := CRegistryPlugin.Instance.Priority
		MatchQuality := 1 ;Only one result which matches perfectly
		Path := "Open Registry"
		Detail1 := "Registry"
	}

	IsInSinglePluginContext(Filter, LastFilter)
	{
		return IsRegKey(Filter) ? true : false
	}

	OnOpen(Accessor)
	{
		if(this.Settings.UseSelectedText && !Accessor.FilterWithoutTimer && !Accessor.Filter && Accessor.SelectedText && IsRegKey(Accessor.SelectedText))
			Accessor.SetFilter(Accessor.SelectedText)
	}

	ShowSettings(PluginSettings, GUI, PluginGUI)
	{
		AddControl(PluginSettings, PluginGUI, "Checkbox", "CloseRegedit", "Close open Regedit windows when opening key (recommended)", "", "", "", "", "", "", "This is suggested since there might be problems`n to open the correct key when Regedit is already running.")
		AddControl(PluginSettings, PluginGUI, "Checkbox", "UseSelectedText", "Automatically open the selected text as registry path in Accessor when appropriate", "", "")
	}

	RefreshList(Accessor, Filter, LastFilter, KeywordSet, Parameters)
	{
		Results := Array()
		
		if(Filter := IsRegKey(Filter))
		{
			Result := new this.CResult()
			Result.Title := Filter
			Result.Icon := Accessor.GenericIcons.Folder
			Results.Insert(Result)
		}
		return Results
	}

	OpenKey(Accessor, ListEntry)
	{
		if(ListEntry.Title)
		{
			while(this.Settings.CloseRegedit && hwnd := WinExist("ahk_class RegEdit_RegEdit"))
				WinClose, ahk_id %hwnd%
			Path := ListEntry.Title
			Name := ""
			RegistryKeyType(Path, Name, Path)
			RegWrite, Reg_SZ, HKCU, Software\Microsoft\Windows\CurrentVersion\Applets\Regedit, LastKey, % "Computer\" Path
			run RegEdit,, UseErrorLevel
		}
	}
}



;Determines if a string is a registry key. Returns the full length version of it if it is.
IsRegKey(Key)
{
	Keys := ["HKLM", "HKCU", "HKCR", "HKU", "HKCC", "HKEY_LOCAL_MACHINE", "HKEY_USERS", "HKEY_CURRENT_USER", "HKEY_CLASSES_ROOT", "HKEY_CURRENT_CONFIG"]
	for index, k in Keys
		if(InStr(Key, k "\") = 1)
		{
			if(StrLen(k) <= 4)
				Key := StringReplace(Key, k, {HKCU : "HKEY_CURRENT_USER", HKLM : "HKEY_LOCAL_MACHINE", HKCR : "HKEY_CLASSES_ROOT", HKU : "HKEY_USERS", HKCC : "HKEY_CURRENT_CONFIG"}[k])
			return Key
		}
}

;Gets the type of a registry key. 0 if not existing, 1 if value, 2 if key
RegistryKeyType(CheckRegPath, ByRef ValueName = "", ByRef Dir = "")
{
	StrLen:=InStr(CheckRegPath,"\")
	StringLeft, RootK, CheckRegPath, % StrLen-1
	StringRight, PathK, CheckRegPath, % StrLen(CheckRegPath)-Strlen
	KeyExist=0
	Loop, %RootK%, %PathK%, 1, 0
		return 2
	ValueName := SubStr(PathK, InStr(PathK, "\", 0, 0) + 1)
	StringLeft, PathK, PathK, % StrLen(PathK) - StrLen(ValueName) -1
	Dir := RootK "\" PathK
	Loop, %RootK%, %Dir%, 0, 0
		if(A_LoopRegName = ValueName)
			return 1
	return 0
}