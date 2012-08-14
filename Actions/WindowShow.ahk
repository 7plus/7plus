Class CWindowShowAction Extends CAction
{
	static Type := RegisterType(CWindowShowAction, "Show a window")
	static Category := RegisterCategory(CWindowShowAction, "Window")
	static __WikiLink := "WindowShow"
	static _ImplementsWindowFilter := ImplementWindowFilterInterface(CWindowShowAction)
	
	Execute()
	{
		hwnd := this.WindowFilterGet()
		if(hwnd != 0)
			WinShow ahk_id %hwnd%
		return 1
	}
	
	DisplayString()
	{
		return "Show Window " this.WindowFilterDisplayString()
	}
	
	GUIShow(GUI)
	{
		this.WindowFilterGUIShow(GUI)
	}
	
	GUISubmit(GUI)
	{
		this.WindowFilterGUISubmit(GUI)
	}
}
