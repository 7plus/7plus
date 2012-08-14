Class CSelectFilesAction Extends CAction
{
	static Type := RegisterType(CSelectFilesAction, "Select files")
	static Category := RegisterCategory(CSelectFilesAction, "Explorer")
	static __WikiLink := "SelectFiles"
	static _ImplementsWindowFilter := ImplementWindowFilterInterface(CSelectFilesAction)
	static Filter := "*.exe;*.jpg"
	static Wildcard := true
	static WindowMatchType := "Active"
	
	Execute(Event)
	{
		hwnd := this.WindowFilterGet()
		Filter := Event.ExpandPlaceholders(this.Filter)
		Separator := ";"
		Filter := ToArray(Filter, Separator)
		if(this.Wildcard)
			Loop % Filter.MaxIndex()
				Filter[A_Index] := "*" Filter[A_Index] "*"
		Navigation.SelectFiles(Filter, hwnd)
		return 1
	} 

	DisplayString()
	{
		return "Select files: " this.Filter
	}
	
	GuiShow(GUI, GoToLabel = "")
	{
		static sGUI
		if(GoToLabel = "")
		{
			sGUI := GUI
			this.AddControls(GUI, "Text", "Desc", "This action selects files in an active explorer window.")
			this.AddControls(GUI, "Edit", "Filter", "", "", "Filter:", "Placeholders", "Action_SelectFiles_Placeholders_Filter")
			this.AddControls(GUI, "Checkbox", "Wildcard", "Automatically add wildcards to start and end")
			this.WindowFilterGuiShow(GUI)
		}
		else if(GoToLabel = "Placeholders_Filter")
			ShowPlaceholderMenu(sGUI, "Filter")
	}
	
	GuiSubmit(GUI)
	{
		this.WindowFilterGUISubmit(GUI)
		Base.GUISubmit(GUI)
	}
}
Action_SelectFiles_Placeholders_Filter:
GetCurrentSubEvent().GuiShow("", "Placeholders_Filter")
return
