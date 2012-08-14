Class CWindowCreatedTrigger Extends CTrigger
{
	static Type := RegisterType(CWindowCreatedTrigger, "Window created")
	static Category := RegisterCategory(CWindowCreatedTrigger, "Window")
	static _ImplementsWindowFilter := ImplementWindowFilterInterface(CWindowCreatedTrigger)
	
	Matches(Filter)
	{
		return this.WindowFilterMatches(Filter.Window, Filter)
	}

	DisplayString()
	{
		return "Window created: " this.WindowFilterDisplayString()
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