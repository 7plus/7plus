Class CControlPanelPlugin extends CAccessorPlugin
{
	;Register this plugin with the Accessor main object
	static Type := CAccessor.RegisterPlugin("ControlPanel", CControlPanelPlugin)
	
	Description := "This plugin is used to index the control panel applets."
	
	;List of control panel applets
	List := Array()

	SaveHistory := true

	AllowDelayedExecution := false
	
	Class CSettings extends CAccessorPlugin.CSettings
	{
		Keyword := "cpl"
		KeywordOnly := false
		MinChars := 2
	}

	Class CResult extends CAccessorPlugin.CResult
	{
		Class CActions extends CArray
		{
			DefaultAction := new CAccessor.CAction("Open", "Open")
		}
		Type := "ControlPanel"
		Priority := CControlPanelPlugin.Instance.Priority
		Detail1 := "ControlPanel"
		ResultIndexingKey := "Title"
		__new()
		{
			this.Actions := new this.CActions()
		}
	}
	Init()
	{
		;Find all registered control panel applets
		Loop, HKEY_LOCAL_MACHINE, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel\NameSpace\, 2, 0
		{
			if(InStr(A_LoopRegName, "{") != 1)
				continue
			;Appname is used to open the applet with control.exe
			RegRead, appname, HKCR, CLSID\%A_LoopRegName%, System.ApplicationName
			if(!appname)
				RegRead, appname, HKCR, CLSID\%A_LoopRegName%
			;Get localized name
			RegRead, localstring, HKCR, CLSID\%A_LoopRegName%, LocalizedString
			if(InStr(localstring, "@") = 1)
				localstring := SubStr(localstring, 2)
			file := SubStr(localstring, 1, InStr(localstring, ",") - 1)
			id := SubStr(localstring, InStr(localstring, ",-") + 2)
			localized := TranslateMUI(ExpandPathPlaceholders(file), id)
			if(!localized)
				localized := AppName
			;Get default icon
			RegRead, iconstring, HKCR, CLSID\%A_LoopRegName%\DefaultIcon
			if(InStr(iconstring, "@") = 1)
				iconstring := SubStr(iconstring, 2)
			file := LookupFileInPATH(ExpandPathPlaceholders(SubStr(iconstring, 1, InStr(iconstring, ",") - 1)))
			;Convert it from resource id to icon index
			id := IndexOfIconResource(file, SubStr(iconstring, InStr(iconstring, ",-") + 2))
			this.List.Insert({appname : appname, localString : localized, icon : file, IconNumber : id})
		}
	}

	RefreshList(Accessor, Filter, LastFilter, KeywordSet, Parameters)
	{
		Results := Array()
		for index, applet in this.List
		{
			if(KeywordSet || (MatchQuality := FuzzySearch(applet.localString, Filter, false)) > Accessor.Settings.FuzzySearchThreshold)
			{
				Result := new this.CResult()
				Result.Title := applet.localString
				Result.Path := ""
				Result.Icon := applet.Icon
				Result.IconNumber := applet.IconNumber
				Result.AppName := applet.AppName
				Result.MatchQuality := MatchQuality
				Results.Insert(Result)
			}
		}
		return Results
	}
	
	Open(Accessor, ListEntry)
	{
		if(ListEntry.AppName)
			RunAsUser("control.exe /name " ListEntry.AppName)
	}
}