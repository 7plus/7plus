Class CWindowStateChangeTrigger Extends CTrigger
{
	static Type := RegisterType(CWindowStateChangeTrigger, "Window state changed")
	static Category := RegisterCategory(CWindowStateChangeTrigger, "Window")
	static __WikiLink := "WindowStateChange"
	static _ImplementsWindowFilter := ImplementWindowFilterInterface(CWindowStateChangeTrigger)
	static Event := "Window minimized"
	
	Matches(Filter)
	{
		return this.Event = Filter.Event && this.WindowFilterMatches(Filter.Window, Filter)
	}

	DisplayString()
	{
		return "Window state changed: " this.WindowFilterDisplayString()
	}

	GuiShow(GUI)
	{
		this.AddControl(GUI, "DropDownList", "Event", "Window minimized|Window maximized", "", "Event:")
		this.WindowFilterGuiShow(GUI)
	}
}
