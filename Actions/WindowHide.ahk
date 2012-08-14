Class CWindowHideAction Extends CAction
{
	static Type := RegisterType(CWindowHideAction, "Hide a window")
	static Category := RegisterCategory(CWindowHideAction, "Window")
	static _ImplementsWindowFilter := ImplementWindowFilterInterface(CWindowCloseAction)

	Execute()
	{
		hwnd := this.WindowFilterGet()
		if(hwnd != 0)
			WinHide ahk_id %hwnd%
		return 1
	}
	
	DisplayString()
	{
		return "Hide Window " this.WindowFilterDisplayString()
	}
	
	GuiShow(GUI)
	{
		this.WindowFilterGuiShow(GUI)
	}
	
	GuiSubmit(GUI)
	{
		this.WindowFilterGUISubmit(GUI)
	}
}