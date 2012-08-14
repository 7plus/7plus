Class CMouseClickAction Extends CAction
{
	static Type := RegisterType(CMouseClickAction, "Mouse click")
	static Category := RegisterCategory(CMouseClickAction, "Input/Output")
	static __WikiLink := "MouseClick"
	static RestorePosition := true
	static Relative := true
	static Button := "Left"
	static Double := true
	static X := 0
	static Y := 0
	Execute(Event)
	{
		CoordMode, Mouse, Screen
		MouseGetPos, mx,my
		X := Event.ExpandPlaceholders(this.X)
		Y := Event.ExpandPlaceholders(this.Y)
		if(this.Relative)
			CoordMode, Mouse, Relative
		Button := this.Button	
		Double := this.Double ? 2 : 1
		Click %Button% %X%, %Y% %Double%
		CoordMode, Mouse, Screen
		if(this.RestorePosition)
			MouseMove, %mx%, %my%
		return 1
	} 

	DisplayString()
	{
		return "Click " this.Button " at " this.X "/" this.Y (this.Relative ? " relative to current window" : "")
	} 
	GuiShow(GUI, GoToLabel = "")
	{
		static sGUI	
		if(GoToLabel = "")
		{
			sGUI := GUI
			this.AddControl(GUI, "DropDownList", "Button", "Left||Middle|Right", "", "Button:")
			this.AddControl(GUI, "Edit", "X", "", "", "X:", "Placeholders", "Action_MouseClick_Placeholders_X","","","Leave empty to click at current cursor position.")
			this.AddControl(GUI, "Edit", "Y", "", "", "Y:", "Placeholders", "Action_MouseClick_Placeholders_Y","","","Leave empty to click at current cursor position.")
			this.AddControl(GUI, "Checkbox", "Relative", "Position relative to active window")
			this.AddControl(GUI, "Checkbox", "RestorePosition", "Restore previous mouse position")
			this.AddControl(GUI, "Checkbox", "Double", "Double click")
		}
		else if(GoToLabel = "Placeholders_X")
			ShowPlaceholderMenu(sGUI, "X")
		else if(GoToLabel = "Placeholders_Y")
			ShowPlaceholderMenu(sGUI, "Y")
	}
}
Action_MouseClick_Placeholders_X:
GetCurrentSubEvent().GuiShow("", "Placeholders_X")
return
Action_MouseClick_Placeholders_Y:
GetCurrentSubEvent().GuiShow("", "Placeholders_Y")
return
