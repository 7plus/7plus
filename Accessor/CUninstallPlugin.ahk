Class CUninstallPlugin extends CAccessorPlugin
{
	;Register this plugin with the Accessor main object
	static Type := CAccessor.RegisterPlugin("Uninstall", CUninstallPlugin)
	
	Description := "This plugin lets you uninstall programs or remove the uninstall entries from the list."
	
	;List containing the uninstallation entries
	List := Array()
	
	;This plugin is not listed by the history plugin because the results may not be valid anymore.
	SaveHistory := false

	AllowDelayedExecution := false
	
	Column2Text := "Install path"

	Class CSettings extends CAccessorPlugin.CSettings
	{
		Keyword := "Uninstall"
		KeywordOnly := true
		MinChars := 0
		FuzzySearch := false
	}

	Class CResult extends CAccessorPlugin.CResult
	{
		Class CActions extends CArray
		{
			DefaultAction := new CAccessor.CAction("Uninstall", "Uninstall", "", true, false)
			__new()
			{
				this.Insert(new CAccessor.CAction("Remove entry", "RemoveUninstallEntry", "", false, false, true, A_WinDir "\System32\Shell32.dll", 132))
				this.Insert(new CAccessor.CAction("Open installation path in explorer`tCTRL + E", "OpenExplorer", new Delegate(CUninstallPlugin.CResult.CActions, "HasInstallLocation"), true, false, true, A_WinDir "\System32\Shell32.dll", 4))
				this.Insert(new CAccessor.CAction("Open installation path in CMD", "OpenCMD", new Delegate(CUninstallPlugin.CResult.CActions, "HasInstallLocation"), true, false, true, A_WinDir "\System32\cmd.exe", 1))
				this.Insert(new CAccessor.CAction("Copy installation path`tCTRL + C", "Copy", new Delegate(CUninstallPlugin.CResult.CActions, "HasInstallLocation"), false, false))
			}
			HasInstallLocation(ListEntry)
			{
				return InStr(FileExist(ListEntry.Path), "D")
			}
		}
		Type := "Uninstall"
		Actions := new this.CActions()
		Priority := CUninstallPlugin.Instance.Priority
	}

	IsInSinglePluginContext(Filter, LastFilter)
	{
		return false
	}

	OnOpen(Accessor)
	{
		this.List := Array()
	}

	OnClose(Accessor)
	{
		for index, ListEntry in this.List
			if(ListEntry.Icon != Accessor.GenericIcons.Application)			
				DestroyIcon(ListEntry.Icon)
		this.List := Array()
	}

	RefreshList(Accessor, Filter, LastFilter, KeywordSet, Parameters)
	{
		;Lazy loading
		if(this.List.MaxIndex() = 0)
		{
			outputdebug pre load
			this.LoadUninstallEntries()
			outputdebug post load
		}
		Results := Array()
		for index, ListEntry in this.List
		{
			if((MatchQuality := FuzzySearch(ListEntry.DisplayName, Filter, this.Settings.FuzzySearch) > Accessor.Settings.FuzzySearchThreshold))
			{
				Result := new this.CResult()
				Result.Title := ListEntry.DisplayName
				Result.UninstallString := ListEntry.UninstallString
				Result.Path := ListEntry.InstallLocation
				Result.GUID := ListEntry.GUID
				Result.Icon := ListEntry.Icon
				Result.MatchQuality := MatchQuality
				Results.Insert(Result)
			}
		}
		outputdebug plugin refreshlist finish
		return Results
	}

	Uninstall(Accessor, ListEntry)
	{
		Run(ListEntry.UninstallString)
	}

	RemoveUninstallEntry(Accessor, ListEntry)
	{
		RegDelete, HKLM, % "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" ListEntry.GUID
		key := this.List.FindKeyWithValue("GUID", ListEntry.GUID)
		if(key)
		{
			this.List.Remove(key)
			Accessor.RefreshList()
		}
	}
	
	LoadUninstallEntries()
	{
		outputdebug LoadUninstallEntries start
		Loop, HKLM , SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, 2, 0
		{
			GUID := A_LoopRegName ;Note: This is not always a GUID but can also be a regular name. It seems that MSIExec likes to use GUIDs
			RegRead, DisplayName, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%GUID%, DisplayName
			RegRead, UninstallString, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%GUID%, UninstallString
			RegRead, InstallLocation, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%GUID%, InstallLocation
			RegRead, DisplayIcon, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%GUID%, DisplayIcon

			;The presence of this key indicates an update which should not be shown here
			RegRead, ParentKeyName, HKLM, SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%GUID%, ParentKeyName
			if(ErrorLevel)
			{
				DisplayIcon := UnQuote(DisplayIcon)
				if(RegexMatch(DisplayIcon, ".+,\d*"))
				{
					Number := strTrim(SubStr(DisplayIcon, InStr(DisplayIcon, ",", 0, 0) + 1), " ")
					DisplayIcon := strTrim(SubStr(DisplayIcon, 1, InStr(DisplayIcon, ",", 0, 0) - 1), " ")
				}
				DisplayIcon := UnQuote(DisplayIcon)
				if((flags := FileExist(AppendPaths(InstallLocation, DisplayIcon))) && !InStr(flags, "D"))
					DisplayIcon := AppendPaths(InstallLocation, DisplayIcon)
				else if(FileExist(A_WinDir "\Installer\" GUID "\ARPPRODUCTICON.exe"))
					DisplayIcon := A_WinDir "\Installer\" GUID "\ARPPRODUCTICON.exe"
				;outputdebug % DisplayName ": " DisplayIcon ":" FileExist(DisplayIcon)
				if(!Number)
					Number := 0
				if(FileExist(DisplayIcon))
				{
					hIcon := LoadIcon(DisplayIcon)
					;if(DisplayIcon = A_WinDir "\Installer\" GUID "\ARPPRODUCTICON.exe")
						;outputdebug % DisplayName ":" DisplayIcon ": " hIcon 
					if(hIcon = 0)
						hIcon := ExtractAssociatedIcon(Number, DisplayIcon, iIndex)
				}
				else
					hIcon := CAccessor.Instance.GenericIcons.Application
				if(DisplayName)
					this.List.Insert(Object("GUID", GUID, "DisplayName", DisplayName, "UninstallString", UninstallString, "InstallLocation", InstallLocation, "Icon", hIcon))
			}
		}
		outputdebug LoadUninstallEntries end
	}
}