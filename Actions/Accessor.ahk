Class CAccessorAction Extends CAction
{
	static Type := RegisterType(CAccessorAction, "Show Accessor")
	static Category := RegisterCategory(CAccessorAction, "Window")
	static __WikiLink := "Accessor"
	static InitialQuery := ""
	__New()
	{
	}
	Execute(Event)
	{
		result := CAccessor.Instance.Show(this, Event.ExpandPlaceholders(this.InitialQuery))
		return result
	}

	DisplayString()
	{
		return "Show accessor"
	}

	GuiShow(ActionGUI, GoToLabel = "")
	{
		static sActionGUI
		if(!GoToLabel)
		{
			sActionGUI := ActionGUI
			this.AddControl(ActionGUI, "Edit", "InitialQuery", "", "", "Initial Query:", "Placeholders", "Action_InitialQuery_Placeholders", "", "", "The text of the query text field when Accessor is opened")
		}
		else if(GoToLabel = "InitialQuery_Placeholders")
			ShowPlaceholderMenu(sActionGUI, "InitialQuery")
	}
}

Action_InitialQuery_Placeholders:
GetCurrentSubEvent().GuiShow("", "InitialQuery_Placeholders")
return
