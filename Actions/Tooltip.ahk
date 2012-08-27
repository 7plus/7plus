Class CTooltipAction Extends CAction
{
	static Type := RegisterType(CTooltipAction, "Show a tooltip")
	static Category := RegisterCategory(CTooltipAction, "Input/Output")	
	static __WikiLink := "ToolTip"
	static TrayToolTip := false
	static Timeout := 5
	static Text := "Some Tooltip"
	static Title := "Title is used for tray tooltips only."
	static Icon := ""
	static EventOnClickID := "%SystemRoot%\system32\SHELL32.dl,2"
	
	Execute(Event)
	{
		Text := Event.ExpandPlaceholders(this.Text)
		Timeout := this.Timeout * 1000
		if(this.TrayToolTip)
		{		
			Title := Event.ExpandPlaceholders(this.Title)
			this.tmpPlaceholders := Event.Placeholders
			Notify(Title, Text, Timeout / 1000, Event.ExpandPlaceholders(this.Icon), new Delegate(this, "TipClicked"))
		}
		else
		{
			ToolTip, %Text%
			SetTimer, Action_ToolTip_Timeout, -%Timeout%
		}
		return 1
	}
	
	TipClicked(URLorID = "")
	{
		outputdebug tip clicked
		if(IsNumeric(URLorID))
		{
			Event := EventSystem.Events.GetEventWithValue("ID", URLorID)
			outputdebug % URLorID Event.Name IsObject(this.tmpPlaceholders)
			if(Event)
				Event.TriggerThisEvent("", this.tmpPlaceholders)
		}
		else if(URLorID = "" && this.EventOnClickID)
		{
			Event := EventSystem.Events.GetEventWithValue("ID", this.EventOnClickID)
			if(Event)
				Event.TriggerThisEvent("", this.tmpPlaceholders)
		}
	}

	DisplayString()
	{
		return "Show tooltip: " this.Text
	}

	GuiShow(GUI, GoToLabel = "")
	{
		static sGUI
		if(GoToLabel = "")
		{
			sGUI := GUI
			this.AddControl(GUI, "Edit", "Text", "", "", "Text:", "Placeholders", "Action_ToolTip_Placeholders_Text")
			this.AddControl(GUI, "Edit", "Timeout", "", "", "Timeout [s]:")
			this.AddControl(GUI, "Checkbox", "TrayToolTip", "Use notification window instead")
			this.AddControl(GUI, "Edit", "Title", "", "", "Title:", "Placeholders", "Action_ToolTip_Placeholders_Title")
			this.AddControl(GUI, "ComboBox", "EventOnClickID", "TriggerType:", "", "Trigger on click:")
			this.AddControl(GUI, "Edit", "Icon", "", "", "Icon:","Browse", "Action_Tooltip_Icon")
		}
		else if(GoToLabel = "Placeholders_Text")
			ShowPlaceholderMenu(sGUI, "Text")
		else if(GoToLabel = "Placeholders_Title")
			ShowPlaceholderMenu(sGUI, "Title")
		else if(GoToLabel = "Icon")
		{
			ControlGetText, icon, , % "ahk_id " sGUI.Edit_Icon
			StringSplit, icon, icon, `, ,%A_Space%
			if(PickIcon(icon1, icon2))
				ControlSetText, , %icon1%`, %icon2%, % "ahk_id " sGUI.Edit_Icon
		}
	}
}

Action_ToolTip_Timeout:
Tooltip
return

Action_ToolTip_Icon:
GetCurrentSubEvent().GuiShow("", "Icon")
return
Action_ToolTip_Placeholders_Text:
GetCurrentSubEvent().GuiShow("", "Placeholders_Text")
return
Action_ToolTip_Placeholders_Title:
GetCurrentSubEvent().GuiShow("", "Placeholders_Title")
return
