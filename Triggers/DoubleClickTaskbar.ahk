Class CDoubleClickTaskbarTrigger Extends CTrigger
{
	static Type := RegisterType(CDoubleClickTaskbarTrigger, "Double click on taskbar")
	static Category := RegisterCategory(CDoubleClickTaskbarTrigger, "Hotkeys")
	static __WikiLink := "DoubleClickTaskbar"
	Matches(Filter)
	{
		return true ;type is checked elsewhere
	}
	DisplayString()
	{
		return "Double click on empty taskbar area"
	}
}

;Can't add the double click condition here, because IsDoubleClick seems to fail when called in the #if condition
;mouse click on the taskbar is simulated instead.
#if IsMouseOverTaskList()
LButton::DoubleClickTaskbar()
#if

DoubleClickTaskbar()
{
	if(IsDoubleClick() && IsMouseOverFreeTaskListSpace())
	{
		Trigger := new CDoubleClickTaskbarTrigger()
		EventSystem.OnTrigger(Trigger)
	}
	else
	{
		Click Left Down
		while(GetKeyState("LButton", "P"))
			Sleep 10
		Click Left Up
	}
	return
}
