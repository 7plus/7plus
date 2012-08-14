Class CWindowExistsCondition Extends CCondition
{
	static Type := RegisterType(CWindowExistsCondition, "Window exists")
	static Category := RegisterCategory(CWindowExistsCondition, "WIndow")
	static _ImplementsWindowFilter := ImplementWindowFilterInterface(CWindowExistsCondition)
	
	Evaluate()
	{
		if(this.WindowMatchType = "Program")
		{
			filter := this.Filter
			Process, Exist, %Filter%
			if(Errorlevel)
				return WinExist("ahk_pid " Errorlevel) != 0
			else
				return false
		}
		else if(this.WindowMatchType = "Class")
			return WinExist("ahk_class " this.Filter) != 0
		else if(this.WindowMatchType = "Title")
			return WinExist(this.Filter) != 0
		else if(this.WindowMatchType = "Active") ;Active window always exists
			return true
		else if(this.WindowMatchType = "UnderMouse") ;Window under mouse always exists
			return true
		return this.WindowFilterMatches("A")
	}
	
	DisplayString()
	{
		return "Window exists: " this.WindowFilterDisplayString()
	}

	GuiShow(GUI)
	{
		this.WindowFilterGuiShow(GUI)
	}
	GuiSubmit(GUI)
	{
		this.WindowFilterGuiSubmit(GUI)
		Base.GuiSubmit(GUI)
	}
}