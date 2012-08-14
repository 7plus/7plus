Class CProgramLauncherPlugin extends CAccessorPlugin
{
	;Register this plugin with the Accessor main object
	static Type := CAccessor.RegisterPlugin("Program Launcher", CProgramLauncherPlugin)
	
	Description := "Run programs/files by typing a part of their name. All programs/files from the folders in the list `nbelow can be used. 7plus also looks for running programs and automatically adds them `nto the index, so you don't have to add large directories like Program Files or WinDir usually."
	
	;List of cached programs
	List := Array()
	
	;List of cached paths
	Paths := Array()

	AllowDelayedExecution := true
	

	Class CSettings extends CAccessorPlugin.CSettings
	{
		Keyword := "run"
		KeywordOnly := false
		FuzzySearch := false
		IgnoreExtensions := true
		;Exclude := "setup,install,uninst,remove"
		MinChars := 2
		OpenWithKeyword := "ow"
		;RefreshOnStartup := true
		BasePriority := 0.7
	}

	/*
	represents a path which is included in the indexing of this plugin
	*/
	Class CIndexingPath
	{
		Path := ""
		Extensions := "lnk,exe"
		Actions := [{Action : "Run", Command : "${File}"}]
		UpdateOnStart := true
		UpdateOnOpen := false
		Exclude := "setup,install,unins,remove"

		Load(json)
		{
			if(json.HasKey("Path"))
			{
				for key, value in this
				{
					if(!IsFunc(value) && key != "Base" && key != "Actions" && json.HasKey(key))
						this[key] := json[key]
					else if(key = "Actions" && json.HasKey("Actions"))
					{
						this.Actions := Array()
						if(!json.Actions.MaxIndex())
							json.Actions := [json.Actions]
						for index, action in json.Actions
							if(action.HasKey("Action") && action.HasKey("Command"))
								this.Actions.Insert({Action : action.Action, Command : action.Command})
					}
				}
			}
		}

		Write(json)
		{
			jsonPath := {}
			for key, value in this
			{
				if(!IsFunc(value) && key != "Base" && key != "Actions")
					jsonPath[key] := this[key]
				else if(key = "Actions")
				{
					jsonPath.Actions := Array()
					for index, action in value
						if(action.HasKey("Action") && action.HasKey("Command"))
							jsonPath.Actions.Insert({Action : action.Action, Command : action.Command})
				}
			}
			json.Insert(jsonPath)
		}
	}

	/*
	Represents an indexed file for the Program Launcher plugin.
	*/
	Class CIndexedFile
	{
		args := ""
		BasePath := ""
		Command := ""
		ResolvedName := ""
		Filename := ""

		Load(json)
		{
			if(json.HasKey("Command"))
				for key, value in this
					if(!IsFunc(value) && key != "Base" && json.HasKey(key))
						this[key] := json[key]
			if(!this.ResolvedName)
			{
				Command := this.Command
				SplitPath, command, ResolvedName
				this.ResolvedName := Command
			}
		}

		Write(json)
		{
			jsonFile := {}
			for key, value in this
				if(!IsFunc(value) && key != "Base")
					jsonFile[key] := this[key]
			json.Insert(jsonFile)
		}
	}

	Class CResult extends CAccessorPlugin.CResult
	{
		Class CActions extends CArray
		{
			DefaultAction := CAccessorPlugin.CActions.Run
			__new(BasePath = "")
			{
				;If this program is from an indexed path there can be customized actions for it
				if(BasePath)
				{
					Actions := CProgramLauncherPlugin.Instance.Paths.GetItemWithValue("Path", BasePath).Actions
					if(Actions)
						for index, Action in Actions
						{
							CustomAction := new CAccessor.CAction(Action.Action, "CustomAction")
							CustomAction.Command := Action.Command
							if(index = 1)
								this.DefaultAction := CustomAction
							else
								this.Insert(CustomAction)
						}
				}
				this.Insert(CAccessorPlugin.CActions.RunWithArgs)
				this.Insert(CAccessorPlugin.CActions.RunAsAdmin)
				this.Insert(CAccessorPlugin.CActions.OpenWith)
				this.Insert(CAccessorPlugin.CActions.OpenExplorer)
				this.Insert(CAccessorPlugin.CActions.OpenCMD)
				this.Insert(CAccessorPlugin.CActions.OpenPathWithAccessor)
				this.Insert(CAccessorPlugin.CActions.Copy)
				this.Insert(CAccessorPlugin.CActions.ExplorerContextMenu)
			}
		}
		Type := "Program Launcher"
		Priority := CProgramLauncherPlugin.Instance.Priority
		ResultIndexingKey := "Path"
		IsFile := true
		__new(BasePath = "")
		{
			this.Actions := new this.CActions(BasePath)
		}
	}

	;result for open with actions
	Class COpenWithResult extends CAccessorPlugin.CResult
	{
		Type := "Program Launcher"
		ResultIndexingKey := "Path" ;By using the same index for normal and OpenWith results the weighting can be shared
		SaveHistory := false ;Doesn't make sense to save it since the context is not preserved

		Class CActions extends CArray
		{
			DefaultAction := new CAccessor.CAction("Open With", "OpenWith")
		}
		
		__new()
		{
			this.Actions := new this.CActions()
		}
	}

	Init()
	{
		this.ReadCache()
		for index, IndexingPath in this.Paths
			if(IndexingPath.UpdateOnStart)
				this.RefreshCache(IndexingPath)
		SetTimer, UpdateLauncherPrograms, 60000
	}
	
	ShowSettings(PluginSettings, GUI, PluginGUI)
	{
		this.SettingsWindow := {Settings: PluginSettings, GUI: GUI, PluginGUI: PluginGUI}
		this.SettingsWindow.Paths := this.Paths.DeepCopy()
		AddControl(PluginSettings, PluginGUI, "Checkbox", "IgnoreExtensions", "Ignore file extensions", "", "", "", "", "", "", "If checked, file extensions will be excluded from the query.")
		AddControl(PluginSettings, PluginGUI, "Edit", "OpenWithKeyword", "", "", "Open With keyword", "", "", "", "", "Selected files in explorer or similar programs can be quickly opened by typing this keyword and then an application name, i.e. ""ow Notepad""")
		
		GUI.ListBox := GUI.AddControl("ListBox", "ListBox", "-Hdr -Multi -ReadOnly x" PluginGUI.x " y+10 w330 R9", "")
		for index, IndexedPath in this.SettingsWindow.Paths
			GUI.ListBox.Items.Add(IndexedPath.Path)
		GUI.ListBox.SelectionChanged.Handler := new Delegate(this, "Settings_PathSelectionChanged")
		GUI.ListBox.DoubleClick.Handler := new Delegate(this, "Settings_Edit")
		
		GUI.btnAddPath := GUI.AddControl("Button", "btnAddPath", "x+10 w80", "&Add Path")
		GUI.btnAddPath.Click.Handler := new Delegate(this, "Settings_AddPath")
		
		GUI.btnEdit := GUI.AddControl("Button", "btnEdit", "y+10 w80", "&Edit")
		GUI.btnEdit.Click.Handler := new Delegate(this, "Settings_Edit")
		
		GUI.btnDeletePath := GUI.AddControl("Button", "btnDeletePath", "y+10 w80", "&Delete Path")
		GUI.btnDeletePath.Click.Handler := new Delegate(this, "Settings_DeletePath")
		
		GUI.btnRefreshCache := GUI.AddControl("Button", "btnRefreshCache", "y+10 w80", "&Refresh Cache")
		GUI.btnRefreshCache.Click.Handler := new Delegate(this, "Settings_RefreshCache")


		if(GUI.ListBox.Items.MaxIndex())
			GUI.ListBox.SelectedIndex := 1
		else
		{
			GUI.btnEdit.Enabled := false
			GUI.btnDeletePath.Enabled := false
		}
	}

	SaveSettings(PluginSettings, GUI, PluginGUI)
	{
		this.Paths := Array()
		for index, IndexedPath in this.SettingsWindow.Paths
		{
			if(InStr(FileExist(ExpandPathPlaceholders(IndexedPath.Path)), "D"))
				this.Paths.Insert(IndexedPath)
			else
				Notify("Invalid indexing path", "Ignoring " IndexedPath.Path " because it is invalid.", 5, NotifyIcons.Error)
		}
		this.RefreshCache()
		this.Remove("SettingsWindow")
	}

	Settings_PathSelectionChanged(Sender, Row)
	{
		if(this.SettingsWindow.GUI.ListBox.SelectedItem)
		{
			this.SettingsWindow.GUI.btnDeletePath.Enabled := true
			this.SettingsWindow.GUI.btnEdit.Enabled := true
		}
		else
		{
			this.SettingsWindow.GUI.btnDeletePath.Enabled := false
			this.SettingsWindow.GUI.btnEdit.Enabled := false
		}
	}

	Settings_AddPath(Sender)
	{
		fd := new CFolderDialog()
		fd.Title := "Add indexing path"
		if(fd.Show())
		{
			IndexPathObject := new this.CIndexingPath()
			IndexPathObject.Path := fd.Folder
			PathEditorWindow := new CProgramLauncherPathEditorWindow(IndexPathObject, true)
			PathEditorWindow.OnClose.Handler := new Delegate(this, "IndexPath_OnClose")
			PathEditorWindow.Show()
		}
	}

	Settings_Edit(Params*)
	{
		if(this.SettingsWindow.GUI.ListBox.SelectedItem)
		{
			PathEditorWindow := new CProgramLauncherPathEditorWindow(this.SettingsWindow.Paths[this.SettingsWindow.GUI.ListBox.SelectedIndex], false)
			PathEditorWindow.OnClose.Handler := new Delegate(this, "IndexPath_OnClose")
			PathEditorWindow.Show()
		}
	}

	IndexPath_OnClose(Sender)
	{
		this.SettingsWindow.GUI.Enabled := true
		if(IndexPathObject := Sender.Result)
		{
			if(Sender.Temporary)
			{
				this.SettingsWindow.Paths.Insert(IndexPathObject)
				this.SettingsWindow.GUI.ListBox.Items.Add(IndexPathObject.Path)
			}
			else
			{
				this.SettingsWindow.Paths[this.SettingsWindow.GUI.ListBox.SelectedIndex] := IndexPathObject
				this.SettingsWindow.GUI.ListBox.SelectedItem.Text := IndexPathObject.Path
			}
		}
	}

	Settings_DeletePath(Sender)
	{
		if(this.SettingsWindow.GUI.ListBox.SelectedItem)
		{
			this.SettingsWindow.Paths.Remove(this.SettingsWindow.GUI.ListBox.SelectedIndex)
			this.SettingsWindow.GUI.ListBox.Items.Delete(this.SettingsWindow.GUI.ListBox.SelectedIndex)
		}
	}

	Settings_RefreshCache(Sender)
	{
		this.RefreshCache()
	}
	
	IsInSinglePluginContext(Filter, LastFilter)
	{
		return this.Settings.OpenWithKeyword && InStr(Filter, this.Settings.OpenWithKeyword " ") = 1
	}

	GetDisplayStrings(ListEntry, ByRef Title, ByRef Path, ByRef Detail1, ByRef Detail2)
	{
		Detail1 := "Program"
	}

	OnOpen(Accessor)
	{
		for index, IndexingPath in this.Paths
			if(IndexingPath.UpdateOnOpen)
				this.RefreshCache(IndexingPath)
	}

	OnExit(Accessor)
	{
		for index, ListEntry in this.List
			DestroyIcon(this.List.hIcon)
		this.WriteCache()
	}

	GetFooterText()
	{
		return this.OpenWithActive ? "Choose a program to open " (CAccessor.Instance.SelectedFile ? CAccessor.Instance.SelectedFile : (CAccessor.Instance.TemporaryFile ? CAccessor.Instance.TemporaryFile : (CAccessor.Instance.TemporaryText ? CAccessor.Instance.TemporaryText : CAccessor.Instance.SelectedText))) " with." : "If a file is not found by this plugin you can add it by executing it through File Search/System plugins."
	}
	
	RefreshList(Accessor, Filter, LastFilter, KeywordSet, Parameters)
	{
		Results := Array()
		
		;Detect "Open with" functionality
		if((Accessor.SelectedFile || Accessor.TemporaryFile || Accessor.TemporaryText || Accessor.SelectedText) && this.Settings.OpenWithKeyword && InStr(Filter, this.Settings.OpenWithKeyword " ") = 1)
		{
			this.OpenWithActive := true
			Filter := strTrimLeft(SubStr(Filter, strlen(this.Settings.OpenWithKeyword) + 2), " ")
			if(strlen(Filter) < this.Settings.MinChars)
				return
		}
		else
			this.OpenWithActive := false

		;Possibly remove file extension from filter
		strippedFilter := this.Settings.IgnoreFileExtensions ? RegexReplace(Filter, "\.\w+") : Filter

		index := 1
		Loop % this.List.MaxIndex()
		{
			ListEntry := this.List[index]
			if(!ListEntry.Command || !FileExist(ListEntry.Command))
			{
				this.List.Remove(index)
				continue
			}
			MatchPos := 0
			
			;Match by name of the resolved filename
			strippedResolvedName := this.Settings.IgnoreFileExtensions ? RegexReplace(ListEntry.ResolvedName, "\.\w+") : ListEntry.ResolvedName
			ResolvedMatch := 0
			if(strippedResolvedName)
				ResolvedMatch := FuzzySearch(strippedResolvedName, StrippedFilter, this.Settings.FuzzySearch)
			
			;Match by filename
			FilenameMatch := 0
			if(ListEntry.Filename)
				FilenameMatch := FuzzySearch(ListEntry.Filename, StrippedFilter, this.Settings.FuzzySearch)
			
			;ResolvedMatch is weighted slightly better
			if((Quality := max(ResolvedMatch - 0.1, FilenameMatch)) > Accessor.Settings.FuzzySearchThreshold)
			{
				if(!ListEntry.hIcon) ;Program launcher icons are cached lazy, only when needed
					ListEntry.hIcon := ExtractAssociatedIcon(0, ListEntry.Command, iIndex)
				
				Name := ListEntry.Filename ? ListEntry.Filename : ListEntry.ResolvedName
				
				;Create result
				if(this.OpenWithActive)
					result := new this.COpenWithResult()
				else
					result := new this.CResult(ListEntry.BasePath)
				result.Title := Name
				result.Path := ListEntry.Command
				result.args := ListEntry.args
				result.icon := ListEntry.hIcon
				result.MatchQuality := Quality
				Results.Insert(result)
			}
			index++
		}
		return Results
	}	
	
	;Functions specific to this plugin:

	;All customized actions use this action
	CustomAction(Accessor, ListEntry, Action)
	{
		Command := StringReplace(Action.Command, "${File}", ListEntry.Path)
		RunAsUser(Command)
	}

	;Open a file with a specific program
	OpenWith(Accessor, ListEntry, Action)
	{
		if(Accessor.SelectedFile || Accessor.TemporaryFile)
			OpenFileWithProgram(Accessor.SelectedFile ? Accessor.SelectedFile : Accessor.TemporaryFile, ListEntry.Path)
		else if(Accessor.TemporaryText || Accessor.SelectedText)
			RunAsUser(Quote(ListEntry.Path) " " Quote(Accessor.TemporaryText ? Accessor.TemporaryText : Accessor.SelectedText))
	}

	OnFilterChanged(ListEntry, Filter, LastFilter)
	{
		if(InStr(LastFilter, this.Settings.OpenWithKeyword " ") = 1 && InStr(Filter, this.Settings.OpenWithKeyword " ") != 1)
		{
			CAccessor.Remove("TemporaryFile")
			CAccessor.Remove("TemporaryText")
			this.OpenWithActive := false
		}
	}

	;Possibly add the selected program to ProgramLauncher cache
	AddToCache(ListEntry)
	{
		if(!ListEntry.Path)
			return
		if(!this.List.FindKeyWithValue("Command",ListEntry.Path))
		{
			path := ListEntry.Path
			SplitPath, path, Filename
			IndexedFile := new this.CIndexedFile()
			IndexedFile.Filename := Filename
			IndexedFile.Command := path
			this.List.Insert(IndexedFile)
		}
	}

	;Reads the cached files from HDD
	ReadCache()
	{
		this.List := Array()
		this.Paths := Array()
		if(!FileExist(Settings.ConfigPath "\ProgramCache.json") && !FileExist(Settings.ConfigPath "\ProgramCache.xml")) ;File doesn't exist, create default values
		{
			IndexingPath := new this.CIndexingPath()
			IndexingPath.Path := "%StartMenu%"
			this.Paths.Insert(IndexingPath)

			IndexingPath := new this.CIndexingPath()
			IndexingPath.Path := "%StartMenuCommon%"
			this.Paths.Insert(IndexingPath)

			IndexingPath := new this.CIndexingPath()
			IndexingPath.Path := "%Desktop%"
			this.Paths.Insert(IndexingPath)

			IndexingPath := new this.CIndexingPath()
			IndexingPath.Path := "%AppData%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
			this.Paths.Insert(IndexingPath)

			; TODO: Should this be included?
			;IndexingPath := new this.CIndexingPath()
			;IndexingPath.Path := "%UserProfile%\AppData\Roaming\Microsoft\Windows\Recent"
			;IndexingPath.Extensions := "*"
			;IndexingPath.UpdateOnOpen := true
			;this.Paths.Insert(IndexingPath)
			return
		}
		else if(FileExist(Settings.ConfigPath "\ProgramCache.json"))
		{
			FileRead, json, % Settings.ConfigPath "\ProgramCache.json"
			jsonObject := lson(json)
		}
		else ;Backwards compatibility with xml format
		{
			jsonObject := XML_Read(Settings.ConfigPath "\ProgramCache.xml")
			;Convert empty and single arrays to real array
			if(!jsonObject.List.MaxIndex())
				jsonObject.List := IsObject(jsonObject.List) ? Array(jsonObject.List) : Array()
			if(!jsonObject.Paths.MaxIndex())
				jsonObject.Paths := IsObject(jsonObject.Paths) ? Array(jsonObject.Paths) : Array()
			FileDelete, % Settings.ConfigPath "\ProgramCache.xml"
		}
		for index, json in jsonObject.List ;Read cached files
		{
			jsonFile := new this.CIndexedFile()
			jsonFile.Load(json)
			if(!this.List.FindKeyWithValue("Command", jsonFile.Command))
				this.List.Insert(jsonFile)
		}
		
		for index2, json in jsonObject.Paths ;Read scan directories
		{
			Path := new this.CIndexingPath()
			Path.Load(json)
			this.Paths.Insert(Path)
		}
	}
	
	;Writes the cached programs to disk
	WriteCache()
	{
		FileDelete, % Settings.ConfigPath "\ProgramCache.json"
		jsonObject := Object("List", Array(), "Paths", Array())
		for index, IndexedFile in this.List
			IndexedFile.Write(jsonObject.List)
		for index2, Path in this.Paths
			Path.Write(jsonObject.Paths)
		string := lson(jsonObject)
		FileAppend, %string%, % Settings.ConfigPath "\ProgramCache.json"
	}
	
	;Updates the list of cached programs, optionally for a specific path only
	RefreshCache(Path = "")
	{
		;Delete old cache entries which are to be refreshed
		pos := 1
		Loop % this.List.MaxIndex()
		{
			;Remove indexed files which match the specified paths or remove all indexed files from any path (but not others!)
			if((Path && this.List[pos].BasePath = Path.Path) || (!Path && this.List[pos].BasePath))
			{	
				if(this.List[pos].hIcon)
					DestroyIcon(this.List[pos].hIcon)
				this.List.Remove(pos)
				continue
			}
			pos++
		}
		if(Path)
			Paths := Array(Path)
		else
			Paths := this.Paths
		for index, Path in Paths
		{
			BasePath := ExpandInternalPlaceholders(Path.Path)
			if(!BasePath)
				continue
			extList := ToArray(Path.Extensions, ",")
			;Loop over all files (extensions filtered manually since there may be more than one)
			Loop, % BasePath "\*.*", , 1
			{
				if(extList.Contains(A_LoopFileExt) || extList.Contains("*"))
				{
					exclude := Path.Exclude
					command := A_LoopFileLongPath
					Filename := A_LoopFilename
					SplitPath, Filename,,,ext, Filename
					if(ext = "lnk")
					{
						FileGetShortcut, %Command% , ResolvedCommand, , args
						; Don't resolve:
						; - MSI Installer shortcuts which don't resolve to the proper executable
						; - Network paths which may take too long
						if(!InStr(ResolvedCommand, A_WinDir "\Installer") && InStr(ResolvedCommand, "\\") != 1)
						{
							command := ResolvedCommand
							;Check the extension again after resolving the link.
							SplitPath, command,,, ext
							if((!extList.Contains(ext) && !extList.Contains("*")))
								continue
							if(!args)
								SplitPath, command, ResolvedName ;Filename
						}
					}
					;Ignore empty commands and directories
					if(!command || InStr(FileExist(command),"D"))
						continue
					
					;Exclude undesired programs (uninstall, setup,...)
					if command not contains %exclude%
					{
						if Filename not contains %exclude%
						{
							;Check for existing duplicates
							if(!this.List.FindKeyWithValue("Command", command))
							{
								IndexedFile := new this.CIndexedFile()
								IndexedFile.Command := Command
								IndexedFile.args := args
								IndexedFile.BasePath := BasePath
								IndexedFile.Filename := Filename
								if(ResolvedName)
									IndexedFile.ResolvedName := ResolvedName
								this.List.Insert(IndexedFile)
							}
						}
					}
				}
			}
		}
	}
}

