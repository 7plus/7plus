Class CShortenURLAction Extends CAction
{
	static Type := RegisterType(CShortenURLAction, "Shorten a URL")
	static Category := RegisterCategory(CShortenURLAction, "Internet")
	static __WikiLink := "ShortenURL"
	static URL := "${Clip}"
	static Method := "Goo.gl"
	static WriteToClipboard := true
	static WriteToPlaceholder := "ShortURL"
	
	Execute(Event)
	{
		URL := Event.ExpandPlaceholders(this.URL)
		if(!IsURL(URL))
			return 0
		if(this.Method = "Goo.gl")
			ShortURL := googl(URL)
		
		if(ShortURL)
		{
			if(this.WriteToClipboard)
				Clipboard := ShortURL			
			if(this.WriteToPlaceholder)
				EventSystem.GlobalPlaceholders[this.WriteToPlaceholder] := ShortURL
			Notify("URL shortened!", "URL shortened" (this.WriteToClipboard ? " and copied to clipboard!" : "!"), 2, NotifyIcons.Success)
			return 1
		}
		return 0
	} 

	DisplayString()
	{
		return "Shorten URL: " this.URL
	}
	
	GuiShow(GUI, GoToLabel = "")
	{
		static sGUI
		if(GoToLabel = "")
		{
			sGUI := GUI
			this.AddControl(GUI, "Text", "Desc", "This action shortens the URL in the clipboard by using the Goo.gl service. The shortened URL can be written back to clipboard or stored in a placeholder.")
			this.AddControl(GUI, "Edit", "URL", "", "", "URL:", "Placeholders", "Action_ShortenURL_Placeholders")
			this.AddControl(GUI, "Edit", "WriteToPlaceholder", "", "", "hPlaceholder:")
			this.AddControl(GUI, "Checkbox", "WriteToClipboard", "Copy shortened URL to clipboard")
		}
		else if(GoToLabel = "Placeholders")
			ShowPlaceholderMenu(sGUI, "URL")
	}
}
Action_ShortenURL_Placeholders:
GetCurrentSubEvent().GuiShow("", "Placeholders")
return

;Shortens a URL using goo.gl service
;Written By Flak
googl(url) 
{ 
  static apikey := "AIzaSyBXD-RmnD2AKzQcDHGnzZh4humG-7Rpdmg" 
  http := ComObjCreate("WinHttp.WinHttpRequest.5.1") 
  main := "https://www.googleapis.com/urlshortener/v1/url" 
  params := "?key=" apikey 
  http.open("POST", main . params, false) 
  http.SetRequestHeader("Content-Type", "application/json") 
  http.send("{""longUrl"": """ url """}") 
  RegExMatch(http.ResponseText, """id"": ""(.*?)""", match) 
  return match1 
}
