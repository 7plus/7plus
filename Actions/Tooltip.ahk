Class CTooltipAction Extends CAction
{
	static Type := RegisterType(CTooltipAction, "Show a tooltip")
	static Category := RegisterCategory(CTooltipAction, "Input/Output")	
	static TrayToolTip := false
	static Timeout := 5
	static Tooltip := "Some Tooltip"
	static Title := "Title is used for tray tooltips only."
	
	Execute(Event)
	{
		Text := Event.ExpandPlaceholders(this.Text)
		Timeout := this.Timeout * 1000
		if(this.TrayToolTip)
		{		
			Title := Event.ExpandPlaceholders(this.Title)
			Notify(Title, Text, Timeout / 1000, "GC=555555 TC=White MC=White","")
		}
		else
		{
			ToolTip, %Text%
			SetTimer, Action_ToolTip_Timeout, -%Timeout%
		}
		return 1
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
		}
		else if(GoToLabel = "Placeholders_Text")
			ShowPlaceholderMenu(sGUI, "Text")
		else if(GoToLabel = "Placeholders_Title")
			ShowPlaceholderMenu(sGUI, "Title")
	}
}

Action_ToolTip_Timeout:
Tooltip
return

Action_ToolTip_Placeholders_Text:
GetCurrentSubEvent().GuiShow("", "Placeholders_Text")
return
Action_ToolTip_Placeholders_Title:
GetCurrentSubEvent().GuiShow("", "Placeholders_Title")
return