UpdateLauncherPrograms:
UpdateLauncherPrograms()
return
;This function is periodically called and adds running programs to the ProgramLauncher cache
UpdateLauncherPrograms()
{
	global WindowList
	if(!IsObject(CAccessor.Instance) || !IsObject(WindowList))
		return
	for i, Window in WindowList
	{
		if(Window.Path) ;Fails sometimes for some reason
		{
			if(!CProgramLauncherPlugin.Instance.List.FindKeyWithValue("Command", Window.Path))
			{
				path := Window.Path
				SplitPath, path, Filename
				exclude := CProgramLauncherPlugin.Instance.Settings.Exclude
				if path not contains %exclude%
				{
					IndexedFile := new CProgramLauncherPlugin.IndexedFile()
					IndexedFile.Filename := Filename
					IndexedFile.Command := Window.Path
					CProgramLauncherPlugin.Instance.List.Insert(IndexedFile)
				}
			}
		}
	}
}

Class CProgramLauncherPathEditorWindow extends CGUI
{
	txtPath := this.AddControl("Text", "txtPath", "x10 y13 section", "Path:")
	editPath := this.AddControl("Edit", "editPath", "x80 yp-3 w350", "")
	btnPath := this.AddControl("Button", "btnPath", "x+10 yp-2 w60", "Browse")
	txtExtensions := this.AddControl("Text", "txtExtensions", "xs+0 y+13", "Extensions:")
	editExtensions := this.AddControl("Edit", "editExtensions", "x80 yp-3 w350", "")
	txtSeparator := this.AddControl("Text", "txtSeparator", "x+10 yp+3", "Separator: Comma")
	txtExclude := this.AddControl("Text", "txtExclude", "xs+0 y+13", "Exclude:")
	editExclude := this.AddControl("Edit", "editExclude", "x80 yp-3 w350", "")
	chkUpdateOnOpen := this.AddControl("CheckBox", "chkUpdateOnOpen", "xs+0 y+13", "Update this path each time Accessor opens")
	chkUpdateOnStart := this.AddControl("CheckBox", "chkUpdateOnStart", "xs+0 y+10", "Update this path when 7plus starts")
	listActions := this.AddControl("ListView", "listActions", "xs+0 y+10 w520 Section", "Action|Command")
	btnAddAction := this.AddControl("Button", "btnAddAction", "x+10 yp+0 w80", "&Add Action")
	btnDeleteAction := this.AddControl("Button", "btnDeleteAction", "xp+0 y+10 w80", "&Delete Action")
	btnMoveActionUp := this.AddControl("Button", "btnMoveActionUp", "xp+0 y+10 w80", "Move &Up")
	btnMoveActionDown := this.AddControl("Button", "btnMoveActionDown", "xp+0 y+10 w80", "Move &Down")
	txtAction := this.AddControl("Text", "txtAction", "xs+0", "Action:")
	editAction := this.AddControl("Edit", "editAction", "x+10 yp-3", "")
	txtCommand := this.AddControl("Text", "txtCommand", "x+10 yp+3", "Command:")
	editCommand := this.AddControl("Edit", "editCommand", "x+10 yp-3 w217", "")
	btnBrowse := this.AddControl("Button", "btnBrowse", "x+10 yp-2 w60", "Browse")
	btnOK := this.AddControl("BUtton", "btnOK", "xs+350 y+15 w80 Default", "&OK")
	btnCancel := this.AddControl("BUtton", "btnCancel", "x+10 yp+0 w80", "&Cancel")

	__new(IndexPathObject, Temporary)
	{
		this.Temporary := Temporary
		this.Owner := CProgramLauncherPlugin.Instance.SettingsWindow.GUI.hwnd
		this.ToolWindow := true
		this.OwnDialogs := true
		CProgramLauncherPlugin.Instance.SettingsWindow.GUI.Enabled := false
		this.Title := "Edit Program Launcher indexing path"
		this.chkUpdateOnOpen.Tooltip := "This option might be desired for the recent docs folder, but it will increase Accessor opening times."
		this.DestroyOnClose := true
		this.CloseOnEscape := true
		for index, item in IndexPathObject.Actions
			this.listActions.Items.Add(index = 1 ? "Select" : "", item.Action, item.Command)
		this.chkUpdateOnOpen.Checked := IndexPathObject.UpdateOnOpen
		this.chkUpdateOnStart.Checked := IndexPathObject.UpdateOnStart
		this.editExtensions.Text := IndexPathObject.Extensions
		this.editExclude.Text := IndexPathObject.Exclude
		this.editPath.Text := IndexPathObject.Path
		this.listActions.ModifyCol(1, 200)
		this.listActions.ModifyCol(2, "AutoHdr")
		this.listActions_SelectionChanged()
	}

	btnOK_Click()
	{
		IndexPathObject := new CProgramLauncherPlugin.CIndexingPath()
		IndexPathObject.Path := this.editPath.Text
		IndexPathObject.Extensions := this.editExtensions.Text
		IndexPathObject.Exclude := this.editExclude.Text
		IndexPathObject.UpdateOnOpen := this.chkUpdateOnOpen.Checked
		IndexPathObject.UpdateOnStart := this.chkUpdateOnStart.Checked
		IndexPathObject.Actions := Array()
		;Find and fix dupes
		for index, item in this.listActions.Items
		{
			found := false
			for index2, item2 in IndexPathObject.Actions
			{
				if(item2.Action = item.Text)
				{
					found := true
					break
				}
			}
			if(!found)
			{
				IndexPathObject.Actions.Insert({Action : item.Text, Command : item[2]})
				continue
			}
			Loop
			{
				found := false
				index3 := A_Index + 1
				for index4, item4 in IndexPathObject.Actions
				{
					if(item4.Action = item.Text "(" index3 ")")
					{
						found := true
						break
					}
				}
				if(!found)
					break
			}
			if(!found)
				IndexPathObject.Actions.Insert({Action : item.Text "(" index3 ")", Command : item[2]})
		}
		this.Result := IndexPathObject
		this.Close()
	}

	btnCancel_Click()
	{
		this.Close()
	}

	btnPath_Click()
	{
		fd := new CFolderDialog()
		fd.Title := "Set indexing path"
		fd.Folder := this.editPath.Text
		if(fd.Show())
			this.editPath.Text := fd.Folder
	}

	btnBrowse_Click()
	{
		fd := new CFolderDialog()
		fd.Title := "Set indexing path"
		fd.Folder := this.editPath.Text
		if(fd.Show())
			this.editCommand.Text := fd.Folder
	}

	btnAddAction_Click()
	{
		found := false
		for index, item in this.listActions.Items
		{
			if(item.Text = "New Action")
			{
				found := true
				break
			}
		}
		if(!found)
		{
			this.listActions.Items.Add("", "New Action", "${File}")
			return
		}
		else
		{
			while(found)
			{
				found := false
				index := A_Index + 1
				for index2, item in this.listActions.Items
				{
					if(item.Text = "New Action (" index ")")
					{
						found := true
						break
					}
				}
				if(!found)
				{
					this.listActions.Items.Add("", "New Action (" index ")", "${File}")
					return
				}
			}
		}
	}

	btnDeleteAction_Click()
	{
		if(this.listActions.SelectedItems.MaxIndex() = 1)
			this.listActions.Items.Delete(this.listActions.SelectedIndex)
	}

	btnMoveActionUp_Click()
	{
		if(this.listActions.SelectedIndex > 1)
		{
			Action := this.listActions.SelectedItem.Text
			Command := this.listActions.SelectedItem[2]
			this.listActions.SelectedItem.Text := this.listActions.Items[this.listActions.SelectedIndex - 1].Text
			this.listActions.SelectedItem[2] := this.listActions.Items[this.listActions.SelectedIndex - 1][2]
			this.listActions.Items[this.listActions.SelectedIndex - 1].Text := Action
			this.listActions.Items[this.listActions.SelectedIndex - 1][2] := Command
		}
	}

	btnMoveActionDown_Click()
	{
		if(this.listActions.SelectedIndex && this.listActions.SelectedIndex < this.listActions.Items.MaxIndex())
		{
			Action := this.listActions.SelectedItem.Text
			Command := this.listActions.SelectedItem[2]
			this.listActions.SelectedItem.Text := this.listActions.Items[this.listActions.SelectedIndex + 1].Text
			this.listActions.SelectedItem[2] := this.listActions.Items[this.listActions.SelectedIndex + 1][2]
			this.listActions.Items[this.listActions.SelectedIndex + 1].Text := Action
			this.listActions.Items[this.listActions.SelectedIndex + 1][2] := Command
		}
	}

	listActions_SelectionChanged()
	{
		if(this.listActions.SelectedItems.MaxIndex() = 1)
		{
			this.editAction.Enabled := true
			this.editCommand.Enabled := true
			this.btnBrowse.Enabled := true
			this.btnMoveActionUp.Enabled := this.listActions.SelectedIndex > 1
			this.btnMoveActionDown.Enabled := this.listActions.SelectedIndex < this.listActions.Items.MaxIndex()
			this.editAction.Text := this.listActions.SelectedItem.Text
			this.editCommand.Text := this.listActions.SelectedItem[2]
		}
		else
		{
			this.editAction.Enabled := false
			this.editCommand.Enabled := false
			this.btnBrowse.Enabled := false
			this.btnMoveActionUp.Enabled := false
			this.btnMoveActionDown.Enabled := false
			this.editAction.Text := ""
			this.editCommand.Text := ""
		}
	}

	editAction_TextChanged()
	{
		if(this.listActions.SelectedItems.MaxIndex() = 1)
			this.listActions.SelectedItem.Text := this.editAction.Text
	}

	editCommand_TextChanged()
	{
		if(this.listActions.SelectedItems.MaxIndex() = 1)
			this.listActions.SelectedItem[2] := this.editCommand.Text
	}
}