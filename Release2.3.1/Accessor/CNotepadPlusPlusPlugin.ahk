Class CNotepadPlusPlusPlugin extends CAccessorPlugin
{
	;Register this plugin with the Accessor main object
	static Type := CAccessor.RegisterPlugin("Notepad++ Tab Switcher", CNotepadPlusPlusPlugin)
	
	Description := "Activate a specific Notepad++ tab by typing a part of its name. This plugin restores the text `nwhich was previously entered when the current tab was last active. `nThis way you can quicly switch between the most used tabs."
		
	MRUList := Array()
	
	WindowClassName := "Notepad++"
	
	;This plugin is not listed by the history plugin because the results may not be valid anymore.
	SaveHistory := false

	AllowDelayedExecution := false
	
	Class CSettings extends CAccessorPlugin.CSettings
	{
		Keyword := "np"
		KeywordOnly := false
		FuzzySearch := false
		MinChars := 0 ;This is actually 2, but not when Notepad++ is active
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
		Type := "Notepad++ Tab Switcher"
		Detail1 := "NP++ Tab"
		Actions := new this.CActions()
		Priority := CNotepadPlusPlusPlugin.Instance.Priority
		ResultIndexingKey := "Path"
	}

	Init()
	{
		path := this.GetNotepadPlusPlusPath()
		if(path)
			this.Icon := ExtractIcon(path "\Notepad++.exe", 1, 64)
	}

	ShowSettings(PluginSettings, GUI, PluginGUI)
	{
		AddControl(PluginSettings, PluginGUI, "Checkbox", "RememberQueries", "Remember and show the NP++ tabs of the last query for each NP++ tab.")
		AddControl(PluginSettings, PluginGUI, "Checkbox", "UseWhenActive", "Show all NP++ tabs when Accessor opens and no saved queries for the current tab are available.")
	}

	OnOpen(Accessor)
	{
		this.List1 := this.GetListOfOpenNotepadPlusPlusTabs()
		this.List2 := this.GetListOfOpenNotepadPlusPlusTabs(2)
		if(!this.Icon)
		{
			path := this.GetNotepadPlusPlusPath()
			if(path)
				this.Icon := ExtractIcon(path "\Notepad++.exe", 1, 64)
		}
		;if Notepad++ is open and there is an entry with the last usd command for the current tab, put it in edit box
		if(WinExist("ahk_class " this.WindowClassName) = Accessor.PreviousWindow)
		{
			this.Priority += 1
			if(!Accessor.Filter && this.Settings.RememberQueries && index := this.MRUList.FindKeyWithValue("Path", Path := this.GetNotepadPlusPlusActiveTab()))
			{
				Accessor.SetFilter(this.MRUList[index].Command, 0, -1)
				
				for index2, item in Accessor.GUI.ListView.Items
					if(item[2] = this.MRUList[index].Entry && item[3] = "NP++ Tab")
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
	}

	RefreshList(Accessor, Filter, LastFilter, KeywordSet, Parameters)
	{
		if(!WinActive("ahk_class " this.WindowClassName) && strLen(Filter) < 2 && !KeywordSet)
			return
		if(!this.List1.MaxIndex() && !this.List2.MaxIndex())
			return
		Results := Array()
		if(!Filter && KeywordSet)
		{
			MatchQuality := 1
			for index, Path in this.List1
			{
				GoSub NPPlusPlus_CreateResult
				Results.Insert(Result)
			}
			for index, Path in this.List2
			{
				GoSub NPPlusPlus_CreateResult
				Results.Insert(Result)
			}
			return Results
		}
		for index, Path in this.List1
		{
			SplitPath, Path, Name
			if((MatchQuality := FuzzySearch(Name, Filter, this.Settings.FuzzySearch)) > Accessor.Settings.FuzzySearchThreshold)
			{
				GoSub NPPlusPlus_CreateResult
				Results.Insert(Result)
			}
		}
		for index2, Path in this.List2
		{
			SplitPath, Path, Name
			if((MatchQuality := FuzzySearch(Name, Filter, this.Settings.FuzzySearch)) > Accessor.Settings.FuzzySearchThreshold)
			{
				GoSub NPPlusPlus_CreateResult
				Results.Insert(Result)
			}
		}
		return Results
		
		NPPlusPlus_CreateResult:
		SplitPath, Path, Name
		Result := new this.CResult()
		Result.Title := Name
		Result.Path := Path
		Result.MatchQuality := MatchQuality
		Result.Icon := this.Icon
		return
	}
	
	;Functions specific to this plugin:
	ActivateTab(Accessor, ListEntry)
	{
		if(WinExist("ahk_class " this.WindowClassName) = Accessor.PreviousWindow)
		{
			if(Accessor.FilterWithoutTimer)
			{
				if(!(index := this.MRUList.FindKeyWithValue("Path", ActiveTab := this.GetNotepadPlusPlusActiveTab())))
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
		if(strEndsWith(ListEntry.Path, "[2]"))
			this.ActivateNotepadPlusPlusTab(this.List2.indexOf(ListEntry.Path), 2)
		else
			this.ActivateNotepadPlusPlusTab(this.List1.indexOf(ListEntry.Path), 1)
	}
	
	ActivateNotepadPlusPlusTab(Index, View = 1)
	{
		hwnd := WinExist("ahk_class " this.WindowClassName)
		if(!hwnd)
			return
		WinActivate ahk_id %hwnd%
		SendMessage, 0x804, view - 1, index - 1, ,ahk_id %hwnd% ;NPPM_ACTIVATEDOC
	}

	GetListOfOpenNotepadPlusPlusTabs(WhichView = 1)
	{
		IsUnicode := this.IsNotepadPlusPlusUnicode()
		hwnd := WinExist("ahk_class " this.WindowClassName)
		if(!hwnd) ;Notepad++ not running, empty list
			return Array()
		if(WhichView = 1)
			SendMessage, 0x7EF, 0, 1, ,ahk_id %hwnd% ;NPPM_GETNBOPENFILES
		else
			SendMessage, 0x7EF, 0, 2, ,ahk_id %hwnd% ;NPPM_GETNBOPENFILES
		count := Errorlevel ;Count of tabs
		list := Array()
		Loop % count
		{
			pos := A_Index - 1
			if(WhichView = 1)
				SendMessage, 0x823, %pos%, 0, ,ahk_id %hwnd% ;NPPM_GETBUFFERIDFROMPOS
			else
				SendMessage, 0x823, %pos%, 1, ,ahk_id %hwnd% ;NPPM_GETBUFFERIDFROMPOS
			BufferID := Errorlevel
			SendMessage, 0x822, %BufferID%, 0, ,ahk_id %hwnd% ;NPPM_GETFULLPATHFROMBUFFERID
			MsgReply := ErrorLevel > 0x7FFFFFFF ? -(~ErrorLevel) - 1 : ErrorLevel
			if(MsgReply = -1) ;MsgReply = -1 -> Some error occured
				return Array()
			size := IsUnicode ? MsgReply * 2 + 2 : MsgReply + 1
			RemoteBuf_Open(H, hwnd, size)
			RemoteAddress := RemoteBuf_Get(H) ;Get address of buffer
			VarSetCapacity(localBuffer, size, 0) ;Create local buffer of same size
			SendMessage, 0x822, %BufferID%, %RemoteAddress%, ,ahk_id %hwnd% ;NPPM_GETFULLPATHFROMBUFFERID
			RemoteBuf_Read(H, TabName, size, 0) ;Try to read the first string
			if(A_IsUnicode && !IsUnicode)
				Ansi2Unicode(TabName, ConvertedTabName)
			else if(!A_IsUnicode && IsUnicode)
				Unicode2Ansi(TabName, ConvertedTabName)
			if(ConvertedTabName)
				TabName := ConvertedTabName
			if(WhichView != 1)
				TabName .= " [2]"
			list.Insert(TabName)
			RemoteBuf_Close(H) ;Close/free remote buffer
		}
		return list
	}

	IsNotepadPlusPlusUnicode()
	{
		hwnd := WinExist("ahk_class " this.WindowClassName)
		if(!hwnd)
			return 0
		MAXPATH := 260
		size := Maxpath * 2 + 2
		RemoteBuf_Open(H, hwnd, size)
		RemoteAddress := RemoteBuf_Get(H) ;Get address of buffer
		VarSetCapacity(localBuffer, size, 0) ;Create local buffer of same size
		SendMessage, 0xFBF, MAXPATH, RemoteAddress, ,ahk_id %hwnd% ;NPPM_GETNPPDIRECTORY
		RemoteBuf_Read(H, path1, size, 0) ;Try to read the first string
		RemoteBuf_Close(H) ;Close/free remote buffer
		if(NumGet(path1,0, "Char") != 0 && NumGet(path1,1, "Char") = 0)
			return 1
		return 0
	}

	GetNotepadPlusPlusPath()
	{
		hwnd := WinExist("ahk_class " this.WindowClassName)
		if(!hwnd)
			return ""
		MAXPATH := 260
		size := Maxpath * 2 + 2
		RemoteBuf_Open(H, hwnd, size)
		RemoteAddress := RemoteBuf_Get(H) ;Get address of buffer
		VarSetCapacity(localBuffer, size, 0) ;Create local buffer of same size
		SendMessage, 0xFBF, MAXPATH, RemoteAddress, ,ahk_id %hwnd% ;NPPM_GETNPPDIRECTORY
		RemoteBuf_Read(H, Path, size, 0) ;Try to read the first string
		RemoteBuf_Close(H) ;Close/free remote buffer
		IsUnicode := this.IsNotepadPlusPlusUnicode()
		if(A_IsUnicode && !IsUnicode)
			Ansi2Unicode(Path, Path)
		return Path
	}

	;May only be used while Accessor window is visible
	GetNotepadPlusPlusActiveTab()
	{
		hwnd := WinExist("ahk_class " this.WindowClassName)
		if(!hwnd)
			return ""
		RemoteBuf_Open(H, hwnd, 4)
		RemoteAddress := RemoteBuf_Get(H) ;Get address of buffer
		SendMessage, 0x7EC, 0, RemoteAddress, ,ahk_id %hwnd% ;NPPM_GETCURRENTSCINTILLA
		RemoteBuf_Read(H, View, 4, 0) ;Try to read the first string
		RemoteBuf_Close(H) ;Close/free remote buffer
		View := NumGet(View, 0, "UInt")
		if(!View) ;Main View
		{
			SendMessage, 0x7FF, 0, 0, ,ahk_id %hwnd% ;NPPM_GETCURRENTDOCINDEX		
			index := Errorlevel + 1
			return this.List1[index]
		}
		else ;Secondary View
		{
			SendMessage, 0x7FF, 0, 1, ,ahk_id %hwnd% ;NPPM_GETCURRENTDOCINDEX		
			index := Errorlevel + 1
			return this.List2[index]
		}
	}
}