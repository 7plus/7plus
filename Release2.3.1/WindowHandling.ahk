;Check screen borders/corners for Aero Flip 3D
MouseMovePolling:
MouseMovePolling()
return

MouseMovePolling()
{
	global SlideWindows
	static corner, hoverstart, ScreenCornerEvents ;Corner = 1234 (upper left, upper right, lower right, lower left), other values = not in corner
	static lastx, lasty
	;Get total size of all screens
	SysGet, VirtualX, 76
	SysGet, VirtualY, 77
	SysGet, VirtualW, 78
	SysGet, VirtualH, 79
	CoordMode, Mouse, Screen
	MouseGetPos, MouseX, MouseY, win
	if(!IsFullscreen("A", false, false))
	{
		SlideWindows.OnMouseMove(MouseX, MouseY)
		if(corner = 1 && MouseX = VirtualX && MouseY = VirtualY
		||corner = 2 && MouseX = VirtualX + VirtualW - 1 && MouseY = VirtualY
		||corner = 3 && MouseX = VirtualX + VirtualW - 1&& MouseY = VirtualY + VirtualH - 1
		||corner = 4 && MouseX = VirtualX && MouseY = VirtualY + VirtualH - 1)
		{
			index := 1
			Loop % ScreenCornerEvents.MaxIndex() ;Check if any of the events belonging to this corner have reached the time limit yet
			{
				if(ScreenCornerEvents[index].Time < A_TickCount - hoverstart)
				{
					Trigger := new CScreenCornerTrigger()
					Trigger.Corner := Corner
					EventSystem.Events.GetItemWithValue("ID", ScreenCornerEvents[index].ID).TriggerThisEvent(Trigger) ;Trigger the single event and remove it from the list so it only gets triggered once
					ScreenCornerEvents.Remove(index)
				}
				else
					index++
			}
		}
		else
		{
			if(MouseX = VirtualX && MouseY = VirtualY)
				corner := 1
			else if(MouseX = VirtualX + VirtualW - 1 && MouseY = VirtualY)
				corner := 2
			else if(MouseX = VirtualX + VirtualW - 1 && MouseY = VirtualY + VirtualH - 1)
				corner := 3
			else if(MouseX = VirtualX && MouseY = VirtualY + VirtualH - 1)
				corner := 4
			else
			{
				corner := ""
				ScreenCornerEvents :=""
				hoverstart := ""
			}
			if(corner != "") ;Create an array of matching events to save some cpu time on later checks
			{
				ScreenCornerEvents := new CArray()
				for index, Event in EventSystem.Events
				{
					if(Event.Trigger.Is(CScreenCornerTrigger) && Event.Trigger.Corner = Corner)
						ScreenCornerEvents.Insert(Object("time", Event.Trigger.Time, "Id", Event.ID))
				}
				hoverstart := A_TickCount
			}
		}
	}
	else
	{
		corner := ""
	}
	lastx := MouseX
	lasty := MouseY
	return
}

IsAutocompletionVisible()
{
	DetectHiddenWindows, Off
	return WinExist("ahk_class Auto-Suggest Dropdown")
}
;TAB autocompletion when Autocompletion list is visible
#if Settings.Misc.TabAutocompletion && IsAutocompletionVisible()
TAB::Down
#if

;Fix CTRL+Backspace and CTRL+Delete hotkeys in textboxes
#if Settings.Misc.FixEditControlWordDelete && IsEditControlActive() && NothingSelected() ;Special checks for edit control to support .NET and native edit control
^Backspace::ControlBackspaceFix()
^Delete::ControlDeleteFix()
#if

