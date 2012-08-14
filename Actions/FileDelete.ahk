Class CFileDeleteAction Extends CAction
{
	static Type := RegisterType(CFileDeleteAction, "Delete file")
	static Category := RegisterCategory(CFileDeleteAction, "File")
	static _ImplementsFileOperation := ImplementFileOperationInterface(CFileDeleteAction)

	Execute(Event)
	{
		this.FileOperationProcessPaths(Event, sources, targets, flags)
		ShellFileOperation(0x3, sources, "", flags)  
		return 1
	}

	DisplayString()
	{
		return this.FileOperationDisplayString()
	}

	GuiShow(GUI, GoToLabel = "")
	{	
		static sGUI
		if(GoToLabel = "")
		{
			sGUI := GUI
			this.AddControl(GUI, "Edit", "SourceFile", "", "", "Source File(s):", "Placeholders", "Action_Delete_Placeholders_Source")
		}
		else if(GoToLabel = "PlaceholdersSource")
			ShowPlaceholderMenu(sGUI, "SourceFile")
	}
}

Action_Delete_Placeholders_Source:
GetCurrentSubEvent().GuiShow("", "PlaceholdersSource")
return