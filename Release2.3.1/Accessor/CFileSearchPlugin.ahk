Class CFileSearchPlugin extends CAccessorPlugin
{
	;Register this plugin with the Accessor main object
	static Type := CAccessor.RegisterPlugin("File Search", CFileSearchPlugin)
	
	Description := "Quickly find files on the computer or the current directory."
	
	Cleared := false
	List := Array()
	Icons := Array()
	AllowDelayedExecution := true
	SearchIcon := ExtractIcon("%WINDIR%\System32\shell32.dll", 23)

	DllPath := A_ScriptDir "\lib" (A_PtrSize = 8 ? "\x64" : "" ) "\FileSearch.dll"
	IndexingWorkerThreads := {}
	FileSystemIndex := {}

	Class CSettings extends CAccessorPlugin.CSettings
	{
		Keyword := "find"
		KeywordOnly := true
		MinChars := 3
		UseIcons := true
		IndexingFrequency := 24 ;Indexing frequency [hours]
	}

	Class CSearchInAccessorResult extends CAccessorPlugin.CResult
	{
		Actions := {DefaultAction : new CAccessor.CAction("Search", "SearchInAccessor", "", false, false, false, A_WinDir "\System32\Shell32.dll", 210)}
		Type := "File Search"
		Priority := CFileSearchPlugin.Instance.Priority
		MatchQuality := 1 ;Only direct matches are used by this plugin
		Title := "Show search results in Accessor for:"
		Detail1 := "File search"
	}

	Class CMoreResultsResult extends CAccessorPlugin.CResult
	{
		Actions := {DefaultAction : CAccessorPlugin.CActions.Cancel}
		Type := "File Search"
		Priority := 0
		MatchQuality := 1 ;Only direct matches are used by this plugin
		Title := "There were more results which are not shown"
		Detail1 := "File search"
	}

	Class CSearchResult extends CAccessorPlugin.CResult
	{
		Class CFileActions extends CArray
		{
			DefaultAction := new CAccessor.CAction("Open file", "Run")
			__new()
			{
				this.Insert(CAccessorPlugin.CActions.OpenWith)
				this.Insert(CAccessorPlugin.CActions.OpenPathWithAccessor)
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
				this.Insert(CAccessorPlugin.CActions.OpenPathWithAccessor)
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
			DefaultAction := CAccessorPlugin.CActions.OpenExplorer
			__new()
			{
				this.Insert(CAccessorPlugin.CActions.OpenWith)
				this.Insert(CAccessorPlugin.CActions.OpenPathWithAccessor)
				this.Insert(CAccessorPlugin.CActions.OpenCMD)
				this.Insert(CAccessorPlugin.CActions.Copy)
				this.Insert(CAccessorPlugin.CActions.ExplorerContextMenu)
				this.Insert(CAccessorPlugin.CActions.SearchDir)
			}
		}

		__new(Type)
		{
			if(Type = "Folder")
				this.Actions := new this.CFolderActions()
			else if(Type = "Executable")
				this.Actions := new this.CExecutableActions()
			else
				this.Actions := new this.CFileActions()
		}
		
		ResultIndexingKey := "Path"
		Type := "File Search"
		Priority := CFileSearchPlugin.Instance.Priority
		MatchQuality := 1 ;Only direct matches are used by this plugin 
		Detail1 := "Search result"
	}

	Enable()
	{
		this.hModule := DllCall("LoadLibrary", "Str", this.DllPath, "PTR")
		if(!this.hModule)
			MsgBox % "Failed to load " this.DllPath "!"
		else
			this.BuildFileDatabase()
	}

	Disable()
	{
		this.FreeResources()
		SetTimer, UpdateFileSystemIndex, Off
	}

	FreeResources()
	{
		;Get rid of old icons from last queries
		for path, Icon in this.Icons
			DestroyIcon(Icon)
		this.Icons := Array()
		for drive, DriveIndex in this.FileSystemIndex
			DllCall(this.DllPath "\DeleteIndex", "PTR", DriveIndex)
		this.FileSystemIndex := {}
		if(this.hModule)
			DllCall("FreeLibrary", "PTR", this.hModule)
		this.Remove("hModule")
	}
	
	ShowSettings(PluginSettings, GUI, PluginGUI)
	{
		AddControl(PluginSettings, PluginGUI, "Checkbox", "UseIcons", "Use proper icons (not recommended)", "", "", "", "", "", "", "If checked, 7plus will use the correct icon for each file. This can cause instabilities for large results.")
		AddControl(PluginSettings, PluginGUI, "UpDown", "IndexingFrequency", "1-100", "", "Indexing frequency[hours]:", "", "", "", "", "This plugin uses an index to speed up the search.`nTo make sure that the retrieved files aren't outdated`nit needs to be rebuilt regularly. Depending on the`nnumber of files this can take up to a minute.")
	}

	SaveSettings(PluginSettings, GUI, PluginGUI)
	{
		this.BuildFileDatabase()
	}

	RefreshList(Accessor, Filter, LastFilter, KeywordSet, Parameters)
	{
		if(!KeywordSet)
			return

		Results := {}
		if(this.HasKey("SearchPath"))
			SearchPath := this.SearchPath
		if((pos := InStr(Filter, " in ")))
		{
			;Ignore invalid paths
			if(!InStr(FileExist(SubStr(Filter, pos + 4)), "D"))
				return
			outputdebug filter %filter%
			SearchPath := SubStr(Filter, pos + 4)
			Filter := SubStr(Filter, 1, pos - 1)
			outputdebug pos %pos% Filter %filter% searchpath %searchpath%
		}
		if(this.hModule && StrLen(Filter) < 4 && !this.SearchAnyway)
		{
			Result := new this.CSearchInAccessorResult()
			if(SearchPath)
			{
				Result.Title .= " " Filter
				Result.Path := SearchPath
			}
			else
				Result.Path := Filter
			Result.Icon := Accessor.GenericIcons.7plus
			Results.Insert(Result)
		}
		else if(this.hModule)
		{
			this.SearchAnyway := false
			strResult := this.Search(Filter, SearchPath, nResults)
			Loop, Parse, strResult, `n
			{
				SplitPath, A_LoopField, Name, Dir, ext
				IsDir := InStr(FileExist(A_LoopField), "D")
				IsExecutable := !IsDir && ext && InStr("exe,cmd,bat,ahk", ext)
				Result := new this.CSearchResult(IsDir ? "Folder" : (IsExecutable ? "Executable" : "File"))
				Result.Title := Name
				Result.Path := A_LoopField
				if(this.Settings.UseIcons || (nResults != -1 && nResults <= 20))
				{
					if(this.Icons.HasKey(A_LoopField))
						hIcon := this.Icons[A_LoopField]
					else
					{
						hIcon := ExtractAssociatedIcon(0, A_LoopField, iIndex)
						this.Icons.Insert(hIcon)
					}
					Result.Icon := hIcon
				}
				else
					Result.Icon := IsDir ? Accessor.GenericIcons.Folder : (IsExecutable ? Accessor.GenericIcons.Application : Accessor.GenericIcons.File)
				Results.Insert(Result)
			}
			if(nResults = -1) ;More results
			{
				Result := new this.CMoreResultsResult()
				Results.Insert(Result)
			}
		}
		return Results
	}

	Search(Query, SearchPath, ByRef nAllResults)
	{
		strAllDrivesResult := ""
		nAllResults := 0
		outputdebug start search %A_TickCount%
		start := A_TickCount
		for Drive, DriveIndex in this.FileSystemIndex
		{
			outputdebug % Drive ": Start: " A_TickCount
			pResult := DllCall(this.DllPath "\SearchIndex", "PTR", DriveIndex, "wstr", Query, SearchPath ? "wstr" : "ptr", SearchPath ? SearchPath : 0, "int", true, "int", true, "int", 100, "int*", nResults, PTR)
			strResult := StrGet(presult + 0)
			outputdebug % Drive ": Searched: " A_TickCount
			if(pResult)
			{
				DllCall(this.DllPath "\FreeResultsBuffer", "PTR", pResult)
				if(strResult)
					strAllDrivesResult .= (strLen(strAllDrivesResult) = 0 ? "" : "`n") strResult
			}
			outputdebug % Drive ": " A_TickCount - start
			if(nResults != -1)
				nAllResults += nResults
			else
			{
				nAllResults := -1
				break
			}
		}
		outputdebug % "Time: " A_TickCount - start
		return strAllDrivesResult
	}

	OnClose(Accessor)
	{
		this.CancelSearch()
	
		;Get rid of old icons from last queries
		for path, Icon in this.Icons
			DestroyIcon(Icon)
	}

	OnExit()
	{
		this.FreeResources()
	}
	
	SearchInAccessor(Accessor, ListEntry)
	{
		this.SearchAnyway := true
		Accessor.RefreshList()
	}

	;Builds a database of all files on fixed drives
	BuildFileDatabase(LoadExisting = true)
	{
		if(this.hModule)
		{
			DriveGet, Drives, List, FIXED
			NTFSDrives := []
			Loop, Parse, Drives
			{
				DriveGet, FS, FS, %A_LoopField%:
				if(FS = "NTFS")
					NTFSDrives.Insert(A_LoopField)
			}
			DriveCount := NTFSDrives.MaxIndex()
			DrivesLeft := ""
			Critical, On
			for index, Drive in NTFSDrives
			{
				IndexPath := Settings.ConfigPath "\" Drive ".index"
				if(FileExist(IndexPath))
				{
					FileGetTime, ModificationTime, %IndexPath%
					Delta := A_Now
					EnvSub, Delta, %ModificationTime%, minutes
					if(Delta > 0 && Delta / 60 < this.Settings.IndexingFrequency && LoadExisting)
					{
						this.LoadDriveIndex(Drive, IndexPath)
						continue
					}
				}
				Outputdebug Start worker thread to build index for %Drive%
				WorkerThread := new CWorkerThread("BuildFileDatabaseForDrive", 0, 1, 1)
				;WorkerThread.OnProgress.Handler := new Delegate(this, "ProgressHandler")
				WorkerThread.OnStop.Handler := new Delegate(this, "OnStop")
				;WorkerThread.OnData.Handler := new Delegate(this, "OnData")
				WorkerThread.OnFinish.Handler := new Delegate(this, "OnFinish")
				WorkerThread.Start(Drive, IndexPath)
				if(WorkerThread.WaitForStart(5))
				{
					outputdebug Started worker thread for %Drive%
					this.IndexingWorkerThreads[Drive] := WorkerThread
					DrivesLeft .= (StrLen(DrivesLeft) > 0 ? ", " : "") Drive
				}
				else if(WorkerThread.State != "Finished")
				{
					outputdebug failed to wait for worker thread startup
					Notify("File search error!", "Couldn't start the searching process!", 5, NotifyIcons.Error)
				}
			}

			if(StrLen(DrivesLeft))
				this.IndexingWorkerThreads.NotificationWindow := Notify("Indexing drives for file search", "Drives left: " DrivesLeft, "", NotifyIcons.Info)
			
			Critical, Off

			if(Delta > 0 && Delta < this.Settings.IndexingFrequency)
				SetTimer, UpdateFileSystemIndex, % (Delta - this.Settings.IndexingFrequency) * 3600000
			else
				SetTimer, UpdateFileSystemIndex, % "-" max(this.Settings.IndexingFrequency * 3600000, 600000) ;Should be atleast 10 minutes
		}
	}

	OnStop(WorkerThread, Reason)
	{
		;Shouldn't happen
	}

	OnFinish(WorkerThread, Result)
	{
		if(Result = true)
		{
			Drive := WorkerThread.Task.Parameters[1]
			File := WorkerThread.Task.Parameters[2]
			this.LoadDriveIndex(Drive, File)
		}
		this.IndexingWorkerThreads.Remove(Drive)
		DrivesLeft := ""
		for d, value in this.IndexingWorkerThreads
			if(d != "NotificationWindow")
				DrivesLeft .= (StrLen(DrivesLeft) > 0 ? ", " : "") d
		if(StrLen(DrivesLeft))
			this.IndexingWorkerThreads.NotificationWindow.Text := "Drives left: " DrivesLeft
		else
		{
			this.IndexingWorkerThreads.NotificationWindow.Close()
			this.IndexingWorkerThreads.Remove("NotificationWindow")
		}
		outputdebug finished indexing %Drive%! Result: %Result%
	}
	LoadDriveIndex(Drive, Path)
	{
		if(FileExist(Path) && this.hModule)
		{
			outputdebug load file system index for %path%
			if(DriveIndex := DllCall(this.DllPath "\LoadIndexFromDisk", "str", Path, "PTR"))
				this.FileSystemIndex[Drive] := DriveIndex
			else
				Msgbox Failed to load %Path%!
		}
	}

	OnFilterChanged(ListEntry, Filter, LastFilter)
	{
		this.CancelSearch()
		if(this.HasKey("SearchPath") && InStr(LastFilter, this.Settings.Keyword " ") = 1 && InStr(Filter, this.Settings.Keyword " ") != 1)
			this.Remove("SearchPath")
		return true
	}
	GetFooterText()
	{
		return "File search may take up to a few seconds, please have patience."
	}
}

UpdateFileSystemIndex:
CAccessor.Plugins[CFileSearchPlugin.Type].BuildFileDatabase(false)
return

;Builds a database of all files on fixed drives
BuildFileDatabaseForDrive(WorkerThread, Drive, Path)
{
	DllPath := A_ScriptDir "\lib" (A_PtrSize = 8 ? "\x64" : "" ) "\FileSearch.dll"
	hModule := DllCall("LoadLibrary", "Str", DllPath, "PTR")
	result := false
	if(!hModule)
		MsgBox % "Failed to load " DllPath "!"
	else
	{
		DriveIndex := DllCall(DllPath "\CreateIndex", ushort, NumGet(Drive, "ushort"), "PTR")
		if(DriveIndex)
		{
			result := DllCall(DllPath "\SaveIndexToDisk", "PTR", DriveIndex, wstr, Path, "UINT")
			DllCall(DllPath "\DeleteIndex", "PTR", DriveIndex)
		}
	}
	if(hModule)
		DllCall("FreeLibrary", "PTR", hModule)
	return result
}