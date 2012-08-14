Class CRunAction Extends CAction
{
	static Type := RegisterType(CRunAction, "Run a program")
	static Category := RegisterCategory(CRunAction, "System")
	static _ImplementsRun := ImplementRunInterface(CRunAction)
	
	Execute(Event)
	{
		return this.RunExecute(Event)
	}
	
	DisplayString()
	{
		return this.RunDisplayString()
	}
	
	GUIShow(GUI)
	{
		this.RunGUIShow(GUI)
	}
	
	GUISubmit(GUI)
	{
		Base.GUISubmit(GUI)
		this.RunGUISubmit(GUI)
	}
}