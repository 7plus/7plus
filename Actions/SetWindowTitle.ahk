Class CSetWindowTitleAction Extends CAction
{
	static Type := RegisterType(CSetWindowTitleAction, "Set window title")
	static Category := RegisterCategory(CSetWindowTitleAction, "Window")
	static __WikiLink := "SetWindowTitle"
	static _ImplementsWindowFilter := ImplementWindowFilterInterface(CSetWindowTitleAction)
	static Title := "7plus rocks!"
	
	Execute(Event)
	{
		hwnd := this.WindowFilterGet()
		Title := Event.ExpandPlaceholders(this.Title)
		SendMessage, 0xC, 0, "" Title "", , ahk_id %hwnd%
		return 1
	}
	
	DisplayString()
	{
		return "Set window title of " this.WindowFilterDisplayString() " to " this.Title
	}
	
	GuiShow(GUI, GoToLabel = "")
	{
		static sGUI
		if(GoToLabel = "")
		{
			sGUI := GUI
			this.WindowFilterGuiShow(GUI)
			this.AddControl(GUI, "Edit", "Title", "", "", "Title:", "Placeholders", "Action_SetWindowTitle_Placeholders_Title")
		}
		else if(GoToLabel = "Placeholders_Title")
			ShowPlaceholderMenu(sGUI, "Title")
	}

	GuiSubmit(GUI)
	{
		this.WindowFilterGUISubmit(GUI)
		Base.GUISubmit(GUI)
	}
}
Action_SetWindowTitle_Placeholders_Title:
GetCurrentSubEvent().GuiShow("", "Placeholders_Title")
return