IsEditControlActive()
{
	if(WinVer >= WIN_7)
		ControlGetFocus active, A
	else
		active := XPGetFocussed()
	if(InStr(active,"edit") = 1 || RegexMatch(active,"WindowsForms\d*.EDIT."))
		return true
	return false
}
NothingSelected()
{
	if(WinVer >= WIN_7)
		ControlGetFocus focussed, A
	else
		focussed := XPGetFocussed()
	ControlGet, selection, Selected, , %focussed%, A
	return selection = ""
}
ControlBackspaceFix()
{
	if(WinVer >= WIN_7)
		ControlGetFocus focussed, A
	else
		focussed := XPGetFocussed()
	ControlGet, line, CurrentLine, , %focussed%, A
	ControlGet, col, CurrentCol, , %focussed%, A
	ControlGet, text, Line, %line%, %focussed%, A
	SpecialChars := ".,;:""`\/!§$%&/()=#'+-*~€|<>``´{[]}"
	loop ;Remove spaces and tabs first
	{
		char := Substr(text, col - 1, 1)
		if(col > 1 && (char = " " || char = "`t"))
		{
			col--
			count++
		}
		else
			break
	}
	char := Substr(text, col - 1, 1)
	if(InStr(SpecialChars, char))
		IsSpecial := true
	Loop
	{
		if(col = 1 || char = " ") ;break on line start or when a space is found
		{
			if(A_Index = 1)
				count++ ;Remove line if there were only spaces or at start
			break
		}
		if((IsSpecial && InStr(SpecialChars, char)) || (!IsSpecial && !InStr(SpecialChars, char))) ;break on next word
		{
			col--
			count++
			char := Substr(text, col - 1, 1)
		}
		else		
			break
	}
	if(count > 0)
		Send {Backspace %count%} ;Send backspace to remove the last %count% letters
	return
}
    
ControlDeleteFix()
{
	if(WinVer >= WIN_7)
		ControlGetFocus focussed, A
	else
		focussed := XPGetFocussed()
	ControlGet, line, CurrentLine, , %focussed%, A
	ControlGet, col, CurrentCol, , %focussed%, A
	ControlGet, text, Line, %line%, %focussed%, A
	SpecialChars := ".,;:""`\/!§$%&/()=#'+-*~€|<>``´{[]}"
	length := strLen(text)
	char := Substr(text, col, 1)
	if(char = "") ;Linebreak(\r\n is removed automagically), only remove if first char
		CharType := 0
	else if(char = " " || char = "`t") ;Spaces, break immediately and treat after first loop
		CharType := 1
	else if(InStr(SpecialChars, char)) ;Special characters, remove all following of this type
		CharType := 2
	else							;alphanumeric characters, remove all following of this type
		CharType := 3
	Loop
	{
		;outputdebug char %char%
		if(CharType = 0 && A_Index = 1)
		{
			count++
			line++
			col := 1
			ControlGet, text, Line, %line%, %focussed%, A
			char := Substr(text, col, 1)
			break
		}
		if(CharType = 1) ;Treat spaces later as they are always removed
			break
		/*
		if(char = "`n" || char = "`r" || char = " " || char = "`t") ;break on line end and spaces
			break
			*/
		if(char && ((CharType = 2 && InStr(SpecialChars, char))  || (CharType = 3 && char != " " && char != "`t" && !InStr(SpecialChars, char)))) ;break on next word
		{
			col++
			count++
			char := Substr(text, col, 1)
		}
		else
			break
	}   
	loop ;Remove spaces and tabs
	{
		if(char = " " || char = "`t")
		{
			col++
			count++
			char := Substr(text, col, 1)
		}
		else
			break
	}
	if(count > 0)
		Send {Delete %count%} ;Send backspace to remove the last %count% letters
	return
}

;Key remappers for Aero Flip 3D
#IfWinActive, ahk_class Flip3D 
Space::Enter 
Left::Right 
Right::Left 
Down::Up 
Up::Down 
RButton::Esc 
RWin::Esc
LWin::Esc
WheelUp::WheelDown
WheelDown::WheelUp
#if

AutoCloseWindowsUpdate(hwnd)
{
	if(Settings.Windows.AutoCloseWindowsUpdate && hwnd && WinExist("Windows Update ahk_class #32770") = hwnd)
	{
		WinActivate ahk_id %hwnd%
		Send {Up}{Down 2}{Tab 2}{Enter}
	}
}