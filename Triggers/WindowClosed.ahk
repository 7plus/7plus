Class CWindowClosedTrigger Extends CTrigger
{
	static Type := RegisterType(CWindowClosedTrigger, "Window closed")
	static Category := RegisterCategory(CWindowClosedTrigger, "Window")
	static __WikiLink := "WindowClosed"
	static _ImplementsWindowFilter := ImplementWindowFilterInterface(CWindowClosedTrigger)
	
	Matches(Filter)
	{
		return this.WindowFilterMatches(Filter.Window, Filter)
	}

	DisplayString()
	{
		return "Window closed: " this.WindowFilterDisplayString()
	}

	GuiShow(GUI)
	{
		this.WindowFilterGuiShow(GUI)
	}

	GuiSubmit(GUI)
	{
		this.WindowFilterGuiSubmit(GUI)
	}
}
