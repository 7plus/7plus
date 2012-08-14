Class CWindowActiveCondition Extends CCondition
{
	static Type := RegisterType(CWindowActiveCondition, "Window active")
	static Category := RegisterCategory(CWindowActiveCondition, "WIndow")
	static __WikiLink := "WindowActive"
	static _ImplementsWindowFilter := ImplementWindowFilterInterface(CWindowActiveCondition)
	
	Evaluate()
	{
		return this.WindowFilterMatches("A")
	}
	
	DisplayString()
	{
		return "Window Active: " this.WindowFilterDisplayString()
	}

	GuiShow(GUI)
	{
		this.WindowFilterGuiShow(GUI)
	}
	GuiSubmit(GUI)
	{
		this.WindowFilterGUISubmit(GUI)
		Base.GuiSubmit(GUI)
	}
}
