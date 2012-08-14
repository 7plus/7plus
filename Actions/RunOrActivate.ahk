Class CRunOrActivateAction Extends CAction
{
	static Type := RegisterType(CRunOrActivateAction, "Run a program or activate it")
	static Category := RegisterCategory(CRunOrActivateAction, "System")
	static __WikiLink := "RunOrActivate"
	static _ImplementsRun := ImplementRunInterface(CRunOrActivateAction)
	
	Execute(Event)
	{
		Path := this.Command
		SplitCommandLine(Path, Args)
		Path := Event.ExpandPlaceholders(Path)
		SplitPath, Path, Name
		Process, Exist, % Name

		if(Errorlevel != 0)
		{
			Outputdebug RunOrActivate: %Name% is running with PID = %ErrorLevel%
			WinActivate ahk_pid %ErrorLevel%
		}
		else
		{
			Outputdebug RunOrActivate: %Name% is not running and will now be started
			return this.RunExecute(Event)
		}
		return 1
	}
	
	DisplayString()
	{
		return "Run or activate " this.Command
	}
	
	GuiShow(GUI)
	{
		this.AddControl(GUI, "Text", "Desc", "This action will run a program or activate it if it is already running.")
		this.RunGUIShow(GUI)
	}
	
	GuiSubmit(GUI)
	{
		Base.GuiSubmit(GUI)
		this.RunGUISubmit(GUI)
	}
}
