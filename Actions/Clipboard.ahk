Class CClipboardAction Extends CAction
{
	static Type := RegisterType(CClipboardAction, "Write to clipboard")
	static Category := RegisterCategory(CClipboardAction, "System")
	static __WikiLink := "Clipboard"
	static InsertType := "Text"
	static Content := ""
	static Clear := 1
	static Cut := 0
	static Append := 0
	
	Execute(Event)
	{
		Content := Event.ExpandPlaceholders(this.Content)
		if(this.InsertType = "Text")
		{
			text := ReadClipboardText()
			Clipboard := (this.Append ? text "`r`n": "") Content
		}
		else if(this.InsertType = "File")
		{
			if(this.Append)
				AppendToClipboard(Content, this.Cut)
			else
				CopyToClipboard(Content, this.Clear, this.Cut)
		}
		else if(this.InsertType = "FileContent")
		{
			textfiles := ToArray(Content)
			SplitByExtension(textfiles, imagefiles, Settings.Misc.ImageExtensions)
			if(textfiles.MaxIndex() > 0 && FileExist(textfiles[1]))
			{
				file := textfiles[1]
				FileRead, content, %file%
				Clipboard := this.Append ? Clipboard content : content
			}
			else if(imagefiles.MaxIndex() > 0 && FileExist(imagefiles[1]))
			{
				WinClip.Clear()
				WinClip.SetBitmap(imagefiles[1])
			}
		}
		return 1
	} 

	DisplayString()
	{
		if(this.InsertType = "Text")
			return (this.Append ? "Append " : "Write ") this.Content " to clipboard"
		else if(this.InsertType = "File")
			return (this.Append ? "Append " : "Copy ") this.Content " to clipboard"
		else if(this.InsertType = "FileContent")
			return (this.Append ? "Append " : "Copy ") "content of " this.Content " to clipboard"
	}

	GuiShow(GUI, GoToLabel = "")
	{
		static sGUI
		if(GoToLabel = "")
		{
			sGUI := GUI
			this.AddControl(GUI, "Text", "Desc", "This action writes text,text from files or files(copy/move) to the clipboard.")
			this.AddControl(GUI, "DropDownList", "InsertType", "Text|File|FileContent", "", "Write:")
			this.AddControl(GUI, "Edit", "Content", "", "", "Content:", "Browse", "Action_Clipboard_Browse", "Placeholders", "Action_Clipboard_Placeholders")
			this.AddControl(GUI, "Checkbox", "Clear", "Clear Clipboard first (might be neccessary)", "", "")
			this.AddControl(GUI, "Checkbox", "Append", "Append to clipboard (not for images)", "", "")
			this.AddControl(GUI, "Checkbox", "Cut", "Cut files instead of copy (only for files)", "", "")
		}
		else if(GoToLabel = "Browse")
			this.SelectFile(sGUI, "Content")
		else if(GoToLabel = "Placeholders")
			ShowPlaceholderMenu(sGUI, "Content")
	}
}
Action_Clipboard_Browse:
GetCurrentSubEvent().GuiShow("", "Browse")
return

Action_Clipboard_Placeholders:
GetCurrentSubEvent().GuiShow("", "Placeholders")
return
