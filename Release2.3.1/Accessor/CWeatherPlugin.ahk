Class CWeatherPlugin extends CAccessorPlugin
{
	;Register this plugin with the Accessor main object
	static Type := CAccessor.RegisterPlugin("Weather", CWeatherPlugin)
	
	Description := "Quickly look at the weather for any location using Google. Just type ""[Keyword] location""."
	
	Cleared := false
	List := Array()

	AllowDelayedExecution := false
	
	Column1Text := "Weather Prediction"
	Column2Text := "Location"
	
	Class CSettings extends CAccessorPlugin.CSettings
	{
		Keyword := "Weather"
		KeywordOnly := false ;This is actually true, but IsInSinglePluginContext needs to be called every time so it is handled manually here
		MinChars := 2
		DefaultLocation := ""
	}

	Class CResult extends CAccessorPlugin.CResult
	{
		Class CActions extends CArray
		{
			DefaultAction := new CAccessor.CAction("Copy`tCTRL + C", "Copy", "", true, false)
			__new()
			{
			}
		}
		Type := "Weather"
		Actions := new this.CActions()
		Priority := CWeatherPlugin.Instance.Priority
		MatchQuality := 1 ; All results are equally good
	}

	IsInSinglePluginContext(Filter, LastFilter)
	{
		if(InStr(Filter, this.Settings.Keyword) = 1)
		{
			if(!this.Cleared)
			{
				this.Cleared := true
				CAccessor.Instance.RefreshList()
			}
			return true
		}
		this.Cleared := false
		return false
	}

	OnGUICreate(AccessorGUI)
	{
		AccessorGUI.lnkFooter.Click.Handler := new Delegate(this, "OnFooterClick")
	}
	OnFooterClick(Sender, URLorID, Index)
	{
		if(CAccessor.Instance.SingleContext = this.Type)
		{
			if(Index = 1)
			{
				outputdebug index
				Filter := strTrim(CAccessor.Instance.FilterWithoutTimer, this.Settings.Keyword " ")
				this.Settings.DefaultLocation := Filter
			}
		}
	}
	OnOpen(Accessor)
	{
		this.List := Array()
		this.Cleared := false
	}

	OnClose(Accessor)
	{
		for index, ListEntry in this.List
			if(ListEntry.Icon)
				DestroyIcon(ListEntry.Icon)
	}

	RefreshList(Accessor, Filter, LastFilter, KeywordSet, Parameters)
	{
		static Penalty := 0.00001
		if(!KeywordSet && Filter != this.Settings.Keyword)
			return
		Results := Array()

		for index, ListEntry in this.List
		{
			Result := new this.CResult()
			Result.Title := ListEntry.Title
			Result.Path := ListEntry.Path
			Result.Icon := ListEntry.Icon
			Result.Priority -= Penalty * index ;For sorting by day
			Results.Insert(Result)
		}
		return Results
	}

	Copy(Accessor, ListEntry)
	{
		Clipboard := ListEntry.Title
	}
	
	OnFilterChanged(ListEntry, Filter, LastFilter)
	{
		SetTimer, QueryWeatherResult, -100
		return false
	}

	ShowSettings(PluginSettings, Accessor, PluginGUI)
	{
		AddControl(PluginSettings, PluginGUI, "Edit", "DefaultLocation", "", "", "Default Location:")
	}
	GetFooterText()
	{
		Filter := strTrim(CAccessor.Instance.FilterWithoutTimer, this.Settings.Keyword " ")
		return Filter ? "<a>Set default location</a>" : ""
	}
}

;This function is not moved into the class because it seems possible that AHK can hang up when this function is called via SetTimerF().
QueryWeatherResult:
QueryWeatherResult()
return
QueryWeatherResult()
{
	if(!CAccessor.Instance.GUI)
		return
	Accessor := CAccessor.Instance
	if(InStr(Accessor.FilterWithoutTimer, CWeatherPlugin.Instance.Settings.Keyword " ") != 1)
		return
	Filter := strTrim(Accessor.FilterWithoutTimer, CWeatherPlugin.Instance.Settings.Keyword " ")
	if(RegExMatch(Filter, "^\s*$"))
		Filter .= CWeatherPlugin.Instance.Settings.DefaultLocation

	outputdebug Query Weather for %Filter%

	for index, ListEntry in CWeatherPlugin.Instance.List
		if(ListEntry.Icon)
			DestroyIcon(ListEntry.Icon)

	CWeatherPlugin.Instance.List := Array()
	if(Filter)
	{
		URL := "http://www.google.com/ig/api?weather=" uriEncode(Filter) "&oe=utf-8"
		FileDelete, %A_Temp%\7plus\WeatherQuery.xml
		headers := ""
		HttpRequest(URL, WeatherQuery, headers, "BINARY")
		WeatherQuery := StrGet(&WeatherQuery, "UTF-8")

		Loop 5
			pos%A_Index% := 0
		
		RegexMatch(WeatherQuery, "i)<city data=""(.*?)""/>", city, 1)
		if(!city1) ;No results
			return
		WeatherQuery := SubStr(WeatherQuery, InStr(WeatherQuery, "/curren"))
		Loop
		{
			pos1 := RegexMatch(WeatherQuery, "i)<condition data=""(.*?)""/>", condition, pos1+1)
			pos2 := RegexMatch(WeatherQuery, "i)<low data=""(.*?)""/>", low, pos2+1)
			pos3 := RegexMatch(WeatherQuery, "i)<high data=""(.*?)""/>", high, pos3+1)
			pos4 := RegexMatch(WeatherQuery, "i)<day_of_week data=""(.*?)""/>", day_of_week, pos4+1)
			pos5 := RegexMatch(WeatherQuery, "i)<icon data=""(.*?)""/>", icon, pos5+1)
			
			if(pos1 && pos2 && pos3 && pos4 && pos5 && condition1 && low1 && high1 && day_of_week1 && icon1)
			{
				name := SubStr(icon1, InStr(icon1, "/", 0, 0) + 1)
				if(!FileExist(A_Temp "\7plus\" name))
					URLDownloadToFile, http://www.google.com%icon1%, %A_Temp%\7plus\%name%	
				pBitmap := Gdip_CreateBitmapFromFile(A_Temp "\7plus\" name)
				hIcon := Gdip_CreateHICONFromBitmap(pBitmap)
				low1 := Round((5/9)*(low1-32)) ;Convert °F to °C
				high1 := Round((5/9)*(high1-32)) ;Convert °F to °C
				CWeatherPlugin.Instance.List.Insert(Object("Title", day_of_week1 ": " condition1 ", Low: " low1 "°C, high: " high1 "°C", "Path", "Weather in " city1, "Icon", hIcon ))
			}
			else
				break
		}
	}
	Accessor.RefreshList()
}