Class CSciTE4AutoHotkeyPlugin extends CAccessorPlugin
{
	;Register this plugin with the Accessor main object
	static Type := CAccessor.RegisterPlugin("SciTE4AutoHotkey Tab Switcher", CSciTE4AutoHotkeyPlugin)
	
	Description := "Activate a specific SciTE4AutoHotkey tab by typing a part of its name. This plugin restores the text `nwhich was previously entered when the current tab was last active. `nThis way you can quicly switch between the most used tabs."
		
	MRUList := Array()
	
	WindowClassName := "SciTEWindow"
	
	;This plugin is not listed by the history plugin because the results may not be valid anymore.
	SaveHistory := false

	AllowDelayedExecution := false
	
	Class CSettings extends CAccessorPlugin.CSettings
	{
		Keyword := "sc"
		KeywordOnly := false
		FuzzySearch := false
		MinChars := 0 ;This is actually 2, but not when SciTE4AutoHotkey is active
		RememberQueries := true
		UseWhenActive := true
	}
	
	Class CResult extends CAccessorPlugin.CResult
	{
		Class CActions extends CArray
		{
			DefaultAction := new CAccessor.CAction("Activate Tab", "ActivateTab", "", true, false)
			__new()
			{
				this.Insert(CAccessorPlugin.CActions.Run)
				this.Insert(CAccessorPlugin.CActions.OpenWith)
				this.Insert(CAccessorPlugin.CActions.OpenExplorer)
				this.Insert(CAccessorPlugin.CActions.OpenCMD)
				this.Insert(CAccessorPlugin.CActions.Copy)
				this.Insert(CAccessorPlugin.CActions.ExplorerContextMenu)
			}
		}
		Type := "SciTE4AutoHotkey Tab Switcher"
		Detail1 := "S4AHK Tab"
		Actions := new this.CActions()
		Priority := CSciTE4AutoHotkeyPlugin.Instance.Priority
		ResultIndexingKey := "Path"
	}

	Init()
	{
		path := this.GetSciTE4AutoHotkeyPath()
		if(path)
			this.Icon := ExtractIcon(path, 1, 64)
		
		;Scite4Autohotkey uses a COM automation object that allows to remote control it. 
		;However, it does not register this object for all users when using the portable version of SciTE4AHK.
		;To make this version work, 7plus registers the COM object manually on startup and deregisters it on exit.
		RegRead, IsRegistered, HKCR, Scite4AHK.Application
		Scite4Autohotkey.IsRegistered := !(A_IsAdmin && ErrorLevel)
		if(!Scite4Autohotkey.IsRegistered)
		{
			RegWrite, REG_SZ, HKCR, Scite4AHK.Application,, Scite4AHK.Application
			RegWrite, REG_SZ, HKCR, Scite4AHK.Application\CLSID,, {D7334085-22FB-416E-B398-B5038A5A0784}
		}
	}

	IsInSinglePluginContext(Filter, LastFilter)
	{
		return false
	}

	ShowSettings(PluginSettings, GUI, PluginGUI)
	{
		AddControl(PluginSettings, PluginGUI, "Checkbox", "RememberQueries", "Remember and show the S4AHK tabs of the last query for each S4AHK tab.")
		AddControl(PluginSettings, PluginGUI, "Checkbox", "UseWhenActive", "Show all S4AHK tabs when Accessor opens and no saved queries for the current tab are available.")
	}

	OnOpen(Accessor)
	{
		this.List1 := this.GetListOfOpenSciTE4AutoHotkeyTabs()
		if(!this.Icon)
		{
			path := this.GetSciTE4AutoHotkeyPath()
			if(path)
				this.Icon := ExtractIcon(path, 1, 64)
		}
		;if SciTEWindow is open and there is an entry with the last used command for the current tab, put it in edit box
		if(WinExist("ahk_class " this.WindowClassName) = Accessor.PreviousWindow)
		{
			this.Priority += 1
			if(!Accessor.Filter && this.Settings.RememberQueries && index := this.MRUList.FindKeyWithValue("Path", Path := this.GetSciTE4AutoHotkeyActiveTab()))
			{
				Accessor.SetFilter(this.MRUList[index].Command, 0, -1)
				
				for index2, item in Accessor.GUI.ListView.Items
					if(item[2] = this.MRUList[index].Entry && item[3] = "S4AHK Tab")
					{
						Accessor.GUI.ListView.SelectedIndex := index2
						break
					}
			}
			else if(!Accessor.Filter && this.Settings.UseWhenActive)
				Accessor.SetFilter(this.Settings.Keyword " ", 0, -1)
		}
	}

	OnExit(Accessor)
	{
		if(this.Icon)
			DestroyIcon(this.Icon)
		;If the SciTE4AutoHotkey COM object was registered temporarily by 7plus, it needs to be deregistered on exit.
		if(!this.IsRegistered)
			RegDelete, HKCR, Scite4AHK.Application
	}

	RefreshList(Accessor, Filter, LastFilter, KeywordSet, Parameters)
	{
		if(!WinActive("ahk_class " this.WindowClassName) && strLen(Filter) < 2 && !KeywordSet)
			return
		if(!this.List1.MaxIndex())
			return
		Results := Array()
		if(!Filter && KeywordSet)
		{
			MatchQuality := 1
			for index, Path in this.List1
			{
				GoSub S4AHK_CreateResult
				Results.Insert(Result)
			}
			return Results
		}
		InStrList := Array()
		FuzzyList := Array()
		for index, Path in this.List1
		{
			SplitPath, Path, Name
			if((MatchQuality := FuzzySearch(Name, Filter, this.Settings.FuzzySearch)) > Accessor.Settings.FuzzySearchThreshold)
			{
				GoSub S4AHK_CreateResult
				FuzzyList.Insert(Result)
			}
		}
		return Results
		
		S4AHK_CreateResult:
		SplitPath, Path, Name
		Result := new this.CResult()
		Result.Title := Name
		Result.Path := Path
		Result.Icon := this.Icon
		Result.MatchQuality := MatchQuality
		return
	}
	
	;Functions specific to this plugin:
	ActivateTab(Accessor, ListEntry)
	{
		if(WinExist("ahk_class " this.WindowClassName) = Accessor.PreviousWindow)
		{
			if(Accessor.FilterWithoutTimer)
			{
				if(!(index := this.MRUList.FindKeyWithValue("Path", ActiveTab := this.GetSciTE4AutoHotkeyActiveTab())))
					this.MRUList.Insert(Object("Path", ActiveTab, "Command", Accessor.FilterWithoutTimer, "Entry", ListEntry.Path))
				else
				{
					this.MRUList[index].Command := Accessor.FilterWithoutTimer
					this.MRUList[index].Entry := ListEntry.Path
				}
			}
			else
				Notify("Accessor Error", "Filter string empty!", 5, NotifyIcons.Error)
		}
		this.ActivateSciTE4AutoHotkeyTab(this.List1.indexOf(ListEntry.Path))
	}
	
	ActivateSciTE4AutoHotkeyTab(Index)
	{
		ComObjError(0)
		scite := ComObjActive("SciTE4AHK.Application")
		ComObjError(1)
		if(scite)
		{
			scite.SwitchToTab(Index - 1) ; the index is zero-based
			WinActivate, % "ahk_id " scite.SciTEHandle
		}
		else
			Outputdebug SciTE4AHK COM dispatch object not available.
	}
	GetListOfOpenSciTE4AutoHotkeyTabs()
	{
		ComObjError(0)
		scite := ComObjActive("SciTE4AHK.Application")
		ComObjError(1)
		if(!scite) ;SciTE not running, empty list
			return Array()
		list := Array()
		tabs := scite.Tabs.Array 
		; tabs is a SafeArray containing the file names 
		Loop, % scite.tabs.Count
		   list.Insert(tabs[A_Index-1])
		return list
	}

	GetSciTE4AutoHotkeyPath()
	{
		hwnd := WinExist("ahk_class " this.WindowClassName)
		if(!hwnd)
			return ""
		WinGet, pid, PID, ahk_id %hwnd%
		Path := GetModuleFileNameEx(pid)
		return Path
	}
	
	GetSciTE4AutoHotkeyActiveTab()
	{
		ComObjError(0)
		scite := ComObjActive("SciTE4AHK.Application")
		ComObjError(1)
		if(!scite)
			return ""
		return scite.CurrentFile
	}
}