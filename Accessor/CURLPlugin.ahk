Class CURLPlugin extends CAccessorPlugin
{
	;Register this plugin with the Accessor main object
	static Type := CAccessor.RegisterPlugin("URL", CURLPlugin)
	
	Description := "This plugin allows to open URLs in the browser. It can import bookmarks from various browsers.`n Type URL or select a URL in another application, open Accessor and press enter to open that URL."
		
	;Array of Opera bookmarks
	OperaBookmarks := Array()
	OperaClass := "OperaWindowClass"

	;Array of Chrome bookmarks
	ChromeBookmarks := Array()
	ChromeClass := "Chrome_WidgetWin_0"

	;Array of Firefox bookmarks
	FirefoxBookMarks := Array()
	FirefoxClass := "MozillaWindowClass"

	;Array of IE bookmarks
	IEBookmarks := Array()
	IEClass := "IEFrame"

	AllowDelayedExecution := false
	
	Column1Text := "URL"
	Column2Text := "Action"
	
	Class CSettings extends CAccessorPlugin.CSettings
	{
		Keyword := "URL"
		KeywordOnly := false
		MinChars := 3
		IncludeOperaBookmarks := true
		IncludeChromeBookmarks := true
		IncludeFirefoxBookmarks := true
		IncludeIEBookmarks := true
		UseSelectedText := true
	}

	Class CResult extends CAccessorPlugin.CResult
	{
		Class CActions extends CArray
		{
			DefaultAction := new CAccessor.CAction("Open URL", "OpenURL")
			__new()
			{
				this.Insert(CAccessorPlugin.CActions.OpenWith)
			}
		}
		Type := "URL"
		Actions := new this.CActions()
		Priority := CURLPlugin.Instance.Priority
		Detail1 := "Bookmark"
	}

	Init(PluginSettings)
	{
		if(this.Settings.IncludeOperaBookmarks)
			this.LoadOperaBookmarks()
		if(this.Settings.IncludeChromeBookmarks)
			this.LoadChromeBookmarks()
		if(this.Settings.IncludeFirefoxBookmarks)
			this.LoadFirefoxBookmarks()
		if(this.Settings.IncludeIEBookmarks)
			this.LoadIEBookmarks()
	}

	IsInSinglePluginContext(Filter, LastFilter)
	{
		return IsURL(Filter)
	}

	OnOpen(Accessor)
	{
		if(this.Settings.UseSelectedText && !Accessor.Filter && !Accessor.FilterWithoutTimer && Accessor.SelectedText && IsURL(Accessor.SelectedText))
			Accessor.SetFilter(Accessor.SelectedText)
		if({this.OperaClass : "", this.ChromeClass : "", this.IEClass : "", this.FirefoxClass : ""}.HasKey(WinGetClass("ahk_id " Accessor.PreviousWindow)))
			this.Priority += 0.5
	}

	RefreshList(Accessor, Filter, LastFilter, KeywordSet, Parameters)
	{
		Results := {}
		
		if(CouldBeURL(Filter))
		{
			Result := new this.CResult()
			Result.Title := Filter
			Result.Path := InStr(Filter, "://") ? Filter : "http://" Filter
			Result.Icon := Accessor.GenericIcons.URL
			Result.Detail1 := "Open URL"
			Result.ResultIndexingKey := "Title"
			Result.MatchQuality := 0.8 ;Not sure if this is a good match, so lower value
			Results.Insert(Result)
		}
		if(this.Settings.IncludeOperaBookmarks)
			for index, OperaBookmark in this.OperaBookmarks
				if((MatchQuality := FuzzySearch(OperaBookmark.Name, Filter, false)) > Accessor.Settings.FuzzySearchThreshold || (MatchQuality := FuzzySearch(OperaBookmark.URL, Filter, false) - 0.2) > Accessor.Settings.FuzzySearchThreshold)
				{
					Result := new this.CResult()
					Result.Title := OperaBookmark.Name
					Result.Path := OperaBookmark.URL
					Result.Icon := Accessor.GenericIcons.URL
					Result.MatchQuality := MatchQuality
					Result.ResultIndexingKey := "Path"
					Results.Insert(Result.Path, Result)
				}
		if(this.Settings.IncludeChromeBookmarks)
			for index2, ChromeBookmark in this.ChromeBookmarks
				if((MatchQuality := FuzzySearch(ChromeBookmark.Name, Filter, false)) > Accessor.Settings.FuzzySearchThreshold || (MatchQuality := FuzzySearch(ChromeBookmark.URL, Filter, false) - 0.2) > Accessor.Settings.FuzzySearchThreshold)
				{
					Result := new this.CResult()
					Result.Title := ChromeBookmark.Name
					Result.Path := ChromeBookmark.URL
					Result.Icon := Accessor.GenericIcons.URL
					Result.MatchQuality := MatchQuality
					Result.ResultIndexingKey := "Path"
					Results.Insert(Result.Path, Result)
				}
		if(this.Settings.IncludeFirefoxBookmarks)
			for index2, FirefoxBookmark in this.FirefoxBookmarks
				if((MatchQuality := FuzzySearch(FirefoxBookmark.Name, Filter, false)) > Accessor.Settings.FuzzySearchThreshold || (MatchQuality := FuzzySearch(FirefoxBookmark.URL, Filter, false) - 0.2) > Accessor.Settings.FuzzySearchThreshold)
				{
					Result := new this.CResult()
					Result.Title := FirefoxBookmark.Name
					Result.Path := FirefoxBookmark.URL
					Result.Icon := Accessor.GenericIcons.URL
					Result.MatchQuality := MatchQuality
					Result.ResultIndexingKey := "Path"
					Results.Insert(Result.Path, Result)
				}
		if(this.Settings.IncludeIEBookmarks)
			for index3, IEBookmark in this.IEBookmarks
				if((MatchQuality := FuzzySearch(IEBookmark.Name, Filter, false)) > Accessor.Settings.FuzzySearchThreshold || (MatchQuality := FuzzySearch(IEBookmark.URL, Filter, false) - 0.2) > Accessor.Settings.FuzzySearchThreshold)
				{
					Result := new this.CResult()
					Result.Title := IEBookmark.Name
					Result.Path := IEBookmark.URL
					Result.Icon := Accessor.GenericIcons.URL
					Result.MatchQuality := MatchQuality
					Result.ResultIndexingKey := "Path"
					Results.Insert(Result.Path, Result)
				}
		return Results
	}

	ShowSettings(PluginSettings, Accessor, PluginGUI)
	{
		AddControl(PluginSettings, PluginGUI, "Checkbox", "IncludeOperaBookmarks", "Include Opera bookmarks", "", "")
		AddControl(PluginSettings, PluginGUI, "Checkbox", "IncludeChromeBookmarks", "Include Chrome bookmarks", "", "")
		AddControl(PluginSettings, PluginGUI, "Checkbox", "IncludeFirefoxBookmarks", "Include Firefox bookmarks", "", "")
		AddControl(PluginSettings, PluginGUI, "Checkbox", "IncludeIEBookmarks", "Include IE bookmarks", "", "")
		AddControl(PluginSettings, PluginGUI, "Checkbox", "UseSelectedText", "Automatically open the selected text as URL in Accessor when appropriate", "", "")
	}

	LoadChromeBookmarks(obj = "")
	{
		if(!obj)
		{
			;Get path of bookmark file. Local appdata is not defined on XP but it can be retrieved through registry
			RegRead, LocalAppData, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders, Local AppData
			if(FileExist(LocalAppData "\Google\Chrome\User Data\Default\Bookmarks"))
			{
				FileRead, json, % LocalAppData "\Google\Chrome\User Data\Default\Bookmarks"
				obj := lson(json)
				;obj := JSON_load(LocalAppData "\Google\Chrome\User Data\Default\Bookmarks")
				this.ChromeBookmarks := Array()
				for index, folder in obj.roots
					this.LoadChromeBookmarks(folder)
			}
		}
		else
		{
			if(obj.HasKey("Children"))
				for index, node in obj.Children
					this.LoadChromeBookmarks(node)
			if(obj.Type = "URL" && IsURL(obj.URL))
				this.ChromeBookmarks.Insert({Name : obj.Name, URL : obj.URL})
		}
	}

	LoadOperaBookmarks()
	{
		/*
		Example url:
#URL
	ID=329
	NAME=FastMail
	URL=http://redir.opera.com/bookmarks/fastmail
	DISPLAY URL=http://www.fastmail.fm/
	CREATED=1301005413
	UNIQUEID=FCAFE25AD1B88E4886653619102BB03A
	PARTNERID=opera-mail

		*/
		if(FileExist(A_AppData "\Opera\Opera\bookmarks.adr"))
		{
			this.OperaBookmarks := Array()
			state = 0 ; 0=undefined, 1= In URL
			Loop, Read, %A_AppData%\Opera\Opera\bookmarks.adr
			{
				if(A_LoopReadLine = "#URL")
				{
					state = 1
					URL := {}
				}
				else if(state = 1)
				{
					if(InStr(A_LoopReadLine, "NAME="))
						URL.Name := SubStr(A_LoopReadLine, InStr(A_LoopReadLine, "=") + 1)
					else if(InStr(A_LoopReadLine, "URL="))
						URL.URL := SubStr(A_LoopReadLine, InStr(A_LoopReadLine, "=") + 1)
					else
						continue
					if(URL.HasKey("URL") && URL.HasKey("Name") && IsURL(URL.url))
					{
						this.OperaBookmarks.Insert(URL)
						state = 0
					}
				}
			}
		}
	}

	LoadIEBookmarks()
	{
		Loop, % ExpandPathPlaceholders("%USERPROFILE%") "\Favorites\*.url", 0, 1
		{
			Loop, Read, %A_LoopFileLongPath%
			{
				if(pos := InStr(A_LoopReadLine, "URL="))
				{
					Target := SubStr(A_LoopReadLine, pos + 4)
					break
				}
			}
			if(IsURL(Target))
				this.IEBookmarks.Insert({Name : SubStr(A_LoopFileName, 1, -4), URL : Target})
		}
	}
	
	LoadFirefoxBookmarks()
	{
		Loop, % DBPath := ExpandPathPlaceholders("%APPDATA%") "\Mozilla\Firefox\Profiles\*.*", 2, 0
		{
			if(strEndsWith(A_LoopFileLongPath, ".default"))
			{
				DB := DBA.DatabaseFactory.OpenDatabase("SqLite", A_LoopFileLongPath "\places.sqlite")
				result := DB.Query("SELECT moz_bookmarks.title,moz_places.url FROM moz_bookmarks JOIN moz_places WHERE moz_bookmarks.type=1 AND moz_bookmarks.fk=moz_places.id AND moz_bookmarks.title NOT NULL").rows
				for index, bookmark in result
					if(IsURL(bookmark.url))
						this.FirefoxBookmarks.Insert({Name : bookmark.title, URL : bookmark.url})
			}
		}
	}

	OpenURL(Accessor, ListEntry)
	{
		URL := IsURL(ListEntry.Path) ? ListEntry.Path : ListEntry.Title
		if(URL)
		{
			url := (!InStr(URL, "://") ? "http://" : "") URL
			run %url%,, UseErrorLevel
		}
	}
}
#Include <DBA>