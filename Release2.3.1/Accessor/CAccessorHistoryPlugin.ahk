Class CAccessorHistoryPlugin extends CAccessorPlugin
{
	;Register this plugin with the Accessor main object
	static Type := CAccessor.RegisterPlugin("Accessor History", CAccessorHistoryPlugin)
	
	Description := "This plugin stores the recently executed Accessor entries and shows them when Accessor opens `n(and no other plugin shows things in the current context)."
		
	List := Array()

	AllowDelayedExecution := false
	
	Class CSettings extends CAccessorPlugin.CSettings
	{
		Keyword := "History"
		KeywordOnly := false
		FuzzySearch := false
		MaxEntries := 100
		MinChars := 0
		ShowWithEmptyQuery := true
		SearchHistory := false
		BasePriority := 0.3
	}
	ShowSettings(PluginSettings, GUI, PluginGUI)
	{
		AddControl(PluginSettings, PluginGUI, "UpDown", "MaxEntries", "3-1000", "", "History length:", "", "", "", "", "The number of history entries to keep.")
		AddControl(PluginSettings, PluginGUI, "Checkbox", "ShowWithEmptyQuery", "Show history when query string is empty")
		AddControl(PluginSettings, PluginGUI, "Checkbox", "SearchHistory", "Search in history", "", "", "", "", "", "", "This is disabled by default so history entries will only show up when Accessor is opened. This is usually desired because most history entries can still be found as regular results and duplicates can be avoided this way.")
	}

	OnExit(Accessor)
	{
		for index, item in this.List
			if(item.Icon)
				DestroyIcon(item.Icon)
	}

	OnPreExecute(Accessor, ListEntry, Action, Plugin)
	{
		if(!ListEntry.IsHistory && Action.SaveHistory && Plugin.SaveHistory && (!ListEntry.ResultIndexingKey || !getAll(getAll(this.List, "Type", ListEntry.Type), ListEntry.ResultIndexingKey, ListEntry[ListEntry.ResultIndexingKey])))
		{
			;Remove all redundant history entries and destroy their icon copies
			while(this.List.MaxIndex() >= this.Settings.MaxEntries)
				DestroyIcon(this.List.Remove(this.Settings.MaxEntries).Icon)

			;Create a copy of the entry and duplicate its icon (it needs to be destroyed later)
			Copy := Accessor.CopyResult(ListEntry)
			;If the icon is stored as a hIcon it needs to be duplicated
			if(!Copy.HasKey("IconNumber"))
				Copy.Icon := DuplicateIcon(Copy.Icon)
			Copy.IsHistory := true
			this.List.Insert(1, Copy)
		}
	}
	
	RefreshList(Accessor, Filter, LastFilter, KeywordSet, Parameters)
	{
		Results := Array()
		if(!Filter && this.Settings.ShowWithEmptyQuery)
		{
			for index, item in this.List
			{
				item.MatchQuality := 1
				;Footer text can not be shown with GetFooterText with this plugin because its results appear as if they belong to other plugins
				item.FooterText := "You can access the previous searches by pressing CTRL + Up / Down!"
				Results.Insert(item)
			}
			return Results
		}
		else if(Filter && this.Settings.SearchHistory)
		{
			for index, item in this.List
			{
				;Footer text can not be shown with GetFooterText with this plugin because its results appear as if they belong to other plugins
				item.FooterText := "You can access the previous searches by pressing CTRL + Up / Down!"
				if((item.MatchQuality := FuzzySearch(item.Title, Filter, this.Settings.FuzzySearch)) > Accessor.Settings.FuzzySearchThreshold)
					Results.Insert(item)
				else if((item.MatchQuality := FuzzySearch(item.Path, Filter, this.Settings.FuzzySearch)) > Accessor.Settings.FuzzySearchThreshold)
				{
					item.MatchQuality -= 0.1
					Results.Insert(item)
				}
			}
			return Results
		}
	}
}