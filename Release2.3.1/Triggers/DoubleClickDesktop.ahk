Class CDoubleClickDesktopTrigger Extends CTrigger
{
	static Type := RegisterType(CDoubleClickDesktopTrigger, "Double click on desktop")
	static Category := RegisterCategory(CDoubleClickDesktopTrigger, "Hotkeys")
	
	Matches(Filter)
	{
		return true ;type is checked elsewhere
	}
}

#MaxThreadsPerHotkey 2
#if (WinVer >= WIN_Vista && IsWindowUnderCursor("WorkerW")) || (WinVer < WIN_Vista && IsWindowUnderCursor("ProgMan"))
~LButton::DoubleClickDesktop()
#if
#MaxThreadsPerHotkey 1

DoubleClickDesktop()
{
	CurrentDesktopFiles := Navigation.GetSelectedFilepaths()
	if(IsDoubleClick() && !CurrentDesktopFiles.MaxIndex())
	{
		Trigger := new CDoubleClickDesktopTrigger()
		EventSystem.OnTrigger(Trigger)
	}
	Return
}