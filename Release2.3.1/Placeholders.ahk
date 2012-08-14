;Main function to expand placeholders. Placeholders are marked by ${key} and by %PATH%
;Also see Placeholders.ahk
ExpandPlaceholders(SubEvent, Text)
{
	if(IsObject(Text)) ;Internally arrays may be supplied as parameters which mustn't be expanded here
		return Text
	
	;Iteratively expand all placeholders
	OriginalText := ""
	while(OriginalText != Text && !IsObject(Text))
	{
		OriginalText := Text
		
		;Expand local dynamic placeholders (for example ${MessageResult} defined by SendMessage action)
		for key, value in SubEvent.Placeholders
		{
			if(InStr(Text,"${" key "}"))
				Text := StringReplace(Text, "${" key "}", value, 1)
		}
		;Expand dynamic placeholders with global scope (for example the result of an Input action)
		for key, value in EventSystem.GlobalPlaceholders
		{
			if(InStr(Text,"${" key "}"))
				Text := StringReplace(Text, "${" key "}", value, 1)
		}
		Text := ExpandInternalPlaceHolders(Text)
	}
	return Text
}

;Expands internal placeholders found inside text
ExpandInternalPlaceholders(text)
{
	text := ExpandPathPlaceholders(text)
	len := strLen(text)
	pos := 1
	Loop % len
	{
		2chars := SubStr(text, pos, 2)
		if(2chars = "${")
		{
			end := InStr(text, "}",0,pos + 2)
			if(end)
			{
				placeholder := SubStr(text, pos + 2, end - (pos + 2))
				expanded := ExpandPlaceholder(placeholder)
				text := SubStr(text, 1, pos - 1) expanded SubStr(text, end + 1)
				pos += strLen(expanded)
				continue
			}
		}
		pos++
	}
	return text
}


