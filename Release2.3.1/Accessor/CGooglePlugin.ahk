Class CGooglePlugin extends CAccessorPlugin
{
	;Register this plugin with the Accessor main object
	static Type := CAccessor.RegisterPlugin("Google", CGooglePlugin)
	
	Description := "Quickly access google by typing ""[keyword] Search query"" and open the results `ndirectly from within Accessor."
	
	Cleared := false
	List := Array()
	
	AllowDelayedExecution := false
	
	Column2Text := "URL"
	
	Class CSettings extends CAccessorPlugin.CSettings
	{
		Keyword := "g"
		KeywordOnly := false ;This is actually true, but IsInSinglePluginContext needs to be called every time so it is handled manually here
		MinChars := 0
	}
	
	Class CResult extends CAccessorPlugin.CResult
	{
		Class CActions extends CArray
		{
			DefaultAction := new CAccessor.CAction("Open URL", "OpenURL")
			__new()
			{
				this.Insert(new CAccessor.CAction("Copy URL`tCTRL + C", "Copy", "", false, false))
				this.Insert(CAccessorPlugin.CActions.OpenWith)
			}
		}
		Type := "Google"
		Actions := new this.CActions()
		Priority := CGooglePlugin.Instance.Priority
		MatchQuality := 1 ;Only direct matches are used by this plugin
		Detail1 := "Google result"
	}

	IsInSinglePluginContext(Filter, LastFilter)
	{
		if(InStr(Filter, this.Settings.Keyword " ") = 1)
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

	OnOpen(Accessor)
	{
		this.List := Array()
		this.Cleared := false
	}

	RefreshList(Accessor, Filter, LastFilter, KeywordSet, Parameters)
	{
		if(!KeywordSet)
			return
		Results := Array()
		for index, ListEntry in this.List
		{
			Result := new this.CResult()
			Result.Title := ListEntry.titleNoFormatting
			Result.VisibleURL := ListEntry.VisibleURL
			Result.Path := ListEntry.UnescapedUrl
			Result.Icon := Accessor.GenericIcons.URL
			Results.Insert(Result)
		}
		return Results
	}

	GetDisplayStrings(ListEntry, ByRef Title, ByRef Path, ByRef Detail1, ByRef Detail2)
	{
		Path := ListEntry.VisibleURL
	}
	OpenURL(Accessor, ListEntry)
	{
		Run(ListEntry.Path)
	}

	Copy(Accessor, ListEntry)
	{
		Clipboard := ListEntry.Path
	}

	OnFilterChanged(ListEntry, Filter, LastFilter)
	{
		SetTimer, QueryGoogleResult, -100
		return false
	}

}

;This function is not moved into the class because it seems possible that AHK can hang up when this function is called via SetTimerF().
QueryGoogleResult:
QueryGoogleResult()
return
QueryGoogleResult()
{
	outputdebug query google result
	if(InStr(CAccessor.Instance.FilterWithoutTimer, CGooglePlugin.Instance.Settings.Keyword " ") != 1)
		return
	outputdebug do it
	Filter := strTrim(CAccessor.Instance.FilterWithoutTimer, CGooglePlugin.Instance.Settings.Keyword " ")
	
	URL := "http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=" uriEncode(Filter) "&rsz=8&key=ABQIAAAA7YzZ21dHSNKA2c0eu0LVKRTn4CuOUlhiyluSCHXJ1XXcqBr54RRnE69I0b16vHAVgBri6LxRQYtELw"
	Headers := "Referer: http://code.google.com/p/7plus/"
	;~ https://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=Paris%20Hilton&key=INSERT-YOUR-KEY
	HTTPRequest(URL, GoogleQuery, Headers, "")
	
	CGooglePlugin.Instance.List := Array()
	
	pos1 := 0, pos2 := 0, pos3 := 0
	Loop
	{
		pos1 := RegexMatch(GoogleQuery, "i)""unescapedUrl"":""(.*?)""", unescapedURL, pos1 + 1)
		pos2 := RegexMatch(GoogleQuery, "i)""visibleUrl"":""(.*?)""", visibleUrl, pos2 + 1)
		pos3 := RegexMatch(GoogleQuery, "i)""titleNoFormatting"":""(.*?)""", titleNoFormatting, pos3 + 1)
		titleNoFormatting1 := unhtml(Deref_Umlauts(titleNoFormatting1))
		if(pos1 && pos2 && pos3 && unescapedURL1 && visibleURL1 && titleNoFormatting1)
			CGooglePlugin.Instance.List.Insert(Object("unescapedURL",unescapedURL1,"visibleUrl", visibleUrl1, "titleNoFormatting", titleNoFormatting1))
		else
			break
	}
	CAccessor.Instance.RefreshList()
;{"responseData": {"results":[{"GsearchResultClass":"GwebSearch","unescapedUrl":"http://www.test.com/","url":"http://www.test.com/","visibleUrl":"www.test.com","cacheUrl":"http://www.google.com/search?q\u003dcache:S9XHtkEncW8J:www.test.com","title":"\u003cb\u003eTest\u003c/b\u003e.com Web Based \u003cb\u003eTesting\u003c/b\u003e and Certification Software v2.0","titleNoFormatting":"Test.com Web Based Testing and Certification Software v2.0","content":"Easily Author and Administer your own Training Content, \u003cb\u003eTests\u003c/b\u003e, and Certification   Programs Online. \u003cb\u003eTest\u003c/b\u003e.com is Web Based Software."},{"GsearchResultClass":"GwebSearch","unescapedUrl":"http://www.speakeasy.net/speedtest/","url":"http://www.speakeasy.net/speedtest/","visibleUrl":"www.speakeasy.net","cacheUrl":"http://www.google.com/search?q\u003dcache:71lCly1h_zMJ:www.speakeasy.net","title":"Speakeasy - Speed \u003cb\u003eTest\u003c/b\u003e","titleNoFormatting":"Speakeasy - Speed Test","content":"\u003cb\u003eTest\u003c/b\u003e your Internet Connection with Speakeasy\u0026#39;s reliable and accurate broadband   speed \u003cb\u003etest\u003c/b\u003e. What\u0026#39;s your speed?"},{"GsearchResultClass":"GwebSearch","unescapedUrl":"http://en.wikipedia.org/wiki/Test","url":"http://en.wikipedia.org/wiki/Test","visibleUrl":"en.wikipedia.org","cacheUrl":"http://www.google.com/search?q\u003dcache:dxrXMu4BMrYJ:en.wikipedia.org","title":"\u003cb\u003eTest\u003c/b\u003e - Wikipedia, the free encyclopedia","titleNoFormatting":"Test - Wikipedia, the free encyclopedia","content":"\u003cb\u003eTest\u003c/b\u003e, \u003cb\u003eTEST\u003c/b\u003e or Tester may refer to: \u003cb\u003eTest\u003c/b\u003e (assessment), an assessment intended to   measure the respondents\u0026#39; knowledge or other abilities; Physical fitness \u003cb\u003etest\u003c/b\u003e \u003cb\u003e...\u003c/b\u003e"},{"GsearchResultClass":"GwebSearch","unescapedUrl":"http://www.humanmetrics.com/cgi-win/JTypes1.htm","url":"http://www.humanmetrics.com/cgi-win/JTypes1.htm","visibleUrl":"www.humanmetrics.com","cacheUrl":"http://www.google.com/search?q\u003dcache:pQDPQucrOesJ:www.humanmetrics.com","title":"Personality \u003cb\u003etest\u003c/b\u003e based on Jung and Briggs Myers typology","titleNoFormatting":"Personality test based on Jung and Briggs Myers typology","content":"Online \u003cb\u003etest\u003c/b\u003e based on Jung and Briggs Myers typology provides your personality   formula, the description of your type, list of occupations, and option to \u003cb\u003e...\u003c/b\u003e"}],"cursor":{"pages":[{"start":"0","label":1},{"start":"4","label":2},{"start":"8","label":3},{"start":"12","label":4},{"start":"16","label":5},{"start":"20","label":6},{"start":"24","label":7},{"start":"28","label":8}],"estimatedResultCount":"54100000","currentPageIndex":0,"moreResultsUrl":"http://www.google.com/search?oe\u003dutf8\u0026ie\u003dutf8\u0026source\u003duds\u0026start\u003d0\u0026hl\u003den\u0026q\u003dtest"}}, "responseDetails": null, "responseStatus": 200}
}