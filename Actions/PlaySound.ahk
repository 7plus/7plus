Class CPlaySoundAction Extends CAction
{
	static Type := RegisterType(CPlaySoundAction, "Play a sound")
	static Category := RegisterCategory(CPlaySoundAction, "Input/Output")
	static File := "*-1"
	
	DisplayString()
	{
		return "Play " this.File
	}
	
	Execute(Event)
	{
		file := Event.ExpandPlaceholders(this.File)
		SoundPlay, % file
		return 1
	}
	
	GuiShow(GUI, GoToLabel = "")
	{	
		static sGUI
		if(GoToLabel = "")
		{
			sGUI := GUI
			this.AddControl(GUI, "Edit", "File", "", "", "Sound file:", "Browse", "Action_PlaySound_Browse", "Placeholders", "Action_PlaySound_Placeholders_File")
			this.AddControl(GUI, "Button", "", "System Sounds", "Action_PlaySound_Help")
		}
		else if(GoToLabel = "Placeholders_File")
			ShowPlaceholderMenu(sGUI, "File")	
		else if(GoToLabel = "Browse")
			this.SelectFile(sGUI, "File")
		else if(GoToLabel = "Help")
			run, http://www.autohotkey.net/docs/commands/SoundPlay.htm,,UseErrorLevel
	}
}
Action_PlaySound_Placeholders_File:
GetCurrentSubEvent().GuiShow("", "Placeholders_File")
return
Action_PlaySound_Browse:
GetCurrentSubEvent().GuiShow("", "Browse")
return
Action_PlaySound_Help:
GetCurrentSubEvent().GuiShow("", "Help")
return