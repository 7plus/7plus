Class CKeywordPlugin extends CAccessorPlugin
{
	;Register this plugin with the Accessor main object
	static Type := CAccessor.RegisterPlugin("Keyword Plugin", CKeywordPlugin)
	
	Description := "This plugin makes it possible to quickly create keywords by selecting text or a file,`nopen Accessor and type ""Learn as [keyword]"".`nCredits for the idea of this plugin go to Enso Launcher."
	
	SaveHistory := false
	
	AllowDelayedExecution := false

	Column1Text := "New Keyword"
	Column2Text := "New Command"
	
	Class CSettings extends CAccessorPlugin.CSettings
	{
		Keyword := "Learn as"
		KeywordOnly := true
		MinChars := 2
	}

	Class CResult extends CAccessorPlugin.CResult
	{
		Class CActions extends CArray
		{
			DefaultAction := new CAccessor.CAction("New keyword", "LearnKeyword")
		}
		Type := "Keyword Plugin"
		Actions := new this.CActions()
		Priority := CKeywordPlugin.Instance.Priority
		MatchQuality := 1 ;Only one result if this plugin applies
	}

	IsInSinglePluginContext(Filter, LastFilter)
	{
		return false
	}

	RefreshList(Accessor, Filter, LastFilter, KeywordSet, Parameters)
	{
		if(Accessor.SelectedText && Filter := SubStr(Accessor.FilterWithoutTimer, StrLen(this.Settings.Keyword) + 2))
		{
			Results := Array()
			Result := new this.CResult()
			Result.Title := Filter
			Result.Path := Accessor.SelectedText
			Result.Detail1 := "Keyword"
			Result.Icon := Accessor.GenericIcons.7plus
			Results.Insert(Result)
			return Results
		}
	}
	
	LearnKeyword(Accessor, ListEntry)
	{
		if(ListEntry.Path)
		{
			if(index := Accessor.Keywords.FindKeyWithValue("Key", ListEntry.Title))
				Accessor.Keywords[index] := {Key : ListEntry.Title, Command : ListEntry.Path}
			else
				Accessor.Keywords.Insert({Key : ListEntry.Title, Command : ListEntry.Path})
			if(SettingsActive())
				SettingsWindow.AddAccessorKeyword(ListEntry.Title, ListEntry.Path)
		}
	}
}