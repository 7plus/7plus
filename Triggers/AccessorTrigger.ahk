Class CAccessorTrigger Extends CTrigger
{
	static Type := RegisterType(CAccessorTrigger, "Accessor Trigger")
	static Category := RegisterCategory(CAccessorTrigger, "7plus")
	static __WikiLink := "AccessorTrigger"
	static Title := "Accessor Trigger"
	static Path := ""
	static Detail1 := ""
	static Keyword := "Event"
	static ButtonText := "Execute"
	static Icon := "%SystemRoot%\system32\SHELL32.dl,2"

	Matches(Filter, Event)
	{
		return false ; Match is handled through type trigger in Accessor.ahk already
	}

	DisplayString()
	{
		return "Accessor Trigger: " this.Keyword
	}

	GuiShow(GUI, GoToLabel = "")
	{
		static sGUI
		if(GoToLabel = "")
		{
			sGUI := GUI
			this.AddControl(GUI, "Text", "Desc", "This Trigger adds a keyword to Accessor and is called when the user selects it.")
			this.AddControl(GUI, "Text", "Desc2", "This Trigger lets you use ${Acc1} - ${Acc9} placeholders in this event.")
			this.AddControl(GUI, "Edit", "Keyword", "", "", "Keyword:", "", "", "", "", "", "This event will show in Accessor when this keyword is typed by the user.")
			this.AddControl(GUI, "Edit", "ButtonText", "", "", "Button text:", "", "", "", "", "", "The text of the ""Execute"" button in Accessor window.")
			this.AddControl(GUI, "Edit", "Title", "", "", "Title:", "", "", "", "", "", "The text of the title column in Accessor window.")
			this.AddControl(GUI, "Edit", "Path", "", "", "Path:", "", "", "", "", "", "The text of the path column in Accessor window.")
			this.AddControl(GUI, "Edit", "Detail1", "", "", "Detail1:", "", "", "", "", "", "The text of the third column in Accessor window.")
			this.AddControl(GUI, "Edit", "Icon", "", "", "Icon:","Browse", "Action_AccessorTrigger_Icon")
		} 
		else if(GoToLabel = "Icon")
		{
			ControlGetText, icon, , % "ahk_id " sGUI.Edit_Icon
			StringSplit, icon, icon, `, ,%A_Space%
			if(PickIcon(icon1, icon2))
				ControlSetText, , %icon1%`, %icon2%, % "ahk_id " sGUI.Edit_Icon
		}
	}
}
Action_AccessorTrigger_Icon:
GetCurrentSubEvent().GuiShow("", "Icon")
return
