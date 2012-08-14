Class CWindowSwitcherPlugin extends CAccessorPlugin
{
	;Register this plugin with the Accessor main object
	static Type := CAccessor.RegisterPlugin("Window switcher", CWindowSwitcherPlugin)
	
	Description := "Activate windows by typing a part of their title or their executable filename. `nThis also shows CPU usage, shows/sets Always on Top state and `nallows to close and kill processes."
	
	;List of windows that are open when accessor is opened.
	List := Array()
	
	;This plugin is not listed in the history plugin because the single entries may not be valid anymore.
	SaveHistory := false

	AllowDelayedExecution := false
	
	Column1Text := "Window Title"
	Column2Text := "Executable Name"
	Column3Text := "CPU Usage"

	Class CSettings extends CAccessorPlugin.CSettings
	{
		Keyword := "switch"
		KeywordOnly := false
		MinChars := 0
		IgnoreFileExtensions := true
		FuzzySearch := false
		ShowWithEmptyQuery := false
		HideCurrentWindow := true
	}

	Class CResult extends CAccessorPlugin.CResult
	{
		Class CActions extends CArray
		{
			DefaultAction := new CAccessor.CAction("Activate", "ActivateWindow", "", true, false)
			__new()
			{
				this.Insert(new CAccessor.CAction("End process", "EndProcess", "", false, false, true, A_WinDir "\System32\Shell32.dll", 216))
				this.Insert(new CAccessor.CAction("Close window", "CloseWindow", "", false, false, true, A_WinDir "\System32\Shell32.dll", 132))
				this.Insert(CAccessorPlugin.CActions.OpenExplorer)
				this.Insert(CAccessorPlugin.CActions.OpenCMD)
				this.Insert(CAccessorPlugin.CActions.Copy)
				this.Insert(CAccessorPlugin.CActions.ExplorerContextMenu)
				this.Insert(new CAccessor.CAction("Toggle Always On Top", "ToggleOnTop", "", false, false))
			}
		}
		Type := "Window switcher"
		Actions := new this.CActions()
		Priority := CWindowSwitcherPlugin.Instance.Priority
		ResultIndexingKey := "Title"
	}

	IsInSinglePluginContext(Filter, LastFilter)
	{
		return false
	}

	OnOpen(Accessor)
	{
		this.List := GetWindowInfo()
		SetTimer, UpdateTimes, -2000
	}

	OnClose(Accessor)
	{
		;This is apparently not desired for icons obtained by WM_GETICON or GetClassLong since they are shared? See http://msdn.microsoft.com/en-us/library/windows/desktop/ms648063(v=vs.85).aspx
		;~ if(IsObject(this.List))
			;~ for index, ListEntry in this.List
				;~ if(ListEntry.Icon != Accessor.GenericIcons.Application)
					;~ DestroyIcon(ListEntry.Icon)
	}

	GetDisplayStrings(ListEntry, ByRef Title, ByRef Path, ByRef Detail1, ByRef Detail2)
	{
		Path := ListEntry.ExeName
		Detail1 := "CPU: " ListEntry.CPU "%"
		Detail2 := ListEntry.OnTop
	}

	RefreshList(Accessor, Filter, LastFilter, KeywordSet, Parameters)
	{
		if(!Filter && !KeywordSet && !this.Settings.ShowWithEmptyQuery)
			return
		Results := Array()
		FuzzyList := Array()
		for index, window in this.List
		{
			if(this.Settings.HideCurrentWindow && !Filter && window.hwnd = Accessor.PreviousWindow)
				continue
			ExeName := this.Settings.IgnoreFileExtensions ? strTrimRight(window.ExeName,".exe") : window.ExeName
			EmptyMatch := this.Settings.ShowWithEmptyQuery && Filter = ""
			TitleMatch := FuzzySearch(window.Title, Filter, this.Settings.FuzzySearch)
			ExeMatch := FuzzySearch(ExeName, Filter, this.Settings.FuzzySearch)
			if((MatchQuality := max(EmptyMatch, TitleMatch, ExeMatch)) > Accessor.Settings.FuzzySearchThreshold)
			{
				Result := new this.CResult()
				Result.Priority -= window.Order * 0.001
				Result.Title := window.Title
				Result.Path := window.Path
				Result.ExeName := window.ExeName
				Result.CPU := window.CPU
				Result.OnTop := window.OnTop
				Result.PID := window.PID
				Result.hwnd := window.hwnd
				Result.Icon := window.Icon ? window.Icon : Accessor.GenericIcons.Application
				Result.MatchQuality := MatchQuality
				Results.Insert(Result)
			}
		}
		return Results
	}

	ShowSettings(PluginSettings, Accessor, PluginGUI)
	{
		AddControl(PluginSettings, PluginGUI, "Checkbox", "IgnoreFileExtensions", "Ignore .exe extension in program paths", "", "")
		AddControl(PluginSettings, PluginGUI, "Checkbox", "ShowWithEmptyQuery", "Show open windows when query string is empty")
	}

	ActivateWindow(Accessor, ListEntry)
	{
		WinActivate % "ahk_id " ListEntry.hwnd
	}

	EndProcess(Accessor, ListEntry)
	{
		WinKill % "ahk_id " ListEntry.hwnd
	}

	CloseWindow(Accessor, ListEntry)
	{
		PostMessage, 0x112, 0xF060,,, % "ahk_id " ListEntry.hwnd
	}

	ToggleOnTop(Accessor, ListEntry)
	{
		WinSet, AlwaysOnTop, Toggle, % "ahk_id " ListEntry.hwnd
		ListEntry.OnTop := ListEntry.OnTop ? "" : "OnTop"
		Accessor.GUI.ListView.Items[Accessor.List.IndexOf(ListEntry)][4] := ListEntry.OnTop
		return true
	}
	
	UpdateTimes()
	{
		Accessor := CAccessor.Instance
		if(!Accessor.GUI.Visible)
			return
		for index, item in Accessor.GUI.ListView.Items
		{
			ListEntry := Accessor.List[index]
			if(ListEntry.Type = this.Type)
			{
				ListEntry.oldKrnlTime := ListEntry.newKrnlTime
				ListEntry.oldUserTime := ListEntry.newUserTime

				hProc := DllCall("OpenProcess", "Uint", 0x400, "int", 0, "Uint", ListEntry.PID, "Ptr")
				DllCall("GetProcessTimes", "Ptr", hProc, "int64P", CreationTime, "int64P", ExitTime, "int64P", newKrnlTime, "int64P", newUserTime, "UInt")
				DllCall("CloseHandle", "Ptr", hProc)
				ListEntry.newKrnlTime := newKrnlTime
				ListEntry.newUserTime := newUserTime
				ListEntry.CPU := Round(min(max((ListEntry.newKrnlTime - ListEntry.oldKrnlTime + ListEntry.newUserTime - ListEntry.oldUserTime)/20000000 * 100,0),100), 2)   ; 1sec: 10^7
				this.List[this.List.FindKeyWithValue("hwnd", ListEntry.hwnd)].CPU := ListEntry.CPU
				; ListEntry.CPU := GetProcessTimes(ListEntry.PID)
				item[3] := "CPU: " ListEntry.CPU "%"
			}
		}
		SetTimer, UpdateTimes, -2000
	}
}
UpdateTimes:
CWindowSwitcherPlugin.Instance.UpdateTimes()
return