Class CScreenCornerTrigger Extends CTrigger
{
	static Type := RegisterType(CScreenCornerTrigger, "Screen corner")
	static Category := RegisterCategory(CScreenCornerTrigger, "System")
	static __WikiLink := "ScreenCorner"
	static Corner := 1
	static Time := 1000
	Matches(Filter)
	{
		return this.Corner = Filter.Corner ;type is checked elsewhere
	}
	DisplayString()
	{
		return "Hovering over screen corner"
	}
	GuiShow(GUI)
	{
		this.AddControl(GUI, "Text", "Desc", "This trigger is executed when the mouse hovers over a screen corner for a specified time.")
		this.AddControl(GUI, "DropDownList", "Corner", "1: Upper Left|2: Upper Right|3: Lower Right|4: Lower Left", "", "Corner:")	
		this.AddControl(GUI, "Edit", "Time", "", "", "Time[ms]:")
	}
}
