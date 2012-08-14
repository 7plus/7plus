Class CCalculatorPlugin extends CAccessorPlugin
{
	;Register this plugin with the Accessor main object
	static Type := CAccessor.RegisterPlugin("Calculator", CCalculatorPlugin)
	
	Description := "Use Google Calc to make calculations `nand unit conversions (e.g. ""g in pounds"")."
	
	Cleared := false
	List := Array()

	AllowDelayedExecution := false

	Column1Text := "Calculation"
	Column2Text := "URL"
	
	Class CSettings extends CAccessorPlugin.CSettings
	{
		Keyword := "="
		KeywordOnly := false ;This is actually true, but IsInSinglePluginContext needs to be called every time so it is handled manually here
		MinChars := 0
	}

	Class CResult extends CAccessorPlugin.CResult
	{
		Class CActions extends CArray
		{
			DefaultAction := new CAccessor.CAction("Copy Result`tCTRL + C", "Copy")
			__new()
			{
			}
		}
		Type := "Calculator"
		Actions := new this.CActions()
		Priority := CCalculatorPlugin.Instance.Priority
		MatchQuality := 1
		Detail1 := "Calculator"
	}

	IsInSinglePluginContext(Filter, LastFilter)
	{
		return InStr(Filter, this.Settings.Keyword) = 1
	}

	OnOpen(Accessor)
	{
		this.List := Array()
	}

	OnClose(Accessor)
	{
		if(IsObject(this.List))
			for index, ListEntry in this.List
				if(ListEntry.Icon != Accessor.GenericIcons.Application)			
					DestroyIcon(ListEntry.Icon)
	}

	RefreshList(Accessor, Filter, LastFilter, KeywordSet, Parameters)
	{
		if(!KeywordSet && InStr(Accessor.FilterWithoutTimer, this.SetTimer.Keyword) != 1)
			return
		Results := Array()
		for index, ListEntry in this.List
		{
			Result := new this.CResult()
			Result.Title := ListEntry.Result
			Result.Path := ListEntry.URL
			Result.Icon := ListEntry.Icon
			Results.Insert(Result)
		}
		return Results
	}

	Copy(Accessor, ListEntry)
	{
		if(ListEntry)
			Clipboard := ListEntry.Title
	}

	OnFilterChanged(ListEntry, Filter, LastFilter)
	{
		SetTimer, QueryCalcResult, -100
		return false
	}
}

;This function is not moved into the class because it seems possible that AHK can hang up when this function is called via SetTimerF().
QueryCalcResult:
QueryCalcResult()
return
QueryCalcResult()
{
	if(InStr(CAccessor.Instance.FilterWithoutTimer, CCalculatorPlugin.Instance.Settings.Keyword) != 1)
		return
	Filter := strTrimLeft(CAccessor.Instance.FilterWithoutTimer, CCalculatorPlugin.Instance.Settings.Keyword)
	Filter := strTrimLeft(Filter, " ")
	
	URL := "http://www.google.com/search?q=" uriEncode(Filter)
	;~ https://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=Paris%20Hilton&key=INSERT-YOUR-KEY
	Headers := "Referer: http://code.google.com/p/7plus/`nUser-Agent: Mozilla/5.0 (Windows NT 6.1; rv:12.0) Gecko/20100101 Firefox/12.0"
	
	HTTPRequest(URL, GoogleQuery, Headers, "BINARY")
	GoogleQuery := StrGet(&GoogleQuery, "utf-8")

	for index, entry in CCalculatorPlugin.Instance.List
		if(entry.Icon)
			DestroyIcon(entry.Icon)

	CCalculatorPlugin.Instance.List := Array()
	
	if(InStr(GoogleQuery, "/help/features.html#calculator"))
	{
		outputdebug 1
		RegexMatch(GoogleQuery, "s)<h2 class=r.*?=.*?</h2>.*?#calculator", result)
		outputdebug res %result%
		Result := SubStr(Result, start := InStr(Result, "b>") + 2, InStr(Result, "</b>") - start)
		outputdebug res %result%
		StringReplace, result, result, ">,,All
		StringReplace, result, result, ,,All
		StringReplace, result, result, </h2>,,All
		StringReplace, result, result, `r,,All
		StringReplace, result, result, `n,,All
		StringReplace, result, result, <sup>, ^,,All
		Result := RegExReplace(Result, "[ ]{2,}", " ")
		Result := RegExReplace(Result, "(?=\d) (?=\d)", "")
		result := unhtml(Deref_Umlauts(result))
		outputdebug res2 %result%
		if(result)
		{
			if(!FileExist( A_Temp "\7plus\calc_img.gif"))
				URLDownloadToFile, http://www.google.com/images/calc_img.gif, %A_Temp%\7plus\calc_img.gif
			pBitmap := Gdip_CreateBitmapFromFile(A_Temp "\7plus\calc_img.gif")
			hIcon := Gdip_CreateHICONFromBitmap(pBitmap)
			;hIcon := ExtractIcon(A_Temp "\7plus\calc_img.gif")
			;hIcon := LoadIcon(A_Temp "\7plus\calc_img.gif")
			CCalculatorPlugin.Instance.List.Insert(Object("result",result,"URL", "http://www.google.com/search?q=" Filter, "Icon", hIcon))
			CAccessor.Instance.RefreshList()
		}
	}
}