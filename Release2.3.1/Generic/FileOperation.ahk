ImplementFileOperationInterface(SubEvent)
{
	SubEvent.Silent := false
	SubEvent.Overwrite := false
	SubEvent.SourceFile := ""
	SubEvent.TargetPath := ""
	SubEvent.TargetFile := ""
	if(SubEvent.HasKey("__Class"))
	{
		SubEvent.FileOperationDisplayString := Func("Action_FileOperation_DisplayString")
		SubEvent.FileOperationGuiShow := Func("Action_FileOperation_GuiShow")
		SubEvent.FileOperationGuiSubmit := Func("Action_FileOperation_GuiSubmit")
		SubEvent.FileOperationProcessPaths := Func("Action_FileOperation_ProcessPaths")
	}
}

Action_FileOperation_DisplayString(SubEvent)
{
	return SubEvent.Type " " SubEvent.SourceFile (SubEvent.TargetPath || SubEvent.TargetFile ? " to " : " ") SubEvent.TargetPath (SubEvent.TargetFile && SubEvent.TargetPath ? "\" : "") SubEvent.TargetFile
}

Action_FileOperation_GuiShow(SubEvent, GUI, GoToLabel = "")
{
	if(GoToLabel = "")
	{
		SubEvent.tmpFileOperationGUI := GUI
		AddControl(SubEvent, GUI, "Edit", "SourceFile", "", "", "Source file(s):", "Browse", "Action_FileOperation_Browse_Source", "Placeholders", "Action_FileOperation_Placeholders_Source")
		AddControl(SubEvent, GUI, "Edit", "TargetPath", "", "", "Target path:", "Browse", "Action_FileOperation_Browse_Target", "Placeholders", "Action_FileOperation_Placeholders_TargetPath")
		AddControl(SubEvent, GUI, "Edit", "TargetFile", "", "", "Target file(s):", "Placeholders", "Action_FileOperation_Placeholders_TargetName")
		AddControl(SubEvent, GUI, "Checkbox", "Silent", "Silent", "", "")
		AddControl(SubEvent, GUI, "Checkbox", "Overwrite", "Overwrite existing files", "", "")
	}
	else if(GoToLabel = "PlaceholdersSource")
		ShowPlaceholderMenu(SubEvent.tmpFileOperationGUI, "SourceFile")
	else if(GoToLabel = "Browse_Source")
		ShowPlaceholderMenu(SubEvent.tmpFileOperationGUI, "SourceFile")
	else if(GoToLabel = "Browse_Target")
		ShowPlaceholderMenu(SubEvent.tmpFileOperationGUI, "TargetPath")
	else if(GoToLabel = "PlaceholdersTargetPath")
		ShowPlaceholderMenu(SubEvent.tmpFileOperationGUI, "TargetPath")
	else if(GoToLabel = "PlaceholdersTargetName")
		ShowPlaceholderMenu(SubEvent.tmpFileOperationGUI, "TargetFile")	
}
Action_FileOperation_Placeholders_Source:
GetCurrentSubEvent().FileOperationGuiShow("", "PlaceholdersSource")
return
Action_FileOperation_Browse_Source:
GetCurrentSubEvent().FileOperationGuiShow("", "Browse_Source")
return
Action_FileOperation_Browse_Target:
GetCurrentSubEvent().FileOperationGuiShow("", "Browse_Target")
return
Action_FileOperation_Placeholders_TargetPath:
GetCurrentSubEvent().FileOperationGuiShow("", "PlaceholdersTargetPath")
return
Action_FileOperation_Placeholders_TargetName:
GetCurrentSubEvent().FileOperationGuiShow("", "PlaceholdersTargetName")
return

Action_FileOperation_GuiSubmit(SubEvent, GUI)
{
	SubEvent.Remove("tmpFileOperationGUI")
}
Action_FileOperation_ProcessPaths(Action, Event, ByRef Sources, ByRef Targets, ByRef Flags)
{
	SourceFiles := Event.ExpandPlaceholders(Action.SourceFile)
	TargetPath := Event.ExpandPlaceholders(Action.TargetPath)
	TargetFile := Event.ExpandPlaceholders(Action.TargetFile)
	SplitPath, TargetFile, , , TargetExtension, TargetFilenameNoExt
	files := ToArray(SourceFiles)
	targets := Array()
	Loop % files.MaxIndex()
	{
		file := files[A_Index]
		SplitPath, file, Filename, Filepath, Extension, FilenameNoExt
		if(!TargetPath)
			target := FilePath
		else
			target := TargetPath
		if(!TargetFile)
			target .= "\" Filename
		else
		{
			target .= "\" TargetFilenameNoExt ;(A_Index = 1 ? "" : " (" A_Index ")") ;Add (4) to multiple file targets
			if(TargetExtension)
				target .= "." TargetExtension
			else
				target .= "." Extension
		}
		sources .= (A_Index = 1 ? "" : "|") file
		targets.Insert(target)
	}
	target := targets
	targets := ""
	Loop % target.MaxIndex()
	{
		file := target[A_Index]
		pos := A_Index
		if(!Action.Overwrite)
		{
			;Create new numbered filenames
			Splitpath, file, , path, Extension, NameNoExt
			Loop ;Loop over numbers
			{
				testfile := A_Index = 1 ? file : path "\" NameNoExt " (" A_Index ")." Extension	
				found := false
				if(FileExist(testfile))
					found := true
				if(!found)
				{
					Loop % pos - 1 ;Look through previous targets and see if number needs to be increased
					{
						if(target[A_Index] = testfile)
						{
							found := true
							break
						}
					}
				}
				if(!found)
				{
					target[pos] := testfile
					break
				}
			}			
		}
		targets .= (A_Index = 1 ? "" : "|") target[pos]
	}
	flags := (FOF_MULTIDESTFILES := 0x1) | (FOF_NOCONFIRMMKDIR := 0x200) | (Action.Silent ? (FOF_NO_UI := 0x614) : 0x0) | (Action.Overwrite ? 0x0 : (FOF_RENAMEONCOLLISION := 0x0008))
}	