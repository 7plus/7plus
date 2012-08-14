Class CAeroFlipAction Extends CAction
{
	static Type := RegisterType(CAeroFlipAction, "Show Aero Flip")
	static Category := RegisterCategory(CAeroFlipAction, "System")
	Execute(Event)
	{
		if(!WinActive("ahk_class Flip3D") && !WinActive("ahk_class TaskSwitcherWnd"))
		{
			if(this.tmpIsRunning) ;Closed after waiting
			{
				this.tmpIsRunning := 0
				return 1
			}
			else ;Show Aero Flip 3D
			{
				DllCall("Dwmapi.dll\DwmIsCompositionEnabled","IntP",Aero_On)
				if(Aero_On)
					Send ^#{Tab} 
				Else
					Send ^!{Tab}
				this.tmpIsRunning := 1
				return - 1
			}
		}
		else if(this.tmpIsRunning) ;Waiting for close
			return -1
		else ;Aero Flip is already triggered otherwise
			return 1
	} 
	DisplayString()
	{
		return "Show Aero Flip 3D (or task switcher if unavailable)"
	}
}