Class CWindowActivatedTrigger Extends CTrigger
{
	static Type := RegisterType(CWindowActivatedTrigger, "Window activated")
	static Category := RegisterCategory(CWindowActivatedTrigger, "Window")
	static __WikiLink := "WindowActivated"
	static _ImplementsWindowFilter := ImplementWindowFilterInterface(CWindowActivatedTrigger)
	
	Matches(Filter)
	{
		return this.WindowFilterMatches("A", Filter)
	}

	DisplayString()
	{
		return "Window activated: " this.WindowFilterDisplayString()
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
