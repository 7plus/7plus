Class CWindowMoveAction Extends CAction
{
	static Type := RegisterType(CWindowMoveAction, "Move a window")
	static Category := RegisterCategory(CWindowMoveAction, "Window")
	static __WikiLink := "WindowMove"
	static _ImplementsWindowFilter := ImplementWindowFilterInterface(CWindowMoveAction)
	static CenterX := 0
	static CenterY := 0
	static X := 0
	static Y := 0
	
	Execute(Event)
	{
		hwnd := this.WindowFilteGet()
		WinGetPos, curX, curY, curW, curH, ahk_id %hwnd%
		X := Event.ExpandPlaceholders(this.X)
		Y := Event.ExpandPlaceholders(this.Y)
		XValue := strTrimLeft(strTrimLeft(strTrimRight(X,"%"),"-"),"+")
		YValue := strTrimLeft(strTrimLeft(strTrimRight(Y,"%"),"-"),"+")
		if(strEndsWith(X,"%"))
			XValue *= A_ScreenWidth/100
		if(strEndsWith(Y,"%"))
			YValue *= A_ScreenHeight/100
		if(InStr(X,"+") = 1)
			XValue += curX
		if(InStr(Y,"+") = 1)
			YValue += curY
		if(InStr(X,"-") = 1)
			XValue -= curX
		if(InStr(Y,"-") = 1)
			YValue -= curY
		if(this.CenterX)
			XValue -= curW / 2
		if(this.CenterY)
			YValue -= curH / 2
		WinMove,ahk_id %hwnd%,,%XValue%,%YValue%
		return 1
	}
	DisplayString()
	{
		return "Move Window " this.WindowFilterDisplayString() " to " this.X "/" this.Y
	}
	GuiShow(GUI, GoToLabel = "")
	{
		static sGUI
		if(GoToLabel = "")
		{
			sGUI := GUI
			this.WindowFilterGuiShow(GUI)
			this.AddControl(GUI, "Text", "tmpText", "Formats: ""100"", ""+100"", ""10%"", ""-10%""")
			this.AddControl(GUI, "Edit", "X", "", "", "X:", "Placeholders", "Action_WindowMove_Placeholders_X")
			this.AddControl(GUI, "Edit", "Y", "", "", "Y:", "Placeholders", "Action_WindowMove_Placeholders_Y")
			this.AddControl(GUI, "Checkbox", "CenterX", "Use X center of window")
			this.AddControl(GUI, "Checkbox", "CenterY", "Use Y center of window")
		}
		else if(GoToLabel = "Placeholders_X")
			ShowPlaceholderMenu(sGUI, "X")
		else if(GoToLabel = "Placeholders_Y")
			ShowPlaceholderMenu(sGUI, "Y")
	}
	GuiSubmit(GUI)
	{
		this.WindowFilterGuiSubmit(GUI)
		Base.GUISubmit(GUI)
	}
}
Action_WindowMove_Placeholders_X:
GetCurrentSubEvent().GuiShow("", "Placeholders_X")
return
Placeholders_Y:
GetCurrentSubEvent().GuiShow("", "Placeholders_Y")
return
