Class CWindowResizeAction Extends CAction
{
	static Type := RegisterType(CWindowResizeAction, "Resize a window")
	static Category := RegisterCategory(CWindowResizeAction, "Window")
	static __WikiLink := "WindowResize"
	static _ImplementsWindowFilter := ImplementWindowFilterInterface(CWindowResizeAction)
	static CenterX := 0
	static CenterY := 0
	static Width := "100%"
	static Height := "100%"
	
	Execute(Event)
	{
		hwnd := this.WindowFilterGet()
		WinGetPos, curX, curY, curW, curH, ahk_id %hwnd%
		
		Width := Event.ExpandPlaceholders(this.Width)
		Height := Event.ExpandPlaceholders(this.Height)
		
		WidthValue := strTrimLeft(strTrimLeft(strTrimLeft(strTrimLeft(strTrimRight(Width,"%"),"*"),"/"),"-"),"+")
		HeightValue := strTrimLeft(strTrimLeft(strTrimLeft(strTrimLeft(strTrimRight(Height,"%"),"*"),"/"),"-"),"+")
		
		if(strEndsWith(Width,"%"))
			WidthValue *= A_ScreenWidth/100
		if(strEndsWith(Height,"%"))
			HeightValue *= A_ScreenHeight/100
			
		if(InStr(Width,"+") = 1)
			WidthValue += curW
		if(InStr(Height,"+") = 1)
			HeightValue += curH
			
		if(InStr(Width,"-") = 1)
			WidthValue -= curW
		if(InStr(Height,"-") = 1)
			HeightValue -= curH
			
		if(InStr(Width,"*") = 1)
			WidthValue *= curW
		if(InStr(Height,"*") = 1)
			HeightValue *= curH
			
		if(InStr(Width,"/") = 1)
			WidthValue /= curW
		if(InStr(Height,"/") = 1)
			HeightValue /= curH
			
		if(this.CenterX)
			curX -= (WidthValue - curW) / 2
		if(this.CenterY)
			curY -= (HeightValue - curH) / 2
			
		WinMove,ahk_id %hwnd%,,%curX%,%curY%,%WidthValue%,%HeightValue%
		return 1
	}
	
	DisplayString()
	{
		return "Resize Window " this.WindowFilterDisplayString() " to " this.Width "/" this.Height
	}
	
	GUIShow(GUI, GoToLabel = "")
	{
		static sGUI
		if(GoToLabel = "")
		{
			sGUI := GUI
			this.WindowFilterGuiShow(GUI)
			this.AddControl(GUI, "Text", "tmpText", "Formats: ""100"", ""100%"", ""10%"", ""*2""")
			this.AddControl(GUI, "Edit", "Width", "", "", "Width:", "Placeholders", "Action_WindowResize_Placeholders_X")
			this.AddControl(GUI, "Edit", "Height", "", "", "Height:", "Placeholders", "Action_WindowResize_Placeholders_Y")
			this.AddControl(GUI, "Checkbox", "CenterX", "Use X center of window")
			this.AddControl(GUI, "Checkbox", "CenterY", "Use Y center of window")
		}
		else if(GoToLabel = "Placeholders_X")
			ShowPlaceholderMenu(sGUI, "X")
		else if(GoToLabel = "Placeholders_Y")
			ShowPlaceholderMenu(sGUI, "Y")
	}

	GUISubmit(GUI)
	{
		this.WindowFilterGUISubmit(GUI)
		Base.GUISubmit(GUI)
	}
}
Action_WindowResize_Placeholders_X:
GetCurrentSubEvent().GuiShow("", "Placeholders_X")
return
Action_WindowResize_Placeholders_Y:
GetCurrentSubEvent().GuiShow("", "Placeholders_Y")
return
