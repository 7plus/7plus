Class CWindowActivateAction Extends CAction
{
	static Type := RegisterType(CWindowActivateAction, "Activate a window")
	static Category := RegisterCategory(CWindowActivateAction, "Window")
	static _ImplementsWindowFilter := ImplementWindowFilterInterface(CWindowActivateAction)

	Execute()
	{
		hwnd := this.WindowFilterGet()
		if(hwnd != 0)
			WinActivate ahk_id %hwnd%
		return 1
	}
	DisplayString()
	{
		return "Activate Window " this.WindowFilterDisplayString()
	}
	GUIShow(GUI)
	{
		this.WindowFilterGUIShow(GUI)
	}
	GUISubmit(GUI)
	{
		this.WindowFilterGUISubmit(GUI)
		Base.GUISubmit(GUI)
	}
}