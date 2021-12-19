Class CShowSettingsAction Extends CAction
{
	static Type := RegisterType(CShowSettingsAction, "Show settings")
	static Category := RegisterCategory(CShowSettingsAction, "7plus")
	static __WikiLink := "ShowSettings"
	Execute(Event)
	{
		DetectHiddenWindows, Off
		if(WinExist("7plus Settings"))
			WinActivate 7plus Settings
		else
			ShowSettings()
		return 1
	}
	DisplayString()
	{
		return "Show 7plus Settings"
	}
}
