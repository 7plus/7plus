Class CVoiceAction Extends CAction
{
	static Type := RegisterType(CVoiceAction, "Speak text")
	static Category := RegisterCategory(CVoiceAction, "Input/Output")
	static __WikiLink := "Voice"
	static Text := ""
	Execute(Event)
	{
		Text := Event.ExpandPlaceholders(this.Text)
		ComObjCreate("SAPI.SpVoice").Speak(Text)
	} 
	DisplayString()
	{
		return "Speak text:" this.Text
	}
	GuiShow(GUI, GoToLabel = "")
	{	
		static sGUI
		if(GoToLabel = "")
		{
			sGUI := GUI
			this.AddControl(GUI, "Edit", "Text", "", "", "Text:", "Placeholders", "Action_Voice_Placeholders_Text")
		}
		else if(GoToLabel = "Placeholders_Text")
			ShowPlaceholderMenu(sGUI, "Text")	
	}
}
Action_Voice_Placeholders_Text:
GetCurrentSubEvent().GuiShow("", "Placeholders_Text")
return