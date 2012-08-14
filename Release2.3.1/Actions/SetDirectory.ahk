Class CSetDirectoryAction Extends CAction
{
	static Type := RegisterType(CSetDirectoryAction, "Set current directory")
	static Category := RegisterCategory(CSetDirectoryAction, "Explorer")
	static _ImplementsWindowFilter := ImplementWindowFilterInterface(CSetDirectoryAction)
	static WindowMatchType := "Active"
	static Path := ""
	
	Execute(Event)
	{
		hwnd := this.WindowFilterGet()
		path := Event.ExpandPlaceholders(this.Path)
		StringReplace, path, path, ",,All
		if(Path = "Back")
			Navigation.GoBack(hwnd)
		else if(Path = "Forward")
			Navigation.GoForward(hwnd)
		else if(Path = "Upward")
			Navigation.GoUpward(hwnd)
		else
			Navigation.SetPath(Path,hwnd)
		return 1
	}

	DisplayString()
	{
		return "Set Explorer directory to: " this.Path
	}
	
	GuiShow(GUI, GoToLabel = "")
	{
		static sGUI
		if(GoToLabel = "")
		{
			sGUI := GUI
			this.AddControl(GUI, "Text", "Desc", "This action sets the explorer directory and navigates forward/backward/up.")
			this.AddControl(GUI, "Edit", "Path", "", "", "Path:","Browse", "Action_SetDirectory_Browse", "Placeholders", "Action_SetDirectory_Placeholders","You may also enter ""Back"",""Forward"" and ""Upward"" here.")
			this.WindowFilterGuiShow(GUI)
		}
		else if(GoToLabel = "Browse")
			this.Browse(sGUI, "Path")
		else if(GoToLabel = "Placeholders")
			ShowPlaceholderMenu(sGUI, "Path")
	}
	
	GuiSubmit(GUI)
	{
		outputdebug submit directory
		this.WindowFilterGUISubmit(GUI)
		Base.GUISubmit(GUI)
	}
}
Action_SetDirectory_Browse:
GetCurrentSubEvent().GuiShow("", "Browse")
return
Action_SetDirectory_Placeholders:
GetCurrentSubEvent().GuiShow("", "Placeholders")
return
