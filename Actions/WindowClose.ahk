Class CWindowCloseAction Extends CAction
{
	static Type := RegisterType(CWindowCloseAction, "Close a window")
	static Category := RegisterCategory(CWindowCloseAction, "Window")
	static __WikiLink := "WindowClose"
	static _ImplementsWindowFilter := ImplementWindowFilterInterface(CWindowCloseAction)
	static ForceClose := 0
	
	Execute()
	{
		hwnd := this.WindowFilterGet()
		if(hwnd != 0)
		{
			if(this.ForceClose)
				CloseKill(hwnd)
			else
				WinClose ahk_id %hwnd%
		}
		return 1
	}
	
	DisplayString()
	{
		return "Close Window " this.WindowFilterDisplayString()
	}
	
	GUIShow(GUI)
	{
		this.WindowFilterGUIShow(GUI)
		this.AddControl(GUI, "Checkbox", "ForceClose", "Force-close applications", "", "")
	}
	
	GUISubmit(GUI)
	{
		this.WindowFilterGUISubmit(GUI)
		Base.GuiSubmit(GUI)
	}
}
