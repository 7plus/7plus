Class CRecentFoldersPlugin extends CAccessorPlugin
{
	;Register this plugin with the Accessor main object
	static Type := CAccessor.RegisterPlugin("Recent Folders", CRecentFoldersPlugin)
	
	Description := "Access recently used folders and quickly navigate to them in many programs."
	
	AllowDelayedExecution := false
	
	Class CSettings extends CAccessorPlugin.CSettings
	{
		Keyword := "RF"
		KeywordOnly := false
		MinChars := 2
		FuzzySearch := false
		UseHistory := true
		UseFrequent := true
		UseFastFolders := true
		UseWhenNavigable := true ;If true, this plugin will set its keyword when Accessor is opened and the previous window can be navigated.
		BasePriority := 0.6
	}

	Class CResult extends CAccessorPlugin.CResult
	{
		Class CActions extends CArray
		{
			DefaultAction := new CAccessor.CAction("Open Folder", "OpenExplorer", "", true, true, true, A_WinDir "\System32\Shell32.dll", 4)
			__new()
			{
				this.Insert(CAccessorPlugin.CActions.OpenWith)
				this.Insert(CAccessorPlugin.CActions.OpenCMD)
				this.Insert(CAccessorPlugin.CActions.OpenPathWithAccessor)
				this.Insert(CAccessorPlugin.CActions.Copy)
				this.Insert(CAccessorPlugin.CActions.ExplorerContextMenu)
				this.Insert(CAccessorPlugin.CActions.SearchDir)
			}
		}
		IsFolder := true
		Type := "Recent Folders"
		Actions := new this.CActions()
		Priority := CRecentFoldersPlugin.Instance.Priority
		ResultIndexingKey := "Path"
	}

	IsInSinglePluginContext(Filter, LastFilter)
	{
		return false
	}

	ShowSettings(PluginSettings, GUI, PluginGUI)
	{
		AddControl(PluginSettings, PluginGUI, "Checkbox", "UseHistory", "Use directory history")
		AddControl(PluginSettings, PluginGUI, "Checkbox", "UseFrequent", "Use frequent directories")
		AddControl(PluginSettings, PluginGUI, "Checkbox", "UseFastFolders", "Use directories from Fast Folders")
		AddControl(PluginSettings, PluginGUI, "Checkbox", "UseWhenNavigable", "Automatically set the keyword for this plugin when the current window can be navigated by 7plus.", "", "", "", "", "", "", "Enabling this will make the Accessor show the recently used directories`nwhen opened if navigable applications like explorer or CMD were active.")
	}

	OnOpen(Accessor)
	{
		if(Navigation.FindNavigationSource(Accessor.PreviousWindow, "SetPath"))
		{
			if(!Accessor.Filter && this.Settings.UseWhenNavigable)
				Accessor.SetFilter(this.Settings.Keyword " ", 0, -1)
			this.Priority += 0.5
		}
	}

	RefreshList(Accessor, Filter, LastFilter, KeywordSet, Parameters)
	{
		global ExplorerHistory,FastFolders

		outputdebug % "recent folders, filter: " filter ", single context: " Accessor.SingleContext
		Results := Array()
		if(this.Settings.UseHistory)
		{
			Detail := "History"
			for index, Entry in ExplorerHistory.History
				if(A_Index != 1)
					GoSub RecentFolders_CheckEntry
		}
		if(this.Settings.UseFastFolders)
		{
			Detail := "Fast Folders"
			for index2, Entry in FastFolders
				GoSub RecentFolders_CheckEntry
		}
		if(this.Settings.UseFrequent)
		{
			Detail := "Frequent"
			for index3, Entry in ExplorerHistory.FrequentPaths
				GoSub RecentFolders_CheckEntry
		}

		;Find and remove duplicates
		i := 1
		while(Result := Results[i])
		{
			j := i + 1
			while(Result2 := Results[j])
			{
				if(Result2.Path = Result.Path)
				{
					Results.Remove(j)
					continue
				}
				j++
			}
			i++
		}
		return Results

		;Put some code in labels to save some repetitions. Yes I feel nasty for doing this...;)
		RecentFolders_CheckEntry:
		if(Entry.Path)
		{
			if((MatchQuality := FuzzySearch(Entry.Name, Filter, this.Settings.FuzzySearch)) > Accessor.Settings.FuzzySearchThreshold || (MatchQuality := FuzzySearch(Entry.Path, Filter, false) - 0.2) > Accessor.Settings.FuzzySearchThreshold)
			{
				Result := new this.CResult()
				Result.Title := Entry.Name
				Result.Path := Entry.Path
				Result.Icon := Accessor.GenericIcons.Folder
				Result.Detail1 := Detail
				Result.MatchQuality := MatchQuality
				Results.Insert(Result)
			}
		}
		return
	}
}