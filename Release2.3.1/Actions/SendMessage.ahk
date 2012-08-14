Class CSendMessageAction Extends CAction
{
	static Type := RegisterType(CSendMessageAction, "Send a window message")
	static Category := RegisterCategory(CSendMessageAction, "System")
	static _ImplementsWindowFilter := ImplementWindowFilterInterface(CSendMessageAction)
	
	static TargetControl := "Edit1"
	static Message := ""
	static wParam := ""
	static lParam := ""
	static MessageMode := "Post"
	
	Execute(Event)
	{
		hwnd := this.WindowFilterGet()
		TargetControl := Event.ExpandPlaceholders(this.TargetControl)
		Message := Event.ExpandPlaceholders(this.Message)
		wParam := Event.ExpandPlaceholders(this.wParam)
		lParam := Event.ExpandPlaceholders(this.lParam)
		
		if(IsNumeric(TargetControl))
		{
			hwnd := TargetControl
			TargetControl := ""
		}
		if(this.MessageMode = "Post")
			PostMessage, Message, wParam, lParam, %TargetControl%, ahk_id %hwnd%
		else
		{
			SendMessage, Message, wParam, lParam, %TargetControl%, ahk_id %hwnd%
			Event.Placeholders.MessageResult := ErrorLevel
		}
		return 1
	}
	DisplayString()
	{
		return this.MessageMode "Message to " this.TargetControl ", " this.WindowFilterDisplayString()
	}
	GuiShow(GUI, GoToLabel = "")
	{
		static sGUI
		if(GoToLabel = "")
		{
			sGUI := GUI
			this.AddControl(GUI, "Text", "Desc", "This action sends a window message to another window/program. This allows to trigger actions in other programs (such as winamp).")		
			this.AddControl(GUI, "DropDownList", "MessageMode", "Post|Send", "", "Message mode:")
			this.AddControl(GUI, "Text", "tmpText", "Send waits for a response and allows ${MessageResult} to be used.")
			this.AddControl(GUI, "Edit", "Message", "", "", "Message:", "Placeholders", "Action_SendMessage_Placeholders_Message")
			this.AddControl(GUI, "Edit", "wParam", "", "", "wParam:", "Placeholders", "Action_SendMessage_Placeholders_wParam")
			this.AddControl(GUI, "Edit", "lParam", "", "", "lParam:", "Placeholders", "Action_SendMessage_Placeholders_lParam")
			this.WindowFilterGuiShow(GUI)
			this.AddControl(GUI, "Edit", "TargetControl", "", "", "Target Control:")
		}
		else if(GoToLabel = "Placeholders_Message")
			ShowPlaceholderMenu(sGUI, "Message")
		else if(GoToLabel = "Placeholders_wParam")
			ShowPlaceholderMenu(sGUI, "wParam")
		else if(GoToLabel = "Placeholders_lParam")
			ShowPlaceholderMenu(sGUI, "lParam")
	}
	
	GuiSubmit(GUI)
	{
		this.WindowFilterGUISubmit(GUI)
		Base.GUISubmit(GUI)
	}
}
Action_SendMessage_Placeholders_Message:
GetCurrentSubEvent().GuiShow("", "Placeholders_Message")
return
Action_SendMessage_Placeholders_wParam:
GetCurrentSubEvent().GuiShow("", "Placeholders_wParam")
return
Action_SendMessage_Placeholders_lParam:
GetCurrentSubEvent().GuiShow("", "Placeholders_lParam")
return