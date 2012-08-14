Class CNewFileAction Extends CAction
{
	static Type := RegisterType(CNewFileAction, "Create new file")
	static Category := RegisterCategory(CNewFileAction, "Explorer")
	static __WikiLink := "NewFile"
	;WinVer variable isn't set yet here
	static Filename := GetWindowsVersion() >= 6.0 ? TranslateMUI("notepad.exe",470) ".txt" : TranslateMUI("shell32.dll",8587) " " TranslateMUI("notepad.exe",469) ".txt" ;"New Textfile" ".txt"    versus   "New" "Textfile" ".txt"
	static BaseFile := ""
	static Rename := true

	Execute(Event)
	{
		if(!(WinActive("ahk_group ExplorerGroup") || WinActive("ahk_group DesktopGroup") || IsDialog()))
		{
			Notify(this.Type " Error!", "This action requires explorer to be active!", 5, NotifyIcons.Error)
			return 0
		}
		if(IsRenaming())
			return 0
		
		;This is done manually, by creating a text file desired name, which is then focussed
		SetFocusToFileView()
		path := Navigation.GetPath()
		name := Event.ExpandPlaceholders(this.Filename)
		Testpath := FindFreeFileName(path "\" name)
		BaseFile := Event.ExpandPlaceholders(this.BaseFile)
		if(BaseFile && FileExist(BaseFile))
			FileCopy, %BaseFile%, %TestPath%
		else
			FileAppend, %A_Space%, %TestPath%	;Create file and then select it and rename it
		if(!FileExist(TestPath))
		{
			Notify("Could not create new file!", "Could not create a new file here. Make sure you have the correct permissions!", 5, "GC=555555 TC=White MC=White",NotifyIcons.Error)
			return 0
		}
		Navigation.Refresh()
		Sleep 50
		if(WinActive("ahk_group DesktopGroup")) ;Desktop needs more time for refresh and selecting an item is handled by typing its name
			Sleep 1000
		Navigation.SelectFiles(Testpath)
		if(this.Rename)
		{
			Sleep 50
			Send {F2}
		}
		return 1
	} 

	DisplayString()
	{
		return "Create File: " this.Filename
	}

	GuiShow(GUI, GoToLabel = "")
	{
		static sGUI
		if(GoToLabel = "")
		{
			sGUI := GUI
			this.AddControl(GUI, "Text", "Desc", "This action creates a new file in the current directory (text file by default) while explorer is active and goes into renaming mode. It is also possible to use any other base file as source.")
			this.AddControl(GUI, "Edit", "Filename", "", "", "Filename:", "Placeholders", "Action_NewFile_Placeholders")
			this.AddControl(GUI, "Edit", "BaseFile", "", "", "BaseFile:", "Browse", "Action_NewFile_Browse", "Placeholders", "Action_NewFile_Placeholders","To use another file than a txt file, enter the bath to a base file here which will be copied.")
			this.AddControl(GUI, "Checkbox", "Rename", "Start Renaming", "", "")
		}
		else if(GoToLabel = "Placeholders")
			ShowPlaceholderMenu(sGUI, "Filename")
		else if(GoToLabel = "Browse")
			this.SelectFile(sGUI, "BaseFile")
	}
}
Action_NewFile_Placeholders:
GetCurrentSubEvent().GuiShow("", "Placeholders")
return
Action_NewFile_Browse:
GetCurrentSubEvent().GuiShow("", "Browse")
return
