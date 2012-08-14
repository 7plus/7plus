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
			GoSub SettingsHandler ;ShowSettings shouldn't be called here directly because Settingshandler performs an additional check for FirstRun
		return 1
	}
	DisplayString()
	{
		return "Show 7plus Settings"
	}
}
