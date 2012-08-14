Class CFileSystemPlugin extends CAccessorPlugin
{
	;Register this plugin with the Accessor main object
	static Type := CAccessor.RegisterPlugin("File System", CFileSystemPlugin)
	
	Description := "Browse the file system by typing a path. Use Tab for switching through matching entries and`nenter to enter a folder. Programs launched with this plugin are added to the program launcher`nplugin cache. If you select a path in another program you can directly open it in Accessor."
	
	;List of current icon handles
	Icons := Array()

	AllowDelayedExecution := true


	Class CSettings extends CAccessorPlugin.CSettings
	{
		Keyword := "fs"
		KeywordOnly := false
		MinChars := 3
		UseIcons := false
		UseSelectedText := true
		ShowFilesOfCurrentFolder := false
		BasePriority := 0.4
	}

	Class CResult extends CAccessorPlugin.CResult
	{
		Class CFileActions extends CArray
		{
			DefaultAction := new CAccessor.CAction("Open file", "Run")
			__new()
			{
				this.Insert(CAccessorPlugin.CActions.OpenWith)
				this.Insert(CAccessorPlugin.CActions.OpenExplorer)
				this.Insert(CAccessorPlugin.CActions.OpenCMD)
				this.Insert(CAccessorPlugin.CActions.Copy)
				this.Insert(CAccessorPlugin.CActions.ExplorerContextMenu)
			}
		}
		Class CExecutableActions extends CArray
		{
			DefaultAction := CAccessorPlugin.CActions.Run
			__new()
			{
				this.Insert(CAccessorPlugin.CActions.OpenWith)
				this.Insert(CAccessorPlugin.CActions.RunWithArgs)
				this.Insert(CAccessorPlugin.CActions.RunAsAdmin)
				this.Insert(CAccessorPlugin.CActions.OpenExplorer)
				this.Insert(CAccessorPlugin.CActions.OpenCMD)
				this.Insert(CAccessorPlugin.CActions.Copy)
				this.Insert(CAccessorPlugin.CActions.ExplorerContextMenu)
			}
		}
		Class CFolderActions extends CArray
		{
			DefaultAction := new CAccessor.CAction("Enter folder", "EnterDirectory", Func("FileSystemPlugin_IsInDifferentPath"), false, false, false)
			__new()
			{
				this.Insert(CAccessorPlugin.CActions.OpenExplorer)
				this.Insert(CAccessorPlugin.CActions.OpenCMD)
				this.Insert(CAccessorPlugin.CActions.Copy)
				this.Insert(CAccessorPlugin.CActions.ExplorerContextMenu)
				this.Insert(CAccessorPlugin.CActions.SearchDir)
			}
		}
		__new(Type)
		{
			if(Type = "Folder")
			{
				this.Actions := new this.CFolderActions()
				this.IsFolder := true
			}
			else if(Type = "Executable")
				this.Actions := new this.CExecutableActions()
			else
				this.Actions := new this.CFileActions()
			this.IsFile := true
		}
		Type := "File System"
		Priority := CFileSystemPlugin.Instance.Priority
		AllowDelayedExecution := true
		ResultIndexingKey := "Path"
		MatchQuality := 1 ;Only direct matches are used by FileSystem plugin
	}

	IsInSinglePluginContext(Filter, LastFilter)
	{
		Filter := ExpandPathPlaceholders(Filter)

		;Make it possible to use the current directory with \
		if(SubStr(Filter, 1, 1) = "\")
			Filter := CAccessor.Instance.CurrentDirectory Filter

		SplitPath, Filter, name, dir,,,drive
		if((x := InStr(dir, ":") ) != 0 && x != 2) ;Colon may only be drive separator
			return false
		return dir != "" && !InStr(Filter, "://") && InStr(Filter, "HK") != 1 ;Don't match URLs and registry keys
	}

	GetDisplayStrings(ListEntry, ByRef Title, ByRef Path, ByRef Detail1, ByRef Detail2)
	{
		if(InStr(FileExist(ListEntry.Path), "D"))
			Detail1 := "Folder"
		else
			Detail1 := "File"
	}
	
	OnOpen(Accessor)
	{
		;Automatically open path when a path is selected before Accessor is opened
		if(this.Settings.UseSelectedText && Accessor.SelectedText && !Accessor.SelectedFile && !Accessor.Filter && !Accessor.FilterWithoutTimer)
		{
			Path := ExpandPathPlaceholders(Accessor.SelectedText)
			SplitPath, Path, Name, Dir
			if(InStr(FileExist(Path), "D"))
				Accessor.SetFilter(Path (strEndsWith(Path, "\") ? "" : "\"))
			else if(InStr(FileExist(Dir), "D"))
				Accessor.SetFilter(Dir (strEndsWith(Dir, "\") ? "" : "\"))
		}
	}
	
	OnClose(Accessor)
	{
		;Get rid of old icons from last query
		if(this.Settings.UseIcons)
			for index, Icon in this.Icons
				DestroyIcon(Icon)
		this.AutoCompletionString := ""
	}
	RefreshList(Accessor, Filter, LastFilter, KeywordSet, Parameters)
	{
		;Get rid of old icons from last query
		if(this.Settings.UseIcons)
			for index, Icon in this.Icons
				DestroyIcon(Icon)
		
		Results := Array()
		Filter := ExpandPathPlaceholders(Filter)
		
		;Make it possible to use the current directory with \
		if(SubStr(Filter, 1, 1) = "\")
			Filter := Accessor.CurrentDirectory Filter

		SplitPath, filter, name, dir, , , drive
		;Possibly show current files in normal search?
		if(!dir && Accessor.CurrentDirectory && this.Settings.ShowFilesOfCurrentFolder)
			dir := Accessor.CurrentDirectory

		if(dir)
		{
			;Store for temporary use
			this.Path := dir

			Result := new this.CResult("Folder")
			Result.Title := name
			Result.Path := dir
			Result.Icon := Accessor.GenericIcons.Folder

			;Possibly add an action to select the currently entered files
			if(Navigation.FindNavigationSource(Accessor.PreviousWindow, "SelectFiles"))
				Result.Actions.Insert(new CAccessor.CAction("Select these files", "SelectFiles"))
			Result.Actions.Insert(CAccessorPlugin.CActions.SearchDir)
			this.Result := Result


			if(this.AutocompletionString)
				name := this.AutocompletionString
			Loop %dir%\*%name%*, 2, 0
			{
				Result := new this.CResult("Folder")
				Result.Title := A_LoopFileName
				Result.Path := A_LoopFileFullPath
				Result.Icon := Accessor.GenericIcons.Folder
				Results.Insert(Result)
			}
			Loop %dir%\*%name%*, 0, 0
			{
				IsExecutable := A_LoopFileExt && InStr("exe,cmd,bat,ahk", A_LoopFileExt)
				
				Result := new this.CResult(IsExecutable ? "Executable" : "File")
				Result.Title := A_LoopFileName
				Result.Path := A_LoopFileFullPath
				if(this.Settings.UseIcons)
				{
					hIcon := ExtractAssociatedIcon(0, A_LoopFileFullPath, iIndex)
					this.Icons.Insert(hIcon)
				}
				else
				{
					if(IsExecutable)
						hIcon := Accessor.GenericIcons.Application
					else
						hIcon := Accessor.GenericIcons.File
				}
				Result.Icon := hIcon
				Results.Insert(Result)
			}
		}
		else
			this.Remove("Result")
		return Results
	}
	ShowSettings(PluginSettings, Accessor, PluginGUI)
	{
		AddControl(PluginSettings, PluginGUI, "Checkbox", "UseIcons", "Use exact icons (much slower)", "", "")
		AddControl(PluginSettings, PluginGUI, "Checkbox", "UseSelectedText", "Automatically open the selected text as path in Accessor when appropriate", "", "")
		AddControl(PluginSettings, PluginGUI, "Checkbox", "ShowFilesOfCurrentFolder", "Show files from a previously active Explorer window (or similar windows)", "", "")
	}
	
	EnterDirectory(Accessor, ListEntry)
	{
		this.AutoCompletionString := ""
		if(InStr(FileExist(ListEntry.Path),"D"))
			Accessor.SetFilter(ListEntry.Path "\")
	}
	SelectFiles(Accessor, ListEntry)
	{
		Files := Get(GetAll(Accessor.List, "Type", "File System"), "Title")
		Navigation.SelectFiles(Files, Accessor.PreviousWindow)
	}
	OnTab()
	{
		Accessor := CAccessor.Instance
		if(Accessor.List.MaxIndex() = 1 && InStr(FileExist(Accessor.List[1].Path),"D")) ;Go into folder if there is only one entry
		{
			Accessor.PerformAction()
			return
		}
		
		Filter := ExpandPathPlaceholders(Accessor.FilterWithoutTimer)
		SplitPath, Filter, name, dir,,,drive
		
		if(name)
		{
			if(!this.AutocompletionString)
				this.AutocompletionString := name
			AutocompletionString := this.AutocompletionString
			Loop %dir%\*%AutocompletionString%*,1,0
			{
				if(A_Index = 1)
					first := A_LoopFileName
				if(A_LoopFileName = name)
				{
					usenext := true
					continue
				}
				if(usenext || (A_Index = 1 && name = AutocompletionString))
				{
					newname := A_LoopFileName
					break
				}
			}
		}
		else
			return 0
		if(!newname)
			newname := first
		if(!newname)
			return
		
		Accessor.SuppressListViewUpdate := 1
		Accessor.SetFilter(dir "\" newname) 
		Edit_Select(InStr(dir "\" newname, "\", false, 0), -1, "", "ahk_id " Accessor.GUI.EditControl.hwnd)
		for index, item in Accessor.GUI.ListView.Items
		{
			if(item.Text = newname)
			{
				item.Selected := true
				break
			}
		}
		return 1
	}
	OnFilterChanged(ListEntry, Filter, LastFilter)
	{
		this.AutocompletionString := ""
		return true
	}
	GetFooterText()
	{
		return "Files launched using the file system plugin can afterwards be opened by their filename without the path!"
	}
}

;Not included in class to avoid circular references
FileSystemPlugin_IsInDifferentPath(ListEntry)
{
	return CFileSystemPlugin.Instance.Path != ListEntry.Path
}

#if (CAccessor.Instance.GUI && CAccessor.Instance.SingleContext = "File System")
Tab::
CFileSystemPlugin.Instance.OnTab()
return
#if
#if (CAccessor.Instance.GUI && CAccessor.Instance.SingleContext = "File System" && CAccessor.Instance.GUI.ActiveControl = CAccessor.Instance.GUI.ListView)
Backspace::
CAccessor.Instance.SetFilter(SubStr(CAccessor.Instance.FilterWithoutTimer, 1, InStr(CAccessor.Instance.FilterWithoutTimer, "\", false, 0, strEndsWith(CAccessor.Instance.FilterWithoutTimer, "\") ? 2 : 1)))
return
#if