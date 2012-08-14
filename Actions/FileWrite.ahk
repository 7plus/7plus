Class CFileWriteAction Extends CAction
{
	static Type := RegisterType(CFileWriteAction, "Write to file")
	static Category := RegisterCategory(CFileWriteAction, "File")
	static Append := false
	static Content := ""
	static Target := ""
	static Quality := 95
	static ImageExtension := "png"
	
	Execute(Event)
	{
		Target := Event.ExpandPlaceholders(this.Target)
		SplitPath, InputVar ,, OutDir, OutExtension, OutNameNoExt
		if(InStr(this.Content, "${clip}") && WriteClipboardImageToFile(OutDir "\" OutNameNoExt "." this.ImageExtension, this.Quality))
			return
		Content := Event.ExpandPlaceholders(this.Content)
		if(!this.Append)
			FileDelete, %Target%
		Content := strTrim(Content,"`r`n")
		Content := strTrim(Content,"`n")
		Content .= "`n"
		FileAppend, %Content%, %Target%
		return 1
	}

	DisplayString()
	{
		return (this.Append ? "Append " : "Write ") this.Content " to " this.Target
	}

	GuiShow(GUI, GoToLabel = "")
	{	
		static sGUI
		if(GoToLabel = "")
		{
			sGUI := GUI
			this.AddControl(GUI, "Text", "Desc", "This action writes text or images (from clipboard) to files.")
			this.AddControl(GUI, "Edit", "Content", "", "", "Content:", "Placeholders", "Action_Write_Placeholders_Content", "", "", "Use ${clip} to use the clipboard content as source.")
			this.AddControl(GUI, "Edit", "Target", "", "", "Target:", "Browse", "Action_Write_Browse", "Placeholders", "Action_Write_Placeholders_Target")
			this.AddControl(GUI, "Edit", "Quality", "", "", "Image quality:", "", "", "", "", "0-100")
			this.AddControl(GUI, "Edit", "ImageExtension", "", "", "Image extension:")
			this.AddControl(GUI, "Checkbox", "Append", "Append text to file")
		}
		else if(GoToLabel = "Placeholders_Content")
			ShowPlaceholderMenu(sGUI, "Content")
		else if(GoToLabel = "Placeholders_Target")
			ShowPlaceholderMenu(sGUI, "Target")
		else if(GoToLabel = "Browse")
			this.SelectFile(sGUI, "Target", "Select File", "", 0, "S2")
	}
}

Action_Write_Placeholders_Content:
GetCurrentSubEvent().GuiShow("", "Placeholders_Content")
return
Action_Write_Placeholders_Target:
GetCurrentSubEvent().GuiShow("", "Placeholders_Target")
return
Action_Write_Browse:
GetCurrentSubEvent().GuiShow("", "Browse")
return