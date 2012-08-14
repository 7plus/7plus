Class CWindowSendToBottomAction Extends CAction
{
	static Type := RegisterType(CWindowSendToBottomAction, "Put window in background")
	static Category := RegisterCategory(CWindowSendToBottomAction, "Window")
	static _ImplementsWindowFilter := ImplementWindowFilterInterface(CWindowSendToBottomAction)
	
	Execute()
	{
		global PreviousWindow
		hwnd := this.WindowFilterGet()
		if(hwnd != 0)
		{
			WinGetClass, class, ahk_id %hwnd%
			if(class != "Shell_TrayWnd" && class != "WorkerW" && class != "Progman")
			{
				WinSet, Bottom,, ahk_id %hwnd%
				WinActivate ahk_id %PreviousWindow% ;Activate previous window so the window doesn't stay active
			}
		}
		return 1
	}
	DisplayString()
	{
		return "Put window in background: " this.WindowFilterDisplayString()
	}
	GuiShow(GUI)
	{
		this.WindowFilterGUIShow(GUI)
	}
	GuiSubmit(GUI)
	{
		this.WindowFilterGUISubmit(GUI)
	}
}