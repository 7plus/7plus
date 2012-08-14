Class CSendKeysAction Extends CAction
{
	static Type := RegisterType(CSendKeysAction, "Send keyboard input")
	static Category := RegisterCategory(CSendKeysAction, "Input/Output")	
	static __WikiLink := "SendKeys"
	static Keys := ""
	static WriteText := False
	static KeyDelay := 0
	
	Execute(Event)
	{
		keys := Event.ExpandPlaceholders(this.Keys)
		if(this.WriteText)
		{
			Transform, Text, deref, %keys%
			PasteText(Text)
		}
		else
		{
			Backup := A_KeyDelay
			SetKeyDelay % this.KeyDelay
			SendEvent %keys%
			SetKeyDelay % Backup
		}
		return 1
	} 
	
	DisplayString()
	{
		return "Send Keys " this.Keys
	}
	
	GuiShow(GUI, GoToLabel = "")
	{
		static sGUI
		if(GoToLabel = "")
		{
			sGUI := GUI
			this.AddControl(GUI, "Text", "Desc", "This action sends keyboard input.")
			this.AddControl(GUI, "Edit", "Keys", "", "", "Keys to send:", "Placeholders", "Action_SendKeys_Placeholders", "Key names", "Action_SendKeys_KeyNames")
			this.AddControl(GUI, "Edit", "KeyDelay", "", "", "Key delay:")
			this.AddControl(GUI, "Checkbox", "WriteText", "Write text directly (useful for newlines, tabs etc.)")
		}
		else if(GoToLabel = "Placeholders")
			ShowPlaceholderMenu(sGUI, "Keys")
	}
}

Action_SendKeys_Placeholders:
GetCurrentSubEvent().GuiShow("", "Placeholders")
return

Action_SendKeys_KeyNames:
run http://www.autohotkey.com/docs/commands/Send.htm ,, UseErrorLevel
return
