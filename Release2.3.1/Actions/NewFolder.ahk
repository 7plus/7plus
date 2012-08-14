Class CNewFolderAction Extends CAction
{
	static Type := RegisterType(CNewFolderAction, "Create new folder")
	static Category := RegisterCategory(CNewFolderAction, "Explorer")
	static Rename := true
	static FolderName := TranslateMUI("shell32.dll",30320) ;"New Folder"
	
	;Assign dynamically extracted localized "New Folder" name on startup as default property
	Startup()
	{
		global shell32muipath
		if(WinVer >= WIN_Vista)
			this.FolderName:=TranslateMUI(shell32muipath,16859) ;"New Folder"
	}
	
	Execute(Event)
	{
		if(!(WinActive("ahk_group ExplorerGroup") || WinActive("ahk_group DesktopGroup") || IsDialog()))
		{
			Notify(this.Type " Error!", "This action requires explorer to be active!", 5, NotifyIcons.Error)
			return 0
		}
		if(IsRenaming())
			return 0
		
		;This is done manually, by creating a folder desired name, which is then focussed
		SetFocusToFileView()
		path := Navigation.GetPath()
		if(strEndsWith(path, "\"))
			path := SubStr(path, 1, StrLen(path) - 1)
		name := Event.ExpandPlaceholders(this.Foldername)
		TestPath := FindFreeFileName(path "\" name)
		FileCreateDir, %TestPath% ;Create Folder and then select it and rename it
		
		;if folder wasn't created, it's possible that it happens because the user is on a network share/drive and logged in with wrong credentials.
		;Let CMD handle directory creation then.
		if(!InStr(FileExist(Testpath), "D"))
		{
			SplitPath, TestPath,,,,,Drive
			FileDelete, %A_Temp%\mkdir.bat
			FileAppend, %Drive%`nmkdir "%Testpath%", %A_Temp%\mkdir.bat
			Run, %A_Temp%\mkdir.bat,,Hide
			FileDelete, %A_Temp%\mkdir.bat
		}
		
		if(!InStr(FileExist(Testpath), "D"))
		{
			Notify("Could not create new folder!", "Could not create a new folder here. Make sure you have the correct permissions!", 5, NotifyIcons.Error)
			return 0
		}
		Navigation.Refresh()
		Sleep 50
		if(WinActive("ahk_group DesktopGroup")) ;Desktop needs more time for refresh and selecting an item is handled by typing its name
			Sleep 1000
		Navigation.SelectFiles(TestPath)
		if(this.Rename)
		{
			Sleep 50
			Send {F2}
		}
		return 1
	} 

	DisplayString()
	{
		return "Create Folder: " this.Foldername
	}

	GuiShow(GUI, GoToLabel = "")
	{
		static sGUI
		if(GoToLabel = "")
		{
			sGUI := GUI
			this.AddControl(GUI, "Text", "Desc", "This action creates a new folder in the current directory while explorer is active and goes into renaming mode.")
			this.AddControl(GUI, "Edit", "Foldername", "", "", "Foldername:", "Placeholders", "Action_NewFolder_Placeholders")
			this.AddControl(GUI, "Checkbox", "Rename", "Start Renaming", "", "")
		}
		else if(GoToLabel = "Placeholders")
			ShowPlaceholderMenu(sGUI, "Foldername")
	}
}
Action_NewFolder_Placeholders:
GetCurrentSubEvent().GuiShow("", "Placeholders")
return