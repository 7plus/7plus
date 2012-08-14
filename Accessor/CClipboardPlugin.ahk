Class CClipboardPlugin extends CAccessorPlugin
{
	;Register this plugin with the Accessor main object
	static Type := CAccessor.RegisterPlugin("Clipboard", CClipboardPlugin)
	
	Description := "This plugin is used to add, search and paste persistent clips stored by the 7plus clipboard manager"

	SaveHistory := false

	AllowDelayedExecution := false
	
	Icon := ExtractIcon("shell32.dll", 261, 64)

	Column2Text := "Content"

	Class CSettings extends CAccessorPlugin.CSettings
	{
		Keyword := "clip"
		KeywordOnly := false
		MinChars := 0
	}

	Class CResult extends CAccessorPlugin.CResult
	{
		Class CActions extends CArray
		{
			DefaultAction := new CAccessor.CAction("Paste", "Paste")
			__new()
			{
				this.Insert(CAccessorPlugin.CActions.OpenWith)
			}
		}

		Type := "Clipboard"
		Icon := CClipboardPlugin.Instance.Icon
		Priority := CClipboardPlugin.Instance.Priority

		__new()
		{
			this.Actions := new this.CActions()
		}
	}
	Class CStoreResult extends CAccessorPlugin.CResult
	{
		Class CActions extends CArray
		{
			DefaultAction := new CAccessor.CAction("Store clip", "Paste", "", true, true, true, A_WinDir "\System32\wmploc.dll", 16)
		}

		Type := "Clipboard"
		Icon := CClipboardPlugin.Instance.Icon
		Priority := CClipboardPlugin.Instance.Priority

		__new()
		{
			this.Actions := new this.CActions()
		}
	}

	OnOpen(Accessor)
	{
		if(IsEditControlActive())
			this.Priority += 0.5 ;Lower priority than most other dynamic priorities, since they are more specialized
	}

	RefreshList(Accessor, Filter, LastFilter, KeywordSet, Parameters)
	{
		global ClipboardList
		Results := Array()
		NameResults := Array()
		TextResults := Array()
		if(Accessor.SelectedText && !Filter)
		{
			Result := new this.CStoreResult()
			Result.Title := "Store selected text as clip"
			Result.Path := Accessor.SelectedText
			Result.ClipType := "SelectedText"
			Result.MatchQuality := 1
			Results.Insert(Result)
		}
		if(KeywordSet || StrLen(Filter) >= 2)
		{
			for index, clip in ClipboardList
			{
				if(KeywordSet || (MatchQuality := FuzzySearch(clip, Filter, false)) > Accessor.Settings.FuzzySearchThreshold)
				{
					Result := new this.CResult()
					Result.Title := index
					Result.Path := clip
					Result.Detail1 := "Clip"
					Result.ClipType := "History"
					Result.MatchQuality := MatchQuality
					Results.Insert(Result)
				}
			}
			for index2, clip in ClipboardList.Persistent
			{
				if(KeywordSet || (MatchQuality := FuzzySearch(clip.Name, Filter, false)) > Accessor.Settings.FuzzySearchThreshold)
				{
					Result := new this.CResult()
					Result.Title := clip.Name
					Result.Path := clip.Text
					Result.Detail1 := "Clip"
					Result.ClipType := "Persistent"
					Result.MatchQuality := MatchQuality - 0.1
					;This ID is stored only for identifying and weighting this result
					Result.ID := index2 ":" Result.Title
					Result.ResultIndexingKey := "ID"
					Result.Index := index2
					Results.Insert(Result)
				}
				;Only search in the text of the clip when the user entered a longer query
				else if(strLen(Filter) > 8 && (MatchQuality := FuzzySearch(clip.Text, Filter, false)) > Accessor.Settings.FuzzySearchThreshold)
				{
					Result := new this.CResult()
					Result.Title := clip.Name
					Result.Path := clip.Text
					Result.Detail1 := "Clip"
					Result.ClipType := "Persistent"
					Result.MatchQuality := MatchQuality
					;This ID is stored only for identifying and weighting this result
					Result.ID := index2 ":" Result.Title
					Result.ResultIndexingKey := "ID"
					Result.Index := index2
					Results.Insert(Result)
				}
			}
		}
		return Results
	}

	Paste(Accessor, ListEntry)
	{
		if(ListEntry.ClipType = "SelectedText")
			AddClip(ListEntry.Path)
		else
		{
			this.ListEntry := ListEntry
			Settimer, CClipboardPlugin_WaitForAccessorClose, -100
		}
	}
	
	WaitForAccessorClose()
	{
		if(!WinActive("ahk_id " CAccessor.Instance.GUI.hwnd))
		{
			if(this.ListEntry.ClipType = "History")
				PasteText(this.ListEntry.Path)
			else if(this.ListEntry.ClipType = "Persistent")
				PersistentClipboard(this.ListEntry.Index)
			this.Remove("ListEntry")
		}
		else
			Settimer, CClipboardPlugin_WaitForAccessorClose, -100
	}
}
CClipboardPlugin_WaitForAccessorClose:
CClipboardPlugin.Instance.WaitForAccessorClose()
return