;Expands a single placeholder. Placeholder argument contains only the name, without ${}
ExpandPlaceholder(Placeholder)
{
	if(Placeholder = "Clip")
		return ReadClipboardText()
	else if(Placeholder = "A")
		return WinExist("A")
	else if(Placeholder = "Class")
		return WinGetClass("A")
	else if(Placeholder = "Title")
		return WinGetTitle("A")
	else if(Placeholder = "Control")
	{
		if(WinVer >= WIN_Vista)
			ControlGetFocus focussed, A
		else
			focussed := XPGetFocussed()
		return focussed
	}
	else if(Placeholder = "WindowsVersion")
		return WinVer
	else if(Placeholder = "WinVer") ;Deprecated
		return A_OSVersion
	else if(Placeholder = "WINXP")
		return WIN_XP
	else if(Placeholder = "WINXP64")
		return WIN_XP64
	else if(Placeholder = "WINVISTA")
		return WIN_VISTA
	else if(Placeholder = "WIN7")
		return WIN_7
	else if(Placeholder = "WIN8")
		return WIN_8
	else if(Placeholder = "U" || InStr(Placeholder,"M") = 1) ;Mouse submenu
	{
		if(strlen(Placeholder > 1) && InStr(Placeholder, "A") = 2)
			CoordMode, Mouse, Relative
		MouseGetPos,x,y,UnderMouse, Control
		if(strlen(Placeholder > 1) && InStr(Placeholder, "U") = 2)
		{
			WinGetPos, wx, wy, , ,ahk_id %UnderMouse%
			x -= wx
			y -= wy
		}
		if(Placeholder = "U")
			return UnderMouse
		else if(InStr(Placeholder, "X") = 2)
			return x
		else if(InStr(Placeholder, "Y") = 2)
			return y
		else if(InStr(Placeholder, "NN") = 2)
			return Control
		else if(InStr(Placeholder, "C") = 2)
			return WinGetClass("ahk_id " UnderMouse)
	}
	else if(InStr(Placeholder, "DateTime") = 1)
	{
		Placeholder := SubStr(Placeholder, 9)
		FormatTime, Placeholder ,, %Placeholder%
		return Placeholder
	}
	else if(Placeholder = "TitleFilename")
	{
		;Extract filename from active window title
		RegExMatch(WinGetTitle("A"),"([a-zA-Z]:\\[^/:\*\?<>\|]+\.\w{2,6})|(\\\\[^/:\*\?<>\|]+\.\w{2,6})",titlepath)
		return titlepath
	}
	else if(Placeholder = "TitlePath")
	{
		;Extract filename from active window title
		RegExMatch(WinGetTitle("A"),"([a-zA-Z]:\\[^/:\*\?<>\|]+\.\w{2,6})|(\\\\[^/:\*\?<>\|]+\.\w{2,6})",titlepath)
		SplitPath, titlepath,,titlepath
		return titlepath
	}
	else if(Placeholder = "P")
		return Settings.Explorer.CurrentPath
	else if(Placeholder = "T")
		return Settings.Explorer.PreviousPath
	else if(Placeholder = "SelText")
		return GetSelectedText()
	else if(InStr(Placeholder, "Sel") = 1 && (WinActive("ahk_group ExplorerGroup") || WinActive("ahk_group DesktopGroup") || IsDialog()))
	{
		files := Navigation.GetSelectedFilepaths()
		RegExMatch(Placeholder,"Sel\d+",number)
		array := Array()
		if(number)
		{
			number := SubStr(number, 4)
			if(number > 0 && files.MaxIndex() <= number)
				files := Array(files[number])
			else
				files := Array()
		}
		if(files.MaxIndex() = 0)
			return ""
		Placeholder := SubStr(Placeholder, 4+max(strLen(number), 1))
		quote := InStr(Placeholder, "Q")
		Filename := InStr(Placeholder, "NE")
		FilenameNoExt := !Filename && InStr(Placeholder, "N")
		Extension := !Filename && InStr(Placeholder, "E")
		FilePath := InStr(Placeholder, "D")
		NewLine := InStr(Placeholder, "M")
		output := ""
		for index, file in files
		{
			SplitPath, file, name, path, ext, namenoext
			if(Filename)
				file := name
			else if(FilenameNoExt)
				file := namenoext
			else if(Extension)
				file := ext
			else if(FilePath)
				file := path
			if(quote)
				file := """" file """"
			output .= file (NewLine ? "`n" : " ")
		}
		return SubStr(output,1,-1)
	}
}
ShowPlaceholderMenu(SubEventGUI, name, ClickedMenu="")
{
	static sSubEventGUI,sname
	if(ClickedMenu = "")
	{
		sSubEventGUI := SubEventGUI
		sname := name
		
		Menu, Placeholders, add, 1,PlaceholderHandler
		Menu, Placeholders, DeleteAll
		
		Menu, Placeholders_FilePaths, add, 1,PlaceholderHandler
		Menu, Placeholders_FilePaths, DeleteAll
		Menu, Placeholders_DateTime, add, 1,PlaceholderHandler
		Menu, Placeholders_DateTime, DeleteAll		
		Menu, Placeholders_Explorer, add, 1,PlaceholderHandler
		Menu, Placeholders_Explorer, DeleteAll
		Menu, Placeholders_Mouse, add, 1,PlaceholderHandler
		Menu, Placeholders_Mouse, DeleteAll
		Menu, Placeholders_System, add, 1,PlaceholderHandler
		Menu, Placeholders_System, DeleteAll
		Menu, Placeholders_Windows, add, 1,PlaceholderHandler
		Menu, Placeholders_Windows, DeleteAll
		Menu, Placeholders_Accessor, add, 1,PlaceholderHandler
		Menu, Placeholders_Accessor, DeleteAll
		
		Menu, Placeholders, add, Accessor, :Placeholders_Accessor
		Menu, Placeholders, add, Date and Time, :Placeholders_DateTime
		Menu, Placeholders, add, Explorer, :Placeholders_Explorer
		Menu, Placeholders, add, File Paths, :Placeholders_FilePaths
		Menu, Placeholders, add, Mouse, :Placeholders_Mouse
		Menu, Placeholders, add, System, :Placeholders_System
		Menu, Placeholders, add, Windows, :Placeholders_Windows
		
		Menu, Placeholders_Accessor, add, ${AccAll} - All parameters of the Accessor command (for an event using an Accessor trigger), PlaceholderHandler
		Menu, Placeholders_Accessor, add, ${Acc1} - First parameter of the Accessor command (for an event using an Accessor trigger), PlaceholderHandler
		Menu, Placeholders_Accessor, add, ${Acc2} - second parameter of the Accessor command (for an event using an Accessor trigger), PlaceholderHandler
		Menu, Placeholders_Accessor, add, ${Acc3} - third parameter of the Accessor command (for an event using an Accessor trigger), PlaceholderHandler
		Menu, Placeholders_Accessor, add, ${Acc4} - 4th parameter of the Accessor command (for an event using an Accessor trigger), PlaceholderHandler
		Menu, Placeholders_Accessor, add, ${Acc5} - 5th parameter of the Accessor command (for an event using an Accessor trigger), PlaceholderHandler
		Menu, Placeholders_Accessor, add, ${Acc6} - 6th parameter of the Accessor command (for an event using an Accessor trigger), PlaceholderHandler
		Menu, Placeholders_Accessor, add, ${Acc7} - 7th parameter of the Accessor command (for an event using an Accessor trigger), PlaceholderHandler
		Menu, Placeholders_Accessor, add, ${Acc8} - 8th parameter of the Accessor command (for an event using an Accessor trigger), PlaceholderHandler
		Menu, Placeholders_Accessor, add, ${Acc9} - 9th parameter of the Accessor command (for an event using an Accessor trigger), PlaceholderHandler
		
		Menu, Placeholders_DateTime, add, ${DateTime} - Language-specific time and date (4:55 PM Saturday`, November 27`, 2010), PlaceholderHandler
		Menu, Placeholders_DateTime, add, ${DateTimeLongDate} - Language-specific long date (Friday`, April 23`, 2010), PlaceholderHandler
		Menu, Placeholders_DateTime, add, ${DateTimeShortDate} - Language-specific short date (02/29/10), PlaceholderHandler
		Menu, Placeholders_DateTime, add, ${DateTimeTime} - Language-specific time (5:26 PM), PlaceholderHandler
		Menu, Placeholders_DateTime, add, ${DateTime[Format]} - Other [Format]`, see here, PlaceholderHandler
		
		Menu, Placeholders_Explorer, add, ${P} - Path of last active explorer window, PlaceholderHandler
		Menu, Placeholders_Explorer, add, ${PP} - Previous path of explorer window, PlaceholderHandler
		Menu, Placeholders_Explorer, add, ${Sel1} - Filepath of first selected file, PlaceholderHandler
		Menu, Placeholders_Explorer, add, ${Sel2DQ} - Directory of second selected file`, quoted, PlaceholderHandler
		Menu, Placeholders_Explorer, add, ${Sel3N} - Filename of third selected file`, no extension, PlaceholderHandler
		Menu, Placeholders_Explorer, add, ${Sel4NE} - Filename of fourth selected file`, including extension, PlaceholderHandler
		Menu, Placeholders_Explorer, add, ${SelN} - Filepaths of all selected files`, separated by spaces, PlaceholderHandler
		Menu, Placeholders_Explorer, add, ${SelNNEM} - Filenames+extensions of all selected files`, separated by new lines, PlaceholderHandler
		Menu, Placeholders_Explorer, add, Feel free to combine those expressions!, PlaceholderHandler
		
		Menu, Placeholders_FilePaths, add, `%ProgramFiles`% - Program Files Directory, PlaceholderHandler
		Menu, Placeholders_FilePaths, add, `%AppData`% - AppData Directory, PlaceholderHandler
		Menu, Placeholders_FilePaths, add, `%Desktop`% - Desktop Directory, PlaceholderHandler
		Menu, Placeholders_FilePaths, add, `%MyDocuments`% - My Documents Directory, PlaceholderHandler
		Menu, Placeholders_FilePaths, add, `%Temp`% - Temp Directory, PlaceholderHandler
		Menu, Placeholders_FilePaths, add, `%StartMenu`% - Start Menu Directory, PlaceholderHandler
		Menu, Placeholders_FilePaths, add, `%StartMenuCommon`% - Common Start Menu Directory, PlaceholderHandler
		Menu, Placeholders_FilePaths, add, `%7plusDrive`% - Drive 7plus is running from, PlaceholderHandler
		Menu, Placeholders_FilePaths, add, `%7plusDir`% - 7plus Directory, PlaceholderHandler
		Menu, Placeholders_FilePaths, add, `%ImageEditor`% - Default image editor, PlaceholderHandler
		Menu, Placeholders_FilePaths, add, `%TextEditor`% - Default text editor, PlaceholderHandler
		
		Menu, Placeholders_Mouse, add, ${U} - Handle of window under mouse, PlaceholderHandler
		Menu, Placeholders_Mouse, add, ${MC} - Class of window under mouse, PlaceholderHandler
		Menu, Placeholders_Mouse, add, ${MNN} - ClassNN of control under mouse, PlaceholderHandler
		Menu, Placeholders_Mouse, add, ${MX} - Mouse X coordinate, PlaceholderHandler
		Menu, Placeholders_Mouse, add, ${MY} - Mouse Y coordinate, PlaceholderHandler		
		Menu, Placeholders_Mouse, add, ${MXA} - Mouse X coordinate`, relative to active window, PlaceholderHandler
		Menu, Placeholders_Mouse, add, ${MYA} - Mouse Y coordinate`, relative to active window, PlaceholderHandler		
		Menu, Placeholders_Mouse, add, ${MXU} - Mouse X coordinate`, relative to window under mouse, PlaceholderHandler
		Menu, Placeholders_Mouse, add, ${MYU} - Mouse Y coordinate`, relative to window under mouse, PlaceholderHandler
		
		Menu, Placeholders_System, add, ${Clip} - Clipboard contents, PlaceholderHandler
		Menu, Placeholders_System, add, ${MessageResult} - Result of previous SendMessage action (Send only!), PlaceholderHandler
		Menu, Placeholders_System, add, ${wParam} - wParam value if this condition/action was triggered by OnMessage trigger, PlaceholderHandler
		Menu, Placeholders_System, add, ${lParam} - lParam value if this condition/action was triggered by OnMessage trigger, PlaceholderHandler
		Menu, Placeholders_System, add, ${Context} - List of selected files(with paths) from Contextmenu trigger`, separated by newlines, PlaceholderHandler
		Menu, Placeholders_System, add, ${SelText} - Selected Text, PlaceholderHandler
		Menu, Placeholders_System, add, ${WinVer} - Windows version(WIN_7`, WIN_VISTA`, WIN_XP`, WIN_2003`,...), PlaceholderHandler
		Menu, Placeholders_System, add, ${WindowsVersion} - Numeric Windows version(XP : 5.1`, VISTA : 6.0`, 7 : 6.1`, 8 : 6.2`,...), PlaceholderHandler
		Menu, Placeholders_System, add, ${WINXP} - Windows XP version number(5.1), PlaceholderHandler
		Menu, Placeholders_System, add, ${WINXP64} - Windows XP x64 version number(5.2), PlaceholderHandler
		Menu, Placeholders_System, add, ${WINVISTA} - Windows Vista version number(6.0), PlaceholderHandler
		Menu, Placeholders_System, add, ${WIN7} - Windows 7 version number(6.1), PlaceholderHandler
		Menu, Placeholders_System, add, ${WIN8} - Windows 8 version number(6.2), PlaceholderHandler
		
		Menu, Placeholders_Windows, add, ${A} - Active window handle, PlaceholderHandler
		Menu, Placeholders_Windows, add, ${Class} - Active window class, PlaceholderHandler
		Menu, Placeholders_Windows, add, ${Title} - Active window title, PlaceholderHandler
		Menu, Placeholders_Windows, add, ${Control} - Focussed control ClassNN, PlaceholderHandler
		Menu, Placeholders_Windows, add, ${TitlePath} - Path in active window title, PlaceholderHandler
		Menu, Placeholders_Windows, add, ${TitleFilename} - Path and filename in active window title, PlaceholderHandler
		Menu, Placeholders, Show
	}
	else
	{
		if(ClickedMenu = "${DateTime[Format]} - Other [Format], see here")
		{
			run http://www.autohotkey.com/docs/commands/FormatTime.htm
			return
		}
		else if(ClickedMenu = "Feel free to combine those expressions!")
			return
		else if(InStr(ClickedMenu, "-"))
			placeholder := SubStr(ClickedMenu, 1, InStr(ClickedMenu, " -") - 1)
		
		enum := sSubEventGUI._newEnum()
		while enum[key,value]
		{
			if(InStr(key,"_" sname) && !InStr(key, "Button1_") && !InStr(key, "Button2_") && !InStr(key, "Desc_"))
			{
				ControlGetText, text, , ahk_id %value%
				ControlSetText, , %text%%placeholder%, ahk_id %value%
				break
			}
		}
	}
}
PlaceholderHandler:
ShowPlaceholderMenu("","",A_ThisMenuItem)
return